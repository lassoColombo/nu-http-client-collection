# Auto-generated client for Stream Chat API v79.19.1
# Source: https://api.apis.guru/v2/specs/stream-io-api.com/v79.19.1/openapi.json
# Auth (JWT): --token-jwt flag or $env.STREAM_CHAT_API_JWT_TOKEN
# Auth (api_key): --token-apikey flag or $env.STREAM_CHAT_API_APIKEY_TOKEN
# Auth (stream-auth-type): --token-streamauthtype flag or $env.STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN

const CLIENT = {
  base_url: "https://chat.stream-io-api.com"
  token_env_var: "STREAM_CHAT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: jwt, in: header, header_name: Authorization, prefix: JWT}
    {name: query-api_key, in: query, header_name: api_key, prefix: ""}
    {name: stream-auth-type, in: header, header_name: Stream-Auth-Type, prefix: ""}
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

def base-url-completer [] { ["https://chat.stream-io-api.com" "http://localhost:3030"] }
def auth-scheme-completer [] { ["jwt" "query-api_key" "stream-auth-type"] }

# Completers for enum parameters
def enforce-unique-usernames-completer [] { ["app" "no" "team"] }
def permission-version-completer [] { ["v1" "v2"] }
def video-provider-completer [] { ["agora" "hms"] }
def type-completer [] { ["audio" "video"] }
def automod-completer [] { ["AI" "disabled" "simple"] }
def automod-behavior-completer [] { ["block" "flag"] }
def blocklist-behavior-completer [] { ["block" "flag"] }
def push-provider-type-completer [] { ["apn" "firebase" "huawei" "xiaomi"] }
def push-provider-completer [] { ["apn" "firebase" "huawei" "xiaomi"] }
def mode-completer [] { ["insert" "upsert"] }
def language-completer [] { ["af" "am" "ar" "az" "bg" "bn" "bs" "cs" "da" "de" "el" "en" "es" "es-MX" "et" "fa" "fa-AF" "fi" "fr" "fr-CA" "ha" "he" "hi" "hr" "hu" "id" "it" "ja" "ka" "ko" "lv" "ms" "nl" "no" "pl" "ps" "pt" "ro" "ru" "sk" "sl" "so" "sq" "sr" "sv" "sw" "ta" "th" "tl" "tr" "uk" "ur" "vi" "zh" "zh-TW"] }
def conversations-completer [] { ["hard" "soft"] }
def messages-completer [] { ["hard" "pruning" "soft"] }
def user-completer [] { ["hard" "pruning" "soft"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-jwt" "token-apikey" "token-streamauthtype"]
  let return_types = {
    get-app: "record<app: record<agora_options: record<app_certificate: string, app_id: string, default_role: string, role_map: record>, async_url_enrich_enabled: bool, auto_translation_enabled: bool, before_message_send_hook_url: string, campaign_enabled: bool, cdn_expiration_seconds: float, channel_configs: record, custom_action_handler_url: string, disable_auth_checks: bool, disable_permissions_checks: bool, enforce_unique_usernames: string, file_upload_config: record<allowed_file_extensions: list, allowed_mime_types: list, blocked_file_extensions: list, blocked_mime_types: list>, grants: record, hms_options: record<app_certificate: string, app_id: string, default_role: string, role_map: record>, image_moderation_enabled: bool, image_moderation_labels: list<string>, image_upload_config: record<allowed_file_extensions: list, allowed_mime_types: list, blocked_file_extensions: list, blocked_mime_types: list>, multi_tenant_enabled: bool, name: string, organization: string, permission_version: string, policies: record, push_notifications: record<apn: record, firebase: record, huawei: record, offline_only: bool, providers: list, version: string, xiaomi: record>, reminders_interval: float, revoke_tokens_issued_before: string, search_backend: string, sqs_key: string, sqs_secret: string, sqs_url: string, suspended: bool, suspended_explanation: string, user_search_disallowed_roles: list<string>, video_provider: string, webhook_events: list<string>, webhook_url: string>, duration: string>"
    update-app: "record<duration: string>"
    list-block-lists: "record<blocklists: table<created_at: string, name: string, updated_at: string, words: list>, duration: string>"
    create-block-list: "record<duration: string>"
    delete-block-list: "record<duration: string>"
    get-block-list: "record<blocklist: record<created_at: string, name: string, updated_at: string, words: list<string>>, duration: string>"
    update-block-list: "record<duration: string>"
    get-call-token-1: "record<agora_app_id: string, agora_uid: float, duration: string, token: string>"
    get-call-token-call-id-0: "record<agora_app_id: string, agora_uid: float, duration: string, token: string>"
    query-campaigns: "record<campaigns: table<attachments: list, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, channels: record, duration: string, segments: record, users: record>"
    create-campaign: "record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>"
    delete-campaign: "record<duration: string>"
    update-campaign: "record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>"
    resume-campaign: "record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>"
    schedule-campaign: "record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>"
    stop-campaign: "record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>"
    test-campaign: "record<details: string, duration: string, results: record, status: string>"
    query-channels: "record<channels: table<channel: record, hidden: bool, hide_messages_before: string, members: list, membership: record, messages: list, pending_messages: list, pinned_messages: list, read: list, watcher_count: float, watchers: list>, duration: string>"
    delete-channels: "record<duration: string, result: record, task_id: string>"
    mark-channels-read: "record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>>"
    get-or-create-channel-type-1: "record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, hidden: bool, hide_messages_before: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, membership: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, pending_messages: table<channel: record, message: record, metadata: record, user: record>, pinned_messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, read: table<last_read: string, unread_messages: float, user: record>, watcher_count: float, watchers: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>"
    delete-channel: "record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string>"
    update-channel-partial: "record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>>"
    update-channel: "record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    create-call: "record<agora_app_id: string, agora_uid: float, call: record<agora: record<channel: string>, hms: record<room_id: string, room_name: string>, id: string, provider: string, type: string>, duration: string, token: string>"
    send-event: "record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>>"
    delete-file: "record<duration: string>"
    upload-file: "record<duration: string, file: string, thumb_url: string>"
    hide-channel: "record<duration: string>"
    delete-image: "record<duration: string>"
    upload-image: "record<duration: string, file: string, thumb_url: string, upload_sizes: table<crop: string, height: float, resize: string, width: float>>"
    send-message: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, pending_message_metadata: record>"
    get-many-messages: "record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>>"
    get-or-create-channel-type-id-0: "record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, hidden: bool, hide_messages_before: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, membership: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, pending_messages: table<channel: record, message: record, metadata: record, user: record>, pinned_messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, read: table<last_read: string, unread_messages: float, user: record>, watcher_count: float, watchers: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>"
    mark-read: "record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>>"
    show-channel: "record<duration: string>"
    stop-watching-channel: "record<duration: string>"
    truncate-channel: "record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    mark-unread: "record<duration: string>"
    list-channel-types: "record<channel_types: record, duration: string>"
    create-channel-type: "record<automod: string, automod_behavior: string, automod_thresholds: record<explicit: record<block: float, flag: float>, spam: record<block: float, flag: float>, toxic: record<block: float, flag: float>>, blocklist: string, blocklist_behavior: string, commands: list<string>, connect_events: bool, created_at: string, custom_events: bool, duration: string, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, permissions: table<action: string, name: string, owner: bool, priority: float, resources: list, roles: list>, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>"
    delete-channel-type: "record<duration: string>"
    get-channel-type: "record<duration: string>"
    update-channel-type: "record<automod: string, automod_behavior: string, automod_thresholds: record<explicit: record<block: float, flag: float>, spam: record<block: float, flag: float>, toxic: record<block: float, flag: float>>, blocklist: string, blocklist_behavior: string, commands: list<string>, connect_events: bool, created_at: string, custom_events: bool, duration: string, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, permissions: table<action: string, name: string, owner: bool, priority: float, resources: list, roles: list>, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>"
    check-push: "record<device_errors: record, duration: string, general_errors: list<string>, rendered_apn_template: string, rendered_firebase_template: string, rendered_message: record, skip_devices: bool>"
    check-sqs: "record<data: record, duration: string, error: string, status: string>"
    list-commands: "record<commands: table<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string>"
    create-command: "record<command: record<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string>"
    delete-command: "record<duration: string, name: string>"
    get-command: "record<args: string, created_at: string, description: string, duration: string, name: string, set: string, updated_at: string>"
    update-command: "record<command: record<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string>"
    delete-device: "record<duration: string>"
    list-devices: "record<devices: table<created_at: string, disabled: bool, disabled_reason: string, id: string, push_provider: string, push_provider_name: string, user_id: string>, duration: string>"
    create-device: "record<duration: string>"
    export-user: "record<duration: string, task_id: string>"
    export-channels: "record<duration: string, task_id: string>"
    get-export-channels-status: "record<created_at: string, duration: string, error: record<description: any, stacktrace: string, type: string, version: string>, result: record<path: string, s3_bucket_name: string, url: string>, status: string, task_id: string, updated_at: string>"
    create-guest: "record<access_token: string, duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>"
    create-import-url: "record<duration: string, path: string, upload_url: string>"
    list-imports: "record<duration: string, import_tasks: table<created_at: string, history: list, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>>"
    create-import: "record<duration: string, import_task: record<created_at: string, history: list<record>, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>>"
    get-import: "record<duration: string, import_task: record<created_at: string, history: list<record>, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>>"
    query-members: "record<duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>>"
    delete-message: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    get-message: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, pending_message_metadata: record>"
    update-message: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    update-message-partial: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    run-message-action: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    commit-message: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    send-reaction: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>>"
    delete-reaction: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>>"
    get-reactions: "record<duration: string, reactions: table<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>>"
    translate-message: "record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    get-replies: "record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>>"
    unban: "record<duration: string>"
    ban: "record<duration: string>"
    flag: "record<duration: string, flag: record<approved_at: string, created_at: string, created_by_automod: bool, details: record<automod: record>, rejected_at: string, reviewed_at: string, target_message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, target_message_id: string, target_user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    query-message-flags: "record<duration: string, flags: table<approved_at: string, created_at: string, created_by_automod: bool, message: record, moderation_result: record, rejected_at: string, reviewed_at: string, reviewed_by: record, updated_at: string, user: record>>"
    mute-user: "record<duration: string, mute: record<created_at: string, expires: string, target: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, mutes: table<created_at: string, expires: string, target: record, updated_at: string, user: record>, own_user: record<banned: bool, channel_mutes: list<record>, created_at: string, deactivated_at: string, deleted_at: string, devices: list<record>, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list<string>, mutes: list<record>, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, role: string, teams: list<string>, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>>"
    mute-channel: "record<channel_mute: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, created_at: string, expires: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, channel_mutes: table<channel: record, created_at: string, expires: string, updated_at: string, user: record>, duration: string, own_user: record<banned: bool, channel_mutes: list<record>, created_at: string, deactivated_at: string, deleted_at: string, devices: list<record>, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list<string>, mutes: list<record>, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, role: string, teams: list<string>, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>>"
    unflag: "record<duration: string, flag: record<approved_at: string, created_at: string, created_by_automod: bool, details: record<automod: record>, rejected_at: string, reviewed_at: string, target_message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, target_message_id: string, target_user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>"
    unmute-user: "record<duration: string>"
    unmute-channel: "record<duration: string>"
    get-og: "record<actions: table<name: string, style: string, text: string, type: string, value: string>, asset_url: string, author_icon: string, author_link: string, author_name: string, color: string, duration: string, fallback: string, fields: table<short: bool, title: string, value: string>, footer: string, footer_icon: string, giphy: record<fixed_height: record<frames: string, height: string, size: string, url: string, width: string>, fixed_height_downsampled: record<frames: string, height: string, size: string, url: string, width: string>, fixed_height_still: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width_downsampled: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width_still: record<frames: string, height: string, size: string, url: string, width: string>, original: record<frames: string, height: string, size: string, url: string, width: string>>, image_url: string, og_scrape_url: string, original_height: float, original_width: float, pretext: string, text: string, thumb_url: string, title: string, title_link: string, type: string>"
    list-permissions: "record<duration: string, permissions: table<action: string, condition: record, custom: bool, description: string, id: string, level: string, name: string, owner: bool, same_team: bool, tags: list>>"
    get-permission: "record<duration: string, permission: record<action: string, condition: record, custom: bool, description: string, id: string, level: string, name: string, owner: bool, same_team: bool, tags: list<string>>>"
    list-push-providers: "record<duration: string, push_providers: table<apn_auth_key: string, apn_auth_type: string, apn_development: bool, apn_host: string, apn_key_id: string, apn_notification_template: string, apn_p12_cert: string, apn_team_id: string, apn_topic: string, created_at: string, description: string, disabled_at: string, disabled_reason: string, firebase_apn_template: string, firebase_credentials: string, firebase_data_template: string, firebase_notification_template: string, firebase_server_key: string, huawei_app_id: string, huawei_app_secret: string, name: string, type: float, updated_at: string, xiaomi_app_secret: string, xiaomi_package_name: string>>"
    upsert-push-provider: "record<duration: string, push_provider: record<apn_auth_key: string, apn_auth_type: string, apn_development: bool, apn_host: string, apn_key_id: string, apn_notification_template: string, apn_p12_cert: string, apn_team_id: string, apn_topic: string, created_at: string, description: string, disabled_at: string, disabled_reason: string, firebase_apn_template: string, firebase_credentials: string, firebase_data_template: string, firebase_notification_template: string, firebase_server_key: string, huawei_app_id: string, huawei_app_secret: string, name: string, type: float, updated_at: string, xiaomi_app_secret: string, xiaomi_package_name: string>>"
    delete-push-provider: "record<duration: string>"
    query-banned-users: "record<bans: table<banned_by: record, channel: record, created_at: string, expires: string, reason: string, shadow: bool, user: record>, duration: string>"
    get-rate-limits: "record<android: record, duration: string, ios: record, server_side: record, web: record>"
    query-recipients: "record<campaigns: record, channels: record, duration: string, recipients: table<campaign_id: string, channel_cid: string, created_at: string, details: string, message_id: string, receiver_id: string, status: string, updated_at: string>, segments: record, users: record>"
    list-roles: "record<duration: string, roles: table<created_at: string, custom: bool, name: string, scopes: list, updated_at: string>>"
    create-role: "record<duration: string, role: record<created_at: string, custom: bool, name: string, scopes: list<string>, updated_at: string>>"
    delete-role: "record<duration: string>"
    search: "record<duration: string, next: string, previous: string, results: table<message: record>, results_warning: record<channel_search_cids: list<string>, channel_search_count: float, warning_code: float, warning_description: string>>"
    query-segments: "record<duration: string, segments: table<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>>"
    create-segment: "record<duration: string, segment: record<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>>"
    delete-segment: "record<duration: string>"
    update-segment: "record<duration: string, segment: record<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>>"
    sync: "record<duration: string, events: table<automoderation: bool, automoderation_scores: record, channel: record, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record, me: record, member: record, message: record, parent_id: string, reaction: record, reason: string, team: string, type: string, user: record, user_id: string, watcher_count: float>, inaccessible_cids: list<string>>"
    get-task: "record<created_at: string, duration: string, error: record<description: any, stacktrace: string, type: string, version: string>, result: record, status: string, task_id: string, updated_at: string>"
    query-users: "record<duration: string, users: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, shadow_banned: bool, teams: list, updated_at: string>>"
    update-users-partial: "record<duration: string, users: record>"
    update-users: "record<duration: string, users: record>"
    deactivate-users: "record<duration: string, task_id: string>"
    delete-users: "record<duration: string, task_id: string>"
    reactivate-users: "record<duration: string, task_id: string>"
    restore-users: "record<duration: string>"
    delete-user: "record<duration: string, task_id: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>"
    deactivate-user: "record<duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>"
    send-user-custom-event: "record<duration: string>"
    get-users-user-id-export: "record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, reactions: table<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>"
    reactivate-user: "record<duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-app" "update-app" "list-block-lists" "create-block-list" "delete-block-list" "get-block-list" "update-block-list" "get-call-token-1" "get-call-token-call-id-0" "query-campaigns" "create-campaign" "delete-campaign" "update-campaign" "resume-campaign" "schedule-campaign" "stop-campaign" "test-campaign" "query-channels" "delete-channels" "mark-channels-read" "get-or-create-channel-type-1" "delete-channel" "update-channel-partial" "update-channel" "create-call" "send-event" "delete-file" "upload-file" "hide-channel" "delete-image" "upload-image" "send-message" "get-many-messages" "get-or-create-channel-type-id-0" "mark-read" "show-channel" "stop-watching-channel" "truncate-channel" "mark-unread" "list-channel-types" "create-channel-type" "delete-channel-type" "get-channel-type" "update-channel-type" "check-push" "check-sqs" "list-commands" "create-command" "delete-command" "get-command" "update-command" "connect" "delete-device" "list-devices" "create-device" "export-user" "export-channels" "get-export-channels-status" "create-guest" "create-import-url" "list-imports" "create-import" "get-import" "long-poll" "query-members" "delete-message" "get-message" "update-message" "update-message-partial" "run-message-action" "commit-message" "send-reaction" "delete-reaction" "get-reactions" "translate-message" "get-replies" "unban" "ban" "flag" "query-message-flags" "mute-user" "mute-channel" "unflag" "unmute-user" "unmute-channel" "get-og" "list-permissions" "get-permission" "list-push-providers" "upsert-push-provider" "delete-push-provider" "query-banned-users" "get-rate-limits" "query-recipients" "list-roles" "create-role" "delete-role" "search" "query-segments" "create-segment" "delete-segment" "update-segment" "sync" "get-task" "query-users" "update-users-partial" "update-users" "deactivate-users" "delete-users" "reactivate-users" "restore-users" "delete-user" "deactivate-user" "send-user-custom-event" "get-users-user-id-export" "reactivate-user" "commands"] | sort) } | get name | first)
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

# Get App Settings
#
# GET /app
# Returns: record<app: record<agora_options: record<app_certificate: string, app_id: string, default_role: string, role_map: record>, async_url_enrich_enabled: bool, auto_translation_enabled: bool, before_message_send_hook_url: string, campaign_enabled: bool, cdn_expiration_seconds: float, channel_configs: record, custom_action_handler_url: string, disable_auth_checks: bool, disable_permissions_checks: bool, enforce_unique_usernames: string, file_upload_config: record<allowed_file_extensions: list, allowed_mime_types: list, blocked_file_extensions: list, blocked_mime_types: list>, grants: record, hms_options: record<app_certificate: string, app_id: string, default_role: string, role_map: record>, image_moderation_enabled: bool, image_moderation_labels: list<string>, image_upload_config: record<allowed_file_extensions: list, allowed_mime_types: list, blocked_file_extensions: list, blocked_mime_types: list>, multi_tenant_enabled: bool, name: string, organization: string, permission_version: string, policies: record, push_notifications: record<apn: record, firebase: record, huawei: record, offline_only: bool, providers: list, version: string, xiaomi: record>, reminders_interval: float, revoke_tokens_issued_before: string, search_backend: string, sqs_key: string, sqs_secret: string, sqs_url: string, suspended: bool, suspended_explanation: string, user_search_disallowed_roles: list<string>, video_provider: string, webhook_events: list<string>, webhook_url: string>, duration: string>
# operationId: GetApp
export def "get-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/app"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update App Settings
#
# PATCH /app
# Returns: record<duration: string>
# operationId: UpdateApp
export def "update-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --agora-options: record # shape: {app_certificate: string, app_id: string, default_role?: "attendee"|"publisher"|"subscriber"|"admin", role_map?: record}
  --apn-config: record # shape: {Disabled?: bool, auth_key?: string, auth_type?: "certificate"|"token", bundle_id?: string, development?: bool, host?: string, key_id?: string, notification_template?: string, p12_cert?: string, team_id?: string}
  --async-moderation-config: record # shape: {callback?: record, timeout_ms?: float}
  --async-url-enrich-enabled: oneof<nothing, bool>
  --auto-translation-enabled: oneof<nothing, bool>
  --before-message-send-hook-url: string
  --cdn-expiration-seconds: float
  --channel-hide-members-only: oneof<nothing, bool>
  --custom-action-handler-url: string
  --disable-auth-checks: oneof<nothing, bool>
  --disable-permissions-checks: oneof<nothing, bool>
  --enforce-unique-usernames: string@enforce-unique-usernames-completer
  --file-upload-config: record # shape: {allowed_file_extensions?: list<string>, allowed_mime_types?: list<string>, blocked_file_extensions?: list<string>, blocked_mime_types?: list<string>}
  --firebase-config: record # shape: {Disabled?: bool, apn_template?: string, credentials_json?: string, data_template?: string, notification_template?: string, server_key?: string}
  --grants: record
  --hms-options: record # shape: {app_certificate: string, app_id: string, default_role?: "attendee"|"publisher"|"subscriber"|"admin", role_map?: record}
  --huawei-config: record # shape: {Disabled?: bool, id?: string, secret?: string}
  --image-moderation-block-labels: list<string>
  --image-moderation-enabled: oneof<nothing, bool>
  --image-moderation-labels: list<string>
  --image-upload-config: record # shape: {allowed_file_extensions?: list<string>, allowed_mime_types?: list<string>, blocked_file_extensions?: list<string>, blocked_mime_types?: list<string>}
  --migrate-permissions-to-v2: oneof<nothing, bool>
  --multi-tenant-enabled: oneof<nothing, bool>
  --permission-version: string@permission-version-completer
  --push-config: record # shape: {offline_only?: bool, version?: "v1"|"v2"}
  --reminders-interval: float
  --revoke-tokens-issued-before: string # format: date-time
  --sqs-key: string
  --sqs-secret: string
  --sqs-url: string
  --user-search-disallowed-roles: list<string>
  --video-provider: string@video-provider-completer
  --webhook-events: list<string>
  --webhook-url: string
  --xiaomi-config: record # shape: {Disabled?: bool, package_name?: string, secret?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/app"
    body: {content_type: "application/json", kind: json, fields: [{name: agora_options, var: agora_options}, {name: apn_config, var: apn_config}, {name: async_moderation_config, var: async_moderation_config}, {name: async_url_enrich_enabled, var: async_url_enrich_enabled}, {name: auto_translation_enabled, var: auto_translation_enabled}, {name: before_message_send_hook_url, var: before_message_send_hook_url}, {name: cdn_expiration_seconds, var: cdn_expiration_seconds}, {name: channel_hide_members_only, var: channel_hide_members_only}, {name: custom_action_handler_url, var: custom_action_handler_url}, {name: disable_auth_checks, var: disable_auth_checks}, {name: disable_permissions_checks, var: disable_permissions_checks}, {name: enforce_unique_usernames, var: enforce_unique_usernames}, {name: file_upload_config, var: file_upload_config}, {name: firebase_config, var: firebase_config}, {name: grants, var: grants}, {name: hms_options, var: hms_options}, {name: huawei_config, var: huawei_config}, {name: image_moderation_block_labels, var: image_moderation_block_labels}, {name: image_moderation_enabled, var: image_moderation_enabled}, {name: image_moderation_labels, var: image_moderation_labels}, {name: image_upload_config, var: image_upload_config}, {name: migrate_permissions_to_v2, var: migrate_permissions_to_v2}, {name: multi_tenant_enabled, var: multi_tenant_enabled}, {name: permission_version, var: permission_version}, {name: push_config, var: push_config}, {name: reminders_interval, var: reminders_interval}, {name: revoke_tokens_issued_before, var: revoke_tokens_issued_before}, {name: sqs_key, var: sqs_key}, {name: sqs_secret, var: sqs_secret}, {name: sqs_url, var: sqs_url}, {name: user_search_disallowed_roles, var: user_search_disallowed_roles}, {name: video_provider, var: video_provider}, {name: webhook_events, var: webhook_events}, {name: webhook_url, var: webhook_url}, {name: xiaomi_config, var: xiaomi_config}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    agora_options: $agora_options, apn_config: $apn_config, async_moderation_config: $async_moderation_config, async_url_enrich_enabled: $async_url_enrich_enabled, auto_translation_enabled: $auto_translation_enabled, before_message_send_hook_url: $before_message_send_hook_url, cdn_expiration_seconds: $cdn_expiration_seconds, channel_hide_members_only: $channel_hide_members_only, custom_action_handler_url: $custom_action_handler_url, disable_auth_checks: $disable_auth_checks, disable_permissions_checks: $disable_permissions_checks, enforce_unique_usernames: $enforce_unique_usernames, file_upload_config: $file_upload_config, firebase_config: $firebase_config, grants: $grants, hms_options: $hms_options, huawei_config: $huawei_config, image_moderation_block_labels: $image_moderation_block_labels, image_moderation_enabled: $image_moderation_enabled, image_moderation_labels: $image_moderation_labels, image_upload_config: $image_upload_config, migrate_permissions_to_v2: $migrate_permissions_to_v2, multi_tenant_enabled: $multi_tenant_enabled, permission_version: $permission_version, push_config: $push_config, reminders_interval: $reminders_interval, revoke_tokens_issued_before: $revoke_tokens_issued_before, sqs_key: $sqs_key, sqs_secret: $sqs_secret, sqs_url: $sqs_url, user_search_disallowed_roles: $user_search_disallowed_roles, video_provider: $video_provider, webhook_events: $webhook_events, webhook_url: $webhook_url, xiaomi_config: $xiaomi_config
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List block lists
#
# GET /blocklists
# Returns: record<blocklists: table<created_at: string, name: string, updated_at: string, words: list>, duration: string>
# operationId: ListBlockLists
export def "list-block-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/blocklists"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create block list
#
# POST /blocklists
# Returns: record<duration: string>
# operationId: CreateBlockList
export def "create-block-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Block list name
  words: list<string> # List of words to block
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/blocklists"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: words, var: words}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name, words: $words
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete block list
#
# DELETE /blocklists/{name}
# Returns: record<duration: string>
# operationId: DeleteBlockList
export def "delete-block-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/blocklists/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get block list
#
# GET /blocklists/{name}
# Returns: record<blocklist: record<created_at: string, name: string, updated_at: string, words: list<string>>, duration: string>
# operationId: GetBlockList
export def "get-block-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/blocklists/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update block list
#
# PUT /blocklists/{name}
# Returns: record<duration: string>
# operationId: UpdateBlockList
export def "update-block-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-name: string # (spec name: Name)
  --words: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/blocklists/{name}"
    path_params: [{name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: body_name}, {name: words, var: words}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name, body_name: $body_name, words: $words
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Call Token ()
#
# POST /calls/
# Returns: record<agora_app_id: string, agora_uid: float, duration: string, token: string>
# operationId: GetCallToken__1
export def "get-call-token-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string # **Server-side only**. User ID which server acts upon
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/"
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Call Token (call_id)
#
# POST /calls/{call_id}
# Returns: record<agora_app_id: string, agora_uid: float, duration: string, token: string>
# operationId: GetCallToken_call_id_0
export def "get-call-token-call-id-0" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string # **Server-side only**. User ID which server acts upon
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_id}"
    path_params: [{name: call_id, var: call_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    call_id: $call_id, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query campaigns
#
# GET /campaigns
# Returns: record<campaigns: table<attachments: list, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, channels: record, duration: string, segments: record, users: record>
# operationId: QueryCampaigns
export def "query-campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/campaigns"
    query: [{name: payload, var: payload}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    payload: $payload
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create campaign
#
# POST /campaigns
# Returns: record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>
# operationId: CreateCampaign
export def "create-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  campaign: record # shape: {attachments?: list, channel_type?: string, defaults?: record, description?: string, name: string, segment_id: string, sender_id: string, text: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/campaigns"
    body: {content_type: "application/json", kind: json, fields: [{name: campaign, var: campaign}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    campaign: $campaign
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete campaign
#
# DELETE /campaigns/{id}
# Returns: record<duration: string>
# operationId: DeleteCampaign
export def "delete-campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recipients: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/campaigns/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: recipients, var: recipients}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, recipients: $recipients
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update campaign
#
# PUT /campaigns/{id}
# Returns: record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>
# operationId: UpdateCampaign
export def "update-campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  campaign: record # shape: {attachments?: list, channel_type?: string, defaults?: record, description?: string, name?: string, segment_id?: string, sender_id?: string, text?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/campaigns/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: campaign, var: campaign}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, campaign: $campaign
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resume campaign
#
# PATCH /campaigns/{id}/resume
# Returns: record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>
# operationId: ResumeCampaign
export def "resume-campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/campaigns/{id}/resume"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule campaign
#
# PATCH /campaigns/{id}/schedule
# Returns: record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>
# operationId: ScheduleCampaign
export def "schedule-campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scheduled-for: float
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/campaigns/{id}/schedule"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: scheduled_for, var: scheduled_for}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, scheduled_for: $scheduled_for
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop campaign
#
# PATCH /campaigns/{id}/stop
# Returns: record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string>
# operationId: StopCampaign
export def "stop-campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/campaigns/{id}/stop"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test campaign
#
# POST /campaigns/{id}/test
# Returns: record<details: string, duration: string, results: record, status: string>
# operationId: TestCampaign
export def "test-campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/campaigns/{id}/test"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: users, var: users}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, users: $users
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query channels
#
# POST /channels
# Returns: record<channels: table<channel: record, hidden: bool, hide_messages_before: string, members: list, membership: record, messages: list, pending_messages: list, pinned_messages: list, read: list, watcher_count: float, watchers: list>, duration: string>
# operationId: QueryChannels
export def "query-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --connection-id: string
  --body-client-id: string # (spec name: client_id)
  --body-connection-id: string # (spec name: connection_id)
  --filter-conditions: record
  --limit: float # Number of channels to limit
  --member-limit: float # Number of members to limit
  --message-limit: float # Number of messages to limit
  --offset: float # Channel pagination offset
  --presence: oneof<nothing, bool>
  sort: list # List of sort parameters — item shape: {direction?: float, field?: string}
  --state: oneof<nothing, bool> # Whether to update channel state or not
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
  --watch: oneof<nothing, bool> # Whether to start watching found channels or not
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels"
    query: [{name: client_id, var: client_id}, {name: connection_id, var: connection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: body_client_id}, {name: connection_id, var: body_connection_id}, {name: filter_conditions, var: filter_conditions}, {name: limit, var: limit}, {name: member_limit, var: member_limit}, {name: message_limit, var: message_limit}, {name: offset, var: offset}, {name: presence, var: presence}, {name: sort, var: sort}, {name: state, var: state}, {name: user, var: user}, {name: user_id, var: user_id}, {name: watch, var: watch}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    client_id: $client_id, connection_id: $connection_id, body_client_id: $body_client_id, body_connection_id: $body_connection_id, filter_conditions: $filter_conditions, limit: $limit, member_limit: $member_limit, message_limit: $message_limit, offset: $offset, presence: $presence, sort: $sort, state: $state, user: $user, user_id: $user_id, watch: $watch
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes channels asynchronously
#
# POST /channels/delete
# Returns: record<duration: string, result: record, task_id: string>
# operationId: DeleteChannels
export def "delete-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cids: list<string> # All channels that should be deleted
  --hard-delete: oneof<nothing, bool> # Specify if channels and all ressources should be hard deleted
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: cids, var: cids}, {name: hard_delete, var: hard_delete}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    cids: $cids, hard_delete: $hard_delete
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark channels as read
#
# POST /channels/read
# Returns: record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>>
# operationId: MarkChannelsRead
export def "mark-channels-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/read"
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get or create channel (type)
#
# POST /channels/{type}/query
# Returns: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, hidden: bool, hide_messages_before: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, membership: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, pending_messages: table<channel: record, message: record, metadata: record, user: record>, pinned_messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, read: table<last_read: string, unread_messages: float, user: record>, watcher_count: float, watchers: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>
# operationId: GetOrCreateChannel_type_1
export def "get-or-create-channel-type-1" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --connection-id: string
  --body-client-id: string # (spec name: client_id)
  --body-connection-id: string # (spec name: connection_id)
  --data: record # shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
  --members: record # shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
  --messages: record # shape: {created_at_after?: string, created_at_after_or_equal?: string, created_at_around?: string, created_at_before?: string, created_at_before_or_equal?: string, id_around?: string, id_gt?: string, id_gte?: string, id_lt?: string, id_lte?: string, limit?: float, offset?: float}
  --presence: oneof<nothing, bool> # Fetch user presence info
  --state: oneof<nothing, bool> # Refresh channel state
  --watch: oneof<nothing, bool> # Start watching the channel
  --watchers: record # shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/query"
    path_params: [{name: type, var: type}]
    query: [{name: client_id, var: client_id}, {name: connection_id, var: connection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: body_client_id}, {name: connection_id, var: body_connection_id}, {name: data, var: data}, {name: members, var: members}, {name: messages, var: messages}, {name: presence, var: presence}, {name: state, var: state}, {name: watch, var: watch}, {name: watchers, var: watchers}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, client_id: $client_id, connection_id: $connection_id, body_client_id: $body_client_id, body_connection_id: $body_connection_id, data: $data, members: $members, messages: $messages, presence: $presence, state: $state, watch: $watch, watchers: $watchers
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete channel
#
# DELETE /channels/{type}/{id}
# Returns: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string>
# operationId: DeleteChannel
export def "delete-channel" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard-delete: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/channels/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: hard_delete, var: hard_delete}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, hard_delete: $hard_delete
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially update channel
#
# PATCH /channels/{type}/{id}
# Returns: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>>
# operationId: UpdateChannelPartial
export def "update-channel-partial" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  set: record
  unset: list<string>
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/channels/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: set, var: set}, {name: unset, var: unset}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, set: $set, unset: $unset, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update channel
#
# POST /channels/{type}/{id}
# Returns: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: UpdateChannel
export def "update-channel" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-invite: oneof<nothing, bool> # Set to `true` to accept the invite
  --add-members: list # List of user IDs to add to the channel — item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
  add_moderators: list<string> # List of user IDs to make channel moderators
  --assign-roles: list # List of channel member role assignments. If any specified user is not part of the channel, the request will fail — item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
  --cooldown: float # Sets cool down period for the channel in seconds
  --data: record # shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
  demote_moderators: list<string> # List of user IDs to take away moderators status from
  --hide-history: oneof<nothing, bool> # Set to `true` to hide channel's history when adding new members
  --invites: list # List of user IDs to invite to the channel — item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
  --message: record # Represents any chat message — shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
  --reject-invite: oneof<nothing, bool> # Set to `true` to reject the invite
  remove_members: list<string> # List of user IDs to remove from the channel
  --skip-push: oneof<nothing, bool> # When `message` is set disables all push notifications for it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accept_invite, var: accept_invite}, {name: add_members, var: add_members}, {name: add_moderators, var: add_moderators}, {name: assign_roles, var: assign_roles}, {name: cooldown, var: cooldown}, {name: data, var: data}, {name: demote_moderators, var: demote_moderators}, {name: hide_history, var: hide_history}, {name: invites, var: invites}, {name: message, var: message}, {name: reject_invite, var: reject_invite}, {name: remove_members, var: remove_members}, {name: skip_push, var: skip_push}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, accept_invite: $accept_invite, add_members: $add_members, add_moderators: $add_moderators, assign_roles: $assign_roles, cooldown: $cooldown, data: $data, demote_moderators: $demote_moderators, hide_history: $hide_history, invites: $invites, message: $message, reject_invite: $reject_invite, remove_members: $remove_members, skip_push: $skip_push, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a call
#
# POST /channels/{type}/{id}/call
# Returns: record<agora_app_id: string, agora_uid: float, call: record<agora: record<channel: string>, hms: record<room_id: string, room_name: string>, id: string, provider: string, type: string>, duration: string, token: string>
# operationId: CreateCall
export def "create-call" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # (spec name: id)
  --options: record
  --body-type: string@type-completer # (spec name: type)
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string # **Server-side only**. User ID which server acts upon
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/call"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id, required: true}, {name: options, var: options}, {name: type, var: body_type, required: true}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, body_id: $body_id, options: $options, body_type: $body_type, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send event
#
# POST /channels/{type}/{id}/event
# Returns: record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>>
# operationId: SendEvent
export def "send-event" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # Represents an BaseEvent that happened in Stream Chat — shape: {automoderation?: bool, automoderation_scores?: record, channel?: record, channel_id?: string, channel_type?: string, cid?: string, connection_id?: string, created_at?: string, created_by?: record, me?: record, member?: record, message?: record, parent_id?: string, reaction?: record, reason?: string, team?: string, type: string, user?: record, user_id?: string, watcher_count?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/event"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, event: $event
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete file
#
# DELETE /channels/{type}/{id}/file
# Returns: record<duration: string>
# operationId: DeleteFile
export def "delete-file" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/channels/{type}/{id}/file"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: url, var: url}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, url: $url
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file
#
# POST /channels/{type}/{id}/file
# Returns: record<duration: string, file: string, thumb_url: string>
# operationId: UploadFile
export def "upload-file" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # file field
  --user: record # shape: {id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/file"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, file: $file, user: $user
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hide channel
#
# POST /channels/{type}/{id}/hide
# Returns: record<duration: string>
# operationId: HideChannel
export def "hide-channel" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-history: oneof<nothing, bool> # Whether to clear message history of the channel or not
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/hide"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: clear_history, var: clear_history}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, clear_history: $clear_history, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete image
#
# DELETE /channels/{type}/{id}/image
# Returns: record<duration: string>
# operationId: DeleteImage
export def "delete-image" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/channels/{type}/{id}/image"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: url, var: url}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, url: $url
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload image
#
# POST /channels/{type}/{id}/image
# Returns: record<duration: string, file: string, thumb_url: string, upload_sizes: table<crop: string, height: float, resize: string, width: float>>
# operationId: UploadImage
export def "upload-image" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string
  --upload-sizes: list # field with JSON-encoded array of image size configurations — item shape: {crop?: "top"|"bottom"|"left"|"right"|"center", height?: float, resize?: "clip"|"crop"|"scale"|"fill", width?: float}
  --user: record # shape: {id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/image"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: upload_sizes, var: upload_sizes}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, file: $file, upload_sizes: $upload_sizes, user: $user
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send new message
#
# POST /channels/{type}/{id}/message
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, pending_message_metadata: record>
# operationId: SendMessage
export def "send-message" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-moderation: oneof<nothing, bool> # Enable moderation on server-side requests
  --is-pending-message: oneof<nothing, bool> # Make the message a pending message. This message will not be viewable to others until it is committed.
  message: record # Represents any chat message — shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
  --pending-message-metadata: record
  --skip-enrich-url: oneof<nothing, bool> # Do not try to enrich the links within message
  --skip-push: oneof<nothing, bool> # Disables all push notifications for this message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/message"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: force_moderation, var: force_moderation}, {name: is_pending_message, var: is_pending_message}, {name: message, var: message}, {name: pending_message_metadata, var: pending_message_metadata}, {name: skip_enrich_url, var: skip_enrich_url}, {name: skip_push, var: skip_push}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, force_moderation: $force_moderation, is_pending_message: $is_pending_message, message: $message, pending_message_metadata: $pending_message_metadata, skip_enrich_url: $skip_enrich_url, skip_push: $skip_push
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get many messages
#
# GET /channels/{type}/{id}/messages
# Returns: record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>>
# operationId: GetManyMessages
export def "get-many-messages" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{type}/{id}/messages"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: ids, var: ids}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, ids: $ids
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get or create channel (type, id)
#
# POST /channels/{type}/{id}/query
# Returns: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, hidden: bool, hide_messages_before: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, membership: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, pending_messages: table<channel: record, message: record, metadata: record, user: record>, pinned_messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, read: table<last_read: string, unread_messages: float, user: record>, watcher_count: float, watchers: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>
# operationId: GetOrCreateChannel_type_id_0
export def "get-or-create-channel-type-id-0" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --connection-id: string
  --body-client-id: string # (spec name: client_id)
  --body-connection-id: string # (spec name: connection_id)
  --data: record # shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
  --members: record # shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
  --messages: record # shape: {created_at_after?: string, created_at_after_or_equal?: string, created_at_around?: string, created_at_before?: string, created_at_before_or_equal?: string, id_around?: string, id_gt?: string, id_gte?: string, id_lt?: string, id_lte?: string, limit?: float, offset?: float}
  --presence: oneof<nothing, bool> # Fetch user presence info
  --state: oneof<nothing, bool> # Refresh channel state
  --watch: oneof<nothing, bool> # Start watching the channel
  --watchers: record # shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/query"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: client_id, var: client_id}, {name: connection_id, var: connection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: body_client_id}, {name: connection_id, var: body_connection_id}, {name: data, var: data}, {name: members, var: members}, {name: messages, var: messages}, {name: presence, var: presence}, {name: state, var: state}, {name: watch, var: watch}, {name: watchers, var: watchers}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, client_id: $client_id, connection_id: $connection_id, body_client_id: $body_client_id, body_connection_id: $body_connection_id, data: $data, members: $members, messages: $messages, presence: $presence, state: $state, watch: $watch, watchers: $watchers
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark read
#
# POST /channels/{type}/{id}/read
# Returns: record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>>
# operationId: MarkRead
export def "mark-read" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message-id: string # ID of the message that is considered last read by client
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/read"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message_id, var: message_id}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, message_id: $message_id, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show channel
#
# POST /channels/{type}/{id}/show
# Returns: record<duration: string>
# operationId: ShowChannel
export def "show-channel" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/show"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop watching channel
#
# POST /channels/{type}/{id}/stop-watching
# Returns: record<duration: string>
# operationId: StopWatchingChannel
export def "stop-watching-channel" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --connection-id: string
  --body-client-id: string # (spec name: client_id)
  --body-connection-id: string # (spec name: connection_id)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/stop-watching"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: client_id, var: client_id}, {name: connection_id, var: connection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: body_client_id}, {name: connection_id, var: body_connection_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, client_id: $client_id, connection_id: $connection_id, body_client_id: $body_client_id, body_connection_id: $body_connection_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Truncate channel
#
# POST /channels/{type}/{id}/truncate
# Returns: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: TruncateChannel
export def "truncate-channel" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard-delete: oneof<nothing, bool> # Permanently delete channel data (messages, reactions, etc.)
  --message: record # Represents any chat message — shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
  --skip-push: oneof<nothing, bool> # When `message` is set disables all push notifications for it
  --truncated-at: string # Truncate channel data up to `truncated_at`. The system message (if provided) creation time is always greater than `truncated_at` (format: date-time)
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/truncate"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hard_delete, var: hard_delete}, {name: message, var: message}, {name: skip_push, var: skip_push}, {name: truncated_at, var: truncated_at}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, hard_delete: $hard_delete, message: $message, skip_push: $skip_push, truncated_at: $truncated_at, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark unread
#
# POST /channels/{type}/{id}/unread
# Returns: record<duration: string>
# operationId: MarkUnread
export def "mark-unread" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message_id: string # ID of the message from where the channel is marked unread
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{type}/{id}/unread"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message_id, var: message_id}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, id: $id, message_id: $message_id, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List channel types
#
# GET /channeltypes
# Returns: record<channel_types: record, duration: string>
# operationId: ListChannelTypes
export def "list-channel-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channeltypes"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create channel type
#
# POST /channeltypes
# Returns: record<automod: string, automod_behavior: string, automod_thresholds: record<explicit: record<block: float, flag: float>, spam: record<block: float, flag: float>, toxic: record<block: float, flag: float>>, blocklist: string, blocklist_behavior: string, commands: list<string>, connect_events: bool, created_at: string, custom_events: bool, duration: string, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, permissions: table<action: string, name: string, owner: bool, priority: float, resources: list, roles: list>, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>
# operationId: CreateChannelType
export def "create-channel-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  automod: string@automod-completer # Enables automatic message moderation
  --automod-behavior: string@automod-behavior-completer # Sets behavior of automatic moderation
  --blocklist: string # Name of the blocklist to use
  --blocklist-behavior: string@blocklist-behavior-completer # Sets behavior of blocklist
  --commands: list<string> # List of commands that channel supports
  --connect-events: oneof<nothing, bool> # Connect events support
  --custom-events: oneof<nothing, bool> # Enables custom events
  --grants: record
  --max-message-length: float # Number of maximum message characters
  --message-retention: string # Number of days to keep messages. 'infinite' disables retention
  --mutes: oneof<nothing, bool> # Enables mutes
  name: string # Channel type name
  --permissions: list # List of permissions for the channel type — item shape: {action?: "Deny"|"Allow", name: string, owner?: bool, priority: float, resources?: list<string>, roles?: list<string>}
  --push-notifications: oneof<nothing, bool> # Enables push notifications
  --reactions: oneof<nothing, bool> # Enables message reactions
  --read-events: oneof<nothing, bool> # Read events support
  --replies: oneof<nothing, bool> # Enables message replies (threads)
  --search: oneof<nothing, bool> # Enables message search
  --typing-events: oneof<nothing, bool> # Typing events support
  --uploads: oneof<nothing, bool> # Enables file uploads
  --url-enrichment: oneof<nothing, bool> # Enables URL enrichment
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channeltypes"
    body: {content_type: "application/json", kind: json, fields: [{name: automod, var: automod}, {name: automod_behavior, var: automod_behavior}, {name: blocklist, var: blocklist}, {name: blocklist_behavior, var: blocklist_behavior}, {name: commands, var: commands}, {name: connect_events, var: connect_events}, {name: custom_events, var: custom_events}, {name: grants, var: grants}, {name: max_message_length, var: max_message_length}, {name: message_retention, var: message_retention}, {name: mutes, var: mutes}, {name: name, var: name}, {name: permissions, var: permissions}, {name: push_notifications, var: push_notifications}, {name: reactions, var: reactions}, {name: read_events, var: read_events}, {name: replies, var: replies}, {name: search, var: search}, {name: typing_events, var: typing_events}, {name: uploads, var: uploads}, {name: url_enrichment, var: url_enrichment}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    automod: $automod, automod_behavior: $automod_behavior, blocklist: $blocklist, blocklist_behavior: $blocklist_behavior, commands: $commands, connect_events: $connect_events, custom_events: $custom_events, grants: $grants, max_message_length: $max_message_length, message_retention: $message_retention, mutes: $mutes, name: $name, permissions: $permissions, push_notifications: $push_notifications, reactions: $reactions, read_events: $read_events, replies: $replies, search: $search, typing_events: $typing_events, uploads: $uploads, url_enrichment: $url_enrichment
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete channel type
#
# DELETE /channeltypes/{name}
# Returns: record<duration: string>
# operationId: DeleteChannelType
export def "delete-channel-type" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/channeltypes/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel type
#
# GET /channeltypes/{name}
# Returns: record<duration: string>
# operationId: GetChannelType
export def "get-channel-type" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channeltypes/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update channel type
#
# PUT /channeltypes/{name}
# Returns: record<automod: string, automod_behavior: string, automod_thresholds: record<explicit: record<block: float, flag: float>, spam: record<block: float, flag: float>, toxic: record<block: float, flag: float>>, blocklist: string, blocklist_behavior: string, commands: list<string>, connect_events: bool, created_at: string, custom_events: bool, duration: string, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, permissions: table<action: string, name: string, owner: bool, priority: float, resources: list, roles: list>, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>
# operationId: UpdateChannelType
export def "update-channel-type" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-from-path: string
  automod: string@automod-completer
  --automod-behavior: string@automod-behavior-completer
  --automod-thresholds: record # Sets thresholds for AI moderation — shape: {explicit?: record, spam?: record, toxic?: record}
  --blocklist: string
  --blocklist-behavior: string@blocklist-behavior-completer
  --commands: list<string> # List of commands that channel supports
  --connect-events: oneof<nothing, bool>
  --custom-events: oneof<nothing, bool>
  --grants: record
  --max-message-length: float
  --message-retention: string
  --mutes: oneof<nothing, bool>
  --permissions: list # item shape: {action?: "Deny"|"Allow", name: string, owner?: bool, priority: float, resources?: list<string>, roles?: list<string>}
  --push-notifications: oneof<nothing, bool>
  --quotes: oneof<nothing, bool>
  --reactions: oneof<nothing, bool>
  --read-events: oneof<nothing, bool>
  --reminders: oneof<nothing, bool>
  --replies: oneof<nothing, bool>
  --search: oneof<nothing, bool>
  --typing-events: oneof<nothing, bool>
  --uploads: oneof<nothing, bool>
  --url-enrichment: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/channeltypes/{name}"
    path_params: [{name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: NameFromPath, var: name_from_path}, {name: automod, var: automod}, {name: automod_behavior, var: automod_behavior}, {name: automod_thresholds, var: automod_thresholds}, {name: blocklist, var: blocklist}, {name: blocklist_behavior, var: blocklist_behavior}, {name: commands, var: commands}, {name: connect_events, var: connect_events}, {name: custom_events, var: custom_events}, {name: grants, var: grants}, {name: max_message_length, var: max_message_length}, {name: message_retention, var: message_retention}, {name: mutes, var: mutes}, {name: permissions, var: permissions}, {name: push_notifications, var: push_notifications}, {name: quotes, var: quotes}, {name: reactions, var: reactions}, {name: read_events, var: read_events}, {name: reminders, var: reminders}, {name: replies, var: replies}, {name: search, var: search}, {name: typing_events, var: typing_events}, {name: uploads, var: uploads}, {name: url_enrichment, var: url_enrichment}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name, name_from_path: $name_from_path, automod: $automod, automod_behavior: $automod_behavior, automod_thresholds: $automod_thresholds, blocklist: $blocklist, blocklist_behavior: $blocklist_behavior, commands: $commands, connect_events: $connect_events, custom_events: $custom_events, grants: $grants, max_message_length: $max_message_length, message_retention: $message_retention, mutes: $mutes, permissions: $permissions, push_notifications: $push_notifications, quotes: $quotes, reactions: $reactions, read_events: $read_events, reminders: $reminders, replies: $replies, search: $search, typing_events: $typing_events, uploads: $uploads, url_enrichment: $url_enrichment
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check push
#
# POST /check_push
# Returns: record<device_errors: record, duration: string, general_errors: list<string>, rendered_apn_template: string, rendered_firebase_template: string, rendered_message: record, skip_devices: bool>
# operationId: CheckPush
export def "check-push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apn-template: string # Push message template for APN
  --firebase-data-template: string # Push message data template for Firebase
  --firebase-template: string # Push message template for Firebase
  --message-id: string # Message ID to send push notification for
  --push-provider-name: string # Name of push provider
  --push-provider-type: string@push-provider-type-completer # Push provider type
  --skip-devices: oneof<nothing, bool> # Don't require existing devices to render templates
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/check_push"
    body: {content_type: "application/json", kind: json, fields: [{name: apn_template, var: apn_template}, {name: firebase_data_template, var: firebase_data_template}, {name: firebase_template, var: firebase_template}, {name: message_id, var: message_id}, {name: push_provider_name, var: push_provider_name}, {name: push_provider_type, var: push_provider_type}, {name: skip_devices, var: skip_devices}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    apn_template: $apn_template, firebase_data_template: $firebase_data_template, firebase_template: $firebase_template, message_id: $message_id, push_provider_name: $push_provider_name, push_provider_type: $push_provider_type, skip_devices: $skip_devices, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check SQS
#
# POST /check_sqs
# Returns: record<data: record, duration: string, error: string, status: string>
# operationId: CheckSQS
export def "check-sqs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sqs-key: string # AWS SQS access key
  --sqs-secret: string # AWS SQS key secret
  --sqs-url: string # AWS SQS endpoint URL
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/check_sqs"
    body: {content_type: "application/json", kind: json, fields: [{name: sqs_key, var: sqs_key}, {name: sqs_secret, var: sqs_secret}, {name: sqs_url, var: sqs_url}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    sqs_key: $sqs_key, sqs_secret: $sqs_secret, sqs_url: $sqs_url
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commands
#
# GET /commands
# Returns: record<commands: table<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string>
# operationId: ListCommands
export def "list-commands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/commands"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create command
#
# POST /commands
# Returns: record<command: record<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string>
# operationId: CreateCommand
export def "create-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --args: string # Arguments help text, shown in commands auto-completion
  description: string # Description, shown in commands auto-completion
  name: string # Unique command name
  --set: string # Set name used for grouping commands
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/commands"
    body: {content_type: "application/json", kind: json, fields: [{name: args, var: args}, {name: description, var: description}, {name: name, var: name}, {name: set, var: set}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    args: $args, description: $description, name: $name, set: $set
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete command
#
# DELETE /commands/{name}
# Returns: record<duration: string, name: string>
# operationId: DeleteCommand
export def "delete-command" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/commands/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get command
#
# GET /commands/{name}
# Returns: record<args: string, created_at: string, description: string, duration: string, name: string, set: string, updated_at: string>
# operationId: GetCommand
export def "get-command" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/commands/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update command
#
# PUT /commands/{name}
# Returns: record<command: record<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string>
# operationId: UpdateCommand
export def "update-command" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-name: string # (spec name: Name)
  --args: string # Arguments help text, shown in commands auto-completion
  description: string # Description, shown in commands auto-completion
  --set: string # Set name used for grouping commands
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/commands/{name}"
    path_params: [{name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: body_name}, {name: args, var: args}, {name: description, var: description}, {name: set, var: set}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name, body_name: $body_name, args: $args, description: $description, set: $set
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Connect (WebSocket)
#
# GET /connect
# operationId: Connect
export def "connect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: string
]: nothing -> any {
  http-request {
    method: get
    path: "/connect"
    query: [{name: json, var: json}]
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    json: $json
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete device
#
# DELETE /devices
# Returns: record<duration: string>
# operationId: DeleteDevice
export def "delete-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --user-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/devices"
    query: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List devices
#
# GET /devices
# Returns: record<devices: table<created_at: string, disabled: bool, disabled_reason: string, id: string, push_provider: string, push_provider_name: string, user_id: string>, duration: string>
# operationId: ListDevices
export def "list-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/devices"
    query: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create device
#
# POST /devices
# Returns: record<duration: string>
# operationId: CreateDevice
export def "create-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --push-provider: string@push-provider-completer
  --push-provider-name: string
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string # **Server-side only**. User ID which server acts upon
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/devices"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: push_provider, var: push_provider}, {name: push_provider_name, var: push_provider_name}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, push_provider: $push_provider, push_provider_name: $push_provider_name, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export users
#
# POST /export/users
# Returns: record<duration: string, task_id: string>
# operationId: ExportUser
export def "export-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/export/users"
    body: {content_type: "application/json", kind: json, fields: [{name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user_ids: $user_ids
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export channels
#
# POST /export_channels
# Returns: record<duration: string, task_id: string>
# operationId: ExportChannels
export def "export-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channels: list # Export options for channels — item shape: {cid?: string, id?: string, messages_since?: string, messages_until?: string, type?: string}
  --clear-deleted-message-text: oneof<nothing, bool> # Set if deleted message text should be cleared
  --export-users: oneof<nothing, bool>
  --include-truncated-messages: oneof<nothing, bool> # Set if you want to include truncated messages
  --version: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/export_channels"
    body: {content_type: "application/json", kind: json, fields: [{name: channels, var: channels}, {name: clear_deleted_message_text, var: clear_deleted_message_text}, {name: export_users, var: export_users}, {name: include_truncated_messages, var: include_truncated_messages}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    channels: $channels, clear_deleted_message_text: $clear_deleted_message_text, export_users: $export_users, include_truncated_messages: $include_truncated_messages, version: $version
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export channels status
#
# GET /export_channels/{id}
# Returns: record<created_at: string, duration: string, error: record<description: any, stacktrace: string, type: string, version: string>, result: record<path: string, s3_bucket_name: string, url: string>, status: string, task_id: string, updated_at: string>
# operationId: GetExportChannelsStatus
export def "get-export-channels-status" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/export_channels/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create guest
#
# POST /guest
# Returns: record<access_token: string, duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>
# operationId: CreateGuest
export def "create-guest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/guest"
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user: $user
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create import URL
#
# POST /import_urls
# Returns: record<duration: string, path: string, upload_url: string>
# operationId: CreateImportURL
export def "create-import-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filename: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/import_urls"
    body: {content_type: "application/json", kind: json, fields: [{name: filename, var: filename}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    filename: $filename
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get import
#
# GET /imports
# Returns: record<duration: string, import_tasks: table<created_at: string, history: list, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>>
# operationId: ListImports
export def "list-imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/imports"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create import
#
# POST /imports
# Returns: record<duration: string, import_task: record<created_at: string, history: list<record>, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>>
# operationId: CreateImport
export def "create-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer
  path: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/imports"
    body: {content_type: "application/json", kind: json, fields: [{name: mode, var: mode}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    mode: $mode, path: $path
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get import
#
# GET /imports/{id}
# Returns: record<duration: string, import_task: record<created_at: string, history: list<record>, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>>
# operationId: GetImport
export def "get-import" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/imports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long Poll (Transport)
#
# GET /longpoll
# operationId: LongPoll
export def "long-poll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: string
  --connection-id: string
]: nothing -> any {
  http-request {
    method: get
    path: "/longpoll"
    query: [{name: json, var: json}, {name: connection_id, var: connection_id}]
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    json: $json, connection_id: $connection_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query members
#
# GET /members
# Returns: record<duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>>
# operationId: QueryMembers
export def "query-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/members"
    query: [{name: payload, var: payload}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    payload: $payload
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete message
#
# DELETE /messages/{id}
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: DeleteMessage
export def "delete-message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: hard, var: hard}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, hard: $hard
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get message
#
# GET /messages/{id}
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, pending_message_metadata: record>
# operationId: GetMessage
export def "get-message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update message
#
# POST /messages/{id}
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: UpdateMessage
export def "update-message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: record # Represents any chat message — shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
  --pending-message-metadata: record
  --skip-enrich-url: oneof<nothing, bool> # Do not try to enrich the links within message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: pending_message_metadata, var: pending_message_metadata}, {name: skip_enrich_url, var: skip_enrich_url}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, message: $message, pending_message_metadata: $pending_message_metadata, skip_enrich_url: $skip_enrich_url
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially message update
#
# PUT /messages/{id}
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: UpdateMessagePartial
export def "update-message-partial" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  set: record # Sets new field values
  --skip-enrich-url: oneof<nothing, bool> # Do not try to enrich the links within message
  unset: list<string> # Array of field names to unset
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: set, var: set}, {name: skip_enrich_url, var: skip_enrich_url}, {name: unset, var: unset}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, set: $set, skip_enrich_url: $skip_enrich_url, unset: $unset, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run message command action
#
# POST /messages/{id}/action
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: RunMessageAction
export def "run-message-action" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # (spec name: ID)
  form_data: record # Data to execute command with
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/{id}/action"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ID, var: body_id}, {name: form_data, var: form_data}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, body_id: $body_id, form_data: $form_data, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commit message
#
# POST /messages/{id}/commit
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: CommitMessage
export def "commit-message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/messages/{id}/commit"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send reaction
#
# POST /messages/{id}/reaction
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>>
# operationId: SendReaction
export def "send-reaction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # (spec name: ID)
  --enforce-unique: oneof<nothing, bool> # Whether to replace all existing user reactions
  --reaction: record # Represents user reaction to a message (nullable) — shape: {message_id?: string, score?: float, type: string, user?: record, user_id?: string}
  --skip-push: oneof<nothing, bool> # Skips any mobile push notifications
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/{id}/reaction"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ID, var: body_id}, {name: enforce_unique, var: enforce_unique}, {name: reaction, var: reaction}, {name: skip_push, var: skip_push}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, body_id: $body_id, enforce_unique: $enforce_unique, reaction: $reaction, skip_push: $skip_push
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete reaction
#
# DELETE /messages/{id}/reaction/{type}
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>>
# operationId: DeleteReaction
export def "delete-reaction" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/messages/{id}/reaction/{type}"
    path_params: [{name: id, var: id}, {name: type, var: type}]
    query: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, type: $type, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get reactions
#
# GET /messages/{id}/reactions
# Returns: record<duration: string, reactions: table<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>>
# operationId: GetReactions
export def "get-reactions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string
  --offset: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/{id}/reactions"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, limit: $limit, offset: $offset
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate message
#
# POST /messages/{id}/translate
# Returns: record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: TranslateMessage
export def "translate-message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string@language-completer # Language to translate message to
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/{id}/translate"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: language, var: language}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, language: $language
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get replies
#
# GET /messages/{parent_id}/replies
# Returns: record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>>
# operationId: GetReplies
export def "get-replies" [
  parent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-gte: string
  --id-gt: string
  --id-lte: string
  --id-lt: string
  --created-at-after-or-equal: string
  --created-at-after: string
  --created-at-before-or-equal: string
  --created-at-before: string
  --id-around: string
  --created-at-around: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/{parent_id}/replies"
    path_params: [{name: parent_id, var: parent_id}]
    query: [{name: id_gte, var: id_gte}, {name: id_gt, var: id_gt}, {name: id_lte, var: id_lte}, {name: id_lt, var: id_lt}, {name: created_at_after_or_equal, var: created_at_after_or_equal}, {name: created_at_after, var: created_at_after}, {name: created_at_before_or_equal, var: created_at_before_or_equal}, {name: created_at_before, var: created_at_before}, {name: id_around, var: id_around}, {name: created_at_around, var: created_at_around}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    parent_id: $parent_id, id_gte: $id_gte, id_gt: $id_gt, id_lte: $id_lte, id_lt: $id_lt, created_at_after_or_equal: $created_at_after_or_equal, created_at_after: $created_at_after, created_at_before_or_equal: $created_at_before_or_equal, created_at_before: $created_at_before, id_around: $id_around, created_at_around: $created_at_around
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unban user
#
# DELETE /moderation/ban
# Returns: record<duration: string>
# operationId: Unban
export def "unban" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-user-id: string
  --type: string
  --id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/moderation/ban"
    query: [{name: target_user_id, var: target_user_id}, {name: type, var: type}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    target_user_id: $target_user_id, type: $type, id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ban user
#
# POST /moderation/ban
# Returns: record<duration: string>
# operationId: Ban
export def "ban" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --banned-by: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --banned-by-id: string # User ID who issued a ban
  --id: string # Channel ID to ban user in
  --ip-ban: oneof<nothing, bool> # Whether to perform IP ban or not
  --reason: string # Ban reason
  --shadow: oneof<nothing, bool> # Whether to perform shadow ban or not
  target_user_id: string # ID of user to ban
  --timeout: float # Timeout of ban in minutes. User will be unbanned after this period of time
  --type: string # Channel type to ban user in
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/moderation/ban"
    body: {content_type: "application/json", kind: json, fields: [{name: banned_by, var: banned_by}, {name: banned_by_id, var: banned_by_id}, {name: id, var: id}, {name: ip_ban, var: ip_ban}, {name: reason, var: reason}, {name: shadow, var: shadow}, {name: target_user_id, var: target_user_id}, {name: timeout, var: timeout}, {name: type, var: type}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    banned_by: $banned_by, banned_by_id: $banned_by_id, id: $id, ip_ban: $ip_ban, reason: $reason, shadow: $shadow, target_user_id: $target_user_id, timeout: $timeout, type: $type, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Flag
#
# POST /moderation/flag
# Returns: record<duration: string, flag: record<approved_at: string, created_at: string, created_by_automod: bool, details: record<automod: record>, rejected_at: string, reviewed_at: string, target_message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, target_message_id: string, target_user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: Flag
export def "flag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-message-id: string # ID of the message when reporting a message
  --target-user-id: string # ID of the user when reporting a user
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/moderation/flag"
    body: {content_type: "application/json", kind: json, fields: [{name: target_message_id, var: target_message_id}, {name: target_user_id, var: target_user_id}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    target_message_id: $target_message_id, target_user_id: $target_user_id, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query Message Flags
#
# GET /moderation/flags/message
# Returns: record<duration: string, flags: table<approved_at: string, created_at: string, created_by_automod: bool, message: record, moderation_result: record, rejected_at: string, reviewed_at: string, reviewed_by: record, updated_at: string, user: record>>
# operationId: QueryMessageFlags
export def "query-message-flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/moderation/flags/message"
    query: [{name: payload, var: payload}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    payload: $payload
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mute user
#
# POST /moderation/mute
# Returns: record<duration: string, mute: record<created_at: string, expires: string, target: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, mutes: table<created_at: string, expires: string, target: record, updated_at: string, user: record>, own_user: record<banned: bool, channel_mutes: list<record>, created_at: string, deactivated_at: string, deleted_at: string, devices: list<record>, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list<string>, mutes: list<record>, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, role: string, teams: list<string>, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>>
# operationId: MuteUser
export def "mute-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  target_ids: list<string> # User IDs to mute (if multiple users)
  --timeout: float # Duration of mute in minutes
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/moderation/mute"
    body: {content_type: "application/json", kind: json, fields: [{name: target_ids, var: target_ids}, {name: timeout, var: timeout}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    target_ids: $target_ids, timeout: $timeout, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mute channel
#
# POST /moderation/mute/channel
# Returns: record<channel_mute: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, created_at: string, expires: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, channel_mutes: table<channel: record, created_at: string, expires: string, updated_at: string, user: record>, duration: string, own_user: record<banned: bool, channel_mutes: list<record>, created_at: string, deactivated_at: string, deleted_at: string, devices: list<record>, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list<string>, mutes: list<record>, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, role: string, teams: list<string>, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>>
# operationId: MuteChannel
export def "mute-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_cids: list<string> # Channel CIDs to mute (if multiple channels)
  --expiration: float # Duration of mute in milliseconds
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/moderation/mute/channel"
    body: {content_type: "application/json", kind: json, fields: [{name: channel_cids, var: channel_cids}, {name: expiration, var: expiration}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    channel_cids: $channel_cids, expiration: $expiration, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unflag
#
# POST /moderation/unflag
# Returns: record<duration: string, flag: record<approved_at: string, created_at: string, created_by_automod: bool, details: record<automod: record>, rejected_at: string, reviewed_at: string, target_message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, target_message_id: string, target_user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>>
# operationId: Unflag
export def "unflag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-message-id: string # ID of the message when reporting a message
  --target-user-id: string # ID of the user when reporting a user
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/moderation/unflag"
    body: {content_type: "application/json", kind: json, fields: [{name: target_message_id, var: target_message_id}, {name: target_user_id, var: target_user_id}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    target_message_id: $target_message_id, target_user_id: $target_user_id, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmute user
#
# POST /moderation/unmute
# Returns: record<duration: string>
# operationId: UnmuteUser
export def "unmute-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  target_id: string
  target_ids: list<string>
  --timeout: float
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/moderation/unmute"
    body: {content_type: "application/json", kind: json, fields: [{name: target_id, var: target_id}, {name: target_ids, var: target_ids}, {name: timeout, var: timeout}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    target_id: $target_id, target_ids: $target_ids, timeout: $timeout, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmute channel
#
# POST /moderation/unmute/channel
# Returns: record<duration: string>
# operationId: UnmuteChannel
export def "unmute-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_cid: string
  channel_cids: list<string>
  --expiration: float
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/moderation/unmute/channel"
    body: {content_type: "application/json", kind: json, fields: [{name: channel_cid, var: channel_cid}, {name: channel_cids, var: channel_cids}, {name: expiration, var: expiration}, {name: user, var: user}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    channel_cid: $channel_cid, channel_cids: $channel_cids, expiration: $expiration, user: $user, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get OG
#
# GET /og
# Returns: record<actions: table<name: string, style: string, text: string, type: string, value: string>, asset_url: string, author_icon: string, author_link: string, author_name: string, color: string, duration: string, fallback: string, fields: table<short: bool, title: string, value: string>, footer: string, footer_icon: string, giphy: record<fixed_height: record<frames: string, height: string, size: string, url: string, width: string>, fixed_height_downsampled: record<frames: string, height: string, size: string, url: string, width: string>, fixed_height_still: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width_downsampled: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width_still: record<frames: string, height: string, size: string, url: string, width: string>, original: record<frames: string, height: string, size: string, url: string, width: string>>, image_url: string, og_scrape_url: string, original_height: float, original_width: float, pretext: string, text: string, thumb_url: string, title: string, title_link: string, type: string>
# operationId: GetOG
export def "get-og" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/og"
    query: [{name: url, var: url}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    url: $url
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List permissions
#
# GET /permissions
# Returns: record<duration: string, permissions: table<action: string, condition: record, custom: bool, description: string, id: string, level: string, name: string, owner: bool, same_team: bool, tags: list>>
# operationId: ListPermissions
export def "list-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/permissions"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get permission
#
# GET /permissions/{id}
# Returns: record<duration: string, permission: record<action: string, condition: record, custom: bool, description: string, id: string, level: string, name: string, owner: bool, same_team: bool, tags: list<string>>>
# operationId: GetPermission
export def "get-permission" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/permissions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List push providers
#
# GET /push_providers
# Returns: record<duration: string, push_providers: table<apn_auth_key: string, apn_auth_type: string, apn_development: bool, apn_host: string, apn_key_id: string, apn_notification_template: string, apn_p12_cert: string, apn_team_id: string, apn_topic: string, created_at: string, description: string, disabled_at: string, disabled_reason: string, firebase_apn_template: string, firebase_credentials: string, firebase_data_template: string, firebase_notification_template: string, firebase_server_key: string, huawei_app_id: string, huawei_app_secret: string, name: string, type: float, updated_at: string, xiaomi_app_secret: string, xiaomi_package_name: string>>
# operationId: ListPushProviders
export def "list-push-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/push_providers"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert a push provider
#
# POST /push_providers
# Returns: record<duration: string, push_provider: record<apn_auth_key: string, apn_auth_type: string, apn_development: bool, apn_host: string, apn_key_id: string, apn_notification_template: string, apn_p12_cert: string, apn_team_id: string, apn_topic: string, created_at: string, description: string, disabled_at: string, disabled_reason: string, firebase_apn_template: string, firebase_credentials: string, firebase_data_template: string, firebase_notification_template: string, firebase_server_key: string, huawei_app_id: string, huawei_app_secret: string, name: string, type: float, updated_at: string, xiaomi_app_secret: string, xiaomi_package_name: string>>
# operationId: UpsertPushProvider
export def "upsert-push-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --push-provider: record # shape: {apn_auth_key?: string, apn_auth_type?: string, apn_development?: bool, apn_host?: string, apn_key_id?: string, apn_notification_template?: string, apn_p12_cert?: string, apn_team_id?: string, apn_topic?: string, created_at?: string, description?: string, disabled_at?: string, disabled_reason?: string, firebase_apn_template?: string, firebase_credentials?: string, firebase_data_template?: string, firebase_notification_template?: string, firebase_server_key?: string, huawei_app_id?: string, ... (6 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/push_providers"
    body: {content_type: "application/json", kind: json, fields: [{name: push_provider, var: push_provider}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    push_provider: $push_provider
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a push provider
#
# DELETE /push_providers/{type}/{name}
# Returns: record<duration: string>
# operationId: DeletePushProvider
export def "delete-push-provider" [
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/push_providers/{type}/{name}"
    path_params: [{name: type, var: type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    type: $type, name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query Banned Users
#
# GET /query_banned_users
# Returns: record<bans: table<banned_by: record, channel: record, created_at: string, expires: string, reason: string, shadow: bool, user: record>, duration: string>
# operationId: QueryBannedUsers
export def "query-banned-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query_banned_users"
    query: [{name: payload, var: payload}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    payload: $payload
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get rate limits
#
# GET /rate_limits
# Returns: record<android: record, duration: string, ios: record, server_side: record, web: record>
# operationId: GetRateLimits
export def "get-rate-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --server-side: string
  --android: string
  --ios: string
  --web: string
  --endpoints: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rate_limits"
    query: [{name: server_side, var: server_side}, {name: android, var: android}, {name: ios, var: ios}, {name: web, var: web}, {name: endpoints, var: endpoints}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    server_side: $server_side, android: $android, ios: $ios, web: $web, endpoints: $endpoints
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query recipients
#
# GET /recipients
# Returns: record<campaigns: record, channels: record, duration: string, recipients: table<campaign_id: string, channel_cid: string, created_at: string, details: string, message_id: string, receiver_id: string, status: string, updated_at: string>, segments: record, users: record>
# operationId: QueryRecipients
export def "query-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipients"
    query: [{name: payload, var: payload}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    payload: $payload
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List roles
#
# GET /roles
# Returns: record<duration: string, roles: table<created_at: string, custom: bool, name: string, scopes: list, updated_at: string>>
# operationId: ListRoles
export def "list-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/roles"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create role
#
# POST /roles
# Returns: record<duration: string, role: record<created_at: string, custom: bool, name: string, scopes: list<string>, updated_at: string>>
# operationId: CreateRole
export def "create-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Role name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/roles"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete role
#
# DELETE /roles/{name}
# Returns: record<duration: string>
# operationId: DeleteRole
export def "delete-role" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/roles/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search messages
#
# GET /search
# Returns: record<duration: string, next: string, previous: string, results: table<message: record>, results_warning: record<channel_search_cids: list<string>, channel_search_count: float, warning_code: float, warning_description: string>>
# operationId: Search
export def "search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search"
    query: [{name: payload, var: payload}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    payload: $payload
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query segments
#
# GET /segments
# Returns: record<duration: string, segments: table<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>>
# operationId: QuerySegments
export def "query-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/segments"
    query: [{name: payload, var: payload}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    payload: $payload
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create segment
#
# POST /segments
# Returns: record<duration: string, segment: record<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>>
# operationId: CreateSegment
export def "create-segment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  segment: record # shape: {description?: string, filter: record, name: string, type: "user"|"channel"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/segments"
    body: {content_type: "application/json", kind: json, fields: [{name: segment, var: segment}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    segment: $segment
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete segment
#
# DELETE /segments/{id}
# Returns: record<duration: string>
# operationId: DeleteSegment
export def "delete-segment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/segments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update segment
#
# PUT /segments/{id}
# Returns: record<duration: string, segment: record<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>>
# operationId: UpdateSegment
export def "update-segment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  segment: record # shape: {description?: string, filter?: record, name?: string, type?: "user"|"channel"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/segments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: segment, var: segment}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, segment: $segment
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sync
#
# POST /sync
# Returns: record<duration: string, events: table<automoderation: bool, automoderation_scores: record, channel: record, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record, me: record, member: record, message: record, parent_id: string, reaction: record, reason: string, team: string, type: string, user: record, user_id: string, watcher_count: float>, inaccessible_cids: list<string>>
# operationId: Sync
export def "sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-inaccessible-cids: string
  --watch: string
  --client-id: string
  --connection-id: string
  --channel-cids: list<string> # List of channel CIDs to sync
  --body-client-id: string # (spec name: client_id)
  --body-connection-id: string # (spec name: connection_id)
  last_sync_at: string # Date from which synchronization should happen (format: date-time)
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
  --body-watch: oneof<nothing, bool> # If set to true this will start watching requested and newly added channels that user has access to. If error occurred with this option enabled and it is not an input error - channels will still be watched. (spec name: watch)
  --body-with-inaccessible-cids: oneof<nothing, bool> # If set to true this will add 'inaccessible_cids' to response type (spec name: with_inaccessible_cids)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sync"
    query: [{name: with_inaccessible_cids, var: with_inaccessible_cids}, {name: watch, var: watch}, {name: client_id, var: client_id}, {name: connection_id, var: connection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channel_cids, var: channel_cids}, {name: client_id, var: body_client_id}, {name: connection_id, var: body_connection_id}, {name: last_sync_at, var: last_sync_at}, {name: user, var: user}, {name: user_id, var: user_id}, {name: watch, var: body_watch}, {name: with_inaccessible_cids, var: body_with_inaccessible_cids}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    with_inaccessible_cids: $with_inaccessible_cids, watch: $watch, client_id: $client_id, connection_id: $connection_id, channel_cids: $channel_cids, body_client_id: $body_client_id, body_connection_id: $body_connection_id, last_sync_at: $last_sync_at, user: $user, user_id: $user_id, body_watch: $body_watch, body_with_inaccessible_cids: $body_with_inaccessible_cids
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status of a task
#
# GET /tasks/{id}
# Returns: record<created_at: string, duration: string, error: record<description: any, stacktrace: string, type: string, version: string>, result: record, status: string, task_id: string, updated_at: string>
# operationId: GetTask
export def "get-task" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query users
#
# GET /users
# Returns: record<duration: string, users: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, shadow_banned: bool, teams: list, updated_at: string>>
# operationId: QueryUsers
export def "query-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: payload, var: payload}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    payload: $payload
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially update user
#
# PATCH /users
# Returns: record<duration: string, users: record>
# operationId: UpdateUsersPartial
export def "update-users-partial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # User ID to update
  set: record
  unset: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: set, var: set}, {name: unset, var: unset}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    id: $id, set: $set, unset: $unset
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert users
#
# POST /users
# Returns: record<duration: string, users: record>
# operationId: UpdateUsers
export def "update-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: record # Object containing users
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: users, var: users}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    users: $users
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate users
#
# POST /users/deactivate
# Returns: record<duration: string, task_id: string>
# operationId: DeactivateUsers
export def "deactivate-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # ID of the user who deactivated the users
  --mark-messages-deleted: oneof<nothing, bool> # Makes messages appear to be deleted
  user_ids: list<string> # User IDs to deactivate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/deactivate"
    body: {content_type: "application/json", kind: json, fields: [{name: created_by_id, var: created_by_id}, {name: mark_messages_deleted, var: mark_messages_deleted}, {name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    created_by_id: $created_by_id, mark_messages_deleted: $mark_messages_deleted, user_ids: $user_ids
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Users
#
# POST /users/delete
# Returns: record<duration: string, task_id: string>
# operationId: DeleteUsers
export def "delete-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversations: string@conversations-completer # Conversation channels delete mode. Conversation channel is any channel which only has two members one of which is the user being deleted. * null or empty string - doesn't delete any conversation channels * soft - marks all conversation channels as deleted (same effect as Delete Channels with 'hard' option disabled) * hard - deletes channel and all its data completely including messages (same effect as Delete Channels with 'hard' option enabled)
  --messages: string@messages-completer # Message delete mode. * null or empty string - doesn't delete user messages * soft - marks all user messages as deleted without removing any related message data * pruning - marks all user messages as deleted, nullifies message information and removes some message data such as reactions and flags * hard - deletes messages completely with all related information
  --new-channel-owner-id: string
  --user: string@user-completer # User delete mode. * soft - marks user as deleted and retains all user data * pruning - marks user as deleted and nullifies user information * hard - deletes user completely. Requires 'hard' option for messages and conversations as well
  user_ids: list<string> # IDs of users to delete
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: conversations, var: conversations}, {name: messages, var: messages}, {name: new_channel_owner_id, var: new_channel_owner_id}, {name: user, var: user}, {name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    conversations: $conversations, messages: $messages, new_channel_owner_id: $new_channel_owner_id, user: $user, user_ids: $user_ids
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reactivate users
#
# POST /users/reactivate
# Returns: record<duration: string, task_id: string>
# operationId: ReactivateUsers
export def "reactivate-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # ID of the user who's reactivating the users
  --restore-messages: oneof<nothing, bool> # Restore previously deleted messages
  user_ids: list<string> # User IDs to reactivate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/reactivate"
    body: {content_type: "application/json", kind: json, fields: [{name: created_by_id, var: created_by_id}, {name: restore_messages, var: restore_messages}, {name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    created_by_id: $created_by_id, restore_messages: $restore_messages, user_ids: $user_ids
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore users
#
# POST /users/restore
# Returns: record<duration: string>
# operationId: RestoreUsers
export def "restore-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/restore"
    body: {content_type: "application/json", kind: json, fields: [{name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user_ids: $user_ids
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user
#
# DELETE /users/{user_id}
# Returns: record<duration: string, task_id: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>
# operationId: DeleteUser
export def "delete-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mark-messages-deleted: string
  --hard-delete: string
  --delete-conversation-channels: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: mark_messages_deleted, var: mark_messages_deleted}, {name: hard_delete, var: hard_delete}, {name: delete_conversation_channels, var: delete_conversation_channels}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user_id: $user_id, mark_messages_deleted: $mark_messages_deleted, hard_delete: $hard_delete, delete_conversation_channels: $delete_conversation_channels
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate user
#
# POST /users/{user_id}/deactivate
# Returns: record<duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>
# operationId: DeactivateUser
export def "deactivate-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # ID of the user who deactivated the user
  --mark-messages-deleted: oneof<nothing, bool> # Makes messages appear to be deleted
  --body-user-id: string # (spec name: user_id)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/deactivate"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_by_id, var: created_by_id}, {name: mark_messages_deleted, var: mark_messages_deleted}, {name: user_id, var: body_user_id, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user_id: $user_id, created_by_id: $created_by_id, mark_messages_deleted: $mark_messages_deleted, body_user_id: $body_user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send user event
#
# POST /users/{user_id}/event
# Returns: record<duration: string>
# operationId: SendUserCustomEvent
export def "send-user-custom-event" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {created_at?: string, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/event"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user_id: $user_id, event: $event
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export user
#
# GET /users/{user_id}/export
# Returns: record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, reactions: table<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>
export def "get-users-user-id-export" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/export"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reactivate user
#
# POST /users/{user_id}/reactivate
# Returns: record<duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>>
# operationId: ReactivateUser
export def "reactivate-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (Authorization)
  --token-apikey: string # Auth token for api_key (api_key)
  --token-streamauthtype: string # Auth token for stream-auth-type (Stream-Auth-Type)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # ID of the user who's reactivating the user
  --name: string # Set this field to put new name for the user
  --restore-messages: oneof<nothing, bool> # Restore previously deleted messages
  --body-user-id: string # (spec name: user_id)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/reactivate"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_by_id, var: created_by_id}, {name: name, var: name}, {name: restore_messages, var: restore_messages}, {name: user_id, var: body_user_id, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: jwt, var: token_jwt, env: STREAM_CHAT_API_JWT_TOKEN}, {scheme: query-api_key, var: token_apikey, env: STREAM_CHAT_API_APIKEY_TOKEN}, {scheme: stream-auth-type, var: token_streamauthtype, env: STREAM_CHAT_API_STREAMAUTHTYPE_TOKEN}]
  } {
    user_id: $user_id, created_by_id: $created_by_id, name: $name, restore_messages: $restore_messages, body_user_id: $body_user_id
    base_url: $base_url, token_jwt: $token_jwt, token_apikey: $token_apikey, token_streamauthtype: $token_streamauthtype, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
