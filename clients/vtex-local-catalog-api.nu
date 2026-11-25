# Auto-generated client for Catalog API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Catalog-API/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.CATALOG_API_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.CATALOG_API_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "CATALOG_API_TOKEN"
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
    get-gift-list: "record<IsPublic: bool, address: string, dateCreated: string, eventCity: string, eventDate: string, eventLocation: string, eventState: string, fileId: int, fileUrl: string, giftCardId: int, giftCardRechargeSkuId: int, giftListId: int, giftListMembers: table<clientId: string, giftListId: int, giftListMemberId: int, isActive: bool, isAdmin: bool, name: string, surname: string, text1: string, text2: string, title: string, userId: string>, giftListSkuIds: list<string>, giftListTypeId: int, giftListTypeName: string, isActive: bool, isAddressOk: bool, memberNames: string, message: string, name: string, profileSystemUserAddressName: string, profileSystemUserId: string, shipsToOwner: bool, telemarketingId: int, telemarketingObservation: string, urlFolder: string, userId: string, version: int>"
    review-rate-product: "float"
    post-api-catalog-pvt-attachment: "record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string>"
    get-api-catalog-pvt-attachment-attachmentid: "record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string>"
    put-api-catalog-pvt-attachment-attachmentid: "record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string>"
    get-api-catalog-pvt-attachments: "record<Data: table<Domains: list, Id: int, IsActive: bool, IsRequired: bool, Name: string>, Page: int, Size: int, TotalPage: int, TotalRows: int>"
    post-api-catalog-pvt-brand: "record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string>"
    get-api-catalog-pvt-brand-brand-id: "record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string>"
    put-api-catalog-pvt-brand-brand-id: "record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string>"
    post-api-catalog-pvt-category: "record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string>"
    get-api-catalog-pvt-category-category-id: "record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string>"
    put-api-catalog-pvt-category-category-id: "record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string>"
    post-api-catalog-pvt-collection: "record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string>"
    get-api-catalog-pvt-collection-collection-id: "record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string>"
    put-api-catalog-pvt-collection-collection-id: "record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string>"
    get-api-catalog-pvt-collection-collection-id-subcollection: "table<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string>"
    post-api-catalog-pvt-product: "record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>"
    get-productbyid: "record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>"
    put-api-catalog-pvt-product-product-id: "record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>"
    get-api-catalog-pvt-product-product-id-salespolicy: "table<ProductId: int, StoreId: int>"
    get-api-catalog-pvt-product-product-id-similarcategory: "table<CategoryId: int, ProductId: int>"
    post-api-catalog-pvt-product-product-id-similarcategory-category-id: "record<ProductId: int, StoreId: int>"
    get-product-specificationby-product-id: "table<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string>"
    post-api-catalog-pvt-product-product-id-specification: "record<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string>"
    put-api-catalog-pvt-product-product-id-specificationvalue: "table<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string>"
    post-api-catalog-pvt-skuattachment: "record<AttachmentId: int, Id: int, SkuId: int>"
    create-sku-complement: "table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int>"
    get-sku-complementby-sku-complement-id: "table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int>"
    post-api-catalog-pvt-skuservice: "record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string>"
    get-api-catalog-pvt-skuservice-sku-service-id: "record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string>"
    put-api-catalog-pvt-skuservice-sku-service-id: "record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string>"
    post-api-catalog-pvt-skuservicetype: "record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool>"
    get-api-catalog-pvt-skuservicetype-sku-service-type-id: "record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool>"
    put-api-catalog-pvt-skuservicetype-sku-service-type-id: "record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool>"
    post-api-catalog-pvt-skuservicetypeattachment: "record<AttachmentId: int, Id: int, SkuServiceTypeId: int>"
    post-api-catalog-pvt-skuservicevalue: "record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float>"
    get-api-catalog-pvt-skuservicevalue-sku-service-value-id: "record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float>"
    put-api-catalog-pvt-skuservicevalue-sku-service-value-id: "record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float>"
    post-api-catalog-pvt-specification: "record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int>"
    get-api-catalog-pvt-specification-nonstructured: "table<Id: int, SkuId: int, SpecificationName: string, SpecificationValue: string>"
    get-api-catalog-pvt-specification-nonstructured-id: "table<Id: int, SkuId: int, SpecificationName: string, SpecificationValue: string>"
    get-api-catalog-pvt-specification-specification-id: "record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int>"
    put-api-catalog-pvt-specification-specification-id: "record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int>"
    specification-group-insert2: "record<CategoryId: int, Id: int, Name: string, Position: int>"
    put-api-catalog-pvt-specificationgroup-group-id: "record<CategoryId: int, Id: int, Name: string, Position: int>"
    post-api-catalog-pvt-specificationvalue: "record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>"
    get-api-catalog-pvt-specificationvalue-specification-value-id: "record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>"
    put-api-catalog-pvt-specificationvalue-specification-value-id: "record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>"
    get-api-catalog-pvt-stockkeepingunit: "record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: float, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: string, WeightKg: float, Width: float>"
    post-api-catalog-pvt-stockkeepingunit: "record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, Ean: string, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float>"
    put-api-catalog-pvt-stockkeepingunit-copy-sku-idfrom-sku-idto-file: "table<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int>"
    sku: "record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float>"
    put-api-catalog-pvt-stockkeepingunit-sku-id: "record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float>"
    get-api-catalog-pvt-stockkeepingunit-sku-id-attachment: "table<AttachmentId: int, Id: int, SkuId: int>"
    get-sku-complementby-skuid: "table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int>"
    get-sku-complementsby-complement-type-id: "table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int>"
    get-api-catalog-pvt-stockkeepingunit-sku-id-ean: "list<string>"
    get-api-catalog-pvt-stockkeepingunit-sku-id-file: "table<ArchiveId: int, Id: int, IsMain: bool, Label: string, Name: string, SkuId: int>"
    post-api-catalog-pvt-stockkeepingunit-sku-id-file: "record<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int>"
    put-api-catalog-pvt-stockkeepingunit-sku-id-file-sku-file-id: "record<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int>"
    get-api-catalog-pvt-stockkeepingunit-sku-id-specification: "table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string>"
    post-api-catalog-pvt-stockkeepingunit-sku-id-specification: "record<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string>"
    put-api-catalog-pvt-stockkeepingunit-sku-id-specification: "table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string>"
    put-api-catalog-pvt-stockkeepingunit-sku-id-specificationvalue: "table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string>"
    get-api-catalog-pvt-stockkeepingunitkit: "record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int>"
    post-api-catalog-pvt-stockkeepingunitkit: "record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int>"
    get-api-catalog-pvt-stockkeepingunitkit-kit-id: "record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int>"
    post-api-catalog-pvt-subcollection: "record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string>"
    get-api-catalog-pvt-subcollection-sub-collection-id: "record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string>"
    put-api-catalog-pvt-subcollection-sub-collection-id: "record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string>"
    post-api-catalog-pvt-subcollection-sub-collection-id-brand: "record<BrandId: int, SubCollectionId: int>"
    post-api-catalog-pvt-subcollection-sub-collection-id-category: "record<CategoryId: int, SubCollectionId: int>"
    post-api-catalog-pvt-subcollection-sub-collection-id-stockkeepingunit: "record<SkuId: int, SubCollectionId: int>"
    post-api-catalog-pvt-supplier: "record<CellPhone: string, Cnpj: string, CorporateName: string, CorportePhone: string, Email: string, Id: int, IsActive: bool, Name: string, Phone: string, StateInscription: string>"
    put-api-catalog-pvt-supplier-supplier-id: "record<CellPhone: string, Cnpj: string, CorporateName: string, CorportePhone: string, Email: string, Id: int, IsActive: bool, Name: string, Phone: string, StateInscription: string>"
    category-tree: "table<MetaTagDescription: string, Title: string, children: list<record>, hasChildren: bool, id: int, name: string, url: string>"
    product-variations: "record<available: bool, dimensions: list<string>, dimensionsInputType: record, dimensionsMap: record, displayMode: string, name: string, productId: int, salesChannel: string, skus: table<available: bool, availablequantity: int, bestPrice: int, bestPriceFormated: string, cacheVersionUsedToCallCheckout: string, dimensions: record, image: string, installments: int, installmentsInsterestRate: int, installmentsValue: int, listPrice: int, listPriceFormated: string, measures: record, rewardValue: int, sellerId: string, sku: int, skuname: string, spotPrice: int, taxAsInt: int, taxFormated: string, unitMultiplier: float>>"
    sales-channelby-id: "record<ConditionRule: string, CountryCode: string, CultureInfo: string, CurrencyCode: string, CurrencyDecimalDigits: int, CurrencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, CurrencyLocale: int, CurrencySymbol: string, Id: int, IsActive: bool, Name: string, Origin: string, Position: int, ProductClusterId: int, TimeZone: string>"
    sku-idlistby-ref-idlist: "record"
    specifications-by-category-id: "table<CategoryId: int, FieldId: int, IsActive: bool, IsStockKeepingUnit: bool, Name: string>"
    specifications-tree-by-category-id: "table<CategoryId: int, FieldId: int, IsActive: bool, IsStockKeepingUnit: bool, Name: string>"
    specifications-field: "record<DefaultValue: string, Description: string, FieldGroupId: int, FieldGroupName: string, FieldId: int, FieldTypeId: int, FieldTypeName: string, FieldValueId: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int>"
    specifications-values-by-field-id: "table<FieldValueId: int, IsActive: bool, Position: int, Value: string>"
    specifications-group-get: "record<CategoryId: int, Id: int, Name: string, Position: int>"
    brand-list: "table<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string>"
    brand-list-per-page: "record<items: table<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string>, paging: record<page: int, pages: int, perPage: int, total: int>>"
    brand: "record<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string>"
    get-all-commercial-conditions: "table<Id: int, IsDefault: bool, Name: string>"
    get-commercial-conditions: "record<Id: int, IsDefault: bool, Name: string>"
    product-and-sku-ids: "record<data: record<\"Product ID\": list<any>>, range: record<from: int, to: int, total: int>>"
    productand-trade-policy: "record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, ListStoreId: list<any>, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>"
    productby-ref-id: "record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, ListStoreId: list<int>, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>"
    get-product-specification: "table<Id: int, Name: string, Value: list<string>>"
    sales-channel-list: "table<ConditionRule: string, CountryCode: string, CultureInfo: string, CurrencyCode: string, CurrencyDecimalDigits: int, CurrencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, CurrencyLocale: int, CurrencySymbol: string, Id: int, IsActive: bool, Name: string, Origin: string, Position: int, ProductClusterId: int, TimeZone: string>"
    create-seller: "record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>"
    update-seller: "record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>"
    seller-list: "record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>"
    get-sellerby-id: "record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>"
    get-sellersby-id: "record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>"
    get-sk-ucomplementsbytype: "record<ComplementSkuIds: list<int>, ParentSkuId: int, Type: string>"
    skulistby-product-id: "table<ActivateIfPossible: bool, CommercialConditionId: int, CubicWeight: float, DateUpdated: string, EstimatedDateArrival: string, FlagKitItensSellApart: bool, Height: float, Id: int, InternalNote: string, IsActive: bool, IsDynamicKit: string, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsPersisted: bool, IsRemoved: bool, IsTransported: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalId: int, ModalType: string, Name: string, Position: int, ProductId: int, RealHeight: float, RealLength: float, RealWeightKg: float, RealWidth: float, RefId: string, ReferenceStockKeepingUnitId: string, RewardValue: float, UnitMultiplier: float, WeightKg: float, Width: float, isKitOptimized: bool>"
    skuby-alternate-id: "record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, CategoriesFullPath: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsDirectCategoryActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, PositionsInClusters: record, ProductCategories: record, ProductCategoryIds: string, ProductClusterHighlights: record, ProductClusterNames: record, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float>"
    skuby-ean: "record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, CategoriesFullPath: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsDirectCategoryActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, PositionsInClusters: record, ProductCategories: record, ProductCategoryIds: string, ProductClusterHighlights: record, ProductClusterNames: record, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float>"
    sku-context: "record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, ProductCategories: record, ProductCategoryIds: string, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float>"
    sku-idby-ref-id: "string"
    listall-skui-ds: "list<int>"
    get-api-catalog-system-pvt-sku-stockkeepingunitidsbysaleschannel: "list<int>"
    get-sk-useller: "record<IsActive: bool, IsPersisted: bool, IsRemoved: bool, RequestedUpdateDate: string, SellerId: string, SellerStockKeepingUnitId: string, SkuSellerId: int, StockKeepingUnitId: int, UpdateDate: string>"
    specifications-insert-field: "int"
    specifications-insert-field-update: "int"
    specifications-insert-field-value: "record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>"
    specifications-update-field-value: "string"
    specifications-get-field-value: "record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>"
    specifications-group-listby-category: "table<CategoryId: int, Id: int, Name: string, Position: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-gift-list" "review-rate-product" "post-api-catalog-pvt-attachment" "delete-api-catalog-pvt-attachment-attachmentid" "get-api-catalog-pvt-attachment-attachmentid" "put-api-catalog-pvt-attachment-attachmentid" "get-api-catalog-pvt-attachments" "post-api-catalog-pvt-brand" "delete-api-catalog-pvt-brand-brand-id" "get-api-catalog-pvt-brand-brand-id" "put-api-catalog-pvt-brand-brand-id" "post-api-catalog-pvt-category" "get-api-catalog-pvt-category-category-id" "put-api-catalog-pvt-category-category-id" "post-api-catalog-pvt-collection" "post-create-collection" "get-all-inactive-collections" "get-importfileexample" "delete-api-catalog-pvt-collection-collection-id" "get-api-catalog-pvt-collection-collection-id" "put-api-catalog-pvt-collection-collection-id" "post-api-catalog-pvt-collection-collection-id-position" "get-productsfromacollection" "post-removeproductsbyimportfile" "post-addproductsbyimportfile" "get-api-catalog-pvt-collection-collection-id-subcollection" "post-api-catalog-pvt-product" "get-productbyid" "put-api-catalog-pvt-product-product-id" "get-api-catalog-pvt-product-product-id-salespolicy" "delete-api-catalog-pvt-product-product-id-salespolicy-tradepolicy-id" "post-api-catalog-pvt-product-product-id-salespolicy-tradepolicy-id" "get-api-catalog-pvt-product-product-id-similarcategory" "delete-api-catalog-pvt-product-product-id-similarcategory-category-id" "post-api-catalog-pvt-product-product-id-similarcategory-category-id" "delete-all-product-specifications" "get-product-specificationby-product-id" "post-api-catalog-pvt-product-product-id-specification" "deletea-product-specification" "put-api-catalog-pvt-product-product-id-specificationvalue" "delete-api-catalog-pvt-skuattachment" "post-api-catalog-pvt-skuattachment" "delete-api-catalog-pvt-skuattachment-sku-attachment-association-id" "create-sku-complement" "delete-sku-complementby-sku-complement-id" "get-sku-complementby-sku-complement-id" "post-api-catalog-pvt-skuservice" "delete-api-catalog-pvt-skuservice-sku-service-id" "get-api-catalog-pvt-skuservice-sku-service-id" "put-api-catalog-pvt-skuservice-sku-service-id" "post-api-catalog-pvt-skuservicetype" "delete-api-catalog-pvt-skuservicetype-sku-service-type-id" "get-api-catalog-pvt-skuservicetype-sku-service-type-id" "put-api-catalog-pvt-skuservicetype-sku-service-type-id" "delete-api-catalog-pvt-skuservicetypeattachment" "post-api-catalog-pvt-skuservicetypeattachment" "delete-api-catalog-pvt-skuservicetypeattachment-sku-service-type-attachment-id" "post-api-catalog-pvt-skuservicevalue" "delete-api-catalog-pvt-skuservicevalue-sku-service-value-id" "get-api-catalog-pvt-skuservicevalue-sku-service-value-id" "put-api-catalog-pvt-skuservicevalue-sku-service-value-id" "post-api-catalog-pvt-specification" "delete-api-catalog-pvt-specification-nonstructured" "get-api-catalog-pvt-specification-nonstructured" "delete-api-catalog-pvt-specification-nonstructured-id" "get-api-catalog-pvt-specification-nonstructured-id" "get-api-catalog-pvt-specification-specification-id" "put-api-catalog-pvt-specification-specification-id" "specification-group-insert2" "put-api-catalog-pvt-specificationgroup-group-id" "post-api-catalog-pvt-specificationvalue" "get-api-catalog-pvt-specificationvalue-specification-value-id" "put-api-catalog-pvt-specificationvalue-specification-value-id" "get-api-catalog-pvt-stockkeepingunit" "post-api-catalog-pvt-stockkeepingunit" "put-api-catalog-pvt-stockkeepingunit-copy-sku-idfrom-sku-idto-file" "delete-api-catalog-pvt-stockkeepingunit-disassociate-sku-id-file-sku-file-id" "sku" "put-api-catalog-pvt-stockkeepingunit-sku-id" "get-api-catalog-pvt-stockkeepingunit-sku-id-attachment" "get-sku-complementby-skuid" "get-sku-complementsby-complement-type-id" "delete-api-catalog-pvt-stockkeepingunit-sku-id-ean" "get-api-catalog-pvt-stockkeepingunit-sku-id-ean" "delete-api-catalog-pvt-stockkeepingunit-sku-id-ean-ean" "post-api-catalog-pvt-stockkeepingunit-sku-id-ean-ean" "delete-api-catalog-pvt-stockkeepingunit-sku-id-file" "get-api-catalog-pvt-stockkeepingunit-sku-id-file" "post-api-catalog-pvt-stockkeepingunit-sku-id-file" "delete-api-catalog-pvt-stockkeepingunit-sku-id-file-sku-file-id" "put-api-catalog-pvt-stockkeepingunit-sku-id-file-sku-file-id" "delete-api-catalog-pvt-stockkeepingunit-sku-id-specification" "get-api-catalog-pvt-stockkeepingunit-sku-id-specification" "post-api-catalog-pvt-stockkeepingunit-sku-id-specification" "put-api-catalog-pvt-stockkeepingunit-sku-id-specification" "delete-api-catalog-pvt-stockkeepingunit-sku-id-specification-specification-id" "put-api-catalog-pvt-stockkeepingunit-sku-id-specificationvalue" "delete-api-catalog-pvt-stockkeepingunitkit" "get-api-catalog-pvt-stockkeepingunitkit" "post-api-catalog-pvt-stockkeepingunitkit" "delete-api-catalog-pvt-stockkeepingunitkit-kit-id" "get-api-catalog-pvt-stockkeepingunitkit-kit-id" "post-api-catalog-pvt-subcollection" "delete-api-catalog-pvt-subcollection-sub-collection-id" "get-api-catalog-pvt-subcollection-sub-collection-id" "put-api-catalog-pvt-subcollection-sub-collection-id" "post-api-catalog-pvt-subcollection-sub-collection-id-brand" "delete-api-catalog-pvt-subcollection-sub-collection-id-brand-brand-id" "delete-api-catalog-pvt-subcollection-sub-collection-id-brand-category-id" "post-api-catalog-pvt-subcollection-sub-collection-id-category" "post-api-catalog-pvt-subcollection-sub-collection-id-stockkeepingunit" "delete-api-catalog-pvt-subcollection-sub-collection-id-stockkeepingunit-sku-id" "post-api-catalog-pvt-supplier" "delete-api-catalog-pvt-supplier-supplier-id" "put-api-catalog-pvt-supplier-supplier-id" "category-tree" "product-variations" "sales-channelby-id" "sku-idlistby-ref-idlist" "specifications-by-category-id" "specifications-tree-by-category-id" "specifications-field" "specifications-values-by-field-id" "specifications-group-get" "brand-list" "brand-list-per-page" "brand" "get-all-collections" "get-collectionsbyseachterms" "get-all-commercial-conditions" "get-commercial-conditions" "indexed-info" "product-and-sku-ids" "productand-trade-policy" "productby-ref-id" "get-product-specification" "update-product-specification" "sales-channel-list" "create-seller" "update-seller" "seller-list" "get-sellerby-id" "get-sellersby-id" "associateattachmentsto-sku" "get-sk-ucomplementsbytype" "skulistby-product-id" "skuby-alternate-id" "skuby-ean" "sku-context" "sku-idby-ref-id" "listall-skui-ds" "get-api-catalog-system-pvt-sku-stockkeepingunitidsbysaleschannel" "post-api-catalog-system-pvt-skuseller-changenotification-seller-id-seller-sku-id" "change-notification" "delete-sk-usellerassociation" "get-sk-useller" "specifications-insert-field" "specifications-insert-field-update" "specifications-insert-field-value" "specifications-update-field-value" "specifications-get-field-value" "specifications-group-listby-category" "commands"] | sort) } | get name | first)
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

# Get Gift List
#
# GET /api/addon/pvt/giftlist/get/{listId}
# Returns: record<IsPublic: bool, address: string, dateCreated: string, eventCity: string, eventDate: string, eventLocation: string, eventState: string, fileId: int, fileUrl: string, giftCardId: int, giftCardRechargeSkuId: int, giftListId: int, giftListMembers: table<clientId: string, giftListId: int, giftListMemberId: int, isActive: bool, isAdmin: bool, name: string, surname: string, text1: string, text2: string, title: string, userId: string>, giftListSkuIds: list<string>, giftListTypeId: int, giftListTypeName: string, isActive: bool, isAddressOk: bool, memberNames: string, message: string, name: string, profileSystemUserAddressName: string, profileSystemUserId: string, shipsToOwner: bool, telemarketingId: int, telemarketingObservation: string, urlFolder: string, userId: string, version: int>
# operationId: GetGiftList
export def "get-gift-list" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/addon/pvt/giftlist/get/{listId}"
    path_params: [{name: listId, var: list_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    list_id: $list_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product Review Rate by Product ID
#
# GET /api/addon/pvt/review/GetProductRate/{productId}
# Returns: float
# operationId: ReviewRateProduct
export def "review-rate-product" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/addon/pvt/review/GetProductRate/{productId}"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create attachment
#
# POST /api/catalog/pvt/attachment
# Returns: record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string>
export def "post-api-catalog-pvt-attachment" [
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
  domains: list # List of characteristics related to the attachment. — item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
  --is-active: oneof<nothing, bool> # Defines if the attachment is active or not. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the attachment is required or not. (e.g. false)
  name: string # Attachment Name. (e.g. Shirt customization)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/attachment"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Domains, var: domains}, {name: IsActive, var: is_active, required: true}, {name: IsRequired, var: is_required, required: true}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, domains: $domains, is_active: $is_active, is_required: $is_required, name: $name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attachment
#
# DELETE /api/catalog/pvt/attachment/{attachmentid}
export def "delete-api-catalog-pvt-attachment-attachmentid" [
  attachmentid: string
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
    method: delete
    path: "/api/catalog/pvt/attachment/{attachmentid}"
    path_params: [{name: attachmentid, var: attachmentid}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    attachmentid: $attachmentid, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment
#
# GET /api/catalog/pvt/attachment/{attachmentid}
# Returns: record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string>
export def "get-api-catalog-pvt-attachment-attachmentid" [
  attachmentid: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/attachment/{attachmentid}"
    path_params: [{name: attachmentid, var: attachmentid}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    attachmentid: $attachmentid, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update attachment
#
# PUT /api/catalog/pvt/attachment/{attachmentid}
# Returns: record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string>
export def "put-api-catalog-pvt-attachment-attachmentid" [
  attachmentid: string
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
  domains: list # List of characteristics related to the attachment. — item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
  --is-active: oneof<nothing, bool> # Defines if the attachment is active or not. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the attachment is required or not. (e.g. false)
  name: string # Attachment Name. (e.g. Shirt customization)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/attachment/{attachmentid}"
    path_params: [{name: attachmentid, var: attachmentid}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Domains, var: domains}, {name: IsActive, var: is_active, required: true}, {name: IsRequired, var: is_required, required: true}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    attachmentid: $attachmentid, content_type: $content_type, hdr_accept: $hdr_accept, domains: $domains, is_active: $is_active, is_required: $is_required, name: $name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all attachments
#
# GET /api/catalog/pvt/attachments
# Returns: record<Data: table<Domains: list, Id: int, IsActive: bool, IsRequired: bool, Name: string>, Page: int, Size: int, TotalPage: int, TotalRows: int>
export def "get-api-catalog-pvt-attachments" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/attachments"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Brand
#
# POST /api/catalog/pvt/brand
# Returns: record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string>
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
export def "post-api-catalog-pvt-brand" [
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
  --active: oneof<nothing, bool> # Defines if the brand is active (`true`) or not (`false`). (e.g. true)
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  id: int # Brand's unique numerical identifier. (e.g. 2000003)
  --keywords: string # Store Framework - Deprecated. Legacy CMS Portal - Alternative search terms that will lead to the specific brand. The user can find the desired brand even when misspelling it. Used especially when words are of foreign origin and have a distinct spelling that is transcribed into a generic one, or when small spelling mistakes occur. (e.g. adidas)
  --link-id: string # Brand page slug. Only lowercase letters and hyphens (`-`) are allowed. (nullable, e.g. adidas-sports)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --menu-home: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - Defines if the Brand appears in the Department Menu control (`<vtex.cmc:departmentNavigator/>`). (e.g. true)
  name: string # Brand name. (e.g. Adidas)
  --score: int # Store Framework - Deprecated Legacy CMS Portal - Value used to set the priority on the search result page. (nullable, e.g. 10)
  --site-title: string # Meta Title for the Brand page. (e.g. Adidas)
  --text: string # Meta Description for the Brand page. A brief description of the brand, displayed by search engines. Since search engines can only display less than 150 characters, we recommend not exceeding this character limit when creating the description. (e.g. Adidas)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/brand"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Active, var: active}, {name: AdWordsRemarketingCode, var: ad_words_remarketing_code}, {name: Id, var: id}, {name: Keywords, var: keywords}, {name: LinkId, var: link_id}, {name: LomadeeCampaignCode, var: lomadee_campaign_code}, {name: MenuHome, var: menu_home}, {name: Name, var: name}, {name: Score, var: score}, {name: SiteTitle, var: site_title}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, active: $active, ad_words_remarketing_code: $ad_words_remarketing_code, id: $id, keywords: $keywords, link_id: $link_id, lomadee_campaign_code: $lomadee_campaign_code, menu_home: $menu_home, name: $name, score: $score, site_title: $site_title, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Brand
#
# DELETE /api/catalog/pvt/brand/{brandId}
export def "delete-api-catalog-pvt-brand-brand-id" [
  brand_id: string
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
    method: delete
    path: "/api/catalog/pvt/brand/{brandId}"
    path_params: [{name: brandId, var: brand_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    brand_id: $brand_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Brand and context
#
# GET /api/catalog/pvt/brand/{brandId}
# Returns: record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string>
export def "get-api-catalog-pvt-brand-brand-id" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/brand/{brandId}"
    path_params: [{name: brandId, var: brand_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    brand_id: $brand_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Brand
#
# PUT /api/catalog/pvt/brand/{brandId}
# Returns: record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string>
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
export def "put-api-catalog-pvt-brand-brand-id" [
  brand_id: string
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
  --active: oneof<nothing, bool> # Defines if the brand is active (`true`) or not (`false`). (e.g. true)
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  id: int # Brand's unique numerical identifier. (e.g. 2000003)
  --keywords: string # Store Framework - Deprecated. Legacy CMS Portal - Alternative search terms that will lead to the specific brand. The user can find the desired brand even when misspelling it. Used especially when words are of foreign origin and have a distinct spelling that is transcribed into a generic one, or when small spelling mistakes occur. (e.g. adidas)
  --link-id: string # Brand page slug. Only lowercase letters and hyphens (`-`) are allowed. (nullable, e.g. adidas-sports)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --menu-home: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - Defines if the Brand appears in the Department Menu control (`<vtex.cmc:departmentNavigator/>`). (e.g. true)
  name: string # Brand name. (e.g. Adidas)
  --score: int # Store Framework - Deprecated Legacy CMS Portal - Value used to set the priority on the search result page. (nullable, e.g. 10)
  --site-title: string # Meta Title for the Brand page. (e.g. Adidas)
  --text: string # Meta Description for the Brand page. A brief description of the brand, displayed by search engines. Since search engines can only display less than 150 characters, we recommend not exceeding this character limit when creating the description. (e.g. Adidas)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/brand/{brandId}"
    path_params: [{name: brandId, var: brand_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Active, var: active}, {name: AdWordsRemarketingCode, var: ad_words_remarketing_code}, {name: Id, var: id}, {name: Keywords, var: keywords}, {name: LinkId, var: link_id}, {name: LomadeeCampaignCode, var: lomadee_campaign_code}, {name: MenuHome, var: menu_home}, {name: Name, var: name}, {name: Score, var: score}, {name: SiteTitle, var: site_title}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    brand_id: $brand_id, content_type: $content_type, hdr_accept: $hdr_accept, active: $active, ad_words_remarketing_code: $ad_words_remarketing_code, id: $id, keywords: $keywords, link_id: $link_id, lomadee_campaign_code: $lomadee_campaign_code, menu_home: $menu_home, name: $name, score: $score, site_title: $site_title, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Category
#
# POST /api/catalog/pvt/category
# Returns: record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string>
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
export def "post-api-catalog-pvt-category" [
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
  --active-store-front-link: oneof<nothing, bool> # If true, the Category link becomes active in store. (e.g. true)
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, nullable, e.g. Sale)
  description: string # Text used in meta description tag for Category page. (e.g. Discover our range of home appliances. Find smart vacuums, kitchen and laundry appliances to suit your needs. Order online now.)
  --father-category-id: int # ID of the parent category, apply in case of category and subcategory. (nullable, e.g. 2)
  global_category_id: int # Google Global Category ID. (e.g. 222)
  --id: int # Category unique identifier. If not informed, it will be automatically generated by VTEX. (e.g. 1)
  --is-active: oneof<nothing, bool> # If true, the Category page becomes available in store. (e.g. true)
  keywords: string # Substitute words for the Category. (e.g. Kitchen, Laundry, Appliances)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, nullable, e.g. Sale)
  name: string # Category name. (e.g. Home Appliances)
  --score: int # Score for search sorting order. (nullable, e.g. 3)
  --show-brand-filter: oneof<nothing, bool> # If true, the Category page displays a Brand filter. (e.g. true)
  --show-in-store-front: oneof<nothing, bool> # If true, the Category is shown in the top and side menu. (e.g. true)
  stock_keeping_unit_selection_mode: string # Defines how the SKU will be exhibited (e.g. SPECIFICATION)
  title: string # Text used in title tag for Category page. (e.g. Home Appliances)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/category"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveStoreFrontLink, var: active_store_front_link, required: true}, {name: AdWordsRemarketingCode, var: ad_words_remarketing_code}, {name: Description, var: description}, {name: FatherCategoryId, var: father_category_id}, {name: GlobalCategoryId, var: global_category_id}, {name: Id, var: id}, {name: IsActive, var: is_active, required: true}, {name: Keywords, var: keywords}, {name: LomadeeCampaignCode, var: lomadee_campaign_code}, {name: Name, var: name}, {name: Score, var: score}, {name: ShowBrandFilter, var: show_brand_filter, required: true}, {name: ShowInStoreFront, var: show_in_store_front, required: true}, {name: StockKeepingUnitSelectionMode, var: stock_keeping_unit_selection_mode}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, active_store_front_link: $active_store_front_link, ad_words_remarketing_code: $ad_words_remarketing_code, description: $description, father_category_id: $father_category_id, global_category_id: $global_category_id, id: $id, is_active: $is_active, keywords: $keywords, lomadee_campaign_code: $lomadee_campaign_code, name: $name, score: $score, show_brand_filter: $show_brand_filter, show_in_store_front: $show_in_store_front, stock_keeping_unit_selection_mode: $stock_keeping_unit_selection_mode, title: $title
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Category by ID
#
# GET /api/catalog/pvt/category/{categoryId}
# Returns: record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string>
export def "get-api-catalog-pvt-category-category-id" [
  category_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/category/{categoryId}"
    path_params: [{name: categoryId, var: category_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    category_id: $category_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Category
#
# PUT /api/catalog/pvt/category/{categoryId}
# Returns: record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string>
export def "put-api-catalog-pvt-category-category-id" [
  category_id: int
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
  --active-store-front-link: oneof<nothing, bool> # If true, the Category link becomes active in store. (e.g. true)
  ad_words_remarketing_code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, e.g. Sale)
  description: string # Text used in meta description tag for Category page. (e.g. Discover our range of home appliances. Find smart vacuums, kitchen and laundry appliances to suit your needs. Order online now.)
  --father-category-id: int # ID of the parent category, apply in case of category and subcategory. (nullable, e.g. 2)
  global_category_id: int # Google Global Category ID. (e.g. 222)
  --is-active: oneof<nothing, bool> # If true, the Category page becomes available in store. (e.g. true)
  keywords: string # Substitute words for the Category. (e.g. Kitchen, Laundry, Appliances)
  lomadee_campaign_code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, e.g. Sale)
  name: string # Category name. (e.g. Home Appliances)
  score: int # Score for search sorting order. (e.g. 3)
  --show-brand-filter: oneof<nothing, bool> # If true, the Category page displays a Brand filter. (e.g. true)
  --show-in-store-front: oneof<nothing, bool> # If true, the Category is shown in the top and side menu. (e.g. true)
  stock_keeping_unit_selection_mode: string # Defines how the SKU will be exhibited (e.g. SPECIFICATION)
  title: string # Text used in title tag for Category page. (e.g. Home Appliances)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/category/{categoryId}"
    path_params: [{name: categoryId, var: category_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveStoreFrontLink, var: active_store_front_link, required: true}, {name: AdWordsRemarketingCode, var: ad_words_remarketing_code}, {name: Description, var: description}, {name: FatherCategoryId, var: father_category_id}, {name: GlobalCategoryId, var: global_category_id}, {name: IsActive, var: is_active, required: true}, {name: Keywords, var: keywords}, {name: LomadeeCampaignCode, var: lomadee_campaign_code}, {name: Name, var: name}, {name: Score, var: score}, {name: ShowBrandFilter, var: show_brand_filter, required: true}, {name: ShowInStoreFront, var: show_in_store_front, required: true}, {name: StockKeepingUnitSelectionMode, var: stock_keeping_unit_selection_mode}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    category_id: $category_id, content_type: $content_type, hdr_accept: $hdr_accept, active_store_front_link: $active_store_front_link, ad_words_remarketing_code: $ad_words_remarketing_code, description: $description, father_category_id: $father_category_id, global_category_id: $global_category_id, is_active: $is_active, keywords: $keywords, lomadee_campaign_code: $lomadee_campaign_code, name: $name, score: $score, show_brand_filter: $show_brand_filter, show_in_store_front: $show_in_store_front, stock_keeping_unit_selection_mode: $stock_keeping_unit_selection_mode, title: $title
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Collection
#
# POST /api/catalog/pvt/collection
# Returns: record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string>
export def "post-api-catalog-pvt-collection" [
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
  date_from: string # Initial value date for the Collection. (e.g. 2017-09-27T10:47:00)
  date_to: string # Final value date for the Collection. (e.g. 2017-09-27T10:47:00)
  --highlight: oneof<nothing, bool> # Defines if the Collection is highlighted or not. (e.g. false)
  name: string # Collection Name. (e.g. Test)
  --searchable: oneof<nothing, bool> # Defines if the Collection is searchable or not. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/collection"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DateFrom, var: date_from}, {name: DateTo, var: date_to}, {name: Highlight, var: highlight, required: true}, {name: Name, var: name}, {name: Searchable, var: searchable, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, date_from: $date_from, date_to: $date_to, highlight: $highlight, name: $name, searchable: $searchable
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Collection
#
# POST /api/catalog/pvt/collection/
# operationId: POST-CreateCollection
export def "post-create-collection" [
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
  date_from: string # Collection start date and time. If a future date and time are set, the collection will have a scheduled status. (e.g. 2020-11-26T15:23:00)
  date_to: string # Collection end date and time. (e.g. 2069-11-26T15:23:00)
  description: string # Collection's description for internal use, with the collection's details. It will not be used for search engines. (e.g. HomeHalloween)
  --highlight: oneof<nothing, bool> # Option if you want the collection to highlight specific products using a tag. (e.g. false)
  name: string # Collection's Name. (e.g. Halloween costumes)
  --searchable: oneof<nothing, bool> # Option making the collection searchable in the store. (e.g. false)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/collection/"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DateFrom, var: date_from}, {name: DateTo, var: date_to}, {name: Description, var: description}, {name: Highlight, var: highlight, required: true}, {name: Name, var: name}, {name: Searchable, var: searchable, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, date_from: $date_from, date_to: $date_to, description: $description, highlight: $highlight, name: $name, searchable: $searchable
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Inactive Collections
#
# GET /api/catalog/pvt/collection/inactive
# operationId: GET-AllInactiveCollections
export def "get-all-inactive-collections" [
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
    path: "/api/catalog/pvt/collection/inactive"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import Collection file example
#
# GET /api/catalog/pvt/collection/stockkeepingunit/importfileexample
# operationId: GET-Importfileexample
export def "get-importfileexample" [
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
    path: "/api/catalog/pvt/collection/stockkeepingunit/importfileexample"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Collection
#
# DELETE /api/catalog/pvt/collection/{collectionId}
export def "delete-api-catalog-pvt-collection-collection-id" [
  collection_id: int
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
    method: delete
    path: "/api/catalog/pvt/collection/{collectionId}"
    path_params: [{name: collectionId, var: collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    collection_id: $collection_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Collection
#
# GET /api/catalog/pvt/collection/{collectionId}
# Returns: record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string>
export def "get-api-catalog-pvt-collection-collection-id" [
  collection_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/collection/{collectionId}"
    path_params: [{name: collectionId, var: collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    collection_id: $collection_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Collection
#
# PUT /api/catalog/pvt/collection/{collectionId}
# Returns: record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string>
export def "put-api-catalog-pvt-collection-collection-id" [
  collection_id: int
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
  date_from: string # Initial value date for the Collection. (e.g. 2017-09-27T10:47:00)
  date_to: string # Final value date for the Collection. (e.g. 2017-09-27T10:47:00)
  --highlight: oneof<nothing, bool> # Defines if the Collection is highlighted or not (e.g. false)
  name: string # Collection Name. (e.g. Test)
  --searchable: oneof<nothing, bool> # Defines if the Collection is searchable or not. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/collection/{collectionId}"
    path_params: [{name: collectionId, var: collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DateFrom, var: date_from}, {name: DateTo, var: date_to}, {name: Highlight, var: highlight, required: true}, {name: Name, var: name}, {name: Searchable, var: searchable, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    collection_id: $collection_id, content_type: $content_type, hdr_accept: $hdr_accept, date_from: $date_from, date_to: $date_to, highlight: $highlight, name: $name, searchable: $searchable
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reposition SKU on the Subcollection
#
# POST /api/catalog/pvt/collection/{collectionId}/position
export def "post-api-catalog-pvt-collection-collection-id-position" [
  collection_id: int
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
  position: int # SKU position. (e.g. 1)
  sku_id: int # SKU ID. (e.g. 1)
  sub_collection_id: int # Subcollection ID. (e.g. 17)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/collection/{collectionId}/position"
    path_params: [{name: collectionId, var: collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: position, var: position}, {name: skuId, var: sku_id}, {name: subCollectionId, var: sub_collection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    collection_id: $collection_id, content_type: $content_type, hdr_accept: $hdr_accept, position: $position, sku_id: $sku_id, sub_collection_id: $sub_collection_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get products from a collection
#
# GET /api/catalog/pvt/collection/{collectionId}/products
# operationId: GET-Productsfromacollection
export def "get-productsfromacollection" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (e.g. 2)
  --page-size: int # Number of the items of the page. (e.g. 15)
  --filter: string # Filter used to refine the Collection's products. (e.g. Pre launch)
  --active: oneof<nothing, bool> # Defines if the status of the product is active or not. (e.g. true)
  --visible: oneof<nothing, bool> # Defines if the product is visible on the store or not. (e.g. true)
  --category-id: int # Product's Category unique identifier. (e.g. 12)
  --brand-id: int # Product's Brand unique identifier. (e.g. 3)
  --supplier-id: int # Product's Supplier unique identifier. (e.g. 1)
  --sales-channel-id: int # Product's Trade Policy unique identifier. (e.g. 1)
  --release-from: string # Product past release date. (e.g. 2069-11-26T15:23:00)
  --release-to: string # Product future release date. (e.g. 2069-11-26T15:23:00)
  --specification-product: string # Product Specification Field Value. You must also fill in `SpecificationFieldId` to use this parameter. (e.g. M)
  --specification-field-id: int # Product Specification Field unique identifier. (e.g. 40)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/catalog/pvt/collection/{collectionId}/products"
    path_params: [{name: collectionId, var: collection_id}]
    query: [{name: page, var: page}, {name: pageSize, var: page_size}, {name: Filter, var: filter}, {name: Active, var: active}, {name: Visible, var: visible}, {name: CategoryId, var: category_id}, {name: BrandId, var: brand_id}, {name: SupplierId, var: supplier_id}, {name: SalesChannelId, var: sales_channel_id}, {name: ReleaseFrom, var: release_from}, {name: ReleaseTo, var: release_to}, {name: SpecificationProduct, var: specification_product}, {name: SpecificationFieldId, var: specification_field_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    collection_id: $collection_id, page: $page, page_size: $page_size, filter: $filter, active: $active, visible: $visible, category_id: $category_id, brand_id: $brand_id, supplier_id: $supplier_id, sales_channel_id: $sales_channel_id, release_from: $release_from, release_to: $release_to, specification_product: $specification_product, specification_field_id: $specification_field_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove products from Collection by imported file
#
# POST /api/catalog/pvt/collection/{collectionId}/stockkeepingunit/importexclude
# operationId: POST-Removeproductsbyimportfile
export def "post-removeproductsbyimportfile" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: multipart/form-data)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --file: any # XLS file with information about products to be added to a Collection. The file must be an imported template from [Import Collection file example](https://developers.vtex.com/vtex-developer-docs/reference/get-importfileexample) endpoint. (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/collection/{collectionId}/stockkeepingunit/importexclude"
    path_params: [{name: collectionId, var: collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "multipart/form-data"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    collection_id: $collection_id, content_type: $content_type, hdr_accept: $hdr_accept, file: $file
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add products to Collection by imported file
#
# POST /api/catalog/pvt/collection/{collectionId}/stockkeepingunit/importinsert
# operationId: POST-Addproductsbyimportfile
export def "post-addproductsbyimportfile" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: multipart/form-data)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --file: any # XLS file with information about products to be added to a Collection. The file must be an imported template from [Import Collection file example](https://developers.vtex.com/vtex-developer-docs/reference/get-importfileexample) endpoint. (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/collection/{collectionId}/stockkeepingunit/importinsert"
    path_params: [{name: collectionId, var: collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "multipart/form-data"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    collection_id: $collection_id, content_type: $content_type, hdr_accept: $hdr_accept, file: $file
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Subcollection by Collection ID
#
# GET /api/catalog/pvt/collection/{collectionId}/subcollection
# Returns: table<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string>
export def "get-api-catalog-pvt-collection-collection-id-subcollection" [
  collection_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/collection/{collectionId}/subcollection"
    path_params: [{name: collectionId, var: collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    collection_id: $collection_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Product with Category and Brand
#
# POST /api/catalog/pvt/product
# Returns: record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
@deprecated --flag supplier-id
export def "post-api-catalog-pvt-product" [
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
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --brand-id: int # ID of an existing Brand that will be associated with this product. It is mandatory to use either this field or the `BrandName` field. (e.g. 12121219)
  --brand-name: string # Name of the brand that will be associated with this product. It is mandatory to use either this field or the `BrandId` field. If you wish to create a new brand, that is, in case the brand does not exist yet, use this field instead of `BrandId`. (e.g. Sample Brand)
  --category-id: int # ID of an existing Category that will be associated with this product. It is mandatory to use either this field or the `CategoryPath` field. (e.g. 2000090)
  --category-path: string # Path of categories associated with this product, from the highest level of category to the lowest level, separated by `/`. It is mandatory to use either this field or the `CategoryId` field. (e.g. Mens/Clothing/T-Shirts)
  --description: string # Product description. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  --description-short: string # Short product description. This information can be displayed on both the product page and the shelf, using the following controls: Store Framework: `$product.DescriptionShort`. Legacy CMS Portal: `<vtex.cmc:productDescriptionShort/>`. (e.g. The Nike Zoom Stefan Janoski is made with a premium leather.)
  --id: int # Product’s unique numerical identifier. If not informed, it will be automatically generated by VTEX. (e.g. 42)
  --is-active: oneof<nothing, bool> # Activate (`true`) or inactivate (`false`) product. (e.g. true)
  --is-visible: oneof<nothing, bool> # Shows (`true`) or hides (`false`) the product in search result and product pages, but the product can still be added to the shopping cart. Usually applicable for gifts. (e.g. true)
  --key-words: string # Store Framework: Deprecated. Legacy CMS Portal: Keywords or synonyms related to the product, separated by comma (`,`). "Television", for example, can have a substitute word like "TV". This field is important to make your searches more comprehensive. (e.g. Zoom,Stefan,Janoski)
  --link-id: string # Slug that will be used to build the product page URL. If it not informed, it will be generated according to the product's name replacing spaces and special characters by hyphens (`-`). (e.g. stefan-janoski-canvas-varsity-red)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --meta-tag-description: string # Brief description of the product for SEO. It is recommended not to exceed 150 characters. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  name: string # Product's name. Limited to 150 characters. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
  --ref-id: string # Product Reference Code. (e.g. sr_1_90)
  --release-date: string # Used to assist in the ordering of the search result of the site. Using the `O=OrderByReleaseDateDESC` query string, you can pull this value and show the display order by release date. This attribute is also used as a condition for dynamic collections. (e.g. 2019-01-01T00:00:00)
  --score: int # Value used to set the priority on the search result page. (e.g. 1)
  --show-without-stock: oneof<nothing, bool> # If `true`, activates the [Notify Me](https://help.vtex.com/en/tutorial/setting-up-the-notify-me-option--2VqVifQuf6Co2KG048Yu6e) option when the product is out of stock. (e.g. true)
  --supplier-id: int # DEPRECATED, nullable
  --tax-code: string # Product tax code, used for tax calculation. (e.g. 12345)
  --title: string # Product's Title tag. Limited to 150 characters. It is presented in the browser tab and corresponds to the title of the product page. This field is important for SEO. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/product"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AdWordsRemarketingCode, var: ad_words_remarketing_code}, {name: BrandId, var: brand_id}, {name: BrandName, var: brand_name}, {name: CategoryId, var: category_id}, {name: CategoryPath, var: category_path}, {name: Description, var: description}, {name: DescriptionShort, var: description_short}, {name: Id, var: id}, {name: IsActive, var: is_active}, {name: IsVisible, var: is_visible}, {name: KeyWords, var: key_words}, {name: LinkId, var: link_id}, {name: LomadeeCampaignCode, var: lomadee_campaign_code}, {name: MetaTagDescription, var: meta_tag_description}, {name: Name, var: name}, {name: RefId, var: ref_id}, {name: ReleaseDate, var: release_date}, {name: Score, var: score}, {name: ShowWithoutStock, var: show_without_stock}, {name: SupplierId, var: supplier_id}, {name: TaxCode, var: tax_code}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, ad_words_remarketing_code: $ad_words_remarketing_code, brand_id: $brand_id, brand_name: $brand_name, category_id: $category_id, category_path: $category_path, description: $description, description_short: $description_short, id: $id, is_active: $is_active, is_visible: $is_visible, key_words: $key_words, link_id: $link_id, lomadee_campaign_code: $lomadee_campaign_code, meta_tag_description: $meta_tag_description, name: $name, ref_id: $ref_id, release_date: $release_date, score: $score, show_without_stock: $show_without_stock, supplier_id: $supplier_id, tax_code: $tax_code, title: $title
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product by ID
#
# GET /api/catalog/pvt/product/{productId}
# Returns: record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>
# operationId: GetProductbyid
export def "get-productbyid" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/product/{productId}"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Product
#
# PUT /api/catalog/pvt/product/{productId}
# Returns: record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
@deprecated --flag supplier-id
export def "put-api-catalog-pvt-product-product-id" [
  product_id: int
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
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  brand_id: int # Brand ID associated with this product. (e.g. 12121219)
  category_id: int # Category ID associated with this product. (e.g. 2000090)
  --department-id: int # Department ID according to the product's category. (e.g. 2000089)
  --description: string # Product description. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  --description-short: string # Short product description. This information can be displayed on both the product page and the shelf, using the following controls: Store Framework: `$product.DescriptionShort`. Legacy CMS Portal: `<vtex.cmc:productDescriptionShort/>`. (e.g. The Nike Zoom Stefan Janoski is made with a premium leather.)
  --is-active: oneof<nothing, bool> # Activate (`true`) or inactivate (`false`) product. (e.g. true)
  --is-visible: oneof<nothing, bool> # Shows (`true`) or hides (`false`) the product in search result and product pages, but the product can still be added to the shopping cart. Usually applicable for gifts. (e.g. true)
  --key-words: string # Store Framework: Deprecated. Legacy CMS Portal: Keywords or synonyms related to the product, separated by comma (`,`). "Television", for example, can have a substitute word like "TV". This field is important to make your searches more comprehensive. (e.g. Zoom,Stefan,Janoski)
  --link-id: string # Slug that will be used to build the product page URL. If it not informed, it will be generated according to the product's name replacing spaces and special characters by hyphens (`-`). (e.g. stefan-janoski-canvas-varsity-red)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --meta-tag-description: string # Brief description of the product for SEO. It is recommended not to exceed 150 characters. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  name: string # Product's name. Limited to 150 characters. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
  --ref-id: string # Product Reference Code. (e.g. sr_1_90)
  --release-date: string # Used to assist in the ordering of the search result of the site. Using the `O=OrderByReleaseDateDESC` query string, you can pull this value and show the display order by release date. This attribute is also used as a condition for dynamic collections. (e.g. 2019-01-01T00:00:00)
  --score: int # Value used to set the priority on the search result page. (e.g. 1)
  --show-without-stock: oneof<nothing, bool> # If `true`, activates the [Notify Me](https://help.vtex.com/en/tutorial/setting-up-the-notify-me-option--2VqVifQuf6Co2KG048Yu6e) option when the product is out of stock. (e.g. true)
  --supplier-id: int # DEPRECATED, nullable
  --tax-code: string # Product tax code, used for tax calculation. (e.g. 12345)
  --title: string # Product's Title tag. Limited to 150 characters. It is presented in the browser tab and corresponds to the title of the product page. This field is important for SEO. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/product/{productId}"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AdWordsRemarketingCode, var: ad_words_remarketing_code}, {name: BrandId, var: brand_id}, {name: CategoryId, var: category_id}, {name: DepartmentId, var: department_id}, {name: Description, var: description}, {name: DescriptionShort, var: description_short}, {name: IsActive, var: is_active}, {name: IsVisible, var: is_visible}, {name: KeyWords, var: key_words}, {name: LinkId, var: link_id}, {name: LomadeeCampaignCode, var: lomadee_campaign_code}, {name: MetaTagDescription, var: meta_tag_description}, {name: Name, var: name}, {name: RefId, var: ref_id}, {name: ReleaseDate, var: release_date}, {name: Score, var: score}, {name: ShowWithoutStock, var: show_without_stock}, {name: SupplierId, var: supplier_id}, {name: TaxCode, var: tax_code}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept, ad_words_remarketing_code: $ad_words_remarketing_code, brand_id: $brand_id, category_id: $category_id, department_id: $department_id, description: $description, description_short: $description_short, is_active: $is_active, is_visible: $is_visible, key_words: $key_words, link_id: $link_id, lomadee_campaign_code: $lomadee_campaign_code, meta_tag_description: $meta_tag_description, name: $name, ref_id: $ref_id, release_date: $release_date, score: $score, show_without_stock: $show_without_stock, supplier_id: $supplier_id, tax_code: $tax_code, title: $title
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Trade Policies by Product ID
#
# GET /api/catalog/pvt/product/{productId}/salespolicy
# Returns: table<ProductId: int, StoreId: int>
export def "get-api-catalog-pvt-product-product-id-salespolicy" [
  product_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/product/{productId}/salespolicy"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Product from Trade Policy
#
# DELETE /api/catalog/pvt/product/{productId}/salespolicy/{tradepolicyId}
export def "delete-api-catalog-pvt-product-product-id-salespolicy-tradepolicy-id" [
  product_id: int
  tradepolicy_id: int
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
    method: delete
    path: "/api/catalog/pvt/product/{productId}/salespolicy/{tradepolicyId}"
    path_params: [{name: productId, var: product_id}, {name: tradepolicyId, var: tradepolicy_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, tradepolicy_id: $tradepolicy_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate Product with Trade Policy
#
# POST /api/catalog/pvt/product/{productId}/salespolicy/{tradepolicyId}
export def "post-api-catalog-pvt-product-product-id-salespolicy-tradepolicy-id" [
  product_id: int
  tradepolicy_id: int
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
    method: post
    path: "/api/catalog/pvt/product/{productId}/salespolicy/{tradepolicyId}"
    path_params: [{name: productId, var: product_id}, {name: tradepolicyId, var: tradepolicy_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, tradepolicy_id: $tradepolicy_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Similar Categories
#
# GET /api/catalog/pvt/product/{productId}/similarcategory/
# Returns: table<CategoryId: int, ProductId: int>
export def "get-api-catalog-pvt-product-product-id-similarcategory" [
  product_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/product/{productId}/similarcategory/"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Similar Category
#
# DELETE /api/catalog/pvt/product/{productId}/similarcategory/{categoryId}
export def "delete-api-catalog-pvt-product-product-id-similarcategory-category-id" [
  product_id: int
  category_id: int
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
    method: delete
    path: "/api/catalog/pvt/product/{productId}/similarcategory/{categoryId}"
    path_params: [{name: productId, var: product_id}, {name: categoryId, var: category_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, category_id: $category_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Similar Category
#
# POST /api/catalog/pvt/product/{productId}/similarcategory/{categoryId}
# Returns: record<ProductId: int, StoreId: int>
export def "post-api-catalog-pvt-product-product-id-similarcategory-category-id" [
  product_id: int
  category_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/catalog/pvt/product/{productId}/similarcategory/{categoryId}"
    path_params: [{name: productId, var: product_id}, {name: categoryId, var: category_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, category_id: $category_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all Product Specifications by Product ID
#
# DELETE /api/catalog/pvt/product/{productId}/specification
# operationId: DeleteAllProductSpecifications
export def "delete-all-product-specifications" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/product/{productId}/specification"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product Specification and its information by Product ID
#
# GET /api/catalog/pvt/product/{productId}/specification
# Returns: table<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string>
# operationId: GetProductSpecificationbyProductID
export def "get-product-specificationby-product-id" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/product/{productId}/specification"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate Product Specification
#
# POST /api/catalog/pvt/product/{productId}/specification
# Returns: record<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string>
export def "post-api-catalog-pvt-product-product-id-specification" [
  product_id: int
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
  field_id: int # Specification ID. (e.g. 19)
  --field-value-id: int # Specification Value ID. Mandatory for `FieldTypeId` `5`, `6` and `7`. Must not be used for any other field types (e.g. 12)
  --text: string # Value of specification. Only for `FieldTypeId` different from `5`, `6` and `7`. (e.g. Metal)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/product/{productId}/specification"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldId, var: field_id}, {name: FieldValueId, var: field_value_id}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept, field_id: $field_id, field_value_id: $field_value_id, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Product Specification
#
# DELETE /api/catalog/pvt/product/{productId}/specification/{specificationId}
# operationId: DeleteaProductSpecification
export def "deletea-product-specification" [
  product_id: int
  specification_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/product/{productId}/specification/{specificationId}"
    path_params: [{name: productId, var: product_id}, {name: specificationId, var: specification_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, specification_id: $specification_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate product specification using specification name and group name
#
# PUT /api/catalog/pvt/product/{productId}/specificationvalue
# Returns: table<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string>
export def "put-api-catalog-pvt-product-product-id-specificationvalue" [
  product_id: int
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
  field_name: string # Specification name. (e.g. Material)
  field_values: list<string> # Array of specification values. (e.g. [Cotton, Polyester])
  group_name: string # Group name. (e.g. Composition)
  --root-level-specification: oneof<nothing, bool> # Root level specification. (e.g. true)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/product/{productId}/specificationvalue"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldName, var: field_name}, {name: FieldValues, var: field_values}, {name: GroupName, var: group_name}, {name: RootLevelSpecification, var: root_level_specification, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept, field_name: $field_name, field_values: $field_values, group_name: $group_name, root_level_specification: $root_level_specification
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dissociate attachments and SKUs
#
# DELETE /api/catalog/pvt/skuattachment
export def "delete-api-catalog-pvt-skuattachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU ID. By using this query param, you can dissociate all the attachments from an SKU based on its SKU ID. (format: int32, e.g. 1)
  --attachment-id: int # Attachment ID. By using this query param, you can dissociate the given attachment from all previously associated SKUs. (format: int32, e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/skuattachment"
    query: [{name: skuId, var: sku_id}, {name: attachmentId, var: attachment_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, attachment_id: $attachment_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate SKU Attachment
#
# POST /api/catalog/pvt/skuattachment
# Returns: record<AttachmentId: int, Id: int, SkuId: int>
export def "post-api-catalog-pvt-skuattachment" [
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
  attachment_id: int # Attachment ID. (e.g. 1)
  sku_id: int # Unique identifier of an SKU. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/skuattachment"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AttachmentId, var: attachment_id}, {name: SkuId, var: sku_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, attachment_id: $attachment_id, sku_id: $sku_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU Attachment by Attachment Association ID
#
# DELETE /api/catalog/pvt/skuattachment/{skuAttachmentAssociationId}
export def "delete-api-catalog-pvt-skuattachment-sku-attachment-association-id" [
  sku_attachment_association_id: int
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
    method: delete
    path: "/api/catalog/pvt/skuattachment/{skuAttachmentAssociationId}"
    path_params: [{name: skuAttachmentAssociationId, var: sku_attachment_association_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_attachment_association_id: $sku_attachment_association_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SKU Complement
#
# POST /api/catalog/pvt/skucomplement
# Returns: table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int>
# operationId: CreateSKUComplement
export def "create-sku-complement" [
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
  complement_type_id: int # Complement Type ID. This represents the type of the complement. The possible values are: `1` for Accessory; `2` for Suggestion; `3` for Similar Product; `5` for Show Together. (e.g. 1)
  parent_sku_id: int # ID of the Parent SKU, where the Complement is inserted. (e.g. 1)
  sku_id: int # ID of the SKU which will be inserted as a Complement in the Parent SKU. (e.g. 1)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/skucomplement"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ComplementTypeId, var: complement_type_id}, {name: ParentSkuId, var: parent_sku_id}, {name: SkuId, var: sku_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, complement_type_id: $complement_type_id, parent_sku_id: $parent_sku_id, sku_id: $sku_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU Complement by SKU Complement ID
#
# DELETE /api/catalog/pvt/skucomplement/{skuComplementId}
# operationId: DeleteSKUComplementbySKUComplementID
export def "delete-sku-complementby-sku-complement-id" [
  sku_complement_id: int
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
    method: delete
    path: "/api/catalog/pvt/skucomplement/{skuComplementId}"
    path_params: [{name: skuComplementId, var: sku_complement_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_complement_id: $sku_complement_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Complement by SKU Complement ID
#
# GET /api/catalog/pvt/skucomplement/{skuComplementId}
# Returns: table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int>
# operationId: GetSKUComplementbySKUComplementID
export def "get-sku-complementby-sku-complement-id" [
  sku_complement_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/skucomplement/{skuComplementId}"
    path_params: [{name: skuComplementId, var: sku_complement_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_complement_id: $sku_complement_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate SKU Service
#
# POST /api/catalog/pvt/skuservice
# Returns: record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string>
export def "post-api-catalog-pvt-skuservice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --is-active: oneof<nothing, bool> # Defines if the SKU Service is active or not. (e.g. true)
  name: string # SKU Service Name. Maximum of 50 characters. (e.g. Engraving)
  sku_id: int # SKU ID. (e.g. 1)
  sku_service_type_id: int # SKU Service Type ID. (e.g. 1)
  sku_service_value_id: int # SKU Service Value ID. (e.g. 1)
  text: string # Internal description of the SKU Service. Maximum of 100 characters. (e.g. Name engraving additional service.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/skuservice"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IsActive, var: is_active, required: true}, {name: Name, var: name}, {name: SkuId, var: sku_id}, {name: SkuServiceTypeId, var: sku_service_type_id}, {name: SkuServiceValueId, var: sku_service_value_id}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, is_active: $is_active, name: $name, sku_id: $sku_id, sku_service_type_id: $sku_service_type_id, sku_service_value_id: $sku_service_value_id, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dissociate SKU Service
#
# DELETE /api/catalog/pvt/skuservice/{skuServiceId}
export def "delete-api-catalog-pvt-skuservice-sku-service-id" [
  sku_service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/skuservice/{skuServiceId}"
    path_params: [{name: skuServiceId, var: sku_service_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_id: $sku_service_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Service
#
# GET /api/catalog/pvt/skuservice/{skuServiceId}
# Returns: record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string>
export def "get-api-catalog-pvt-skuservice-sku-service-id" [
  sku_service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/skuservice/{skuServiceId}"
    path_params: [{name: skuServiceId, var: sku_service_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_id: $sku_service_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update SKU Service
#
# PUT /api/catalog/pvt/skuservice/{skuServiceId}
# Returns: record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string>
export def "put-api-catalog-pvt-skuservice-sku-service-id" [
  sku_service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --is-active: oneof<nothing, bool> # Defines if the SKU Service is active or not. (e.g. true)
  name: string # SKU Service Name. Maximum of 50 characters. (e.g. Test name)
  sku_id: int # SKU ID. (e.g. 1)
  sku_service_type_id: int # SKU Service Type ID. (e.g. 2)
  sku_service_value_id: int # SKU Service Value ID. (e.g. 1)
  text: string # Internal description for the SKU Service. Maximum of 100 characters. (e.g. Text)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/skuservice/{skuServiceId}"
    path_params: [{name: skuServiceId, var: sku_service_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IsActive, var: is_active, required: true}, {name: Name, var: name}, {name: SkuId, var: sku_id}, {name: SkuServiceTypeId, var: sku_service_type_id}, {name: SkuServiceValueId, var: sku_service_value_id}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_id: $sku_service_id, content_type: $content_type, hdr_accept: $hdr_accept, is_active: $is_active, name: $name, sku_id: $sku_id, sku_service_type_id: $sku_service_type_id, sku_service_value_id: $sku_service_value_id, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SKU Service Type
#
# POST /api/catalog/pvt/skuservicetype
# Returns: record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool>
@deprecated --flag show-on-product-front
export def "post-api-catalog-pvt-skuservicetype" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --is-active: oneof<nothing, bool> # Defines if the SKU Service Type is active or not. (default: true)
  --is-gift-card: oneof<nothing, bool> # Defines if the SKU Service Type is displayed as a Gift Card. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the SKU Service type is mandatory. (e.g. false)
  name: string # SKU Service Type Name. Maximum of 100 characters. (default: Test API Sku Services)
  --show-on-attachment-front: oneof<nothing, bool> # Defines if the SKU Service Type has an attachment. (e.g. false)
  --show-on-cart-front: oneof<nothing, bool> # Defines if the SKU Service Type is displayed on the cart screen. (e.g. false)
  --show-on-file-upload: oneof<nothing, bool> # Defines if the SKU Service Type can be associated with an attachment or not. (e.g. false)
  --show-on-product-front: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/skuservicetype"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IsActive, var: is_active, required: true}, {name: IsGiftCard, var: is_gift_card, required: true}, {name: IsRequired, var: is_required, required: true}, {name: Name, var: name}, {name: ShowOnAttachmentFront, var: show_on_attachment_front, required: true}, {name: ShowOnCartFront, var: show_on_cart_front, required: true}, {name: ShowOnFileUpload, var: show_on_file_upload, required: true}, {name: ShowOnProductFront, var: show_on_product_front, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, is_active: $is_active, is_gift_card: $is_gift_card, is_required: $is_required, name: $name, show_on_attachment_front: $show_on_attachment_front, show_on_cart_front: $show_on_cart_front, show_on_file_upload: $show_on_file_upload, show_on_product_front: $show_on_product_front
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU Service Type
#
# DELETE /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
export def "delete-api-catalog-pvt-skuservicetype-sku-service-type-id" [
  sku_service_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/skuservicetype/{skuServiceTypeId}"
    path_params: [{name: skuServiceTypeId, var: sku_service_type_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_type_id: $sku_service_type_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Service Type
#
# GET /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
# Returns: record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool>
export def "get-api-catalog-pvt-skuservicetype-sku-service-type-id" [
  sku_service_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/skuservicetype/{skuServiceTypeId}"
    path_params: [{name: skuServiceTypeId, var: sku_service_type_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_type_id: $sku_service_type_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update SKU Service Type
#
# PUT /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
# Returns: record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool>
@deprecated --flag show-on-product-front
export def "put-api-catalog-pvt-skuservicetype-sku-service-type-id" [
  sku_service_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --is-active: oneof<nothing, bool> # Defines if the SKU Service Type is active or not. (default: true)
  --is-gift-card: oneof<nothing, bool> # Defines if the SKU Service Type is displayed as a Gift Card. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the SKU Service type is mandatory. (e.g. false)
  name: string # SKU Service Type Name. Maximum of 100 characters. (default: Test API Sku Services)
  --show-on-attachment-front: oneof<nothing, bool> # Defines if the SKU Service Type has an attachment. (e.g. false)
  --show-on-cart-front: oneof<nothing, bool> # Defines if the SKU Service Type is displayed on the cart screen. (e.g. false)
  --show-on-file-upload: oneof<nothing, bool> # Defines if the SKU Service Type can be associated with an attachment or not. (e.g. false)
  --show-on-product-front: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/skuservicetype/{skuServiceTypeId}"
    path_params: [{name: skuServiceTypeId, var: sku_service_type_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IsActive, var: is_active, required: true}, {name: IsGiftCard, var: is_gift_card, required: true}, {name: IsRequired, var: is_required, required: true}, {name: Name, var: name}, {name: ShowOnAttachmentFront, var: show_on_attachment_front, required: true}, {name: ShowOnCartFront, var: show_on_cart_front, required: true}, {name: ShowOnFileUpload, var: show_on_file_upload, required: true}, {name: ShowOnProductFront, var: show_on_product_front, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_type_id: $sku_service_type_id, content_type: $content_type, hdr_accept: $hdr_accept, is_active: $is_active, is_gift_card: $is_gift_card, is_required: $is_required, name: $name, show_on_attachment_front: $show_on_attachment_front, show_on_cart_front: $show_on_cart_front, show_on_file_upload: $show_on_file_upload, show_on_product_front: $show_on_product_front
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dissociate Attachment by Attachment ID or SKU Service Type ID
#
# DELETE /api/catalog/pvt/skuservicetypeattachment
export def "delete-api-catalog-pvt-skuservicetypeattachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment-id: int # SKU Service Attachment unique identifier. (e.g. 1)
  --sku-service-type-id: int # SKU Service Type unique identifier. (e.g. 1)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/skuservicetypeattachment"
    query: [{name: attachmentId, var: attachment_id}, {name: skuServiceTypeId, var: sku_service_type_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    attachment_id: $attachment_id, sku_service_type_id: $sku_service_type_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate SKU Service Attachment
#
# POST /api/catalog/pvt/skuservicetypeattachment
# Returns: record<AttachmentId: int, Id: int, SkuServiceTypeId: int>
export def "post-api-catalog-pvt-skuservicetypeattachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  attachment_id: int # Attachment ID. (e.g. 1)
  sku_service_type_id: int # An explanation about the purpose of this instance. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/skuservicetypeattachment"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AttachmentId, var: attachment_id}, {name: SkuServiceTypeId, var: sku_service_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, attachment_id: $attachment_id, sku_service_type_id: $sku_service_type_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dissociate Attachment from SKU Service Type
#
# DELETE /api/catalog/pvt/skuservicetypeattachment/{skuServiceTypeAttachmentId}
export def "delete-api-catalog-pvt-skuservicetypeattachment-sku-service-type-attachment-id" [
  sku_service_type_attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/skuservicetypeattachment/{skuServiceTypeAttachmentId}"
    path_params: [{name: skuServiceTypeAttachmentId, var: sku_service_type_attachment_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_type_attachment_id: $sku_service_type_attachment_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SKU Service Value
#
# POST /api/catalog/pvt/skuservicevalue
# Returns: record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float>
export def "post-api-catalog-pvt-skuservicevalue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  cost: float # SKU Service Value cost. (e.g. 10.5)
  name: string # SKU Service Value name. Maximum of 100 characters. (e.g. Test ServiceValue API)
  sku_service_type_id: int # SKU Service Type ID. (e.g. 2)
  value: float # SKU Service Value value. (e.g. 10.5)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/skuservicevalue"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Cost, var: cost}, {name: Name, var: name}, {name: SkuServiceTypeId, var: sku_service_type_id}, {name: Value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, cost: $cost, name: $name, sku_service_type_id: $sku_service_type_id, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU Service Value
#
# DELETE /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
export def "delete-api-catalog-pvt-skuservicevalue-sku-service-value-id" [
  sku_service_value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/skuservicevalue/{skuServiceValueId}"
    path_params: [{name: skuServiceValueId, var: sku_service_value_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_value_id: $sku_service_value_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Service Value
#
# GET /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
# Returns: record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float>
export def "get-api-catalog-pvt-skuservicevalue-sku-service-value-id" [
  sku_service_value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/skuservicevalue/{skuServiceValueId}"
    path_params: [{name: skuServiceValueId, var: sku_service_value_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_value_id: $sku_service_value_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update SKU Service Value
#
# PUT /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
# Returns: record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float>
export def "put-api-catalog-pvt-skuservicevalue-sku-service-value-id" [
  sku_service_value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  cost: float # SKU Service Value cost. (e.g. 10.5)
  name: string # SKU Service Value name. Maximum of 100 characters. (e.g. Test ServiceValue API)
  sku_service_type_id: int # SKU Service Type ID. (e.g. 2)
  value: float # SKU Service Value value. (e.g. 10.5)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/skuservicevalue/{skuServiceValueId}"
    path_params: [{name: skuServiceValueId, var: sku_service_value_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Cost, var: cost}, {name: Name, var: name}, {name: SkuServiceTypeId, var: sku_service_type_id}, {name: Value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_service_value_id: $sku_service_value_id, content_type: $content_type, hdr_accept: $hdr_accept, cost: $cost, name: $name, sku_service_type_id: $sku_service_type_id, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Specification
#
# POST /api/catalog/pvt/specification
# Returns: record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int>
@deprecated --flag description
@deprecated --flag is-wizard
export def "post-api-catalog-pvt-specification" [
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
  --category-id: int # Category ID associated with this specification. (e.g. 1)
  --default-value: string # Specification default value. (e.g. Cotton)
  --description: string # DEPRECATED, nullable, e.g. Composition of the product.
  field_group_id: int # ID of the group of specifications that contains the new specification. (e.g. 22)
  field_type_id: int # Field Type ID can be `1 - Text`, `2 - Multi-Line Text`, `4 - Number`, `5 - Combo`, `6 - Radio`, `7 - Checkbox`, `8 - Indexed Text`, `9 - Indexed Multi-Line Text`. (e.g. 1)
  --is-active: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification. (e.g. true)
  --is-filter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar. (e.g. false)
  --is-on-product-details: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page. (e.g. true)
  --is-required: oneof<nothing, bool> # Makes the specification mandatory (`true`) or optional (`false`). (e.g. false)
  --is-side-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar. (e.g. false)
  --is-stock-keeping-unit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification. If `false`, it will be added as a product specification field. (e.g. false)
  --is-top-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu. (e.g. false)
  --is-wizard: oneof<nothing, bool> # DEPRECATED, nullable
  name: string # Specification name. (e.g. Material)
  --position: int # Store Framework - Deprecated. Legacy CMS Portal - This position number is used in ordering the specifications both in the navigation menu and in the specification listing on the product page. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/specification"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryId, var: category_id}, {name: DefaultValue, var: default_value}, {name: Description, var: description}, {name: FieldGroupId, var: field_group_id}, {name: FieldTypeId, var: field_type_id}, {name: IsActive, var: is_active}, {name: IsFilter, var: is_filter}, {name: IsOnProductDetails, var: is_on_product_details}, {name: IsRequired, var: is_required}, {name: IsSideMenuLinkActive, var: is_side_menu_link_active}, {name: IsStockKeepingUnit, var: is_stock_keeping_unit}, {name: IsTopMenuLinkActive, var: is_top_menu_link_active}, {name: IsWizard, var: is_wizard}, {name: Name, var: name}, {name: Position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, category_id: $category_id, default_value: $default_value, description: $description, field_group_id: $field_group_id, field_type_id: $field_type_id, is_active: $is_active, is_filter: $is_filter, is_on_product_details: $is_on_product_details, is_required: $is_required, is_side_menu_link_active: $is_side_menu_link_active, is_stock_keeping_unit: $is_stock_keeping_unit, is_top_menu_link_active: $is_top_menu_link_active, is_wizard: $is_wizard, name: $name, position: $position
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Non Structured Specification by SKU ID
#
# DELETE /api/catalog/pvt/specification/nonstructured
export def "delete-api-catalog-pvt-specification-nonstructured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU’s unique numerical identifier. (required, e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/specification/nonstructured"
    query: [{name: skuId, var: sku_id, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Non Structured Specification by SKU ID
#
# GET /api/catalog/pvt/specification/nonstructured
# Returns: table<Id: int, SkuId: int, SpecificationName: string, SpecificationValue: string>
export def "get-api-catalog-pvt-specification-nonstructured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU’s unique numerical identifier. (required, e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/specification/nonstructured"
    query: [{name: skuId, var: sku_id, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Non Structured Specification
#
# DELETE /api/catalog/pvt/specification/nonstructured/{Id}
export def "delete-api-catalog-pvt-specification-nonstructured-id" [
  id: int
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
    method: delete
    path: "/api/catalog/pvt/specification/nonstructured/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Non Structured Specification by ID
#
# GET /api/catalog/pvt/specification/nonstructured/{Id}
# Returns: table<Id: int, SkuId: int, SpecificationName: string, SpecificationValue: string>
export def "get-api-catalog-pvt-specification-nonstructured-id" [
  id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/specification/nonstructured/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specification
#
# GET /api/catalog/pvt/specification/{specificationId}
# Returns: record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int>
export def "get-api-catalog-pvt-specification-specification-id" [
  specification_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/specification/{specificationId}"
    path_params: [{name: specificationId, var: specification_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    specification_id: $specification_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Specification
#
# PUT /api/catalog/pvt/specification/{specificationId}
# Returns: record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int>
@deprecated --flag is-wizard
export def "put-api-catalog-pvt-specification-specification-id" [
  specification_id: int
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
  category_id: int # Specification Category ID. (e.g. 0)
  default_value: string # Specification Default Value. (e.g. Leather)
  description: string # Specification Description. (e.g. Composition of the product.)
  field_group_id: int # Numerical ID of the Group of Specifications that contains the new Specification. (e.g. 0)
  field_type_id: int # Field Type can be `1 - Text`, `2 - Multi-Line Text`, `4 - Number`, `5 - Combo`, `6 - Radio`, `7 - Checkbox`, `8 - Indexed Text`, `9 - Indexed Multi-Line Text`. (e.g. 1)
  --is-active: oneof<nothing, bool> # Defines if the Specification is active or not. (e.g. false)
  --is-filter: oneof<nothing, bool> # Defines if the Specification can be used as a Filter. (e.g. false)
  --is-on-product-details: oneof<nothing, bool> # Defines if the Specification will be shown on the Product screen in the specification area. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the Specification is required or not. (e.g. false)
  --is-side-menu-link-active: oneof<nothing, bool> # Defines if the Specification is shown in the side menu. (e.g. false)
  --is-stock-keeping-unit: oneof<nothing, bool> # Defines if the Specification is applied to a specific SKU. (e.g. false)
  --is-top-menu-link-active: oneof<nothing, bool> # Defines if the Specification is shown in the main menu of the site. (e.g. false)
  --is-wizard: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
  name: string # Specification Name. (e.g. Material)
  position: int # The current Specification's position in comparison to the other Specifications. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/specification/{specificationId}"
    path_params: [{name: specificationId, var: specification_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryId, var: category_id}, {name: DefaultValue, var: default_value}, {name: Description, var: description}, {name: FieldGroupId, var: field_group_id}, {name: FieldTypeId, var: field_type_id}, {name: IsActive, var: is_active, required: true}, {name: IsFilter, var: is_filter, required: true}, {name: IsOnProductDetails, var: is_on_product_details, required: true}, {name: IsRequired, var: is_required, required: true}, {name: IsSideMenuLinkActive, var: is_side_menu_link_active, required: true}, {name: IsStockKeepingUnit, var: is_stock_keeping_unit, required: true}, {name: IsTopMenuLinkActive, var: is_top_menu_link_active, required: true}, {name: IsWizard, var: is_wizard, required: true}, {name: Name, var: name}, {name: Position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    specification_id: $specification_id, content_type: $content_type, hdr_accept: $hdr_accept, category_id: $category_id, default_value: $default_value, description: $description, field_group_id: $field_group_id, field_type_id: $field_type_id, is_active: $is_active, is_filter: $is_filter, is_on_product_details: $is_on_product_details, is_required: $is_required, is_side_menu_link_active: $is_side_menu_link_active, is_stock_keeping_unit: $is_stock_keeping_unit, is_top_menu_link_active: $is_top_menu_link_active, is_wizard: $is_wizard, name: $name, position: $position
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Specification Group
#
# POST /api/catalog/pvt/specificationgroup
# Returns: record<CategoryId: int, Id: int, Name: string, Position: int>
# operationId: SpecificationGroupInsert2
export def "specification-group-insert2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  category_id: int # Category ID. (format: int32)
  name: string # Specification Group Name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/specificationgroup"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryId, var: category_id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, category_id: $category_id, name: $name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Specification Group
#
# PUT /api/catalog/pvt/specificationgroup/{groupId}
# Returns: record<CategoryId: int, Id: int, Name: string, Position: int>
export def "put-api-catalog-pvt-specificationgroup-group-id" [
  group_id: int
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
  category_id: int # Category ID where the Specification Group is contained. (e.g. 1)
  id: int # Specification Group ID. (format: int32, e.g. 24)
  name: string # Specification Group Name. (e.g. Sizes)
  position: int # Specification Group Position. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/specificationgroup/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryId, var: category_id}, {name: Id, var: id}, {name: Name, var: name}, {name: Position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    group_id: $group_id, content_type: $content_type, hdr_accept: $hdr_accept, category_id: $category_id, id: $id, name: $name, position: $position
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Specification Value
#
# POST /api/catalog/pvt/specificationvalue
# Returns: record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>
@deprecated --flag text
export def "post-api-catalog-pvt-specificationvalue" [
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
  field_id: int # Specification ID associated with this specification value. (e.g. 193)
  --is-active: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification value. (e.g. true)
  name: string # Specification Value name. (e.g. Metal)
  --position: int # The position of the value to be shown on product registration page (`/admin/Site/Produto.aspx`). (e.g. 1)
  --text: string # Specification Value Text. (DEPRECATED, nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/specificationvalue"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldId, var: field_id}, {name: IsActive, var: is_active}, {name: Name, var: name}, {name: Position, var: position}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, field_id: $field_id, is_active: $is_active, name: $name, position: $position, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specification Value
#
# GET /api/catalog/pvt/specificationvalue/{specificationValueId}
# Returns: record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>
export def "get-api-catalog-pvt-specificationvalue-specification-value-id" [
  specification_value_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/specificationvalue/{specificationValueId}"
    path_params: [{name: specificationValueId, var: specification_value_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    specification_value_id: $specification_value_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Specification Value
#
# PUT /api/catalog/pvt/specificationvalue/{specificationValueId}
# Returns: record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>
@deprecated --flag text
export def "put-api-catalog-pvt-specificationvalue-specification-value-id" [
  specification_value_id: int
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
  field_id: int # Specification ID associated with this specification value. (e.g. 193)
  --is-active: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification value. (e.g. true)
  name: string # Specification Value name. (e.g. Metal)
  --position: int # The position of the value to be shown on product registration page (`/admin/Site/Produto.aspx`). (e.g. 1)
  --text: string # Specification Value Text. (DEPRECATED, nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/specificationvalue/{specificationValueId}"
    path_params: [{name: specificationValueId, var: specification_value_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldId, var: field_id}, {name: IsActive, var: is_active}, {name: Name, var: name}, {name: Position, var: position}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    specification_value_id: $specification_value_id, content_type: $content_type, hdr_accept: $hdr_accept, field_id: $field_id, is_active: $is_active, name: $name, position: $position, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU by RefId
#
# GET /api/catalog/pvt/stockkeepingunit
# Returns: record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: float, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: string, WeightKg: float, Width: float>
export def "get-api-catalog-pvt-stockkeepingunit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref-id: string # SKU Reference ID. (required, e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunit"
    query: [{name: refId, var: ref_id, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    ref_id: $ref_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SKU
#
# POST /api/catalog/pvt/stockkeepingunit
# Returns: record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, Ean: string, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float>
export def "post-api-catalog-pvt-stockkeepingunit" [
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
  --activate-if-possible: oneof<nothing, bool> # When set to `true`, this attribute will automatically update the SKU as active once associated with an image or an active component. (e.g. true)
  --commercial-condition-id: int # Used to define SKU specific promotions or installment rules. In case of no specific condition, use `1` (default value). This field does not accept `0`. Find out more by reading [Registering a commercial condition](https://help.vtex.com/tutorial/registering-a-commercial-condition--tutorials_445). (e.g. 1)
  --creation-date: string # Date and time of the SKU's creation. (e.g. 2020-01-25T15:51:29.2614605)
  --cubic-weight: float # [Cubic weight](https://help.vtex.com/en/tutorial/understanding-the-cubic-weight-factor--tutorials_128). (e.g. 0.1667)
  --ean: string # EAN code. Required only if `RefId` is not informed, but can be used alongside `RefId` as well. (e.g. 8949461894984)
  --estimated-date-arrival: string # To add the product as pre-sale, enter the product estimated arrival date in [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) format. You must take into consideration both the launch date and the freight calculation for the arrival date. (nullable)
  --height: float # SKU real height. (e.g. 1)
  --id: int # SKU unique identifier. If not informed, it will be automatically generated by VTEX. (e.g. 1)
  --is-active: oneof<nothing, bool> # Shows if the SKU is active (`true`) or not (`false`). (e.g. false)
  --is-kit: oneof<nothing, bool> # Flag to set whether the product SKU is made up of one or more SKUs, thereby becoming a bundle. Must be enabled if you are adding a bundle. Once activated, the flag cannot be reverted. (e.g. false)
  --kit-itens-sell-apart: oneof<nothing, bool> # Defines if Kit components can be sold apart. (e.g. false)
  --length: float # SKU real length. (e.g. 1)
  --manufacturer-code: string # Provided by the manufacturers to identify their product. This field should be filled in if the product has a specific manufacturer’s code. (e.g. 123)
  --measurement-unit: string # Used only in cases when you need to convert the unit of measure for sale. If a product is sold in boxes for example, but customers want to buy per square meter (m²). In common cases, use `'un'`. (e.g. un)
  --modal-type: string # Links an unusual type of SKU to a carrier specialized in delivering it. This field should be filled in with the name of the modal (e.g. "Chemicals" or "Refrigerated products"). To learn more about this feature, read our articles [How the modal works](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125) and [Setting up modal for carriers](https://help.vtex.com/en/tutorial/configure-modal--3jhLqxuPhuiq24UoykCcqy). (nullable)
  name: string # SKU name, meaning the variation of the previously added product. For example: **Product** - _Fridge_, **SKU** - _110V_. (e.g. Size 10)
  packaged_height: float # Height used for shipping calculation. (e.g. 10)
  packaged_length: float # Length used for shipping calculation. (e.g. 10)
  packaged_weight_kg: int # Weight used for shipping calculation, in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 10)
  packaged_width: float # Width used for shipping calculation. (e.g. 10)
  product_id: int # ID of the Product associated with this SKU. (e.g. 42)
  --ref-id: string # Reference code used internally for organizational purposes. Must be unique. Required only if `Ean` is not informed, but can be used alongside `Ean` as well. (e.g. B096QW8Y8Z)
  --reward-value: float # Credit that the customer receives when finalizing an order of one specific SKU unit. By filling this field out with `1`, the customer gets U$ 1 credit on the site. (e.g. 1)
  --unit-multiplier: float # This is the multiple number of SKU. If the Multiplier is 5.0000, the product can be added in multiple quantities of 5, 10, 15, 20, onward. (e.g. 2)
  --videos: list<string> # Videos URLs (e.g. [https://www.youtube.com/])
  --weight-kg: float # Weight of the SKU in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 1)
  --width: float # SKU real width. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/stockkeepingunit"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivateIfPossible, var: activate_if_possible}, {name: CommercialConditionId, var: commercial_condition_id}, {name: CreationDate, var: creation_date}, {name: CubicWeight, var: cubic_weight}, {name: Ean, var: ean}, {name: EstimatedDateArrival, var: estimated_date_arrival}, {name: Height, var: height}, {name: Id, var: id}, {name: IsActive, var: is_active}, {name: IsKit, var: is_kit}, {name: KitItensSellApart, var: kit_itens_sell_apart}, {name: Length, var: length}, {name: ManufacturerCode, var: manufacturer_code}, {name: MeasurementUnit, var: measurement_unit}, {name: ModalType, var: modal_type}, {name: Name, var: name}, {name: PackagedHeight, var: packaged_height}, {name: PackagedLength, var: packaged_length}, {name: PackagedWeightKg, var: packaged_weight_kg}, {name: PackagedWidth, var: packaged_width}, {name: ProductId, var: product_id}, {name: RefId, var: ref_id}, {name: RewardValue, var: reward_value}, {name: UnitMultiplier, var: unit_multiplier}, {name: Videos, var: videos}, {name: WeightKg, var: weight_kg}, {name: Width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, activate_if_possible: $activate_if_possible, commercial_condition_id: $commercial_condition_id, creation_date: $creation_date, cubic_weight: $cubic_weight, ean: $ean, estimated_date_arrival: $estimated_date_arrival, height: $height, id: $id, is_active: $is_active, is_kit: $is_kit, kit_itens_sell_apart: $kit_itens_sell_apart, length: $length, manufacturer_code: $manufacturer_code, measurement_unit: $measurement_unit, modal_type: $modal_type, name: $name, packaged_height: $packaged_height, packaged_length: $packaged_length, packaged_weight_kg: $packaged_weight_kg, packaged_width: $packaged_width, product_id: $product_id, ref_id: $ref_id, reward_value: $reward_value, unit_multiplier: $unit_multiplier, videos: $videos, weight_kg: $weight_kg, width: $width
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy Files from an SKU to another SKU
#
# PUT /api/catalog/pvt/stockkeepingunit/copy/{skuIdfrom}/{skuIdto}/file/
# Returns: table<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int>
export def "put-api-catalog-pvt-stockkeepingunit-copy-sku-idfrom-sku-idto-file" [
  sku_idfrom: int
  sku_idto: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/api/catalog/pvt/stockkeepingunit/copy/{skuIdfrom}/{skuIdto}/file/"
    path_params: [{name: skuIdfrom, var: sku_idfrom}, {name: skuIdto, var: sku_idto}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_idfrom: $sku_idfrom, sku_idto: $sku_idto, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociate SKU File
#
# DELETE /api/catalog/pvt/stockkeepingunit/disassociate/{skuId}/file/{skuFileId}
export def "delete-api-catalog-pvt-stockkeepingunit-disassociate-sku-id-file-sku-file-id" [
  sku_id: int
  sku_file_id: int
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
    method: delete
    path: "/api/catalog/pvt/stockkeepingunit/disassociate/{skuId}/file/{skuFileId}"
    path_params: [{name: skuId, var: sku_id}, {name: skuFileId, var: sku_file_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, sku_file_id: $sku_file_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}
# Returns: record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float>
# operationId: Sku
export def "sku" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update SKU
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}
# Returns: record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float>
export def "put-api-catalog-pvt-stockkeepingunit-sku-id" [
  sku_id: int
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
  --activate-if-possible: oneof<nothing, bool> # When set to `true`, this attribute will automatically update the SKU as active once associated with an image or an active component. (e.g. false)
  --commercial-condition-id: int # Used to define SKU specific promotions or installment rules. In case of no specific condition, use `1` (default value). This field does not accept `0`. Find out more by reading [Registering a commercial condition](https://help.vtex.com/tutorial/registering-a-commercial-condition--tutorials_445). (e.g. 1)
  --creation-date: string # Date and time of the SKU's creation. (e.g. 2020-01-25T15:51:00)
  --cubic-weight: float # [Cubic weight](https://help.vtex.com/en/tutorial/understanding-the-cubic-weight-factor--tutorials_128). (e.g. 0.1667)
  --estimated-date-arrival: string # To add the product as pre-sale, enter the product estimated arrival date in [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) format. You must take into consideration both the launch date and the freight calculation for the arrival date. (nullable)
  --height: float # SKU real height. (e.g. 1)
  --is-active: oneof<nothing, bool> # Shows if the SKU is active (`true`) or not (`false`). (e.g. false)
  --is-kit: oneof<nothing, bool> # Flag to set whether the product SKU is made up of one or more SKUs, thereby becoming a bundle. Must be enabled if you are adding a bundle. Once activated, the flag cannot be reverted. (e.g. false)
  --kit-itens-sell-apart: oneof<nothing, bool> # Defines if Kit components can be sold apart. (e.g. false)
  --length: float # SKU real length. (e.g. 1)
  --manufacturer-code: string # Provided by the manufacturers to identify their product. This field should be filled in if the product has a specific manufacturer’s code. (e.g. 123)
  --measurement-unit: string # Used only in cases when you need to convert the unit of measure for sale. If a product is sold in boxes for example, but customers want to buy per square meter (m²). In common cases, use `'un'`. (e.g. un)
  --modal-type: string # Links an unusual type of SKU to a carrier specialized in delivering it. This field should be filled in with the name of the modal (e.g. "Chemicals" or "Refrigerated products"). To learn more about this feature, read our articles [How the modal works](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125) and [Setting up modal for carriers](https://help.vtex.com/en/tutorial/configure-modal--3jhLqxuPhuiq24UoykCcqy). (nullable)
  name: string # SKU name, meaning the variation of the previously added product. For example: **Product** - _Fridge_, **SKU** - _110V_. (e.g. Size 10)
  packaged_height: float # Height used for shipping calculation. (e.g. 10)
  packaged_length: float # Length used for shipping calculation. (e.g. 10)
  packaged_weight_kg: int # Weight used for shipping calculation, in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 10)
  packaged_width: float # Width used for shipping calculation. (e.g. 10)
  product_id: int # ID of the Product associated with this SKU. (e.g. 42)
  --ref-id: string # Reference code used internally for organizational purposes. Must be unique. It is not required only if EAN code already exists. If not, this field must be provided. (e.g. B096QW8Y8Z)
  --reward-value: float # Credit that the customer receives when finalizing an order of one specific SKU unit. By filling this field out with `1`, the customer gets U$ 1 credit on the site. (e.g. 1)
  --unit-multiplier: float # This is the multiple number of SKU. If the Multiplier is 5.0000, the product can be added in multiple quantities of 5, 10, 15, 20, onward. (e.g. 2)
  --videos: list<string> # Videos URLs (e.g. [https://www.youtube.com/])
  --weight-kg: float # Weight of the SKU in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 1)
  --width: float # SKU real width. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivateIfPossible, var: activate_if_possible}, {name: CommercialConditionId, var: commercial_condition_id}, {name: CreationDate, var: creation_date}, {name: CubicWeight, var: cubic_weight}, {name: EstimatedDateArrival, var: estimated_date_arrival}, {name: Height, var: height}, {name: IsActive, var: is_active}, {name: IsKit, var: is_kit}, {name: KitItensSellApart, var: kit_itens_sell_apart}, {name: Length, var: length}, {name: ManufacturerCode, var: manufacturer_code}, {name: MeasurementUnit, var: measurement_unit}, {name: ModalType, var: modal_type}, {name: Name, var: name}, {name: PackagedHeight, var: packaged_height}, {name: PackagedLength, var: packaged_length}, {name: PackagedWeightKg, var: packaged_weight_kg}, {name: PackagedWidth, var: packaged_width}, {name: ProductId, var: product_id}, {name: RefId, var: ref_id}, {name: RewardValue, var: reward_value}, {name: UnitMultiplier, var: unit_multiplier}, {name: Videos, var: videos}, {name: WeightKg, var: weight_kg}, {name: Width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept, activate_if_possible: $activate_if_possible, commercial_condition_id: $commercial_condition_id, creation_date: $creation_date, cubic_weight: $cubic_weight, estimated_date_arrival: $estimated_date_arrival, height: $height, is_active: $is_active, is_kit: $is_kit, kit_itens_sell_apart: $kit_itens_sell_apart, length: $length, manufacturer_code: $manufacturer_code, measurement_unit: $measurement_unit, modal_type: $modal_type, name: $name, packaged_height: $packaged_height, packaged_length: $packaged_length, packaged_weight_kg: $packaged_weight_kg, packaged_width: $packaged_width, product_id: $product_id, ref_id: $ref_id, reward_value: $reward_value, unit_multiplier: $unit_multiplier, videos: $videos, weight_kg: $weight_kg, width: $width
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Attachments by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/attachment
# Returns: table<AttachmentId: int, Id: int, SkuId: int>
export def "get-api-catalog-pvt-stockkeepingunit-sku-id-attachment" [
  sku_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/attachment"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Complement by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/complement
# Returns: table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int>
# operationId: GetSKUComplementbySKUID
export def "get-sku-complementby-skuid" [
  sku_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/complement"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Complements by Complement Type ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/complement/{complementTypeId}
# Returns: table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int>
# operationId: GetSKUComplementsbyComplementTypeID
export def "get-sku-complementsby-complement-type-id" [
  sku_id: int
  complement_type_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/complement/{complementTypeId}"
    path_params: [{name: skuId, var: sku_id}, {name: complementTypeId, var: complement_type_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, complement_type_id: $complement_type_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all SKU EAN values
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/ean
export def "delete-api-catalog-pvt-stockkeepingunit-sku-id-ean" [
  sku_id: int
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
    method: delete
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/ean"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get EAN by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/ean
# Returns: list<string>
export def "get-api-catalog-pvt-stockkeepingunit-sku-id-ean" [
  sku_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/ean"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU EAN
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/ean/{ean}
export def "delete-api-catalog-pvt-stockkeepingunit-sku-id-ean-ean" [
  sku_id: int
  ean: string
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
    method: delete
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/ean/{ean}"
    path_params: [{name: skuId, var: sku_id}, {name: ean, var: ean}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, ean: $ean, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SKU EAN
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/ean/{ean}
export def "post-api-catalog-pvt-stockkeepingunit-sku-id-ean-ean" [
  sku_id: int
  ean: string
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
    method: post
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/ean/{ean}"
    path_params: [{name: skuId, var: sku_id}, {name: ean, var: ean}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, ean: $ean, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete All SKU Files
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/file
export def "delete-api-catalog-pvt-stockkeepingunit-sku-id-file" [
  sku_id: int
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
    method: delete
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/file"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Files
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/file
# Returns: table<ArchiveId: int, Id: int, IsMain: bool, Label: string, Name: string, SkuId: int>
export def "get-api-catalog-pvt-stockkeepingunit-sku-id-file" [
  sku_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/file"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SKU File
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/file
# Returns: record<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int>
export def "post-api-catalog-pvt-stockkeepingunit-sku-id-file" [
  sku_id: int
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
  --is-main: oneof<nothing, bool> # Defines if the Image is the main image of the SKU. (e.g. true)
  --label: string # SKU image label. (e.g. Main)
  name: string # SKU image name. (e.g. Nike-Red-Janoski-1)
  --text: string # General text of the image. (nullable, e.g. Nike-Red-Janoski)
  url: string # External Image's URL. The URL must start with the protocol identifier (`http://` or `https://`) and end with the file extension (`.jpg`, `.png` or `.gif`). (e.g. https://m.media-amazon.com/images/I/610G2-sJx5L._AC_UX695_.jpg)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/file"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IsMain, var: is_main}, {name: Label, var: label}, {name: Name, var: name}, {name: Text, var: text}, {name: Url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept, is_main: $is_main, label: $label, name: $name, text: $text, url: $url
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU Image File
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/file/{skuFileId}
export def "delete-api-catalog-pvt-stockkeepingunit-sku-id-file-sku-file-id" [
  sku_id: int
  sku_file_id: int
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
    method: delete
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/file/{skuFileId}"
    path_params: [{name: skuId, var: sku_id}, {name: skuFileId, var: sku_file_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, sku_file_id: $sku_file_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update SKU File
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/file/{skuFileId}
# Returns: record<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int>
export def "put-api-catalog-pvt-stockkeepingunit-sku-id-file-sku-file-id" [
  sku_id: int
  sku_file_id: int
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
  --is-main: oneof<nothing, bool> # Defines if the Image is the main image of the SKU. (e.g. true)
  --label: string # SKU image label. (e.g. Main)
  name: string # SKU image name. (e.g. Nike-Red-Janoski-1)
  --text: string # General text of the image. (nullable, e.g. Nike-Red-Janoski)
  url: string # External Image's URL. The URL must start with the protocol identifier (`http://` or `https://`) and end with the file extension (`.jpg`, `.png` or `.gif`). (e.g. https://m.media-amazon.com/images/I/610G2-sJx5L._AC_UX695_.jpg)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/file/{skuFileId}"
    path_params: [{name: skuId, var: sku_id}, {name: skuFileId, var: sku_file_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IsMain, var: is_main}, {name: Label, var: label}, {name: Name, var: name}, {name: Text, var: text}, {name: Url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, sku_file_id: $sku_file_id, content_type: $content_type, hdr_accept: $hdr_accept, is_main: $is_main, label: $label, name: $name, text: $text, url: $url
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all SKU Specifications
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "delete-api-catalog-pvt-stockkeepingunit-sku-id-specification" [
  sku_id: int
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
    method: delete
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/specification"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Specifications
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/specification
# Returns: table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string>
export def "get-api-catalog-pvt-stockkeepingunit-sku-id-specification" [
  sku_id: int
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/specification"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate SKU Specification
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/specification
# Returns: record<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string>
export def "post-api-catalog-pvt-stockkeepingunit-sku-id-specification" [
  sku_id: int
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
  field_id: int # Specification ID. (e.g. 13)
  --field-value-id: int # Specification Value ID. Required only for `FieldTypeId` as `5`, `6` and `7`. (e.g. 101)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/specification"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldId, var: field_id}, {name: FieldValueId, var: field_value_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept, field_id: $field_id, field_value_id: $field_value_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update SKU Specification
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/specification
# Returns: table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string>
export def "put-api-catalog-pvt-stockkeepingunit-sku-id-specification" [
  sku_id: int
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
  field_id: int # Specification unique identifier. This field cannot be updated. (e.g. 32)
  field_value_id: int # Specification value unique identifier. This field can only be updated with other values of the same `FieldId`. (e.g. 131)
  id: int # Specification and SKU association unique identifier. This field cannot be updated. (e.g. 65)
  --body-sku-id: int # SKU unique identifier. This field cannot be updated. (e.g. 21) (spec name: SkuId)
  --text: string # Specification Value Name. This field is automatically updated if the `FieldValue` is updated. Otherwise, the value cannot be modified. (e.g. Red)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/specification"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldId, var: field_id}, {name: FieldValueId, var: field_value_id}, {name: Id, var: id}, {name: SkuId, var: body_sku_id}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept, field_id: $field_id, field_value_id: $field_value_id, id: $id, body_sku_id: $body_sku_id, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU Specification
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/specification/{specificationId}
export def "delete-api-catalog-pvt-stockkeepingunit-sku-id-specification-specification-id" [
  sku_id: int
  specification_id: int
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
    method: delete
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/specification/{specificationId}"
    path_params: [{name: skuId, var: sku_id}, {name: specificationId, var: specification_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, specification_id: $specification_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate SKU specification using specification name and group name
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/specificationvalue
# Returns: table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string>
export def "put-api-catalog-pvt-stockkeepingunit-sku-id-specificationvalue" [
  sku_id: int
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
  field_name: string # Specification name. (e.g. Material)
  field_values: list<string> # Array of specification values. SKU Specifications must contain only one value. (e.g. [M])
  group_name: string # Group name. (e.g. Composition)
  --root-level-specification: oneof<nothing, bool> # Root level specification. (e.g. true)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/stockkeepingunit/{skuId}/specificationvalue"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldName, var: field_name}, {name: FieldValues, var: field_values}, {name: GroupName, var: group_name}, {name: RootLevelSpecification, var: root_level_specification, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept, field_name: $field_name, field_values: $field_values, group_name: $group_name, root_level_specification: $root_level_specification
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU Kit by SKU ID or Parent SKU ID
#
# DELETE /api/catalog/pvt/stockkeepingunitkit
export def "delete-api-catalog-pvt-stockkeepingunitkit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --parent-sku-id: int # Parent SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/catalog/pvt/stockkeepingunitkit"
    query: [{name: skuId, var: sku_id}, {name: parentSkuId, var: parent_sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, parent_sku_id: $parent_sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Kit by SKU ID or Parent SKU ID
#
# GET /api/catalog/pvt/stockkeepingunitkit
# Returns: record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int>
export def "get-api-catalog-pvt-stockkeepingunitkit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --parent-sku-id: int # Parent SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunitkit"
    query: [{name: skuId, var: sku_id}, {name: parentSkuId, var: parent_sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, parent_sku_id: $parent_sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SKU Kit
#
# POST /api/catalog/pvt/stockkeepingunitkit
# Returns: record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int>
export def "post-api-catalog-pvt-stockkeepingunitkit" [
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
  quantity: int # Component quantity. (e.g. 3)
  stock_keeping_unit_id: int # Component SKU ID. (e.g. 31018374)
  stock_keeping_unit_parent: int # SKU ID of the SKU Kit. (e.g. 31018373)
  unit_price: float # Component price per unit. (e.g. 15.5)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/stockkeepingunitkit"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Quantity, var: quantity}, {name: StockKeepingUnitId, var: stock_keeping_unit_id}, {name: StockKeepingUnitParent, var: stock_keeping_unit_parent}, {name: UnitPrice, var: unit_price}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, quantity: $quantity, stock_keeping_unit_id: $stock_keeping_unit_id, stock_keeping_unit_parent: $stock_keeping_unit_parent, unit_price: $unit_price
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU Kit by KitId
#
# DELETE /api/catalog/pvt/stockkeepingunitkit/{kitId}
export def "delete-api-catalog-pvt-stockkeepingunitkit-kit-id" [
  kit_id: int
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
    method: delete
    path: "/api/catalog/pvt/stockkeepingunitkit/{kitId}"
    path_params: [{name: kitId, var: kit_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    kit_id: $kit_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU Kit
#
# GET /api/catalog/pvt/stockkeepingunitkit/{kitId}
# Returns: record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int>
export def "get-api-catalog-pvt-stockkeepingunitkit-kit-id" [
  kit_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/stockkeepingunitkit/{kitId}"
    path_params: [{name: kitId, var: kit_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    kit_id: $kit_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Subcollection
#
# POST /api/catalog/pvt/subcollection
# Returns: record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string>
export def "post-api-catalog-pvt-subcollection" [
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
  collection_id: int # SubCollection ID. (e.g. 17)
  name: string # SubCollection Name. (e.g. group 1)
  --pre-sale: oneof<nothing, bool> # Defines PreSale date. (e.g. false)
  --release: oneof<nothing, bool> # Defines Release date. (e.g. false)
  type: string # Either `“Exclusive”` (all the products contained in it will not be used) or `“Inclusive”` (all the products contained in it will be used). (e.g. Inclusive)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/subcollection"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CollectionId, var: collection_id}, {name: Name, var: name}, {name: PreSale, var: pre_sale, required: true}, {name: Release, var: release, required: true}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, collection_id: $collection_id, name: $name, pre_sale: $pre_sale, release: $release, type: $type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}
export def "delete-api-catalog-pvt-subcollection-sub-collection-id" [
  sub_collection_id: int
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
    method: delete
    path: "/api/catalog/pvt/subcollection/{subCollectionId}"
    path_params: [{name: subCollectionId, var: sub_collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Subcollection
#
# GET /api/catalog/pvt/subcollection/{subCollectionId}
# Returns: record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string>
export def "get-api-catalog-pvt-subcollection-sub-collection-id" [
  sub_collection_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog/pvt/subcollection/{subCollectionId}"
    path_params: [{name: subCollectionId, var: sub_collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Subcollection
#
# PUT /api/catalog/pvt/subcollection/{subCollectionId}
# Returns: record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string>
export def "put-api-catalog-pvt-subcollection-sub-collection-id" [
  sub_collection_id: int
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
  collection_id: int # Collection ID. (e.g. 17)
  name: string # Subcollection Name. (e.g. group 1)
  --pre-sale: oneof<nothing, bool> # Defines PreSale date. (e.g. false)
  --release: oneof<nothing, bool> # Defines Release date. (e.g. false)
  type: string # Either `“Exclusive”` (all the products contained in it will not be used) or `“Inclusive”` (all the products contained in it will be used). (e.g. Inclusive)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/subcollection/{subCollectionId}"
    path_params: [{name: subCollectionId, var: sub_collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CollectionId, var: collection_id}, {name: Name, var: name}, {name: PreSale, var: pre_sale, required: true}, {name: Release, var: release, required: true}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, content_type: $content_type, hdr_accept: $hdr_accept, collection_id: $collection_id, name: $name, pre_sale: $pre_sale, release: $release, type: $type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate Brand to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/brand
# Returns: record<BrandId: int, SubCollectionId: int>
export def "post-api-catalog-pvt-subcollection-sub-collection-id-brand" [
  sub_collection_id: int
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
  brand_id: int # Unique identifier of a Brand. (e.g. 2000000)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/subcollection/{subCollectionId}/brand"
    path_params: [{name: subCollectionId, var: sub_collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BrandId, var: brand_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, content_type: $content_type, hdr_accept: $hdr_accept, brand_id: $brand_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Brand from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/brand/{brandId}
export def "delete-api-catalog-pvt-subcollection-sub-collection-id-brand-brand-id" [
  sub_collection_id: int
  brand_id: int
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
    method: delete
    path: "/api/catalog/pvt/subcollection/{subCollectionId}/brand/{brandId}"
    path_params: [{name: subCollectionId, var: sub_collection_id}, {name: brandId, var: brand_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, brand_id: $brand_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Category from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/brand/{categoryId}
export def "delete-api-catalog-pvt-subcollection-sub-collection-id-brand-category-id" [
  sub_collection_id: int
  category_id: int
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
    method: delete
    path: "/api/catalog/pvt/subcollection/{subCollectionId}/brand/{categoryId}"
    path_params: [{name: subCollectionId, var: sub_collection_id}, {name: categoryId, var: category_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, category_id: $category_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate Category to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/category
# Returns: record<CategoryId: int, SubCollectionId: int>
export def "post-api-catalog-pvt-subcollection-sub-collection-id-category" [
  sub_collection_id: int
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
  category_id: int # Unique identifier of a Category. (e.g. 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/subcollection/{subCollectionId}/category"
    path_params: [{name: subCollectionId, var: sub_collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryId, var: category_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, content_type: $content_type, hdr_accept: $hdr_accept, category_id: $category_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add SKU to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/stockkeepingunit
# Returns: record<SkuId: int, SubCollectionId: int>
export def "post-api-catalog-pvt-subcollection-sub-collection-id-stockkeepingunit" [
  sub_collection_id: int
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
  sku_id: int # Unique identifier of an SKU. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/subcollection/{subCollectionId}/stockkeepingunit"
    path_params: [{name: subCollectionId, var: sub_collection_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SkuId, var: sku_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, content_type: $content_type, hdr_accept: $hdr_accept, sku_id: $sku_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SKU from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/stockkeepingunit/{skuId}
export def "delete-api-catalog-pvt-subcollection-sub-collection-id-stockkeepingunit-sku-id" [
  sub_collection_id: int
  sku_id: int
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
    method: delete
    path: "/api/catalog/pvt/subcollection/{subCollectionId}/stockkeepingunit/{skuId}"
    path_params: [{name: subCollectionId, var: sub_collection_id}, {name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sub_collection_id: $sub_collection_id, sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Supplier
#
# POST /api/catalog/pvt/supplier
# Returns: record<CellPhone: string, Cnpj: string, CorporateName: string, CorportePhone: string, Email: string, Id: int, IsActive: bool, Name: string, Phone: string, StateInscription: string>
export def "post-api-catalog-pvt-supplier" [
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
  cell_phone: string # Supplier Cellphone. (e.g. 4444444444)
  cnpj: string # Corporate legal ID. (e.g. 33304981001272)
  corporate_name: string # Supplier Corporate Name. (e.g. TopStore)
  corporte_phone: string # Supplier Corporate Phone. (e.g. 5555555555)
  email: string # Supplier email. (e.g. email@email.com)
  --is-active: oneof<nothing, bool> # Defines if the Supplier is active (`true`) or not (`false`). (e.g. false)
  name: string # Supplier Name. (e.g. Supplier)
  phone: string # Supplier Phone. (e.g. 3333333333)
  state_inscription: string # State Inscription. (e.g. 123456)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog/pvt/supplier"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CellPhone, var: cell_phone}, {name: Cnpj, var: cnpj}, {name: CorporateName, var: corporate_name}, {name: CorportePhone, var: corporte_phone}, {name: Email, var: email}, {name: IsActive, var: is_active, required: true}, {name: Name, var: name}, {name: Phone, var: phone}, {name: StateInscription, var: state_inscription}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, cell_phone: $cell_phone, cnpj: $cnpj, corporate_name: $corporate_name, corporte_phone: $corporte_phone, email: $email, is_active: $is_active, name: $name, phone: $phone, state_inscription: $state_inscription
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Supplier
#
# DELETE /api/catalog/pvt/supplier/{supplierId}
export def "delete-api-catalog-pvt-supplier-supplier-id" [
  supplier_id: int
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
    method: delete
    path: "/api/catalog/pvt/supplier/{supplierId}"
    path_params: [{name: supplierId, var: supplier_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    supplier_id: $supplier_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Supplier
#
# PUT /api/catalog/pvt/supplier/{supplierId}
# Returns: record<CellPhone: string, Cnpj: string, CorporateName: string, CorportePhone: string, Email: string, Id: int, IsActive: bool, Name: string, Phone: string, StateInscription: string>
export def "put-api-catalog-pvt-supplier-supplier-id" [
  supplier_id: int
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
  cell_phone: string # Supplier Cellphone. (e.g. 4444444444)
  cnpj: string # Corporate legal ID. (e.g. 33304981001272)
  corporate_name: string # Supplier Corporate Name. (e.g. TopStore)
  corporte_phone: string # Supplier Corporate Phone. (e.g. 5555555555)
  email: string # Supplier email. (e.g. email@email.com)
  --is-active: oneof<nothing, bool> # Defines if the Supplier is active (`true`) or not (`false`). (e.g. false)
  name: string # Supplier Name. (e.g. Supplier)
  phone: string # Supplier Phone. (e.g. 3333333333)
  state_inscription: string # State Inscription. (e.g. 123456)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog/pvt/supplier/{supplierId}"
    path_params: [{name: supplierId, var: supplier_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CellPhone, var: cell_phone}, {name: Cnpj, var: cnpj}, {name: CorporateName, var: corporate_name}, {name: CorportePhone, var: corporte_phone}, {name: Email, var: email}, {name: IsActive, var: is_active, required: true}, {name: Name, var: name}, {name: Phone, var: phone}, {name: StateInscription, var: state_inscription}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    supplier_id: $supplier_id, content_type: $content_type, hdr_accept: $hdr_accept, cell_phone: $cell_phone, cnpj: $cnpj, corporate_name: $corporate_name, corporte_phone: $corporte_phone, email: $email, is_active: $is_active, name: $name, phone: $phone, state_inscription: $state_inscription
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Category Tree
#
# GET /api/catalog_system/pub/category/tree/{categoryLevels}
# Returns: table<MetaTagDescription: string, Title: string, children: list<record>, hasChildren: bool, id: int, name: string, url: string>
# operationId: CategoryTree
export def "category-tree" [
  category_levels: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pub/category/tree/{categoryLevels}"
    path_params: [{name: categoryLevels, var: category_levels}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    category_levels: $category_levels, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product's SKUs by Product ID
#
# GET /api/catalog_system/pub/products/variations/{productId}
# Returns: record<available: bool, dimensions: list<string>, dimensionsInputType: record, dimensionsMap: record, displayMode: string, name: string, productId: int, salesChannel: string, skus: table<available: bool, availablequantity: int, bestPrice: int, bestPriceFormated: string, cacheVersionUsedToCallCheckout: string, dimensions: record, image: string, installments: int, installmentsInsterestRate: int, installmentsValue: int, listPrice: int, listPriceFormated: string, measures: record, rewardValue: int, sellerId: string, sku: int, skuname: string, spotPrice: int, taxAsInt: int, taxFormated: string, unitMultiplier: float>>
# operationId: ProductVariations
export def "product-variations" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pub/products/variations/{productId}"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Sales Channel by ID
#
# GET /api/catalog_system/pub/saleschannel/{salesChannelId}
# Returns: record<ConditionRule: string, CountryCode: string, CultureInfo: string, CurrencyCode: string, CurrencyDecimalDigits: int, CurrencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, CurrencyLocale: int, CurrencySymbol: string, Id: int, IsActive: bool, Name: string, Origin: string, Position: int, ProductClusterId: int, TimeZone: string>
# operationId: SalesChannelbyId
export def "sales-channelby-id" [
  sales_channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pub/saleschannel/{salesChannelId}"
    path_params: [{name: salesChannelId, var: sales_channel_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sales_channel_id: $sales_channel_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve SKU ID list by Reference ID list
#
# POST /api/catalog_system/pub/sku/stockkeepingunitidsbyrefids
# Returns: record
# operationId: SkuIdlistbyRefIdlist
export def "sku-idlistby-ref-idlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog_system/pub/sku/stockkeepingunitidsbyrefids"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specifications By Category ID
#
# GET /api/catalog_system/pub/specification/field/listByCategoryId/{categoryId}
# Returns: table<CategoryId: int, FieldId: int, IsActive: bool, IsStockKeepingUnit: bool, Name: string>
# operationId: SpecificationsByCategoryId
export def "specifications-by-category-id" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pub/specification/field/listByCategoryId/{categoryId}"
    path_params: [{name: categoryId, var: category_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    category_id: $category_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specifications Tree By Category ID
#
# GET /api/catalog_system/pub/specification/field/listTreeByCategoryId/{categoryId}
# Returns: table<CategoryId: int, FieldId: int, IsActive: bool, IsStockKeepingUnit: bool, Name: string>
# operationId: SpecificationsTreeByCategoryId
export def "specifications-tree-by-category-id" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pub/specification/field/listTreeByCategoryId/{categoryId}"
    path_params: [{name: categoryId, var: category_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    category_id: $category_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specification Field
#
# GET /api/catalog_system/pub/specification/fieldGet/{fieldId}
# Returns: record<DefaultValue: string, Description: string, FieldGroupId: int, FieldGroupName: string, FieldId: int, FieldTypeId: int, FieldTypeName: string, FieldValueId: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int>
# operationId: SpecificationsField
export def "specifications-field" [
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pub/specification/fieldGet/{fieldId}"
    path_params: [{name: fieldId, var: field_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    field_id: $field_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specification Values By Field ID
#
# GET /api/catalog_system/pub/specification/fieldvalue/{fieldId}
# Returns: table<FieldValueId: int, IsActive: bool, Position: int, Value: string>
# operationId: SpecificationsValuesByFieldId
export def "specifications-values-by-field-id" [
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pub/specification/fieldvalue/{fieldId}"
    path_params: [{name: fieldId, var: field_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    field_id: $field_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specification Group
#
# GET /api/catalog_system/pub/specification/groupGet/{groupId}
# Returns: record<CategoryId: int, Id: int, Name: string, Position: int>
# operationId: SpecificationsGroupGet
export def "specifications-group-get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pub/specification/groupGet/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    group_id: $group_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Brand List
#
# GET /api/catalog_system/pvt/brand/list
# Returns: table<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string>
# operationId: BrandList
export def "brand-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/brand/list"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Brand List Per Page
#
# GET /api/catalog_system/pvt/brand/pagedlist
# Returns: record<items: table<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string>, paging: record<page: int, pages: int, perPage: int, total: int>>
# operationId: BrandListPerPage
export def "brand-list-per-page" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Quantity of brands per page. (required, e.g. 5)
  --page: int # Page number of the brand list. (required, e.g. 1)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/brand/pagedlist"
    query: [{name: pageSize, var: page_size, required: true}, {name: page, var: page, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    page_size: $page_size, page: $page, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Brand
#
# GET /api/catalog_system/pvt/brand/{brandId}
# Returns: record<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string>
# operationId: Brand
export def "brand" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/brand/{brandId}"
    path_params: [{name: brandId, var: brand_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    brand_id: $brand_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Collections
#
# GET /api/catalog_system/pvt/collection/search
# operationId: GET-AllCollections
export def "get-all-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (required, e.g. 2)
  --page-size: int # Number of the items of the page. (required, e.g. 15)
  --order-by-asc: oneof<nothing, bool> # Defines if the items of the page are in ascending order. (required, e.g. true)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/collection/search"
    query: [{name: page, var: page, required: true}, {name: pageSize, var: page_size, required: true}, {name: orderByAsc, var: order_by_asc, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    page: $page, page_size: $page_size, order_by_asc: $order_by_asc, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Collections by search terms
#
# GET /api/catalog_system/pvt/collection/search/{searchTerms}
# operationId: GET-Collectionsbyseachterms
export def "get-collectionsbyseachterms" [
  search_terms: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (e.g. 2)
  --page-size: int # Number of the items of the page. (e.g. 15)
  --order-by-asc: oneof<nothing, bool> # Defines if the items of the page are in ascending order. (e.g. true)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/collection/search/{searchTerms}"
    path_params: [{name: searchTerms, var: search_terms}]
    query: [{name: page, var: page}, {name: pageSize, var: page_size}, {name: orderByAsc, var: order_by_asc}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    search_terms: $search_terms, page: $page, page_size: $page_size, order_by_asc: $order_by_asc, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all commercial conditions
#
# GET /api/catalog_system/pvt/commercialcondition/list
# Returns: table<Id: int, IsDefault: bool, Name: string>
# operationId: GetAllCommercialConditions
export def "get-all-commercial-conditions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/commercialcondition/list"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get commercial condition
#
# GET /api/catalog_system/pvt/commercialcondition/{commercialConditionId}
# Returns: record<Id: int, IsDefault: bool, Name: string>
# operationId: GetCommercialConditions
export def "get-commercial-conditions" [
  commercial_condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/commercialcondition/{commercialConditionId}"
    path_params: [{name: commercialConditionId, var: commercial_condition_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    commercial_condition_id: $commercial_condition_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product Indexed Information
#
# GET /api/catalog_system/pvt/products/GetIndexedInfo/{productId}
# operationId: IndexedInfo
export def "indexed-info" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/products/GetIndexedInfo/{productId}"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: [xml]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product and SKU IDs
#
# GET /api/catalog_system/pvt/products/GetProductAndSkuIds
# Returns: record<data: record<"Product ID": list<any>>, range: record<from: int, to: int, total: int>>
# operationId: ProductAndSkuIds
export def "product-and-sku-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: int # ID of the category from which you need to retrieve Products and SKUs. (format: int32, e.g. 1)
  --from: int # Insert the ID that will start the request result. (format: int32, e.g. 1)
  --to: int # Insert the ID that will end the request result. (format: int32, e.g. 10)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/products/GetProductAndSkuIds"
    query: [{name: categoryId, var: category_id}, {name: _from, var: from}, {name: _to, var: to}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    category_id: $category_id, from: $from, to: $to, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product and its general context
#
# GET /api/catalog_system/pvt/products/productget/{productId}
# Returns: record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, ListStoreId: list<any>, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>
# operationId: ProductandTradePolicy
export def "productand-trade-policy" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/products/productget/{productId}"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product by RefId
#
# GET /api/catalog_system/pvt/products/productgetbyrefid/{refId}
# Returns: record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, ListStoreId: list<int>, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string>
# operationId: ProductbyRefId
export def "productby-ref-id" [
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/products/productgetbyrefid/{refId}"
    path_params: [{name: refId, var: ref_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    ref_id: $ref_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product Specification by Product ID
#
# GET /api/catalog_system/pvt/products/{productId}/specification
# Returns: table<Id: int, Name: string, Value: list<string>>
# operationId: GetProductSpecification
export def "get-product-specification" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/products/{productId}/specification"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Product Specification by Product ID
#
# POST /api/catalog_system/pvt/products/{productId}/specification
# operationId: UpdateProductSpecification
export def "update-product-specification" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/catalog_system/pvt/products/{productId}/specification"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Sales Channel List
#
# GET /api/catalog_system/pvt/saleschannel/list
# Returns: table<ConditionRule: string, CountryCode: string, CultureInfo: string, CurrencyCode: string, CurrencyDecimalDigits: int, CurrencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, CurrencyLocale: int, CurrencySymbol: string, Id: int, IsActive: bool, Name: string, Origin: string, Position: int, ProductClusterId: int, TimeZone: string>
# operationId: SalesChannelList
export def "sales-channel-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/saleschannel/list"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Seller
#
# POST /api/catalog_system/pvt/seller
# Returns: record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>
# operationId: CreateSeller
export def "create-seller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  archive_id: int # Seller archive ID. (e.g. 1)
  cnpj: string # Company registration number. (e.g. 12035072751)
  csc_identification: string # CSC identification. (e.g. pedrostore)
  catalog_system_endpoint: string # URL of the endpoint of the seller's catalog. This field will only be displayed if the seller type is VTEX Store. The field format will be as follows: `http://{sellerName}.vtexcommercestable.com.br/api/catalog_system/`. (e.g. http://pedrostore.vtexcommercestable.com.br/api/catalog_system/)
  --category-commission-percentage: string # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. [{"CategoryId":14,"ProductCommission":15.0,"FreightCommission":0.0}])
  delivery_policy: string # Text describing the delivery policy previously agreed between the marketplace and the seller. (e.g. Delivery policy text)
  description: string # Text describing the seller with a marketing tone. You can display this text in the marketplace window display by [customizing the CMS](https://help.vtex.com/en/tutorial/list-of-controls-for-templates--tutorials_563). (e.g. Brief description)
  email: string # Email of the admin responsible for the seller. (e.g. breno@breno.com)
  exchange_return_policy: string # Text describing the exchange and return policy previously agreed between the marketplace and the seller. (e.g. Exchange return policy text)
  freight_commission_percentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  fulfillment_endpoint: string # URL of the endpoint for fulfillment of seller's orders, which the marketplace will use to communicate with the seller. This field applies to all sellers, regardless of their type. However, for `VTEX Stores`, you don’t need to fill it in because the system will do that automatically. You can edit this field once the seller has been successfully added. (e.g. http://pedrostore.vtexcommercestable.com.br/api/fulfillment?affiliateid=LDB&sc=1)
  fulfillment_seller_id: int # Identification code of the seller responsible for fulfilling the order. This is an optional field used when a seller sells SKUs from another seller. If the seller sells their own SKUs, it must be left blank. (e.g. 1)
  --is-active: oneof<nothing, bool> # If the selle is active (`true`) or not (`false`). (e.g. true)
  --is-better-scope: oneof<nothing, bool> # Indicates whether it is a [comprehensive seller](https://help.vtex.com/en/tutorial/comprehensive-seller--5Qn4O2GpjUIzWTPpvLUfkI). (e.g. false)
  --merchant-name: string # Name of the marketplace, used to guide payments. This field should be nulled if the marketplace is responsible for processing payments. Check out our [Split Payment](https://help.vtex.com/en/tutorial/split-payment--6k5JidhYRUxileNolY2VLx) article to know more. (e.g. pedrostore)
  name: string # Name of the account in the seller's environment. You can find it on **Account settings > Account > Account Name**). Applicable only if the seller uses their own payment method. (e.g. My pedrostore)
  password: string # Seller password. (e.g. passoword)
  product_commission_percentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  secutity_privacy_policy: string # Text describing the security policy previously agreed between the marketplace and the seller. (e.g. Secutity privacy policy text)
  seller_id: string # Code used to identify the seller. It is assigned by the marketplace. We recommend filling it in with the seller's account name. (e.g. pedrostore)
  seller_type: int # Seller type. (e.g. 1)
  --trust-policy: string # Seller trust policy. The default value is `'Default'`, but if your store is a B2B marketplace and you want to share the customers'emails with the sellers you need to set this field as `'AllowEmailSharing'`. (e.g. Default)
  url_logo: string # Seller URL logo. (e.g. /myseller)
  --use-hybrid-payment-options: oneof<nothing, bool> # Allows customers to use gift cards from the seller to buy their products on the marketplace. It identifies purchases made with a gift card so that only the final price (with discounts applied) is paid to the seller. (e.g. false)
  user_name: string # Seller username. (e.g. myseller)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog_system/pvt/seller"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ArchiveId, var: archive_id}, {name: CNPJ, var: cnpj}, {name: CSCIdentification, var: csc_identification}, {name: CatalogSystemEndpoint, var: catalog_system_endpoint}, {name: CategoryCommissionPercentage, var: category_commission_percentage}, {name: DeliveryPolicy, var: delivery_policy}, {name: Description, var: description}, {name: Email, var: email}, {name: ExchangeReturnPolicy, var: exchange_return_policy}, {name: FreightCommissionPercentage, var: freight_commission_percentage}, {name: FulfillmentEndpoint, var: fulfillment_endpoint}, {name: FulfillmentSellerId, var: fulfillment_seller_id}, {name: IsActive, var: is_active, required: true}, {name: IsBetterScope, var: is_better_scope, required: true}, {name: MerchantName, var: merchant_name}, {name: Name, var: name}, {name: Password, var: password}, {name: ProductCommissionPercentage, var: product_commission_percentage}, {name: SecutityPrivacyPolicy, var: secutity_privacy_policy}, {name: SellerId, var: seller_id}, {name: SellerType, var: seller_type}, {name: TrustPolicy, var: trust_policy}, {name: UrlLogo, var: url_logo}, {name: UseHybridPaymentOptions, var: use_hybrid_payment_options, required: true}, {name: UserName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, archive_id: $archive_id, cnpj: $cnpj, csc_identification: $csc_identification, catalog_system_endpoint: $catalog_system_endpoint, category_commission_percentage: $category_commission_percentage, delivery_policy: $delivery_policy, description: $description, email: $email, exchange_return_policy: $exchange_return_policy, freight_commission_percentage: $freight_commission_percentage, fulfillment_endpoint: $fulfillment_endpoint, fulfillment_seller_id: $fulfillment_seller_id, is_active: $is_active, is_better_scope: $is_better_scope, merchant_name: $merchant_name, name: $name, password: $password, product_commission_percentage: $product_commission_percentage, secutity_privacy_policy: $secutity_privacy_policy, seller_id: $seller_id, seller_type: $seller_type, trust_policy: $trust_policy, url_logo: $url_logo, use_hybrid_payment_options: $use_hybrid_payment_options, user_name: $user_name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Seller
#
# PUT /api/catalog_system/pvt/seller
# Returns: record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>
# operationId: UpdateSeller
export def "update-seller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  archive_id: int # Seller archive ID. (e.g. 1)
  cnpj: string # Company registration number. (e.g. 12035072751)
  csc_identification: string # CSC identification. (e.g. pedrostore)
  catalog_system_endpoint: string # URL of the endpoint of the seller's catalog. This field will only be displayed if the seller type is VTEX Store. The field format will be as follows: `http://{sellerName}.vtexcommercestable.com.br/api/catalog_system/`. (e.g. http://pedrostore.vtexcommercestable.com.br/api/catalog_system/)
  --category-commission-percentage: string # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. [{"CategoryId":14,"ProductCommission":15.0,"FreightCommission":0.0}])
  delivery_policy: string # Text describing the delivery policy previously agreed between the marketplace and the seller. (e.g. Delivery policy text)
  description: string # Text describing the seller with a marketing tone. You can display this text in the marketplace window display by [customizing the CMS](https://help.vtex.com/en/tutorial/list-of-controls-for-templates--tutorials_563). (e.g. Brief description)
  email: string # Email of the admin responsible for the seller. (e.g. breno@breno.com)
  exchange_return_policy: string # Text describing the exchange and return policy previously agreed between the marketplace and the seller. (e.g. Exchange return policy text)
  freight_commission_percentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  fulfillment_endpoint: string # URL of the endpoint for fulfillment of seller's orders, which the marketplace will use to communicate with the seller. This field applies to all sellers, regardless of their type. However, for `VTEX Stores`, you don’t need to fill it in because the system will do that automatically. You can edit this field once the seller has been successfully added. (e.g. http://pedrostore.vtexcommercestable.com.br/api/fulfillment?affiliateid=LDB&sc=1)
  fulfillment_seller_id: int # Identification code of the seller responsible for fulfilling the order. This is an optional field used when a seller sells SKUs from another seller. If the seller sells their own SKUs, it must be left blank. (e.g. 1)
  --is-active: oneof<nothing, bool> # If the selle is active (`true`) or not (`false`). (e.g. true)
  --is-better-scope: oneof<nothing, bool> # Indicates whether it is a [comprehensive seller](https://help.vtex.com/en/tutorial/comprehensive-seller--5Qn4O2GpjUIzWTPpvLUfkI). (e.g. false)
  --merchant-name: string # Name of the marketplace, used to guide payments. This field should be nulled if the marketplace is responsible for processing payments. Check out our [Split Payment](https://help.vtex.com/en/tutorial/split-payment--6k5JidhYRUxileNolY2VLx) article to know more. (e.g. pedrostore)
  name: string # Name of the account in the seller's environment. You can find it on **Account settings > Account > Account Name**). Applicable only if the seller uses their own payment method. (e.g. My pedrostore)
  password: string # Seller password. (e.g. passoword)
  product_commission_percentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  secutity_privacy_policy: string # Text describing the security policy previously agreed between the marketplace and the seller. (e.g. Secutity privacy policy text)
  seller_id: string # ID that identifies the seller in the marketplace. It can be the same as the seller name or a unique number. Check the **Sellers management** section in the Admin to get the correct ID. (e.g. pedrostore)
  seller_type: int # Seller type. (e.g. 1)
  --trust-policy: string # Seller trust policy. The default value is `'Default'`, but if your store is a B2B marketplace and you want to share the customers'emails with the sellers you need to set this field as `'AllowEmailSharing'`. (e.g. Default)
  url_logo: string # Seller URL logo. (e.g. /myseller)
  --use-hybrid-payment-options: oneof<nothing, bool> # Allows customers to use gift cards from the seller to buy their products on the marketplace. It identifies purchases made with a gift card so that only the final price (with discounts applied) is paid to the seller. (e.g. false)
  user_name: string # Seller username. (e.g. myseller)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/catalog_system/pvt/seller"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ArchiveId, var: archive_id}, {name: CNPJ, var: cnpj}, {name: CSCIdentification, var: csc_identification}, {name: CatalogSystemEndpoint, var: catalog_system_endpoint}, {name: CategoryCommissionPercentage, var: category_commission_percentage}, {name: DeliveryPolicy, var: delivery_policy}, {name: Description, var: description}, {name: Email, var: email}, {name: ExchangeReturnPolicy, var: exchange_return_policy}, {name: FreightCommissionPercentage, var: freight_commission_percentage}, {name: FulfillmentEndpoint, var: fulfillment_endpoint}, {name: FulfillmentSellerId, var: fulfillment_seller_id}, {name: IsActive, var: is_active, required: true}, {name: IsBetterScope, var: is_better_scope, required: true}, {name: MerchantName, var: merchant_name}, {name: Name, var: name}, {name: Password, var: password}, {name: ProductCommissionPercentage, var: product_commission_percentage}, {name: SecutityPrivacyPolicy, var: secutity_privacy_policy}, {name: SellerId, var: seller_id}, {name: SellerType, var: seller_type}, {name: TrustPolicy, var: trust_policy}, {name: UrlLogo, var: url_logo}, {name: UseHybridPaymentOptions, var: use_hybrid_payment_options, required: true}, {name: UserName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, archive_id: $archive_id, cnpj: $cnpj, csc_identification: $csc_identification, catalog_system_endpoint: $catalog_system_endpoint, category_commission_percentage: $category_commission_percentage, delivery_policy: $delivery_policy, description: $description, email: $email, exchange_return_policy: $exchange_return_policy, freight_commission_percentage: $freight_commission_percentage, fulfillment_endpoint: $fulfillment_endpoint, fulfillment_seller_id: $fulfillment_seller_id, is_active: $is_active, is_better_scope: $is_better_scope, merchant_name: $merchant_name, name: $name, password: $password, product_commission_percentage: $product_commission_percentage, secutity_privacy_policy: $secutity_privacy_policy, seller_id: $seller_id, seller_type: $seller_type, trust_policy: $trust_policy, url_logo: $url_logo, use_hybrid_payment_options: $use_hybrid_payment_options, user_name: $user_name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Seller List
#
# GET /api/catalog_system/pvt/seller/list
# Returns: record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>
# operationId: SellerList
export def "seller-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade policy ID. (format: int32, e.g. 1)
  --seller-type: int # Seller type. (format: int32, e.g. 1)
  --is-better-scope: oneof<nothing, bool> # If the seller is better scope. (e.g. false)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/seller/list"
    query: [{name: sc, var: sc}, {name: sellerType, var: seller_type}, {name: isBetterScope, var: is_better_scope}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sc: $sc, seller_type: $seller_type, is_better_scope: $is_better_scope, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Seller by ID
#
# GET /api/catalog_system/pvt/seller/{sellerId}
# Returns: record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>
# operationId: GetSellerbyId
export def "get-sellerby-id" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/seller/{sellerId}"
    path_params: [{name: sellerId, var: seller_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Seller by ID
#
# GET /api/catalog_system/pvt/sellers/{sellerId}
# Returns: record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string>
# operationId: GetSellersbyId
export def "get-sellersby-id" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sellers/{sellerId}"
    path_params: [{name: sellerId, var: seller_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate attachments to an SKU
#
# POST /api/catalog_system/pvt/sku/associateattachments
# operationId: AssociateattachmentstoSKU
export def "associateattachmentsto-sku" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  attachment_names: list<string> # Array with all the names of the attachments that you need to associate to the SKU.
  sku_id: int # Unique identifier of the SKU. (e.g. 1)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/catalog_system/pvt/sku/associateattachments"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AttachmentNames, var: attachment_names}, {name: SkuId, var: sku_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, attachment_names: $attachment_names, sku_id: $sku_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU complements by type
#
# GET /api/catalog_system/pvt/sku/complements/{parentSkuId}/{type}
# Returns: record<ComplementSkuIds: list<int>, ParentSkuId: int, Type: string>
# operationId: GetSKUcomplementsbytype
export def "get-sk-ucomplementsbytype" [
  parent_sku_id: int
  type: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sku/complements/{parentSkuId}/{type}"
    path_params: [{name: parentSkuId, var: parent_sku_id}, {name: type, var: type}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    parent_sku_id: $parent_sku_id, type: $type, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU list by Product ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitByProductId/{productId}
# Returns: table<ActivateIfPossible: bool, CommercialConditionId: int, CubicWeight: float, DateUpdated: string, EstimatedDateArrival: string, FlagKitItensSellApart: bool, Height: float, Id: int, InternalNote: string, IsActive: bool, IsDynamicKit: string, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsPersisted: bool, IsRemoved: bool, IsTransported: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalId: int, ModalType: string, Name: string, Position: int, ProductId: int, RealHeight: float, RealLength: float, RealWeightKg: float, RealWidth: float, RefId: string, ReferenceStockKeepingUnitId: string, RewardValue: float, UnitMultiplier: float, WeightKg: float, Width: float, isKitOptimized: bool>
# operationId: SkulistbyProductId
export def "skulistby-product-id" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sku/stockkeepingunitByProductId/{productId}"
    path_params: [{name: productId, var: product_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU by Alternate ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyalternateId/{alternateId}
# Returns: record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, CategoriesFullPath: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsDirectCategoryActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, PositionsInClusters: record, ProductCategories: record, ProductCategoryIds: string, ProductClusterHighlights: record, ProductClusterNames: record, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float>
# operationId: SkubyAlternateId
export def "skuby-alternate-id" [
  alternate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sku/stockkeepingunitbyalternateId/{alternateId}"
    path_params: [{name: alternateId, var: alternate_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    alternate_id: $alternate_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU by EAN
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyean/{ean}
# Returns: record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, CategoriesFullPath: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsDirectCategoryActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, PositionsInClusters: record, ProductCategories: record, ProductCategoryIds: string, ProductClusterHighlights: record, ProductClusterNames: record, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float>
# operationId: SkubyEAN
export def "skuby-ean" [
  ean: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sku/stockkeepingunitbyean/{ean}"
    path_params: [{name: ean, var: ean}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    ean: $ean, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU and context
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyid/{skuId}
# Returns: record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, ProductCategories: record, ProductCategoryIds: string, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float>
# operationId: SkuContext
export def "sku-context" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy's unique identifier number. (e.g. 1)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sku/stockkeepingunitbyid/{skuId}"
    path_params: [{name: skuId, var: sku_id}]
    query: [{name: sc, var: sc}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, sc: $sc, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SKU ID by Reference ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitidbyrefid/{refId}
# Returns: string
# operationId: SkuIdbyRefId
export def "sku-idby-ref-id" [
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sku/stockkeepingunitidbyrefid/{refId}"
    path_params: [{name: refId, var: ref_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    ref_id: $ref_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all SKU IDs
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitids
# Returns: list<int>
# operationId: ListallSKUIDs
export def "listall-skui-ds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page from where you need to retrieve SKU IDs. (required, e.g. 1)
  --pagesize: int # Size of the page from where you need retrieve SKU IDs. The maximum value is `1000`. (required, e.g. 25)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sku/stockkeepingunitids"
    query: [{name: page, var: page, required: true}, {name: pagesize, var: pagesize, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    page: $page, pagesize: $pagesize, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all SKUs of a Trade Policy
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitidsbysaleschannel
# Returns: list<int>
export def "get-api-catalog-system-pvt-sku-stockkeepingunitidsbysaleschannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy’s unique numerical identifier. (required, e.g. 1)
  --page: int # Page number. (e.g. 1)
  --page-size: int # Number of items in the page. (e.g. 1)
  --only-assigned: oneof<nothing, bool> # If set as `false`, it allows the user to decide if the SKUs that are not assigned to a specific trade policy should be also returned. (e.g. true)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/sku/stockkeepingunitidsbysaleschannel"
    query: [{name: sc, var: sc, required: true}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: onlyAssigned, var: only_assigned}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sc: $sc, page: $page, page_size: $page_size, only_assigned: $only_assigned, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Notification with Seller ID and Seller SKU ID
#
# POST /api/catalog_system/pvt/skuseller/changenotification/{sellerId}/{sellerSkuId}
export def "post-api-catalog-system-pvt-skuseller-changenotification-seller-id-seller-sku-id" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/catalog_system/pvt/skuseller/changenotification/{sellerId}/{sellerSkuId}"
    path_params: [{name: sellerId, var: seller_id}, {name: sellerSkuId, var: seller_sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, seller_sku_id: $seller_sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Notification with SKU ID
#
# POST /api/catalog_system/pvt/skuseller/changenotification/{skuId}
# operationId: ChangeNotification
export def "change-notification" [
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
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/catalog_system/pvt/skuseller/changenotification/{skuId}"
    path_params: [{name: skuId, var: sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a seller's SKU binding
#
# POST /api/catalog_system/pvt/skuseller/remove/{sellerId}/{sellerSkuId}
# operationId: DeleteSKUsellerassociation
export def "delete-sk-usellerassociation" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/catalog_system/pvt/skuseller/remove/{sellerId}/{sellerSkuId}"
    path_params: [{name: sellerId, var: seller_id}, {name: sellerSkuId, var: seller_sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, seller_sku_id: $seller_sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of a seller's SKU
#
# GET /api/catalog_system/pvt/skuseller/{sellerId}/{sellerSkuId}
# Returns: record<IsActive: bool, IsPersisted: bool, IsRemoved: bool, RequestedUpdateDate: string, SellerId: string, SellerStockKeepingUnitId: string, SkuSellerId: int, StockKeepingUnitId: int, UpdateDate: string>
# operationId: GetSKUseller
export def "get-sk-useller" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/skuseller/{sellerId}/{sellerSkuId}"
    path_params: [{name: sellerId, var: seller_id}, {name: sellerSkuId, var: seller_sku_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, seller_sku_id: $seller_sku_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Specification Field
#
# POST /api/catalog_system/pvt/specification/field
# Returns: int
# operationId: SpecificationsInsertField
@deprecated --flag is-wizard
export def "specifications-insert-field" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --category-id: int # Category ID. (nullable)
  --default-value: string # Specification Field default Value. (nullable)
  --description: string # Specification Field Description. (nullable)
  field_group_id: int # Specification Field Group ID. (format: int32)
  field_group_name: string # Specification Field Group Name.
  --field-id: int # Specification Field ID. (nullable)
  field_type_id: int # Specification Field Type ID. (format: int32)
  --field-value-id: int # Specification Field Value ID. (nullable)
  --is-active: oneof<nothing, bool> # Defines if the Specification Field is active. The default value is `true`.
  --is-filter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar.
  --is-on-product-details: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page.
  --is-required: oneof<nothing, bool> # Makes the Specification Field mandatory (`true`) or optional (`false`).
  --is-side-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar.
  --is-stock-keeping-unit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification. If `false`, it will be added as a product specification field.
  --is-top-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu.
  --is-wizard: oneof<nothing, bool> # Deprecated field. (DEPRECATED)
  name: string # Specification Field ID.
  position: int # Specification Field Position. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/catalog_system/pvt/specification/field"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryId, var: category_id}, {name: DefaultValue, var: default_value}, {name: Description, var: description}, {name: FieldGroupId, var: field_group_id}, {name: FieldGroupName, var: field_group_name}, {name: FieldId, var: field_id}, {name: FieldTypeId, var: field_type_id}, {name: FieldValueId, var: field_value_id}, {name: IsActive, var: is_active, required: true}, {name: IsFilter, var: is_filter, required: true}, {name: IsOnProductDetails, var: is_on_product_details, required: true}, {name: IsRequired, var: is_required, required: true}, {name: IsSideMenuLinkActive, var: is_side_menu_link_active, required: true}, {name: IsStockKeepingUnit, var: is_stock_keeping_unit, required: true}, {name: IsTopMenuLinkActive, var: is_top_menu_link_active, required: true}, {name: IsWizard, var: is_wizard, required: true}, {name: Name, var: name}, {name: Position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, category_id: $category_id, default_value: $default_value, description: $description, field_group_id: $field_group_id, field_group_name: $field_group_name, field_id: $field_id, field_type_id: $field_type_id, field_value_id: $field_value_id, is_active: $is_active, is_filter: $is_filter, is_on_product_details: $is_on_product_details, is_required: $is_required, is_side_menu_link_active: $is_side_menu_link_active, is_stock_keeping_unit: $is_stock_keeping_unit, is_top_menu_link_active: $is_top_menu_link_active, is_wizard: $is_wizard, name: $name, position: $position
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Specification Field
#
# PUT /api/catalog_system/pvt/specification/field
# Returns: int
# operationId: SpecificationsInsertFieldUpdate
@deprecated --flag is-wizard
export def "specifications-insert-field-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --category-id: int # Category ID. (nullable)
  --default-value: string # Specification Field default Value. (nullable)
  --description: string # Specification Field Description. (nullable)
  field_group_id: int # Specification Field Group ID. (format: int32)
  field_group_name: string # Specification Field Group Name.
  --field-id: int # Specification Field ID. (nullable)
  field_type_id: int # Specification Field Type ID. (format: int32)
  --field-value-id: int # Specification Field Value ID. (nullable)
  --is-active: oneof<nothing, bool> # Enables(`true`) or disables (`false`) the Specification Field. (e.g. true)
  --is-filter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar.
  --is-on-product-details: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page.
  --is-required: oneof<nothing, bool> # Makes the Specification Field mandatory (`true`) or optional (`false`).
  --is-side-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar. (e.g. false)
  --is-stock-keeping-unit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification field. If `false`, it will be added as a product specification field.
  --is-top-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu.
  --is-wizard: oneof<nothing, bool> # Deprecated field. (DEPRECATED)
  name: string # Specification Field ID.
  position: int # Specification Field Position. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/catalog_system/pvt/specification/field"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryId, var: category_id}, {name: DefaultValue, var: default_value}, {name: Description, var: description}, {name: FieldGroupId, var: field_group_id}, {name: FieldGroupName, var: field_group_name}, {name: FieldId, var: field_id}, {name: FieldTypeId, var: field_type_id}, {name: FieldValueId, var: field_value_id}, {name: IsActive, var: is_active, required: true}, {name: IsFilter, var: is_filter, required: true}, {name: IsOnProductDetails, var: is_on_product_details, required: true}, {name: IsRequired, var: is_required, required: true}, {name: IsSideMenuLinkActive, var: is_side_menu_link_active, required: true}, {name: IsStockKeepingUnit, var: is_stock_keeping_unit, required: true}, {name: IsTopMenuLinkActive, var: is_top_menu_link_active, required: true}, {name: IsWizard, var: is_wizard, required: true}, {name: Name, var: name}, {name: Position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, category_id: $category_id, default_value: $default_value, description: $description, field_group_id: $field_group_id, field_group_name: $field_group_name, field_id: $field_id, field_type_id: $field_type_id, field_value_id: $field_value_id, is_active: $is_active, is_filter: $is_filter, is_on_product_details: $is_on_product_details, is_required: $is_required, is_side_menu_link_active: $is_side_menu_link_active, is_stock_keeping_unit: $is_stock_keeping_unit, is_top_menu_link_active: $is_top_menu_link_active, is_wizard: $is_wizard, name: $name, position: $position
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Specification Field Value
#
# POST /api/catalog_system/pvt/specification/fieldValue
# Returns: record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>
# operationId: SpecificationsInsertFieldValue
export def "specifications-insert-field-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  field_id: int # Specification Field ID. (format: int32)
  --is-active: oneof<nothing, bool> # Defines if the Specification Field Value is active (`true`) or inactive (`false`).
  name: string # Specification Field Value Name.
  position: int # Specification Field Value Position. (format: int32)
  text: string # Specification Field Value Description.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/catalog_system/pvt/specification/fieldValue"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldId, var: field_id}, {name: IsActive, var: is_active, required: true}, {name: Name, var: name}, {name: Position, var: position}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, field_id: $field_id, is_active: $is_active, name: $name, position: $position, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Specification Field Value
#
# PUT /api/catalog_system/pvt/specification/fieldValue
# Returns: string
# operationId: SpecificationsUpdateFieldValue
export def "specifications-update-field-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --field-id: int # Specification Field ID. (nullable)
  --is-active: oneof<nothing, bool> # Defines if the Specification Field Value is active (`true`) or inactive (`false`).
  name: string # Specification Field Value Name.
  position: int # Specification Field Position. (format: int32)
  --text: string # Specification Field Value Description. (nullable)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/catalog_system/pvt/specification/fieldValue"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FieldId, var: field_id}, {name: IsActive, var: is_active, required: true}, {name: Name, var: name}, {name: Position, var: position}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, field_id: $field_id, is_active: $is_active, name: $name, position: $position, text: $text
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specification Field Value
#
# GET /api/catalog_system/pvt/specification/fieldValue/{fieldValueId}
# Returns: record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string>
# operationId: SpecificationsGetFieldValue
export def "specifications-get-field-value" [
  field_value_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/specification/fieldValue/{fieldValueId}"
    path_params: [{name: fieldValueId, var: field_value_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    field_value_id: $field_value_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Specification Group by Category
#
# GET /api/catalog_system/pvt/specification/groupbycategory/{categoryId}
# Returns: table<CategoryId: int, Id: int, Name: string, Position: int>
# operationId: SpecificationsGroupListbyCategory
export def "specifications-group-listby-category" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/catalog_system/pvt/specification/groupbycategory/{categoryId}"
    path_params: [{name: categoryId, var: category_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CATALOG_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CATALOG_API_APPTOKEN_TOKEN}]
  } {
    category_id: $category_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
