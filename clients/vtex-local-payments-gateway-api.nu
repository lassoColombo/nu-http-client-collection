# Auto-generated client for Payments Gateway API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Payments-Gateway-API/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.PAYMENTS_GATEWAY_API_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "PAYMENTS_GATEWAY_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-vtex-api-appkey, in: header, header_name: X-VTEX-API-AppKey, prefix: ""}
    {name: x-vtex-api-apptoken, in: header, header_name: X-VTEX-API-AppToken, prefix: ""}
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.vtexpayments.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let return_types = {
    installmentsoptions: "record<installments: table<options: list, payment: record>, value: float>"
    available-payment-methods: "table<affiliationId: string, allowCommercialCondition: bool, allowCommercialPolicy: bool, allowCountry: bool, allowInstallments: bool, allowIssuer: bool, allowMultiple: bool, allowNotification: bool, allowPeriod: bool, antifraudConnectorImplementation: string, connectorId: int, connectorImplementation: string, description: string, dueDate: string, fields: string, groupName: string, id: int, implementation: string, isAvailable: bool, isCustom: bool, isSelfAuthorized: bool, name: string, requiresDocument: bool, requiresPhone: bool, rules: list<record>, validator: record<cardCodeMask: string, cardCodeRegex: string, mask: string, regex: string, useBillingAddress: bool, useCardHolderName: bool, useCvv: bool, useExpirationDate: bool, validCardLengths: string, weights: list>>"
    "1-createanewtransaction": "record<acceptHeader: string, antifraudAffiliationId: string, antifraudTid: string, authorizationDate: string, authorizationToken: string, buyer: string, cancelationDate: string, cancelationToken: string, cancellations: record<href: string>, channel: string, commitmentDate: string, commitmentToken: string, fields: table<name: string, value: string>, id: string, interactions: record<href: string>, ipAddress: string, markedForRecurrence: bool, owner: string, payments: record<href: string>, receiverUri: string, referenceKey: string, refundingDate: string, refundingToken: string, refunds: record<href: string>, salesChannel: string, settlements: record<href: string>, softDescriptor: string, startDate: string, status: string, timeoutStatus: int, totalRefunds: float, transactionId: string, urn: string, userAgent: string, value: int>"
    transaction-details: "record<acceptHeader: string, antifraudAffiliationId: string, antifraudTid: string, authorizationDate: string, authorizationToken: string, buyer: string, cancelationDate: string, cancelationToken: string, cancellations: record<href: string>, channel: string, commitmentDate: string, commitmentToken: string, fields: table<name: string, value: string>, id: string, interactions: record<href: string>, ipAddress: string, markedForRecurrence: bool, owner: string, payments: record<href: string>, receiverUri: string, referenceKey: string, refundingDate: string, refundingToken: string, refunds: record<href: string>, salesChannel: string, settlements: record<href: string>, softDescriptor: string, startDate: string, status: string, timeoutStatus: int, totalRefunds: float, transactionId: string, urn: string, userAgent: string, value: int>"
    payment-details: "record<ConnectorResponses: string, ShowConnectorResponses: bool, allowInstallments: bool, allowIssuer: bool, allowNotification: bool, connector: string, connectorResponse: string, currencyCode: string, description: string, fields: table<name: string, value: string>, group: string, id: string, installments: int, installmentsInterestRate: int, installmentsValue: int, isAvailable: bool, isCustom: bool, merchantName: string, paymentSystem: int, paymentSystemName: string, provider: string, referenceValue: int, returnCode: string, returnMessage: string, self: record<href: string>, sheets: string, status: string, tid: string, value: int>"
    settlethetransaction: "record<cancelledValue: int, connectorRefundedValue: int, message: string, processingDate: string, refundedToken: string, refundedValue: int, status: int, statusDetail: string, token: string>"
    transaction-settlement-details: "record<actions: table<connectorResponse: string, date: string, payment: record, paymentId: string, type: string, value: int>, requests: table<date: string, id: string, value: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["2-send-payments-public" "affiliations" "insert-affiliation" "affiliation-by-id" "update-affiliation" "installmentsoptions" "available-payment-methods" "rules" "insert-rule" "rule" "rule-by-id" "put-rule-by-id" "1-createanewtransaction" "transaction-details" "3-send-additional-data" "4-doauthorization" "cancelthetransaction" "2-send-payments-with-saved-credit-card" "payment-details" "refundthetransaction" "settlethetransaction" "transaction-settlement-details" "commands"] | sort) } | get name | first)
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

# 2.1 Send Payments Information Public
#
# POST /api/pub/transactions/{transactionId}/payments
# operationId: 2.SendPaymentsPublic
export def "2-send-payments-public" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # required, e.g. {{orderId}}
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pub/transactions/{transactionId}/payments"
    path_params: [{name: transactionId, var: transaction_id}]
    query: [{name: orderId, var: order_id, required: true}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, order_id: $order_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Affiliations
#
# GET /api/pvt/affiliations
# operationId: Affiliations
export def "affiliations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/pvt/affiliations"
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert Affiliation
#
# POST /api/pvt/affiliations
# operationId: InsertAffiliation
export def "insert-affiliation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  configuration: list # item shape: {name: string, value: string}
  implementation: string
  --is-configured: oneof<nothing, bool>
  --isdelivered: oneof<nothing, bool>
  name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pvt/affiliations"
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: configuration, var: configuration}, {name: implementation, var: implementation}, {name: isConfigured, var: is_configured, required: true}, {name: isdelivered, var: isdelivered, required: true}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept, configuration: $configuration, implementation: $implementation, is_configured: $is_configured, isdelivered: $isdelivered, name: $name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Affiliation By Id
#
# GET /api/pvt/affiliations/{affiliationId}
# operationId: AffiliationById
export def "affiliation-by-id" [
  affiliation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/pvt/affiliations/{affiliationId}"
    path_params: [{name: affiliationId, var: affiliation_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    affiliation_id: $affiliation_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Affiliation
#
# PUT /api/pvt/affiliations/{affiliationId}
# operationId: UpdateAffiliation
export def "update-affiliation" [
  affiliation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  configuration: list # item shape: {name: string, value: string}
  id: string
  implementation: string
  --is-configured: oneof<nothing, bool>
  --isdelivered: oneof<nothing, bool>
  name: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/pvt/affiliations/{affiliationId}"
    path_params: [{name: affiliationId, var: affiliation_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: configuration, var: configuration}, {name: id, var: id}, {name: implementation, var: implementation}, {name: isConfigured, var: is_configured, required: true}, {name: isdelivered, var: isdelivered, required: true}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    affiliation_id: $affiliation_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, configuration: $configuration, id: $id, implementation: $implementation, is_configured: $is_configured, isdelivered: $isdelivered, name: $name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Installments options
#
# GET /api/pvt/installments
# Returns: record<installments: table<options: list, payment: record>, value: float>
# operationId: Installmentsoptions
export def "installmentsoptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-value: int # required, format: int32, e.g. 10
  --request-sales-channel: int # format: int32, e.g. 1
  --request-payment-details-0-id: int # format: int32, e.g. 2
  --request-payment-details-0-value: int # format: int32, e.g. 10
  --request-payment-details-0-bin: int # format: int32, e.g. 411111
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/pvt/installments"
    query: [{name: "request.value", var: request_value, required: true}, {name: "request.salesChannel", var: request_sales_channel}, {name: "request.paymentDetails[0].id", var: request_payment_details_0_id}, {name: "request.paymentDetails[0].value", var: request_payment_details_0_value}, {name: "request.paymentDetails[0].bin", var: request_payment_details_0_bin}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    request_value: $request_value, request_sales_channel: $request_sales_channel, request_payment_details_0_id: $request_payment_details_0_id, request_payment_details_0_value: $request_payment_details_0_value, request_payment_details_0_bin: $request_payment_details_0_bin, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Available Payment Methods
#
# GET /api/pvt/merchants/payment-systems
# Returns: table<affiliationId: string, allowCommercialCondition: bool, allowCommercialPolicy: bool, allowCountry: bool, allowInstallments: bool, allowIssuer: bool, allowMultiple: bool, allowNotification: bool, allowPeriod: bool, antifraudConnectorImplementation: string, connectorId: int, connectorImplementation: string, description: string, dueDate: string, fields: string, groupName: string, id: int, implementation: string, isAvailable: bool, isCustom: bool, isSelfAuthorized: bool, name: string, requiresDocument: bool, requiresPhone: bool, rules: list<record>, validator: record<cardCodeMask: string, cardCodeRegex: string, mask: string, regex: string, useBillingAddress: bool, useCardHolderName: bool, useCvv: bool, useExpirationDate: bool, validCardLengths: string, weights: list>>
# operationId: AvailablePaymentMethods
export def "available-payment-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/pvt/merchants/payment-systems"
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rules
#
# GET /api/pvt/rules
# operationId: Rules
export def "rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/pvt/rules"
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert Rule
#
# POST /api/pvt/rules
# operationId: InsertRule
export def "insert-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  antifraud: record # e.g. {affiliationId: , implementation: } — shape: {affiliationId: string, implementation: string}
  --begin-date: string # nullable
  --condition: string # nullable
  connector: record # e.g. {affiliationId: e046d326-5421-45ab-95ae-f13d37f260b5, implementation: Vtex.PaymentGateway.Connectors.PromissoryConnector} — shape: {affiliationId: string, implementation: string}
  --country: string # nullable
  --date-intervals: string # nullable
  --enabled: oneof<nothing, bool>
  --end-date: string # nullable
  --installment-options: string # nullable
  --installments-service: string # nullable
  --is-default: oneof<nothing, bool>
  --is-self-authorized: string # nullable
  issuer: record # e.g. {name: } — shape: {name: string}
  --multi-merchant-list: string # nullable
  name: string
  payment_system: record # e.g. {id: 47, implementation: , name: Cash} — shape: {id: int, implementation: string, name: string}
  --requires-authentication: string # nullable
  sales_channels: list # item shape: {id: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pvt/rules"
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: antifraud, var: antifraud}, {name: beginDate, var: begin_date}, {name: condition, var: condition}, {name: connector, var: connector}, {name: country, var: country}, {name: dateIntervals, var: date_intervals}, {name: enabled, var: enabled, required: true}, {name: endDate, var: end_date}, {name: installmentOptions, var: installment_options}, {name: installmentsService, var: installments_service}, {name: isDefault, var: is_default, required: true}, {name: isSelfAuthorized, var: is_self_authorized}, {name: issuer, var: issuer}, {name: multiMerchantList, var: multi_merchant_list}, {name: name, var: name}, {name: paymentSystem, var: payment_system}, {name: requiresAuthentication, var: requires_authentication}, {name: salesChannels, var: sales_channels}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, antifraud: $antifraud, begin_date: $begin_date, condition: $condition, connector: $connector, country: $country, date_intervals: $date_intervals, enabled: $enabled, end_date: $end_date, installment_options: $installment_options, installments_service: $installments_service, is_default: $is_default, is_self_authorized: $is_self_authorized, issuer: $issuer, multi_merchant_list: $multi_merchant_list, name: $name, payment_system: $payment_system, requires_authentication: $requires_authentication, sales_channels: $sales_channels
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Rule
#
# DELETE /api/pvt/rules/{ruleId}
# operationId: Rule
export def "rule" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/pvt/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    rule_id: $rule_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rule By Id
#
# GET /api/pvt/rules/{ruleId}
# operationId: RuleById
export def "rule-by-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/pvt/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    rule_id: $rule_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rule By Id
#
# PUT /api/pvt/rules/{ruleId}
# operationId: PutRuleById
export def "put-rule-by-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  antifraud: record # e.g. {affiliationId: f952588c-8b41-41cc-a06f-c0f48f7320ef} — shape: {affiliationId: string}
  begin_date: string
  --condition: string # nullable
  connector: record # e.g. {affiliationId: e046d326-5421-45ab-95ae-f13d37f260b5, implementation: Vtex.PaymentGateway.Connectors.PromissoryConnector} — shape: {affiliationId: string, implementation: string}
  --country: string # nullable
  --date-intervals: string # nullable
  --enabled: oneof<nothing, bool>
  end_date: string
  id: string
  installment_options: record # e.g. {interestRateMethod: } — shape: {interestRateMethod: string}
  --is-default: string # nullable
  --is-self-authorized: string # nullable
  issuer: record # e.g. {name: } — shape: {name: string}
  --multi-merchant-list: string # nullable
  name: string
  payment_system: record # e.g. {id: 47, implementation: , name: Cash} — shape: {id: int, implementation: string, name: string}
  sales_channels: list # item shape: {id: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/pvt/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}, {name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: antifraud, var: antifraud}, {name: beginDate, var: begin_date}, {name: condition, var: condition}, {name: connector, var: connector}, {name: country, var: country}, {name: dateIntervals, var: date_intervals}, {name: enabled, var: enabled, required: true}, {name: endDate, var: end_date}, {name: id, var: id}, {name: installmentOptions, var: installment_options}, {name: isDefault, var: is_default}, {name: isSelfAuthorized, var: is_self_authorized}, {name: issuer, var: issuer}, {name: multiMerchantList, var: multi_merchant_list}, {name: name, var: name}, {name: paymentSystem, var: payment_system}, {name: salesChannels, var: sales_channels}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    rule_id: $rule_id, hdr_accept: $hdr_accept, content_type: $content_type, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, antifraud: $antifraud, begin_date: $begin_date, condition: $condition, connector: $connector, country: $country, date_intervals: $date_intervals, enabled: $enabled, end_date: $end_date, id: $id, installment_options: $installment_options, is_default: $is_default, is_self_authorized: $is_self_authorized, issuer: $issuer, multi_merchant_list: $multi_merchant_list, name: $name, payment_system: $payment_system, sales_channels: $sales_channels
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 1. Starts a new transaction
#
# POST /api/pvt/transactions
# Returns: record<acceptHeader: string, antifraudAffiliationId: string, antifraudTid: string, authorizationDate: string, authorizationToken: string, buyer: string, cancelationDate: string, cancelationToken: string, cancellations: record<href: string>, channel: string, commitmentDate: string, commitmentToken: string, fields: table<name: string, value: string>, id: string, interactions: record<href: string>, ipAddress: string, markedForRecurrence: bool, owner: string, payments: record<href: string>, receiverUri: string, referenceKey: string, refundingDate: string, refundingToken: string, refunds: record<href: string>, salesChannel: string, settlements: record<href: string>, softDescriptor: string, startDate: string, status: string, timeoutStatus: int, totalRefunds: float, transactionId: string, urn: string, userAgent: string, value: int>
# operationId: 1.Createanewtransaction
export def "1-createanewtransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  channel: string
  reference_id: string
  sales_channel: string
  --urn: string
  value: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/pvt/transactions"
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: channel, var: channel}, {name: referenceId, var: reference_id}, {name: salesChannel, var: sales_channel}, {name: urn, var: urn}, {name: value, var: value}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, channel: $channel, reference_id: $reference_id, sales_channel: $sales_channel, urn: $urn, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transaction Details
#
# GET /api/pvt/transactions/{transactionId}
# Returns: record<acceptHeader: string, antifraudAffiliationId: string, antifraudTid: string, authorizationDate: string, authorizationToken: string, buyer: string, cancelationDate: string, cancelationToken: string, cancellations: record<href: string>, channel: string, commitmentDate: string, commitmentToken: string, fields: table<name: string, value: string>, id: string, interactions: record<href: string>, ipAddress: string, markedForRecurrence: bool, owner: string, payments: record<href: string>, receiverUri: string, referenceKey: string, refundingDate: string, refundingToken: string, refunds: record<href: string>, salesChannel: string, settlements: record<href: string>, softDescriptor: string, startDate: string, status: string, timeoutStatus: int, totalRefunds: float, transactionId: string, urn: string, userAgent: string, value: int>
# operationId: TransactionDetails
export def "transaction-details" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/pvt/transactions/{transactionId}"
    path_params: [{name: transactionId, var: transaction_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 3. Send Additional Data
#
# POST /api/pvt/transactions/{transactionId}/additional-data
# operationId: 3.SendAdditionalData
export def "3-send-additional-data" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --name: string # Type of data that will be added to the transaction.
  --value: string # Data to be added to the transaction.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pvt/transactions/{transactionId}/additional-data"
    path_params: [{name: transactionId, var: transaction_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, name: $name, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Do authorization
#
# POST /api/pvt/transactions/{transactionId}/authorization-request
# operationId: 4.Doauthorization
export def "4-doauthorization" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --prepare-for-recurrency: oneof<nothing, bool>
  soft_descriptor: string
  --body-transaction-id: string # (spec name: transactionId)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pvt/transactions/{transactionId}/authorization-request"
    path_params: [{name: transactionId, var: transaction_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: prepareForRecurrency, var: prepare_for_recurrency, required: true}, {name: softDescriptor, var: soft_descriptor}, {name: transactionId, var: body_transaction_id, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, prepare_for_recurrency: $prepare_for_recurrency, soft_descriptor: $soft_descriptor, body_transaction_id: $body_transaction_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel the transaction
#
# POST /api/pvt/transactions/{transactionId}/cancellation-request
# operationId: Cancelthetransaction
export def "cancelthetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --minicart: record # This field is filled with the content of the cart of the transaction, which can be obtained using [Get Orders](https://developers.vtex.com/vtex-rest-api/reference/orders#getorder) or [Transaction Details](https://developers.vtex.com/vtex-rest-api/reference/transaction-process#transactiondetails) endpoints. It should only be included for transactions with split payment. (default: {minicart: {freight: 200, items: [{discount: 50, id: 122323, name: Tenis Preto I, quantity: 1, shippingDiscount: 0, value: 1000}, {discount: 50, id: 122324, name: Tenis Nike Azul, quantity: 1, shippingDiscount: 0, value: 1100}], tax: 0}, value: 2300}) — shape: {freight?: int, items?: list, tax?: int}
  value: int # Value of the purchase. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pvt/transactions/{transactionId}/cancellation-request"
    path_params: [{name: transactionId, var: transaction_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: minicart, var: minicart}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, minicart: $minicart, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 2.2 Send Payments With Saved Credit Card
#
# POST /api/pvt/transactions/{transactionId}/payments
# operationId: 2.SendPaymentsWithSavedCreditCard
export def "2-send-payments-with-saved-credit-card" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pvt/transactions/{transactionId}/payments"
    path_params: [{name: transactionId, var: transaction_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment Details
#
# GET /api/pvt/transactions/{transactionId}/payments/{paymentId}
# Returns: record<ConnectorResponses: string, ShowConnectorResponses: bool, allowInstallments: bool, allowIssuer: bool, allowNotification: bool, connector: string, connectorResponse: string, currencyCode: string, description: string, fields: table<name: string, value: string>, group: string, id: string, installments: int, installmentsInterestRate: int, installmentsValue: int, isAvailable: bool, isCustom: bool, merchantName: string, paymentSystem: int, paymentSystemName: string, provider: string, referenceValue: int, returnCode: string, returnMessage: string, self: record<href: string>, sheets: string, status: string, tid: string, value: int>
# operationId: PaymentDetails
export def "payment-details" [
  transaction_id: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/pvt/transactions/{transactionId}/payments/{paymentId}"
    path_params: [{name: transactionId, var: transaction_id}, {name: paymentId, var: payment_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, payment_id: $payment_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refund the transaction
#
# POST /api/pvt/transactions/{transactionId}/refunding-request
# operationId: Refundthetransaction
export def "refundthetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --minicart: record # This field is filled with the content of the cart of the transaction, which can be obtained using [Get Orders](https://developers.vtex.com/vtex-rest-api/reference/orders#getorder) or [Transaction Details](https://developers.vtex.com/vtex-rest-api/reference/transaction-process#transactiondetails) endpoints. It should only be included for transactions with split payment. (default: {minicart: {freight: 200, items: [{discount: 50, id: 122323, name: Tenis Preto I, quantity: 1, shippingDiscount: 0, value: 1000}, {discount: 50, id: 122324, name: Tenis Nike Azul, quantity: 1, shippingDiscount: 0, value: 1100}], tax: 0}, value: 2300}) — shape: {freight?: int, items?: list, tax?: int}
  value: int # Value of the purchase. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pvt/transactions/{transactionId}/refunding-request"
    path_params: [{name: transactionId, var: transaction_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: minicart, var: minicart}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, minicart: $minicart, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Settle the transaction
#
# POST /api/pvt/transactions/{transactionId}/settlement-request
# Returns: record<cancelledValue: int, connectorRefundedValue: int, message: string, processingDate: string, refundedToken: string, refundedValue: int, status: int, statusDetail: string, token: string>
# operationId: Settlethetransaction
export def "settlethetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  value: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/pvt/transactions/{transactionId}/settlement-request"
    path_params: [{name: transactionId, var: transaction_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, hdr_accept: $hdr_accept, content_type: $content_type, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transaction Settlement Details
#
# GET /api/pvt/transactions/{transactionId}/settlements
# Returns: record<actions: table<connectorResponse: string, date: string, payment: record, paymentId: string, type: string, value: int>, requests: table<date: string, id: string, value: int>>
# operationId: TransactionSettlementDetails
export def "transaction-settlement-details" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (required, e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/pvt/transactions/{transactionId}/settlements"
    path_params: [{name: transactionId, var: transaction_id}]
    header: [{name: X-PROVIDER-API-AppKey, var: x_provider_api_app_key, required: true}, {name: X-PROVIDER-API-AppToken, var: x_provider_api_app_token, required: true}, {name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PAYMENTS_GATEWAY_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PAYMENTS_GATEWAY_API_APPTOKEN_TOKEN}]
  } {
    transaction_id: $transaction_id, x_provider_api_app_key: $x_provider_api_app_key, x_provider_api_app_token: $x_provider_api_app_token, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
