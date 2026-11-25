# Auto-generated client for Google Analytics API v3
# Source: https://api.apis.guru/v2/specs/googleapis.com/analytics/v3/openapi.json
# Auth: --token flag or $env.GOOGLE_ANALYTICS_API_TOKEN

const CLIENT = {
  base_url: "https://analytics.googleapis.com/analytics/v3"
  token_env_var: "GOOGLE_ANALYTICS_API_TOKEN"
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

def base-url-completer [] { ["https://analytics.googleapis.com/analytics/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def output-completer [] { ["dataTable" "json"] }
def sampling-level-completer [] { ["DEFAULT" "FASTER" "HIGHER_PRECISION"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    analytics-data-ga-get: "record<columnHeaders: table<columnType: string, dataType: string, name: string>, containsSampledData: bool, dataLastRefreshed: string, dataTable: record<cols: list<record>, rows: list<record>>, id: string, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, end-date: string, filters: string, ids: string, max-results: int, metrics: list<string>, samplingLevel: string, segment: string, sort: list<string>, start-date: string, start-index: int>, rows: list<list<string>>, sampleSize: string, sampleSpace: string, selfLink: string, totalResults: int, totalsForAllResults: record>"
    analytics-data-mcf-get: "record<columnHeaders: table<columnType: string, dataType: string, name: string>, containsSampledData: bool, id: string, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, end-date: string, filters: string, ids: string, max-results: int, metrics: list<string>, samplingLevel: string, segment: string, sort: list<string>, start-date: string, start-index: int>, rows: list<list<record>>, sampleSize: string, sampleSpace: string, selfLink: string, totalResults: int, totalsForAllResults: record>"
    analytics-data-realtime-get: "record<columnHeaders: table<columnType: string, dataType: string, name: string>, id: string, kind: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, filters: string, ids: string, max-results: int, metrics: list<string>, sort: list<string>>, rows: list<list<string>>, selfLink: string, totalResults: int, totalsForAllResults: record>"
    analytics-management-account-summaries-list: "record<items: table<id: string, kind: string, name: string, starred: bool, webProperties: list>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-accounts-list: "record<items: table<childLink: record, created: string, id: string, kind: string, name: string, permissions: record, selfLink: string, starred: bool, updated: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-account-user-links-list: "record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>"
    analytics-management-account-user-links-insert: "record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>"
    analytics-management-account-user-links-update: "record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>"
    analytics-management-filters-list: "record<items: table<accountId: string, advancedDetails: record, created: string, excludeDetails: record, id: string, includeDetails: record, kind: string, lowercaseDetails: record, name: string, parentLink: record, searchAndReplaceDetails: record, selfLink: string, type: string, updated: string, uppercaseDetails: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-filters-insert: "record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>"
    analytics-management-filters-delete: "record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>"
    analytics-management-filters-get: "record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>"
    analytics-management-filters-patch: "record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>"
    analytics-management-filters-update: "record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>"
    analytics-management-webproperties-list: "record<items: table<accountId: string, childLink: record, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record, permissions: record, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-webproperties-insert: "record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>"
    analytics-management-webproperties-get: "record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>"
    analytics-management-webproperties-patch: "record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>"
    analytics-management-webproperties-update: "record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>"
    analytics-management-custom-data-sources-list: "record<items: table<accountId: string, childLink: record, created: string, description: string, id: string, importBehavior: string, kind: string, name: string, parentLink: record, profilesLinked: list, schema: list, selfLink: string, type: string, updated: string, uploadType: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-uploads-list: "record<items: table<accountId: string, customDataSourceId: string, errors: list, id: string, kind: string, status: string, uploadTime: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>"
    analytics-management-uploads-upload-data: "record<accountId: string, customDataSourceId: string, errors: list<string>, id: string, kind: string, status: string, uploadTime: string>"
    analytics-management-uploads-get: "record<accountId: string, customDataSourceId: string, errors: list<string>, id: string, kind: string, status: string, uploadTime: string>"
    analytics-management-custom-dimensions-list: "record<items: table<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record, scope: string, selfLink: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-custom-dimensions-insert: "record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string>"
    analytics-management-custom-dimensions-get: "record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string>"
    analytics-management-custom-dimensions-patch: "record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string>"
    analytics-management-custom-dimensions-update: "record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string>"
    analytics-management-custom-metrics-list: "record<items: table<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-custom-metrics-insert: "record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>"
    analytics-management-custom-metrics-get: "record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>"
    analytics-management-custom-metrics-patch: "record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>"
    analytics-management-custom-metrics-update: "record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>"
    analytics-management-web-property-ad-words-links-list: "record<items: table<adWordsAccounts: list, entity: record, id: string, kind: string, name: string, profileIds: list, selfLink: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>"
    analytics-management-web-property-ad-words-links-insert: "record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string>"
    analytics-management-web-property-ad-words-links-get: "record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string>"
    analytics-management-web-property-ad-words-links-patch: "record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string>"
    analytics-management-web-property-ad-words-links-update: "record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string>"
    analytics-management-webproperty-user-links-list: "record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>"
    analytics-management-webproperty-user-links-insert: "record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>"
    analytics-management-webproperty-user-links-update: "record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>"
    analytics-management-profiles-list: "record<items: table<accountId: string, botFilteringEnabled: bool, childLink: record, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record, permissions: record, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-profiles-insert: "record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>"
    analytics-management-profiles-get: "record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>"
    analytics-management-profiles-patch: "record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>"
    analytics-management-profiles-update: "record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>"
    analytics-management-profile-user-links-list: "record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>"
    analytics-management-profile-user-links-insert: "record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>"
    analytics-management-profile-user-links-update: "record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>"
    analytics-management-experiments-list: "record<items: table<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: list, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-experiments-insert: "record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>"
    analytics-management-experiments-get: "record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>"
    analytics-management-experiments-patch: "record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>"
    analytics-management-experiments-update: "record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>"
    analytics-management-goals-list: "record<items: table<accountId: string, active: bool, created: string, eventDetails: record, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record, value: float, visitNumPagesDetails: record, visitTimeOnSiteDetails: record, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-goals-insert: "record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string>"
    analytics-management-goals-get: "record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string>"
    analytics-management-goals-patch: "record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string>"
    analytics-management-goals-update: "record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string>"
    analytics-management-profile-filter-links-list: "record<items: table<filterRef: record, id: string, kind: string, profileRef: record, rank: int, selfLink: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-profile-filter-links-insert: "record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string>"
    analytics-management-profile-filter-links-get: "record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string>"
    analytics-management-profile-filter-links-patch: "record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string>"
    analytics-management-profile-filter-links-update: "record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string>"
    analytics-management-unsampled-reports-list: "record<items: table<accountId: string, cloudStorageDownloadDetails: record, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record, end-date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start-date: string, status: string, title: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-unsampled-reports-insert: "record<accountId: string, cloudStorageDownloadDetails: record<bucketId: string, objectId: string>, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record<documentId: string>, end-date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start-date: string, status: string, title: string, updated: string, webPropertyId: string>"
    analytics-management-unsampled-reports-get: "record<accountId: string, cloudStorageDownloadDetails: record<bucketId: string, objectId: string>, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record<documentId: string>, end-date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start-date: string, status: string, title: string, updated: string, webPropertyId: string>"
    analytics-management-remarketing-audience-list: "record<items: table<accountId: string, audienceDefinition: record, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: list, linkedViews: list, name: string, stateBasedAudienceDefinition: record, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-management-remarketing-audience-insert: "record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string>"
    analytics-management-remarketing-audience-get: "record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string>"
    analytics-management-remarketing-audience-patch: "record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string>"
    analytics-management-remarketing-audience-update: "record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string>"
    analytics-management-client-id-hash-client-id: "record<clientId: string, hashedClientId: string, kind: string, webPropertyId: string>"
    analytics-management-segments-list: "record<items: table<created: string, definition: string, id: string, kind: string, name: string, segmentId: string, selfLink: string, type: string, updated: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>"
    analytics-metadata-columns-list: "record<attributeNames: list<string>, etag: string, items: table<attributes: record, id: string, kind: string>, kind: string, totalResults: int>"
    analytics-provisioning-create-account-ticket: "record<account: record<childLink: record<href: string, type: string>, created: string, id: string, kind: string, name: string, permissions: record<effective: list>, selfLink: string, starred: bool, updated: string>, id: string, kind: string, profile: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, redirectUri: string, webproperty: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>>"
    analytics-provisioning-create-account-tree: "record<account: record<childLink: record<href: string, type: string>, created: string, id: string, kind: string, name: string, permissions: record<effective: list>, selfLink: string, starred: bool, updated: string>, kind: string, profile: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, webproperty: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>>"
    analytics-user-deletion-user-deletion-request-upsert: "record<deletionRequestTime: string, firebaseProjectId: string, id: record<type: string, userId: string>, kind: string, propertyId: string, webPropertyId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["analytics-data-ga-get" "analytics-data-mcf-get" "analytics-data-realtime-get" "analytics-management-account-summaries-list" "analytics-management-accounts-list" "analytics-management-account-user-links-list" "analytics-management-account-user-links-insert" "analytics-management-account-user-links-delete" "analytics-management-account-user-links-update" "analytics-management-filters-list" "analytics-management-filters-insert" "analytics-management-filters-delete" "analytics-management-filters-get" "analytics-management-filters-patch" "analytics-management-filters-update" "analytics-management-webproperties-list" "analytics-management-webproperties-insert" "analytics-management-webproperties-get" "analytics-management-webproperties-patch" "analytics-management-webproperties-update" "analytics-management-custom-data-sources-list" "analytics-management-uploads-delete-upload-data" "analytics-management-uploads-list" "analytics-management-uploads-upload-data" "analytics-management-uploads-get" "analytics-management-custom-dimensions-list" "analytics-management-custom-dimensions-insert" "analytics-management-custom-dimensions-get" "analytics-management-custom-dimensions-patch" "analytics-management-custom-dimensions-update" "analytics-management-custom-metrics-list" "analytics-management-custom-metrics-insert" "analytics-management-custom-metrics-get" "analytics-management-custom-metrics-patch" "analytics-management-custom-metrics-update" "analytics-management-web-property-ad-words-links-list" "analytics-management-web-property-ad-words-links-insert" "analytics-management-web-property-ad-words-links-delete" "analytics-management-web-property-ad-words-links-get" "analytics-management-web-property-ad-words-links-patch" "analytics-management-web-property-ad-words-links-update" "analytics-management-webproperty-user-links-list" "analytics-management-webproperty-user-links-insert" "analytics-management-webproperty-user-links-delete" "analytics-management-webproperty-user-links-update" "analytics-management-profiles-list" "analytics-management-profiles-insert" "analytics-management-profiles-delete" "analytics-management-profiles-get" "analytics-management-profiles-patch" "analytics-management-profiles-update" "analytics-management-profile-user-links-list" "analytics-management-profile-user-links-insert" "analytics-management-profile-user-links-delete" "analytics-management-profile-user-links-update" "analytics-management-experiments-list" "analytics-management-experiments-insert" "analytics-management-experiments-delete" "analytics-management-experiments-get" "analytics-management-experiments-patch" "analytics-management-experiments-update" "analytics-management-goals-list" "analytics-management-goals-insert" "analytics-management-goals-get" "analytics-management-goals-patch" "analytics-management-goals-update" "analytics-management-profile-filter-links-list" "analytics-management-profile-filter-links-insert" "analytics-management-profile-filter-links-delete" "analytics-management-profile-filter-links-get" "analytics-management-profile-filter-links-patch" "analytics-management-profile-filter-links-update" "analytics-management-unsampled-reports-list" "analytics-management-unsampled-reports-insert" "analytics-management-unsampled-reports-delete" "analytics-management-unsampled-reports-get" "analytics-management-remarketing-audience-list" "analytics-management-remarketing-audience-insert" "analytics-management-remarketing-audience-delete" "analytics-management-remarketing-audience-get" "analytics-management-remarketing-audience-patch" "analytics-management-remarketing-audience-update" "analytics-management-client-id-hash-client-id" "analytics-management-segments-list" "analytics-metadata-columns-list" "analytics-provisioning-create-account-ticket" "analytics-provisioning-create-account-tree" "analytics-user-deletion-user-deletion-request-upsert" "commands"] | sort) } | get name | first)
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

# Returns Analytics data for a view (profile).
#
# GET /data/ga
# Returns: record<columnHeaders: table<columnType: string, dataType: string, name: string>, containsSampledData: bool, dataLastRefreshed: string, dataTable: record<cols: list<record>, rows: list<record>>, id: string, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, end-date: string, filters: string, ids: string, max-results: int, metrics: list<string>, samplingLevel: string, segment: string, sort: list<string>, start-date: string, start-index: int>, rows: list<list<string>>, sampleSize: string, sampleSpace: string, selfLink: string, totalResults: int, totalsForAllResults: record>
# operationId: analytics.data.ga.get
export def "analytics-data-ga-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ids: string # Unique table ID for retrieving Analytics data. Table ID is of the form ga:XXXX, where XXXX is the Analytics view (profile) ID. (required)
  --start-date: string # Start date for fetching Analytics data. Requests can specify a start date formatted as YYYY-MM-DD, or as a relative date (e.g., today, yesterday, or 7daysAgo). The default value is 7daysAgo. (required)
  --end-date: string # End date for fetching Analytics data. Request can should specify an end date formatted as YYYY-MM-DD, or as a relative date (e.g., today, yesterday, or 7daysAgo). The default value is yesterday. (required)
  --metrics: string # A comma-separated list of Analytics metrics. E.g., 'ga:sessions,ga:pageviews'. At least one metric must be specified. (required)
  --dimensions: string # A comma-separated list of Analytics dimensions. E.g., 'ga:browser,ga:city'.
  --filters: string # A comma-separated list of dimension or metric filters to be applied to Analytics data.
  --include-empty-rows: oneof<nothing, bool> # The response will include empty rows if this parameter is set to true, the default is true
  --max-results: int # The maximum number of entries to include in this feed.
  --output: string@output-completer # The selected format for the response. Default format is JSON.
  --sampling-level: string@sampling-level-completer # The desired sampling level.
  --segment: string # An Analytics segment to be applied to data.
  --sort: string # A comma-separated list of dimensions or metrics that determine the sort order for Analytics data.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/ga"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: ids, var: ids, required: true}, {name: start-date, var: start_date, required: true}, {name: end-date, var: end_date, required: true}, {name: metrics, var: metrics, required: true}, {name: dimensions, var: dimensions}, {name: filters, var: filters}, {name: include-empty-rows, var: include_empty_rows}, {name: max-results, var: max_results}, {name: output, var: output}, {name: samplingLevel, var: sampling_level}, {name: segment, var: segment}, {name: sort, var: sort}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ids: $ids, start_date: $start_date, end_date: $end_date, metrics: $metrics, dimensions: $dimensions, filters: $filters, include_empty_rows: $include_empty_rows, max_results: $max_results, output: $output, sampling_level: $sampling_level, segment: $segment, sort: $sort, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Analytics Multi-Channel Funnels data for a view (profile).
#
# GET /data/mcf
# Returns: record<columnHeaders: table<columnType: string, dataType: string, name: string>, containsSampledData: bool, id: string, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, end-date: string, filters: string, ids: string, max-results: int, metrics: list<string>, samplingLevel: string, segment: string, sort: list<string>, start-date: string, start-index: int>, rows: list<list<record>>, sampleSize: string, sampleSpace: string, selfLink: string, totalResults: int, totalsForAllResults: record>
# operationId: analytics.data.mcf.get
export def "analytics-data-mcf-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ids: string # Unique table ID for retrieving Analytics data. Table ID is of the form ga:XXXX, where XXXX is the Analytics view (profile) ID. (required)
  --start-date: string # Start date for fetching Analytics data. Requests can specify a start date formatted as YYYY-MM-DD, or as a relative date (e.g., today, yesterday, or 7daysAgo). The default value is 7daysAgo. (required)
  --end-date: string # End date for fetching Analytics data. Requests can specify a start date formatted as YYYY-MM-DD, or as a relative date (e.g., today, yesterday, or 7daysAgo). The default value is 7daysAgo. (required)
  --metrics: string # A comma-separated list of Multi-Channel Funnels metrics. E.g., 'mcf:totalConversions,mcf:totalConversionValue'. At least one metric must be specified. (required)
  --dimensions: string # A comma-separated list of Multi-Channel Funnels dimensions. E.g., 'mcf:source,mcf:medium'.
  --filters: string # A comma-separated list of dimension or metric filters to be applied to the Analytics data.
  --max-results: int # The maximum number of entries to include in this feed.
  --sampling-level: string@sampling-level-completer # The desired sampling level.
  --sort: string # A comma-separated list of dimensions or metrics that determine the sort order for the Analytics data.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/mcf"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: ids, var: ids, required: true}, {name: start-date, var: start_date, required: true}, {name: end-date, var: end_date, required: true}, {name: metrics, var: metrics, required: true}, {name: dimensions, var: dimensions}, {name: filters, var: filters}, {name: max-results, var: max_results}, {name: samplingLevel, var: sampling_level}, {name: sort, var: sort}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ids: $ids, start_date: $start_date, end_date: $end_date, metrics: $metrics, dimensions: $dimensions, filters: $filters, max_results: $max_results, sampling_level: $sampling_level, sort: $sort, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns real time data for a view (profile).
#
# GET /data/realtime
# Returns: record<columnHeaders: table<columnType: string, dataType: string, name: string>, id: string, kind: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, filters: string, ids: string, max-results: int, metrics: list<string>, sort: list<string>>, rows: list<list<string>>, selfLink: string, totalResults: int, totalsForAllResults: record>
# operationId: analytics.data.realtime.get
export def "analytics-data-realtime-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ids: string # Unique table ID for retrieving real time data. Table ID is of the form ga:XXXX, where XXXX is the Analytics view (profile) ID. (required)
  --metrics: string # A comma-separated list of real time metrics. E.g., 'rt:activeUsers'. At least one metric must be specified. (required)
  --dimensions: string # A comma-separated list of real time dimensions. E.g., 'rt:medium,rt:city'.
  --filters: string # A comma-separated list of dimension or metric filters to be applied to real time data.
  --max-results: int # The maximum number of entries to include in this feed.
  --sort: string # A comma-separated list of dimensions or metrics that determine the sort order for real time data.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/realtime"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: ids, var: ids, required: true}, {name: metrics, var: metrics, required: true}, {name: dimensions, var: dimensions}, {name: filters, var: filters}, {name: max-results, var: max_results}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ids: $ids, metrics: $metrics, dimensions: $dimensions, filters: $filters, max_results: $max_results, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists account summaries (lightweight tree comprised of accounts/properties/profiles) to which the user has access.
#
# GET /management/accountSummaries
# Returns: record<items: table<id: string, kind: string, name: string, starred: bool, webProperties: list>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.accountSummaries.list
export def "analytics-management-account-summaries-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of account summaries to include in this response, where the largest acceptable value is 1000.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accountSummaries"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all accounts to which the user has access.
#
# GET /management/accounts
# Returns: record<items: table<childLink: record, created: string, id: string, kind: string, name: string, permissions: record, selfLink: string, starred: bool, updated: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.accounts.list
export def "analytics-management-accounts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of accounts to include in this response.
  --start-index: int # An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists account-user links for a given account.
#
# GET /management/accounts/{accountId}/entityUserLinks
# Returns: record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>
# operationId: analytics.management.accountUserLinks.list
export def "analytics-management-account-user-links-list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of account-user links to include in this response.
  --start-index: int # An index of the first account-user link to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/entityUserLinks"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new user to the given account.
#
# POST /management/accounts/{accountId}/entityUserLinks
# Returns: record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>
# operationId: analytics.management.accountUserLinks.insert
export def "analytics-management-account-user-links-insert" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/entityUserLinks"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: permissions, var: permissions}, {name: selfLink, var: self_link}, {name: userRef, var: user_ref}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, entity: $entity, id: $id, kind: $kind, permissions: $permissions, self_link: $self_link, user_ref: $user_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from the given account.
#
# DELETE /management/accounts/{accountId}/entityUserLinks/{linkId}
# operationId: analytics.management.accountUserLinks.delete
export def "analytics-management-account-user-links-delete" [
  account_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/entityUserLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates permissions for an existing user on the given account.
#
# PUT /management/accounts/{accountId}/entityUserLinks/{linkId}
# Returns: record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>
# operationId: analytics.management.accountUserLinks.update
export def "analytics-management-account-user-links-update" [
  account_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/entityUserLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: permissions, var: permissions}, {name: selfLink, var: self_link}, {name: userRef, var: user_ref}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, entity: $entity, id: $id, kind: $kind, permissions: $permissions, self_link: $self_link, user_ref: $user_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all filters for an account
#
# GET /management/accounts/{accountId}/filters
# Returns: record<items: table<accountId: string, advancedDetails: record, created: string, excludeDetails: record, id: string, includeDetails: record, kind: string, lowercaseDetails: record, name: string, parentLink: record, searchAndReplaceDetails: record, selfLink: string, type: string, updated: string, uppercaseDetails: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.filters.list
export def "analytics-management-filters-list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of filters to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/filters"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new filter.
#
# POST /management/accounts/{accountId}/filters
# Returns: record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>
# operationId: analytics.management.filters.insert
export def "analytics-management-filters-insert" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this filter belongs. (spec name: accountId)
  --advanced-details: record # Details for the filter of the type ADVANCED. — shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
  --exclude-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --id: string # Filter ID.
  --include-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --lowercase-details: record # Details for the filter of the type LOWER. — shape: {field?: string, fieldIndex?: int}
  --name: string # Name of this filter.
  --parent-link: record # Parent link for this filter. Points to the account to which this filter belongs. — shape: {href?: string, type?: string}
  --search-and-replace-details: record # Details for the filter of the type SEARCH_AND_REPLACE. — shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
  --type: string # Type of this filter. Possible values are INCLUDE, EXCLUDE, LOWERCASE, UPPERCASE, SEARCH_AND_REPLACE and ADVANCED.
  --uppercase-details: record # Details for the filter of the type UPPER. — shape: {field?: string, fieldIndex?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/filters"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: advancedDetails, var: advanced_details}, {name: excludeDetails, var: exclude_details}, {name: id, var: id}, {name: includeDetails, var: include_details}, {name: lowercaseDetails, var: lowercase_details}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: searchAndReplaceDetails, var: search_and_replace_details}, {name: type, var: type}, {name: uppercaseDetails, var: uppercase_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, advanced_details: $advanced_details, exclude_details: $exclude_details, id: $id, include_details: $include_details, lowercase_details: $lowercase_details, name: $name, parent_link: $parent_link, search_and_replace_details: $search_and_replace_details, type: $type, uppercase_details: $uppercase_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a filter.
#
# DELETE /management/accounts/{accountId}/filters/{filterId}
# Returns: record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>
# operationId: analytics.management.filters.delete
export def "analytics-management-filters-delete" [
  account_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/filters/{filterId}"
    path_params: [{name: accountId, var: account_id}, {name: filterId, var: filter_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, filter_id: $filter_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns filters to which the user has access.
#
# GET /management/accounts/{accountId}/filters/{filterId}
# Returns: record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>
# operationId: analytics.management.filters.get
export def "analytics-management-filters-get" [
  account_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/filters/{filterId}"
    path_params: [{name: accountId, var: account_id}, {name: filterId, var: filter_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, filter_id: $filter_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing filter. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/filters/{filterId}
# Returns: record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>
# operationId: analytics.management.filters.patch
export def "analytics-management-filters-patch" [
  account_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this filter belongs. (spec name: accountId)
  --advanced-details: record # Details for the filter of the type ADVANCED. — shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
  --exclude-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --id: string # Filter ID.
  --include-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --lowercase-details: record # Details for the filter of the type LOWER. — shape: {field?: string, fieldIndex?: int}
  --name: string # Name of this filter.
  --parent-link: record # Parent link for this filter. Points to the account to which this filter belongs. — shape: {href?: string, type?: string}
  --search-and-replace-details: record # Details for the filter of the type SEARCH_AND_REPLACE. — shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
  --type: string # Type of this filter. Possible values are INCLUDE, EXCLUDE, LOWERCASE, UPPERCASE, SEARCH_AND_REPLACE and ADVANCED.
  --uppercase-details: record # Details for the filter of the type UPPER. — shape: {field?: string, fieldIndex?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/filters/{filterId}"
    path_params: [{name: accountId, var: account_id}, {name: filterId, var: filter_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: advancedDetails, var: advanced_details}, {name: excludeDetails, var: exclude_details}, {name: id, var: id}, {name: includeDetails, var: include_details}, {name: lowercaseDetails, var: lowercase_details}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: searchAndReplaceDetails, var: search_and_replace_details}, {name: type, var: type}, {name: uppercaseDetails, var: uppercase_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, filter_id: $filter_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, advanced_details: $advanced_details, exclude_details: $exclude_details, id: $id, include_details: $include_details, lowercase_details: $lowercase_details, name: $name, parent_link: $parent_link, search_and_replace_details: $search_and_replace_details, type: $type, uppercase_details: $uppercase_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing filter.
#
# PUT /management/accounts/{accountId}/filters/{filterId}
# Returns: record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>>
# operationId: analytics.management.filters.update
export def "analytics-management-filters-update" [
  account_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this filter belongs. (spec name: accountId)
  --advanced-details: record # Details for the filter of the type ADVANCED. — shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
  --exclude-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --id: string # Filter ID.
  --include-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --lowercase-details: record # Details for the filter of the type LOWER. — shape: {field?: string, fieldIndex?: int}
  --name: string # Name of this filter.
  --parent-link: record # Parent link for this filter. Points to the account to which this filter belongs. — shape: {href?: string, type?: string}
  --search-and-replace-details: record # Details for the filter of the type SEARCH_AND_REPLACE. — shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
  --type: string # Type of this filter. Possible values are INCLUDE, EXCLUDE, LOWERCASE, UPPERCASE, SEARCH_AND_REPLACE and ADVANCED.
  --uppercase-details: record # Details for the filter of the type UPPER. — shape: {field?: string, fieldIndex?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/filters/{filterId}"
    path_params: [{name: accountId, var: account_id}, {name: filterId, var: filter_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: advancedDetails, var: advanced_details}, {name: excludeDetails, var: exclude_details}, {name: id, var: id}, {name: includeDetails, var: include_details}, {name: lowercaseDetails, var: lowercase_details}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: searchAndReplaceDetails, var: search_and_replace_details}, {name: type, var: type}, {name: uppercaseDetails, var: uppercase_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, filter_id: $filter_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, advanced_details: $advanced_details, exclude_details: $exclude_details, id: $id, include_details: $include_details, lowercase_details: $lowercase_details, name: $name, parent_link: $parent_link, search_and_replace_details: $search_and_replace_details, type: $type, uppercase_details: $uppercase_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists web properties to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties
# Returns: record<items: table<accountId: string, childLink: record, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record, permissions: record, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.webproperties.list
export def "analytics-management-webproperties-list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of web properties to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new property if the account has fewer than 20 properties. Web properties are visible in the Google Analytics interface only if they have at least one profile.
#
# POST /management/accounts/{accountId}/webproperties
# Returns: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>
# operationId: analytics.management.webproperties.insert
export def "analytics-management-webproperties-insert" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this web property belongs. (spec name: accountId)
  --child-link: record # Child link for this web property. Points to the list of views (profiles) for this web property. — shape: {href?: string, type?: string}
  --data-retention-reset-on-new-activity: oneof<nothing, bool> # Set to true to reset the retention period of the user identifier with each new event from that user (thus setting the expiration date to current time plus retention period). Set to false to delete data associated with the user identifier automatically after the rentention period. This property cannot be set on insert.
  --data-retention-ttl: string # The length of time for which user and event data is retained. This property cannot be set on insert.
  --default-profile-id: string # Default view (profile) ID. (format: int64)
  --id: string # Web property ID of the form UA-XXXXX-YY.
  --industry-vertical: string # The industry vertical/category selected for this web property.
  --name: string # Name of this web property.
  --parent-link: record # Parent link for this web property. Points to the account to which this web property belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this web property.
  --starred: oneof<nothing, bool> # Indicates whether this web property is starred or not.
  --website-url: string # Website url for this web property.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: childLink, var: child_link}, {name: dataRetentionResetOnNewActivity, var: data_retention_reset_on_new_activity}, {name: dataRetentionTtl, var: data_retention_ttl}, {name: defaultProfileId, var: default_profile_id}, {name: id, var: id}, {name: industryVertical, var: industry_vertical}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: permissions, var: permissions}, {name: starred, var: starred}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, child_link: $child_link, data_retention_reset_on_new_activity: $data_retention_reset_on_new_activity, data_retention_ttl: $data_retention_ttl, default_profile_id: $default_profile_id, id: $id, industry_vertical: $industry_vertical, name: $name, parent_link: $parent_link, permissions: $permissions, starred: $starred, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a web property to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}
# Returns: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>
# operationId: analytics.management.webproperties.get
export def "analytics-management-webproperties-get" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing web property. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}
# Returns: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>
# operationId: analytics.management.webproperties.patch
export def "analytics-management-webproperties-patch" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this web property belongs. (spec name: accountId)
  --child-link: record # Child link for this web property. Points to the list of views (profiles) for this web property. — shape: {href?: string, type?: string}
  --data-retention-reset-on-new-activity: oneof<nothing, bool> # Set to true to reset the retention period of the user identifier with each new event from that user (thus setting the expiration date to current time plus retention period). Set to false to delete data associated with the user identifier automatically after the rentention period. This property cannot be set on insert.
  --data-retention-ttl: string # The length of time for which user and event data is retained. This property cannot be set on insert.
  --default-profile-id: string # Default view (profile) ID. (format: int64)
  --id: string # Web property ID of the form UA-XXXXX-YY.
  --industry-vertical: string # The industry vertical/category selected for this web property.
  --name: string # Name of this web property.
  --parent-link: record # Parent link for this web property. Points to the account to which this web property belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this web property.
  --starred: oneof<nothing, bool> # Indicates whether this web property is starred or not.
  --website-url: string # Website url for this web property.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: childLink, var: child_link}, {name: dataRetentionResetOnNewActivity, var: data_retention_reset_on_new_activity}, {name: dataRetentionTtl, var: data_retention_ttl}, {name: defaultProfileId, var: default_profile_id}, {name: id, var: id}, {name: industryVertical, var: industry_vertical}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: permissions, var: permissions}, {name: starred, var: starred}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, child_link: $child_link, data_retention_reset_on_new_activity: $data_retention_reset_on_new_activity, data_retention_ttl: $data_retention_ttl, default_profile_id: $default_profile_id, id: $id, industry_vertical: $industry_vertical, name: $name, parent_link: $parent_link, permissions: $permissions, starred: $starred, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing web property.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}
# Returns: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>
# operationId: analytics.management.webproperties.update
export def "analytics-management-webproperties-update" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this web property belongs. (spec name: accountId)
  --child-link: record # Child link for this web property. Points to the list of views (profiles) for this web property. — shape: {href?: string, type?: string}
  --data-retention-reset-on-new-activity: oneof<nothing, bool> # Set to true to reset the retention period of the user identifier with each new event from that user (thus setting the expiration date to current time plus retention period). Set to false to delete data associated with the user identifier automatically after the rentention period. This property cannot be set on insert.
  --data-retention-ttl: string # The length of time for which user and event data is retained. This property cannot be set on insert.
  --default-profile-id: string # Default view (profile) ID. (format: int64)
  --id: string # Web property ID of the form UA-XXXXX-YY.
  --industry-vertical: string # The industry vertical/category selected for this web property.
  --name: string # Name of this web property.
  --parent-link: record # Parent link for this web property. Points to the account to which this web property belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this web property.
  --starred: oneof<nothing, bool> # Indicates whether this web property is starred or not.
  --website-url: string # Website url for this web property.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: childLink, var: child_link}, {name: dataRetentionResetOnNewActivity, var: data_retention_reset_on_new_activity}, {name: dataRetentionTtl, var: data_retention_ttl}, {name: defaultProfileId, var: default_profile_id}, {name: id, var: id}, {name: industryVertical, var: industry_vertical}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: permissions, var: permissions}, {name: starred, var: starred}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, child_link: $child_link, data_retention_reset_on_new_activity: $data_retention_reset_on_new_activity, data_retention_ttl: $data_retention_ttl, default_profile_id: $default_profile_id, id: $id, industry_vertical: $industry_vertical, name: $name, parent_link: $parent_link, permissions: $permissions, starred: $starred, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List custom data sources to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources
# Returns: record<items: table<accountId: string, childLink: record, created: string, description: string, id: string, importBehavior: string, kind: string, name: string, parentLink: record, profilesLinked: list, schema: list, selfLink: string, type: string, updated: string, uploadType: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.customDataSources.list
export def "analytics-management-custom-data-sources-list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of custom data sources to include in this response.
  --start-index: int # A 1-based index of the first custom data source to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete data associated with a previous upload.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/deleteUploadData
# operationId: analytics.management.uploads.deleteUploadData
export def "analytics-management-uploads-delete-upload-data" [
  account_id: string
  web_property_id: string
  custom_data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --custom-data-import-uids: list<string> # A list of upload UIDs.
]: any -> any {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/deleteUploadData"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customDataSourceId, var: custom_data_source_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: customDataImportUids, var: custom_data_import_uids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_data_source_id: $custom_data_source_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, custom_data_import_uids: $custom_data_import_uids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List uploads to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads
# Returns: record<items: table<accountId: string, customDataSourceId: string, errors: list, id: string, kind: string, status: string, uploadTime: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>
# operationId: analytics.management.uploads.list
export def "analytics-management-uploads-list" [
  account_id: string
  web_property_id: string
  custom_data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of uploads to include in this response.
  --start-index: int # A 1-based index of the first upload to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customDataSourceId, var: custom_data_source_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_data_source_id: $custom_data_source_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload data for a custom data source.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads
# Returns: record<accountId: string, customDataSourceId: string, errors: list<string>, id: string, kind: string, status: string, uploadTime: string>
# operationId: analytics.management.uploads.uploadData
export def "analytics-management-uploads-upload-data" [
  account_id: string
  web_property_id: string
  custom_data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customDataSourceId, var: custom_data_source_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_data_source_id: $custom_data_source_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List uploads to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads/{uploadId}
# Returns: record<accountId: string, customDataSourceId: string, errors: list<string>, id: string, kind: string, status: string, uploadTime: string>
# operationId: analytics.management.uploads.get
export def "analytics-management-uploads-get" [
  account_id: string
  web_property_id: string
  custom_data_source_id: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads/{uploadId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customDataSourceId, var: custom_data_source_id}, {name: uploadId, var: upload_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_data_source_id: $custom_data_source_id, upload_id: $upload_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists custom dimensions to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions
# Returns: record<items: table<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record, scope: string, selfLink: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.customDimensions.list
export def "analytics-management-custom-dimensions-list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of custom dimensions to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new custom dimension.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions
# Returns: record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string>
# operationId: analytics.management.customDimensions.insert
export def "analytics-management-custom-dimensions-insert" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID. (spec name: accountId)
  --active: oneof<nothing, bool> # Boolean indicating whether the custom dimension is active.
  --id: string # Custom dimension ID.
  --name: string # Name of the custom dimension.
  --parent-link: record # Parent link for the custom dimension. Points to the property to which the custom dimension belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom dimension: HIT, SESSION, USER or PRODUCT.
  --body-web-property-id: string # Property ID. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: id, var: id}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: scope, var: scope}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, active: $active, id: $id, name: $name, parent_link: $parent_link, scope: $scope, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a custom dimension to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}
# Returns: record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string>
# operationId: analytics.management.customDimensions.get
export def "analytics-management-custom-dimensions-get" [
  account_id: string
  web_property_id: string
  custom_dimension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customDimensionId, var: custom_dimension_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_dimension_id: $custom_dimension_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing custom dimension. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}
# Returns: record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string>
# operationId: analytics.management.customDimensions.patch
export def "analytics-management-custom-dimensions-patch" [
  account_id: string
  web_property_id: string
  custom_dimension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-custom-data-source-links: oneof<nothing, bool> # Force the update and ignore any warnings related to the custom dimension being linked to a custom data source / data set.
  --body-account-id: string # Account ID. (spec name: accountId)
  --active: oneof<nothing, bool> # Boolean indicating whether the custom dimension is active.
  --id: string # Custom dimension ID.
  --name: string # Name of the custom dimension.
  --parent-link: record # Parent link for the custom dimension. Points to the property to which the custom dimension belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom dimension: HIT, SESSION, USER or PRODUCT.
  --body-web-property-id: string # Property ID. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customDimensionId, var: custom_dimension_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: ignoreCustomDataSourceLinks, var: ignore_custom_data_source_links}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: id, var: id}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: scope, var: scope}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_dimension_id: $custom_dimension_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ignore_custom_data_source_links: $ignore_custom_data_source_links, body_account_id: $body_account_id, active: $active, id: $id, name: $name, parent_link: $parent_link, scope: $scope, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing custom dimension.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}
# Returns: record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string>
# operationId: analytics.management.customDimensions.update
export def "analytics-management-custom-dimensions-update" [
  account_id: string
  web_property_id: string
  custom_dimension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-custom-data-source-links: oneof<nothing, bool> # Force the update and ignore any warnings related to the custom dimension being linked to a custom data source / data set.
  --body-account-id: string # Account ID. (spec name: accountId)
  --active: oneof<nothing, bool> # Boolean indicating whether the custom dimension is active.
  --id: string # Custom dimension ID.
  --name: string # Name of the custom dimension.
  --parent-link: record # Parent link for the custom dimension. Points to the property to which the custom dimension belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom dimension: HIT, SESSION, USER or PRODUCT.
  --body-web-property-id: string # Property ID. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customDimensionId, var: custom_dimension_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: ignoreCustomDataSourceLinks, var: ignore_custom_data_source_links}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: id, var: id}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: scope, var: scope}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_dimension_id: $custom_dimension_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ignore_custom_data_source_links: $ignore_custom_data_source_links, body_account_id: $body_account_id, active: $active, id: $id, name: $name, parent_link: $parent_link, scope: $scope, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists custom metrics to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics
# Returns: record<items: table<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.customMetrics.list
export def "analytics-management-custom-metrics-list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of custom metrics to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new custom metric.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics
# Returns: record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>
# operationId: analytics.management.customMetrics.insert
export def "analytics-management-custom-metrics-insert" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID. (spec name: accountId)
  --active: oneof<nothing, bool> # Boolean indicating whether the custom metric is active.
  --id: string # Custom metric ID.
  --max-value: string # Max value of custom metric.
  --min-value: string # Min value of custom metric.
  --name: string # Name of the custom metric.
  --parent-link: record # Parent link for the custom metric. Points to the property to which the custom metric belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom metric: HIT or PRODUCT.
  --type: string # Data type of custom metric.
  --body-web-property-id: string # Property ID. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: id, var: id}, {name: max_value, var: max_value}, {name: min_value, var: min_value}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: scope, var: scope}, {name: type, var: type}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, active: $active, id: $id, max_value: $max_value, min_value: $min_value, name: $name, parent_link: $parent_link, scope: $scope, type: $type, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a custom metric to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}
# Returns: record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>
# operationId: analytics.management.customMetrics.get
export def "analytics-management-custom-metrics-get" [
  account_id: string
  web_property_id: string
  custom_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customMetricId, var: custom_metric_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_metric_id: $custom_metric_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing custom metric. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}
# Returns: record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>
# operationId: analytics.management.customMetrics.patch
export def "analytics-management-custom-metrics-patch" [
  account_id: string
  web_property_id: string
  custom_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-custom-data-source-links: oneof<nothing, bool> # Force the update and ignore any warnings related to the custom metric being linked to a custom data source / data set.
  --body-account-id: string # Account ID. (spec name: accountId)
  --active: oneof<nothing, bool> # Boolean indicating whether the custom metric is active.
  --id: string # Custom metric ID.
  --max-value: string # Max value of custom metric.
  --min-value: string # Min value of custom metric.
  --name: string # Name of the custom metric.
  --parent-link: record # Parent link for the custom metric. Points to the property to which the custom metric belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom metric: HIT or PRODUCT.
  --type: string # Data type of custom metric.
  --body-web-property-id: string # Property ID. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customMetricId, var: custom_metric_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: ignoreCustomDataSourceLinks, var: ignore_custom_data_source_links}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: id, var: id}, {name: max_value, var: max_value}, {name: min_value, var: min_value}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: scope, var: scope}, {name: type, var: type}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_metric_id: $custom_metric_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ignore_custom_data_source_links: $ignore_custom_data_source_links, body_account_id: $body_account_id, active: $active, id: $id, max_value: $max_value, min_value: $min_value, name: $name, parent_link: $parent_link, scope: $scope, type: $type, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing custom metric.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}
# Returns: record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>
# operationId: analytics.management.customMetrics.update
export def "analytics-management-custom-metrics-update" [
  account_id: string
  web_property_id: string
  custom_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-custom-data-source-links: oneof<nothing, bool> # Force the update and ignore any warnings related to the custom metric being linked to a custom data source / data set.
  --body-account-id: string # Account ID. (spec name: accountId)
  --active: oneof<nothing, bool> # Boolean indicating whether the custom metric is active.
  --id: string # Custom metric ID.
  --max-value: string # Max value of custom metric.
  --min-value: string # Min value of custom metric.
  --name: string # Name of the custom metric.
  --parent-link: record # Parent link for the custom metric. Points to the property to which the custom metric belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom metric: HIT or PRODUCT.
  --type: string # Data type of custom metric.
  --body-web-property-id: string # Property ID. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: customMetricId, var: custom_metric_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: ignoreCustomDataSourceLinks, var: ignore_custom_data_source_links}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: id, var: id}, {name: max_value, var: max_value}, {name: min_value, var: min_value}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: scope, var: scope}, {name: type, var: type}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, custom_metric_id: $custom_metric_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ignore_custom_data_source_links: $ignore_custom_data_source_links, body_account_id: $body_account_id, active: $active, id: $id, max_value: $max_value, min_value: $min_value, name: $name, parent_link: $parent_link, scope: $scope, type: $type, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists webProperty-Google Ads links for a given web property.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks
# Returns: record<items: table<adWordsAccounts: list, entity: record, id: string, kind: string, name: string, profileIds: list, selfLink: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>
# operationId: analytics.management.webPropertyAdWordsLinks.list
export def "analytics-management-web-property-ad-words-links-list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of webProperty-Google Ads links to include in this response.
  --start-index: int # An index of the first webProperty-Google Ads link to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a webProperty-Google Ads link.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks
# Returns: record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string>
# operationId: analytics.management.webPropertyAdWordsLinks.insert
export def "analytics-management-web-property-ad-words-links-insert" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ad-words-accounts: list # A list of Google Ads client accounts. These cannot be MCC accounts. This field is required when creating a Google Ads link. It cannot be empty. — item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
  --entity: record # Web property being linked. — shape: {webPropertyRef?: record}
  --id: string # Entity Google Ads link ID
  --kind: string # Resource type for entity Google Ads link. (default: analytics#entityAdWordsLink)
  --name: string # Name of the link. This field is required when creating a Google Ads link.
  --profile-ids: list<string> # IDs of linked Views (Profiles) represented as strings.
  --self-link: string # URL link for this Google Analytics - Google Ads link.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: adWordsAccounts, var: ad_words_accounts}, {name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: profileIds, var: profile_ids}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ad_words_accounts: $ad_words_accounts, entity: $entity, id: $id, kind: $kind, name: $name, profile_ids: $profile_ids, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a web property-Google Ads link.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}
# operationId: analytics.management.webPropertyAdWordsLinks.delete
export def "analytics-management-web-property-ad-words-links-delete" [
  account_id: string
  web_property_id: string
  web_property_ad_words_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: webPropertyAdWordsLinkId, var: web_property_ad_words_link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, web_property_ad_words_link_id: $web_property_ad_words_link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a web property-Google Ads link to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}
# Returns: record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string>
# operationId: analytics.management.webPropertyAdWordsLinks.get
export def "analytics-management-web-property-ad-words-links-get" [
  account_id: string
  web_property_id: string
  web_property_ad_words_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: webPropertyAdWordsLinkId, var: web_property_ad_words_link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, web_property_ad_words_link_id: $web_property_ad_words_link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing webProperty-Google Ads link. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}
# Returns: record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string>
# operationId: analytics.management.webPropertyAdWordsLinks.patch
export def "analytics-management-web-property-ad-words-links-patch" [
  account_id: string
  web_property_id: string
  web_property_ad_words_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ad-words-accounts: list # A list of Google Ads client accounts. These cannot be MCC accounts. This field is required when creating a Google Ads link. It cannot be empty. — item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
  --entity: record # Web property being linked. — shape: {webPropertyRef?: record}
  --id: string # Entity Google Ads link ID
  --kind: string # Resource type for entity Google Ads link. (default: analytics#entityAdWordsLink)
  --name: string # Name of the link. This field is required when creating a Google Ads link.
  --profile-ids: list<string> # IDs of linked Views (Profiles) represented as strings.
  --self-link: string # URL link for this Google Analytics - Google Ads link.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: webPropertyAdWordsLinkId, var: web_property_ad_words_link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: adWordsAccounts, var: ad_words_accounts}, {name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: profileIds, var: profile_ids}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, web_property_ad_words_link_id: $web_property_ad_words_link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ad_words_accounts: $ad_words_accounts, entity: $entity, id: $id, kind: $kind, name: $name, profile_ids: $profile_ids, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing webProperty-Google Ads link.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}
# Returns: record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string>
# operationId: analytics.management.webPropertyAdWordsLinks.update
export def "analytics-management-web-property-ad-words-links-update" [
  account_id: string
  web_property_id: string
  web_property_ad_words_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ad-words-accounts: list # A list of Google Ads client accounts. These cannot be MCC accounts. This field is required when creating a Google Ads link. It cannot be empty. — item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
  --entity: record # Web property being linked. — shape: {webPropertyRef?: record}
  --id: string # Entity Google Ads link ID
  --kind: string # Resource type for entity Google Ads link. (default: analytics#entityAdWordsLink)
  --name: string # Name of the link. This field is required when creating a Google Ads link.
  --profile-ids: list<string> # IDs of linked Views (Profiles) represented as strings.
  --self-link: string # URL link for this Google Analytics - Google Ads link.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: webPropertyAdWordsLinkId, var: web_property_ad_words_link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: adWordsAccounts, var: ad_words_accounts}, {name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: profileIds, var: profile_ids}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, web_property_ad_words_link_id: $web_property_ad_words_link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ad_words_accounts: $ad_words_accounts, entity: $entity, id: $id, kind: $kind, name: $name, profile_ids: $profile_ids, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists webProperty-user links for a given web property.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks
# Returns: record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>
# operationId: analytics.management.webpropertyUserLinks.list
export def "analytics-management-webproperty-user-links-list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of webProperty-user Links to include in this response.
  --start-index: int # An index of the first webProperty-user link to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new user to the given web property.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks
# Returns: record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>
# operationId: analytics.management.webpropertyUserLinks.insert
export def "analytics-management-webproperty-user-links-insert" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: permissions, var: permissions}, {name: selfLink, var: self_link}, {name: userRef, var: user_ref}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, entity: $entity, id: $id, kind: $kind, permissions: $permissions, self_link: $self_link, user_ref: $user_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from the given web property.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks/{linkId}
# operationId: analytics.management.webpropertyUserLinks.delete
export def "analytics-management-webproperty-user-links-delete" [
  account_id: string
  web_property_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates permissions for an existing user on the given web property.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks/{linkId}
# Returns: record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>
# operationId: analytics.management.webpropertyUserLinks.update
export def "analytics-management-webproperty-user-links-update" [
  account_id: string
  web_property_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: permissions, var: permissions}, {name: selfLink, var: self_link}, {name: userRef, var: user_ref}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, entity: $entity, id: $id, kind: $kind, permissions: $permissions, self_link: $self_link, user_ref: $user_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists views (profiles) to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles
# Returns: record<items: table<accountId: string, botFilteringEnabled: bool, childLink: record, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record, permissions: record, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.profiles.list
export def "analytics-management-profiles-list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of views (profiles) to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new view (profile).
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles
# Returns: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>
# operationId: analytics.management.profiles.insert
export def "analytics-management-profiles-insert" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this view (profile) belongs. (spec name: accountId)
  --bot-filtering-enabled: oneof<nothing, bool> # Indicates whether bot filtering is enabled for this view (profile).
  --child-link: record # Child link for this view (profile). Points to the list of goals for this view (profile). — shape: {href?: string, type?: string}
  --currency: string # The currency type associated with this view (profile), defaults to USD. The supported values are: USD, JPY, EUR, GBP, AUD, KRW, BRL, CNY, DKK, RUB, SEK, NOK, PLN, TRY, TWD, HKD, THB, IDR, ARS, MXN, VND, PHP, INR, CHF, CAD, CZK, NZD, HUF, BGN, LTL, ZAR, UAH, AED, BOB, CLP, COP, EGP, HRK, ILS, MAD, MYR, PEN, PKR, RON, RSD, SAR, SGD, VEF, LVL
  --default-page: string # Default page for this view (profile).
  --e-commerce-tracking: oneof<nothing, bool> # Indicates whether ecommerce tracking is enabled for this view (profile).
  --enhanced-e-commerce-tracking: oneof<nothing, bool> # Indicates whether enhanced ecommerce tracking is enabled for this view (profile). This property can only be enabled if ecommerce tracking is enabled.
  --exclude-query-parameters: string # The query parameters that are excluded from this view (profile).
  --id: string # View (Profile) ID.
  --name: string # Name of this view (profile).
  --parent-link: record # Parent link for this view (profile). Points to the web property to which this view (profile) belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this view (profile).
  --site-search-category-parameters: string # Site search category parameters for this view (profile).
  --site-search-query-parameters: string # The site search query parameters for this view (profile).
  --starred: oneof<nothing, bool> # Indicates whether this view (profile) is starred or not.
  --strip-site-search-category-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search category parameters from the URLs in your reports.
  --strip-site-search-query-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search query parameters from the URLs in your reports.
  --timezone: string # Time zone for which this view (profile) has been configured. Time zones are identified by strings from the TZ database.
  --type: string # View (Profile) type. Supported types: WEB or APP.
  --website-url: string # Website URL for this view (profile).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: botFilteringEnabled, var: bot_filtering_enabled}, {name: childLink, var: child_link}, {name: currency, var: currency}, {name: defaultPage, var: default_page}, {name: eCommerceTracking, var: e_commerce_tracking}, {name: enhancedECommerceTracking, var: enhanced_e_commerce_tracking}, {name: excludeQueryParameters, var: exclude_query_parameters}, {name: id, var: id}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: permissions, var: permissions}, {name: siteSearchCategoryParameters, var: site_search_category_parameters}, {name: siteSearchQueryParameters, var: site_search_query_parameters}, {name: starred, var: starred}, {name: stripSiteSearchCategoryParameters, var: strip_site_search_category_parameters}, {name: stripSiteSearchQueryParameters, var: strip_site_search_query_parameters}, {name: timezone, var: timezone}, {name: type, var: type}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, bot_filtering_enabled: $bot_filtering_enabled, child_link: $child_link, currency: $currency, default_page: $default_page, e_commerce_tracking: $e_commerce_tracking, enhanced_e_commerce_tracking: $enhanced_e_commerce_tracking, exclude_query_parameters: $exclude_query_parameters, id: $id, name: $name, parent_link: $parent_link, permissions: $permissions, site_search_category_parameters: $site_search_category_parameters, site_search_query_parameters: $site_search_query_parameters, starred: $starred, strip_site_search_category_parameters: $strip_site_search_category_parameters, strip_site_search_query_parameters: $strip_site_search_query_parameters, timezone: $timezone, type: $type, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a view (profile).
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}
# operationId: analytics.management.profiles.delete
export def "analytics-management-profiles-delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a view (profile) to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}
# Returns: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>
# operationId: analytics.management.profiles.get
export def "analytics-management-profiles-get" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing view (profile). This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}
# Returns: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>
# operationId: analytics.management.profiles.patch
export def "analytics-management-profiles-patch" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this view (profile) belongs. (spec name: accountId)
  --bot-filtering-enabled: oneof<nothing, bool> # Indicates whether bot filtering is enabled for this view (profile).
  --child-link: record # Child link for this view (profile). Points to the list of goals for this view (profile). — shape: {href?: string, type?: string}
  --currency: string # The currency type associated with this view (profile), defaults to USD. The supported values are: USD, JPY, EUR, GBP, AUD, KRW, BRL, CNY, DKK, RUB, SEK, NOK, PLN, TRY, TWD, HKD, THB, IDR, ARS, MXN, VND, PHP, INR, CHF, CAD, CZK, NZD, HUF, BGN, LTL, ZAR, UAH, AED, BOB, CLP, COP, EGP, HRK, ILS, MAD, MYR, PEN, PKR, RON, RSD, SAR, SGD, VEF, LVL
  --default-page: string # Default page for this view (profile).
  --e-commerce-tracking: oneof<nothing, bool> # Indicates whether ecommerce tracking is enabled for this view (profile).
  --enhanced-e-commerce-tracking: oneof<nothing, bool> # Indicates whether enhanced ecommerce tracking is enabled for this view (profile). This property can only be enabled if ecommerce tracking is enabled.
  --exclude-query-parameters: string # The query parameters that are excluded from this view (profile).
  --id: string # View (Profile) ID.
  --name: string # Name of this view (profile).
  --parent-link: record # Parent link for this view (profile). Points to the web property to which this view (profile) belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this view (profile).
  --site-search-category-parameters: string # Site search category parameters for this view (profile).
  --site-search-query-parameters: string # The site search query parameters for this view (profile).
  --starred: oneof<nothing, bool> # Indicates whether this view (profile) is starred or not.
  --strip-site-search-category-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search category parameters from the URLs in your reports.
  --strip-site-search-query-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search query parameters from the URLs in your reports.
  --timezone: string # Time zone for which this view (profile) has been configured. Time zones are identified by strings from the TZ database.
  --type: string # View (Profile) type. Supported types: WEB or APP.
  --website-url: string # Website URL for this view (profile).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: botFilteringEnabled, var: bot_filtering_enabled}, {name: childLink, var: child_link}, {name: currency, var: currency}, {name: defaultPage, var: default_page}, {name: eCommerceTracking, var: e_commerce_tracking}, {name: enhancedECommerceTracking, var: enhanced_e_commerce_tracking}, {name: excludeQueryParameters, var: exclude_query_parameters}, {name: id, var: id}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: permissions, var: permissions}, {name: siteSearchCategoryParameters, var: site_search_category_parameters}, {name: siteSearchQueryParameters, var: site_search_query_parameters}, {name: starred, var: starred}, {name: stripSiteSearchCategoryParameters, var: strip_site_search_category_parameters}, {name: stripSiteSearchQueryParameters, var: strip_site_search_query_parameters}, {name: timezone, var: timezone}, {name: type, var: type}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, bot_filtering_enabled: $bot_filtering_enabled, child_link: $child_link, currency: $currency, default_page: $default_page, e_commerce_tracking: $e_commerce_tracking, enhanced_e_commerce_tracking: $enhanced_e_commerce_tracking, exclude_query_parameters: $exclude_query_parameters, id: $id, name: $name, parent_link: $parent_link, permissions: $permissions, site_search_category_parameters: $site_search_category_parameters, site_search_query_parameters: $site_search_query_parameters, starred: $starred, strip_site_search_category_parameters: $strip_site_search_category_parameters, strip_site_search_query_parameters: $strip_site_search_query_parameters, timezone: $timezone, type: $type, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing view (profile).
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}
# Returns: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>
# operationId: analytics.management.profiles.update
export def "analytics-management-profiles-update" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this view (profile) belongs. (spec name: accountId)
  --bot-filtering-enabled: oneof<nothing, bool> # Indicates whether bot filtering is enabled for this view (profile).
  --child-link: record # Child link for this view (profile). Points to the list of goals for this view (profile). — shape: {href?: string, type?: string}
  --currency: string # The currency type associated with this view (profile), defaults to USD. The supported values are: USD, JPY, EUR, GBP, AUD, KRW, BRL, CNY, DKK, RUB, SEK, NOK, PLN, TRY, TWD, HKD, THB, IDR, ARS, MXN, VND, PHP, INR, CHF, CAD, CZK, NZD, HUF, BGN, LTL, ZAR, UAH, AED, BOB, CLP, COP, EGP, HRK, ILS, MAD, MYR, PEN, PKR, RON, RSD, SAR, SGD, VEF, LVL
  --default-page: string # Default page for this view (profile).
  --e-commerce-tracking: oneof<nothing, bool> # Indicates whether ecommerce tracking is enabled for this view (profile).
  --enhanced-e-commerce-tracking: oneof<nothing, bool> # Indicates whether enhanced ecommerce tracking is enabled for this view (profile). This property can only be enabled if ecommerce tracking is enabled.
  --exclude-query-parameters: string # The query parameters that are excluded from this view (profile).
  --id: string # View (Profile) ID.
  --name: string # Name of this view (profile).
  --parent-link: record # Parent link for this view (profile). Points to the web property to which this view (profile) belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this view (profile).
  --site-search-category-parameters: string # Site search category parameters for this view (profile).
  --site-search-query-parameters: string # The site search query parameters for this view (profile).
  --starred: oneof<nothing, bool> # Indicates whether this view (profile) is starred or not.
  --strip-site-search-category-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search category parameters from the URLs in your reports.
  --strip-site-search-query-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search query parameters from the URLs in your reports.
  --timezone: string # Time zone for which this view (profile) has been configured. Time zones are identified by strings from the TZ database.
  --type: string # View (Profile) type. Supported types: WEB or APP.
  --website-url: string # Website URL for this view (profile).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: botFilteringEnabled, var: bot_filtering_enabled}, {name: childLink, var: child_link}, {name: currency, var: currency}, {name: defaultPage, var: default_page}, {name: eCommerceTracking, var: e_commerce_tracking}, {name: enhancedECommerceTracking, var: enhanced_e_commerce_tracking}, {name: excludeQueryParameters, var: exclude_query_parameters}, {name: id, var: id}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: permissions, var: permissions}, {name: siteSearchCategoryParameters, var: site_search_category_parameters}, {name: siteSearchQueryParameters, var: site_search_query_parameters}, {name: starred, var: starred}, {name: stripSiteSearchCategoryParameters, var: strip_site_search_category_parameters}, {name: stripSiteSearchQueryParameters, var: strip_site_search_query_parameters}, {name: timezone, var: timezone}, {name: type, var: type}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, bot_filtering_enabled: $bot_filtering_enabled, child_link: $child_link, currency: $currency, default_page: $default_page, e_commerce_tracking: $e_commerce_tracking, enhanced_e_commerce_tracking: $enhanced_e_commerce_tracking, exclude_query_parameters: $exclude_query_parameters, id: $id, name: $name, parent_link: $parent_link, permissions: $permissions, site_search_category_parameters: $site_search_category_parameters, site_search_query_parameters: $site_search_query_parameters, starred: $starred, strip_site_search_category_parameters: $strip_site_search_category_parameters, strip_site_search_query_parameters: $strip_site_search_query_parameters, timezone: $timezone, type: $type, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists profile-user links for a given view (profile).
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks
# Returns: record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int>
# operationId: analytics.management.profileUserLinks.list
export def "analytics-management-profile-user-links-list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of profile-user links to include in this response.
  --start-index: int # An index of the first profile-user link to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new user to the given view (profile).
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks
# Returns: record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>
# operationId: analytics.management.profileUserLinks.insert
export def "analytics-management-profile-user-links-insert" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: permissions, var: permissions}, {name: selfLink, var: self_link}, {name: userRef, var: user_ref}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, entity: $entity, id: $id, kind: $kind, permissions: $permissions, self_link: $self_link, user_ref: $user_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from the given view (profile).
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks/{linkId}
# operationId: analytics.management.profileUserLinks.delete
export def "analytics-management-profile-user-links-delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates permissions for an existing user on the given view (profile).
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks/{linkId}
# Returns: record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>>
# operationId: analytics.management.profileUserLinks.update
export def "analytics-management-profile-user-links-update" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: entity, var: entity}, {name: id, var: id}, {name: kind, var: kind}, {name: permissions, var: permissions}, {name: selfLink, var: self_link}, {name: userRef, var: user_ref}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, entity: $entity, id: $id, kind: $kind, permissions: $permissions, self_link: $self_link, user_ref: $user_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists experiments to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments
# Returns: record<items: table<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: list, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.experiments.list
export def "analytics-management-experiments-list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of experiments to include in this response.
  --start-index: int # An index of the first experiment to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new experiment.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments
# Returns: record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>
# operationId: analytics.management.experiments.insert
export def "analytics-management-experiments-insert" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this experiment belongs. This field is read-only. (spec name: accountId)
  --created: string # Time the experiment was created. This field is read-only. (format: date-time)
  --description: string # Notes about this experiment.
  --editable-in-ga-ui: oneof<nothing, bool> # If true, the end user will be able to edit the experiment via the Google Analytics user interface.
  --end-time: string # The ending time of the experiment (the time the status changed from RUNNING to ENDED). This field is present only if the experiment has ended. This field is read-only. (format: date-time)
  --equal-weighting: oneof<nothing, bool> # Boolean specifying whether to distribute traffic evenly across all variations. If the value is False, content experiments follows the default behavior of adjusting traffic dynamically based on variation performance. Optional -- defaults to False. This field may not be changed for an experiment whose status is ENDED.
  --id: string # Experiment ID. Required for patch and update. Disallowed for create.
  --internal-web-property-id: string # Internal ID for the web property to which this experiment belongs. This field is read-only.
  --kind: string # Resource type for an Analytics experiment. This field is read-only. (default: analytics#experiment)
  --minimum-experiment-length-in-days: int # An integer number in [3, 90]. Specifies the minimum length of the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: int32)
  --name: string # Experiment name. This field may not be changed for an experiment whose status is ENDED. This field is required when creating an experiment.
  --objective-metric: string # The metric that the experiment is optimizing. Valid values: "ga:goal(n)Completions", "ga:adsenseAdsClicks", "ga:adsenseAdsViewed", "ga:adsenseRevenue", "ga:bounces", "ga:pageviews", "ga:sessionDuration", "ga:transactions", "ga:transactionRevenue". This field is required if status is "RUNNING" and servingFramework is one of "REDIRECT" or "API".
  --optimization-type: string # Whether the objectiveMetric should be minimized or maximized. Possible values: "MAXIMUM", "MINIMUM". Optional--defaults to "MAXIMUM". Cannot be specified without objectiveMetric. Cannot be modified when status is "RUNNING" or "ENDED".
  --parent-link: record # Parent link for an experiment. Points to the view (profile) to which this experiment belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this experiment belongs. This field is read-only. (spec name: profileId)
  --reason-experiment-ended: string # Why the experiment ended. Possible values: "STOPPED_BY_USER", "WINNER_FOUND", "EXPERIMENT_EXPIRED", "ENDED_WITH_NO_WINNER", "GOAL_OBJECTIVE_CHANGED". "ENDED_WITH_NO_WINNER" means that the experiment didn't expire but no winner was projected to be found. If the experiment status is changed via the API to ENDED this field is set to STOPPED_BY_USER. This field is read-only.
  --rewrite-variation-urls-as-original: oneof<nothing, bool> # Boolean specifying whether variations URLS are rewritten to match those of the original. This field may not be changed for an experiments whose status is ENDED.
  --self-link: string # Link for this experiment. This field is read-only.
  --serving-framework: string # The framework used to serve the experiment variations and evaluate the results. One of: - REDIRECT: Google Analytics redirects traffic to different variation pages, reports the chosen variation and evaluates the results. - API: Google Analytics chooses and reports the variation to serve and evaluates the results; the caller is responsible for serving the selected variation. - EXTERNAL: The variations will be served externally and the chosen variation reported to Google Analytics. The caller is responsible for serving the selected variation and evaluating the results.
  --snippet: string # The snippet of code to include on the control page(s). This field is read-only.
  --start-time: string # The starting time of the experiment (the time the status changed from READY_TO_RUN to RUNNING). This field is present only if the experiment has started. This field is read-only. (format: date-time)
  --status: string # Experiment status. Possible values: "DRAFT", "READY_TO_RUN", "RUNNING", "ENDED". Experiments can be created in the "DRAFT", "READY_TO_RUN" or "RUNNING" state. This field is required when creating an experiment.
  --traffic-coverage: float # A floating-point number in (0, 1]. Specifies the fraction of the traffic that participates in the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --updated: string # Time the experiment was last modified. This field is read-only. (format: date-time)
  --variations: list # Array of variations. The first variation in the array is the original. The number of variations may not change once an experiment is in the RUNNING state. At least two variations are required before status can be set to RUNNING. — item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
  --body-web-property-id: string # Web property ID to which this experiment belongs. The web property ID is of the form UA-XXXXX-YY. This field is read-only. (spec name: webPropertyId)
  --winner-confidence-level: float # A floating-point number in (0, 1). Specifies the necessary confidence level to choose a winner. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --winner-found: oneof<nothing, bool> # Boolean specifying whether a winner has been found for this experiment. This field is read-only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: created, var: created}, {name: description, var: description}, {name: editableInGaUi, var: editable_in_ga_ui}, {name: endTime, var: end_time}, {name: equalWeighting, var: equal_weighting}, {name: id, var: id}, {name: internalWebPropertyId, var: internal_web_property_id}, {name: kind, var: kind}, {name: minimumExperimentLengthInDays, var: minimum_experiment_length_in_days}, {name: name, var: name}, {name: objectiveMetric, var: objective_metric}, {name: optimizationType, var: optimization_type}, {name: parentLink, var: parent_link}, {name: profileId, var: body_profile_id}, {name: reasonExperimentEnded, var: reason_experiment_ended}, {name: rewriteVariationUrlsAsOriginal, var: rewrite_variation_urls_as_original}, {name: selfLink, var: self_link}, {name: servingFramework, var: serving_framework}, {name: snippet, var: snippet}, {name: startTime, var: start_time}, {name: status, var: status}, {name: trafficCoverage, var: traffic_coverage}, {name: updated, var: updated}, {name: variations, var: variations}, {name: webPropertyId, var: body_web_property_id}, {name: winnerConfidenceLevel, var: winner_confidence_level}, {name: winnerFound, var: winner_found}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, created: $created, description: $description, editable_in_ga_ui: $editable_in_ga_ui, end_time: $end_time, equal_weighting: $equal_weighting, id: $id, internal_web_property_id: $internal_web_property_id, kind: $kind, minimum_experiment_length_in_days: $minimum_experiment_length_in_days, name: $name, objective_metric: $objective_metric, optimization_type: $optimization_type, parent_link: $parent_link, body_profile_id: $body_profile_id, reason_experiment_ended: $reason_experiment_ended, rewrite_variation_urls_as_original: $rewrite_variation_urls_as_original, self_link: $self_link, serving_framework: $serving_framework, snippet: $snippet, start_time: $start_time, status: $status, traffic_coverage: $traffic_coverage, updated: $updated, variations: $variations, body_web_property_id: $body_web_property_id, winner_confidence_level: $winner_confidence_level, winner_found: $winner_found
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an experiment.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}
# operationId: analytics.management.experiments.delete
export def "analytics-management-experiments-delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: experimentId, var: experiment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, experiment_id: $experiment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an experiment to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}
# Returns: record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>
# operationId: analytics.management.experiments.get
export def "analytics-management-experiments-get" [
  account_id: string
  web_property_id: string
  profile_id: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: experimentId, var: experiment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, experiment_id: $experiment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing experiment. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}
# Returns: record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>
# operationId: analytics.management.experiments.patch
export def "analytics-management-experiments-patch" [
  account_id: string
  web_property_id: string
  profile_id: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this experiment belongs. This field is read-only. (spec name: accountId)
  --created: string # Time the experiment was created. This field is read-only. (format: date-time)
  --description: string # Notes about this experiment.
  --editable-in-ga-ui: oneof<nothing, bool> # If true, the end user will be able to edit the experiment via the Google Analytics user interface.
  --end-time: string # The ending time of the experiment (the time the status changed from RUNNING to ENDED). This field is present only if the experiment has ended. This field is read-only. (format: date-time)
  --equal-weighting: oneof<nothing, bool> # Boolean specifying whether to distribute traffic evenly across all variations. If the value is False, content experiments follows the default behavior of adjusting traffic dynamically based on variation performance. Optional -- defaults to False. This field may not be changed for an experiment whose status is ENDED.
  --id: string # Experiment ID. Required for patch and update. Disallowed for create.
  --internal-web-property-id: string # Internal ID for the web property to which this experiment belongs. This field is read-only.
  --kind: string # Resource type for an Analytics experiment. This field is read-only. (default: analytics#experiment)
  --minimum-experiment-length-in-days: int # An integer number in [3, 90]. Specifies the minimum length of the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: int32)
  --name: string # Experiment name. This field may not be changed for an experiment whose status is ENDED. This field is required when creating an experiment.
  --objective-metric: string # The metric that the experiment is optimizing. Valid values: "ga:goal(n)Completions", "ga:adsenseAdsClicks", "ga:adsenseAdsViewed", "ga:adsenseRevenue", "ga:bounces", "ga:pageviews", "ga:sessionDuration", "ga:transactions", "ga:transactionRevenue". This field is required if status is "RUNNING" and servingFramework is one of "REDIRECT" or "API".
  --optimization-type: string # Whether the objectiveMetric should be minimized or maximized. Possible values: "MAXIMUM", "MINIMUM". Optional--defaults to "MAXIMUM". Cannot be specified without objectiveMetric. Cannot be modified when status is "RUNNING" or "ENDED".
  --parent-link: record # Parent link for an experiment. Points to the view (profile) to which this experiment belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this experiment belongs. This field is read-only. (spec name: profileId)
  --reason-experiment-ended: string # Why the experiment ended. Possible values: "STOPPED_BY_USER", "WINNER_FOUND", "EXPERIMENT_EXPIRED", "ENDED_WITH_NO_WINNER", "GOAL_OBJECTIVE_CHANGED". "ENDED_WITH_NO_WINNER" means that the experiment didn't expire but no winner was projected to be found. If the experiment status is changed via the API to ENDED this field is set to STOPPED_BY_USER. This field is read-only.
  --rewrite-variation-urls-as-original: oneof<nothing, bool> # Boolean specifying whether variations URLS are rewritten to match those of the original. This field may not be changed for an experiments whose status is ENDED.
  --self-link: string # Link for this experiment. This field is read-only.
  --serving-framework: string # The framework used to serve the experiment variations and evaluate the results. One of: - REDIRECT: Google Analytics redirects traffic to different variation pages, reports the chosen variation and evaluates the results. - API: Google Analytics chooses and reports the variation to serve and evaluates the results; the caller is responsible for serving the selected variation. - EXTERNAL: The variations will be served externally and the chosen variation reported to Google Analytics. The caller is responsible for serving the selected variation and evaluating the results.
  --snippet: string # The snippet of code to include on the control page(s). This field is read-only.
  --start-time: string # The starting time of the experiment (the time the status changed from READY_TO_RUN to RUNNING). This field is present only if the experiment has started. This field is read-only. (format: date-time)
  --status: string # Experiment status. Possible values: "DRAFT", "READY_TO_RUN", "RUNNING", "ENDED". Experiments can be created in the "DRAFT", "READY_TO_RUN" or "RUNNING" state. This field is required when creating an experiment.
  --traffic-coverage: float # A floating-point number in (0, 1]. Specifies the fraction of the traffic that participates in the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --updated: string # Time the experiment was last modified. This field is read-only. (format: date-time)
  --variations: list # Array of variations. The first variation in the array is the original. The number of variations may not change once an experiment is in the RUNNING state. At least two variations are required before status can be set to RUNNING. — item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
  --body-web-property-id: string # Web property ID to which this experiment belongs. The web property ID is of the form UA-XXXXX-YY. This field is read-only. (spec name: webPropertyId)
  --winner-confidence-level: float # A floating-point number in (0, 1). Specifies the necessary confidence level to choose a winner. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --winner-found: oneof<nothing, bool> # Boolean specifying whether a winner has been found for this experiment. This field is read-only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: experimentId, var: experiment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: created, var: created}, {name: description, var: description}, {name: editableInGaUi, var: editable_in_ga_ui}, {name: endTime, var: end_time}, {name: equalWeighting, var: equal_weighting}, {name: id, var: id}, {name: internalWebPropertyId, var: internal_web_property_id}, {name: kind, var: kind}, {name: minimumExperimentLengthInDays, var: minimum_experiment_length_in_days}, {name: name, var: name}, {name: objectiveMetric, var: objective_metric}, {name: optimizationType, var: optimization_type}, {name: parentLink, var: parent_link}, {name: profileId, var: body_profile_id}, {name: reasonExperimentEnded, var: reason_experiment_ended}, {name: rewriteVariationUrlsAsOriginal, var: rewrite_variation_urls_as_original}, {name: selfLink, var: self_link}, {name: servingFramework, var: serving_framework}, {name: snippet, var: snippet}, {name: startTime, var: start_time}, {name: status, var: status}, {name: trafficCoverage, var: traffic_coverage}, {name: updated, var: updated}, {name: variations, var: variations}, {name: webPropertyId, var: body_web_property_id}, {name: winnerConfidenceLevel, var: winner_confidence_level}, {name: winnerFound, var: winner_found}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, experiment_id: $experiment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, created: $created, description: $description, editable_in_ga_ui: $editable_in_ga_ui, end_time: $end_time, equal_weighting: $equal_weighting, id: $id, internal_web_property_id: $internal_web_property_id, kind: $kind, minimum_experiment_length_in_days: $minimum_experiment_length_in_days, name: $name, objective_metric: $objective_metric, optimization_type: $optimization_type, parent_link: $parent_link, body_profile_id: $body_profile_id, reason_experiment_ended: $reason_experiment_ended, rewrite_variation_urls_as_original: $rewrite_variation_urls_as_original, self_link: $self_link, serving_framework: $serving_framework, snippet: $snippet, start_time: $start_time, status: $status, traffic_coverage: $traffic_coverage, updated: $updated, variations: $variations, body_web_property_id: $body_web_property_id, winner_confidence_level: $winner_confidence_level, winner_found: $winner_found
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing experiment.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}
# Returns: record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>
# operationId: analytics.management.experiments.update
export def "analytics-management-experiments-update" [
  account_id: string
  web_property_id: string
  profile_id: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this experiment belongs. This field is read-only. (spec name: accountId)
  --created: string # Time the experiment was created. This field is read-only. (format: date-time)
  --description: string # Notes about this experiment.
  --editable-in-ga-ui: oneof<nothing, bool> # If true, the end user will be able to edit the experiment via the Google Analytics user interface.
  --end-time: string # The ending time of the experiment (the time the status changed from RUNNING to ENDED). This field is present only if the experiment has ended. This field is read-only. (format: date-time)
  --equal-weighting: oneof<nothing, bool> # Boolean specifying whether to distribute traffic evenly across all variations. If the value is False, content experiments follows the default behavior of adjusting traffic dynamically based on variation performance. Optional -- defaults to False. This field may not be changed for an experiment whose status is ENDED.
  --id: string # Experiment ID. Required for patch and update. Disallowed for create.
  --internal-web-property-id: string # Internal ID for the web property to which this experiment belongs. This field is read-only.
  --kind: string # Resource type for an Analytics experiment. This field is read-only. (default: analytics#experiment)
  --minimum-experiment-length-in-days: int # An integer number in [3, 90]. Specifies the minimum length of the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: int32)
  --name: string # Experiment name. This field may not be changed for an experiment whose status is ENDED. This field is required when creating an experiment.
  --objective-metric: string # The metric that the experiment is optimizing. Valid values: "ga:goal(n)Completions", "ga:adsenseAdsClicks", "ga:adsenseAdsViewed", "ga:adsenseRevenue", "ga:bounces", "ga:pageviews", "ga:sessionDuration", "ga:transactions", "ga:transactionRevenue". This field is required if status is "RUNNING" and servingFramework is one of "REDIRECT" or "API".
  --optimization-type: string # Whether the objectiveMetric should be minimized or maximized. Possible values: "MAXIMUM", "MINIMUM". Optional--defaults to "MAXIMUM". Cannot be specified without objectiveMetric. Cannot be modified when status is "RUNNING" or "ENDED".
  --parent-link: record # Parent link for an experiment. Points to the view (profile) to which this experiment belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this experiment belongs. This field is read-only. (spec name: profileId)
  --reason-experiment-ended: string # Why the experiment ended. Possible values: "STOPPED_BY_USER", "WINNER_FOUND", "EXPERIMENT_EXPIRED", "ENDED_WITH_NO_WINNER", "GOAL_OBJECTIVE_CHANGED". "ENDED_WITH_NO_WINNER" means that the experiment didn't expire but no winner was projected to be found. If the experiment status is changed via the API to ENDED this field is set to STOPPED_BY_USER. This field is read-only.
  --rewrite-variation-urls-as-original: oneof<nothing, bool> # Boolean specifying whether variations URLS are rewritten to match those of the original. This field may not be changed for an experiments whose status is ENDED.
  --self-link: string # Link for this experiment. This field is read-only.
  --serving-framework: string # The framework used to serve the experiment variations and evaluate the results. One of: - REDIRECT: Google Analytics redirects traffic to different variation pages, reports the chosen variation and evaluates the results. - API: Google Analytics chooses and reports the variation to serve and evaluates the results; the caller is responsible for serving the selected variation. - EXTERNAL: The variations will be served externally and the chosen variation reported to Google Analytics. The caller is responsible for serving the selected variation and evaluating the results.
  --snippet: string # The snippet of code to include on the control page(s). This field is read-only.
  --start-time: string # The starting time of the experiment (the time the status changed from READY_TO_RUN to RUNNING). This field is present only if the experiment has started. This field is read-only. (format: date-time)
  --status: string # Experiment status. Possible values: "DRAFT", "READY_TO_RUN", "RUNNING", "ENDED". Experiments can be created in the "DRAFT", "READY_TO_RUN" or "RUNNING" state. This field is required when creating an experiment.
  --traffic-coverage: float # A floating-point number in (0, 1]. Specifies the fraction of the traffic that participates in the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --updated: string # Time the experiment was last modified. This field is read-only. (format: date-time)
  --variations: list # Array of variations. The first variation in the array is the original. The number of variations may not change once an experiment is in the RUNNING state. At least two variations are required before status can be set to RUNNING. — item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
  --body-web-property-id: string # Web property ID to which this experiment belongs. The web property ID is of the form UA-XXXXX-YY. This field is read-only. (spec name: webPropertyId)
  --winner-confidence-level: float # A floating-point number in (0, 1). Specifies the necessary confidence level to choose a winner. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --winner-found: oneof<nothing, bool> # Boolean specifying whether a winner has been found for this experiment. This field is read-only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: experimentId, var: experiment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: created, var: created}, {name: description, var: description}, {name: editableInGaUi, var: editable_in_ga_ui}, {name: endTime, var: end_time}, {name: equalWeighting, var: equal_weighting}, {name: id, var: id}, {name: internalWebPropertyId, var: internal_web_property_id}, {name: kind, var: kind}, {name: minimumExperimentLengthInDays, var: minimum_experiment_length_in_days}, {name: name, var: name}, {name: objectiveMetric, var: objective_metric}, {name: optimizationType, var: optimization_type}, {name: parentLink, var: parent_link}, {name: profileId, var: body_profile_id}, {name: reasonExperimentEnded, var: reason_experiment_ended}, {name: rewriteVariationUrlsAsOriginal, var: rewrite_variation_urls_as_original}, {name: selfLink, var: self_link}, {name: servingFramework, var: serving_framework}, {name: snippet, var: snippet}, {name: startTime, var: start_time}, {name: status, var: status}, {name: trafficCoverage, var: traffic_coverage}, {name: updated, var: updated}, {name: variations, var: variations}, {name: webPropertyId, var: body_web_property_id}, {name: winnerConfidenceLevel, var: winner_confidence_level}, {name: winnerFound, var: winner_found}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, experiment_id: $experiment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, created: $created, description: $description, editable_in_ga_ui: $editable_in_ga_ui, end_time: $end_time, equal_weighting: $equal_weighting, id: $id, internal_web_property_id: $internal_web_property_id, kind: $kind, minimum_experiment_length_in_days: $minimum_experiment_length_in_days, name: $name, objective_metric: $objective_metric, optimization_type: $optimization_type, parent_link: $parent_link, body_profile_id: $body_profile_id, reason_experiment_ended: $reason_experiment_ended, rewrite_variation_urls_as_original: $rewrite_variation_urls_as_original, self_link: $self_link, serving_framework: $serving_framework, snippet: $snippet, start_time: $start_time, status: $status, traffic_coverage: $traffic_coverage, updated: $updated, variations: $variations, body_web_property_id: $body_web_property_id, winner_confidence_level: $winner_confidence_level, winner_found: $winner_found
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists goals to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals
# Returns: record<items: table<accountId: string, active: bool, created: string, eventDetails: record, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record, value: float, visitNumPagesDetails: record, visitTimeOnSiteDetails: record, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.goals.list
export def "analytics-management-goals-list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of goals to include in this response.
  --start-index: int # An index of the first goal to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new goal.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals
# Returns: record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string>
# operationId: analytics.management.goals.insert
export def "analytics-management-goals-insert" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this goal belongs. (spec name: accountId)
  --active: oneof<nothing, bool> # Determines whether this goal is active.
  --created: string # Time this goal was created. (format: date-time)
  --event-details: record # Details for the goal of the type EVENT. — shape: {eventConditions?: list, useEventValue?: bool}
  --id: string # Goal ID.
  --internal-web-property-id: string # Internal ID for the web property to which this goal belongs.
  --kind: string # Resource type for an Analytics goal. (default: analytics#goal)
  --name: string # Goal name.
  --parent-link: record # Parent link for a goal. Points to the view (profile) to which this goal belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this goal belongs. (spec name: profileId)
  --self-link: string # Link for this goal.
  --type: string # Goal type. Possible values are URL_DESTINATION, VISIT_TIME_ON_SITE, VISIT_NUM_PAGES, AND EVENT.
  --updated: string # Time this goal was last modified. (format: date-time)
  --url-destination-details: record # Details for the goal of the type URL_DESTINATION. — shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
  --value: float # Goal value. (format: float)
  --visit-num-pages-details: record # Details for the goal of the type VISIT_NUM_PAGES. — shape: {comparisonType?: string, comparisonValue?: string}
  --visit-time-on-site-details: record # Details for the goal of the type VISIT_TIME_ON_SITE. — shape: {comparisonType?: string, comparisonValue?: string}
  --body-web-property-id: string # Web property ID to which this goal belongs. The web property ID is of the form UA-XXXXX-YY. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: created, var: created}, {name: eventDetails, var: event_details}, {name: id, var: id}, {name: internalWebPropertyId, var: internal_web_property_id}, {name: kind, var: kind}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: profileId, var: body_profile_id}, {name: selfLink, var: self_link}, {name: type, var: type}, {name: updated, var: updated}, {name: urlDestinationDetails, var: url_destination_details}, {name: value, var: value}, {name: visitNumPagesDetails, var: visit_num_pages_details}, {name: visitTimeOnSiteDetails, var: visit_time_on_site_details}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, active: $active, created: $created, event_details: $event_details, id: $id, internal_web_property_id: $internal_web_property_id, kind: $kind, name: $name, parent_link: $parent_link, body_profile_id: $body_profile_id, self_link: $self_link, type: $type, updated: $updated, url_destination_details: $url_destination_details, value: $value, visit_num_pages_details: $visit_num_pages_details, visit_time_on_site_details: $visit_time_on_site_details, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a goal to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}
# Returns: record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string>
# operationId: analytics.management.goals.get
export def "analytics-management-goals-get" [
  account_id: string
  web_property_id: string
  profile_id: string
  goal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: goalId, var: goal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, goal_id: $goal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing goal. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}
# Returns: record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string>
# operationId: analytics.management.goals.patch
export def "analytics-management-goals-patch" [
  account_id: string
  web_property_id: string
  profile_id: string
  goal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this goal belongs. (spec name: accountId)
  --active: oneof<nothing, bool> # Determines whether this goal is active.
  --created: string # Time this goal was created. (format: date-time)
  --event-details: record # Details for the goal of the type EVENT. — shape: {eventConditions?: list, useEventValue?: bool}
  --id: string # Goal ID.
  --internal-web-property-id: string # Internal ID for the web property to which this goal belongs.
  --kind: string # Resource type for an Analytics goal. (default: analytics#goal)
  --name: string # Goal name.
  --parent-link: record # Parent link for a goal. Points to the view (profile) to which this goal belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this goal belongs. (spec name: profileId)
  --self-link: string # Link for this goal.
  --type: string # Goal type. Possible values are URL_DESTINATION, VISIT_TIME_ON_SITE, VISIT_NUM_PAGES, AND EVENT.
  --updated: string # Time this goal was last modified. (format: date-time)
  --url-destination-details: record # Details for the goal of the type URL_DESTINATION. — shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
  --value: float # Goal value. (format: float)
  --visit-num-pages-details: record # Details for the goal of the type VISIT_NUM_PAGES. — shape: {comparisonType?: string, comparisonValue?: string}
  --visit-time-on-site-details: record # Details for the goal of the type VISIT_TIME_ON_SITE. — shape: {comparisonType?: string, comparisonValue?: string}
  --body-web-property-id: string # Web property ID to which this goal belongs. The web property ID is of the form UA-XXXXX-YY. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: goalId, var: goal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: created, var: created}, {name: eventDetails, var: event_details}, {name: id, var: id}, {name: internalWebPropertyId, var: internal_web_property_id}, {name: kind, var: kind}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: profileId, var: body_profile_id}, {name: selfLink, var: self_link}, {name: type, var: type}, {name: updated, var: updated}, {name: urlDestinationDetails, var: url_destination_details}, {name: value, var: value}, {name: visitNumPagesDetails, var: visit_num_pages_details}, {name: visitTimeOnSiteDetails, var: visit_time_on_site_details}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, goal_id: $goal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, active: $active, created: $created, event_details: $event_details, id: $id, internal_web_property_id: $internal_web_property_id, kind: $kind, name: $name, parent_link: $parent_link, body_profile_id: $body_profile_id, self_link: $self_link, type: $type, updated: $updated, url_destination_details: $url_destination_details, value: $value, visit_num_pages_details: $visit_num_pages_details, visit_time_on_site_details: $visit_time_on_site_details, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing goal.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}
# Returns: record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string>
# operationId: analytics.management.goals.update
export def "analytics-management-goals-update" [
  account_id: string
  web_property_id: string
  profile_id: string
  goal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this goal belongs. (spec name: accountId)
  --active: oneof<nothing, bool> # Determines whether this goal is active.
  --created: string # Time this goal was created. (format: date-time)
  --event-details: record # Details for the goal of the type EVENT. — shape: {eventConditions?: list, useEventValue?: bool}
  --id: string # Goal ID.
  --internal-web-property-id: string # Internal ID for the web property to which this goal belongs.
  --kind: string # Resource type for an Analytics goal. (default: analytics#goal)
  --name: string # Goal name.
  --parent-link: record # Parent link for a goal. Points to the view (profile) to which this goal belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this goal belongs. (spec name: profileId)
  --self-link: string # Link for this goal.
  --type: string # Goal type. Possible values are URL_DESTINATION, VISIT_TIME_ON_SITE, VISIT_NUM_PAGES, AND EVENT.
  --updated: string # Time this goal was last modified. (format: date-time)
  --url-destination-details: record # Details for the goal of the type URL_DESTINATION. — shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
  --value: float # Goal value. (format: float)
  --visit-num-pages-details: record # Details for the goal of the type VISIT_NUM_PAGES. — shape: {comparisonType?: string, comparisonValue?: string}
  --visit-time-on-site-details: record # Details for the goal of the type VISIT_TIME_ON_SITE. — shape: {comparisonType?: string, comparisonValue?: string}
  --body-web-property-id: string # Web property ID to which this goal belongs. The web property ID is of the form UA-XXXXX-YY. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: goalId, var: goal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: active, var: active}, {name: created, var: created}, {name: eventDetails, var: event_details}, {name: id, var: id}, {name: internalWebPropertyId, var: internal_web_property_id}, {name: kind, var: kind}, {name: name, var: name}, {name: parentLink, var: parent_link}, {name: profileId, var: body_profile_id}, {name: selfLink, var: self_link}, {name: type, var: type}, {name: updated, var: updated}, {name: urlDestinationDetails, var: url_destination_details}, {name: value, var: value}, {name: visitNumPagesDetails, var: visit_num_pages_details}, {name: visitTimeOnSiteDetails, var: visit_time_on_site_details}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, goal_id: $goal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, active: $active, created: $created, event_details: $event_details, id: $id, internal_web_property_id: $internal_web_property_id, kind: $kind, name: $name, parent_link: $parent_link, body_profile_id: $body_profile_id, self_link: $self_link, type: $type, updated: $updated, url_destination_details: $url_destination_details, value: $value, visit_num_pages_details: $visit_num_pages_details, visit_time_on_site_details: $visit_time_on_site_details, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all profile filter links for a profile.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks
# Returns: record<items: table<filterRef: record, id: string, kind: string, profileRef: record, rank: int, selfLink: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.profileFilterLinks.list
export def "analytics-management-profile-filter-links-list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of profile filter links to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new profile filter link.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks
# Returns: record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string>
# operationId: analytics.management.profileFilterLinks.insert
export def "analytics-management-profile-filter-links-insert" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --filter-ref: record # JSON template for a profile filter link. — shape: {href?: string, id?: string, kind?: string}
  --id: string # Profile filter link ID.
  --profile-ref: record # JSON template for a linked view (profile). — shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
  --rank: int # The rank of this profile filter link relative to the other filters linked to the same profile. For readonly (i.e., list and get) operations, the rank always starts at 1. For write (i.e., create, update, or delete) operations, you may specify a value between 0 and 255 inclusively, [0, 255]. In order to insert a link at the end of the list, either don't specify a rank or set a rank to a number greater than the largest rank in the list. In order to insert a link to the beginning of the list specify a rank that is less than or equal to 1. The new link will move all existing filters with the same or lower rank down the list. After the link is inserted/updated/deleted all profile filter links will be renumbered starting at 1. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: filterRef, var: filter_ref}, {name: id, var: id}, {name: profileRef, var: profile_ref}, {name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, filter_ref: $filter_ref, id: $id, profile_ref: $profile_ref, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a profile filter link.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}
# operationId: analytics.management.profileFilterLinks.delete
export def "analytics-management-profile-filter-links-delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single profile filter link.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}
# Returns: record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string>
# operationId: analytics.management.profileFilterLinks.get
export def "analytics-management-profile-filter-links-get" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing profile filter link. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}
# Returns: record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string>
# operationId: analytics.management.profileFilterLinks.patch
export def "analytics-management-profile-filter-links-patch" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --filter-ref: record # JSON template for a profile filter link. — shape: {href?: string, id?: string, kind?: string}
  --id: string # Profile filter link ID.
  --profile-ref: record # JSON template for a linked view (profile). — shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
  --rank: int # The rank of this profile filter link relative to the other filters linked to the same profile. For readonly (i.e., list and get) operations, the rank always starts at 1. For write (i.e., create, update, or delete) operations, you may specify a value between 0 and 255 inclusively, [0, 255]. In order to insert a link at the end of the list, either don't specify a rank or set a rank to a number greater than the largest rank in the list. In order to insert a link to the beginning of the list specify a rank that is less than or equal to 1. The new link will move all existing filters with the same or lower rank down the list. After the link is inserted/updated/deleted all profile filter links will be renumbered starting at 1. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: filterRef, var: filter_ref}, {name: id, var: id}, {name: profileRef, var: profile_ref}, {name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, filter_ref: $filter_ref, id: $id, profile_ref: $profile_ref, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing profile filter link.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}
# Returns: record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string>
# operationId: analytics.management.profileFilterLinks.update
export def "analytics-management-profile-filter-links-update" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --filter-ref: record # JSON template for a profile filter link. — shape: {href?: string, id?: string, kind?: string}
  --id: string # Profile filter link ID.
  --profile-ref: record # JSON template for a linked view (profile). — shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
  --rank: int # The rank of this profile filter link relative to the other filters linked to the same profile. For readonly (i.e., list and get) operations, the rank always starts at 1. For write (i.e., create, update, or delete) operations, you may specify a value between 0 and 255 inclusively, [0, 255]. In order to insert a link at the end of the list, either don't specify a rank or set a rank to a number greater than the largest rank in the list. In order to insert a link to the beginning of the list specify a rank that is less than or equal to 1. The new link will move all existing filters with the same or lower rank down the list. After the link is inserted/updated/deleted all profile filter links will be renumbered starting at 1. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: linkId, var: link_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: filterRef, var: filter_ref}, {name: id, var: id}, {name: profileRef, var: profile_ref}, {name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, link_id: $link_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, filter_ref: $filter_ref, id: $id, profile_ref: $profile_ref, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists unsampled reports to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports
# Returns: record<items: table<accountId: string, cloudStorageDownloadDetails: record, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record, end-date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start-date: string, status: string, title: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.unsampledReports.list
export def "analytics-management-unsampled-reports-list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of unsampled reports to include in this response.
  --start-index: int # An index of the first unsampled report to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new unsampled report.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports
# Returns: record<accountId: string, cloudStorageDownloadDetails: record<bucketId: string, objectId: string>, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record<documentId: string>, end-date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start-date: string, status: string, title: string, updated: string, webPropertyId: string>
# operationId: analytics.management.unsampledReports.insert
export def "analytics-management-unsampled-reports-insert" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this unsampled report belongs. (spec name: accountId)
  --dimensions: string # The dimensions for the unsampled report.
  --end-date: string # The end date for the unsampled report.
  --filters: string # The filters for the unsampled report.
  --id: string # Unsampled report ID.
  --metrics: string # The metrics for the unsampled report.
  --body-profile-id: string # View (Profile) ID to which this unsampled report belongs. (spec name: profileId)
  --segment: string # The segment for the unsampled report.
  --start-date: string # The start date for the unsampled report.
  --title: string # Title of the unsampled report.
  --body-web-property-id: string # Web property ID to which this unsampled report belongs. The web property ID is of the form UA-XXXXX-YY. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: dimensions, var: dimensions}, {name: end-date, var: end_date}, {name: filters, var: filters}, {name: id, var: id}, {name: metrics, var: metrics}, {name: profileId, var: body_profile_id}, {name: segment, var: segment}, {name: start-date, var: start_date}, {name: title, var: title}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, dimensions: $dimensions, end_date: $end_date, filters: $filters, id: $id, metrics: $metrics, body_profile_id: $body_profile_id, segment: $segment, start_date: $start_date, title: $title, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an unsampled report.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports/{unsampledReportId}
# operationId: analytics.management.unsampledReports.delete
export def "analytics-management-unsampled-reports-delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  unsampled_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports/{unsampledReportId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: unsampledReportId, var: unsampled_report_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, unsampled_report_id: $unsampled_report_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single unsampled report.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports/{unsampledReportId}
# Returns: record<accountId: string, cloudStorageDownloadDetails: record<bucketId: string, objectId: string>, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record<documentId: string>, end-date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start-date: string, status: string, title: string, updated: string, webPropertyId: string>
# operationId: analytics.management.unsampledReports.get
export def "analytics-management-unsampled-reports-get" [
  account_id: string
  web_property_id: string
  profile_id: string
  unsampled_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports/{unsampledReportId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: profileId, var: profile_id}, {name: unsampledReportId, var: unsampled_report_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, profile_id: $profile_id, unsampled_report_id: $unsampled_report_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists remarketing audiences to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences
# Returns: record<items: table<accountId: string, audienceDefinition: record, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: list, linkedViews: list, name: string, stateBasedAudienceDefinition: record, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.remarketingAudience.list
export def "analytics-management-remarketing-audience-list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of remarketing audiences to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
  --type: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new remarketing audience.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences
# Returns: record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string>
# operationId: analytics.management.remarketingAudience.insert
export def "analytics-management-remarketing-audience-insert" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this remarketing audience belongs. (spec name: accountId)
  --audience-definition: record # The simple audience definition that will cause a user to be added to an audience. — shape: {includeConditions?: record}
  --audience-type: string # The type of audience, either SIMPLE or STATE_BASED.
  --id: string # Remarketing Audience ID.
  --kind: string # Collection type. (default: analytics#remarketingAudience)
  --linked-ad-accounts: list # The linked ad accounts associated with this remarketing audience. A remarketing audience can have only one linkedAdAccount currently. — item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
  --linked-views: list<string> # The views (profiles) that this remarketing audience is linked to.
  --name: string # The name of this remarketing audience.
  --state-based-audience-definition: record # A state based audience definition that will cause a user to be added or removed from an audience. — shape: {excludeConditions?: record, includeConditions?: record}
  --body-web-property-id: string # Web property ID of the form UA-XXXXX-YY to which this remarketing audience belongs. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: audienceDefinition, var: audience_definition}, {name: audienceType, var: audience_type}, {name: id, var: id}, {name: kind, var: kind}, {name: linkedAdAccounts, var: linked_ad_accounts}, {name: linkedViews, var: linked_views}, {name: name, var: name}, {name: stateBasedAudienceDefinition, var: state_based_audience_definition}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, audience_definition: $audience_definition, audience_type: $audience_type, id: $id, kind: $kind, linked_ad_accounts: $linked_ad_accounts, linked_views: $linked_views, name: $name, state_based_audience_definition: $state_based_audience_definition, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a remarketing audience.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}
# operationId: analytics.management.remarketingAudience.delete
export def "analytics-management-remarketing-audience-delete" [
  account_id: string
  web_property_id: string
  remarketing_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: remarketingAudienceId, var: remarketing_audience_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, remarketing_audience_id: $remarketing_audience_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a remarketing audience to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}
# Returns: record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string>
# operationId: analytics.management.remarketingAudience.get
export def "analytics-management-remarketing-audience-get" [
  account_id: string
  web_property_id: string
  remarketing_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: remarketingAudienceId, var: remarketing_audience_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, remarketing_audience_id: $remarketing_audience_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing remarketing audience. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}
# Returns: record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string>
# operationId: analytics.management.remarketingAudience.patch
export def "analytics-management-remarketing-audience-patch" [
  account_id: string
  web_property_id: string
  remarketing_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this remarketing audience belongs. (spec name: accountId)
  --audience-definition: record # The simple audience definition that will cause a user to be added to an audience. — shape: {includeConditions?: record}
  --audience-type: string # The type of audience, either SIMPLE or STATE_BASED.
  --id: string # Remarketing Audience ID.
  --kind: string # Collection type. (default: analytics#remarketingAudience)
  --linked-ad-accounts: list # The linked ad accounts associated with this remarketing audience. A remarketing audience can have only one linkedAdAccount currently. — item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
  --linked-views: list<string> # The views (profiles) that this remarketing audience is linked to.
  --name: string # The name of this remarketing audience.
  --state-based-audience-definition: record # A state based audience definition that will cause a user to be added or removed from an audience. — shape: {excludeConditions?: record, includeConditions?: record}
  --body-web-property-id: string # Web property ID of the form UA-XXXXX-YY to which this remarketing audience belongs. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: remarketingAudienceId, var: remarketing_audience_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: audienceDefinition, var: audience_definition}, {name: audienceType, var: audience_type}, {name: id, var: id}, {name: kind, var: kind}, {name: linkedAdAccounts, var: linked_ad_accounts}, {name: linkedViews, var: linked_views}, {name: name, var: name}, {name: stateBasedAudienceDefinition, var: state_based_audience_definition}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, remarketing_audience_id: $remarketing_audience_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, audience_definition: $audience_definition, audience_type: $audience_type, id: $id, kind: $kind, linked_ad_accounts: $linked_ad_accounts, linked_views: $linked_views, name: $name, state_based_audience_definition: $state_based_audience_definition, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing remarketing audience.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}
# Returns: record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string>
# operationId: analytics.management.remarketingAudience.update
export def "analytics-management-remarketing-audience-update" [
  account_id: string
  web_property_id: string
  remarketing_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this remarketing audience belongs. (spec name: accountId)
  --audience-definition: record # The simple audience definition that will cause a user to be added to an audience. — shape: {includeConditions?: record}
  --audience-type: string # The type of audience, either SIMPLE or STATE_BASED.
  --id: string # Remarketing Audience ID.
  --kind: string # Collection type. (default: analytics#remarketingAudience)
  --linked-ad-accounts: list # The linked ad accounts associated with this remarketing audience. A remarketing audience can have only one linkedAdAccount currently. — item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
  --linked-views: list<string> # The views (profiles) that this remarketing audience is linked to.
  --name: string # The name of this remarketing audience.
  --state-based-audience-definition: record # A state based audience definition that will cause a user to be added or removed from an audience. — shape: {excludeConditions?: record, includeConditions?: record}
  --body-web-property-id: string # Web property ID of the form UA-XXXXX-YY to which this remarketing audience belongs. (spec name: webPropertyId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}"
    path_params: [{name: accountId, var: account_id}, {name: webPropertyId, var: web_property_id}, {name: remarketingAudienceId, var: remarketing_audience_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: audienceDefinition, var: audience_definition}, {name: audienceType, var: audience_type}, {name: id, var: id}, {name: kind, var: kind}, {name: linkedAdAccounts, var: linked_ad_accounts}, {name: linkedViews, var: linked_views}, {name: name, var: name}, {name: stateBasedAudienceDefinition, var: state_based_audience_definition}, {name: webPropertyId, var: body_web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, web_property_id: $web_property_id, remarketing_audience_id: $remarketing_audience_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, audience_definition: $audience_definition, audience_type: $audience_type, id: $id, kind: $kind, linked_ad_accounts: $linked_ad_accounts, linked_views: $linked_views, name: $name, state_based_audience_definition: $state_based_audience_definition, body_web_property_id: $body_web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hashes the given Client ID.
#
# POST /management/clientId:hashClientId
# Returns: record<clientId: string, hashedClientId: string, kind: string, webPropertyId: string>
# operationId: analytics.management.clientId.hashClientId
export def "analytics-management-client-id-hash-client-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --client-id: string
  --kind: string # default: analytics#hashClientIdRequest
  --web-property-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/management/clientId:hashClientId"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: kind, var: kind}, {name: webPropertyId, var: web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, client_id: $client_id, kind: $kind, web_property_id: $web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists segments to which the user has access.
#
# GET /management/segments
# Returns: record<items: table<created: string, definition: string, id: string, kind: string, name: string, segmentId: string, selfLink: string, type: string, updated: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string>
# operationId: analytics.management.segments.list
export def "analytics-management-segments-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of segments to include in this response.
  --start-index: int # An index of the first segment to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/management/segments"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: max-results, var: max_results}, {name: start-index, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all columns for a report type
#
# GET /metadata/{reportType}/columns
# Returns: record<attributeNames: list<string>, etag: string, items: table<attributes: record, id: string, kind: string>, kind: string, totalResults: int>
# operationId: analytics.metadata.columns.list
export def "analytics-metadata-columns-list" [
  report_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata/{reportType}/columns"
    path_params: [{name: reportType, var: report_type}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    report_type: $report_type, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an account ticket.
#
# POST /provisioning/createAccountTicket
# Returns: record<account: record<childLink: record<href: string, type: string>, created: string, id: string, kind: string, name: string, permissions: record<effective: list>, selfLink: string, starred: bool, updated: string>, id: string, kind: string, profile: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, redirectUri: string, webproperty: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>>
# operationId: analytics.provisioning.createAccountTicket
export def "analytics-provisioning-create-account-ticket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --account: record # JSON template for Analytics account entry. — shape: {childLink?: record, created?: string, id?: string, kind?: string, name?: string, permissions?: record, selfLink?: string, starred?: bool, updated?: string}
  --id: string # Account ticket ID used to access the account ticket.
  --kind: string # Resource type for account ticket. (default: analytics#accountTicket)
  --profile: record # JSON template for an Analytics view (profile). — shape: {accountId?: string, botFilteringEnabled?: bool, childLink?: record, currency?: string, defaultPage?: string, eCommerceTracking?: bool, enhancedECommerceTracking?: bool, excludeQueryParameters?: string, id?: string, name?: string, parentLink?: record, permissions?: record, siteSearchCategoryParameters?: string, siteSearchQueryParameters?: string, starred?: bool, stripSiteSearchCategoryParameters?: bool, stripSiteSearchQueryParameters?: bool, timezone?: string, type?: string, websiteUrl?: string}
  --redirect-uri: string # Redirect URI where the user will be sent after accepting Terms of Service. Must be configured in APIs console as a callback URL.
  --webproperty: record # JSON template for an Analytics web property. — shape: {accountId?: string, childLink?: record, dataRetentionResetOnNewActivity?: bool, dataRetentionTtl?: string, defaultProfileId?: string, id?: string, industryVertical?: string, name?: string, parentLink?: record, permissions?: record, starred?: bool, websiteUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/provisioning/createAccountTicket"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: id, var: id}, {name: kind, var: kind}, {name: profile, var: profile}, {name: redirectUri, var: redirect_uri}, {name: webproperty, var: webproperty}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, account: $account, id: $id, kind: $kind, profile: $profile, redirect_uri: $redirect_uri, webproperty: $webproperty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provision account.
#
# POST /provisioning/createAccountTree
# Returns: record<account: record<childLink: record<href: string, type: string>, created: string, id: string, kind: string, name: string, permissions: record<effective: list>, selfLink: string, starred: bool, updated: string>, kind: string, profile: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, webproperty: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>>
# operationId: analytics.provisioning.createAccountTree
export def "analytics-provisioning-create-account-tree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --account-name: string
  --kind: string # Resource type for account ticket. (default: analytics#accountTreeRequest)
  --profile-name: string
  --timezone: string
  --webproperty-name: string
  --website-url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/provisioning/createAccountTree"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: kind, var: kind}, {name: profileName, var: profile_name}, {name: timezone, var: timezone}, {name: webpropertyName, var: webproperty_name}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, account_name: $account_name, kind: $kind, profile_name: $profile_name, timezone: $timezone, webproperty_name: $webproperty_name, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert or update a user deletion requests.
#
# POST /userDeletion/userDeletionRequests:upsert
# Returns: record<deletionRequestTime: string, firebaseProjectId: string, id: record<type: string, userId: string>, kind: string, propertyId: string, webPropertyId: string>
# operationId: analytics.userDeletion.userDeletionRequest.upsert
export def "analytics-user-deletion-user-deletion-request-upsert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --firebase-project-id: string # Firebase Project Id
  --id: record # User ID. — shape: {type?: string, userId?: string}
  --kind: string # Value is "analytics#userDeletionRequest". (default: analytics#userDeletionRequest)
  --property-id: string # Property ID
  --web-property-id: string # Web property ID of the form UA-XXXXX-YY.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/userDeletion/userDeletionRequests:upsert"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: firebaseProjectId, var: firebase_project_id}, {name: id, var: id}, {name: kind, var: kind}, {name: propertyId, var: property_id}, {name: webPropertyId, var: web_property_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, firebase_project_id: $firebase_project_id, id: $id, kind: $kind, property_id: $property_id, web_property_id: $web_property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
