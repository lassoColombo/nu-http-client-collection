# Auto-generated client for Logistics API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Logistics-API/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.LOGISTICS_API_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.LOGISTICS_API_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "LOGISTICS_API_TOKEN"
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let return_types = {
    all-docks: "table<dockTimeFake: string, freightTableIds: list<string>, id: string, name: string, pickupStoreInfo: record<additionalInfo: string, address: string, dockId: string, friendlyName: string, isPickupStore: bool, storeId: string>, priority: int, salesChannel: string, salesChannels: list<string>, timeFakeOverhead: string, wmsEndPoint: string>"
    dock-by-id: "record<dockTimeFake: string, freightTableIds: list<string>, id: string, name: string, pickupStoreInfo: record<additionalInfo: string, address: string, dockId: string, friendlyName: string, isPickupStore: bool, storeId: string>, priority: int, salesChannel: string, salesChannels: list<string>, timeFakeOverhead: string, wmsEndPoint: string>"
    freight-values: "table<absoluteMoneyCost: float, country: string, maxVolume: float, minimumValueInsurance: float, operationType: int, polygon: string, pricePercent: float, pricePercentByWeight: float, restrictedFreights: list<string>, timeCost: string, weightEnd: float, weightStart: float, zipCodeEnd: string, zipCodeStart: string>"
    list-all-pickup-ppoints: "table<accountGroupId: string, accountOwnerId: string, accountOwnerName: string, address: record<city: string, complement: string, country: record, location: record, neighborhood: string, number: string, postalCode: string, state: string, street: string>, businessHours: list<record>, description: string, distance: float, formatted_address: string, id: string, instructions: string, isActive: bool, isThirdPartyPickup: bool, name: string, originalId: string, parentAccountName: string, pickupHolidays: list<string>, seller: string, tagsLabel: list<string>>"
    get-by-id: "record<address: record<city: string, complement: string, country: record<acronym: string, name: string>, location: record<latitude: float, longitude: float>, neighborhood: string, number: string, postalCode: string, state: string, street: string>, businessHours: table<closingTime: string, dayOfWeek: int, openingTime: string>, description: string, formatted_address: string, id: string, instructions: string, isActive: bool, name: string, warehouseId: string>"
    create-update-pickup-point: "record<address: record<city: string, complement: string, country: record<acronym: string, name: string>, location: record<latitude: float, longitude: float>, neighborhood: string, number: string, postalCode: string, reference: string, state: string, street: string>, businessHours: table<closingTime: string, dayOfWeek: int, openingTime: string>, description: string, formatted_address: string, id: string, instructions: string, isActive: bool, name: string, pickupHolidays: list<string>, tagsLabel: list<string>>"
    all-warehouses: "table<id: string, isActive: bool, name: string, pickupPointIds: list<any>, priority: int, warehouseDocks: list<record>>"
    warehouse-by-id: "record<id: string, isActive: bool, name: string, pickupPointIds: list<any>, priority: int, warehouseDocks: table<cost: float, dockId: string, time: string>>"
    getinventorywithdispatchedreservations: "table<availableQuantity: int, dispatchedReservationsQuantity: int, isUnlimitedQuantity: bool, quantity: int, skuId: string, totalReservedQuantity: int, warehouseId: string>"
    inventoryperdock: "table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string>"
    inventoryperdockandwarehouse: "table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string>"
    inventoryperwarehouse: "table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string>"
    create-reservation: "record<AuthorizedDateUtc: string, CanceledDateUtc: string, ConfirmedDateUtc: string, Errors: list<string>, IsSucess: bool, LastUpdateDateUtc: string, LockId: string, MaximumConfirmationDateUtc: string, PickupPointItemOptions: string, ReservationDateUtc: string, SalesChannel: string, SlaRequest: table<deliveryWindows: string, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, item: record, listPrice: float, location: record, pickupStoreInfo: string, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string, wmsEndPoint: string>, Status: int>"
    reservation-by-id: "record<AuthorizedDateUtc: string, CanceledDateUtc: string, ConfirmedDateUtc: string, Errors: list<string>, IsSucess: bool, LastUpdateDateUtc: string, LockId: string, MaximumConfirmationDateUtc: string, PickupPointItemOptions: string, ReservationDateUtc: string, SalesChannel: string, SlaRequest: table<deliveryWindows: string, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, item: record, listPrice: float, location: record, pickupStoreInfo: string, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string, wmsEndPoint: string>, Status: int>"
    inventory-by-sku: "record<balance: table<hasUnlimitedQuantity: bool, reservedQuantity: int, totalQuantity: int, warehouseId: string, warehouseName: string>, skuId: string>"
    calculate-sla: "list<table<aditionalTimeBlockedDays: string, availabilityQuantity: int, carrierSchedule: list, coordinates: string, deliveryOnWeekends: bool, deliveryWindows: list, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, itemId: string, listPrice: float, location: record, pickupStoreInfo: string, quantity: int, restrictedFreight: string, salesChannel: string, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-logistics-capacity-resources-carrier-capacity-type-shipping-policy-id-time-frames" "get-api-logistics-capacity-resources-carrier-capacity-type-shipping-policy-id-time-frames-window-day-f-window-start-time-t-window-end-time" "add-blocked-delivery-windows" "retrieve-blocked-delivery-windows" "remove-blocked-delivery-windows" "all-docks" "create-update-dock" "dock" "dock-by-id" "activate-dock" "deactivate-dock" "create-update-freight-values" "freight-values" "paged-polygons" "create-update-polygon" "delete-polygon" "polygonby-id" "all-holidays" "holiday" "holiday-by-id" "create-update-holiday" "list-all-pickup-ppoints" "getpaged" "delete" "get-by-id" "create-update-pickup-point" "all-warehouses" "create-update-warehouse" "remove-warehouse" "warehouse-by-id" "activate-warehouse" "deactivate-warehouse" "getinventorywithdispatchedreservations" "inventoryperdock" "inventoryperdockandwarehouse" "inventoryperwarehouse" "get-supply-lots" "save-supply-lot" "transfer-supply-lot" "create-reservation" "reservation-by-id" "acknowledgment-reservation" "cancel-reservation" "confirm-reservation" "reservationby-warehouseand-sku" "inventory-by-sku" "update-inventory-by-skuand-warehouse" "get-api-logistics-pvt-shipping-policies" "post-api-logistics-pvt-shipping-policies" "delete-api-logistics-pvt-shipping-policies-id" "get-api-logistics-pvt-shipping-policies-id" "put-api-logistics-pvt-shipping-policies-id" "calculate-sla" "commands"] | sort) } | get name | first)
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

# Search capacity reservations in time range
#
# GET /api/logistics-capacity/resources/carrier@{capacityType}@{shippingPolicyId}/time-frames
export def "get-api-logistics-capacity-resources-carrier-capacity-type-shipping-policy-id-time-frames" [
  capacity_type: string
  shipping_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --range-start: string # Starting date of time range (required, e.g. yyyy-mm-dd)
  --range-end: string # End date of time range. (required, e.g. yyyy-mm-dd)
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, e.g. application/vnd.vtex.availability.v1+json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics-capacity/resources/carrier@{capacityType}@{shippingPolicyId}/time-frames"
    path_params: [{name: capacityType, var: capacity_type}, {name: shippingPolicyId, var: shipping_policy_id}]
    query: [{name: rangeStart, var: range_start, required: true}, {name: rangeEnd, var: range_end, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    capacity_type: $capacity_type, shipping_policy_id: $shipping_policy_id, range_start: $range_start, range_end: $range_end, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get capacity reservation usage by window
#
# GET /api/logistics-capacity/resources/carrier@{capacityType}@{shippingPolicyId}/time-frames/{windowDay}F{windowStartTime}T{windowEndTime}
export def "get-api-logistics-capacity-resources-carrier-capacity-type-shipping-policy-id-time-frames-window-day-f-window-start-time-t-window-end-time" [
  capacity_type: string
  shipping_policy_id: string
  window_day: string
  window_start_time: string
  window_end_time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, e.g. application/vnd.vtex.availability.v1+json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics-capacity/resources/carrier@{capacityType}@{shippingPolicyId}/time-frames/{windowDay}F{windowStartTime}T{windowEndTime}"
    path_params: [{name: capacityType, var: capacity_type}, {name: shippingPolicyId, var: shipping_policy_id}, {name: windowDay, var: window_day}, {name: windowStartTime, var: window_start_time}, {name: windowEndTime, var: window_end_time}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    capacity_type: $capacity_type, shipping_policy_id: $shipping_policy_id, window_day: $window_day, window_start_time: $window_start_time, window_end_time: $window_end_time, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add blocked delivery windows
#
# POST /api/logistics/pvt/configuration/carriers/{carrierId}/adddayofweekblocked
# operationId: AddBlockedDeliveryWindows
export def "add-blocked-delivery-windows" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/logistics/pvt/configuration/carriers/{carrierId}/adddayofweekblocked"
    path_params: [{name: carrierId, var: carrier_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    carrier_id: $carrier_id, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve blocked delivery windows
#
# GET /api/logistics/pvt/configuration/carriers/{carrierId}/getdayofweekblocked
# operationId: RetrieveBlockedDeliveryWindows
export def "retrieve-blocked-delivery-windows" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/carriers/{carrierId}/getdayofweekblocked"
    path_params: [{name: carrierId, var: carrier_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    carrier_id: $carrier_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove blocked delivery windows
#
# POST /api/logistics/pvt/configuration/carriers/{carrierId}/removedayofweekblocked
# operationId: RemoveBlockedDeliveryWindows
export def "remove-blocked-delivery-windows" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/logistics/pvt/configuration/carriers/{carrierId}/removedayofweekblocked"
    path_params: [{name: carrierId, var: carrier_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    carrier_id: $carrier_id, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all docks
#
# GET /api/logistics/pvt/configuration/docks
# Returns: table<dockTimeFake: string, freightTableIds: list<string>, id: string, name: string, pickupStoreInfo: record<additionalInfo: string, address: string, dockId: string, friendlyName: string, isPickupStore: bool, storeId: string>, priority: int, salesChannel: string, salesChannels: list<string>, timeFakeOverhead: string, wmsEndPoint: string>
# operationId: AllDocks
export def "all-docks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/docks"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/update dock
#
# POST /api/logistics/pvt/configuration/docks
# operationId: Create/UpdateDock
export def "create-update-dock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  address: record # e.g. {city: Rio de Janeiro, complement: , coordinates: [[-43.18228090000002, -22.9460398]], country: {acronym: BRA, name: Brazil}, neighborhood: Catete, number: 100, postalCode: 22220070, state: RJ, street: Artur Bernardes Street} — shape: {city: string, complement: string, coordinates: list, country: record, neighborhood: string, number: string, postalCode: string, state: string, street: string}
  dock_time_fake: string
  freight_table_ids: list<string>
  id: string
  name: string
  priority: int # format: int32
  --sales-channel: string # nullable
  sales_channels: list<string>
  time_fake_overhead: string
  wms_end_point: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/logistics/pvt/configuration/docks"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: address, var: address}, {name: dockTimeFake, var: dock_time_fake}, {name: freightTableIds, var: freight_table_ids}, {name: id, var: id}, {name: name, var: name}, {name: priority, var: priority}, {name: salesChannel, var: sales_channel}, {name: salesChannels, var: sales_channels}, {name: timeFakeOverhead, var: time_fake_overhead}, {name: wmsEndPoint, var: wms_end_point}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, address: $address, dock_time_fake: $dock_time_fake, freight_table_ids: $freight_table_ids, id: $id, name: $name, priority: $priority, sales_channel: $sales_channel, sales_channels: $sales_channels, time_fake_overhead: $time_fake_overhead, wms_end_point: $wms_end_point
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete dock
#
# DELETE /api/logistics/pvt/configuration/docks/{dockId}
# operationId: Dock
export def "dock" [
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/logistics/pvt/configuration/docks/{dockId}"
    path_params: [{name: dockId, var: dock_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    dock_id: $dock_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List dock by ID
#
# GET /api/logistics/pvt/configuration/docks/{dockId}
# Returns: record<dockTimeFake: string, freightTableIds: list<string>, id: string, name: string, pickupStoreInfo: record<additionalInfo: string, address: string, dockId: string, friendlyName: string, isPickupStore: bool, storeId: string>, priority: int, salesChannel: string, salesChannels: list<string>, timeFakeOverhead: string, wmsEndPoint: string>
# operationId: DockById
export def "dock-by-id" [
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/docks/{dockId}"
    path_params: [{name: dockId, var: dock_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    dock_id: $dock_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate dock
#
# POST /api/logistics/pvt/configuration/docks/{dockId}/activation
# operationId: ActivateDock
export def "activate-dock" [
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/logistics/pvt/configuration/docks/{dockId}/activation"
    path_params: [{name: dockId, var: dock_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    dock_id: $dock_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate dock
#
# POST /api/logistics/pvt/configuration/docks/{dockId}/deactivation
# operationId: DeactivateDock
export def "deactivate-dock" [
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/logistics/pvt/configuration/docks/{dockId}/deactivation"
    path_params: [{name: dockId, var: dock_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    dock_id: $dock_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/update freight values
#
# POST /api/logistics/pvt/configuration/freights/{carrierId}/values/update
# operationId: Create/UpdateFreightValues
export def "create-update-freight-values" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/logistics/pvt/configuration/freights/{carrierId}/values/update"
    path_params: [{name: carrierId, var: carrier_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    carrier_id: $carrier_id, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List freight values
#
# GET /api/logistics/pvt/configuration/freights/{carrierId}/{cep}/values
# Returns: table<absoluteMoneyCost: float, country: string, maxVolume: float, minimumValueInsurance: float, operationType: int, polygon: string, pricePercent: float, pricePercentByWeight: float, restrictedFreights: list<string>, timeCost: string, weightEnd: float, weightStart: float, zipCodeEnd: string, zipCodeStart: string>
# operationId: FreightValues
export def "freight-values" [
  carrier_id: string
  cep: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/freights/{carrierId}/{cep}/values"
    path_params: [{name: carrierId, var: carrier_id}, {name: cep, var: cep}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    carrier_id: $carrier_id, cep: $cep, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List paged polygons
#
# GET /api/logistics/pvt/configuration/geoshape
# operationId: PagedPolygons
export def "paged-polygons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # required, e.g. {{page}}
  --per-page: string # required, e.g. {{perPage}}
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/geoshape"
    query: [{name: page, var: page, required: true}, {name: perPage, var: per_page, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    page: $page, per_page: $per_page, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/update polygon
#
# PUT /api/logistics/pvt/configuration/geoshape
# operationId: CreateUpdatePolygon
export def "create-update-polygon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  geo_shape: record # shape: {coordinates: list}
  name: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/logistics/pvt/configuration/geoshape"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: geoShape, var: geo_shape}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, geo_shape: $geo_shape, name: $name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete polygon
#
# DELETE /api/logistics/pvt/configuration/geoshape/{polygonName}
# operationId: DeletePolygon
export def "delete-polygon" [
  polygon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/logistics/pvt/configuration/geoshape/{polygonName}"
    path_params: [{name: polygonName, var: polygon_name}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    polygon_name: $polygon_name, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List polygon by ID
#
# GET /api/logistics/pvt/configuration/geoshape/{polygonName}
# operationId: PolygonbyId
export def "polygonby-id" [
  polygon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/geoshape/{polygonName}"
    path_params: [{name: polygonName, var: polygon_name}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    polygon_name: $polygon_name, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all holidays
#
# GET /api/logistics/pvt/configuration/holidays
# operationId: AllHolidays
export def "all-holidays" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/holidays"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete holiday
#
# DELETE /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: Holiday
export def "holiday" [
  holiday_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/logistics/pvt/configuration/holidays/{holidayId}"
    path_params: [{name: holidayId, var: holiday_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    holiday_id: $holiday_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List holiday by ID
#
# GET /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: HolidayById
export def "holiday-by-id" [
  holiday_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/holidays/{holidayId}"
    path_params: [{name: holidayId, var: holiday_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    holiday_id: $holiday_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/update holiday
#
# PUT /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: Create/UpdateHoliday
export def "create-update-holiday" [
  holiday_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  name: string
  start_date: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/logistics/pvt/configuration/holidays/{holidayId}"
    path_params: [{name: holidayId, var: holiday_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: name, var: name}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    holiday_id: $holiday_id, hdr_accept: $hdr_accept, content_type: $content_type, name: $name, start_date: $start_date
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all pickup points
#
# GET /api/logistics/pvt/configuration/pickuppoints
# Returns: table<accountGroupId: string, accountOwnerId: string, accountOwnerName: string, address: record<city: string, complement: string, country: record, location: record, neighborhood: string, number: string, postalCode: string, state: string, street: string>, businessHours: list<record>, description: string, distance: float, formatted_address: string, id: string, instructions: string, isActive: bool, isThirdPartyPickup: bool, name: string, originalId: string, parentAccountName: string, pickupHolidays: list<string>, seller: string, tagsLabel: list<string>>
# operationId: ListAllPickupPpoints
export def "list-all-pickup-ppoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/pickuppoints"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List paged Pickup Points
#
# GET /api/logistics/pvt/configuration/pickuppoints/_search
# operationId: Getpaged
export def "getpaged" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # required, e.g. {{pageNumber}}
  --page-size: string # required, e.g. {{pageSize}}
  --keyword: string # required, e.g. 
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/pickuppoints/_search"
    query: [{name: page, var: page, required: true}, {name: pageSize, var: page_size, required: true}, {name: keyword, var: keyword, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    page: $page, page_size: $page_size, keyword: $keyword, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Pickup Point
#
# DELETE /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# operationId: Delete
export def "delete" [
  pickup_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/logistics/pvt/configuration/pickuppoints/{pickupPointId}"
    path_params: [{name: pickupPointId, var: pickup_point_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    pickup_point_id: $pickup_point_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Pickup Point By ID
#
# GET /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# Returns: record<address: record<city: string, complement: string, country: record<acronym: string, name: string>, location: record<latitude: float, longitude: float>, neighborhood: string, number: string, postalCode: string, state: string, street: string>, businessHours: table<closingTime: string, dayOfWeek: int, openingTime: string>, description: string, formatted_address: string, id: string, instructions: string, isActive: bool, name: string, warehouseId: string>
# operationId: GetById
export def "get-by-id" [
  pickup_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/pickuppoints/{pickupPointId}"
    path_params: [{name: pickupPointId, var: pickup_point_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    pickup_point_id: $pickup_point_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/Update Pickup Point
#
# PUT /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# Returns: record<address: record<city: string, complement: string, country: record<acronym: string, name: string>, location: record<latitude: float, longitude: float>, neighborhood: string, number: string, postalCode: string, reference: string, state: string, street: string>, businessHours: table<closingTime: string, dayOfWeek: int, openingTime: string>, description: string, formatted_address: string, id: string, instructions: string, isActive: bool, name: string, pickupHolidays: list<string>, tagsLabel: list<string>>
# operationId: CreateUpdatePickupPoint
export def "create-update-pickup-point" [
  pickup_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  address: record # e.g. {city: Rio de Janeiro, complement: , country: {acronym: BRA, name: Brazil}, location: {latitude: -22.974477767944336, longitude: -43.18672561645508}, neighborhood: Copacabana, number: , postalCode: 22070002, reference: Grey building, state: RJ, street: Avenida Atl├óntica} — shape: {city: string, complement: string, country: record, location: record, neighborhood: string, number: string, postalCode: string, reference: string, state: string, street: string}
  business_hours: list # item shape: {closingTime: string, dayOfWeek: int, openingTime: string}
  description: string # Pickup point description. (e.g. Pickup your items in our store.)
  formatted_address: string # Formated address.
  id: string # Pickup Point ID. Cannot contain spaces. (e.g. 123456789)
  instructions: string # Pickup point instructions. (e.g. Bring your ID in order to pickup your order.)
  --is-active: oneof<nothing, bool>
  --is-third-party-pickup: oneof<nothing, bool>
  name: string # Pickup point name. (e.g. Pickup store.)
  tags_label: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/logistics/pvt/configuration/pickuppoints/{pickupPointId}"
    path_params: [{name: pickupPointId, var: pickup_point_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: address, var: address}, {name: businessHours, var: business_hours}, {name: description, var: description}, {name: formatted_address, var: formatted_address}, {name: id, var: id}, {name: instructions, var: instructions}, {name: isActive, var: is_active, required: true}, {name: isThirdPartyPickup, var: is_third_party_pickup}, {name: name, var: name}, {name: tagsLabel, var: tags_label}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    pickup_point_id: $pickup_point_id, content_type: $content_type, hdr_accept: $hdr_accept, address: $address, business_hours: $business_hours, description: $description, formatted_address: $formatted_address, id: $id, instructions: $instructions, is_active: $is_active, is_third_party_pickup: $is_third_party_pickup, name: $name, tags_label: $tags_label
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all warehouses
#
# GET /api/logistics/pvt/configuration/warehouses
# Returns: table<id: string, isActive: bool, name: string, pickupPointIds: list<any>, priority: int, warehouseDocks: list<record>>
# operationId: AllWarehouses
export def "all-warehouses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/warehouses"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/update warehouse
#
# POST /api/logistics/pvt/configuration/warehouses
# operationId: Create/UpdateWarehouse
export def "create-update-warehouse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  id: string
  name: string
  warehouse_docks: list # item shape: {cost: string, costToDisplay: string, dockId: string, name: string, time: string, translateDays: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/logistics/pvt/configuration/warehouses"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: warehouseDocks, var: warehouse_docks}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type, id: $id, name: $name, warehouse_docks: $warehouse_docks
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove warehouse
#
# DELETE /api/logistics/pvt/configuration/warehouses/{warehouseId}
# operationId: RemoveWarehouse
export def "remove-warehouse" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/logistics/pvt/configuration/warehouses/{warehouseId}"
    path_params: [{name: warehouseId, var: warehouse_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    warehouse_id: $warehouse_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List warehouse by ID
#
# GET /api/logistics/pvt/configuration/warehouses/{warehouseId}
# Returns: record<id: string, isActive: bool, name: string, pickupPointIds: list<any>, priority: int, warehouseDocks: table<cost: float, dockId: string, time: string>>
# operationId: WarehouseById
export def "warehouse-by-id" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/configuration/warehouses/{warehouseId}"
    path_params: [{name: warehouseId, var: warehouse_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    warehouse_id: $warehouse_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate warehouse
#
# POST /api/logistics/pvt/configuration/warehouses/{warehouseId}/activation
# operationId: ActivateWarehouse
export def "activate-warehouse" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/logistics/pvt/configuration/warehouses/{warehouseId}/activation"
    path_params: [{name: warehouseId, var: warehouse_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    warehouse_id: $warehouse_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate warehouse
#
# POST /api/logistics/pvt/configuration/warehouses/{warehouseId}/deactivation
# operationId: DeactivateWarehouse
export def "deactivate-warehouse" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/logistics/pvt/configuration/warehouses/{warehouseId}/deactivation"
    path_params: [{name: warehouseId, var: warehouse_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    warehouse_id: $warehouse_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List inventory with dispatched reservations
#
# GET /api/logistics/pvt/inventory/items/{itemId}/warehouses/{warehouseId}/dispatched
# Returns: table<availableQuantity: int, dispatchedReservationsQuantity: int, isUnlimitedQuantity: bool, quantity: int, skuId: string, totalReservedQuantity: int, warehouseId: string>
# operationId: Getinventorywithdispatchedreservations
export def "getinventorywithdispatchedreservations" [
  item_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/inventory/items/{itemId}/warehouses/{warehouseId}/dispatched"
    path_params: [{name: itemId, var: item_id}, {name: warehouseId, var: warehouse_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    item_id: $item_id, warehouse_id: $warehouse_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List inventory per dock
#
# GET /api/logistics/pvt/inventory/items/{skuId}/docks/{dockId}
# Returns: table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string>
# operationId: Inventoryperdock
export def "inventoryperdock" [
  sku_id: string
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/inventory/items/{skuId}/docks/{dockId}"
    path_params: [{name: skuId, var: sku_id}, {name: dockId, var: dock_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, dock_id: $dock_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List inventory per dock and warehouse
#
# GET /api/logistics/pvt/inventory/items/{skuId}/docks/{dockId}/warehouses/{warehouseId}
# Returns: table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string>
# operationId: Inventoryperdockandwarehouse
export def "inventoryperdockandwarehouse" [
  sku_id: string
  dock_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/inventory/items/{skuId}/docks/{dockId}/warehouses/{warehouseId}"
    path_params: [{name: skuId, var: sku_id}, {name: dockId, var: dock_id}, {name: warehouseId, var: warehouse_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, dock_id: $dock_id, warehouse_id: $warehouse_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List inventory per warehouse
#
# GET /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}
# Returns: table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string>
# operationId: Inventoryperwarehouse
export def "inventoryperwarehouse" [
  sku_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}"
    path_params: [{name: skuId, var: sku_id}, {name: warehouseId, var: warehouse_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, warehouse_id: $warehouse_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List supply lots
#
# GET /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots
# operationId: GetSupplyLots
export def "get-supply-lots" [
  sku_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, e.g. application/json; charset=utf-8)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots"
    path_params: [{name: skuId, var: sku_id}, {name: warehouseId, var: warehouse_id}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, warehouse_id: $warehouse_id, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save supply lot
#
# PUT /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots/{supplyLotId}
# operationId: SaveSupplyLot
export def "save-supply-lot" [
  sku_id: string
  warehouse_id: string
  supply_lot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  date_of_supply_utc: string
  --keep-selling-after-expiration: oneof<nothing, bool>
  quantity: float
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots/{supplyLotId}"
    path_params: [{name: skuId, var: sku_id}, {name: warehouseId, var: warehouse_id}, {name: supplyLotId, var: supply_lot_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: dateOfSupplyUtc, var: date_of_supply_utc}, {name: keepSellingAfterExpiration, var: keep_selling_after_expiration, required: true}, {name: quantity, var: quantity}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, warehouse_id: $warehouse_id, supply_lot_id: $supply_lot_id, hdr_accept: $hdr_accept, content_type: $content_type, date_of_supply_utc: $date_of_supply_utc, keep_selling_after_expiration: $keep_selling_after_expiration, quantity: $quantity
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer supply lot
#
# POST /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots/{supplyLotId}/transfer
# operationId: TransferSupplyLot
export def "transfer-supply-lot" [
  sku_id: string
  warehouse_id: string
  supply_lot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots/{supplyLotId}/transfer"
    path_params: [{name: skuId, var: sku_id}, {name: warehouseId, var: warehouse_id}, {name: supplyLotId, var: supply_lot_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, warehouse_id: $warehouse_id, supply_lot_id: $supply_lot_id, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create reservation
#
# POST /api/logistics/pvt/inventory/reservations
# Returns: record<AuthorizedDateUtc: string, CanceledDateUtc: string, ConfirmedDateUtc: string, Errors: list<string>, IsSucess: bool, LastUpdateDateUtc: string, LockId: string, MaximumConfirmationDateUtc: string, PickupPointItemOptions: string, ReservationDateUtc: string, SalesChannel: string, SlaRequest: table<deliveryWindows: string, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, item: record, listPrice: float, location: record, pickupStoreInfo: string, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string, wmsEndPoint: string>, Status: int>
# operationId: CreateReservation
export def "create-reservation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json; charset=utf-8)
  autorization_expiration_ttl: string
  delivery_item_options: list # item shape: {aditionalTimeBlockedDays: string, deliveryWindows: list<string>, dockId: string, dockTime: string, item: record, listPrice: float, location: record, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string}
  --lock-id: string # nullable
  sales_channel: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/logistics/pvt/inventory/reservations"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: autorizationExpirationTTL, var: autorization_expiration_ttl}, {name: deliveryItemOptions, var: delivery_item_options}, {name: lockId, var: lock_id}, {name: salesChannel, var: sales_channel}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type, autorization_expiration_ttl: $autorization_expiration_ttl, delivery_item_options: $delivery_item_options, lock_id: $lock_id, sales_channel: $sales_channel
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List reservation by ID
#
# GET /api/logistics/pvt/inventory/reservations/{reservationId}
# Returns: record<AuthorizedDateUtc: string, CanceledDateUtc: string, ConfirmedDateUtc: string, Errors: list<string>, IsSucess: bool, LastUpdateDateUtc: string, LockId: string, MaximumConfirmationDateUtc: string, PickupPointItemOptions: string, ReservationDateUtc: string, SalesChannel: string, SlaRequest: table<deliveryWindows: string, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, item: record, listPrice: float, location: record, pickupStoreInfo: string, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string, wmsEndPoint: string>, Status: int>
# operationId: ReservationById
export def "reservation-by-id" [
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/inventory/reservations/{reservationId}"
    path_params: [{name: reservationId, var: reservation_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    reservation_id: $reservation_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Acknowledgment reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/acknowledge
# operationId: AcknowledgmentReservation
export def "acknowledgment-reservation" [
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/logistics/pvt/inventory/reservations/{reservationId}/acknowledge"
    path_params: [{name: reservationId, var: reservation_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    reservation_id: $reservation_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/cancel
# operationId: CancelReservation
export def "cancel-reservation" [
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/logistics/pvt/inventory/reservations/{reservationId}/cancel"
    path_params: [{name: reservationId, var: reservation_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    reservation_id: $reservation_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/confirm
# operationId: ConfirmReservation
export def "confirm-reservation" [
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/logistics/pvt/inventory/reservations/{reservationId}/confirm"
    path_params: [{name: reservationId, var: reservation_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    reservation_id: $reservation_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List reservation by warehouse and SKU
#
# GET /api/logistics/pvt/inventory/reservations/{warehouseId}/{skuId}
# operationId: ReservationbyWarehouseandSku
export def "reservationby-warehouseand-sku" [
  warehouse_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/inventory/reservations/{warehouseId}/{skuId}"
    path_params: [{name: warehouseId, var: warehouse_id}, {name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    warehouse_id: $warehouse_id, sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List inventory by SKU
#
# GET /api/logistics/pvt/inventory/skus/{skuId}
# Returns: record<balance: table<hasUnlimitedQuantity: bool, reservedQuantity: int, totalQuantity: int, warehouseId: string, warehouseName: string>, skuId: string>
# operationId: InventoryBySku
export def "inventory-by-sku" [
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/logistics/pvt/inventory/skus/{skuId}"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update inventory by SKU and warehouse
#
# PUT /api/logistics/pvt/inventory/skus/{skuId}/warehouses/{warehouseId}
# operationId: UpdateInventoryBySkuandWarehouse
export def "update-inventory-by-skuand-warehouse" [
  sku_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json; charset=utf-8)
  --date-utc-on-balance-system: string # Defines the corresponding moment to the informed warehouse. It is useful due to the liberation of handling order reservations. When requested as `null`, this value will be the date/time of the request. Its format is `DateTimeOffset`, as in `yyyy-mm-dd-Thh:mm:ss`. For example: `2022-03-15T00:52:16`. (e.g. null)
  quantity: int # format: int32
  time_to_refill_deprecated: string
  --unlimited-quantity: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/logistics/pvt/inventory/skus/{skuId}/warehouses/{warehouseId}"
    path_params: [{name: skuId, var: sku_id}, {name: warehouseId, var: warehouse_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: dateUtcOnBalanceSystem, var: date_utc_on_balance_system}, {name: quantity, var: quantity}, {name: "timeToRefill (deprecated)", var: time_to_refill_deprecated}, {name: unlimitedQuantity, var: unlimited_quantity, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, warehouse_id: $warehouse_id, hdr_accept: $hdr_accept, content_type: $content_type, date_utc_on_balance_system: $date_utc_on_balance_system, quantity: $quantity, time_to_refill_deprecated: $time_to_refill_deprecated, unlimited_quantity: $unlimited_quantity
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List shipping policies
#
# GET /api/logistics/pvt/shipping-policies
export def "get-api-logistics-pvt-shipping-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Desired number of pages to retrieve information from your Shipping Policies. (required, e.g. page)
  --per-page: string # Desired number of items per page, to retrieve information from your Shipping Policies. (required, e.g. perPage)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/shipping-policies"
    query: [{name: page, var: page, required: true}, {name: perPage, var: per_page, required: true}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    page: $page, per_page: $per_page, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create shipping policy
#
# POST /api/logistics/pvt/shipping-policies
export def "post-api-logistics-pvt-shipping-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json)
  business_hour_settings: record # Business hour configuration. (e.g. {carrierBusinessHours: [{closingTime: 18:59:59, dayOfWeek: 0, openingTime: 09:00:00}], isOpenOutsideBusinessHours: true}) — shape: {carrierBusinessHours: list, isOpenOutsideBusinessHours: bool}
  --carrier-schedule: list # Schedule sent by the carrier, to configure Shipping policy — item shape: {dayOfWeek?: int, timeLimit?: string}
  cubic_weight_settings: record # Measure that accounts package's volume, and not only weight. (e.g. {minimunAcceptableVolumetricWeight: 5, volumetricFactor: 3}) — shape: {minimunAcceptableVolumetricWeight: float, volumetricFactor: float}
  delivery_schedule_settings: record # Settings for the Scheduled Delivery feature. (e.g. {dayOfWeekForDelivery: [{dayOfWeek: 2, deliveryRanges: [{endTime: 12:00:00, listPrice: 5, startTime: 08:00:00}, {endTime: 18:00:00, listPrice: 10, startTime: 12:01:00}]}], maxRangeDelivery: 5, useDeliverySchedule: true}) — shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
  id: string # ID of the shipping policy. (e.g. 123)
  --is-active: oneof<nothing, bool> # Indicates whether shipping policy is active or not. (e.g. false)
  max_dimension: record # Object containing attributes of maximum dimension permitted by the shipping policy (carrier). (e.g. {largestMeasure: 15, maxMeasureSum: 25}) — shape: {largestMeasure: float, maxMeasureSum: float}
  maximum_value_aceptable: float # Maximum value accepted by the carrier, to realize the shipping. (e.g. 0)
  minimum_value_aceptable: float # Minimum value accepted by the carrier, to realize the shipping. (e.g. 0)
  modal_settings: record # Configurations for the [modal](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125), which is the attachement of a specific product to a carrier specialized in delivering that type of product. (e.g. {modals: [Modal1], useOnlyItemsWithDefinedModal: false}) — shape: {modals: list, useOnlyItemsWithDefinedModal: bool}
  name: string # Name of the shipping policy. (e.g. Normal)
  number_of_items_per_shipment: int # Capacity of your store's logistics of shipment, determines number of items permitted per shipment. (e.g. 5)
  pickup_points_settings: record # Configuration for Pickup Points. (e.g. {pickupPointIds: [null], pickupPointTags: [null], sellers: [cosmetics2]}) — shape: {pickupPointIds: list, pickupPointTags: list, sellers: list}
  shipping_method: string # Type of shipping available for this shipping policy (carrier). Options shown on freight simulation (e.g. Normal)
  weekend_and_holidays: record # If the shipping policy includes deliveries on weekends and holidays. (e.g. {holiday: false, saturday: false, sunday: false}) — shape: {holiday: bool, saturday: bool, sunday: bool}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/logistics/pvt/shipping-policies"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: businessHourSettings, var: business_hour_settings}, {name: carrierSchedule, var: carrier_schedule}, {name: cubicWeightSettings, var: cubic_weight_settings}, {name: deliveryScheduleSettings, var: delivery_schedule_settings}, {name: id, var: id}, {name: isActive, var: is_active, required: true}, {name: maxDimension, var: max_dimension}, {name: maximumValueAceptable, var: maximum_value_aceptable}, {name: minimumValueAceptable, var: minimum_value_aceptable}, {name: modalSettings, var: modal_settings}, {name: name, var: name}, {name: numberOfItemsPerShipment, var: number_of_items_per_shipment}, {name: pickupPointsSettings, var: pickup_points_settings}, {name: shippingMethod, var: shipping_method}, {name: weekendAndHolidays, var: weekend_and_holidays}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type, business_hour_settings: $business_hour_settings, carrier_schedule: $carrier_schedule, cubic_weight_settings: $cubic_weight_settings, delivery_schedule_settings: $delivery_schedule_settings, id: $id, is_active: $is_active, max_dimension: $max_dimension, maximum_value_aceptable: $maximum_value_aceptable, minimum_value_aceptable: $minimum_value_aceptable, modal_settings: $modal_settings, name: $name, number_of_items_per_shipment: $number_of_items_per_shipment, pickup_points_settings: $pickup_points_settings, shipping_method: $shipping_method, weekend_and_holidays: $weekend_and_holidays
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete shipping policies by ID
#
# DELETE /api/logistics/pvt/shipping-policies/{id}
export def "delete-api-logistics-pvt-shipping-policies-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/logistics/pvt/shipping-policies/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    id: $id, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve shipping policy by ID
#
# GET /api/logistics/pvt/shipping-policies/{id}
export def "get-api-logistics-pvt-shipping-policies-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/logistics/pvt/shipping-policies/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    id: $id, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update shipping policy
#
# PUT /api/logistics/pvt/shipping-policies/{id}
export def "put-api-logistics-pvt-shipping-policies-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json)
  --delivery-on-weekends: oneof<nothing, bool> # If the shipping policy (carrier) delivers on weekends (e.g. false)
  --delivery-schedule-settings: record # Settings for the Scheduled Delivery feature. — shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
  --is-active: oneof<nothing, bool> # If the shipping policy is active or not. (e.g. true)
  max_dimension: record # Object containing attributes of maximum dimension permitted by the shipping policy (carrier). (e.g. {largestMeasure: 10, maxMeasureSum: 30}) — shape: {largestMeasure: float, maxMeasureSum: float}
  name: string # Name of the shipping policy (e.g. Correios PAC)
  shipping_method: string # Type of shipping available for this shipping policy (carrier). Options shown on freight simulation. (e.g. Normal)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/logistics/pvt/shipping-policies/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deliveryOnWeekends, var: delivery_on_weekends, required: true}, {name: deliveryScheduleSettings, var: delivery_schedule_settings}, {name: isActive, var: is_active, required: true}, {name: maxDimension, var: max_dimension}, {name: name, var: name}, {name: shippingMethod, var: shipping_method}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    id: $id, hdr_accept: $hdr_accept, content_type: $content_type, delivery_on_weekends: $delivery_on_weekends, delivery_schedule_settings: $delivery_schedule_settings, is_active: $is_active, max_dimension: $max_dimension, name: $name, shipping_method: $shipping_method
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate SLA
#
# POST /api/logistics/pvt/shipping/calculate
# Returns: list<table<aditionalTimeBlockedDays: string, availabilityQuantity: int, carrierSchedule: list, coordinates: string, deliveryOnWeekends: bool, deliveryWindows: list, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, itemId: string, listPrice: float, location: record, pickupStoreInfo: string, quantity: int, restrictedFreight: string, salesChannel: string, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string>>
# operationId: CalculateSLA
export def "calculate-sla" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json; charset=utf-8)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/logistics/pvt/shipping/calculate"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json; charset=utf-8"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json; charset=utf-8", kind: json, accepts: scalar}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: LOGISTICS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: LOGISTICS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
