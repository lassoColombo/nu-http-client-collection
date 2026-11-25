# Auto-generated client for Orders API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Orders-API/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.ORDERS_API_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.ORDERS_API_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "ORDERS_API_TOKEN"
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
    get-window-to-change-seller: "int"
    status-completed: "table<cancelled: bool, completedDate: string, dateOfRequest: string, email: string, filter: string, hostUri: string, id: string, instanceId: string, lasUpdateTime: string, linkToDownload: string, publishId: string, query: string, rowNumber: int, rowsProcessed: int, startDate: string, utcTime: string>"
    status-in-progress: "table<cancelled: bool, completedDate: string, dateOfRequest: string, email: string, filter: string, hostUri: string, id: string, instanceId: string, lasUpdateTime: string, linkToDownload: string, publishId: string, query: string, rowNumber: int, rowsProcessed: int, startDate: string, utcTime: string>"
    list-orders: "record<facets: list<string>, list: table<ShippingEstimatedDate: string, ShippingEstimatedDateMax: string, ShippingEstimatedDateMin: string, affiliateId: string, authorizedDate: string, callCenterOperatorName: string, clientName: string, creationDate: string, currencyCode: string, items: string, lastMessageUnread: string, listId: string, listType: string, marketPlaceOrderId: string, orderId: string, orderIsComplete: bool, origin: string, paymentNames: string, salesChannel: string, sequence: string, status: string, statusDescription: string, totalItems: int, totalValue: int, workflowInErrorState: bool, workflowInRetry: bool>, paging: record<currentPage: int, pages: int, perPage: int, total: int>, stats: record<stats: record<totalItems: record, totalValue: record>>>"
    get-order: "record<affiliateId: string, allowCancellation: bool, allowEdition: bool, approvedBy: string, authorizedDate: string, callCenterOperatorData: string, cancelReason: string, cancelledBy: string, changesAttachment: record<changesData: list<record>, id: string>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, id: string, isCorporate: bool, lastName: string, phone: string, stateInscription: string, tradeName: string, userProfileId: string>, commercialConditionData: string, creationDate: string, customData: string, emailTracked: string, followUpEmail: string, giftRegistryData: string, hostname: string, invoiceData: record, invoicedDate: string, isCheckedIn: bool, isCompleted: bool, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, lastChange: string, lastMessage: string, marketingData: string, marketplace: record<baseURL: string, isCertified: string, name: string>, marketplaceItems: list<string>, marketplaceOrderId: string, marketplaceServicesEndpoint: string, merchantName: string, openTextField: string, orderFormId: string, orderGroup: string, orderId: string, origin: string, packageAttachment: record<packages: list<record>>, paymentData: record<giftCards: list<any>, transactions: list<record>>, ratesAndBenefitsData: record<id: string, rateAndBenefitsIdentifiers: list<string>>, roundingError: int, salesChannel: string, sellerOrderId: string, sellers: table<fulfillmentEndpoint: string, id: string, logo: string, name: string>, sequence: string, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, entityId: string, geoCoordinates: list, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string, versionId: string>, id: string, logisticsInfo: list<record>, selectedAddresses: list<record>, trackingHints: string>, status: string, statusDescription: string, storePreferencesData: record<countryCode: string, currencyCode: string, currencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, currencyLocale: int, currencySymbol: string, timeZone: string>, totals: table<id: string, name: string, value: int>, value: int>"
    cancel-order: "record<date: string, orderId: string, receipt: string>"
    register-change: "record<date: string, orderId: string, receipt: string>"
    get-conversation: "table<attachmentNames: list<string>, body: string, date: string, firstWords: string, from: record<aliasMaskType: int, conversationRelatedTo: string, conversationSubject: string, email: string, emailAlias: string, name: string, role: string>, hasAttachment: bool, id: string, subject: string, to: list<record>>"
    invoice-notification: "record<date: string, orderId: string, receipt: string>"
    updatepartialinvoice-send-tracking-number: "record<date: string, orderId: string, receipt: string>"
    update-tracking-status: "record<date: string, orderId: string, receipt: string>"
    get-paymenttransaction: "record<isActive: bool, merchantName: string, payments: table<cardHolder: string, cardNumber: string, connectorResponses: record, cvv2: string, dueDate: string, expireMonth: string, expireYear: string, firstDigits: string, giftCardCaption: string, giftCardId: string, giftCardName: string, group: string, id: string, installments: int, lastDigits: string, paymentSystem: string, paymentSystemName: string, redemptionCode: string, referenceValue: int, tid: string, url: string, value: int>, status: string, transactionId: string>"
    userorderslist: "record<facets: list<string>, list: table<ShippingEstimatedDate: string, ShippingEstimatedDateMax: string, ShippingEstimatedDateMin: string, affiliateId: string, authorizedDate: string, callCenterOperatorName: string, clientName: string, creationDate: string, currencyCode: string, items: list, lastMessageUnread: string, listId: string, listType: string, marketPlaceOrderId: string, orderId: string, orderIsComplete: bool, origin: string, paymentNames: string, salesChannel: string, sequence: string, status: string, statusDescription: string, totalItems: int, totalValue: int, workflowInErrorState: bool, workflowInRetry: bool>, paging: record<currentPage: int, pages: int, perPage: int, total: int>, stats: record<stats: record<totalItems: record, totalValue: record>>>"
    userorderdetails: "record<affiliateId: string, allowCancellation: bool, allowEdition: bool, authorizedDate: string, callCenterOperatorData: string, cancelReason: string, cancellationData: record<CancellationDate: string, Reason: string, RequestedByPaymentNotification: bool, RequestedBySellerNotification: bool, RequestedBySystem: bool, RequestedByUser: bool>, changesAttachment: record<changesData: list<record>, id: string>, checkedInPickupPointId: string, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, id: string, isCorporate: bool, lastName: string, phone: string, stateInscription: string, tradeName: string, userProfileId: string>, commercialConditionData: string, creationDate: string, customData: string, followUpEmail: string, giftRegistryData: string, hostname: string, invoiceData: record, invoicedDate: string, isCheckedIn: bool, isCompleted: bool, itemMetadata: record<Items: list<record>>, items: table<additionalInfo: record, assemblies: list, attachmentOfferings: list, attachments: list, bundleItems: list, callCenterOperator: string, commission: int, components: list, costPrice: int, detailUrl: string, ean: string, freightCommission: int, id: string, imageUrl: string, isGift: bool, itemAttachment: record, listPrice: int, lockId: string, manualPrice: string, measurementUnit: string, name: string, offerings: list, params: list, parentAssemblyBinding: string, parentItemIndex: string, preSaleDate: string, price: int, priceDefinitions: record, priceTags: list, priceValidUntil: string, productId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerSku: string, sellingPrice: int, serialNumbers: string, shippingPrice: string, tax: int, taxCode: string, uniqueId: string, unitMultiplier: int>, lastChange: string, lastMessage: string, marketingData: record<coupon: string, id: string, marketingTags: list<string>, utmCampaign: string, utmMedium: string, utmPartner: string, utmSource: string, utmiCampaign: string, utmiPart: string, utmipage: string>, marketplace: record<baseURL: string, isCertified: string, name: string>, marketplaceItems: list<string>, marketplaceOrderId: string, marketplaceServicesEndpoint: string, merchantName: string, openTextField: string, orderFormId: string, orderGroup: string, orderId: string, origin: string, packageAttachment: record<packages: list<string>>, paymentData: record<giftCards: list<any>, transactions: list<record>>, ratesAndBenefitsData: record<id: string, rateAndBenefitsIdentifiers: list<string>>, roundingError: int, salesChannel: string, sellerOrderId: string, sellers: table<fulfillmentEndpoint: string, id: string, logo: string, name: string>, sequence: string, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, entityId: string, geoCoordinates: list, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string, versionId: string>, id: string, logisticsInfo: list<record>, selectedAddresses: list<record>, trackingHints: string>, status: string, statusDescription: string, storePreferencesData: record<countryCode: string, currencyCode: string, currencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, currencyLocale: int, currencySymbol: string, timeZone: string>, subscriptionData: record<SubscriptionGroupId: string, Subscriptions: list<record>>, taxData: record<areTaxesDesignatedByMarketplace: bool, taxInfoCollection: list<record>>, totals: table<id: string, name: string, value: int>, value: int>"
    getfeedorderstatus1: "table<currentChange: string, domain: string, eventId: string, handle: string, lastChange: string, lastState: string, orderId: string, state: string>"
    commititemfeedorderstatus: "record"
    get-feed-configuration: "record<approximateAgeOfOldestMessageInSeconds: float, filter: record<disableSingleFire: bool, expression: string, status: list<string>, type: string>, quantity: int, queue: record<MessageRetentionPeriodInSeconds: int, visibilityTimeoutInSeconds: int>>"
    hook-configuration: "record<CurrentChange: string, Domain: string, LastChange: string, LastState: string, OrderId: string, Origin: record<Account: string, Key: string>, State: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-window-to-change-seller" "update-window-to-change-seller" "status-completed" "status-in-progress" "getfeedorderstatus" "list-orders" "get-order" "cancel-order" "register-change" "get-conversation" "add-log" "invoice-notification" "updatepartialinvoice-send-tracking-number" "update-tracking-status" "get-paymenttransaction" "send-payment-notification" "start-handling" "userorderslist" "userorderdetails" "test-jso-nata-expression" "getfeedorderstatus1" "commititemfeedorderstatus" "feed-configuration-delete" "get-feed-configuration" "feed-configuration" "delete-hook-configuration" "get-hook-configuration" "hook-configuration" "commands"] | sort) } | get name | first)
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

# Get window to change seller
#
# GET /api/checkout/pvt/configuration/window-to-change-seller
# Returns: int
# operationId: GetWindowToChangeSeller
export def "get-window-to-change-seller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/checkout/pvt/configuration/window-to-change-seller"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update window to change seller
#
# POST /api/checkout/pvt/configuration/window-to-change-seller
# operationId: UpdateWindowToChangeSeller
export def "update-window-to-change-seller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  waiting_time: int # Number of days after order cancelation by a seller, during which another seller may be assigned to fulfill the order.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/checkout/pvt/configuration/window-to-change-seller"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: waitingTime, var: waiting_time}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, waiting_time: $waiting_time
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export order report with status 'Completed'
#
# GET /api/oms/pvt/admin/reports/completed
# Returns: table<cancelled: bool, completedDate: string, dateOfRequest: string, email: string, filter: string, hostUri: string, id: string, instanceId: string, lasUpdateTime: string, linkToDownload: string, publishId: string, query: string, rowNumber: int, rowsProcessed: int, startDate: string, utcTime: string>
# operationId: StatusCompleted
export def "status-completed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/oms/pvt/admin/reports/completed"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export order report with status 'In Progress'
#
# GET /api/oms/pvt/admin/reports/inprogress
# Returns: table<cancelled: bool, completedDate: string, dateOfRequest: string, email: string, filter: string, hostUri: string, id: string, instanceId: string, lasUpdateTime: string, linkToDownload: string, publishId: string, query: string, rowNumber: int, rowsProcessed: int, startDate: string, utcTime: string>
# operationId: StatusInProgress
export def "status-in-progress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/oms/pvt/admin/reports/inprogress"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get feed order status
#
# GET /api/oms/pvt/feed/orders/status
# operationId: Getfeedorderstatus
export def "getfeedorderstatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-lot: string # required, default: {{maxLot}}
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/oms/pvt/feed/orders/status"
    query: [{name: maxLot, var: max_lot, required: true, default: "{{maxLot}}"}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    max_lot: $max_lot, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List orders
#
# GET /api/oms/pvt/orders
# Returns: record<facets: list<string>, list: table<ShippingEstimatedDate: string, ShippingEstimatedDateMax: string, ShippingEstimatedDateMin: string, affiliateId: string, authorizedDate: string, callCenterOperatorName: string, clientName: string, creationDate: string, currencyCode: string, items: string, lastMessageUnread: string, listId: string, listType: string, marketPlaceOrderId: string, orderId: string, orderIsComplete: bool, origin: string, paymentNames: string, salesChannel: string, sequence: string, status: string, statusDescription: string, totalItems: int, totalValue: int, workflowInErrorState: bool, workflowInRetry: bool>, paging: record<currentPage: int, pages: int, perPage: int, total: int>, stats: record<stats: record<totalItems: record, totalValue: record>>>
# operationId: ListOrders
export def "list-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # You can retrieve orders lists filtering by an `OrderField` combined with an `OrderType`. To do so, you have to concatenate them: `orderBy={{OrderField}},{{OrderType}}`. - `OrderField` values accepted: `creationDate`, `orderId`, `items`, `totalValue` and `origin`. - `OrderType` values accepted: `asc` and `desc`. (default: v502556llux-01,asc)
  --page: int # Define the number of pages you wish to retrieve, restricted to the limit of 30 pages. (format: int32, default: 10)
  --per-page: int # Quantity of orders for each page, the default value is 15 and it goes up to 100 orders per page. Be aware that the limit of retrieval ofthis endpoint is 30 pages. (format: int32, default: 15)
  --f-creation-date: string # Concatened value sufix `{{creationDate}}` and range date in Timestamp format. To use the `utc` query parameter, to filter orders by time zone, you must also fill the `f_creationDate` date parameter. (required, default: creationDate:[2016-01-01T02:00:00.000Z TO 2021-01-01T01:59:59.999Z])
  --f-has-input-invoice: oneof<nothing, bool> # Filters list to return only orders with non `null` values for the `invoiceInput` field. (default: false)
  --q: string # This parameter filters using Fulltext and accepts the values below. Be aware that the `+` caracter is not allowed in Fulltext Search. - Order Id - Client email - Client document - Client name (default: - OrderID: v212333lux-02  - Client email: taylor@email.com  - Client document: 21133355524  - Client name: Taylor)
  --utc: int # Converts orders' time zone to the Universal Time Coordinated (UTC) format and shows the amount of orders set for that UTC, up to the limit of 30 pages. For it to work properly, you have to associate it with the `f_creationDate` parameter. (format: int32, default: -2000)
  --f-shipping-estimate: string # You can filter orders by shipping estimate time in days by concatenating the desired number of days with the sufix `.days`. For example: - Next 7 days: `7.days` - Tomorrow: `1.days` - Today: `0.days` - Late: `-1.days` (default: 0.days)
  --f-invoiced-date: string # You can filter orders by invoiced date by concatenating the sufix `invoicedDate:` with the range date in Timestamp format. For example: - 1 Day: `invoicedDate:[2022-01-01T02:00:00.000Z TO 2022-01-02T01:59:59.999Z]` - 1 Month: `invoicedDate:[2022-01-01T02:00:00.000Z TO 2022-02-01T01:59:59.999Z]` - 1 Year: `invoicedDate:[2022-01-01T02:00:00.000Z TO 2022-01-01T01:59:59.999Z]` (default: invoicedDate:[2022-01-01T02:00:00.000Z TO 2022-01-02T01:59:59.999Z])
  --f-authorized-date: string # You can filter orders by creation date by concatenating the sufix `authorizedDate:` with the range date in Timestamp format. For example: - 1 Day: `authorizedDate:[2022-01-01T02:00:00.000Z TO 2022-01-02T01:59:59.999Z]` - 1 Month: `authorizedDate:[2022-01-01T02:00:00.000Z TO 2022-02-01T01:59:59.999Z]` - 1 Year: `authorizedDate:[2022-01-01T02:00:00.000Z TO 2022-01-01T01:59:59.999Z]` (default: creationDate:[2022-01-01T02:00:00.000Z TO 2022-01-02T01:59:59.999Z])
  --f-utm-source: string # You can filter orders by using a Universal Transverse Mercator (UTM) source. (default: christmas_campaign)
  --f-seller-names: string # You can filter orders by using a seller's name. (default: SellerName)
  --f-call-center-operator-name: string # You can filter orders by using a Call Center Operator's identification. (default: Operator%20Name)
  --f-sales-channel: string # You can filter orders by sales channel's ([or trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) name. (default: Main)
  --sales-channel-id: string # You can filter orders by sales channel's ([or trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) ID. (default: 1)
  --f-affiliate-id: string # You can filter orders by affiliate ID. (default: WLM)
  --f-status: string # You can filter orders by the following [order status](https://help.vtex.com/en/tutorial/order-flow-and-status--tutorials_196): - `waiting-for-sellers-confirmation` - `payment-pending` - `payment-approved` - `ready-for-handling` - `handling` - `invoiced` - `canceled` (default: ready-for-handling)
  --incomplete-orders: oneof<nothing, bool> # When set as `true`, you retrieve [incomplete orders](https://help.vtex.com/en/tutorial/understanding-incomplete-orders), when set as `false`, you retrieve orders that are not incomplete. (default: true)
  --f-payment-names: string # You can filter orders by payment type. (default: Visa)
  --f-rn-b: string # You can filter orders by rates and benefits (promotions). (default: Free+Shipping)
  --search-field: string # You can search orders by using one of the following criterias: - SKU ID - `sku_Ids&sku_Ids` - Gift List ID - `listId&listId` - Transaction ID (TID) - `tid&tid` - PCI Connector's Transaction ID (TID) - `pci_tid&pci_tid` - Payment ID (PID) - `paymentId&paymentId` - Connector's NSU - `nsu&nsu` (default:  - SKU ID: `25`  - Gift List ID: `11223`  - Transaction ID (TID): `54546300238810034995829230012`  - PCI Connector's Transaction ID (TID): `7032909234899834298423209`  - Payment ID (PID): `2`  - Connector's NSU: `2437281`)
  --f-is-instore: oneof<nothing, bool> # When set as `true`, this parameter filters orders made via [inStore](https://help.vtex.com/en/tracks/what-is-instore--zav76TFEZlAjnyBVL5tRc), and when set as `false`, it filters orders that were not made via inStore. (default: true)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/oms/pvt/orders"
    query: [{name: orderBy, var: order_by}, {name: page, var: page}, {name: per_page, var: per_page}, {name: f_creationDate, var: f_creation_date, required: true, default: "creationDate:[2016-01-01T02:00:00.000Z TO 2021-01-01T01:59:59.999Z]"}, {name: f_hasInputInvoice, var: f_has_input_invoice}, {name: q, var: q}, {name: utc, var: utc}, {name: f_shippingEstimate, var: f_shipping_estimate}, {name: f_invoicedDate, var: f_invoiced_date}, {name: f_authorizedDate, var: f_authorized_date}, {name: f_UtmSource, var: f_utm_source}, {name: f_sellerNames, var: f_seller_names}, {name: f_callCenterOperatorName, var: f_call_center_operator_name}, {name: f_salesChannel, var: f_sales_channel}, {name: salesChannelId, var: sales_channel_id}, {name: f_affiliateId, var: f_affiliate_id}, {name: f_status, var: f_status}, {name: incompleteOrders, var: incomplete_orders}, {name: f_paymentNames, var: f_payment_names}, {name: f_RnB, var: f_rn_b}, {name: searchField, var: search_field}, {name: f_isInstore, var: f_is_instore}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_by: $order_by, page: $page, per_page: $per_page, f_creation_date: $f_creation_date, f_has_input_invoice: $f_has_input_invoice, q: $q, utc: $utc, f_shipping_estimate: $f_shipping_estimate, f_invoiced_date: $f_invoiced_date, f_authorized_date: $f_authorized_date, f_utm_source: $f_utm_source, f_seller_names: $f_seller_names, f_call_center_operator_name: $f_call_center_operator_name, f_sales_channel: $f_sales_channel, sales_channel_id: $sales_channel_id, f_affiliate_id: $f_affiliate_id, f_status: $f_status, incomplete_orders: $incomplete_orders, f_payment_names: $f_payment_names, f_rn_b: $f_rn_b, search_field: $search_field, f_is_instore: $f_is_instore, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get order
#
# GET /api/oms/pvt/orders/{orderId}
# Returns: record<affiliateId: string, allowCancellation: bool, allowEdition: bool, approvedBy: string, authorizedDate: string, callCenterOperatorData: string, cancelReason: string, cancelledBy: string, changesAttachment: record<changesData: list<record>, id: string>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, id: string, isCorporate: bool, lastName: string, phone: string, stateInscription: string, tradeName: string, userProfileId: string>, commercialConditionData: string, creationDate: string, customData: string, emailTracked: string, followUpEmail: string, giftRegistryData: string, hostname: string, invoiceData: record, invoicedDate: string, isCheckedIn: bool, isCompleted: bool, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, lastChange: string, lastMessage: string, marketingData: string, marketplace: record<baseURL: string, isCertified: string, name: string>, marketplaceItems: list<string>, marketplaceOrderId: string, marketplaceServicesEndpoint: string, merchantName: string, openTextField: string, orderFormId: string, orderGroup: string, orderId: string, origin: string, packageAttachment: record<packages: list<record>>, paymentData: record<giftCards: list<any>, transactions: list<record>>, ratesAndBenefitsData: record<id: string, rateAndBenefitsIdentifiers: list<string>>, roundingError: int, salesChannel: string, sellerOrderId: string, sellers: table<fulfillmentEndpoint: string, id: string, logo: string, name: string>, sequence: string, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, entityId: string, geoCoordinates: list, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string, versionId: string>, id: string, logisticsInfo: list<record>, selectedAddresses: list<record>, trackingHints: string>, status: string, statusDescription: string, storePreferencesData: record<countryCode: string, currencyCode: string, currencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, currencyLocale: int, currencySymbol: string, timeZone: string>, totals: table<id: string, name: string, value: int>, value: int>
# operationId: GetOrder
export def "get-order" [
  order_id: string
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
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/oms/pvt/orders/{orderId}"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel order
#
# POST /api/oms/pvt/orders/{orderId}/cancel
# Returns: record<date: string, orderId: string, receipt: string>
# operationId: CancelOrder
export def "cancel-order" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --reason: string # Reason for cancelling the order. (default: Unexpected stock shortage)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/oms/pvt/orders/{orderId}/cancel"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, hdr_accept: $hdr_accept, content_type: $content_type, reason: $reason
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register change on order
#
# POST /api/oms/pvt/orders/{orderId}/changes
# Returns: record<date: string, orderId: string, receipt: string>
# operationId: RegisterChange
export def "register-change" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  discount_value: int # This field can be used to apply a discount to the total value of the order. Value in cents. (format: int32, default: 100)
  increment_value: int # This field can be used to increment the total value of the order. Value in cents. (format: int32, default: 100)
  --items-added: list # List of items that should be added to the order. — item shape: {id: string, price: int, quantity: int}
  --items-removed: list # List of items that should be removed from the order. — item shape: {id: string, price: int, quantity: int}
  reason: string # Reason for order change. This may be shown to the shopper in the UI or transactional emails. (default: Stock shortage)
  request_id: string # Request identification of the change. Only the first change made with each `requestId` will be effective on a given order. Use different IDs for different changes to the same order. (default: change-request-0123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/oms/pvt/orders/{orderId}/changes"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: discountValue, var: discount_value}, {name: incrementValue, var: increment_value}, {name: itemsAdded, var: items_added}, {name: itemsRemoved, var: items_removed}, {name: reason, var: reason}, {name: requestId, var: request_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, content_type: $content_type, hdr_accept: $hdr_accept, discount_value: $discount_value, increment_value: $increment_value, items_added: $items_added, items_removed: $items_removed, reason: $reason, request_id: $request_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve order conversation
#
# GET /api/oms/pvt/orders/{orderId}/conversation-message
# Returns: table<attachmentNames: list<string>, body: string, date: string, firstWords: string, from: record<aliasMaskType: int, conversationRelatedTo: string, conversationSubject: string, email: string, emailAlias: string, name: string, role: string>, hasAttachment: bool, id: string, subject: string, to: list<record>>
# operationId: GetConversation
export def "get-conversation" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. Relevant only for PII platform version. (e.g. data-validation)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/oms/pvt/orders/{orderId}/conversation-message"
    path_params: [{name: orderId, var: order_id}]
    query: [{name: reason, var: reason}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, reason: $reason, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add log in orders
#
# POST /api/oms/pvt/orders/{orderId}/interactions
# operationId: AddLog
export def "add-log" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  message: string
  source: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/oms/pvt/orders/{orderId}/interactions"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, content_type: $content_type, hdr_accept: $hdr_accept, message: $message, source: $source
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order invoice notification
#
# POST /api/oms/pvt/orders/{orderId}/invoice
# Returns: record<date: string, orderId: string, receipt: string>
# operationId: InvoiceNotification
export def "invoice-notification" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --courier: string # The name of the carrier responsible for delivering the order. *This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`).* (nullable)
  --dispatched-date: string # Order dispatch date. May be `null`. (nullable, default: 2019-02-08T13:16:13.4617653+00:00)
  --embedded-invoice: string # XML text of the invoice, not the URL. This field is very important for external marketplace integrations such as Mercado Libre. (nullable, default: <NFe> <infNFe Id="NFe34687999999090910270550010000000015180000000000" versao="1.10"> <ide> <cUF>37</cUF> <cNF>000005177</cNF> <natOp>Venda a vista</natOp> <indPag>0</indPag> <mod>55</mod> <serie>1</serie> <nNF>1</nNF> <dEmi>2018-07-06</dEmi> <dSaiEnt>2018-07-06</dSaiEnt> <tpNF>0</tpNF> <cMunFG>79950308</cMunFG> <tpImp>1</tpImp> <tpEmis>1</tpEmis> <cDV>3</cDV> <tpAmb>2</tpAmb> <finNFe>1</finNFe> <procEmi>0</procEmi> <verProc>NF-eletronica.com</verProc> </ide> <emit> <CNPJ>99999090998760</CNPJ> <xNome>NF-e Associacao NF-e</xNome> <xFant>NF-e</xFant> <enderEmit> <xLgr>Rua Central</xLgr> <nro>100</nro> <xCpl>Fundos</xCpl> <xBairro>Distrito Industrial</xBairro> <cMun>0000000</cMun> <xMun>Município</xMun> <UF>SP</UF> <CEP>0000000</CEP> <cPais>1058</cPais> <xPais>Brasil</xPais> <fone>1733021717</fone> </enderEmit> <IE>123456789012</IE> </emit> <dest> <CNPJ>00000000000000</CNPJ> <xNome>DISTRIBUIDORA DE AGUAS MINERAIS</xNome> <enderDest> <xLgr>AV DAS FONTES</xLgr> <nro>1777</nro> <xCpl>1001 ANDAR</xCpl> <xBairro>PARQUE</xBairro> <cMun>0000000</cMun> <xMun>Sao Paulo</xMun> <UF>SP</UF> <CEP>00000000</CEP> <cPais>1058</cPais> <xPais>BRASIL</xPais> <fone>3900000000</fone> </enderDest> <IE> </IE> </dest> <retirada> <CNPJ>000000000004</CNPJ> <xLgr>AV PAULISTA</xLgr> <nro>12345</nro> <xCpl>TERREO</xCpl> <xBairro>CERQUEIRA CESAR</xBairro> <cMun>0000000</cMun> <xMun>SAO PAULO</xMun> <UF>SP</UF> </retirada> <entrega> <CNPJ>00000000299000194</CNPJ> <xLgr>AV FARIA LIMA</xLgr> <nro>154400</nro> <xCpl>156 ANDAR</xCpl> <xBairro>PINHEIROS</xBairro> <cMun>0000308</cMun> <xMun>SAO PAULO</xMun> <UF>SP</UF> </entrega> <det nItem="1"> <prod> <cProd>00001</cProd> <cEAN/> <xProd>Agua Mineral</xProd> <CFOP>5101</CFOP> <uCom>dz</uCom> <qCom>1000000.0000</qCom> <vUnCom>1</vUnCom> <vProd>10000000.00</vProd> <cEANTrib/> <uTrib>und</uTrib> <qTrib>12000000.0000</qTrib> <vUnTrib>1</vUnTrib> </prod> <imposto> <ICMS> <ICMS00> <orig>0</orig> <CST>00</CST> <modBC>0</modBC> <vBC>10000000.00</vBC> <pICMS>18.00</pICMS> <vICMS>1800000.00</vICMS> </ICMS00> </ICMS> <PIS> <PISAliq> <CST>01</CST> <vBC>10000000.00</vBC> <pPIS>0.65</pPIS> <vPIS>65000</vPIS> </PISAliq> </PIS> <COFINS> <COFINSAliq> <CST>01</CST> <vBC>10000000.00</vBC> <pCOFINS>2.00</pCOFINS> <vCOFINS>200000.00</vCOFINS> </COFINSAliq> </COFINS> </imposto> </det> <det nItem="2"> <prod> <cProd>00002</cProd> <cEAN/> <xProd>Agua Mineral</xProd> <CFOP>5101</CFOP> <uCom>pack</uCom> <qCom>5000000.0000</qCom> <vUnCom>2</vUnCom> <vProd>10000000.00</vProd> <cEANTrib/> <uTrib>und</uTrib> <qTrib>3000000.0000</qTrib> <vUnTrib>0.3333</vUnTrib> </prod> <imposto> <ICMS> <ICMS00> <orig>0</orig> <CST>00</CST> <modBC>0</modBC> <vBC>10000000.00</vBC> <pICMS>18.00</pICMS> <vICMS>1800000.00</vICMS> </ICMS00> </ICMS> <PIS> <PISAliq> <CST>01</CST> <vBC>10000000.00</vBC> <pPIS>0.65</pPIS> <vPIS>65000</vPIS> </PISAliq> </PIS> <COFINS> <COFINSAliq> <CST>01</CST> <vBC>10000000.00</vBC> <pCOFINS>2.00</pCOFINS> <vCOFINS>200000.00</vCOFINS> </COFINSAliq> </COFINS> </imposto> </det> <total> <ICMSTot> <vBC>20000000.00</vBC> <vICMS>18.00</vICMS> <vBCST>0</vBCST> <vST>0</vST> <vProd>20000000.00</vProd> <vFrete>0</vFrete> <vSeg>0</vSeg> <vDesc>0</vDesc> <vII>0</vII> <vIPI>0</vIPI> <vPIS>130000.00</vPIS> <vCOFINS>400000.00</vCOFINS> <vOutro>0</vOutro> <vNF>20000000.00</vNF> </ICMSTot> </total> <transp> <modFrete>0</modFrete> <transporta> <CNPJ>00000000000000</CNPJ> <xNome>Distribuidora de Bebidas Fazenda de SP Ltda.</xNome> <IE>00000000999119</IE> <xEnder>Rua Central 100 - Fundos - Distrito Industrial</xEnder> <xMun>SAO PAULO</xMun> <UF>SP</UF> </transporta> <veicTransp> <placa>BXI1717</placa> <UF>SP</UF> <RNTC>123456789</RNTC> </veicTransp> <reboque> <placa>UUU0000</placa> <UF>SP</UF> <RNTC>123456789</RNTC> </reboque> <vol> <qVol>10000</qVol> <esp>CAIXA</esp> <marca>LINDOYA</marca> <nVol>500</nVol> <pesoL>1000000000.000</pesoL> <pesoB>1200000000.000</pesoB> <lacres> <nLacre>XYZ10231486</nLacre> </lacres> </vol> </transp> <infAdic> <infAdFisco>Nota Fiscal de exemplo NF-eletronica.com</infAdFisco> </infAdic> </infNFe> <Signature> <SignedInfo> <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-0321120010315"/> <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/> <Reference URI="#NFe3508059999977777777705500100000000000000000"> <Transforms> <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/> <Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-66666615"/> </Transforms> <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/> <DigestValue>xFzhgdgnhjSD1e9uqe04lnoHT4ZzLSY=</DigestValue> </Reference> </SignedInfo> <SignatureValue> Iz5Z3PLQbzZt9jnBtr6xsmHZMOu/3plXG9xxfFjRCQYGnD1rjlhzBGrqt026Ca2VHHM/bHNepi6FuFkAi595GScKVuHREUotzifE2OIjgavvTOrMwbXG7+0LYgkwPFiPCao2S33UpZe7MneaxcmKQGKQZw1fP8fsWmaQ4cczZT8= </SignatureValue> <KeyInfo> <X509Data> <X509Certificate> MIIEuzCCA6OgAwIBAgIDMTMxMA0GasfFSDAGQUAMIGSMQswCQYDVQQGEwJCUjELMAkGA1UECBMCUlMxFTATBgNVBAcTDFBvcnRvIEFsZWdyZTEdMBsGA1UEChMUVGVzdGUgUHJvamV0byBORmUgUlMxHTAbBgNVBAsTFFRlc3RlIFByb2pldG8gTkZlIFJTMSEwHwYDVQQDExhORmUgLSBBQyBJbnRlcm1lZGlhcmlhIDEwHhcNMDgwNDI4MDkwMTAyWhcNMDkwNDMwMjM1OTU5WjCBnjELMAkGA1UECBMCUlMxHTAfvw4567DRhg76FByb2pldG8gTkZlIFJTMR0wGwYDVQQKExRUZXN0ZSBQcm9qZXRvIE5GZSBSUzEVMBMGA1UEBxMMUE9SVE8gQUxFR1JFMQswCQYDVQQGEwJCUjEtMCsGA1UEAxMkTkZlIC0gQXNzb2NpYWNhbyBORi1lOjk5OTk5MDkwOTEwMjcwMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDh6RRv0bj4RYX+tDQrZRb5opa77LBVVs+6LphIfSF3TSWPfnKh0+xLlBFdmnB5YGgbbW9Uon6pZQTfaC8jZhRhI5eFRRofY/Ugoeo0NGt6PcIQNZQd6lLQ/ASd1qWwjqJoEa7udriKjy3h351Mf1bng1VxS1urqC3Dn39ZWIEwQIDAQABo4IBjjCCAYowIgYDVR0jAQEABBgwFoAUPT5TqhNWAm+ZpcVsvB7malDBjEQwDwYDVR0TAQH/BAUwAwEBADAPBgNVHQ8BAf8EBQMDAOAAMAwGA1UdIAEBAAQCMAAwgbwGA1UdEQEBAASBsTCBrqA4BgVgTAEDBKAvBC0wNzA4MTk1MTE1MTk0NTMxMDg3MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDCgHQYFYEwBAwKgFAQSRmVybmFuZG8gQ2FudG8gQWx0oBkGBWBMAQMDoBAEDjk5OTk5MDkwOTEwMjcwoBcGBWBMAQMHoA4EDDAwMDAwMDAwMDAwMIEfZmVybmFuZG8tYWx0QHByb2NlcmdzLnJzLmdvdi5icjAgBgNVHSUBAf8EFjAUBggrBgEFBQcDAgYIKwYBBQUHAwQwUwYDVR0fAQEABEkwRzBFoEOgQYY/aHR0cDovL25mZWNlcnRpZmljYWRvLnNlZmF6LnJzLmdvdi5ici9MQ1IvQUNJbnRlcm1lZGlhcmlhMzguY3JsMA0GCSqGSIb3DQEBBQUAA4IBAQCNPpaZ3Byu3/70nObXE8NiM53j1ddIFXsb+v2ghCVd4ffExv3hYc+/a3lfgV8H/WfQsdSCTzS2cHrd4Aasr/eXfclVDmf2hcWz+R7iysOHuT6B6r+DvV3JcMdJJCDdynR5REa+zViMnVZo1G3KuceQ7/y5X3WFNVq4kwHvonJ9oExsWyw8rTwUK5bsjz0A2yEwXkmkJIngnF41sP31+9jCImiqkXcmsesFhxzX7iurAQAQCZOm7iwMWxQKcAjXCZrgSZWRQy6mU224sX3HTArHahmLJ9Iw+WYAua5qBJsiN6PC7v5tfhdsgGD46DHMnOecxvkkPolDUyBa7d7xwgm </X509Certificate> </X509Data> </KeyInfo> </Signature> </NFe>)
  --invoice-key: string # nullable
  --invoice-number: string # Number that identifies the invoice. (nullable)
  --invoice-url: string # URL of the invoice. Can be used to send the URL of an XML file, for example, which is useful for some integrations. (nullable)
  invoice_value: string # Total amount being invoiced in cents. Do not use any decimal separator. For instance, `$24.99` should be represented as `2499`. (default: 2499)
  issuance_date: string # Issuance date of the invoice. You must add date and time in this field. (e.g. 2019-01-31T18:25:43-05:00)
  items: list # Array containing the SKUs that are being invoiced. — item shape: {description?: string, id: string, price: int, quantity: int}
  --tracking-number: string # The number code that identifies the order tracking. *This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`).* (nullable)
  --tracking-url: string # The URL used to track the order. *This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`).* (nullable)
  type: string # The type of invoice. There are two possible values: **Output** and **Input**. The Output type should be used when the invoice you are sending is a selling invoice. The Input type should be used when you send a return invoice.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/oms/pvt/orders/{orderId}/invoice"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: dispatchedDate, var: dispatched_date}, {name: embeddedInvoice, var: embedded_invoice}, {name: invoiceKey, var: invoice_key}, {name: invoiceNumber, var: invoice_number}, {name: invoiceUrl, var: invoice_url}, {name: invoiceValue, var: invoice_value}, {name: issuanceDate, var: issuance_date}, {name: items, var: items}, {name: trackingNumber, var: tracking_number}, {name: trackingUrl, var: tracking_url}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, hdr_accept: $hdr_accept, content_type: $content_type, courier: $courier, dispatched_date: $dispatched_date, embedded_invoice: $embedded_invoice, invoice_key: $invoice_key, invoice_number: $invoice_number, invoice_url: $invoice_url, invoice_value: $invoice_value, issuance_date: $issuance_date, items: $items, tracking_number: $tracking_number, tracking_url: $tracking_url, type: $type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order's partial invoice (send tracking number)
#
# PATCH /api/oms/pvt/orders/{orderId}/invoice/{invoiceNumber}
# Returns: record<date: string, orderId: string, receipt: string>
# operationId: Updatepartialinvoice.SendTrackingNumber
export def "updatepartialinvoice-send-tracking-number" [
  order_id: string
  invoice_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --courier: string # The name of the carrier responsible for delivering the order. (nullable)
  --dispatched-date: string # Date when the package was dispatched. For example, 2023-01-08T13:16:13.4617653+00:00. (nullable)
  tracking_number: string # The number code that identifies the order tracking.
  --tracking-url: string # Package tracking URL. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/oms/pvt/orders/{orderId}/invoice/{invoiceNumber}"
    path_params: [{name: orderId, var: order_id}, {name: invoiceNumber, var: invoice_number}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: dispatchedDate, var: dispatched_date}, {name: trackingNumber, var: tracking_number}, {name: trackingUrl, var: tracking_url}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, invoice_number: $invoice_number, content_type: $content_type, hdr_accept: $hdr_accept, courier: $courier, dispatched_date: $dispatched_date, tracking_number: $tracking_number, tracking_url: $tracking_url
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order tracking status
#
# PUT /api/oms/pvt/orders/{orderId}/invoice/{invoiceNumber}/tracking
# Returns: record<date: string, orderId: string, receipt: string>
# operationId: UpdateTrackingStatus
export def "update-tracking-status" [
  order_id: string
  invoice_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --delivered-date: string # Date and time of when the package was delivered. Note that it is different from the tracking date parameter. The `deliveredDate` format is `yyyy-mm-dd hh:mm`. (nullable, default: 2022-10-01 21:15)
  events: list # item shape: {city: string, date: string, description: string, state: string}
  --is-delivered: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/oms/pvt/orders/{orderId}/invoice/{invoiceNumber}/tracking"
    path_params: [{name: orderId, var: order_id}, {name: invoiceNumber, var: invoice_number}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deliveredDate, var: delivered_date}, {name: events, var: events}, {name: isDelivered, var: is_delivered, required: true}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, invoice_number: $invoice_number, content_type: $content_type, hdr_accept: $hdr_accept, delivered_date: $delivered_date, events: $events, is_delivered: $is_delivered
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve payment transaction
#
# GET /api/oms/pvt/orders/{orderId}/payment-transaction
# Returns: record<isActive: bool, merchantName: string, payments: table<cardHolder: string, cardNumber: string, connectorResponses: record, cvv2: string, dueDate: string, expireMonth: string, expireYear: string, firstDigits: string, giftCardCaption: string, giftCardId: string, giftCardName: string, group: string, id: string, installments: int, lastDigits: string, paymentSystem: string, paymentSystemName: string, redemptionCode: string, referenceValue: int, tid: string, url: string, value: int>, status: string, transactionId: string>
# operationId: GetPaymenttransaction
export def "get-paymenttransaction" [
  order_id: string
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
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/oms/pvt/orders/{orderId}/payment-transaction"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send payment notification
#
# POST /api/oms/pvt/orders/{orderId}/payments/{paymentId}/payment-notification
# operationId: SendPaymentNotification
export def "send-payment-notification" [
  order_id: string
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
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/oms/pvt/orders/{orderId}/payments/{paymentId}/payment-notification"
    path_params: [{name: orderId, var: order_id}, {name: paymentId, var: payment_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, payment_id: $payment_id, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start handling order
#
# POST /api/oms/pvt/orders/{orderId}/start-handling
# operationId: StartHandling
export def "start-handling" [
  order_id: string
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
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/oms/pvt/orders/{orderId}/start-handling"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve user's orders
#
# GET /api/oms/user/orders
# Returns: record<facets: list<string>, list: table<ShippingEstimatedDate: string, ShippingEstimatedDateMax: string, ShippingEstimatedDateMin: string, affiliateId: string, authorizedDate: string, callCenterOperatorName: string, clientName: string, creationDate: string, currencyCode: string, items: list, lastMessageUnread: string, listId: string, listType: string, marketPlaceOrderId: string, orderId: string, orderIsComplete: bool, origin: string, paymentNames: string, salesChannel: string, sequence: string, status: string, statusDescription: string, totalItems: int, totalValue: int, workflowInErrorState: bool, workflowInRetry: bool>, paging: record<currentPage: int, pages: int, perPage: int, total: int>, stats: record<stats: record<totalItems: record, totalValue: record>>>
# operationId: Userorderslist
export def "userorderslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-email: string # Customer email. (required, e.g. customer@mail.com)
  --page: string # Page number for result pagination. (required, e.g. 15)
  --per-page: string # Page quantity for result pagination. (required, e.g. 15)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/oms/user/orders"
    query: [{name: clientEmail, var: client_email, required: true}, {name: page, var: page, required: true}, {name: per_page, var: per_page, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    client_email: $client_email, page: $page, per_page: $per_page, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve user order details
#
# GET /api/oms/user/orders/{orderId}
# Returns: record<affiliateId: string, allowCancellation: bool, allowEdition: bool, authorizedDate: string, callCenterOperatorData: string, cancelReason: string, cancellationData: record<CancellationDate: string, Reason: string, RequestedByPaymentNotification: bool, RequestedBySellerNotification: bool, RequestedBySystem: bool, RequestedByUser: bool>, changesAttachment: record<changesData: list<record>, id: string>, checkedInPickupPointId: string, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, id: string, isCorporate: bool, lastName: string, phone: string, stateInscription: string, tradeName: string, userProfileId: string>, commercialConditionData: string, creationDate: string, customData: string, followUpEmail: string, giftRegistryData: string, hostname: string, invoiceData: record, invoicedDate: string, isCheckedIn: bool, isCompleted: bool, itemMetadata: record<Items: list<record>>, items: table<additionalInfo: record, assemblies: list, attachmentOfferings: list, attachments: list, bundleItems: list, callCenterOperator: string, commission: int, components: list, costPrice: int, detailUrl: string, ean: string, freightCommission: int, id: string, imageUrl: string, isGift: bool, itemAttachment: record, listPrice: int, lockId: string, manualPrice: string, measurementUnit: string, name: string, offerings: list, params: list, parentAssemblyBinding: string, parentItemIndex: string, preSaleDate: string, price: int, priceDefinitions: record, priceTags: list, priceValidUntil: string, productId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerSku: string, sellingPrice: int, serialNumbers: string, shippingPrice: string, tax: int, taxCode: string, uniqueId: string, unitMultiplier: int>, lastChange: string, lastMessage: string, marketingData: record<coupon: string, id: string, marketingTags: list<string>, utmCampaign: string, utmMedium: string, utmPartner: string, utmSource: string, utmiCampaign: string, utmiPart: string, utmipage: string>, marketplace: record<baseURL: string, isCertified: string, name: string>, marketplaceItems: list<string>, marketplaceOrderId: string, marketplaceServicesEndpoint: string, merchantName: string, openTextField: string, orderFormId: string, orderGroup: string, orderId: string, origin: string, packageAttachment: record<packages: list<string>>, paymentData: record<giftCards: list<any>, transactions: list<record>>, ratesAndBenefitsData: record<id: string, rateAndBenefitsIdentifiers: list<string>>, roundingError: int, salesChannel: string, sellerOrderId: string, sellers: table<fulfillmentEndpoint: string, id: string, logo: string, name: string>, sequence: string, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, entityId: string, geoCoordinates: list, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string, versionId: string>, id: string, logisticsInfo: list<record>, selectedAddresses: list<record>, trackingHints: string>, status: string, statusDescription: string, storePreferencesData: record<countryCode: string, currencyCode: string, currencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, currencyLocale: int, currencySymbol: string, timeZone: string>, subscriptionData: record<SubscriptionGroupId: string, Subscriptions: list<record>>, taxData: record<areTaxesDesignatedByMarketplace: bool, taxInfoCollection: list<record>>, totals: table<id: string, name: string, value: int>, value: int>
# operationId: Userorderdetails
export def "userorderdetails" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-email: string # Customer email. (required, e.g. customer@mail.com)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/oms/user/orders/{orderId}"
    path_params: [{name: orderId, var: order_id}]
    query: [{name: clientEmail, var: client_email, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    order_id: $order_id, client_email: $client_email, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test JSONata expression
#
# POST /api/orders/expressions/jsonata
# operationId: TestJSONataExpression
export def "test-jso-nata-expression" [
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
  document: string # JSON document to be evaluated by the expression.
  expression: string # JSONata expression to be tested.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/orders/expressions/jsonata"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Document, var: document}, {name: Expression, var: expression}]}
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type, document: $document, expression: $expression
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve feed items
#
# GET /api/orders/feed
# Returns: table<currentChange: string, domain: string, eventId: string, handle: string, lastChange: string, lastState: string, orderId: string, state: string>
# operationId: Getfeedorderstatus1
export def "getfeedorderstatus1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxlot: string # Lot quantity to retrieve. Maximum accepted value is 10. (required, default: {{maxLot}})
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent (required, default: application/json)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/orders/feed"
    query: [{name: maxlot, var: maxlot, required: true, default: "{{maxLot}}"}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    maxlot: $maxlot, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commit feed items
#
# POST /api/orders/feed
# Returns: record
# operationId: Commititemfeedorderstatus
export def "commititemfeedorderstatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  handles: list<string> # List of item handles to commit
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/orders/feed"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: handles, var: handles}]}
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, handles: $handles
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete feed configuration
#
# DELETE /api/orders/feed/config
# operationId: FeedConfigurationDelete
export def "feed-configuration-delete" [
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
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/orders/feed/config"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get feed configuration
#
# GET /api/orders/feed/config
# Returns: record<approximateAgeOfOldestMessageInSeconds: float, filter: record<disableSingleFire: bool, expression: string, status: list<string>, type: string>, quantity: int, queue: record<MessageRetentionPeriodInSeconds: int, visibilityTimeoutInSeconds: int>>
# operationId: GetFeedConfiguration
export def "get-feed-configuration" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/orders/feed/config"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update feed configuration
#
# POST /api/orders/feed/config
# operationId: FeedConfiguration
export def "feed-configuration" [
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
  --content-type: string # Type of the content being sent. (required, default: application/json)
  filter: record # Object with type and status that will filter feed orders. — shape: {disableSingleFire?: bool, expression?: string, status?: list<string>, type: string}
  queue: record # Object with information about timeout and message retention. — shape: {MessageRetentionPeriodInSeconds: int, visibilityTimeoutInSeconds: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/orders/feed/config"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: filter, var: filter}, {name: queue, var: queue}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type, filter: $filter, queue: $queue
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete hook configuration
#
# DELETE /api/orders/hook/config
# operationId: DeleteHookConfiguration
export def "delete-hook-configuration" [
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
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/orders/hook/config"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get hook configuration
#
# GET /api/orders/hook/config
# operationId: GetHookConfiguration
export def "get-hook-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-email: string # Customer email. (e.g. customer@mail.com)
  --page: string # Page number for result pagination. (e.g. 10)
  --per-page: string # Page quantity for result pagination. (e.g. 15)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/orders/hook/config"
    query: [{name: clientEmail, var: client_email}, {name: page, var: page}, {name: per_page, var: per_page}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    client_email: $client_email, page: $page, per_page: $per_page, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update hook configuration
#
# POST /api/orders/hook/config
# Returns: record<CurrentChange: string, Domain: string, LastChange: string, LastState: string, OrderId: string, Origin: record<Account: string, Key: string>, State: string>
# operationId: HookConfiguration
export def "hook-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  filter: record # shape: {disableSingleFire?: bool, expression?: string, status?: list<string>, type: string}
  hook: record # e.g. {headers: {key: value}, url: https://endpoint.example/path} — shape: {headers: record, url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/orders/hook/config"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: filter, var: filter}, {name: hook, var: hook}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: ORDERS_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: ORDERS_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, filter: $filter, hook: $hook
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
