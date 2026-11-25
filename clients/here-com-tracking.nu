# Auto-generated client for HERE Tracking v2.1.191
# Source: https://api.apis.guru/v2/specs/here.com/tracking/2.1.191/openapi.json
# Auth: --token flag or $env.HERE_TRACKING_TOKEN

const CLIENT = {
  base_url: "https://tracking.api.here.com"
  token_env_var: "HERE_TRACKING_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: oauth, in: header, header_name: Authorization, prefix: Oauth}
  ]
}

# The request runtime, emitted verbatim into every generated client.
#
# Each API command is one `http-request` call: a descriptor of the operation
# (method, path, where each argument goes, body encoding, accepted response
# types, success codes, auth) and a record of every argument the command
# received, keyed by variable name. `build-request` turns the two into the
# request record `--dry-run` returns plus the body as sent; `http-send` sends
# it. Everything the generator knew about the client itself (base URL, token
# env var, timeout, default headers, auth schemes, Unix socket) is the
# `CLIENT` constant above.

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, spelling included,
# and names match whatever their case (`accept` replaces `Accept`; a plain
# `merge` would send both). `Cookie` is the exception: a request carries all
# its cookies in one header (RFC 6265 §5.4), so both sides' cookie strings
# are kept, joined with `; `, or a cookie param would drop a cookie-located
# auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let is_cookie = {|k| ($k | str lowercase) == "cookie" }
  let cookie = ([$base $extra] | each {|h| $h | transpose k v | where {|e| do $is_cookie $e.k } | get v } | flatten
    | where {|c| $c | is-not-empty } | each { into string } | str join "; ")
  let replaced = ($extra | columns | each { str lowercase })
  let stale = ($base | columns | where {|k| (($k | str lowercase) in $replaced) or (do $is_cookie $k) })
  let merged = ($base | reject -o ...$stale | merge $extra)
  let merged = ($merged | reject -o ...($merged | columns | where {|k| do $is_cookie $k }))
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

# The body kind of a media type a Content-Type header param picks at call
# time (the descriptor's own kind was decided at generation time, the same
# way): json for `application/json` and the `+json` suffix types, form,
# multipart, or opaque. Parameters such as a charset are ignored.
def body-kind [content_type: string]: nothing -> string {
  let media = ($content_type | split row ";" | first | str trim | str lowercase)
  if ($media == "application/json") or ($media | str ends-with "+json") {
    "json"
  } else if $media == "application/x-www-form-urlencoded" {
    "form"
  } else if $media == "multipart/form-data" {
    "multipart"
  } else {
    "opaque"
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| merge-headers $acc $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
}

# The auth record for one scheme: {scheme, headers, query, location}. The
# token is the flag value, else `$env.<CLIENT.token_env_var>`. The scheme is a
# row of `CLIENT.auth_schemes` saying where the credential goes (`in`:
# header, query or cookie; `header_name`; `prefix`; `base64` for
# `basic-credentials`, which encodes `user:pass` itself); an unknown scheme
# sends `Authorization: Bearer`. `location` tells dry-run callers where the
# token went: "header" | "query" | "cookie" | "none".
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o $CLIENT.token_env_var | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  let s = ($CLIENT.auth_schemes | where name == $scheme | get -o 0 | default {in: header, header_name: Authorization, prefix: Bearer})
  let value = if ($s.base64? | default false) { $token_val | encode base64 } else { $token_val }
  # A query token is percent-encoded like any query value; a cookie goes out
  # as given, like a cookie param: servers do not percent-decode cookies.
  match $s.in {
    "query" => {scheme: $scheme, headers: {}, query: $"(encode-path-segment $s.header_name)=(encode-path-segment $value)", location: "query"}
    "cookie" => {scheme: $scheme, headers: {Cookie: $"($s.header_name)=($value)"}, query: "", location: "cookie"}
    _ => {scheme: $scheme, headers: {$s.header_name: (if ($s.prefix | is-empty) { $value } else { $"($s.prefix) ($value)" })}, query: "", location: "header"}
  }
}

# Build the request an operation descriptor describes from the arguments its
# command received (`args`, keyed by variable name) and its pipeline input.
# Returns {req, wire}: `req` is the request record `--dry-run` returns, with
# the logical body; `wire` is the body as sent (form-encoded, JSON text, or a
# multipart envelope where the content type needs one).
#
# Descriptor keys (absent means empty or the default):
#   method, path        the verb and the spec path template (`{name}` slots)
#   fixed_query         a constant query the path key carries
#   path_params         [{name, var, encode?: array|greedy}]
#   query               [{name, var, style?, required?, default?}]
#   header, cookie      [{name, var, array?, required?, default?}]
#   body                {content_type, kind: json|form|multipart|opaque, accepts?,
#                        fields?: [{name, var, join?, required?}], files?}
#   accept, ok          the response media types, the success status codes
#   base_url            the operation's own server
#   auth | auth_all     the default scheme, or every scheme of an AND-form
#                       requirement: [{scheme, var, env}]
# A flag's name is its variable with `-` for `_`: the generator never puts an
# underscore in a flag.
def build-request [op: record, args: record, input: any]: nothing -> record {
  let auth = if ($op.auth_all? | is-not-empty) {
    merge-auth ($op.auth_all | each {|s| build-auth ($args | get -o $s.var | default ($env | get -o $s.env | default "")) $s.scheme })
  } else {
    build-auth $args.token? ($args.auth_scheme? | default $op.auth)
  }
  let base = ($args.base_url | default ($op.base_url? | default $CLIENT.base_url))
  # An empty path value would leave `/foo//bar`, which routes elsewhere.
  for p in ($op.path_params? | default []) {
    if ($args | get $p.var | is-empty) { error make --unspanned { msg: $"path parameter '($p.name)' must be non-empty" } }
  }
  # A required query/header/cookie param left out takes the spec default (or
  # a lone enum value); with none, the request is refused. A Content-Type or
  # Accept header param always has a value, the body's or the response's type.
  mut args = $args
  for loc in [query header cookie] {
    for p in ($op | get -o $loc | default [] | where {|p| $p.required? | default false }) {
      let value = ($args | get $p.var | default $p.default?)
      $args = ($args | upsert $p.var $value)
      let always_set = ($loc == "header") and (($p.name | str lowercase) in [content-type accept])
      if ($value == null) and (not $always_set) {
        error make --unspanned { msg: $"required ($loc) parameter '($p.name)' missing: pass --($p.var | str replace --all '_' '-')" }
      }
    }
  }
  let args = $args
  let query = ($op.query? | default [])
  let qp = ($query | each {|q| serialize-qp $q.name ($args | get $q.var) ($q.style? | default "scalar") } | flatten | str join "&")
  let path = ($op.path_params? | default [] | reduce --fold $op.path {|p, acc|
    let v = ($args | get $p.var)
    let encoded = match ($p.encode? | default "segment") {
      "array" => (encode-path-array $v)
      "greedy" => (encode-path-greedy $v)
      _ => (encode-path-segment $v)
    }
    $acc | str replace --all $"{($p.name)}" $encoded
  })
  let url = (build-url $base $path ($op.fixed_query? | default "") $qp $auth.query)

  # The body: its per-field flags assembled into a record (a csv/ssv/tsv/pipes
  # form array joined into one value), else the `--body` value; then pipeline
  # input merged in. No field flag and nothing piped is no body, while an
  # explicit `--body {}` or a piped `{}` is sent. A required field that is a
  # flag is checked after the merge, unless the body is not a record: a
  # polymorphic body may be a piped list.
  let body = ($op.body? | default null)
  let req_body = if ($body == null) { null } else {
    let assembled = if ($body.fields? | is-empty) { $args.body? } else {
      let fields = ($body.fields | reduce --fold {} {|f, acc|
        let v = ($args | get $f.var)
        let v = if ($f.join? != null) and ($v | describe | str starts-with "list") { $v | compact | each { into string } | str join $f.join } else { $v }
        $acc | upsert $f.name $v
      } | compact)
      if ($fields | is-empty) { null } else { $fields }
    }
    merge-body-input $input $assembled ($body.accepts? | default "record")
  }
  for f in ($body.fields? | default [] | where {|f| $f.required? | default false }) {
    let checked = ($req_body | default {})
    if ($checked | describe | str starts-with "record") and (($checked | get -o $f.name) == null) {
      error make --unspanned { msg: $"required body field '($f.name)' missing: pass --($f.var | str replace --all '_' '-') or pipe a record" }
    }
  }

  # Headers, in merge order: auth, Accept, header params (an array joined with
  # commas), cookie params (every cookie joined into the one Cookie header by
  # merge-headers), and the client's default headers underneath them all.
  let accept = ($args.accept? | default ($op.accept | first))
  let headers = (merge-headers $auth.headers {Accept: $accept})
  let join_list = {|p, v| if ($p.array? | default false) and ($v | describe | str starts-with "list") { $v | compact | each { into string } | str join "," } else { $v } }
  let headers = if ($op.header? | is-empty) { $headers } else {
    merge-headers $headers ($op.header | reduce --fold {} {|h, acc| $acc | upsert $h.name (do $join_list $h ($args | get $h.var)) } | compact)
  }
  let headers = if ($op.cookie? | is-empty) { $headers } else {
    let cookies = ($op.cookie | each {|c|
      let v = (do $join_list $c ($args | get $c.var))
      if $v == null { null } else { $"($c.name)=($v)" }
    } | str join "; ")
    merge-headers $headers {Cookie: $cookies}
  }
  let headers = if ($CLIENT.default_headers | is-empty) { $headers } else { merge-headers $CLIENT.default_headers $headers }

  # The wire body: null (nothing to send), a string or binary. The encoding is
  # the body kind, unless a Content-Type header param picks the media type at
  # call time. JSON is encoded here, not by `http`, which encodes a record
  # only under `application/json` and refuses a scalar. A form is urlencoded;
  # multipart/form-data is an RFC 7578 envelope with file fields read from disk
  # (not under --dry-run), and a non-record multipart body is sent verbatim.
  # An opaque type takes the caller's own wire form.
  let ct_param = ($op.header? | default [] | where {|h| ($h.name | str lowercase) == "content-type" } | get -o 0)
  let ct_arg = if ($body == null) or ($ct_param == null) { null } else { $args | get $ct_param.var }
  let content_type = ($ct_arg | default $body.content_type?)
  let kind = if ($body == null) { "none" } else if ($ct_arg != null) { body-kind $ct_arg } else { $body.kind }
  let req_body = if $kind == "multipart" { $req_body | default {} } else { $req_body }
  let shape = ($req_body | describe | str replace --regex '<.*' '')
  let mp = if $kind != "multipart" { null } else if $shape == "record" {
    build-multipart-body $req_body ($body.files? | default []) $args.dry_run
  } else {
    {body: $req_body, content_type: $content_type}
  }
  let wire = if ($req_body == null) { null } else {
    match $kind {
      "json" => (if $shape in [string binary] { $req_body } else { $req_body | to json -r })
      "form" => (if $shape == "record" { $req_body | compact | url build-query } else { $req_body | into string })
      "multipart" => $mp.body
      _ => {
        if $shape in [record list table] {
          error make --unspanned { msg: $"a ($content_type) body must be a string or binary: serialize it first" }
        }
        if $shape in [string binary] { $req_body } else { $req_body | into string }
      }
    }
  }

  let req = {
    method: $op.method
    url: $url
    query: ($query | reduce --fold {} {|q, acc| $acc | upsert $q.name ($args | get $q.var) } | compact)
    headers: $headers
    body: $req_body
    content_type: (if $kind == "multipart" { $mp.content_type } else { $content_type })
    timeout: ($args.max_time | default $CLIENT.timeout)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  let req = if ($CLIENT.unix_socket? == null) { $req } else { $req | insert unix_socket ($args.unix_socket? | default $CLIENT.unix_socket) }
  {req: $req, wire: $wire}
}

# Run one operation: build its request, return it under `--dry-run`, send it
# otherwise. Every generated API command is one call to this.
def http-request [op: record, args: record]: any -> any {
  let r = (build-request $op $args $in)
  if $args.dry_run { return ({dry_run: true} | merge $r.req) }
  http-send $r.req $r.wire $args $op.ok
}

# Send a built request with `http <method>` and unwrap the response
# (`handle-response`; a successful HEAD returns just the headers).
#
# The body arrives encoded by `build-request` (a string or binary), so it goes
# out as is with its Content-Type a plain header: nushell's `http` refuses a
# string or binary body under `--content-type` form or multipart, which it
# would encode itself. No body goes out as "" without a Content-Type.
#
# A request with a `unix_socket` (clients generated with one) connects over
# it unless it is empty; `--unix-socket` has no "off" value, so each call has
# two forms.
def http-send [req: record, body: any, args: record, ok: list<int>]: nothing -> any {
  let sock = ($req.unix_socket? | default "")
  let headers = if ($body == null) { $req.headers } else {
    let stale = ($req.headers | columns | where {|k| ($k | str lowercase) == "content-type" })
    $req.headers | reject -o ...$stale | insert Content-Type $req.content_type
  }
  let body = ($body | default "")
  let resp = if ($sock | is-empty) {
    match $req.method {
      get => (http get --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw $req.url)
      head => (http head --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure $req.url)
      options => (http options --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure $req.url)
      post => (http post --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw $req.url $body)
      put => (http put --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw $req.url $body)
      patch => (http patch --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw $req.url $body)
      delete => (http delete --headers $headers --data $body --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw $req.url)
    }
  } else {
    match $req.method {
      get => (http get --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw --unix-socket $sock $req.url)
      head => (http head --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --unix-socket $sock $req.url)
      options => (http options --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --unix-socket $sock $req.url)
      post => (http post --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw --unix-socket $sock $req.url $body)
      put => (http put --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw --unix-socket $sock $req.url $body)
      patch => (http patch --headers $headers --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw --unix-socket $sock $req.url $body)
      delete => (http delete --headers $headers --data $body --full --allow-errors --max-time $req.timeout --insecure=$args.insecure --raw=$args.raw --unix-socket $sock $req.url)
    }
  }
  if ($req.method == "head") and (not $args.full) and (not $args.allow_errors) and (status-ok $resp.status $ok) { return $resp.headers }
  $resp | handle-response $args.allow_errors $args.full $ok
}

def base-url-completer [] { ["https://tracking.api.here.com"] }
def auth-scheme-completer [] { ["bearer" "oauth" "none"] }

# Completers for enum parameters
def x-confirm-completer [] { ["true"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def type-completer [] { ["create" "delete"] }
def action-completer [] { ["acknowledge" "cancel"] }
def group-by-completer [] { ["eventSource" "ruleId"] }
def type-completer-1 [] { ["circle"] }
def resource-type-completer [] { ["device" "geofence" "location" "rule" "sensorRule" "shipment"] }
def channel-type-completer [] { ["browserPull" "email" "webhook"] }
def event-source-completer [] { ["acceleration" "attach" "battery" "detention" "dwelling" "geofence" "humidity" "online" "pressure" "shipmentSchedule" "stock" "tamper" "temperature" "utilization"] }
def event-type-completer [] { ["ABOVE_RANGE" "BELOW_RANGE" "DETENTION_ENDED" "DETENTION_STARTED" "DWELLING_ENDED" "DWELLING_STARTED" "EVENT" "FALSE_TO_TRUE" "INSIDE_GEOFENCE" "IN_RANGE" "NORMAL_VOLUME" "OUTSIDE_GEOFENCE" "OVERSTOCK" "SHIPMENT_DELAYED" "SHIPMENT_EARLY" "SHIPMENT_ON_TIME" "TRUE_TO_FALSE" "UNDERSTOCK" "UNUTILIZED" "UTILIZED"] }
def measure-completer [] { ["asset" "day" "duration" "occurrence"] }
def interval-completer [] { ["day" "month" "week"] }
def group-by-completer-1 [] { ["asset" "geofence"] }
def method-completer [] { ["average" "cumulative" "percentage"] }
def type-completer-2 [] { ["utilization"] }
def type-completer-3 [] { ["battery"] }
def state-completer [] { ["desired" "reported"] }
def accept-completer-1 [] { ["application/json" "text/plain"] }
def metric-completer [] { ["locationDwelling" "segmentPlanPunctualityAtDestination" "segmentPlanPunctualityAtOrigin" "segmentPunctualityAtDestination" "segmentPunctualityAtOrigin" "shipmentPlanPunctualityAtDestination" "shipmentPlanPunctualityAtOrigin" "shipmentPunctualityAtDestination" "shipmentPunctualityAtOrigin"] }
def status-completer [] { ["cancelled" "completed" "ongoing" "pending"] }
def transport-mode-completer [] { ["air" "car" "sea" "truck" "undefined"] }
def mode-completer [] { ["flight" "normal" "sleep" "transport" "unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-aliases-v2: "record<count: int, pageToken: string, data: table<aliases: record, trackingId: string>>"
    get-aliases-v2-health: "record<message: string>"
    get-aliases-v2-tracking-id: "record<appId: string, externalId: string, trackingId: string>"
    get-aliases-v2-tracking-id-1: "record<count: int, pageToken: string, data: record>"
    get-aliases-v2-tracking-id-type: "record<count: int, pageToken: string, data: record>"
    get-associations-v3-geofences-geofence-id: "record<count: int, pageToken: string, data: table<appId: string, externalId: string, trackingId: string>>"
    get-associations-v3-health: "record<message: string>"
    get-associations-v3-rules-rule-id: "record<count: int, pageToken: string, data: table<appId: string, externalId: string, trackingId: string>>"
    get-associations-v3-sensors-sensor-rule-id: "record<count: int, pageToken: string, data: table<appId: string, externalId: string, trackingId: string>>"
    get-associations-v3-tracking-id-geofences: "record<count: int, pageToken: string, data: table<geofence: any, id: string>>"
    get-associations-v3-tracking-id-rules: "record<count: int, pageToken: string, data: table<rule: any, ruleId: string>>"
    get-associations-v3-tracking-id-sensors: "record<count: int, pageToken: string, data: table<description: string, id: string, name: string, range: record, threshold: record, type: string>>"
    get-bulkjobs-v4-device-uploads: "record<count: int, items: table<jobId: string, status: string, type: string>, limit: int, nextPageToken: string>"
    post-bulkjobs-v4-device-uploads: "record<jobId: string>"
    patch-bulkjobs-v4-device-uploads-job-id: "record<status: string>"
    get-bulkjobs-v4-device-uploads-job-id-results: "record<count: int, items: table<connectorId: string, deviceId: string, deviceSecret: string, errors: list, externalDeviceId: string, externalId: string, name: string, trackingId: string>, limit: int, nextPageToken: string, status: string, type: string>"
    get-bulkjobs-v4-device-uploads-job-id-status: "record<failed: int, fileName: string, partiallySucceeded: int, pending: int, progress: float, status: string, succeeded: int, total: int, type: string>"
    get-bulkjobs-v4-health: "record<message: string>"
    get-c2c-v4-connectors: "record<count: int, items: table<connectorId: string, projectId: string, description: string, driverId: string, enabled: bool, externalCloudInfo: record, name: string, refreshIntervalS: int, lastExecTs: string, totalAddedDevices: int, createdAt: string>, limit: int, nextPageToken: string>"
    post-c2c-v4-connectors: "record"
    get-c2c-v4-connectors-ext-devices-external-device-id: "record<items: table<connectorId: string>>"
    get-c2c-v4-connectors-connector-id: "record<connectorId: string, projectId: string, description: string, driverId: string, enabled: bool, externalCloudInfo: record, name: string, refreshIntervalS: int, lastExecTs: string, totalAddedDevices: int, createdAt: string>"
    put-c2c-v4-connectors-connector-id: "record"
    get-c2c-v4-connectors-connector-id-ext-devices: "record<count: int, items: table<enabled: bool, externalDeviceId: string, externalDeviceInfo: record, info: record, localDeviceId: string, provisioning: string>, limit: int, nextPageToken: string>"
    get-c2c-v4-drivers: "record<count: int, items: table<autoProvisionCallbackDevices: bool, driverId: string, driverSyncMethod: string, driverType: string, externalCloudInfoSchema: list, provider: string, strategy: record, version: int>, limit: int, nextPageToken: string>"
    get-c2c-v4-health: "record<message: string>"
    get-device-associations-v2-health: "record<message: string>"
    get-device-associations-v2-tracking-id-geofences: "record<count: int, pageToken: string, data: table<geofence: any, id: string>>"
    get-events-v3: "record<count: int, pageToken: string, data: list<any>>"
    get-events-v3-health: "record<message: string>"
    get-events-v3-statuses: "record<count: int, pageToken: string, data: list<any>>"
    get-events-v3-statuses-device-counts: "record<count: int, pageToken: string, data: list<any>>"
    get-events-v3-tracking-id: "record<count: int, pageToken: string, data: list<any>>"
    get-geofence-associations-v2-health: "record<message: string>"
    get-geofence-associations-v2-geofence-id-devices: "record<count: int, pageToken: string, data: table<appId: string, externalId: string, trackingId: string>>"
    get-geofences-v2: "record<count: int, pageToken: string, data: table<geofence: any, id: string>>"
    post-geofences-v2: "record<id: string, message: string>"
    get-geofences-v2-health: "record<message: string>"
    post-geofences-v2-training-test: "record<metadata: record<coordinate: record<lat: float, lng: float>, timestamp: int, trackingId: string, usedWlanApCount: float>, reason: string, success: bool>"
    get-geofences-v2-geofence-id: "record<geofence: any, id: string>"
    put-geofences-v2-geofence-id: "record<geofence: any, id: string>"
    post-geofences-v2-geofence-id-poi-training: "record<trainingStatus: record<metadata: record<coordinate: record, timestamp: int, trackingId: string, usedWlanApCount: float>, trained: bool>>"
    get-labels-v4-health: "record<message: string>"
    get-labels-v4-resource-type: "record<count: int, items: table<labels: record, resourceId: string, resourceType: string>, limit: int, nextPageToken: string>"
    get-labels-v4-resource-type-keys: "record<keys: list<string>>"
    get-labels-v4-resource-type-keys-key-values: "record<values: list<string>>"
    get-labels-v4-resource-type-resource-id: "record<labels: record, resourceId: string, resourceType: string>"
    put-labels-v4-resource-type-resource-id-batch: "record<labels: record, resourceId: string, resourceType: string>"
    put-labels-v4-resource-type-resource-id-key-value: "record<labels: record, resourceId: string, resourceType: string>"
    post-largedata-v4: "record<dataId: string>"
    get-largedata-v4-devices-tracking-id-metadata: "record<count: int, items: table<completedAt: string, createdAt: string, dataId: string, description: string, name: string, numberOfParts: int, size: int, status: string, trackingId: string>, limit: int, nextPageToken: string>"
    get-largedata-v4-health: "record<message: string>"
    get-largedata-v4-data-id-data: "binary"
    get-largedata-v4-data-id-metadata: "record<completedAt: string, createdAt: string, dataId: string, description: string, name: string, numberOfParts: int, size: int, status: string, trackingId: string>"
    get-largedata-v4-data-id-parts: "record<count: int, items: table<md5: string, partNumber: int, size: int, status: string>, limit: int, nextPageToken: string>"
    get-locations-v4: "record<count: int, items: table<address: record, description: string, externalLocationId: string, geofenceId: string, location: record, locationId: string, name: string>, limit: int, nextPageToken: string, total: int>"
    post-locations-v4: "record<locationId: string>"
    get-locations-v4-health: "record<message: string>"
    get-locations-v4-location-id: "record<address: record<city: string, country: string, postalCode: string, state: string, street: string>, description: string, externalLocationId: string, geofenceId: string, location: record<lat: float, lng: float>, locationId: string, name: string>"
    put-locations-v4-location-id: "record<address: record<city: string, country: string, postalCode: string, state: string, street: string>, description: string, externalLocationId: string, geofenceId: string, location: record<lat: float, lng: float>, locationId: string, name: string>"
    post-metadata-v2-devices-batch: "record<count: int, pageToken: string, data: table<data: record, id: string>>"
    get-metadata-v2-devices-tracking-id: "record<data: record, id: string>"
    put-metadata-v2-devices-tracking-id: "record<data: record, id: string>"
    post-metadata-v2-geofences-batch: "record<count: int, pageToken: string, data: table<data: record, id: string>>"
    get-metadata-v2-geofences-geofence-id: "record<data: record, id: string>"
    put-metadata-v2-geofences-geofence-id: "record<data: record, id: string>"
    get-metadata-v2-health: "record<message: string>"
    post-metadata-v2-sensor-rules-batch: "record<count: int, pageToken: string, data: table<data: record, id: string>>"
    get-metadata-v2-sensor-rules-sensor-rule-id: "record<data: record, id: string>"
    put-metadata-v2-sensor-rules-sensor-rule-id: "record<data: record, id: string>"
    get-notifications-v3-health: "record<message: string>"
    get-notifications-v3-registration-channel-id: "record<registration: any>"
    put-notifications-v3-registration-channel-id: "record<registration: any>"
    get-notifications-v3-registrations: "record<count: int, pageToken: string, data: list<any>>"
    post-notifications-v3-registrations: "record<registration: any>"
    get-registry-v2-devices-device-or-external-id: "record<trackingId: string>"
    put-registry-v2-devices-device-or-external-id: "record<trackingId: string>"
    get-registry-v2-health: "record<message: string>"
    get-registry-v2-licenses: "record<end: int, licenses: table<appId: string, expired: bool, expiryDate: string, features: list, projectDescription: string, projectHrn: string, projectId: string, projectName: string, quota: record, realm: string, type: string>, start: int, total: int>"
    get-registry-v2-app-id-devices: "record<count: int, pageToken: string, data: table<appId: string, deviceId: string, externalId: string, timestamp: int>>"
    post-registry-v2-app-id-devices: "record<jobId: string>"
    get-registry-v2-app-id-license-count: "record<count: float, updatedAt: string>"
    post-registry-v2-app-id-one-device: "record<deviceId: string, deviceSecret: string, trackingId: string>"
    get-registry-v2-job-id-results: "record<count: int, pageToken: string, data: table<deviceId: string, deviceSecret: string, externalId: string, trackingId: string>, errors: table<error: record, id: string>>"
    get-registry-v2-job-id-status: "record<percent: float, status: string>"
    get-registry-v2-tracking-id: "record<deviceId: string>"
    post-registry-v4-resources-resource-type-find: "record<count: int, items: table<resourceId: string>, limit: int, nextPageToken: string, total: int>"
    post-reports-v4: "record<reportId: string>"
    get-reports-v4-health: "record<message: string>"
    get-reports-v4-report-id: "record<count: int, items: list<any>, limit: int, nextPageToken: string, status: string>"
    get-rules-v4: "record<count: int, items: table<rule: any, ruleId: string>, limit: int, nextPageToken: string>"
    post-rules-v4: "record<ruleId: string>"
    get-rules-v4-health: "record<message: string>"
    get-rules-v4-rule-id: "record<rule: any, ruleId: string>"
    put-rules-v4-rule-id: "record<rule: any, ruleId: string>"
    get-sensors-v3: "record<count: int, pageToken: string, data: table<description: string, id: string, name: string, range: record, threshold: record, type: string>>"
    post-sensors-v3: "record<id: string, message: string>"
    get-sensors-v3-health: "record<message: string>"
    get-sensors-v3-sensor-rule-id: "record<description: string, id: string, name: string, range: record<begin: float, end: float>, threshold: record<value: float>, type: string>"
    put-sensors-v3-sensor-rule-id: "record<message: string, description: string, id: string, name: string, range: record<begin: float, end: float>, threshold: record<value: float>, type: string>"
    post-shadows-v2-batch: "table<appId: string, body: record<desired: record, reported: record>, externalId: string, statusCode: int, trackingId: string>"
    get-shadows-v2-health: "record<message: string>"
    get-shadows-v2-tracking-id: "record<desired: record<payload: record, system: record<detectOutliers: bool, disableTracking: record, lastModifiedGeofenceTimestamp: int, rate: record, sensorAlarmConfig: record, sensorLoggingConfigurations: list, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list, wlanConnectivityEnabled: bool>, timestamp: int>, reported: record<payload: record, position: record<accuracy: float, alt: float, altaccuracy: float, confidence: int, floor: record, heading: int, lat: float, lng: float, satellitecount: int, speed: int, timestamp: int, type: string, wlancount: int>, system: record<client: record, computed: record, iccid: string, imsi: string, mode: string, phoneNumber: string, reportedSensorData: record, stateVersion: int>, timestamp: int>>"
    put-shadows-v2-tracking-id: "record<desired: record<payload: record, system: record<detectOutliers: bool, disableTracking: record, lastModifiedGeofenceTimestamp: int, rate: record, sensorAlarmConfig: record, sensorLoggingConfigurations: list, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list, wlanConnectivityEnabled: bool>, timestamp: int>, reported: record<payload: record, position: record<accuracy: float, alt: float, altaccuracy: float, confidence: int, floor: record, heading: int, lat: float, lng: float, satellitecount: int, speed: int, timestamp: int, type: string, wlancount: int>, system: record<client: record, computed: record, iccid: string, imsi: string, mode: string, phoneNumber: string, reportedSensorData: record, stateVersion: int>, timestamp: int>>"
    get-shadows-v4: "record<count: int, items: table<appId: string, externalId: string, shadow: record, trackingId: string>, limit: int, nextPageToken: string>"
    post-shipment-reports-v4: "record<shipmentReportId: string>"
    get-shipment-reports-v4-health: "record<message: string>"
    get-shipment-reports-v4-shipment-report-id-status: "record<error: record<code: int, details: any, error: string, id: string, message: string>, status: string>"
    get-shipment-reports-v4-shipment-report-id-summary: "record<completedAt: string, createdAt: string, totalLocationCount: int, totalSegmentPlanCount: int, totalSegmentsCount: int, totalShipmentPlanCount: int, totalShipmentsCount: int>"
    get-shipment-reports-v4-shipment-report-id-metric: "record<count: int, items: table<ids: record, statistics: record, statisticsCount: int>, limit: int, nextPageToken: string, total: int>"
    get-shipments-v4: "record<count: int, items: table<autoStart: bool, calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, endedAt: string, name: string, providedEta: string, providedEtd: string, ruleIds: list, segments: list, shipmentId: string, shipmentPlanId: string, startedAt: string, status: string, subShipment: bool>, limit: int, nextPageToken: string, total: int>"
    post-shipments-v4: "record<shipmentId: string>"
    get-shipments-v4-health: "record<message: string>"
    get-shipments-v4-plans: "record<count: int, items: table<autoStart: bool, createdAt: string, description: string, name: string, ruleIds: list, segments: list, shipmentPlanId: string, subShipment: bool>, limit: int, nextPageToken: string, total: int>"
    post-shipments-v4-plans: "record<shipmentPlanId: string>"
    get-shipments-v4-plans-shipment-plan-id: "record<autoStart: bool, createdAt: string, description: string, name: string, ruleIds: list<string>, segments: table<description: string, destination: string, durationS: int, name: string, origin: string, segmentPlanId: string, trackingId: string, transportMode: string>, shipmentPlanId: string, subShipment: bool>"
    get-shipments-v4-plans-shipment-plan-id-segment-plan-id: "record<description: string, destination: string, durationS: int, name: string, origin: string, segmentPlanId: string, trackingId: string, transportMode: string>"
    get-shipments-v4-shipment-id: "record<autoStart: bool, calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, endedAt: string, name: string, providedEta: string, providedEtd: string, ruleIds: list<string>, segments: table<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string>, shipmentId: string, shipmentPlanId: string, startedAt: string, status: string, subShipment: bool>"
    get-shipments-v4-shipment-id-segment-id: "record<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string>"
    get-shipments-v4-tracking-id-segments: "record<count: int, items: table<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, shipmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string>, limit: int, nextPageToken: string>"
    get-traces-v2-health: "record<message: string>"
    get-traces-v2-tracking-id: "record<count: int, pageToken: string, data: table<payload: record, position: record, serverTimestamp: int, system: record, timestamp: int, trackingDisabled: list>>"
    get-transitions-v2-devices-tracking-id: "record<count: int, pageToken: string, data: table<geofence: any, geofenceId: string, inOut: string, notificationStatus: string, timestamp: int, trackingId: string>>"
    get-transitions-v2-health: "record<message: string>"
    get-users-v2-devices: "record<count: int, pageToken: string, data: table<appId: string, externalId: string, shadow: record, trackingId: string>>"
    get-users-v2-health: "record<message: string>"
    post-users-v2-login: "record<accessToken: string, expiresIn: int, realm: string, refreshToken: string, tokenType: string, userId: string>"
    post-users-v2-refresh: "record<accessToken: string, expiresIn: int, realm: string, refreshToken: string, tokenType: string, userId: string>"
    post-users-v2-token-exchange: "record<accessToken: string, expiresIn: int, issuedTokenType: string, scope: string, tokenType: string>"
    post-v2: "record<payload: record, system: record<detectOutliers: bool, disableTracking: record<periods: list, position: any, sensors: any>, lastModifiedGeofenceTimestamp: int, rate: record<distanceM: float, sampleMs: float, sendMs: float>, sensorAlarmConfig: record<alertAccelerationGMax: float, alertAccelerationGMin: float, alertBatteryLevelPMax: float, alertBatteryLevelPMin: float, alertPressureHpaMax: float, alertPressureHpaMin: float, alertRelativeHumidityMax: float, alertRelativeHumidityMin: float, alertTemperatureCMax: float, alertTemperatureCMin: float, alertTiltDegreeMax: float, alertTiltDegreeMin: float, isAttachAlertEnabled: bool, isTamperAlertEnabled: bool>, sensorLoggingConfigurations: list<record>, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list<record>, wlanConnectivityEnabled: bool>, timestamp: int>"
    get-v2-health: "record<message: string>"
    get-v2-timestamp: "record<timestamp: int>"
    post-v2-token: "record<accessToken: string, expiresIn: int>"
    post-v3: "record<payload: record, system: record<detectOutliers: bool, disableTracking: record<periods: list, position: any, sensors: any>, lastModifiedGeofenceTimestamp: int, rate: record<distanceM: float, sampleMs: float, sendMs: float>, sensorAlarmConfig: record<alertAccelerationGMax: float, alertAccelerationGMin: float, alertBatteryLevelPMax: float, alertBatteryLevelPMin: float, alertPressureHpaMax: float, alertPressureHpaMin: float, alertRelativeHumidityMax: float, alertRelativeHumidityMin: float, alertTemperatureCMax: float, alertTemperatureCMin: float, alertTiltDegreeMax: float, alertTiltDegreeMin: float, isAttachAlertEnabled: bool, isTamperAlertEnabled: bool>, sensorLoggingConfigurations: list<record>, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list<record>, wlanConnectivityEnabled: bool>, timestamp: int>"
    get-v3-health: "record<message: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-aliases-v2" "get-aliases-v2-health" "get-aliases-v2-tracking-id" "get-aliases-v2-version" "delete-aliases-v2-tracking-id" "get-aliases-v2-tracking-id-1" "put-aliases-v2-tracking-id-batch" "delete-aliases-v2-tracking-id-type" "get-aliases-v2-tracking-id-type" "delete-aliases-v2-tracking-id-type-external-id" "put-aliases-v2-tracking-id-type-external-id" "put-associations-v3-devices-batch-update" "post-associations-v3-devices-tracking-id-batch-create" "post-associations-v3-devices-tracking-id-batch-delete" "get-associations-v3-geofences-geofence-id" "get-associations-v3-health" "get-associations-v3-rules-rule-id" "get-associations-v3-sensors-sensor-rule-id" "get-associations-v3-version" "get-associations-v3-tracking-id-geofences" "delete-associations-v3-tracking-id-geofences-geofence-id" "put-associations-v3-tracking-id-geofences-geofence-id" "get-associations-v3-tracking-id-rules" "delete-associations-v3-tracking-id-rules-rule-id" "put-associations-v3-tracking-id-rules-rule-id" "get-associations-v3-tracking-id-sensors" "delete-associations-v3-tracking-id-sensors-sensor-rule-id" "put-associations-v3-tracking-id-sensors-sensor-rule-id" "get-bulkjobs-v4-device-uploads" "post-bulkjobs-v4-device-uploads" "patch-bulkjobs-v4-device-uploads-job-id" "get-bulkjobs-v4-device-uploads-job-id-results" "get-bulkjobs-v4-device-uploads-job-id-status" "get-bulkjobs-v4-health" "get-bulkjobs-v4-version" "post-c2c-v4-callback" "get-c2c-v4-connectors" "post-c2c-v4-connectors" "get-c2c-v4-connectors-ext-devices-external-device-id" "delete-c2c-v4-connectors-connector-id" "get-c2c-v4-connectors-connector-id" "put-c2c-v4-connectors-connector-id" "get-c2c-v4-connectors-connector-id-ext-devices" "post-c2c-v4-connectors-connector-id-ext-devices" "delete-c2c-v4-connectors-connector-id-ext-devices-batch" "delete-c2c-v4-connectors-connector-id-ext-devices-external-device-id" "get-c2c-v4-drivers" "post-c2c-v4-drivers-driver-id-verify" "get-c2c-v4-health" "get-c2c-v4-version" "get-device-associations-v2-health" "get-device-associations-v2-version" "get-device-associations-v2-tracking-id-geofences" "get-events-v3" "get-events-v3-health" "get-events-v3-statuses" "get-events-v3-statuses-device-counts" "get-events-v3-version" "get-events-v3-tracking-id" "get-geofence-associations-v2-health" "get-geofence-associations-v2-version" "get-geofence-associations-v2-geofence-id-devices" "delete-geofence-associations-v2-geofence-id-tracking-id" "put-geofence-associations-v2-geofence-id-tracking-id" "delete-geofences-v2" "get-geofences-v2" "post-geofences-v2" "get-geofences-v2-health" "post-geofences-v2-training-test" "get-geofences-v2-version" "delete-geofences-v2-geofence-id" "get-geofences-v2-geofence-id" "put-geofences-v2-geofence-id" "post-geofences-v2-geofence-id-poi-training" "get-labels-v4-health" "get-labels-v4-version" "get-labels-v4-resource-type" "get-labels-v4-resource-type-keys" "get-labels-v4-resource-type-keys-key-values" "delete-labels-v4-resource-type-resource-id" "get-labels-v4-resource-type-resource-id" "put-labels-v4-resource-type-resource-id-batch" "delete-labels-v4-resource-type-resource-id-key" "delete-labels-v4-resource-type-resource-id-key-value" "put-labels-v4-resource-type-resource-id-key-value" "post-largedata-v4" "get-largedata-v4-devices-tracking-id-metadata" "get-largedata-v4-health" "get-largedata-v4-version" "delete-largedata-v4-data-id" "post-largedata-v4-data-id" "get-largedata-v4-data-id-data" "get-largedata-v4-data-id-metadata" "get-largedata-v4-data-id-parts" "put-largedata-v4-data-id-parts-part-number" "delete-locations-v4" "get-locations-v4" "post-locations-v4" "get-locations-v4-health" "get-locations-v4-version" "delete-locations-v4-location-id" "get-locations-v4-location-id" "put-locations-v4-location-id" "post-metadata-v2-devices-batch" "delete-metadata-v2-devices-tracking-id" "get-metadata-v2-devices-tracking-id" "put-metadata-v2-devices-tracking-id" "post-metadata-v2-geofences-batch" "delete-metadata-v2-geofences-geofence-id" "get-metadata-v2-geofences-geofence-id" "put-metadata-v2-geofences-geofence-id" "get-metadata-v2-health" "post-metadata-v2-sensor-rules-batch" "delete-metadata-v2-sensor-rules-sensor-rule-id" "get-metadata-v2-sensor-rules-sensor-rule-id" "put-metadata-v2-sensor-rules-sensor-rule-id" "get-metadata-v2-version" "get-notifications-v3-health" "delete-notifications-v3-registration-channel-id" "get-notifications-v3-registration-channel-id" "put-notifications-v3-registration-channel-id" "delete-notifications-v3-registrations" "get-notifications-v3-registrations" "post-notifications-v3-registrations" "get-notifications-v3-version" "delete-registry-v2-devices-device-or-external-id" "get-registry-v2-devices-device-or-external-id" "put-registry-v2-devices-device-or-external-id" "get-registry-v2-health" "get-registry-v2-licenses" "get-registry-v2-version" "get-registry-v2-app-id-devices" "post-registry-v2-app-id-devices" "get-registry-v2-app-id-license-count" "post-registry-v2-app-id-one-device" "get-registry-v2-job-id-results" "get-registry-v2-job-id-status" "delete-registry-v2-tracking-id" "get-registry-v2-tracking-id" "post-registry-v4-resources-resource-type-find" "post-reports-v4" "get-reports-v4-health" "get-reports-v4-version" "get-reports-v4-report-id" "delete-rules-v4" "get-rules-v4" "post-rules-v4" "get-rules-v4-health" "get-rules-v4-version" "delete-rules-v4-rule-id" "get-rules-v4-rule-id" "put-rules-v4-rule-id" "delete-sensors-v3" "get-sensors-v3" "post-sensors-v3" "get-sensors-v3-health" "get-sensors-v3-version" "delete-sensors-v3-sensor-rule-id" "get-sensors-v3-sensor-rule-id" "put-sensors-v3-sensor-rule-id" "post-shadows-v2-batch" "get-shadows-v2-health" "get-shadows-v2-version" "delete-shadows-v2-tracking-id" "get-shadows-v2-tracking-id" "put-shadows-v2-tracking-id" "get-shadows-v2-tracking-id-state" "get-shadows-v2-tracking-id-state-selector" "get-shadows-v4" "post-shipment-reports-v4" "get-shipment-reports-v4-health" "get-shipment-reports-v4-version" "get-shipment-reports-v4-shipment-report-id-status" "get-shipment-reports-v4-shipment-report-id-summary" "get-shipment-reports-v4-shipment-report-id-metric" "delete-shipments-v4" "get-shipments-v4" "post-shipments-v4" "get-shipments-v4-health" "delete-shipments-v4-plans" "get-shipments-v4-plans" "post-shipments-v4-plans" "delete-shipments-v4-plans-shipment-plan-id" "get-shipments-v4-plans-shipment-plan-id" "patch-shipments-v4-plans-shipment-plan-id" "get-shipments-v4-plans-shipment-plan-id-segment-plan-id" "patch-shipments-v4-plans-shipment-plan-id-segment-plan-id" "get-shipments-v4-version" "delete-shipments-v4-shipment-id" "get-shipments-v4-shipment-id" "patch-shipments-v4-shipment-id" "get-shipments-v4-shipment-id-segment-id" "patch-shipments-v4-shipment-id-segment-id" "get-shipments-v4-tracking-id-segments" "get-traces-v2-health" "get-traces-v2-version" "delete-traces-v2-tracking-id" "get-traces-v2-tracking-id" "get-transitions-v2-devices-tracking-id" "get-transitions-v2-health" "get-transitions-v2-version" "get-users-v2-devices" "get-users-v2-health" "post-users-v2-login" "post-users-v2-refresh" "post-users-v2-token-exchange" "get-users-v2-version" "post-v2" "get-v2-health" "get-v2-timestamp" "post-v2-token" "get-v2-version" "post-v3" "post-v3-batch" "get-v3-health" "get-v3-version" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
  scope commands | where decl_id in $cmd_ids | each {|cmd|
    let sig = $cmd.signatures | values | first
    let params = $sig
      | where parameter_type not-in ["input" "output"]
      | where parameter_name not-in $builtin_flags
      | select parameter_name parameter_type syntax_shape is_optional description
    let name = ($cmd.name | str replace $"($mod_name) " "")
    {
      name: $name
      description: $cmd.description
      extra_description: $cmd.extra_description
      return_type: ($return_types | get -o $name | default "any")
      params: $params
    }
  }
}

# Gets all aliases
#
# GET /aliases/v2
# Returns: record<count: int, pageToken: string, data: table<aliases: record, trackingId: string>>
export def "get-aliases-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # An alias type
  --external-id: string # Filter for aliases external IDs
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aliases/v2"
    query: [{name: type, var: type}, {name: externalId, var: external_id}, {name: pageToken, var: page_token}, {name: count, var: count}, {name: after, var: after}, {name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, external_id: $external_id, page_token: $page_token, count: $count, after: $after, project_id: $project_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /aliases/v2/health
# Returns: record<message: string>
export def "get-aliases-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aliases/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the tracking ID associated with an alias
#
# GET /aliases/v2/trackingId
# Returns: record<appId: string, externalId: string, trackingId: string>
export def "get-aliases-v2-tracking-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # An alias type (required)
  --external-id: string # An external ID. An externalId and type pair uniquely identifies an alias. (required)
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aliases/v2/trackingId"
    query: [{name: type, var: type, required: true}, {name: externalId, var: external_id, required: true}, {name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, external_id: $external_id, project_id: $project_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /aliases/v2/version
export def "get-aliases-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/aliases/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all aliases of a device
#
# DELETE /aliases/v2/{trackingId}
export def "delete-aliases-v2-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/aliases/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all aliases of a device
#
# GET /aliases/v2/{trackingId}
# Returns: record<count: int, pageToken: string, data: record>
export def "get-aliases-v2-tracking-id-1" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --type: string # An alias type
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aliases/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}, {name: pageToken, var: page_token}, {name: count, var: count}, {name: type, var: type}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, page_token: $page_token, count: $count, type: $type, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates multiple aliases for a device
#
# PUT /aliases/v2/{trackingId}/batch
export def "put-aliases-v2-tracking-id-batch" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  aliases: record # A map of key-value pairs where the key is the type of the alias and the value is an array of `externalId`s.
]: any -> any {
  $in | http-request {
    method: put
    path: "/aliases/v2/{trackingId}/batch"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: aliases, var: aliases}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id, aliases: $aliases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all aliases of a specified type for a device
#
# DELETE /aliases/v2/{trackingId}/{type}
export def "delete-aliases-v2-tracking-id-type" [
  tracking_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/aliases/v2/{trackingId}/{type}"
    path_params: [{name: trackingId, var: tracking_id}, {name: type, var: type}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, type: $type, app_id: $app_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all aliases of a specified type for a device
#
# GET /aliases/v2/{trackingId}/{type}
# Returns: record<count: int, pageToken: string, data: record>
export def "get-aliases-v2-tracking-id-type" [
  tracking_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aliases/v2/{trackingId}/{type}"
    path_params: [{name: trackingId, var: tracking_id}, {name: type, var: type}]
    query: [{name: appId, var: app_id}, {name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, type: $type, app_id: $app_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an alias
#
# DELETE /aliases/v2/{trackingId}/{type}/{externalId}
export def "delete-aliases-v2-tracking-id-type-external-id" [
  tracking_id: string
  type: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/aliases/v2/{trackingId}/{type}/{externalId}"
    path_params: [{name: trackingId, var: tracking_id}, {name: type, var: type}, {name: externalId, var: external_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, type: $type, external_id: $external_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an alias
#
# PUT /aliases/v2/{trackingId}/{type}/{externalId}
export def "put-aliases-v2-tracking-id-type-external-id" [
  tracking_id: string
  type: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: put
    path: "/aliases/v2/{trackingId}/{type}/{externalId}"
    path_params: [{name: trackingId, var: tracking_id}, {name: type, var: type}, {name: externalId, var: external_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tracking_id: $tracking_id, type: $type, external_id: $external_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates rules associations for devices
#
# PUT /associations/v3/devices/batchUpdate
export def "put-associations-v3-devices-batch-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  new_rules: record # Rules to be associated to the devices — shape: {geofenceIds: list<string>, ruleIds: list<string>}
  old_rules: record # Rules to be disassociated from the devices — shape: {geofenceIds: list<string>, ruleIds: list<string>}
  tracking_ids: list<string> # Array of tracking IDs (external IDs are also permitted here)
]: any -> any {
  $in | http-request {
    method: put
    path: "/associations/v3/devices/batchUpdate"
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: newRules, var: new_rules}, {name: oldRules, var: old_rules}, {name: trackingIds, var: tracking_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    app_id: $app_id, x_request_id: $x_request_id, new_rules: $new_rules, old_rules: $old_rules, tracking_ids: $tracking_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates rules with a device
#
# POST /associations/v3/devices/{trackingId}/batchCreate
export def "post-associations-v3-devices-tracking-id-batch-create" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  geofence_ids: list<string> # Array of geofence IDs
  rule_ids: list<string> # Array of rule IDs
]: any -> any {
  $in | http-request {
    method: post
    path: "/associations/v3/devices/{trackingId}/batchCreate"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: geofenceIds, var: geofence_ids}, {name: ruleIds, var: rule_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id, geofence_ids: $geofence_ids, rule_ids: $rule_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates rules from a device
#
# POST /associations/v3/devices/{trackingId}/batchDelete
export def "post-associations-v3-devices-tracking-id-batch-delete" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  geofence_ids: list<string> # Array of geofence IDs
  rule_ids: list<string> # Array of rule IDs
]: any -> any {
  $in | http-request {
    method: post
    path: "/associations/v3/devices/{trackingId}/batchDelete"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: geofenceIds, var: geofence_ids}, {name: ruleIds, var: rule_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id, geofence_ids: $geofence_ids, rule_ids: $rule_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all devices associated with a geofence
#
# GET /associations/v3/geofences/{geofenceId}
# Returns: record<count: int, pageToken: string, data: table<appId: string, externalId: string, trackingId: string>>
export def "get-associations-v3-geofences-geofence-id" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/associations/v3/geofences/{geofenceId}"
    path_params: [{name: geofenceId, var: geofence_id}]
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    geofence_id: $geofence_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /associations/v3/health
# Returns: record<message: string>
export def "get-associations-v3-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/associations/v3/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all devices associated with a rule
#
# GET /associations/v3/rules/{ruleId}
# Returns: record<count: int, pageToken: string, data: table<appId: string, externalId: string, trackingId: string>>
export def "get-associations-v3-rules-rule-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/associations/v3/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all devices associated with a sensor rule
#
# GET /associations/v3/sensors/{sensorRuleId}
# Returns: record<count: int, pageToken: string, data: table<appId: string, externalId: string, trackingId: string>>
export def "get-associations-v3-sensors-sensor-rule-id" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/associations/v3/sensors/{sensorRuleId}"
    path_params: [{name: sensorRuleId, var: sensor_rule_id}]
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sensor_rule_id: $sensor_rule_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /associations/v3/version
export def "get-associations-v3-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/associations/v3/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets geofences associated with a device
#
# GET /associations/v3/{trackingId}/geofences
# Returns: record<count: int, pageToken: string, data: table<geofence: any, id: string>>
export def "get-associations-v3-tracking-id-geofences" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --type: list<string> # Type of a geofence
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/associations/v3/{trackingId}/geofences"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}, {name: pageToken, var: page_token}, {name: count, var: count}, {name: type, var: type, style: multi}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, page_token: $page_token, count: $count, type: $type, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Disassociates a device and a geofence
#
# DELETE /associations/v3/{trackingId}/geofences/{geofenceId}
export def "delete-associations-v3-tracking-id-geofences-geofence-id" [
  tracking_id: string
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/associations/v3/{trackingId}/geofences/{geofenceId}"
    path_params: [{name: trackingId, var: tracking_id}, {name: geofenceId, var: geofence_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, geofence_id: $geofence_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a device to a geofence
#
# PUT /associations/v3/{trackingId}/geofences/{geofenceId}
export def "put-associations-v3-tracking-id-geofences-geofence-id" [
  tracking_id: string
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: put
    path: "/associations/v3/{trackingId}/geofences/{geofenceId}"
    path_params: [{name: trackingId, var: tracking_id}, {name: geofenceId, var: geofence_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    tracking_id: $tracking_id, geofence_id: $geofence_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets rules associated with a device
#
# GET /associations/v3/{trackingId}/rules
# Returns: record<count: int, pageToken: string, data: table<rule: any, ruleId: string>>
export def "get-associations-v3-tracking-id-rules" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/associations/v3/{trackingId}/rules"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}, {name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a device and a rule
#
# DELETE /associations/v3/{trackingId}/rules/{ruleId}
export def "delete-associations-v3-tracking-id-rules-rule-id" [
  tracking_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/associations/v3/{trackingId}/rules/{ruleId}"
    path_params: [{name: trackingId, var: tracking_id}, {name: ruleId, var: rule_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, rule_id: $rule_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a device to a rule
#
# PUT /associations/v3/{trackingId}/rules/{ruleId}
export def "put-associations-v3-tracking-id-rules-rule-id" [
  tracking_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: put
    path: "/associations/v3/{trackingId}/rules/{ruleId}"
    path_params: [{name: trackingId, var: tracking_id}, {name: ruleId, var: rule_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    tracking_id: $tracking_id, rule_id: $rule_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets sensor rules associated with a device
#
# GET /associations/v3/{trackingId}/sensors
# Returns: record<count: int, pageToken: string, data: table<description: string, id: string, name: string, range: record, threshold: record, type: string>>
export def "get-associations-v3-tracking-id-sensors" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/associations/v3/{trackingId}/sensors"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}, {name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a device and a sensor rule
#
# DELETE /associations/v3/{trackingId}/sensors/{sensorRuleId}
export def "delete-associations-v3-tracking-id-sensors-sensor-rule-id" [
  tracking_id: string
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/associations/v3/{trackingId}/sensors/{sensorRuleId}"
    path_params: [{name: trackingId, var: tracking_id}, {name: sensorRuleId, var: sensor_rule_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, sensor_rule_id: $sensor_rule_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a device with a sensor rule
#
# PUT /associations/v3/{trackingId}/sensors/{sensorRuleId}
export def "put-associations-v3-tracking-id-sensors-sensor-rule-id" [
  tracking_id: string
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: put
    path: "/associations/v3/{trackingId}/sensors/{sensorRuleId}"
    path_params: [{name: trackingId, var: tracking_id}, {name: sensorRuleId, var: sensor_rule_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    tracking_id: $tracking_id, sensor_rule_id: $sensor_rule_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the bulk upload job IDs for a project
#
# GET /bulkjobs/v4/deviceUploads
# Returns: record<count: int, items: table<jobId: string, status: string, type: string>, limit: int, nextPageToken: string>
export def "get-bulkjobs-v4-device-uploads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --type: string@type-completer
  --status: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bulkjobs/v4/deviceUploads"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: limit, var: limit}, {name: type, var: type}, {name: status, var: status}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, limit: $limit, type: $type, status: $status, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts bulk upload
#
# POST /bulkjobs/v4/deviceUploads
# Returns: record<jobId: string>
export def "post-bulkjobs-v4-device-uploads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --file-name: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bulkjobs/v4/deviceUploads"
    query: [{name: projectId, var: project_id}, {name: fileName, var: file_name}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, accepts: list}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_id: $project_id, file_name: $file_name, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates bulk upload job status
#
# PATCH /bulkjobs/v4/deviceUploads/{jobId}
# Returns: record<status: string>
export def "patch-bulkjobs-v4-device-uploads-job-id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  action: string@action-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/bulkjobs/v4/deviceUploads/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, project_id: $project_id, x_request_id: $x_request_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets bulk upload results
#
# GET /bulkjobs/v4/deviceUploads/{jobId}/results
# Returns: record<count: int, items: table<connectorId: string, deviceId: string, deviceSecret: string, errors: list, externalDeviceId: string, externalId: string, name: string, trackingId: string>, limit: int, nextPageToken: string, status: string, type: string>
export def "get-bulkjobs-v4-device-uploads-job-id-results" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bulkjobs/v4/deviceUploads/{jobId}/results"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: limit, var: limit}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, project_id: $project_id, page_token: $page_token, limit: $limit, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets bulk upload status
#
# GET /bulkjobs/v4/deviceUploads/{jobId}/status
# Returns: record<failed: int, fileName: string, partiallySucceeded: int, pending: int, progress: float, status: string, succeeded: int, total: int, type: string>
export def "get-bulkjobs-v4-device-uploads-job-id-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bulkjobs/v4/deviceUploads/{jobId}/status"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, project_id: $project_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /bulkjobs/v4/health
# Returns: record<message: string>
export def "get-bulkjobs-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bulkjobs/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /bulkjobs/v4/version
export def "get-bulkjobs-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/bulkjobs/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Receives external device update reports
#
# POST /c2c/v4/callback
export def "post-c2c-v4-callback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API Key (required)
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/c2c/v4/callback"
    query: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_key: $api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of connectors
#
# GET /c2c/v4/connectors
# Returns: record<count: int, items: table<connectorId: string, projectId: string, description: string, driverId: string, enabled: bool, externalCloudInfo: record, name: string, refreshIntervalS: int, lastExecTs: string, totalAddedDevices: int, createdAt: string>, limit: int, nextPageToken: string>
export def "get-c2c-v4-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/c2c/v4/connectors"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: limit, var: limit}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, limit: $limit, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a connector
#
# POST /c2c/v4/connectors
# Returns: record
export def "post-c2c-v4-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --description: string # Brief description of the connector.
  driver_id: string # Identifier of the driver to be used with this connector.
  --enabled: oneof<nothing, bool> # Enabled state of the connector. If set to false then the connector will not execute periodically.
  external_cloud_info: record # An external cloud-specific object that the driver will use to login to the external cloud. The structure of this object varies per driver implementation. It is recommended to have dedicated credentials for logging in to the external cloud in order not to violate possible concurrent users policies of the external cloud. In case of the HERE Tracking loopback driver, the maximum allowed concurrent user account tokens is 3 per account, therefore it is recommended to create a separate HERE account and grant it the required privilege to update the connector's project, and use that account in externalCloudInfo.
  name: string # Name of the connector.
  --refresh-interval-s: int # This is the interval (in seconds) to execute the sync process between the connector's external cloud and HERE Tracking project. The maximum and at the same time default value for callback-type connectors is 900 seconds. The default value for other type of connectors is 3600 seconds and there is no maximum value set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/c2c/v4/connectors"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: driverId, var: driver_id}, {name: enabled, var: enabled, required: true}, {name: externalCloudInfo, var: external_cloud_info}, {name: name, var: name}, {name: refreshIntervalS, var: refresh_interval_s}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, description: $description, driver_id: $driver_id, enabled: $enabled, external_cloud_info: $external_cloud_info, name: $name, refresh_interval_s: $refresh_interval_s
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets connector identifiers for an external device
#
# GET /c2c/v4/connectors/ext-devices/{externalDeviceId}
# Returns: record<items: table<connectorId: string>>
export def "get-c2c-v4-connectors-ext-devices-external-device-id" [
  external_device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/c2c/v4/connectors/ext-devices/{externalDeviceId}"
    path_params: [{name: externalDeviceId, var: external_device_id}]
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_device_id: $external_device_id, project_id: $project_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a connector
#
# DELETE /c2c/v4/connectors/{connectorId}
export def "delete-c2c-v4-connectors-connector-id" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-devices: oneof<nothing, bool> # Unclaim and unprovision devices
]: nothing -> any {
  http-request {
    method: delete
    path: "/c2c/v4/connectors/{connectorId}"
    path_params: [{name: connectorId, var: connector_id}]
    query: [{name: deleteDevices, var: delete_devices}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    connector_id: $connector_id, delete_devices: $delete_devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a connector info
#
# GET /c2c/v4/connectors/{connectorId}
# Returns: record<connectorId: string, projectId: string, description: string, driverId: string, enabled: bool, externalCloudInfo: record, name: string, refreshIntervalS: int, lastExecTs: string, totalAddedDevices: int, createdAt: string>
export def "get-c2c-v4-connectors-connector-id" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/c2c/v4/connectors/{connectorId}"
    path_params: [{name: connectorId, var: connector_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connector_id: $connector_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a connector info
#
# PUT /c2c/v4/connectors/{connectorId}
# Returns: record
export def "put-c2c-v4-connectors-connector-id" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Brief description of the connector.
  driver_id: string # Identifier of the driver to be used with this connector.
  --enabled: oneof<nothing, bool> # Enabled state of the connector. If set to false then the connector will not execute periodically.
  external_cloud_info: record # An external cloud-specific object that the driver will use to login to the external cloud. The structure of this object varies per driver implementation. It is recommended to have dedicated credentials for logging in to the external cloud in order not to violate possible concurrent users policies of the external cloud. In case of the HERE Tracking loopback driver, the maximum allowed concurrent user account tokens is 3 per account, therefore it is recommended to create a separate HERE account and grant it the required privilege to update the connector's project, and use that account in externalCloudInfo.
  name: string # Name of the connector.
  --refresh-interval-s: int # This is the interval (in seconds) to execute the sync process between the connector's external cloud and HERE Tracking project. The maximum and at the same time default value for callback-type connectors is 900 seconds. The default value for other type of connectors is 3600 seconds and there is no maximum value set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/c2c/v4/connectors/{connectorId}"
    path_params: [{name: connectorId, var: connector_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: driverId, var: driver_id}, {name: enabled, var: enabled, required: true}, {name: externalCloudInfo, var: external_cloud_info}, {name: name, var: name}, {name: refreshIntervalS, var: refresh_interval_s}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connector_id: $connector_id, description: $description, driver_id: $driver_id, enabled: $enabled, external_cloud_info: $external_cloud_info, name: $name, refresh_interval_s: $refresh_interval_s
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all external devices under a connector
#
# GET /c2c/v4/connectors/{connectorId}/ext-devices
# Returns: record<count: int, items: table<enabled: bool, externalDeviceId: string, externalDeviceInfo: record, info: record, localDeviceId: string, provisioning: string>, limit: int, nextPageToken: string>
export def "get-c2c-v4-connectors-connector-id-ext-devices" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/c2c/v4/connectors/{connectorId}/ext-devices"
    path_params: [{name: connectorId, var: connector_id}]
    query: [{name: pageToken, var: page_token}, {name: limit, var: limit}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connector_id: $connector_id, page_token: $page_token, limit: $limit, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds external devices to a connector
#
# POST /c2c/v4/connectors/{connectorId}/ext-devices
export def "post-c2c-v4-connectors-connector-id-ext-devices" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/c2c/v4/connectors/{connectorId}/ext-devices"
    path_params: [{name: connectorId, var: connector_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    connector_id: $connector_id, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a batch of external devices from a connector
#
# DELETE /c2c/v4/connectors/{connectorId}/ext-devices-batch
export def "delete-c2c-v4-connectors-connector-id-ext-devices-batch" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --external-device-ids: list<string>
]: any -> any {
  $in | http-request {
    method: delete
    path: "/c2c/v4/connectors/{connectorId}/ext-devices-batch"
    path_params: [{name: connectorId, var: connector_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalDeviceIds, var: external_device_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    connector_id: $connector_id, x_request_id: $x_request_id, external_device_ids: $external_device_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an external device from a connector
#
# DELETE /c2c/v4/connectors/{connectorId}/ext-devices/{externalDeviceId}
export def "delete-c2c-v4-connectors-connector-id-ext-devices-external-device-id" [
  connector_id: string
  external_device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/c2c/v4/connectors/{connectorId}/ext-devices/{externalDeviceId}"
    path_params: [{name: connectorId, var: connector_id}, {name: externalDeviceId, var: external_device_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    connector_id: $connector_id, external_device_id: $external_device_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of drivers
#
# GET /c2c/v4/drivers
# Returns: record<count: int, items: table<autoProvisionCallbackDevices: bool, driverId: string, driverSyncMethod: string, driverType: string, externalCloudInfoSchema: list, provider: string, strategy: record, version: int>, limit: int, nextPageToken: string>
export def "get-c2c-v4-drivers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/c2c/v4/drivers"
    query: [{name: pageToken, var: page_token}, {name: limit, var: limit}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_token: $page_token, limit: $limit, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate and verify external cloud credentials for driver
#
# POST /c2c/v4/drivers/{driverId}/verify
export def "post-c2c-v4-drivers-driver-id-verify" [
  driver_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/c2c/v4/drivers/{driverId}/verify"
    path_params: [{name: driverId, var: driver_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    driver_id: $driver_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /c2c/v4/health
# Returns: record<message: string>
export def "get-c2c-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/c2c/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /c2c/v4/version
export def "get-c2c-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/c2c/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /device-associations/v2/health
# DEPRECATED
# Returns: record<message: string>
@deprecated
export def "get-device-associations-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/device-associations/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /device-associations/v2/version
# DEPRECATED
@deprecated
export def "get-device-associations-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/device-associations/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets geofences associated with a device
#
# GET /device-associations/v2/{trackingId}/geofences
# DEPRECATED
# Returns: record<count: int, pageToken: string, data: table<geofence: any, id: string>>
@deprecated
export def "get-device-associations-v2-tracking-id-geofences" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/device-associations/v2/{trackingId}/geofences"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: pageToken, var: page_token}, {name: count, var: count}, {name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, page_token: $page_token, count: $count, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets event history
#
# GET /events/v3
# Returns: record<count: int, pageToken: string, data: list<any>>
export def "get-events-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --event-source: string
  --event-type: string
  --rule-id: string
  --initial-state: oneof<nothing, bool>
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 1000)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/v3"
    query: [{name: projectId, var: project_id}, {name: before, var: before}, {name: after, var: after}, {name: eventSource, var: event_source}, {name: eventType, var: event_type}, {name: ruleId, var: rule_id}, {name: initialState, var: initial_state}, {name: pageToken, var: page_token}, {name: count, var: count}, {name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, before: $before, after: $after, event_source: $event_source, event_type: $event_type, rule_id: $rule_id, initial_state: $initial_state, page_token: $page_token, count: $count, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /events/v3/health
# Returns: record<message: string>
export def "get-events-v3-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/v3/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the event statuses
#
# GET /events/v3/statuses
# Returns: record<count: int, pageToken: string, data: list<any>>
export def "get-events-v3-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --event-source: string
  --event-type: string
  --tracking-id: string
  --rule-id: string
  --geofence-id: string
  --shipments: oneof<nothing, bool>
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 1000)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/v3/statuses"
    query: [{name: projectId, var: project_id}, {name: eventSource, var: event_source}, {name: eventType, var: event_type}, {name: trackingId, var: tracking_id}, {name: ruleId, var: rule_id}, {name: geofenceId, var: geofence_id}, {name: shipments, var: shipments}, {name: before, var: before}, {name: after, var: after}, {name: pageToken, var: page_token}, {name: count, var: count}, {name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, event_source: $event_source, event_type: $event_type, tracking_id: $tracking_id, rule_id: $rule_id, geofence_id: $geofence_id, shipments: $shipments, before: $before, after: $after, page_token: $page_token, count: $count, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the number of devices and shipments in each event state
#
# GET /events/v3/statuses/deviceCounts
# Returns: record<count: int, pageToken: string, data: list<any>>
export def "get-events-v3-statuses-device-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --group-by: string@group-by-completer # default: ruleId
  --event-source: string
  --tracking-id: string
  --rule-id: string
  --geofence-id: string
  --shipments: oneof<nothing, bool>
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 1000)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/v3/statuses/deviceCounts"
    query: [{name: projectId, var: project_id}, {name: groupBy, var: group_by}, {name: eventSource, var: event_source}, {name: trackingId, var: tracking_id}, {name: ruleId, var: rule_id}, {name: geofenceId, var: geofence_id}, {name: shipments, var: shipments}, {name: pageToken, var: page_token}, {name: count, var: count}, {name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, group_by: $group_by, event_source: $event_source, tracking_id: $tracking_id, rule_id: $rule_id, geofence_id: $geofence_id, shipments: $shipments, page_token: $page_token, count: $count, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /events/v3/version
export def "get-events-v3-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/events/v3/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets event history for a device or a shipment
#
# GET /events/v3/{trackingId}
# Returns: record<count: int, pageToken: string, data: list<any>>
export def "get-events-v3-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --event-source: string
  --event-type: string
  --rule-id: string
  --initial-state: oneof<nothing, bool>
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 1000)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/v3/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: before, var: before}, {name: after, var: after}, {name: eventSource, var: event_source}, {name: eventType, var: event_type}, {name: ruleId, var: rule_id}, {name: initialState, var: initial_state}, {name: pageToken, var: page_token}, {name: count, var: count}, {name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, before: $before, after: $after, event_source: $event_source, event_type: $event_type, rule_id: $rule_id, initial_state: $initial_state, page_token: $page_token, count: $count, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /geofence-associations/v2/health
# DEPRECATED
# Returns: record<message: string>
@deprecated
export def "get-geofence-associations-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geofence-associations/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /geofence-associations/v2/version
# DEPRECATED
@deprecated
export def "get-geofence-associations-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/geofence-associations/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all devices associated with a geofence
#
# GET /geofence-associations/v2/{geofenceId}/devices
# DEPRECATED
# Returns: record<count: int, pageToken: string, data: table<appId: string, externalId: string, trackingId: string>>
@deprecated
export def "get-geofence-associations-v2-geofence-id-devices" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geofence-associations/v2/{geofenceId}/devices"
    path_params: [{name: geofenceId, var: geofence_id}]
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    geofence_id: $geofence_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a device and a geofence
#
# DELETE /geofence-associations/v2/{geofenceId}/{trackingId}
# DEPRECATED
@deprecated
export def "delete-geofence-associations-v2-geofence-id-tracking-id" [
  geofence_id: string
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/geofence-associations/v2/{geofenceId}/{trackingId}"
    path_params: [{name: geofenceId, var: geofence_id}, {name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    geofence_id: $geofence_id, tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a device with a geofence
#
# PUT /geofence-associations/v2/{geofenceId}/{trackingId}
# DEPRECATED
@deprecated
export def "put-geofence-associations-v2-geofence-id-tracking-id" [
  geofence_id: string
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: put
    path: "/geofence-associations/v2/{geofenceId}/{trackingId}"
    path_params: [{name: geofenceId, var: geofence_id}, {name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    geofence_id: $geofence_id, tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all geofences
#
# DELETE /geofences/v2
export def "delete-geofences-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/geofences/v2"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all geofences
#
# GET /geofences/v2
# Returns: record<count: int, pageToken: string, data: table<geofence: any, id: string>>
export def "get-geofences-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --floor: string # The floor of the indoor geofence (e.g. {id: DM_1234})
  --type: list<string> # Type of a geofence
  --bbox: list<float> # Limit search to geofences intersecting the given bounding box.
  --fields: list<string> # Field names to filter a result object.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geofences/v2"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: count, var: count}, {name: floor, var: floor, style: deepObject}, {name: type, var: type, style: multi}, {name: bbox, var: bbox, style: multi}, {name: fields, var: fields, style: csv}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, count: $count, floor: $floor, type: $type, bbox: $bbox, fields: $fields, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a geofence
#
# POST /geofences/v2
# Returns: record<id: string, message: string>
export def "post-geofences-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --definition: record # An object that defines the area of a circular geofence — shape: {center: record, floor?: record, radius: float}
  --description: string # A description of the area that the geofence encloses and the purpose of the geofence.
  --name: string # A human-readable name of the geofence.
  type: string@type-completer-1 # The geofence type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofences/v2"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: definition, var: definition}, {name: description, var: description}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, definition: $definition, description: $description, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /geofences/v2/health
# Returns: record<message: string>
export def "get-geofences-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geofences/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks if a POI geofence training is possible with the given parameters
#
# POST /geofences/v2/trainingTest
# Returns: record<metadata: record<coordinate: record<lat: float, lng: float>, timestamp: int, trackingId: string, usedWlanApCount: float>, reason: string, success: bool>
export def "post-geofences-v2-training-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --after: int # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The value must be within the past 24 hours from the current timestamp
  --before: int # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The value must not be greater than current timestamp
  --id: string # This is a unique ID associated with the device data in HERE Tracking. For physical devices the `trackingId` gets assigned to a device when the device is claimed by a user, and for virtual devices it is an external device ID along with the device project `appId`.
  --wlan: list # WLAN access points — item shape: {band?: "2.4"|"3.65"|"5", mac: string, powrx: int, timestamp?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofences/v2/trainingTest"
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: after, var: after}, {name: before, var: before}, {name: id, var: id}, {name: wlan, var: wlan}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id, after: $after, before: $before, id: $id, wlan: $wlan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /geofences/v2/version
export def "get-geofences-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/geofences/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a geofence
#
# DELETE /geofences/v2/{geofenceId}
export def "delete-geofences-v2-geofence-id" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/geofences/v2/{geofenceId}"
    path_params: [{name: geofenceId, var: geofence_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    geofence_id: $geofence_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single geofence
#
# GET /geofences/v2/{geofenceId}
# Returns: record<geofence: any, id: string>
export def "get-geofences-v2-geofence-id" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: list<string> # Field names to filter a result object.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geofences/v2/{geofenceId}"
    path_params: [{name: geofenceId, var: geofence_id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    geofence_id: $geofence_id, fields: $fields, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a single geofence
#
# PUT /geofences/v2/{geofenceId}
# Returns: record<geofence: any, id: string>
export def "put-geofences-v2-geofence-id" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --definition: record # An object that defines the area of a circular geofence — shape: {center: record, floor?: record, radius: float}
  --description: string # A description of the area that the geofence encloses and the purpose of the geofence.
  --name: string # A human-readable name of the geofence.
  type: string@type-completer-1 # The geofence type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/geofences/v2/{geofenceId}"
    path_params: [{name: geofenceId, var: geofence_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: definition, var: definition}, {name: description, var: description}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    geofence_id: $geofence_id, x_request_id: $x_request_id, definition: $definition, description: $description, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Trains a POI geofence
#
# POST /geofences/v2/{geofenceId}/poiTraining
# Returns: record<trainingStatus: record<metadata: record<coordinate: record, timestamp: int, trackingId: string, usedWlanApCount: float>, trained: bool>>
export def "post-geofences-v2-geofence-id-poi-training" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --after: int # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The value must be within the past 24 hours from the current timestamp
  --before: int # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The value must not be greater than current timestamp
  --id: string # This is a unique ID associated with the device data in HERE Tracking. For physical devices the `trackingId` gets assigned to a device when the device is claimed by a user, and for virtual devices it is an external device ID along with the device project `appId`.
  --wlan: list # WLAN access points — item shape: {band?: "2.4"|"3.65"|"5", mac: string, powrx: int, timestamp?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofences/v2/{geofenceId}/poiTraining"
    path_params: [{name: geofenceId, var: geofence_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: after, var: after}, {name: before, var: before}, {name: id, var: id}, {name: wlan, var: wlan}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    geofence_id: $geofence_id, x_request_id: $x_request_id, after: $after, before: $before, id: $id, wlan: $wlan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /labels/v4/health
# Returns: record<message: string>
export def "get-labels-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/labels/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /labels/v4/version
export def "get-labels-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/labels/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all labels of a resource type
#
# GET /labels/v4/{resourceType}
# Returns: record<count: int, items: table<labels: record, resourceId: string, resourceType: string>, limit: int, nextPageToken: string>
export def "get-labels-v4-resource-type" [
  resource_type: string@resource-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --labels: record # A filter containing label key-value pairs. (e.g. {group: group1, priority: high})
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --fields: list<string> # Field names to filter a result object.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/labels/v4/{resourceType}"
    path_params: [{name: resourceType, var: resource_type}]
    query: [{name: projectId, var: project_id}, {name: labels, var: labels, style: deepObject}, {name: pageToken, var: page_token}, {name: limit, var: limit}, {name: fields, var: fields, style: csv}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type, project_id: $project_id, labels: $labels, page_token: $page_token, limit: $limit, fields: $fields, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all label keys of a resource type
#
# GET /labels/v4/{resourceType}/keys
# Returns: record<keys: list<string>>
export def "get-labels-v4-resource-type-keys" [
  resource_type: string@resource-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/labels/v4/{resourceType}/keys"
    path_params: [{name: resourceType, var: resource_type}]
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type, project_id: $project_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all values of a label
#
# GET /labels/v4/{resourceType}/keys/{key}/values
# Returns: record<values: list<string>>
export def "get-labels-v4-resource-type-keys-key-values" [
  resource_type: string@resource-type-completer
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/labels/v4/{resourceType}/keys/{key}/values"
    path_params: [{name: resourceType, var: resource_type}, {name: key, var: key}]
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type, key: $key, project_id: $project_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all labels of a resource
#
# DELETE /labels/v4/{resourceType}/{resourceId}
export def "delete-labels-v4-resource-type-resource-id" [
  resource_type: string@resource-type-completer
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/labels/v4/{resourceType}/{resourceId}"
    path_params: [{name: resourceType, var: resource_type}, {name: resourceId, var: resource_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_type: $resource_type, resource_id: $resource_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all labels of a resource
#
# GET /labels/v4/{resourceType}/{resourceId}
# Returns: record<labels: record, resourceId: string, resourceType: string>
export def "get-labels-v4-resource-type-resource-id" [
  resource_type: string@resource-type-completer
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --fields: list<string> # Field names to filter a result object.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/labels/v4/{resourceType}/{resourceId}"
    path_params: [{name: resourceType, var: resource_type}, {name: resourceId, var: resource_id}]
    query: [{name: appId, var: app_id}, {name: fields, var: fields, style: csv}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type, resource_id: $resource_id, app_id: $app_id, fields: $fields, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a set of labels for a resource
#
# PUT /labels/v4/{resourceType}/{resourceId}/batch
# Returns: record<labels: record, resourceId: string, resourceType: string>
export def "put-labels-v4-resource-type-resource-id-batch" [
  resource_type: string@resource-type-completer
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  labels: record # A map of key-value pairs where the key is the label key and the value is an array of label values.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/labels/v4/{resourceType}/{resourceId}/batch"
    path_params: [{name: resourceType, var: resource_type}, {name: resourceId, var: resource_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    resource_type: $resource_type, resource_id: $resource_id, app_id: $app_id, x_request_id: $x_request_id, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all labels of a resource by a label key
#
# DELETE /labels/v4/{resourceType}/{resourceId}/{key}
export def "delete-labels-v4-resource-type-resource-id-key" [
  resource_type: string@resource-type-completer
  resource_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/labels/v4/{resourceType}/{resourceId}/{key}"
    path_params: [{name: resourceType, var: resource_type}, {name: resourceId, var: resource_id}, {name: key, var: key}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_type: $resource_type, resource_id: $resource_id, key: $key, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a label of a resource
#
# DELETE /labels/v4/{resourceType}/{resourceId}/{key}/{value}
export def "delete-labels-v4-resource-type-resource-id-key-value" [
  resource_type: string@resource-type-completer
  resource_id: string
  key: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/labels/v4/{resourceType}/{resourceId}/{key}/{value}"
    path_params: [{name: resourceType, var: resource_type}, {name: resourceId, var: resource_id}, {name: key, var: key}, {name: value, var: value}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_type: $resource_type, resource_id: $resource_id, key: $key, value: $value, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a label for a resource
#
# PUT /labels/v4/{resourceType}/{resourceId}/{key}/{value}
# Returns: record<labels: record, resourceId: string, resourceType: string>
export def "put-labels-v4-resource-type-resource-id-key-value" [
  resource_type: string@resource-type-completer
  resource_id: string
  key: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/labels/v4/{resourceType}/{resourceId}/{key}/{value}"
    path_params: [{name: resourceType, var: resource_type}, {name: resourceId, var: resource_id}, {name: key, var: key}, {name: value, var: value}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    resource_type: $resource_type, resource_id: $resource_id, key: $key, value: $value, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new data upload
#
# POST /largedata/v4
# Returns: record<dataId: string>
export def "post-largedata-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --description: string # Large data object description
  --name: string # Large data object name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/largedata/v4"
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metadata listing for all large data for a device
#
# GET /largedata/v4/devices/{trackingId}/metadata
# Returns: record<count: int, items: table<completedAt: string, createdAt: string, dataId: string, description: string, name: string, numberOfParts: int, size: int, status: string, trackingId: string>, limit: int, nextPageToken: string>
export def "get-largedata-v4-devices-tracking-id-metadata" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/largedata/v4/devices/{trackingId}/metadata"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: pageToken, var: page_token}, {name: limit, var: limit}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, page_token: $page_token, limit: $limit, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /largedata/v4/health
# Returns: record<message: string>
export def "get-largedata-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/largedata/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /largedata/v4/version
export def "get-largedata-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/largedata/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes large data
#
# DELETE /largedata/v4/{dataId}
export def "delete-largedata-v4-data-id" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/largedata/v4/{dataId}"
    path_params: [{name: dataId, var: data_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    data_id: $data_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completes data upload
#
# POST /largedata/v4/{dataId}
export def "post-largedata-v4-data-id" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --abort: oneof<nothing, bool> # default: false
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: post
    path: "/largedata/v4/{dataId}"
    path_params: [{name: dataId, var: data_id}]
    query: [{name: abort, var: abort}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    data_id: $data_id, abort: $abort, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets large data object
#
# GET /largedata/v4/{dataId}/data
# Returns: binary
export def "get-largedata-v4-data-id-data" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --count: int
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: get
    path: "/largedata/v4/{dataId}/data"
    path_params: [{name: dataId, var: data_id}]
    query: [{name: offset, var: offset}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    data_id: $data_id, offset: $offset, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metadata for a large data object
#
# GET /largedata/v4/{dataId}/metadata
# Returns: record<completedAt: string, createdAt: string, dataId: string, description: string, name: string, numberOfParts: int, size: int, status: string, trackingId: string>
export def "get-largedata-v4-data-id-metadata" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/largedata/v4/{dataId}/metadata"
    path_params: [{name: dataId, var: data_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data_id: $data_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets parts information listing for a large data object
#
# GET /largedata/v4/{dataId}/parts
# Returns: record<count: int, items: table<md5: string, partNumber: int, size: int, status: string>, limit: int, nextPageToken: string>
export def "get-largedata-v4-data-id-parts" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/largedata/v4/{dataId}/parts"
    path_params: [{name: dataId, var: data_id}]
    query: [{name: pageToken, var: page_token}, {name: limit, var: limit}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data_id: $data_id, page_token: $page_token, limit: $limit, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a part of a large data
#
# PUT /largedata/v4/{dataId}/parts/{partNumber}
export def "put-largedata-v4-data-id-parts-part-number" [
  data_id: string
  part_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --md5: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/largedata/v4/{dataId}/parts/{partNumber}"
    path_params: [{name: dataId, var: data_id}, {name: partNumber, var: part_number}]
    query: [{name: md5, var: md5}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    data_id: $data_id, part_number: $part_number, md5: $md5, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all locations
#
# DELETE /locations/v4
export def "delete-locations-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/locations/v4"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all locations
#
# GET /locations/v4
# Returns: record<count: int, items: table<address: record, description: string, externalLocationId: string, geofenceId: string, location: record, locationId: string, name: string>, limit: int, nextPageToken: string, total: int>
export def "get-locations-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --limit: int # The number of items to return per page (default: 100)
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --geofence-id: string # Filter the results by `geofenceId` (format: uuid)
  --name: string # Filter locations by name. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *office*)
  --street: string # Filter locations by street address. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *street*)
  --city: string # Filter locations by city. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *city*)
  --postal-code: string # Filter locations by postal code. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *100*)
  --state: string # Filter locations by state. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. New*)
  --country: string # Filter locations by country. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *land*)
  --location-id: string # Filter locations by locationId wildcard. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. LOC-*)
  --sort: string # A paramater to specify field to sort by and order. The following format can be used: 'name:asc' sort by name in ascending order, 'steet:desc' sort by street in descending order. Allowed fields to sort by: locationId, name, street, city, postalCode, state, country. (e.g. name:asc)
  --external-location-id: string # Filter locations by external location id
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locations/v4"
    query: [{name: projectId, var: project_id}, {name: limit, var: limit}, {name: pageToken, var: page_token}, {name: geofenceId, var: geofence_id}, {name: name, var: name}, {name: street, var: street}, {name: city, var: city}, {name: postalCode, var: postal_code}, {name: state, var: state}, {name: country, var: country}, {name: locationId, var: location_id}, {name: sort, var: sort}, {name: externalLocationId, var: external_location_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, limit: $limit, page_token: $page_token, geofence_id: $geofence_id, name: $name, street: $street, city: $city, postal_code: $postal_code, state: $state, country: $country, location_id: $location_id, sort: $sort, external_location_id: $external_location_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a location
#
# POST /locations/v4
# Returns: record<locationId: string>
export def "post-locations-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --address: record # Location address. — shape: {city?: string, country?: string, postalCode?: string, state?: string, street?: string}
  --description: string # Description of the location.
  --external-location-id: string # External location id in external cloud
  --geofence-id: string # Optional geofence ID associated with the location. A geofence with the specified ID must exist. (format: uuid)
  --location: record # Location coordinates. — shape: {lat: float, lng: float}
  --name: string # Name of the location.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/locations/v4"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: description, var: description}, {name: externalLocationId, var: external_location_id}, {name: geofenceId, var: geofence_id}, {name: location, var: location}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, address: $address, description: $description, external_location_id: $external_location_id, geofence_id: $geofence_id, location: $location, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /locations/v4/health
# Returns: record<message: string>
export def "get-locations-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locations/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /locations/v4/version
export def "get-locations-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/locations/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a location
#
# DELETE /locations/v4/{locationId}
export def "delete-locations-v4-location-id" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/locations/v4/{locationId}"
    path_params: [{name: locationId, var: location_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a location details
#
# GET /locations/v4/{locationId}
# Returns: record<address: record<city: string, country: string, postalCode: string, state: string, street: string>, description: string, externalLocationId: string, geofenceId: string, location: record<lat: float, lng: float>, locationId: string, name: string>
export def "get-locations-v4-location-id" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locations/v4/{locationId}"
    path_params: [{name: locationId, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a location details
#
# PUT /locations/v4/{locationId}
# Returns: record<address: record<city: string, country: string, postalCode: string, state: string, street: string>, description: string, externalLocationId: string, geofenceId: string, location: record<lat: float, lng: float>, locationId: string, name: string>
export def "put-locations-v4-location-id" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # Location address. — shape: {city?: string, country?: string, postalCode?: string, state?: string, street?: string}
  --description: string # Description of the location.
  --external-location-id: string # External location id in external cloud
  --geofence-id: string # Optional geofence ID associated with the location. A geofence with the specified ID must exist. (format: uuid)
  --location: record # Location coordinates. — shape: {lat: float, lng: float}
  --name: string # Name of the location.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/locations/v4/{locationId}"
    path_params: [{name: locationId, var: location_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: description, var: description}, {name: externalLocationId, var: external_location_id}, {name: geofenceId, var: geofence_id}, {name: location, var: location}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, address: $address, description: $description, external_location_id: $external_location_id, geofence_id: $geofence_id, location: $location, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a batch of metadata of multiple devices or shipments
#
# POST /metadata/v2/devices/batch
# Returns: record<count: int, pageToken: string, data: table<data: record, id: string>>
export def "post-metadata-v2-devices-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/v2/devices/batch"
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_token: $page_token, count: $count, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all metadata of a device or a shipment
#
# DELETE /metadata/v2/devices/{trackingId}
export def "delete-metadata-v2-devices-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/metadata/v2/devices/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metadata of a device or a shipment
#
# GET /metadata/v2/devices/{trackingId}
# Returns: record<data: record, id: string>
export def "get-metadata-v2-devices-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/v2/devices/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates metadata of a device or a shipment
#
# PUT /metadata/v2/devices/{trackingId}
# Returns: record<data: record, id: string>
export def "put-metadata-v2-devices-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/metadata/v2/devices/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a batch of metadata of multiple geofences
#
# POST /metadata/v2/geofences/batch
# Returns: record<count: int, pageToken: string, data: table<data: record, id: string>>
export def "post-metadata-v2-geofences-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/v2/geofences/batch"
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_token: $page_token, count: $count, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all metadata of a geofence
#
# DELETE /metadata/v2/geofences/{geofenceId}
export def "delete-metadata-v2-geofences-geofence-id" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/metadata/v2/geofences/{geofenceId}"
    path_params: [{name: geofenceId, var: geofence_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    geofence_id: $geofence_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metadata of a geofence
#
# GET /metadata/v2/geofences/{geofenceId}
# Returns: record<data: record, id: string>
export def "get-metadata-v2-geofences-geofence-id" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/v2/geofences/{geofenceId}"
    path_params: [{name: geofenceId, var: geofence_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    geofence_id: $geofence_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates metadata of a geofence
#
# PUT /metadata/v2/geofences/{geofenceId}
# Returns: record<data: record, id: string>
export def "put-metadata-v2-geofences-geofence-id" [
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/metadata/v2/geofences/{geofenceId}"
    path_params: [{name: geofenceId, var: geofence_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    geofence_id: $geofence_id, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /metadata/v2/health
# Returns: record<message: string>
export def "get-metadata-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a batch of metadata for multiple sensor rules
#
# POST /metadata/v2/sensorRules/batch
# Returns: record<count: int, pageToken: string, data: table<data: record, id: string>>
export def "post-metadata-v2-sensor-rules-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/v2/sensorRules/batch"
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_token: $page_token, count: $count, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all metadata of a sensor rule
#
# DELETE /metadata/v2/sensorRules/{sensorRuleId}
export def "delete-metadata-v2-sensor-rules-sensor-rule-id" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/metadata/v2/sensorRules/{sensorRuleId}"
    path_params: [{name: sensorRuleId, var: sensor_rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    sensor_rule_id: $sensor_rule_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metadata of a sensor rule
#
# GET /metadata/v2/sensorRules/{sensorRuleId}
# Returns: record<data: record, id: string>
export def "get-metadata-v2-sensor-rules-sensor-rule-id" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/v2/sensorRules/{sensorRuleId}"
    path_params: [{name: sensorRuleId, var: sensor_rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sensor_rule_id: $sensor_rule_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates metadata of a sensor rule
#
# PUT /metadata/v2/sensorRules/{sensorRuleId}
# Returns: record<data: record, id: string>
export def "put-metadata-v2-sensor-rules-sensor-rule-id" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/metadata/v2/sensorRules/{sensorRuleId}"
    path_params: [{name: sensorRuleId, var: sensor_rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sensor_rule_id: $sensor_rule_id, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /metadata/v2/version
export def "get-metadata-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/metadata/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /notifications/v3/health
# Returns: record<message: string>
export def "get-notifications-v3-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/v3/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregisters from notifications
#
# DELETE /notifications/v3/registration/{channelId}
export def "delete-notifications-v3-registration-channel-id" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/notifications/v3/registration/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single notification channel information
#
# GET /notifications/v3/registration/{channelId}
# Returns: record<registration: any>
export def "get-notifications-v3-registration-channel-id" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/v3/registration/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a notification channel
#
# PUT /notifications/v3/registration/{channelId}
# Returns: record<registration: any>
export def "put-notifications-v3-registration-channel-id" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  channel_type: string@channel-type-completer # The type of notification channel.
  --event-source: string@event-source-completer # The event source rule type.
  --event-type: string@event-type-completer # Type of the event. An event is created every time an associated rule or geofence is triggered by a device ingestion. The event type depends on the data the device sends. Sensors that report numerical data (such as battery, humidity, pressure and temperature sensors), generate an event when the reported sensor reading of the device goes in or out of range, which is configured in the rule. This produces events of BELOW_RANGE, IN_RANGE and ABOVE_RANGE types. Sensors that report boolean data (such as attach and tamper sensors), generate events when the device transitions from one state to another, either from `false` to `true` or vice versa. This produces events of FALSE_TO_TRUE and TRUE_TO_FALSE types. The same event types are also generated by the online rule when the device state changes from `offline` (when the device has stopped ingesting data) to `online` (when the device data ingestion has resumed) or vice versa. The acceleration sensor generates events whenever the reported sensor reading crosses the acceleration threshold (for example, when the device was dropped). This produces events of the type EVENT. Such events are stateless. Events of INSIDE_GEOFENCE and OUTSIDE_GEOFENCE types are generated when the device enters or exits a geofence associated with the device. Events of DWELLING_STARTED type are generated when the device has stayed inside an associated geofence for longer than the threshold duration. DWELLING_ENDED type events are generated when dwelling of the device has ended. Events of DETENTION_STARTED type are generated when the device has been stationary for longer than the threshold duration, regardless whether the device is inside or outside of any geofence. DETENTION_ENDED type events will be generated when the device starts moving again. Events of UNUTILIZED type are generated when the device has been stationary for longer than the threshold duration. UTILIZED type events are generated when the device starts moving again after having been stationary. Events of OVERSTOCK, NORMAL_VOLUME and UNDERSTOCK types are generated when the number of assets inside a geofence crosses the `minVolume` and `maxVolume` thresholds of an associated stock rule. Events of SHIPMENT_EARLY, SHIPMENT_ON_TIME and SHIPMENT_DELAYED types are generated when a shipment is too early, on time or delayed.
  --initial-state: oneof<nothing, bool> # Events with the `initialState` property set as `true` are generated when the rule is evaluated for the first time. It indicates the fact that this is the initial evaluation state, which would serve as a starting point for the subsequent rule evaluations. The rest of the rule events would represent a transition of a device or a shipment or a geofence from one state to another and their `initialState` property will be set to `false`.
  --rule-id: string # Must be a valid UUIDv4. (format: uuid)
  --url: string # A webhook URL that will receive notifications POST requests.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/notifications/v3/registration/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelType, var: channel_type}, {name: eventSource, var: event_source}, {name: eventType, var: event_type}, {name: initialState, var: initial_state}, {name: ruleId, var: rule_id}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_request_id: $x_request_id, channel_type: $channel_type, event_source: $event_source, event_type: $event_type, initial_state: $initial_state, rule_id: $rule_id, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregisters from all notifications
#
# DELETE /notifications/v3/registrations
export def "delete-notifications-v3-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/notifications/v3/registrations"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all registered notification channels
#
# GET /notifications/v3/registrations
# Returns: record<count: int, pageToken: string, data: list<any>>
export def "get-notifications-v3-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --project-id: string
  --channel-type: list<string> # Filter result by channelType. Example: `channelType[]=webhook`, `channelType[]=browserPull,email`
  --user-id: string # User ID. Can be used by the project admin to filter email and browser pull notification channels by subscriber.
  --email-bounce: oneof<nothing, bool> # Filters by `emailBounce` property. When set to `true`, returns the email channels which are not active anymore due to email bounce. When set to `false`, returns all the channels which are active (and not only email channels).
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/v3/registrations"
    query: [{name: pageToken, var: page_token}, {name: count, var: count}, {name: projectId, var: project_id}, {name: channelType, var: channel_type, style: multi}, {name: userId, var: user_id}, {name: emailBounce, var: email_bounce}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_token: $page_token, count: $count, project_id: $project_id, channel_type: $channel_type, user_id: $user_id, email_bounce: $email_bounce, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers for notifications
#
# POST /notifications/v3/registrations
# Returns: record<registration: any>
export def "post-notifications-v3-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --user-id: string # User Id.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  channel_type: string@channel-type-completer # The type of notification channel.
  --event-source: string@event-source-completer # The event source rule type.
  --event-type: string@event-type-completer # Type of the event. An event is created every time an associated rule or geofence is triggered by a device ingestion. The event type depends on the data the device sends. Sensors that report numerical data (such as battery, humidity, pressure and temperature sensors), generate an event when the reported sensor reading of the device goes in or out of range, which is configured in the rule. This produces events of BELOW_RANGE, IN_RANGE and ABOVE_RANGE types. Sensors that report boolean data (such as attach and tamper sensors), generate events when the device transitions from one state to another, either from `false` to `true` or vice versa. This produces events of FALSE_TO_TRUE and TRUE_TO_FALSE types. The same event types are also generated by the online rule when the device state changes from `offline` (when the device has stopped ingesting data) to `online` (when the device data ingestion has resumed) or vice versa. The acceleration sensor generates events whenever the reported sensor reading crosses the acceleration threshold (for example, when the device was dropped). This produces events of the type EVENT. Such events are stateless. Events of INSIDE_GEOFENCE and OUTSIDE_GEOFENCE types are generated when the device enters or exits a geofence associated with the device. Events of DWELLING_STARTED type are generated when the device has stayed inside an associated geofence for longer than the threshold duration. DWELLING_ENDED type events are generated when dwelling of the device has ended. Events of DETENTION_STARTED type are generated when the device has been stationary for longer than the threshold duration, regardless whether the device is inside or outside of any geofence. DETENTION_ENDED type events will be generated when the device starts moving again. Events of UNUTILIZED type are generated when the device has been stationary for longer than the threshold duration. UTILIZED type events are generated when the device starts moving again after having been stationary. Events of OVERSTOCK, NORMAL_VOLUME and UNDERSTOCK types are generated when the number of assets inside a geofence crosses the `minVolume` and `maxVolume` thresholds of an associated stock rule. Events of SHIPMENT_EARLY, SHIPMENT_ON_TIME and SHIPMENT_DELAYED types are generated when a shipment is too early, on time or delayed.
  --initial-state: oneof<nothing, bool> # Events with the `initialState` property set as `true` are generated when the rule is evaluated for the first time. It indicates the fact that this is the initial evaluation state, which would serve as a starting point for the subsequent rule evaluations. The rest of the rule events would represent a transition of a device or a shipment or a geofence from one state to another and their `initialState` property will be set to `false`.
  --rule-id: string # Must be a valid UUIDv4. (format: uuid)
  --url: string # A webhook URL that will receive notifications POST requests.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notifications/v3/registrations"
    query: [{name: projectId, var: project_id}, {name: userId, var: user_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelType, var: channel_type}, {name: eventSource, var: event_source}, {name: eventType, var: event_type}, {name: initialState, var: initial_state}, {name: ruleId, var: rule_id}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, user_id: $user_id, x_request_id: $x_request_id, channel_type: $channel_type, event_source: $event_source, event_type: $event_type, initial_state: $initial_state, rule_id: $rule_id, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /notifications/v3/version
export def "get-notifications-v3-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/v3/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates a device.
#
# DELETE /registry/v2/devices/{deviceOrExternalId}
export def "delete-registry-v2-devices-device-or-external-id" [
  device_or_external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/registry/v2/devices/{deviceOrExternalId}"
    path_params: [{name: deviceOrExternalId, var: device_or_external_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    device_or_external_id: $device_or_external_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the trackingId for a device
#
# GET /registry/v2/devices/{deviceOrExternalId}
# Returns: record<trackingId: string>
export def "get-registry-v2-devices-device-or-external-id" [
  device_or_external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/v2/devices/{deviceOrExternalId}"
    path_params: [{name: deviceOrExternalId, var: device_or_external_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device_or_external_id: $device_or_external_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claims a device
#
# PUT /registry/v2/devices/{deviceOrExternalId}
# Returns: record<trackingId: string>
export def "put-registry-v2-devices-device-or-external-id" [
  device_or_external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --owner-app-id: string # (Deprecated) Application identifier which specifies device owner's application to which the device is associated with.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/registry/v2/devices/{deviceOrExternalId}"
    path_params: [{name: deviceOrExternalId, var: device_or_external_id}]
    query: [{name: appId, var: app_id}, {name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ownerAppId, var: owner_app_id}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    device_or_external_id: $device_or_external_id, app_id: $app_id, project_id: $project_id, x_request_id: $x_request_id, owner_app_id: $owner_app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /registry/v2/health
# Returns: record<message: string>
export def "get-registry-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list user projects along with the license information
#
# GET /registry/v2/licenses
# Returns: record<end: int, licenses: table<appId: string, expired: bool, expiryDate: string, features: list, projectDescription: string, projectHrn: string, projectId: string, projectName: string, quota: record, realm: string, type: string>, start: int, total: int>
export def "get-registry-v2-licenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # default: 0
  --end-index: int # default: 100
  --project-ids: string
  --project-types: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/v2/licenses"
    query: [{name: startIndex, var: start_index}, {name: endIndex, var: end_index}, {name: projectIds, var: project_ids}, {name: projectTypes, var: project_types}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_index: $start_index, end_index: $end_index, project_ids: $project_ids, project_types: $project_types, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /registry/v2/version
export def "get-registry-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/registry/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the devices provisioned by a user
#
# GET /registry/v2/{appId}/devices
# Returns: record<count: int, pageToken: string, data: table<appId: string, deviceId: string, externalId: string, timestamp: int>>
export def "get-registry-v2-app-id-devices" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/v2/{appId}/devices"
    path_params: [{name: appId, var: app_id}]
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates licenses for multiple devices
#
# POST /registry/v2/{appId}/devices
# Returns: record<jobId: string>
export def "post-registry-v2-app-id-devices" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoclaim: oneof<nothing, bool> # If set to `true`, the licenses are created and devices are immediately claimed by the same user. Supported only with `deviceId` array in body, and not with the `count` parameter. (default: false)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --count: int # Number of device credentials requested
  --devices: list # item shape: {id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/registry/v2/{appId}/devices"
    path_params: [{name: appId, var: app_id}]
    query: [{name: autoclaim, var: autoclaim}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: devices, var: devices}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    app_id: $app_id, autoclaim: $autoclaim, x_request_id: $x_request_id, count: $count, devices: $devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a number of device licenses provisioned by a user
#
# GET /registry/v2/{appId}/licenseCount
# Returns: record<count: float, updatedAt: string>
export def "get-registry-v2-app-id-license-count" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/v2/{appId}/licenseCount"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a license for a single physical device
#
# POST /registry/v2/{appId}/one-device
# Returns: record<deviceId: string, deviceSecret: string, trackingId: string>
export def "post-registry-v2-app-id-one-device" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoclaim: oneof<nothing, bool> # If set to `true`, the device license is created and the device is immediately claimed by the same user. (default: false)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/registry/v2/{appId}/one-device"
    path_params: [{name: appId, var: app_id}]
    query: [{name: autoclaim, var: autoclaim}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    app_id: $app_id, autoclaim: $autoclaim, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the multiple device license request job results
#
# GET /registry/v2/{jobId}/results
# Returns: record<count: int, pageToken: string, data: table<deviceId: string, deviceSecret: string, externalId: string, trackingId: string>, errors: table<error: record, id: string>>
export def "get-registry-v2-job-id-results" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/v2/{jobId}/results"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the multiple device license request job status
#
# GET /registry/v2/{jobId}/status
# Returns: record<percent: float, status: string>
export def "get-registry-v2-job-id-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/v2/{jobId}/status"
    path_params: [{name: jobId, var: job_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unclaims a device
#
# DELETE /registry/v2/{trackingId}
export def "delete-registry-v2-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/registry/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the deviceId
#
# GET /registry/v2/{trackingId}
# Returns: record<deviceId: string>
export def "get-registry-v2-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all resources of a resource type
#
# POST /registry/v4/resources/{resourceType}/find
# Returns: record<count: int, items: table<resourceId: string>, limit: int, nextPageToken: string, total: int>
export def "post-registry-v4-resources-resource-type-find" [
  resource_type: string@resource-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  filters: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/registry/v4/resources/{resourceType}/find"
    path_params: [{name: resourceType, var: resource_type}]
    query: [{name: pageToken, var: page_token}, {name: limit, var: limit}, {name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type, page_token: $page_token, limit: $limit, project_id: $project_id, x_request_id: $x_request_id, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts report creation
#
# POST /reports/v4
# Returns: record<reportId: string>
export def "post-reports-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  end: string # End date of the report period. The end date should be greater than the start date. (format: date-time)
  rule_id: string # Rule ID of a dwelling or detention rule. (format: uuid)
  start: string # Start date and time of the report period. When getting reports per interval, this timestamp defines the start of the interval day, week or month. For example, to make the report week start on Monday midnight 1st March 2021 in timezone UTC+1:00, set the `start` parameter to be `2021-02-28T23:00:00.000Z` (GMT). Now when getting interval reports, the first week would contain data between `2021-02-28T23:00:00.000Z` and `2021-03-07T23:00:00.000Z` (GMT). (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/v4"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: end, var: end}, {name: ruleId, var: rule_id}, {name: start, var: start}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, end: $end, rule_id: $rule_id, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /reports/v4/health
# Returns: record<message: string>
export def "get-reports-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /reports/v4/version
export def "get-reports-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/reports/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets reports
#
# GET /reports/v4/{reportId}
# Returns: record<count: int, items: list<any>, limit: int, nextPageToken: string, status: string>
export def "get-reports-v4-report-id" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --measure: string@measure-completer # Defines the report metric to be calculated. The metrics are always calculated over a time period, either over each interval specified by the `interval` parameter (for example, over a week) or over the whole time period of the report. * `duration`: duration of the event * _"The asset dwelled for 45 hours during week 2. It was in detention for 4 hours."_ * `occurrence`: total number of the event occurrences * _"During week 3, the asset was in detention 2 times. During the past month it had 7 individual dwelling periods."_ * `day`: the number of days the event lasted * _"The asset was utilized for 3 days during week 4."_ * `asset`: the number of assets that generated the event * _"On Monday 5 assets were in detention. On Tuesday 16 assets were in detention."_
  --interval: string@interval-completer # Defines an interval, which can be a day, a week or a month, that will be used to group the report results. When the `interval` parameter is provided, the response will be an array of `timestamp`-`value` pairs where the `timestamp` defines the beginning of the interval and the `value` is the specified report metric's value calculated over the interval time.
  --tracking-id: string # Tracking ID. Provide a tracking ID to get a report on a specific asset. > Note that in the report context an asset is a device. For example, to get a report on how many times the specified asset was in detention during each week, create a request specifying the following: * `reportId`: ID of a report created for a detention rule * `trackingId`: tracking ID * `measure`: 'occurrence' * `interval`: 'week'
  --geofence-id: string # ID of the geofence. One can provide a geofence ID in case one wants to get reports on a specific geofence. This parameter can only be used with reports created for a dwelling rule type. For example, to get a report on assets' average dwelling time in the specified geofence during each week, create a request specifying the following: * `reportId`: ID of a report created for a dwelling rule * `measure`: 'duration' * `groupBy`: 'asset' * `interval`: 'week' * `method`: 'average' * `geofenceId`: geofence ID (format: uuid)
  --group-by: string@group-by-completer-1 # Defines whether the report metrics, such as cumulative or average, are calculated per asset or per geofence. The parameter can have a value 'geofence' only with reports created for a dwelling rule. To get a report on how many times on average assets were in detention during each time interval, create a request specifying the following: * `reportId`: ID of a report created for a detention rule * `groupBy`: 'asset' * `method`: 'average' * `measure`: 'occurrence' To get a report on how long all assets dwelled inside each geofence during the report period, create a request specifying the following: * `reportId`: ID of a report created for a dwelling rule * `groupBy`: 'geofence' * `measure`: 'duration' To get a report on how long each asset dwelled (inside any geofence) during the report period, create a request specifying the following: * `reportId`: ID of a report created for a dwelling rule * `groupBy`: 'asset' * `measure`: 'duration'
  --method: string@method-completer # Defines the calculation method. The parameter `method` can only be provided along with `interval`. The parameter value can be `percentage` only when `measure` is 'asset'. For example, to get a report on percentage of all assets that were in use during each week, create a request specifying the following: * `reportId`: ID of a report created for a utilization rule * `interval`: 'week' * `method`: 'percentage' * `measure`: 'asset' When `method` is set to 'cumulative' or 'average' and `measure` is set to 'duration' or 'occurrence', the `groupBy` parameter needs to be provided also. For example, to get a report on how long all assets dwelled in total in the specified geofence during each week, create a request specifying the following: * `reportId`: ID of a report created for a dwelling rule * `geofenceId`: ID of a geofence * `interval`: 'week' * `method`: 'cumulative' * `measure`: 'duration' * `groupBy`: 'asset' When `method` is set to 'cumulative' or 'average' and `measure` is set to 'day', the `groupBy` parameter is automatically set to 'asset'. For example, to get a report on how many days on average assets were in use during each month, create a request specifying the following: * `reportId`: ID of a report created for a utilization rule * `interval`: 'month' * `method`: 'average' * `measure`: 'day' * `groupBy`: 'asset'
  --sort: string # Defines how the items are sorted. * If `interval` is provided, the default is `sort`=`timestamp:asc` * If `interval` is not provided, the default is `sort`=`value:desc` (e.g. timestamp:asc)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/v4/{reportId}"
    path_params: [{name: reportId, var: report_id}]
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: limit, var: limit}, {name: measure, var: measure}, {name: interval, var: interval}, {name: trackingId, var: tracking_id}, {name: geofenceId, var: geofence_id}, {name: groupBy, var: group_by}, {name: method, var: method}, {name: sort, var: sort}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    report_id: $report_id, project_id: $project_id, page_token: $page_token, limit: $limit, measure: $measure, interval: $interval, tracking_id: $tracking_id, geofence_id: $geofence_id, group_by: $group_by, method: $method, sort: $sort, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all rules
#
# DELETE /rules/v4
export def "delete-rules-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/rules/v4"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all rules
#
# GET /rules/v4
# Returns: record<count: int, items: table<rule: any, ruleId: string>, limit: int, nextPageToken: string>
export def "get-rules-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rules/v4"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: limit, var: limit}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, limit: $limit, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a rule
#
# POST /rules/v4
# Returns: record<ruleId: string>
export def "post-rules-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --description: string # Rule description
  --name: string # Rule name
  --threshold: record # Utilization event is triggered when the asset starts moving indicating that the asset is utilized, and also when the asset stops moving and has been stationary for longer than the threshold duration indicating that the asset is unutilized. — shape: {durationS: int}
  type: string@type-completer-2 # The rule type
  --geofence-id: string # Geofence ID (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rules/v4"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: threshold, var: threshold}, {name: type, var: type}, {name: geofenceId, var: geofence_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, description: $description, name: $name, threshold: $threshold, type: $type, geofence_id: $geofence_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /rules/v4/health
# Returns: record<message: string>
export def "get-rules-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rules/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /rules/v4/version
export def "get-rules-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/rules/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a rule
#
# DELETE /rules/v4/{ruleId}
export def "delete-rules-v4-rule-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/rules/v4/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    rule_id: $rule_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single rule
#
# GET /rules/v4/{ruleId}
# Returns: record<rule: any, ruleId: string>
export def "get-rules-v4-rule-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rules/v4/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a single rule
#
# PUT /rules/v4/{ruleId}
# Returns: record<rule: any, ruleId: string>
export def "put-rules-v4-rule-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --description: string # Rule description
  --name: string # Rule name
  --threshold: record # Utilization event is triggered when the asset starts moving indicating that the asset is utilized, and also when the asset stops moving and has been stationary for longer than the threshold duration indicating that the asset is unutilized. — shape: {durationS: int}
  type: string@type-completer-2 # The rule type
  --geofence-id: string # Geofence ID (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/rules/v4/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: threshold, var: threshold}, {name: type, var: type}, {name: geofenceId, var: geofence_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id, x_request_id: $x_request_id, description: $description, name: $name, threshold: $threshold, type: $type, geofence_id: $geofence_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all sensor rules
#
# DELETE /sensors/v3
export def "delete-sensors-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/sensors/v3"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all sensor rules
#
# GET /sensors/v3
# Returns: record<count: int, pageToken: string, data: table<description: string, id: string, name: string, range: record, threshold: record, type: string>>
export def "get-sensors-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sensors/v3"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a sensor rule
#
# POST /sensors/v3
# Returns: record<id: string, message: string>
export def "post-sensors-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --description: string # Sensor rule description
  --name: string # Sensor rule name
  --range: record # shape: {begin: float, end: float}
  type: string@type-completer-3 # The sensor type.
  --threshold: record # shape: {value: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sensors/v3"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: range, var: range}, {name: type, var: type}, {name: threshold, var: threshold}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, description: $description, name: $name, range: $range, type: $type, threshold: $threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /sensors/v3/health
# Returns: record<message: string>
export def "get-sensors-v3-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sensors/v3/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /sensors/v3/version
export def "get-sensors-v3-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/sensors/v3/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a sensor rule
#
# DELETE /sensors/v3/{sensorRuleId}
export def "delete-sensors-v3-sensor-rule-id" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/sensors/v3/{sensorRuleId}"
    path_params: [{name: sensorRuleId, var: sensor_rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    sensor_rule_id: $sensor_rule_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single sensor rule
#
# GET /sensors/v3/{sensorRuleId}
# Returns: record<description: string, id: string, name: string, range: record<begin: float, end: float>, threshold: record<value: float>, type: string>
export def "get-sensors-v3-sensor-rule-id" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sensors/v3/{sensorRuleId}"
    path_params: [{name: sensorRuleId, var: sensor_rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sensor_rule_id: $sensor_rule_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a single sensor rule
#
# PUT /sensors/v3/{sensorRuleId}
# Returns: record<message: string, description: string, id: string, name: string, range: record<begin: float, end: float>, threshold: record<value: float>, type: string>
export def "put-sensors-v3-sensor-rule-id" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --description: string # Sensor rule description
  --name: string # Sensor rule name
  --range: record # shape: {begin: float, end: float}
  type: string@type-completer-3 # The sensor type.
  --threshold: record # shape: {value: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sensors/v3/{sensorRuleId}"
    path_params: [{name: sensorRuleId, var: sensor_rule_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: range, var: range}, {name: type, var: type}, {name: threshold, var: threshold}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sensor_rule_id: $sensor_rule_id, x_request_id: $x_request_id, description: $description, name: $name, range: $range, type: $type, threshold: $threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a batch of device shadows
#
# POST /shadows/v2/batch
# Returns: table<appId: string, body: record<desired: record, reported: record>, externalId: string, statusCode: int, trackingId: string>
export def "post-shadows-v2-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shadows/v2/batch"
    query: [{name: after, var: after}, {name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    after: $after, app_id: $app_id, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /shadows/v2/health
# Returns: record<message: string>
export def "get-shadows-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shadows/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /shadows/v2/version
export def "get-shadows-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/shadows/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears a device shadow
#
# DELETE /shadows/v2/{trackingId}
export def "delete-shadows-v2-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --desired: oneof<nothing, bool> # If `true`, all the values of the `desired` shadow will be cleared (default: true)
  --reported: oneof<nothing, bool> # If `true`, all the values of the `reported` shadow will be cleared (default: true)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/shadows/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}, {name: desired, var: desired}, {name: reported, var: reported}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, desired: $desired, reported: $reported, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a device shadow
#
# GET /shadows/v2/{trackingId}
# Returns: record<desired: record<payload: record, system: record<detectOutliers: bool, disableTracking: record, lastModifiedGeofenceTimestamp: int, rate: record, sensorAlarmConfig: record, sensorLoggingConfigurations: list, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list, wlanConnectivityEnabled: bool>, timestamp: int>, reported: record<payload: record, position: record<accuracy: float, alt: float, altaccuracy: float, confidence: int, floor: record, heading: int, lat: float, lng: float, satellitecount: int, speed: int, timestamp: int, type: string, wlancount: int>, system: record<client: record, computed: record, iccid: string, imsi: string, mode: string, phoneNumber: string, reportedSensorData: record, stateVersion: int>, timestamp: int>>
export def "get-shadows-v2-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shadows/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a device shadow
#
# PUT /shadows/v2/{trackingId}
# Returns: record<desired: record<payload: record, system: record<detectOutliers: bool, disableTracking: record, lastModifiedGeofenceTimestamp: int, rate: record, sensorAlarmConfig: record, sensorLoggingConfigurations: list, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list, wlanConnectivityEnabled: bool>, timestamp: int>, reported: record<payload: record, position: record<accuracy: float, alt: float, altaccuracy: float, confidence: int, floor: record, heading: int, lat: float, lng: float, satellitecount: int, speed: int, timestamp: int, type: string, wlancount: int>, system: record<client: record, computed: record, iccid: string, imsi: string, mode: string, phoneNumber: string, reportedSensorData: record, stateVersion: int>, timestamp: int>>
export def "put-shadows-v2-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --content-length: float # The size of the shadow in bytes. The size is validated against the maximum limit of 1000 bytes. (required)
  desired: record # The desired shadow of the device. — shape: {payload?: record, system?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/shadows/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: content-length, var: content_length, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: desired, var: desired}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id, content_length: $content_length, desired: $desired
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets reported or desired state object of a device
#
# GET /shadows/v2/{trackingId}/{state}
export def "get-shadows-v2-tracking-id-state" [
  tracking_id: string
  state: string@state-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: get
    path: "/shadows/v2/{trackingId}/{state}"
    path_params: [{name: trackingId, var: tracking_id}, {name: state, var: state}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, state: $state, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a value of a shadow property
#
# GET /shadows/v2/{trackingId}/{state}/{selector}
export def "get-shadows-v2-tracking-id-state-selector" [
  tracking_id: string
  state: string@state-completer
  selector: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: get
    path: "/shadows/v2/{trackingId}/{state}/{selector}"
    path_params: [{name: trackingId, var: tracking_id}, {name: state, var: state}, {name: selector, var: selector}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, state: $state, selector: $selector, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all shadows
#
# GET /shadows/v4
# Returns: record<count: int, items: table<appId: string, externalId: string, shadow: record, trackingId: string>, limit: int, nextPageToken: string>
export def "get-shadows-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --after: string # If provided returns the shadows for which `reported.timestamp` is greater than given `after` parameter. (format: date-time)
  --sort: string # Defines how the items are sorted. The default sort is `sort=trackingId:asc` (e.g. reported.timestamp:desc)
  --bbox: list<float> # Limit search to shadows, whose position intersects the given bounding box. The `bbox` array consist of latitude and longitude of Northwest and Southeast corners. (e.g. 61.494750,23.775189,61.494611,23.774758)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shadows/v4"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: limit, var: limit}, {name: after, var: after}, {name: sort, var: sort}, {name: bbox, var: bbox, style: multi}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, limit: $limit, after: $after, sort: $sort, bbox: $bbox, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts shipment report generation
#
# POST /shipment-reports/v4
# Returns: record<shipmentReportId: string>
export def "post-shipment-reports-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --ended-after: string # Include successfully completed shipments of each shipment plan into the shipment report generation which ended after the provided date. (format: date-time)
  --ended-before: string # Include successfully completed shipments of each shipment plan into the shipment report generation which ended before the provided date. (format: date-time)
  --shipment-plan-ids: list<string> # Provide array of shipment plan ids to include into the shipment report. If just a single shipment plan id is given, then the shipment report will include only metrics and shipments for the given shipment plan. If none is given, then the shipment report will include all shipment plans.
  --started-after: string # Include successfully completed shipments of each shipment plan into the shipment report generation which started after the provided date. (format: date-time)
  --started-before: string # Include successfully completed shipments of each shipment plan into the shipment report generation which started before the provided date. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shipment-reports/v4"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endedAfter, var: ended_after}, {name: endedBefore, var: ended_before}, {name: shipmentPlanIds, var: shipment_plan_ids}, {name: startedAfter, var: started_after}, {name: startedBefore, var: started_before}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, ended_after: $ended_after, ended_before: $ended_before, shipment_plan_ids: $shipment_plan_ids, started_after: $started_after, started_before: $started_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /shipment-reports/v4/health
# Returns: record<message: string>
export def "get-shipment-reports-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipment-reports/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /shipment-reports/v4/version
export def "get-shipment-reports-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/shipment-reports/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets status of generation of the shipment report
#
# GET /shipment-reports/v4/{shipmentReportId}/status
# Returns: record<error: record<code: int, details: any, error: string, id: string, message: string>, status: string>
export def "get-shipment-reports-v4-shipment-report-id-status" [
  shipment_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipment-reports/v4/{shipmentReportId}/status"
    path_params: [{name: shipmentReportId, var: shipment_report_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shipment_report_id: $shipment_report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets summary of the shipment report
#
# GET /shipment-reports/v4/{shipmentReportId}/summary
# Returns: record<completedAt: string, createdAt: string, totalLocationCount: int, totalSegmentPlanCount: int, totalSegmentsCount: int, totalShipmentPlanCount: int, totalShipmentsCount: int>
export def "get-shipment-reports-v4-shipment-report-id-summary" [
  shipment_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipment-reports/v4/{shipmentReportId}/summary"
    path_params: [{name: shipmentReportId, var: shipment_report_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shipment_report_id: $shipment_report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metrics of the shipment report
#
# GET /shipment-reports/v4/{shipmentReportId}/{metric}
# Returns: record<count: int, items: table<ids: record, statistics: record, statisticsCount: int>, limit: int, nextPageToken: string, total: int>
export def "get-shipment-reports-v4-shipment-report-id-metric" [
  shipment_report_id: string
  metric: string@metric-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --sort: string # The response items can be sorted to ascending or descending order by their statistics properties. E.g for `shipmentPlanPunctualityAtOrigin` it could be `avg:desc`. Default is ascending sort order.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipment-reports/v4/{shipmentReportId}/{metric}"
    path_params: [{name: shipmentReportId, var: shipment_report_id}, {name: metric, var: metric}]
    query: [{name: pageToken, var: page_token}, {name: limit, var: limit}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shipment_report_id: $shipment_report_id, metric: $metric, page_token: $page_token, limit: $limit, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all shipments
#
# DELETE /shipments/v4
export def "delete-shipments-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/shipments/v4"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all shipments
#
# GET /shipments/v4
# Returns: record<count: int, items: table<autoStart: bool, calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, endedAt: string, name: string, providedEta: string, providedEtd: string, ruleIds: list, segments: list, shipmentId: string, shipmentPlanId: string, startedAt: string, status: string, subShipment: bool>, limit: int, nextPageToken: string, total: int>
export def "get-shipments-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --status: string@status-completer # Filter the results by shipment status
  --started-before: string # Return only shipments that started before the specified timestamp (format: date-time)
  --started-after: string # Return only shipments that started after the specified timestamp (format: date-time)
  --ended-before: string # Return only shipments that ended before the specified timestamp (format: date-time)
  --ended-after: string # Return only shipments that ended after the specified timestamp (format: date-time)
  --name: string # Filter shipments by name. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *portugal*)
  --shipment-plan-id: string # Return only shipments that have been instantiated from the specified `shipmentPlanId`
  --shipment-id: string # Filter shipments by `shipmentId` Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character.
  --is-sub-shipment: oneof<nothing, bool> # Returns only shipments marked as subShipments
  --created-before: string # Return only shipments that have been created before specified timestamp (format: date-time)
  --created-after: string # Return only shipments that have been created after specified timestamp (format: date-time)
  --sort: string # A paramater to specify field to sort by and order. The following format can be used: 'name:asc' sort by name in ascending order, 'shipmentId:desc' sort by shipmentId in descending order. Allowed fields to sort by: shipmentId, name, status, startedAt, createdAt, endedAt, providedEtd, providedEta, calculatedEtd. (e.g. name:asc)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipments/v4"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: limit, var: limit}, {name: status, var: status}, {name: startedBefore, var: started_before}, {name: startedAfter, var: started_after}, {name: endedBefore, var: ended_before}, {name: endedAfter, var: ended_after}, {name: name, var: name}, {name: shipmentPlanId, var: shipment_plan_id}, {name: shipmentId, var: shipment_id}, {name: isSubShipment, var: is_sub_shipment}, {name: createdBefore, var: created_before}, {name: createdAfter, var: created_after}, {name: sort, var: sort}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, limit: $limit, status: $status, started_before: $started_before, started_after: $started_after, ended_before: $ended_before, ended_after: $ended_after, name: $name, shipment_plan_id: $shipment_plan_id, shipment_id: $shipment_id, is_sub_shipment: $is_sub_shipment, created_before: $created_before, created_after: $created_after, sort: $sort, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a shipment
#
# POST /shipments/v4
# Returns: record<shipmentId: string>
export def "post-shipments-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --auto-start: oneof<nothing, bool> # A boolean parameter defining whether the shipment starts upon exiting the first origin location. (default: true)
  --description: string # Description of the shipment
  --name: string # Name of the shipment
  --provided-eta: string # ETA for the shipment (format: date-time)
  --provided-etd: string # ETD for the shipment (format: date-time)
  --rule-ids: list<string> # Array of `ruleId`s to associate with the shipment
  --segments: list # Array of objects each defining the origin and destination of the segment — item shape: {description?: string, destination: string, name?: string, origin: string, providedEta?: string, providedEtd?: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
  --sub-shipment: oneof<nothing, bool> # Flag telling if shipment is a subShipment. (default: false)
  --shipment-departure: string # ETD of the shipment instance. Used to calculate the ETDs and ETAs of all the segments based on the segment durations defined in the plan. (format: date-time)
  --shipment-plan-id: string # Shipment plan ID
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shipments/v4"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoStart, var: auto_start}, {name: description, var: description}, {name: name, var: name}, {name: providedEta, var: provided_eta}, {name: providedEtd, var: provided_etd}, {name: ruleIds, var: rule_ids}, {name: segments, var: segments}, {name: subShipment, var: sub_shipment}, {name: shipmentDeparture, var: shipment_departure}, {name: shipmentPlanId, var: shipment_plan_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, auto_start: $auto_start, description: $description, name: $name, provided_eta: $provided_eta, provided_etd: $provided_etd, rule_ids: $rule_ids, segments: $segments, sub_shipment: $sub_shipment, shipment_departure: $shipment_departure, shipment_plan_id: $shipment_plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /shipments/v4/health
# Returns: record<message: string>
export def "get-shipments-v4-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipments/v4/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all shipment plans
#
# DELETE /shipments/v4/plans
export def "delete-shipments-v4-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/shipments/v4/plans"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: x-confirm, var: x_confirm, required: true, default: "true"}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, x_confirm: $x_confirm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all shipment plans
#
# GET /shipments/v4/plans
# Returns: record<count: int, items: table<autoStart: bool, createdAt: string, description: string, name: string, ruleIds: list, segments: list, shipmentPlanId: string, subShipment: bool>, limit: int, nextPageToken: string, total: int>
export def "get-shipments-v4-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --name: string # Filter shipments by name. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *portugal*)
  --shipment-plan-id: string # Return only shipment plans that have been instantiated from the specified `shipmentPlanId` Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character.
  --location-id: string # Return only shipments that have been instantiated from the specified `locationId`
  --created-before: string # Return only shipments that have been created before specified timestamp (format: date-time)
  --created-after: string # Return only shipments that have been created after specified timestamp (format: date-time)
  --is-sub-shipment: oneof<nothing, bool> # Returns only shipments marked as subShipments
  --sort: string # A paramater to specify field to sort by and order. Allowed fields to sort by: shipmentPlanId, name, createdAt (e.g. name:asc)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipments/v4/plans"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: limit, var: limit}, {name: name, var: name}, {name: shipmentPlanId, var: shipment_plan_id}, {name: locationId, var: location_id}, {name: createdBefore, var: created_before}, {name: createdAfter, var: created_after}, {name: isSubShipment, var: is_sub_shipment}, {name: sort, var: sort}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, limit: $limit, name: $name, shipment_plan_id: $shipment_plan_id, location_id: $location_id, created_before: $created_before, created_after: $created_after, is_sub_shipment: $is_sub_shipment, sort: $sort, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a shipment plan
#
# POST /shipments/v4/plans
# Returns: record<shipmentPlanId: string>
export def "post-shipments-v4-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --auto-start: oneof<nothing, bool> # A boolean parameter defining whether the shipment starts upon exiting the first origin location. (default: true)
  --description: string # Description of the shipment
  --name: string # Name of the shipment
  --rule-ids: list<string> # Array of `ruleId`s to associate with the shipment
  --segments: list # Array of objects each defining the origin and destination of the segment — item shape: {description?: string, destination: string, durationS?: int, name?: string, origin: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
  --sub-shipment: oneof<nothing, bool> # Flag telling if shipment is a subShipment. (default: false)
  --options: record # Optional parameters for plan creation — shape: {calculateDurationsFrom?: "actuals"|"providedEstimate"|"calculatedEstimate", copyTrackingIds?: bool}
  --shipment-id: string # Shipment ID
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shipments/v4/plans"
    query: [{name: projectId, var: project_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoStart, var: auto_start}, {name: description, var: description}, {name: name, var: name}, {name: ruleIds, var: rule_ids}, {name: segments, var: segments}, {name: subShipment, var: sub_shipment}, {name: options, var: options}, {name: shipmentId, var: shipment_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_id: $project_id, x_request_id: $x_request_id, auto_start: $auto_start, description: $description, name: $name, rule_ids: $rule_ids, segments: $segments, sub_shipment: $sub_shipment, options: $options, shipment_id: $shipment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a shipment plan
#
# DELETE /shipments/v4/plans/{shipmentPlanId}
export def "delete-shipments-v4-plans-shipment-plan-id" [
  shipment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/shipments/v4/plans/{shipmentPlanId}"
    path_params: [{name: shipmentPlanId, var: shipment_plan_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shipment_plan_id: $shipment_plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a shipment plan details
#
# GET /shipments/v4/plans/{shipmentPlanId}
# Returns: record<autoStart: bool, createdAt: string, description: string, name: string, ruleIds: list<string>, segments: table<description: string, destination: string, durationS: int, name: string, origin: string, segmentPlanId: string, trackingId: string, transportMode: string>, shipmentPlanId: string, subShipment: bool>
export def "get-shipments-v4-plans-shipment-plan-id" [
  shipment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipments/v4/plans/{shipmentPlanId}"
    path_params: [{name: shipmentPlanId, var: shipment_plan_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shipment_plan_id: $shipment_plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a shipment plan details
#
# PATCH /shipments/v4/plans/{shipmentPlanId}
export def "patch-shipments-v4-plans-shipment-plan-id" [
  shipment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-start: oneof<nothing, bool> # A boolean parameter defining whether the shipment starts upon exiting the first origin location.
  --description: string # Description of the shipment
  --name: string # Name of the shipment
  --rule-ids: list<string> # Array of `ruleId`s to associate with the shipment
  --sub-shipment: oneof<nothing, bool> # Flag telling if shipment is a subShipment.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/shipments/v4/plans/{shipmentPlanId}"
    path_params: [{name: shipmentPlanId, var: shipment_plan_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoStart, var: auto_start}, {name: description, var: description}, {name: name, var: name}, {name: ruleIds, var: rule_ids}, {name: subShipment, var: sub_shipment}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shipment_plan_id: $shipment_plan_id, auto_start: $auto_start, description: $description, name: $name, rule_ids: $rule_ids, sub_shipment: $sub_shipment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a segment plan details
#
# GET /shipments/v4/plans/{shipmentPlanId}/{segmentPlanId}
# Returns: record<description: string, destination: string, durationS: int, name: string, origin: string, segmentPlanId: string, trackingId: string, transportMode: string>
export def "get-shipments-v4-plans-shipment-plan-id-segment-plan-id" [
  shipment_plan_id: string
  segment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipments/v4/plans/{shipmentPlanId}/{segmentPlanId}"
    path_params: [{name: shipmentPlanId, var: shipment_plan_id}, {name: segmentPlanId, var: segment_plan_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shipment_plan_id: $shipment_plan_id, segment_plan_id: $segment_plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a segment plan details
#
# PATCH /shipments/v4/plans/{shipmentPlanId}/{segmentPlanId}
export def "patch-shipments-v4-plans-shipment-plan-id-segment-plan-id" [
  shipment_plan_id: string
  segment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the segment
  --duration-s: int # Segment duration in seconds.
  --name: string # Name of the segment
  --tracking-id: string # ID of the tracking device that produces data for this segment
  --transport-mode: string@transport-mode-completer # Transport mode of the segment
]: any -> any {
  $in | http-request {
    method: patch
    path: "/shipments/v4/plans/{shipmentPlanId}/{segmentPlanId}"
    path_params: [{name: shipmentPlanId, var: shipment_plan_id}, {name: segmentPlanId, var: segment_plan_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: durationS, var: duration_s}, {name: name, var: name}, {name: trackingId, var: tracking_id}, {name: transportMode, var: transport_mode}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shipment_plan_id: $shipment_plan_id, segment_plan_id: $segment_plan_id, description: $description, duration_s: $duration_s, name: $name, tracking_id: $tracking_id, transport_mode: $transport_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /shipments/v4/version
export def "get-shipments-v4-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/shipments/v4/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a shipment
#
# DELETE /shipments/v4/{shipmentId}
export def "delete-shipments-v4-shipment-id" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/shipments/v4/{shipmentId}"
    path_params: [{name: shipmentId, var: shipment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shipment_id: $shipment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a shipment details
#
# GET /shipments/v4/{shipmentId}
# Returns: record<autoStart: bool, calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, endedAt: string, name: string, providedEta: string, providedEtd: string, ruleIds: list<string>, segments: table<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string>, shipmentId: string, shipmentPlanId: string, startedAt: string, status: string, subShipment: bool>
export def "get-shipments-v4-shipment-id" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipments/v4/{shipmentId}"
    path_params: [{name: shipmentId, var: shipment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shipment_id: $shipment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a shipment details
#
# PATCH /shipments/v4/{shipmentId}
export def "patch-shipments-v4-shipment-id" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-start: oneof<nothing, bool> # A boolean parameter defining whether the shipment starts upon exiting the first origin location.
  --description: string # Description of the shipment
  --name: string # Name of the shipment
  --provided-eta: string # ETA for the shipment (format: date-time)
  --provided-etd: string # ETD for the shipment (format: date-time)
  --rule-ids: list<string> # Array of `ruleId`s to associate with the shipment
  --segments: list # Array of objects each defining the origin and destination of the segment — item shape: {description?: string, destination: string, name?: string, origin: string, providedEta?: string, providedEtd?: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
  --status: string@status-completer # Status of the shipment
  --sub-shipment: oneof<nothing, bool> # Flag telling if shipment is a subShipment.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/shipments/v4/{shipmentId}"
    path_params: [{name: shipmentId, var: shipment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoStart, var: auto_start}, {name: description, var: description}, {name: name, var: name}, {name: providedEta, var: provided_eta}, {name: providedEtd, var: provided_etd}, {name: ruleIds, var: rule_ids}, {name: segments, var: segments}, {name: status, var: status}, {name: subShipment, var: sub_shipment}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shipment_id: $shipment_id, auto_start: $auto_start, description: $description, name: $name, provided_eta: $provided_eta, provided_etd: $provided_etd, rule_ids: $rule_ids, segments: $segments, status: $status, sub_shipment: $sub_shipment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a segment details
#
# GET /shipments/v4/{shipmentId}/{segmentId}
# Returns: record<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string>
export def "get-shipments-v4-shipment-id-segment-id" [
  shipment_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipments/v4/{shipmentId}/{segmentId}"
    path_params: [{name: shipmentId, var: shipment_id}, {name: segmentId, var: segment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shipment_id: $shipment_id, segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a segment details
#
# PATCH /shipments/v4/{shipmentId}/{segmentId}
export def "patch-shipments-v4-shipment-id-segment-id" [
  shipment_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the segment
  --name: string # Name of the segment
  --provided-eta: string # ETA for the segment (format: date-time)
  --provided-etd: string # ETD for the segment (format: date-time)
  --status: string@status-completer # Status of the segment
  --tracking-id: string # ID of the tracking device that produces data for the segment
  --transport-mode: string@transport-mode-completer # Transport mode of the segment
]: any -> any {
  $in | http-request {
    method: patch
    path: "/shipments/v4/{shipmentId}/{segmentId}"
    path_params: [{name: shipmentId, var: shipment_id}, {name: segmentId, var: segment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: providedEta, var: provided_eta}, {name: providedEtd, var: provided_etd}, {name: status, var: status}, {name: trackingId, var: tracking_id}, {name: transportMode, var: transport_mode}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shipment_id: $shipment_id, segment_id: $segment_id, description: $description, name: $name, provided_eta: $provided_eta, provided_etd: $provided_etd, status: $status, tracking_id: $tracking_id, transport_mode: $transport_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets segments assigned to a device
#
# GET /shipments/v4/{trackingId}/segments
# Returns: record<count: int, items: table<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, shipmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string>, limit: int, nextPageToken: string>
export def "get-shipments-v4-tracking-id-segments" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --status: string@status-completer # Filter the results by segment status
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipments/v4/{trackingId}/segments"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: pageToken, var: page_token}, {name: limit, var: limit}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, page_token: $page_token, limit: $limit, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /traces/v2/health
# Returns: record<message: string>
export def "get-traces-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/traces/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /traces/v2/version
export def "get-traces-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/traces/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all the device traces and events
#
# DELETE /traces/v2/{trackingId}
export def "delete-traces-v2-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> any {
  http-request {
    method: delete
    path: "/traces/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets traces within a specified time range
#
# GET /traces/v2/{trackingId}
# Returns: record<count: int, pageToken: string, data: table<payload: record, position: record, serverTimestamp: int, system: record, timestamp: int, trackingDisabled: list>>
export def "get-traces-v2-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --outliers: oneof<nothing, bool> # Flag specifying if only outliers (`true`) or only nonoutliers (`false`) are to be returned. If the parameter is not present both nonoutlier and outlier traces are returned.
  --mode: string@mode-completer # Tracker mode.
  --smooth: oneof<nothing, bool> # Flag telling if smoothed traces (true) or non-smoothed (false) traces should get returned. By default the traces are not smoothed. The smoothing will have an effect on to the stationary trace points only.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of records per page. (default: 1000)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/traces/v2/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}, {name: before, var: before}, {name: after, var: after}, {name: outliers, var: outliers}, {name: mode, var: mode}, {name: smooth, var: smooth}, {name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, before: $before, after: $after, outliers: $outliers, mode: $mode, smooth: $smooth, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets transitions for a device
#
# GET /transitions/v2/devices/{trackingId}
# DEPRECATED
# Returns: record<count: int, pageToken: string, data: table<geofence: any, geofenceId: string, inOut: string, notificationStatus: string, timestamp: int, trackingId: string>>
@deprecated
export def "get-transitions-v2-devices-tracking-id" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transitions/v2/devices/{trackingId}"
    path_params: [{name: trackingId, var: tracking_id}]
    query: [{name: appId, var: app_id}, {name: before, var: before}, {name: after, var: after}, {name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_id: $tracking_id, app_id: $app_id, before: $before, after: $after, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /transitions/v2/health
# DEPRECATED
# Returns: record<message: string>
@deprecated
export def "get-transitions-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transitions/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /transitions/v2/version
# DEPRECATED
@deprecated
export def "get-transitions-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/transitions/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all devices claimed by a project
#
# GET /users/v2/devices
# Returns: record<count: int, pageToken: string, data: table<appId: string, externalId: string, shadow: record, trackingId: string>>
export def "get-users-v2-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/v2/devices"
    query: [{name: projectId, var: project_id}, {name: pageToken, var: page_token}, {name: count, var: count}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_token: $page_token, count: $count, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /users/v2/health
# Returns: record<message: string>
export def "get-users-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a user access token
#
# POST /users/v2/login
# Returns: record<accessToken: string, expiresIn: int, realm: string, refreshToken: string, tokenType: string, userId: string>
export def "post-users-v2-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  email: string # The email address of the user
  password: string # The password of the user
  --realm: string # A case-insensitive requested realm ID
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/v2/login"
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}, {name: realm, var: realm}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id, email: $email, password: $password, realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a renewed user access token
#
# POST /users/v2/refresh
# Returns: record<accessToken: string, expiresIn: int, realm: string, refreshToken: string, tokenType: string, userId: string>
export def "post-users-v2-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  access_token: string # The access token obtained in a previous login
  refresh_token: string # The refresh token obtained in a previous login
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/v2/refresh"
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessToken, var: access_token}, {name: refreshToken, var: refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id, access_token: $access_token, refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a project-scoped user access token
#
# POST /users/v2/tokenExchange
# Returns: record<accessToken: string, expiresIn: int, issuedTokenType: string, scope: string, tokenType: string>
export def "post-users-v2-token-exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  access_token: string # HERE Account user access token, obtained from login endpoint.
  scope: string # Requested scope of the access token. Must be an HRN identifying a project that the identified user has access to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/v2/tokenExchange"
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessToken, var: access_token}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id, access_token: $access_token, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /users/v2/version
export def "get-users-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/users/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ingests data and receives a shadow
#
# POST /v2/
# Returns: record<payload: record, system: record<detectOutliers: bool, disableTracking: record<periods: list, position: any, sensors: any>, lastModifiedGeofenceTimestamp: int, rate: record<distanceM: float, sampleMs: float, sendMs: float>, sensorAlarmConfig: record<alertAccelerationGMax: float, alertAccelerationGMin: float, alertBatteryLevelPMax: float, alertBatteryLevelPMin: float, alertPressureHpaMax: float, alertPressureHpaMin: float, alertRelativeHumidityMax: float, alertRelativeHumidityMin: float, alertTemperatureCMax: float, alertTemperatureCMin: float, alertTiltDegreeMax: float, alertTiltDegreeMin: float, isAttachAlertEnabled: bool, isTamperAlertEnabled: bool>, sensorLoggingConfigurations: list<record>, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list<record>, wlanConnectivityEnabled: bool>, timestamp: int>
export def "post-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool> # If set to `true`, ingests the device data and responds immediately with an empty response body. (default: false)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --authorization: string # required, e.g. Bearer h1.yxPIksZ0ViLq77f1Nh-9cg.NVgGBZVlCU8G7kjV_...
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/"
    query: [{name: async, var: async}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    async: $async, x_request_id: $x_request_id, authorization: $authorization, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /v2/health
# Returns: record<message: string>
export def "get-v2-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the current timestamp
#
# GET /v2/timestamp
# Returns: record<timestamp: int>
export def "get-v2-timestamp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/timestamp"
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a token for a registered device
#
# POST /v2/token
# Returns: record<accessToken: string, expiresIn: int>
export def "post-v2-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --authorization: string # Signed OAuth 1.0 header (required, e.g. OAuth oauth_consumer_key='{deviceId}',oauth_signature_method='HMAC_SHA256',oauth_timestamp='{nowS}',oauth_nonce='{nonce}',oauth_signature='{signature}')
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v2/token"
    header: [{name: X-Request-Id, var: x_request_id}, {name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: oauth
  } {
    x_request_id: $x_request_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /v2/version
export def "get-v2-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ingests data for a device and receives a shadow
#
# POST /v3/
# Returns: record<payload: record, system: record<detectOutliers: bool, disableTracking: record<periods: list, position: any, sensors: any>, lastModifiedGeofenceTimestamp: int, rate: record<distanceM: float, sampleMs: float, sendMs: float>, sensorAlarmConfig: record<alertAccelerationGMax: float, alertAccelerationGMin: float, alertBatteryLevelPMax: float, alertBatteryLevelPMin: float, alertPressureHpaMax: float, alertPressureHpaMin: float, alertRelativeHumidityMax: float, alertRelativeHumidityMin: float, alertTemperatureCMax: float, alertTemperatureCMin: float, alertTiltDegreeMax: float, alertTiltDegreeMin: float, isAttachAlertEnabled: bool, isTamperAlertEnabled: bool>, sensorLoggingConfigurations: list<record>, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list<record>, wlanConnectivityEnabled: bool>, timestamp: int>
export def "post-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool> # If set to `true`, ingests the device data and responds immediately with an empty response body. (default: false)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --authorization: string # required, e.g. Bearer h1.yxPIksZ0ViLq77f1Nh-9cg.NVgGBZVlCU8G7kjV_...
  --app-id: string # The user's project appId. Used together with an external ID to identify the virtual device.
  data: list # item shape: {payload?: record, position?: record, scan?: record, system?: record, timestamp: int}
  --id: string # Tracking ID or application specific external ID, needed only if ingesting on behalf of another device.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/"
    query: [{name: async, var: async}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: appId, var: app_id}, {name: data, var: data}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    async: $async, x_request_id: $x_request_id, authorization: $authorization, app_id: $app_id, data: $data, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ingests data for multiple devices
#
# POST /v3/batch
export def "post-v3-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4. (format: uuid)
  --authorization: string # required, e.g. Bearer h1.yxPIksZ0ViLq77f1Nh-9cg.NVgGBZVlCU8G7kjV_...
  --app-id: string # The user's project appId. Used together with an external ID to identify the virtual devices.
  data: list # item shape: {payload?: record, position?: record, scan?: record, system?: record, timestamp: int, id?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/batch"
    header: [{name: X-Request-Id, var: x_request_id}, {name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: appId, var: app_id}, {name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_request_id: $x_request_id, authorization: $authorization, app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service health
#
# GET /v3/health
# Returns: record<message: string>
export def "get-v3-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service version
#
# GET /v3/version
export def "get-v3-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/version"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
