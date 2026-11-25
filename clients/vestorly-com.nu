# Auto-generated client for Vestorly API v1.0.0
# Source: https://api.apis.guru/v2/specs/vestorly.com/1.0.0/swagger.json
# Auth: --token flag or $env.VESTORLY_API_TOKEN

const CLIENT = {
  base_url: "https://staging.vestorly.com/api/v2"
  token_env_var: "VESTORLY_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
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

def base-url-completer [] { ["https://staging.vestorly.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["bounce" "click" "content_posted" "create_post" "delete_post" "delivered" "dropped" "invite" "open" "page_view" "publish_newsletter" "publish_post" "publish_social" "sign_in" "sign_up" "unpublish_post" "update_post"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    find-advisor-by-id: "record<about: string, account_type: string, address: string, adv_brochure: string, api_key: string, city: string, company: string, compliance_bcc_email_address: string, dashboard_url: string, disclosure: string, email_report_blast: string, external_options: string, first_name: string, id: string, last_name: string, linkedin: string, logo: string, name: string, plan: string, profile_picture: string, reg_number: string, state: string, tag: string, twitter_handle: string, website: string, zip: string>"
    find-article-phrases: "record<article_phrases: table<created_at: int, length: int, text: string>>"
    find-articles: "record<articles: table<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>>"
    find-article-by-id: "record<article: record<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>>"
    find-custom-feed-filters: "record<custom_feed_filters: table<_id: string, custom_feed_id: string, source_ids: list>>"
    create-custom-feed-filter: "record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>>"
    delete-custom-feed-filter: "record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>>"
    find-custom-feed-filter-by-id: "record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>>"
    update-custom-feed-filter-by-id: "record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>>"
    find-custom-feeds: "record<custom_feeds: table<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>"
    create-custom-feed: "record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>"
    delete-custom-feed: "record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>"
    find-custom-feed-by-id: "record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>"
    update-category-by-id: "record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>"
    find-custom-feed-articles: "record<articles: table<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>>"
    duplicate-custom-feed: "record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>"
    find-events: "record<events: table<_id: string, advisor_id: string, created_at: string, event_content: record, original_url: string, originator_email: string, originator_id: string, parent_event_id: string, referer: string, subject_email: string, subject_id: string, type: string>>"
    create-event: "record<meta: record<message: string>>"
    find-event-by-id: "record<event: record<_id: string, advisor_id: string, created_at: string, event_content: record<_id: string, content_field: string, content_id: string, content_type: string, created_at: string, slug: string, updated_at: string>, original_url: string, originator_email: string, originator_id: string, parent_event_id: string, referer: string, subject_email: string, subject_id: string, type: string>>"
    find-groups: "record<groups: table<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>"
    create-group: "record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>"
    delete-group: "record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>"
    find-group-by-id: "record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>"
    update-group-by-id: "record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>"
    find-member-events: "record<member_events: table<_id: string, content_url: string, created_at: string, event_date: string, event_source: string, event_type: string, member_id: string, original_url: string, originator_email: string, originator_group_id: string, originator_id: string, originator_name: string, originator_type: string, parent_event_id: string, parent_originator_id: string, referer: string, source: string, subject_id: string, type: string, username: string>, members: table<_id: string, added_on: string, email: string, first_name: string, last_name: string, picture_url: string>>"
    find-member-reports: "record<member_reports: table<day: int, event_count: int, originator_group_id: string, parent_originator_id: string, source: string, type: string, year: int>>"
    find-members: "record<members: table<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list, tags: list, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>, meta: record<message: string>, more_results: bool>"
    create-member: "record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>>"
    find-member-by-id: "record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>>"
    update-member-by-id: "record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>>"
    find-newsletter-settings: "record<newsletter_settings: table<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>>"
    find-newsletter-settings-by-id: "record<newsletter_setting: record<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list<string>, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>>"
    update-newsletter-settings-by-id: "record<newsletter_setting: record<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list<string>, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>>"
    find-newsletters: "record<newsletters: table<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>>"
    get-newsletter-by-id: "record<newsletter: record<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>>"
    update-newsletter-by-id: "record<newsletter: record<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>>"
    find-posts: "record<posts: table<_id: string, advisor_id: string, approval_status: string, approval_transactions: list, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>>"
    create-post: "record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>>"
    get-post-by-id: "record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>>"
    update-post-by-id: "record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>>"
    find-seed-custom-feeds: "record<seed_custom_feeds: table<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list, seeds: list, sort_by: string>>"
    create-seed-custom-feed: "record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>>"
    delete-seed-custom-feed: "record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>>"
    find-seed-custom-feed-by-id: "record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>>"
    update-seed-custom-feed-by-id: "record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>>"
    login: "record<_id: string, current_user: record<_id: string, company: string, first_name: string, last_name: string, name: string, new_user: bool, picture_url: string, plan_expired: bool, plan_id: string, plan_setup: bool, plan_status: string, plan_stripe: bool, show_tour: bool, slug: string, user_type: string, username: string, website: string>, new_user: bool, settings: record<_id: string, adv_brochure: string, company: string, disclosure: string, feature: record<_id: string>, name: string, orgsetting: record<_id: string, company_address: string, company_contact_email: string, company_homepage_url: string, is_default: bool, name: string, privacy_policy_url: string, site_url: string, terms_and_conditions_url: string>, personalsetting: record<_id: string>, picture_url: string, slug: string, website: string>, vestorly-auth: string>"
    logout: "record<message: string>"
    find-sources: "record<sources: table<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>>"
    create-source: "record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>>"
    get-source-by-id: "record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>>"
    update-source-by-id: "record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["find-advisor-by-id" "find-article-phrases" "find-articles" "find-article-by-id" "find-custom-feed-filters" "create-custom-feed-filter" "delete-custom-feed-filter" "find-custom-feed-filter-by-id" "update-custom-feed-filter-by-id" "find-custom-feeds" "create-custom-feed" "delete-custom-feed" "find-custom-feed-by-id" "update-category-by-id" "find-custom-feed-articles" "duplicate-custom-feed" "find-events" "create-event" "find-event-by-id" "find-groups" "create-group" "delete-group" "find-group-by-id" "update-group-by-id" "find-member-events" "find-member-reports" "find-members" "create-member" "find-member-by-id" "update-member-by-id" "find-newsletter-settings" "find-newsletter-settings-by-id" "update-newsletter-settings-by-id" "find-newsletters" "get-newsletter-by-id" "update-newsletter-by-id" "find-posts" "create-post" "get-post-by-id" "update-post-by-id" "find-seed-custom-feeds" "create-seed-custom-feed" "delete-seed-custom-feed" "find-seed-custom-feed-by-id" "update-seed-custom-feed-by-id" "login" "logout" "find-sources" "create-source" "get-source-by-id" "update-source-by-id" "commands"] | sort) } | get name | first)
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

# Returns a single advisor given their ID
#
# GET /advisors/{id}
# Returns: record<about: string, account_type: string, address: string, adv_brochure: string, api_key: string, city: string, company: string, compliance_bcc_email_address: string, dashboard_url: string, disclosure: string, email_report_blast: string, external_options: string, first_name: string, id: string, last_name: string, linkedin: string, logo: string, name: string, plan: string, profile_picture: string, reg_number: string, state: string, tag: string, twitter_handle: string, website: string, zip: string>
# operationId: findAdvisorByID
export def "find-advisor-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/advisors/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phrases used in Categories
#
# GET /article_phrases
# Returns: record<article_phrases: table<created_at: int, length: int, text: string>>
# operationId: findArticlePhrases
export def "find-article-phrases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --text-search: string # Text to search phrases
  --size: int # Number of returned phrases
  --from: int # Number of phrases to skip
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/article_phrases"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}, {name: text_search, var: text_search}, {name: size, var: size}, {name: from, var: from}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, text_search: $text_search, size: $size, from: $from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all articles
#
# GET /articles
# Returns: record<articles: table<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>>
# operationId: findArticles
export def "find-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --limit: int # Limit on the number of articles to return (format: int32)
  --text-query: string # Search query parameter
  --sort-direction: string # Direction of sort (used with sort_by parameter)
  --sort-by: string # Field on model to sort by
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/articles"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}, {name: limit, var: limit}, {name: text_query, var: text_query}, {name: sort_direction, var: sort_direction}, {name: sort_by, var: sort_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, limit: $limit, text_query: $text_query, sort_direction: $sort_direction, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single article
#
# GET /articles/{id}
# Returns: record<article: record<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>>
# operationId: findArticleByID
export def "find-article-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/articles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all Categorie's filters
#
# GET /custom_feed_filters
# Returns: record<custom_feed_filters: table<_id: string, custom_feed_id: string, source_ids: list>>
# operationId: findCustomFeedFilters
export def "find-custom-feed-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_feed_filters"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Category filter
#
# POST /custom_feed_filters
# Returns: record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>>
# operationId: createCustomFeedFilter
export def "create-custom-feed-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  custom_feed_id: string
  --source-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_feed_filters"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_feed_id, var: custom_feed_id}, {name: source_ids, var: source_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, custom_feed_id: $custom_feed_id, source_ids: $source_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Category's filter
#
# DELETE /custom_feed_filters/{id}
# Returns: record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>>
# operationId: deleteCustomFeedFilter
export def "delete-custom-feed-filter" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/custom_feed_filters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single Category's filter
#
# GET /custom_feed_filters/{id}
# Returns: record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>>
# operationId: findCustomFeedFilterByID
export def "find-custom-feed-filter-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_feed_filters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Category Feed Filter
#
# PUT /custom_feed_filters/{id}
# Returns: record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>>
# operationId: updateCustomFeedFilterById
export def "update-custom-feed-filter-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  custom_feed_id: string
  --source-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/custom_feed_filters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_feed_id, var: custom_feed_id}, {name: source_ids, var: source_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, custom_feed_id: $custom_feed_id, source_ids: $source_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all Categories
#
# GET /custom_feeds
# Returns: record<custom_feeds: table<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>
# operationId: findCustomFeeds
export def "find-custom-feeds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_feeds"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Category
#
# POST /custom_feeds
# Returns: record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>
# operationId: createCustomFeed
export def "create-custom-feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --custom-feed-filter-id: string
  --custom-feed-permission-id: string
  --custom-feed-visibility: int # format: int32
  --default: oneof<nothing, bool>
  --is-auto-curated-newsletter-custom-feed: oneof<nothing, bool>
  label: string
  --popularity: float # format: float
  --premium-content: oneof<nothing, bool>
  --seed-custom-feed-id: string
  --social-posting-id: string
  --third-party-articles-custom-feed-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_feeds"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_feed_filter_id, var: custom_feed_filter_id}, {name: custom_feed_permission_id, var: custom_feed_permission_id}, {name: custom_feed_visibility, var: custom_feed_visibility}, {name: default, var: default}, {name: is_auto_curated_newsletter_custom_feed, var: is_auto_curated_newsletter_custom_feed}, {name: label, var: label}, {name: popularity, var: popularity}, {name: premium_content, var: premium_content}, {name: seed_custom_feed_id, var: seed_custom_feed_id}, {name: social_posting_id, var: social_posting_id}, {name: third_party_articles_custom_feed_id, var: third_party_articles_custom_feed_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, custom_feed_filter_id: $custom_feed_filter_id, custom_feed_permission_id: $custom_feed_permission_id, custom_feed_visibility: $custom_feed_visibility, default: $default, is_auto_curated_newsletter_custom_feed: $is_auto_curated_newsletter_custom_feed, label: $label, popularity: $popularity, premium_content: $premium_content, seed_custom_feed_id: $seed_custom_feed_id, social_posting_id: $social_posting_id, third_party_articles_custom_feed_id: $third_party_articles_custom_feed_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a new Category
#
# DELETE /custom_feeds/{id}
# Returns: record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>
# operationId: deleteCustomFeed
export def "delete-custom-feed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/custom_feeds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single Category
#
# GET /custom_feeds/{id}
# Returns: record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>
# operationId: findCustomFeedByID
export def "find-custom-feed-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_feeds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Category
#
# PUT /custom_feeds/{id}
# Returns: record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>
# operationId: updateCategoryById
export def "update-category-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --custom-feed-filter-id: string
  --custom-feed-permission-id: string
  --custom-feed-visibility: int # format: int32
  --default: oneof<nothing, bool>
  --is-auto-curated-newsletter-custom-feed: oneof<nothing, bool>
  label: string
  --popularity: float # format: float
  --premium-content: oneof<nothing, bool>
  --seed-custom-feed-id: string
  --social-posting-id: string
  --third-party-articles-custom-feed-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/custom_feeds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_feed_filter_id, var: custom_feed_filter_id}, {name: custom_feed_permission_id, var: custom_feed_permission_id}, {name: custom_feed_visibility, var: custom_feed_visibility}, {name: default, var: default}, {name: is_auto_curated_newsletter_custom_feed, var: is_auto_curated_newsletter_custom_feed}, {name: label, var: label}, {name: popularity, var: popularity}, {name: premium_content, var: premium_content}, {name: seed_custom_feed_id, var: seed_custom_feed_id}, {name: social_posting_id, var: social_posting_id}, {name: third_party_articles_custom_feed_id, var: third_party_articles_custom_feed_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, custom_feed_filter_id: $custom_feed_filter_id, custom_feed_permission_id: $custom_feed_permission_id, custom_feed_visibility: $custom_feed_visibility, default: $default, is_auto_curated_newsletter_custom_feed: $is_auto_curated_newsletter_custom_feed, label: $label, popularity: $popularity, premium_content: $premium_content, seed_custom_feed_id: $seed_custom_feed_id, social_posting_id: $social_posting_id, third_party_articles_custom_feed_id: $third_party_articles_custom_feed_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Articles by Category
#
# GET /custom_feeds/{id}/articles
# Returns: record<articles: table<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>>
# operationId: findCustomFeedArticles
export def "find-custom-feed-articles" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --limit: int # Limit on the number of articles to return (format: int32)
  --sort-by: string # Field on model to sort by
  --start: int # Field where the fetch will start from (format: int32)
  --created-at-gte-days-ago: string # Filter retrieved articles since this date
  --text-query: string # Search query parameter
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_feeds/{id}/articles"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}, {name: limit, var: limit}, {name: sort_by, var: sort_by}, {name: start, var: start}, {name: created_at_gte_days_ago, var: created_at_gte_days_ago}, {name: text_query, var: text_query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, limit: $limit, sort_by: $sort_by, start: $start, created_at_gte_days_ago: $created_at_gte_days_ago, text_query: $text_query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicates Category
#
# POST /custom_feeds/{id}/duplicates
# Returns: record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>>
# operationId: duplicateCustomFeed
export def "duplicate-custom-feed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/custom_feeds/{id}/duplicates"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all events
#
# GET /events
# Returns: record<events: table<_id: string, advisor_id: string, created_at: string, event_content: record, original_url: string, originator_email: string, originator_id: string, parent_event_id: string, referer: string, subject_email: string, subject_id: string, type: string>>
# operationId: findEvents
export def "find-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new event in the system
#
# POST /events
# Returns: record<meta: record<message: string>>
# operationId: createEvent
export def "create-event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --advisor-id: string
  --created-at: string
  --event-content: any # shape: {_id?: string, content_field?: string, content_id?: string, content_type?: string, created_at?: string, slug?: string, updated_at?: string}
  original_url: string
  --originator-email: string
  --originator-id: string
  --parent-event-id: string
  --referer: string
  subject_email: string
  --subject-id: string
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/events"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: advisor_id, var: advisor_id}, {name: created_at, var: created_at}, {name: event_content, var: event_content}, {name: original_url, var: original_url}, {name: originator_email, var: originator_email}, {name: originator_id, var: originator_id}, {name: parent_event_id, var: parent_event_id}, {name: referer, var: referer}, {name: subject_email, var: subject_email}, {name: subject_id, var: subject_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, advisor_id: $advisor_id, created_at: $created_at, event_content: $event_content, original_url: $original_url, originator_email: $originator_email, originator_id: $originator_id, parent_event_id: $parent_event_id, referer: $referer, subject_email: $subject_email, subject_id: $subject_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single event if the user has access
#
# GET /events/{id}
# Returns: record<event: record<_id: string, advisor_id: string, created_at: string, event_content: record<_id: string, content_field: string, content_id: string, content_type: string, created_at: string, slug: string, updated_at: string>, original_url: string, originator_email: string, originator_id: string, parent_event_id: string, referer: string, subject_email: string, subject_id: string, type: string>>
# operationId: findEventByID
export def "find-event-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # OAuth Token
  --vestorly-auth: string # Vestorly Auth Token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: access_token, var: access_token}, {name: vestorly_auth, var: vestorly_auth, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, access_token: $access_token, vestorly_auth: $vestorly_auth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all groups
#
# GET /groups
# Returns: record<groups: table<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>
# operationId: findGroups
export def "find-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required, format: string)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Group
#
# POST /groups
# Returns: record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>
# operationId: createGroup
export def "create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required, format: string)
  --access-token: string # OAuth Token
  id: string
  --autopublish: oneof<nothing, bool>
  --is-default: oneof<nothing, bool>
  --is-hidden: oneof<nothing, bool>
  --name: string
  --new-weekly-mailer-content: string
  --newsletter-subject: string
  --number-articles-per-group: int # format: int32
  --number-articles-per-newsletter: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: _id, var: id}, {name: autopublish, var: autopublish}, {name: is_default, var: is_default}, {name: is_hidden, var: is_hidden}, {name: name, var: name}, {name: new_weekly_mailer_content, var: new_weekly_mailer_content}, {name: newsletter_subject, var: newsletter_subject}, {name: number_articles_per_group, var: number_articles_per_group}, {name: number_articles_per_newsletter, var: number_articles_per_newsletter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, id: $id, autopublish: $autopublish, is_default: $is_default, is_hidden: $is_hidden, name: $name, new_weekly_mailer_content: $new_weekly_mailer_content, newsletter_subject: $newsletter_subject, number_articles_per_group: $number_articles_per_group, number_articles_per_newsletter: $number_articles_per_newsletter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Group
#
# DELETE /groups/{id}
# Returns: record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>
# operationId: deleteGroup
export def "delete-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required, format: string)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single group if user has access
#
# GET /groups/{id}
# Returns: record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>
# operationId: findGroupByID
export def "find-group-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required, format: string)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Group
#
# PUT /groups/{id}
# Returns: record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>>
# operationId: updateGroupById
export def "update-group-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --body-id: string # (spec name: _id)
  --autopublish: oneof<nothing, bool>
  --is-default: oneof<nothing, bool>
  --is-hidden: oneof<nothing, bool>
  --name: string
  --new-weekly-mailer-content: string
  --newsletter-subject: string
  --number-articles-per-group: int # format: int32
  --number-articles-per-newsletter: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: _id, var: body_id, required: true}, {name: autopublish, var: autopublish}, {name: is_default, var: is_default}, {name: is_hidden, var: is_hidden}, {name: name, var: name}, {name: new_weekly_mailer_content, var: new_weekly_mailer_content}, {name: newsletter_subject, var: newsletter_subject}, {name: number_articles_per_group, var: number_articles_per_group}, {name: number_articles_per_newsletter, var: number_articles_per_newsletter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, body_id: $body_id, autopublish: $autopublish, is_default: $is_default, is_hidden: $is_hidden, name: $name, new_weekly_mailer_content: $new_weekly_mailer_content, newsletter_subject: $newsletter_subject, number_articles_per_group: $number_articles_per_group, number_articles_per_newsletter: $number_articles_per_newsletter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all MemberEvents
#
# GET /member_events
# Returns: record<member_events: table<_id: string, content_url: string, created_at: string, event_date: string, event_source: string, event_type: string, member_id: string, original_url: string, originator_email: string, originator_group_id: string, originator_id: string, originator_name: string, originator_type: string, parent_event_id: string, parent_originator_id: string, referer: string, source: string, subject_id: string, type: string, username: string>, members: table<_id: string, added_on: string, email: string, first_name: string, last_name: string, picture_url: string>>
# operationId: findMemberEvents
export def "find-member-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/member_events"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all member reports
#
# GET /member_reports
# Returns: record<member_reports: table<day: int, event_count: int, originator_group_id: string, parent_originator_id: string, source: string, type: string, year: int>>
# operationId: findMemberReports
export def "find-member-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/member_reports"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all members
#
# GET /members
# Returns: record<members: table<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list, tags: list, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>, meta: record<message: string>, more_results: bool>
# operationId: findMembers
export def "find-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required, format: string)
  --access-token: string # OAuth Token
  --start: int # Skips number of members from start
  --limit: int # Number of members to return
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/members"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}, {name: start, var: start}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, start: $start, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new member in the Vestorly Platform
#
# POST /members
# Returns: record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>>
# operationId: createMember
export def "create-member" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  id: string
  --address: string
  --age: string
  --assets: string
  --city: string
  --data-estimated: oneof<nothing, bool>
  --education: string
  email: string
  --estimated-location: string
  --estimated-zip: string
  --family: string
  --first-name: string
  --gender: string
  --genuine-email: oneof<nothing, bool>
  --high-net-worth: oneof<nothing, bool>
  --home-market-value: string
  --home-owner-status: string
  --hometown: string
  --household-income: string
  --interest-consultation: string
  --interest-in-new-advisor: string
  --invited-by: string
  --invited-on: string
  --is-client: oneof<nothing, bool>
  --is-hidden: oneof<nothing, bool>
  --last-active-date: string
  --last-name: string
  --location: string
  --marital-status: string
  --message: string
  --occupation: string
  --phone: string
  --picture-url: string
  --portfolio-size: string
  --profile-url: string
  --register-ip-addr: string
  --signed-up-with: string
  --state: string
  --subscribed-group-ids: list<string>
  --tags: list<string>
  --unsubscribed: oneof<nothing, bool>
  --unsubscribed-date: oneof<nothing, bool>
  --user-type: string
  --zip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/members"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: _id, var: id}, {name: address, var: address}, {name: age, var: age}, {name: assets, var: assets}, {name: city, var: city}, {name: data_estimated, var: data_estimated}, {name: education, var: education}, {name: email, var: email}, {name: estimated_location, var: estimated_location}, {name: estimated_zip, var: estimated_zip}, {name: family, var: family}, {name: first_name, var: first_name}, {name: gender, var: gender}, {name: genuine_email, var: genuine_email}, {name: high_net_worth, var: high_net_worth}, {name: home_market_value, var: home_market_value}, {name: home_owner_status, var: home_owner_status}, {name: hometown, var: hometown}, {name: household_income, var: household_income}, {name: interest_consultation, var: interest_consultation}, {name: interest_in_new_advisor, var: interest_in_new_advisor}, {name: invited_by, var: invited_by}, {name: invited_on, var: invited_on}, {name: is_client, var: is_client}, {name: is_hidden, var: is_hidden}, {name: last_active_date, var: last_active_date}, {name: last_name, var: last_name}, {name: location, var: location}, {name: marital_status, var: marital_status}, {name: message, var: message}, {name: occupation, var: occupation}, {name: phone, var: phone}, {name: picture_url, var: picture_url}, {name: portfolio_size, var: portfolio_size}, {name: profile_url, var: profile_url}, {name: register_ip_addr, var: register_ip_addr}, {name: signed_up_with, var: signed_up_with}, {name: state, var: state}, {name: subscribed_group_ids, var: subscribed_group_ids}, {name: tags, var: tags}, {name: unsubscribed, var: unsubscribed}, {name: unsubscribed_date, var: unsubscribed_date}, {name: user_type, var: user_type}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, id: $id, address: $address, age: $age, assets: $assets, city: $city, data_estimated: $data_estimated, education: $education, email: $email, estimated_location: $estimated_location, estimated_zip: $estimated_zip, family: $family, first_name: $first_name, gender: $gender, genuine_email: $genuine_email, high_net_worth: $high_net_worth, home_market_value: $home_market_value, home_owner_status: $home_owner_status, hometown: $hometown, household_income: $household_income, interest_consultation: $interest_consultation, interest_in_new_advisor: $interest_in_new_advisor, invited_by: $invited_by, invited_on: $invited_on, is_client: $is_client, is_hidden: $is_hidden, last_active_date: $last_active_date, last_name: $last_name, location: $location, marital_status: $marital_status, message: $message, occupation: $occupation, phone: $phone, picture_url: $picture_url, portfolio_size: $portfolio_size, profile_url: $profile_url, register_ip_addr: $register_ip_addr, signed_up_with: $signed_up_with, state: $state, subscribed_group_ids: $subscribed_group_ids, tags: $tags, unsubscribed: $unsubscribed, unsubscribed_date: $unsubscribed_date, user_type: $user_type, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single member
#
# GET /members/{id}
# Returns: record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>>
# operationId: findMemberByID
export def "find-member-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required, format: string)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/members/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a single member
#
# PUT /members/{id}
# Returns: record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>>
# operationId: updateMemberByID
export def "update-member-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required, format: string)
  --access-token: string # OAuth Token
  --body-id: string # (spec name: _id)
  --address: string
  --age: string
  --assets: string
  --city: string
  --data-estimated: oneof<nothing, bool>
  --education: string
  email: string
  --estimated-location: string
  --estimated-zip: string
  --family: string
  --first-name: string
  --gender: string
  --genuine-email: oneof<nothing, bool>
  --high-net-worth: oneof<nothing, bool>
  --home-market-value: string
  --home-owner-status: string
  --hometown: string
  --household-income: string
  --interest-consultation: string
  --interest-in-new-advisor: string
  --invited-by: string
  --invited-on: string
  --is-client: oneof<nothing, bool>
  --is-hidden: oneof<nothing, bool>
  --last-active-date: string
  --last-name: string
  --location: string
  --marital-status: string
  --message: string
  --occupation: string
  --phone: string
  --picture-url: string
  --portfolio-size: string
  --profile-url: string
  --register-ip-addr: string
  --signed-up-with: string
  --state: string
  --subscribed-group-ids: list<string>
  --tags: list<string>
  --unsubscribed: oneof<nothing, bool>
  --unsubscribed-date: oneof<nothing, bool>
  --user-type: string
  --zip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/members/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: _id, var: body_id, required: true}, {name: address, var: address}, {name: age, var: age}, {name: assets, var: assets}, {name: city, var: city}, {name: data_estimated, var: data_estimated}, {name: education, var: education}, {name: email, var: email}, {name: estimated_location, var: estimated_location}, {name: estimated_zip, var: estimated_zip}, {name: family, var: family}, {name: first_name, var: first_name}, {name: gender, var: gender}, {name: genuine_email, var: genuine_email}, {name: high_net_worth, var: high_net_worth}, {name: home_market_value, var: home_market_value}, {name: home_owner_status, var: home_owner_status}, {name: hometown, var: hometown}, {name: household_income, var: household_income}, {name: interest_consultation, var: interest_consultation}, {name: interest_in_new_advisor, var: interest_in_new_advisor}, {name: invited_by, var: invited_by}, {name: invited_on, var: invited_on}, {name: is_client, var: is_client}, {name: is_hidden, var: is_hidden}, {name: last_active_date, var: last_active_date}, {name: last_name, var: last_name}, {name: location, var: location}, {name: marital_status, var: marital_status}, {name: message, var: message}, {name: occupation, var: occupation}, {name: phone, var: phone}, {name: picture_url, var: picture_url}, {name: portfolio_size, var: portfolio_size}, {name: profile_url, var: profile_url}, {name: register_ip_addr, var: register_ip_addr}, {name: signed_up_with, var: signed_up_with}, {name: state, var: state}, {name: subscribed_group_ids, var: subscribed_group_ids}, {name: tags, var: tags}, {name: unsubscribed, var: unsubscribed}, {name: unsubscribed_date, var: unsubscribed_date}, {name: user_type, var: user_type}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, body_id: $body_id, address: $address, age: $age, assets: $assets, city: $city, data_estimated: $data_estimated, education: $education, email: $email, estimated_location: $estimated_location, estimated_zip: $estimated_zip, family: $family, first_name: $first_name, gender: $gender, genuine_email: $genuine_email, high_net_worth: $high_net_worth, home_market_value: $home_market_value, home_owner_status: $home_owner_status, hometown: $hometown, household_income: $household_income, interest_consultation: $interest_consultation, interest_in_new_advisor: $interest_in_new_advisor, invited_by: $invited_by, invited_on: $invited_on, is_client: $is_client, is_hidden: $is_hidden, last_active_date: $last_active_date, last_name: $last_name, location: $location, marital_status: $marital_status, message: $message, occupation: $occupation, phone: $phone, picture_url: $picture_url, portfolio_size: $portfolio_size, profile_url: $profile_url, register_ip_addr: $register_ip_addr, signed_up_with: $signed_up_with, state: $state, subscribed_group_ids: $subscribed_group_ids, tags: $tags, unsubscribed: $unsubscribed, unsubscribed_date: $unsubscribed_date, user_type: $user_type, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all newsletter settings
#
# GET /newsletter_settings
# Returns: record<newsletter_settings: table<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>>
# operationId: findNewsletterSettings
export def "find-newsletter-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/newsletter_settings"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single newsletter settings if the user has access
#
# GET /newsletter_settings/{id}
# Returns: record<newsletter_setting: record<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list<string>, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>>
# operationId: findNewsletterSettingsByID
export def "find-newsletter-settings-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/newsletter_settings/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a single newsletter setting by ID
#
# PUT /newsletter_settings/{id}
# Returns: record<newsletter_setting: record<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list<string>, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>>
# operationId: updateNewsletterSettingsByID
export def "update-newsletter-settings-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --newsletter-setting: any # shape: {_id: string, banner_color?: string, body_html?: string, email_accent_color?: string, email_day_of_week?: int, email_hour?: int, email_status?: string, facebook_active_wall?: string, footer_email_font?: string, footer_html?: string, footer_image_url?: string, group_id?: string, header_background_color?: string, header_image_url?: string, intro_text?: string, linkedin_active_wall?: string, montage_enabled?: bool, montage_facebook_image_url?: string, montage_linkedin_image_url?: string, ... (12 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/newsletter_settings/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: newsletter_setting, var: newsletter_setting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, newsletter_setting: $newsletter_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all newsletters
#
# GET /newsletters
# Returns: record<newsletters: table<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>>
# operationId: findNewsletters
export def "find-newsletters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/newsletters"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a newsletter by ID
#
# GET /newsletters/{id}
# Returns: record<newsletter: record<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>>
# operationId: getNewsletterByID
export def "get-newsletter-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/newsletters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a newsletter
#
# PUT /newsletters/{id}
# Returns: record<newsletter: record<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>>
# operationId: updateNewsletterByID
export def "update-newsletter-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --click-count: int # format: int64
  --is-default: oneof<nothing, bool>
  --is-sent: oneof<nothing, bool>
  --total-click-count: int # format: int64
  --unique-click-count: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/newsletters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: click_count, var: click_count}, {name: is_default, var: is_default}, {name: is_sent, var: is_sent}, {name: total_click_count, var: total_click_count}, {name: unique_click_count, var: unique_click_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, click_count: $click_count, is_default: $is_default, is_sent: $is_sent, total_click_count: $total_click_count, unique_click_count: $unique_click_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query all posts
#
# GET /posts
# Returns: record<posts: table<_id: string, advisor_id: string, approval_status: string, approval_transactions: list, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>>
# operationId: findPosts
export def "find-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --text-query: string # Filter post by parameters
  --external-url: string # Filter by External URL
  --is-published: string # Filter by is_published boolean
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}, {name: text_query, var: text_query}, {name: external_url, var: external_url}, {name: is_published, var: is_published}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, text_query: $text_query, external_url: $external_url, is_published: $is_published
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new post in the Vestorly Platform
#
# POST /posts
# Returns: record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>>
# operationId: createPost
export def "create-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --advisor-id: string
  --approval-status: string
  --approval-transactions: list<string>
  --article-id: string
  --comment: string
  --created-at: string
  --display-date: string
  --display-summary: string
  --display-tag: string
  --external-url: string
  --external-url-source: string
  --external-url-type: string
  --group-ids: list<string>
  --image-height: string
  --image-path: string
  --image-url: string
  --image-width: string
  --is-featured: oneof<nothing, bool>
  --is-mobile-proxy-needed: oneof<nothing, bool>
  --is-proxy-needed: oneof<nothing, bool>
  --is-published: oneof<nothing, bool>
  --is-responsive: oneof<nothing, bool>
  --logo-url: string
  --needs-sanitize: string
  --newsletter-ids: list<string>
  --post-date: string
  --proxy-url: string
  --slug: string
  --square-logo-url: string
  --suitability-score: string
  --summary: string
  title: string
  --topic: string
  --updated-at: string
  --vestorly-url: string
  --video: string
  --video-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/posts"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: advisor_id, var: advisor_id}, {name: approval_status, var: approval_status}, {name: approval_transactions, var: approval_transactions}, {name: article_id, var: article_id}, {name: comment, var: comment}, {name: created_at, var: created_at}, {name: display_date, var: display_date}, {name: display_summary, var: display_summary}, {name: display_tag, var: display_tag}, {name: external_url, var: external_url}, {name: external_url_source, var: external_url_source}, {name: external_url_type, var: external_url_type}, {name: group_ids, var: group_ids}, {name: image_height, var: image_height}, {name: image_path, var: image_path}, {name: image_url, var: image_url}, {name: image_width, var: image_width}, {name: is_featured, var: is_featured}, {name: is_mobile_proxy_needed, var: is_mobile_proxy_needed}, {name: is_proxy_needed, var: is_proxy_needed}, {name: is_published, var: is_published}, {name: is_responsive, var: is_responsive}, {name: logo_url, var: logo_url}, {name: needs_sanitize, var: needs_sanitize}, {name: newsletter_ids, var: newsletter_ids}, {name: post_date, var: post_date}, {name: proxy_url, var: proxy_url}, {name: slug, var: slug}, {name: square_logo_url, var: square_logo_url}, {name: suitability_score, var: suitability_score}, {name: summary, var: summary}, {name: title, var: title}, {name: topic, var: topic}, {name: updated_at, var: updated_at}, {name: vestorly_url, var: vestorly_url}, {name: video, var: video}, {name: video_id, var: video_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, advisor_id: $advisor_id, approval_status: $approval_status, approval_transactions: $approval_transactions, article_id: $article_id, comment: $comment, created_at: $created_at, display_date: $display_date, display_summary: $display_summary, display_tag: $display_tag, external_url: $external_url, external_url_source: $external_url_source, external_url_type: $external_url_type, group_ids: $group_ids, image_height: $image_height, image_path: $image_path, image_url: $image_url, image_width: $image_width, is_featured: $is_featured, is_mobile_proxy_needed: $is_mobile_proxy_needed, is_proxy_needed: $is_proxy_needed, is_published: $is_published, is_responsive: $is_responsive, logo_url: $logo_url, needs_sanitize: $needs_sanitize, newsletter_ids: $newsletter_ids, post_date: $post_date, proxy_url: $proxy_url, slug: $slug, square_logo_url: $square_logo_url, suitability_score: $suitability_score, summary: $summary, title: $title, topic: $topic, updated_at: $updated_at, vestorly_url: $vestorly_url, video: $video, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query all posts
#
# GET /posts/{id}
# Returns: record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>>
# operationId: getPostByID
export def "get-post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update A Post
#
# PUT /posts/{id}
# Returns: record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>>
# operationId: updatePostByID
export def "update-post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --body-id: string # (spec name: _id)
  --advisor-id: string
  --approval-status: string
  --approval-transactions: list<string>
  --article-id: string
  --comment: string
  --created-at: string
  --display-date: string
  --display-summary: string
  --display-tag: string
  --external-url: string
  --external-url-source: string
  --external-url-type: string
  --group-ids: list<string>
  --image-height: string
  --image-path: string
  --image-url: string
  --image-width: string
  --is-featured: oneof<nothing, bool>
  --is-mobile-proxy-needed: oneof<nothing, bool>
  --is-proxy-needed: oneof<nothing, bool>
  --is-published: oneof<nothing, bool>
  --is-responsive: oneof<nothing, bool>
  --logo-url: string
  --needs-sanitize: string
  --newsletter-ids: list<string>
  --post-date: string
  --proxy-url: string
  --redirector-link: string
  --slug: string
  --square-logo-url: string
  --suitability-score: string
  --summary: string
  --title: string
  --topic: string
  --updated-at: string
  --vestorly-url: string
  --video: string
  --video-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/posts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: _id, var: body_id}, {name: advisor_id, var: advisor_id}, {name: approval_status, var: approval_status}, {name: approval_transactions, var: approval_transactions}, {name: article_id, var: article_id}, {name: comment, var: comment}, {name: created_at, var: created_at}, {name: display_date, var: display_date}, {name: display_summary, var: display_summary}, {name: display_tag, var: display_tag}, {name: external_url, var: external_url}, {name: external_url_source, var: external_url_source}, {name: external_url_type, var: external_url_type}, {name: group_ids, var: group_ids}, {name: image_height, var: image_height}, {name: image_path, var: image_path}, {name: image_url, var: image_url}, {name: image_width, var: image_width}, {name: is_featured, var: is_featured}, {name: is_mobile_proxy_needed, var: is_mobile_proxy_needed}, {name: is_proxy_needed, var: is_proxy_needed}, {name: is_published, var: is_published}, {name: is_responsive, var: is_responsive}, {name: logo_url, var: logo_url}, {name: needs_sanitize, var: needs_sanitize}, {name: newsletter_ids, var: newsletter_ids}, {name: post_date, var: post_date}, {name: proxy_url, var: proxy_url}, {name: redirector_link, var: redirector_link}, {name: slug, var: slug}, {name: square_logo_url, var: square_logo_url}, {name: suitability_score, var: suitability_score}, {name: summary, var: summary}, {name: title, var: title}, {name: topic, var: topic}, {name: updated_at, var: updated_at}, {name: vestorly_url, var: vestorly_url}, {name: video, var: video}, {name: video_id, var: video_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, body_id: $body_id, advisor_id: $advisor_id, approval_status: $approval_status, approval_transactions: $approval_transactions, article_id: $article_id, comment: $comment, created_at: $created_at, display_date: $display_date, display_summary: $display_summary, display_tag: $display_tag, external_url: $external_url, external_url_source: $external_url_source, external_url_type: $external_url_type, group_ids: $group_ids, image_height: $image_height, image_path: $image_path, image_url: $image_url, image_width: $image_width, is_featured: $is_featured, is_mobile_proxy_needed: $is_mobile_proxy_needed, is_proxy_needed: $is_proxy_needed, is_published: $is_published, is_responsive: $is_responsive, logo_url: $logo_url, needs_sanitize: $needs_sanitize, newsletter_ids: $newsletter_ids, post_date: $post_date, proxy_url: $proxy_url, redirector_link: $redirector_link, slug: $slug, square_logo_url: $square_logo_url, suitability_score: $suitability_score, summary: $summary, title: $title, topic: $topic, updated_at: $updated_at, vestorly_url: $vestorly_url, video: $video, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all Categories keywords
#
# GET /seed_custom_feeds
# Returns: record<seed_custom_feeds: table<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list, seeds: list, sort_by: string>>
# operationId: findSeedCustomFeeds
export def "find-seed-custom-feeds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/seed_custom_feeds"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Category Keyword
#
# POST /seed_custom_feeds
# Returns: record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>>
# operationId: createSeedCustomFeed
export def "create-seed-custom-feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --article-id: string
  custom_feed_id: string
  --not-article-id: string
  --not-seeds: list<string>
  --seeds: list<string>
  --sort-by: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/seed_custom_feeds"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: article_id, var: article_id}, {name: custom_feed_id, var: custom_feed_id}, {name: not_article_id, var: not_article_id}, {name: not_seeds, var: not_seeds}, {name: seeds, var: seeds}, {name: sort_by, var: sort_by}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, article_id: $article_id, custom_feed_id: $custom_feed_id, not_article_id: $not_article_id, not_seeds: $not_seeds, seeds: $seeds, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Category keywords
#
# DELETE /seed_custom_feeds/{id}
# Returns: record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>>
# operationId: deleteSeedCustomFeed
export def "delete-seed-custom-feed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/seed_custom_feeds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single Category keyword
#
# GET /seed_custom_feeds/{id}
# Returns: record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>>
# operationId: findSeedCustomFeedByID
export def "find-seed-custom-feed-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/seed_custom_feeds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Category keywords
#
# PUT /seed_custom_feeds/{id}
# Returns: record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>>
# operationId: updateSeedCustomFeedById
export def "update-seed-custom-feed-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --article-id: string
  custom_feed_id: string
  --not-article-id: string
  --not-seeds: list<string>
  --seeds: list<string>
  --sort-by: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/seed_custom_feeds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: article_id, var: article_id}, {name: custom_feed_id, var: custom_feed_id}, {name: not_article_id, var: not_article_id}, {name: not_seeds, var: not_seeds}, {name: seeds, var: seeds}, {name: sort_by, var: sort_by}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, article_id: $article_id, custom_feed_id: $custom_feed_id, not_article_id: $not_article_id, not_seeds: $not_seeds, seeds: $seeds, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login To Vestorly Platform
#
# POST /sessions
# Returns: record<_id: string, current_user: record<_id: string, company: string, first_name: string, last_name: string, name: string, new_user: bool, picture_url: string, plan_expired: bool, plan_id: string, plan_setup: bool, plan_status: string, plan_stripe: bool, show_tour: bool, slug: string, user_type: string, username: string, website: string>, new_user: bool, settings: record<_id: string, adv_brochure: string, company: string, disclosure: string, feature: record<_id: string>, name: string, orgsetting: record<_id: string, company_address: string, company_contact_email: string, company_homepage_url: string, is_default: bool, name: string, privacy_policy_url: string, site_url: string, terms_and_conditions_url: string>, personalsetting: record<_id: string>, picture_url: string, slug: string, website: string>, vestorly-auth: string>
# operationId: login
export def "login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username in the vestorly platform (required)
  --password: string # Password in Vestorly Platform (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sessions"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logout of the vestorly platform
#
# DELETE /sessions/{id}
# Returns: record<message: string>
# operationId: logout
export def "logout" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Authenication token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/sessions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all sources
#
# GET /sources
# Returns: record<sources: table<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>>
# operationId: findSources
export def "find-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sources"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create source
#
# POST /sources
# Returns: record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>>
# operationId: createSource
export def "create-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --custom-rss-feed: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --logo-url: string
  name: string
  rss_publisher: string
  url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sources"
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_rss_feed, var: custom_rss_feed}, {name: enabled, var: enabled}, {name: logo_url, var: logo_url}, {name: name, var: name}, {name: rss_publisher, var: rss_publisher}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vestorly_auth: $vestorly_auth, access_token: $access_token, custom_rss_feed: $custom_rss_feed, enabled: $enabled, logo_url: $logo_url, name: $name, rss_publisher: $rss_publisher, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Source By ID
#
# GET /sources/{id}
# Returns: record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>>
# operationId: getSourceByID
export def "get-source-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sources/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Source By ID
#
# PUT /sources/{id}
# Returns: record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>>
# operationId: updateSourceByID
export def "update-source-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (required)
  --access-token: string # OAuth Token
  --custom-rss-feed: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --logo-url: string
  name: string
  rss_publisher: string
  url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sources/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: vestorly_auth, var: vestorly_auth, required: true}, {name: access_token, var: access_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_rss_feed, var: custom_rss_feed}, {name: enabled, var: enabled}, {name: logo_url, var: logo_url}, {name: name, var: name}, {name: rss_publisher, var: rss_publisher}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vestorly_auth: $vestorly_auth, access_token: $access_token, custom_rss_feed: $custom_rss_feed, enabled: $enabled, logo_url: $logo_url, name: $name, rss_publisher: $rss_publisher, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
