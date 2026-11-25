# Auto-generated client for Swagger API2Cart v1.1
# Source: https://api.apis.guru/v2/specs/api2cart.com/1.1/openapi.json
# Auth: --token flag or $env.SWAGGER_API2CART_TOKEN
# Auth (api_key): --token-apikey flag or $env.SWAGGER_API2CART_APIKEY_TOKEN
# Auth (store_key): --token-storekey flag or $env.SWAGGER_API2CART_STOREKEY_TOKEN

const CLIENT = {
  base_url: "https://api.api2cart.com/v1.1"
  token_env_var: "SWAGGER_API2CART_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: x-api-key, prefix: ""}
    {name: x-store-key, in: header, header_name: x-store-key, prefix: ""}
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

def base-url-completer [] { ["https://api.api2cart.com/v1.1"] }
def auth-scheme-completer [] { ["x-api-key" "x-store-key"] }

# Completers for enum parameters
def amazon-sp-aws-region-completer [] { ["eu-west-1" "us-east-1" "us-west-2"] }
def cart-id-completer [] { ["3DCart" "3DCartApi" "AceShop" "Amazon" "AmazonSP" "AspDotNetStorefront" "BigcommerceApi" "CommerceHQ" "Creloaded" "Cscart" "Cubecart" "Demandware" "EBay" "Ecwid" "Etsy" "EtsyAPIv3" "Gambio" "Hybris" "Interspire" "JooCart" "LightSpeed" "Magento1212" "Magento2Api" "MercadoLibre" "MijoShop" "Neto" "Opencart14" "Oscmax2" "Oscommerce22ms2" "Oxid" "Pinnacle" "Prestashop" "PrestashopApi" "SSPremium" "Shopify" "Shopware" "ShopwareApi" "Squarespace" "Tomatocart" "Ubercart" "Virtuemart" "Volusion" "WPecommerce" "Walmart" "WebAsyst" "Wix" "Woocommerce" "WoocommerceApi" "Xcart" "Xtcommerce" "XtcommerceVeyton" "Zencart137" "Zid"] }
def type-completer [] { ["boolean" "date" "multiselect" "price" "select" "text" "textarea"] }
def action-apply-to-completer [] { ["item_price" "order_total" "shipping"] }
def action-scope-completer [] { ["matching_items" "order"] }
def action-type-completer [] { ["fixed" "percent"] }
def entity-completer [] { ["customer" "order" "order_shipping_address" "product"] }
def key-completer [] { ["category_id" "country" "customer_id" "item_price" "item_quantity" "item_total_price" "product_id" "shipping_total" "subtotal" "total" "total_quantity" "total_weight" "variant_id"] }
def operator-completer [] { ["<" "<=" "==" ">" ">=" "ONE_OF"] }
def type-completer-1 [] { ["base" "thumbnail"] }
def type-completer-2 [] { ["additional" "base" "small" "thumbnail"] }
def type-completer-3 [] { ["option_type_checkbox" "option_type_date" "option_type_datetime" "option_type_file" "option_type_multicheckbox" "option_type_multiselect" "option_type_radio" "option_type_readonly" "option_type_select" "option_type_text" "option_type_textarea" "option_type_time"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-apikey" "token-storekey"]
  let return_types = {
    account-cart-add: "record<result: record<store_key: string>, return_code: int, return_message: string>"
    account-cart-list: "record<result: record<carts: list<record>, carts_count: int>, return_code: int, return_message: string>"
    account-config-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    account-failed-webhooks: "record<result: record<all_failed_webhook: string, webhook: list<record>>, return_code: int, return_message: string>"
    account-supported-platforms: "record<result: record<supported_platforms: list<record>>, return_code: int, return_message: string>"
    attribute-add: "record<result: record<id: string>, return_code: int, return_message: string>"
    attribute-assign-group: "record<result: record<assigned: string>, return_code: int, return_message: string>"
    attribute-assign-set: "record<result: record<assigned: string>, return_code: int, return_message: string>"
    attribute-attributeset-list: "record<result: table<additional_fields: record, assigned_attribute_ids: list, attribute_set_id: string, custom_fields: record, id: string, name: string, position: int>, return_code: int, return_message: string>"
    attribute-count: "record<result: record<attributes_count: int>, return_code: int, return_message: string>"
    attribute-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    attribute-group-list: "record<result: table<additional_fields: record, assigned_attribute_ids: list, attribute_set_id: string, custom_fields: record, id: string, name: string, position: int>, return_code: int, return_message: string>"
    attribute-info: "record<result: record<additional_fields: record, code: string, custom_fields: record, default_values: list<string>, id: string, lang_id: string, name: string, position: int, required: bool, store_id: string, system: bool, type: string, values: list<string>, visible: bool>, return_code: int, return_message: string>"
    attribute-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, attribute: list<record>, attributes_count: int, custom_fields: record>, return_code: int, return_message: string>"
    attribute-type-list: "record<result: record<attribute_type: list<string>>, return_code: int, return_message: string>"
    attribute-unassign-group: "record<result: record<unassigned: string>, return_code: int, return_message: string>"
    attribute-unassign-set: "record<result: record<unassigned: string>, return_code: int, return_message: string>"
    attribute-update: "record<result: record<updated: bool>, return_code: int, return_message: string>"
    basket-info: "record<result: record<additional_fields: record, basket_products: list<record>, basket_url: string, created_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, currency: record<additional_fields: record, avail: bool, custom_fields: record, default: bool, id: string, iso3: string, name: string, rate: float, symbol_left: string, symbol_right: string>, custom_fields: record, customer: record<additional_fields: record, custom_fields: record, email: string, first_name: string, id: string, last_name: string, phone: string>, id: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>>, return_code: int, return_message: string>"
    basket-item-add: "record<result: record<added: bool>, return_code: int, return_message: string>"
    basket-live-shipping-service-create: "record<result: record<id: int>, return_code: int, return_message: string>"
    basket-live-shipping-service-delete: "record<result: record<status: bool>, return_code: int, return_message: string>"
    basket-live-shipping-service-list: "record<result: record<live_shipping_services: list<record>>, return_code: int, return_message: string>"
    bridge-delete: "record<result: record<deleted: bool>, return_code: int, return_message: string>"
    bridge-download: "binary"
    bridge-update: "record<result: record<updated: bool>, return_code: int, return_message: string>"
    cart-bridge: "record<result: record<bridge: string, store_key: string>, return_code: int, return_message: string>"
    cart-catalog-price-rules-count: "record<result: record<catalog_price_rules_count: string>, return_code: int, return_message: string>"
    cart-catalog-price-rules-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, catalog_price_rules: list<record>, catalog_price_rules_count: int, custom_fields: record>, return_code: int, return_message: string>"
    cart-clear-cache: "record<result: record<cache_cleared: string>, return_code: int, return_message: string>"
    cart-config: "record<result: record<db_prefix: string, store_name: string, store_url: string>, return_code: int, return_message: string>"
    cart-config-update: "record<result: record, return_code: int, return_message: string>"
    cart-coupon-add: "record<result: record<coupon_id: string>, return_code: int, return_message: string>"
    cart-coupon-condition-add: "record<result: record<status: bool>, return_code: int, return_message: string>"
    cart-coupon-count: "record<result: record<coupons_count: string>, return_code: int, return_message: string>"
    cart-coupon-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    cart-coupon-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, coupon: list<record>, coupon_count: int, custom_fields: record>, return_code: int, return_message: string>"
    cart-create: "record<result: record<store_key: string>, return_code: int, return_message: string>"
    cart-delete: "record<result: record<store: string>, return_code: int, return_message: string>"
    cart-disconnect: "record<result: record<connection: string>, return_code: int, return_message: string>"
    cart-giftcard-add: "record<result: record<code: string, id: string>, return_code: int, return_message: string>"
    cart-giftcard-count: "record<result: record<gift_cards_count: string>, return_code: int, return_message: string>"
    cart-giftcard-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, gift_card: list<record>>, return_code: int, return_message: string>"
    cart-info: "record<result: record<additional_fields: record, custom_fields: record, db_prefix: string, name: string, shipping_zones: list<record>, stores_info: list<record>, url: string, version: string, warehouses: list<record>>, return_code: int, return_message: string>"
    cart-list: "record<result: record<supported_carts: list<record>>, return_code: int, return_message: string>"
    cart-meta-data-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, items: list<record>, total_count: int>, return_code: int, return_message: string>"
    cart-meta-data-set: "record<result: record<id: string>, return_code: int, return_message: string>"
    cart-meta-data-unset: "record<result: record<status: bool>, return_code: int, return_message: string>"
    cart-methods: "record<result: record<method: list<string>>, return_code: int, return_message: string>"
    cart-plugin-list: "record<result: record<all_plugins: int, plugins: list<record>>, return_code: int, return_message: string>"
    cart-script-add: "record<result: record<script_id: string>, return_code: int, return_message: string>"
    cart-script-delete: "record<result: record<deleted: bool>, return_code: int, return_message: string>"
    cart-script-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, scripts: list<record>, total_count: int>, return_code: int, return_message: string>"
    cart-shipping-zones-list: "record<result: record<additional_fields: record, code: string, country: string, country_iso2_codes: list<string>, custom_fields: record, id: string, name: string>, return_code: int, return_message: string>"
    cart-validate: "record<result: record<status: string>, return_code: int, return_message: string>"
    category-add: "record<result: record<category_id: string>, return_code: int, return_message: string>"
    category-assign: "record<result: record, return_code: int, return_message: string>"
    category-count: "record<result: record<categories_count: int>, return_code: int, return_message: string>"
    category-delete: "record<result: record<deleted: bool>, return_code: int, return_message: string>"
    category-find: "record<result: record<category: list<record>>, return_code: int, return_message: string>"
    category-image-add: "record<result: record<image_path: string>, return_code: int, return_message: string>"
    category-image-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    category-info: "record<result: record<additional_fields: record, avail: bool, created_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, id: string, images: list<record>, keywords: string, meta_description: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, parent_id: string, path: string, seo_url: string, short_description: string, sort_order: int, stores_ids: list<string>>, return_code: int, return_message: string>"
    category-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, categories_count: int, category: list<record>, custom_fields: record>, return_code: int, return_message: string>"
    category-unassign: "record<result: record, return_code: int, return_message: string>"
    category-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    customer-add: "record<result: record<customer_id: string>, return_code: int, return_message: string>"
    customer-attribute-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, items: list<record>, total_count: int>, return_code: int, return_message: string>"
    customer-count: "record<result: record<customers_count: int>, return_code: int, return_message: string>"
    customer-find: "record<result: record<email: string, first_name: string, id: string, last_name: string>, return_code: int, return_message: string>"
    customer-group-add: "record<result: record, return_code: int, return_message: string>"
    customer-group-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, group: list<record>, group_count: int>, return_code: int, return_message: string>"
    customer-info: "record<result: record<additional_fields: record, address_book: list<record>, birth_day: record<additional_fields: record, custom_fields: record, format: string, value: string>, company: string, created_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, email: string, fax: string, first_name: string, gender: string, group: list<record>, id: string, ip_address: string, last_login: record<additional_fields: record, custom_fields: record, format: string, value: string>, last_name: string, last_order_id: string, login: string, modified_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, news_letter_subscription: bool, orders_count: int, phone: string, status: string, stores_ids: list<string>, website: string>, return_code: int, return_message: string>"
    customer-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, customer: list<record>, customers_count: int>, return_code: int, return_message: string>"
    customer-update: "record<result: record<updated: string>, return_code: int, return_message: string>"
    order-abandoned-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, order: list<record>>, return_code: int, return_message: string>"
    order-add: "record<result: record<order_id: string>, return_code: int, return_message: string>"
    order-count: "record<result: record<orders_count: int>, return_code: int, return_message: string>"
    order-financial-status-list: "record<result: record<order_financial_statuses: list<record>>, return_code: int, return_message: string>"
    order-find: "record<result: record<order: list<record>>, return_code: int, return_message: string>"
    order-fulfillment-status-list: "record<result: record<order_fulfillment_statuses: list<record>>, return_code: int, return_message: string>"
    order-info: "record<result: record<additional_fields: record, basket_id: string, billing_address: record<additional_fields: record, address1: string, address2: string, city: string, company: string, country: record, custom_fields: record, default: bool, fax: string, first_name: string, gender: string, id: string, last_name: string, phone: string, postcode: string, region: string, state: record, type: string, website: string>, bundles: list<record>, channel_id: string, comment: string, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, currency: record<additional_fields: record, avail: bool, custom_fields: record, default: bool, id: string, iso3: string, name: string, rate: float, symbol_left: string, symbol_right: string>, custom_fields: record, customer: record<additional_fields: record, custom_fields: record, email: string, first_name: string, id: string, last_name: string, phone: string>, discounts: list<record>, finished_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, gift_message: string, id: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, order_details_url: string, order_id: string, order_products: list<record>, payment_method: record<additional_fields: record, custom_fields: record, name: string>, refunds: list<record>, shipping_address: record<additional_fields: record, address1: string, address2: string, city: string, company: string, country: record, custom_fields: record, default: bool, fax: string, first_name: string, gender: string, id: string, last_name: string, phone: string, postcode: string, region: string, state: record, type: string, website: string>, shipping_method: record<additional_fields: record, custom_fields: record, name: string>, shipping_methods: list<record>, status: record<additional_fields: record, custom_fields: record, history: list, id: string, name: string, refund_info: record>, store_id: string, total: record<additional_fields: record, custom_fields: record, shipping_ex_tax: float, subtotal_ex_tax: float, total: float, total_discount: float, total_paid: float, total_tax: float, wrapping_ex_tax: float>, totals: record<additional_fields: record, custom_fields: record, discount: float, shipping: float, subtotal: float, tax: float, total: float>, warehouses_ids: list<string>>, return_code: int, return_message: string>"
    order-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, order: list<record>, orders_count: int>, return_code: int, return_message: string>"
    order-preestimate-shipping-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, preestimate_shippings: list<record>, preestimate_shippings_count: int>, return_code: int, return_message: string>"
    order-refund-add: "record<result: record<refund_id: string>, return_code: int, return_message: string>"
    order-shipment-add: "record<result: record<shipment_id: string>, return_code: int, return_message: string>"
    order-shipment-delete: "record<result: record<status: int>, return_code: int, return_message: string>"
    order-shipment-info: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, shipment: list<record>, shipment_count: int>, return_code: int, return_message: string>"
    order-shipment-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, shipment: list<record>, shipment_count: int>, return_code: int, return_message: string>"
    order-shipment-tracking-add: "record<result: record<tracking_id: string>, return_code: int, return_message: string>"
    order-shipment-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    order-status-list: "record<result: record<cart_order_statuses: list<record>>, return_code: int, return_message: string>"
    order-transaction-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, transactions: list<record>, transactions_count: int>, return_code: int, return_message: string>"
    order-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    product-add: "record<result: record<product_id: string>, return_code: int, return_message: string>"
    product-attribute-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, attribute: list<record>, custom_fields: record>, return_code: int, return_message: string>"
    product-attribute-value-set: "record<result: record<attribute_id: string, product_id: string, value_id: string>, return_code: int, return_message: string>"
    product-attribute-value-unset: "record<result: record<success: string>, return_code: int, return_message: string>"
    product-brand-list: "record<result: record<product: list<record>>, return_code: int, return_message: string>"
    product-child-item-find: "record<result: record<children: list<record>>, return_code: int, return_message: string>"
    product-child-item-info: "record<result: record<additional_fields: record, advanced_price: list<record>, allow_backorders: bool, avail_for_sale: bool, combination: list<record>, cost_price: float, created_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, default_price: float, default_qty_in_pack: float, dimensions_unit: string, ean: string, full_description: string, gtin: string, height: float, id: string, images: list<record>, in_stock: bool, inventory: list<record>, inventory_level: float, is_qty_in_pack_fixed: bool, isbn: string, length: float, list_price: float, manage_stock: bool, meta_description: string, meta_keywords: string, meta_title: string, min_quantity: float, modified_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, mpn: string, name: string, parent_id: string, short_description: string, sku: string, sort_order: int, tax_class_id: string, upc: string, weight: float, weight_unit: string, wholesale_price: float, width: float>, return_code: int, return_message: string>"
    product-child-item-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, children: list<record>, custom_fields: record, total_count: int>, return_code: int, return_message: string>"
    product-count: "record<result: record<products_count: int>, return_code: int, return_message: string>"
    product-currency-add: "record<result: record<currency_id: string>, return_code: int, return_message: string>"
    product-currency-list: "record<result: record<currency: list<record>>, return_code: int, return_message: string>"
    product-delete: "record<result: record<delete_items: int>, return_code: int, return_message: string>"
    product-fields: "record<result: record, return_code: int, return_message: string>"
    product-find: "record<result: record<product: list<record>>, return_code: int, return_message: string>"
    product-image-add: "record<result: record<id: string, image_path: string>, return_code: int, return_message: string>"
    product-image-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    product-image-update: "record<result: record<updated: string>, return_code: int, return_message: string>"
    product-info: "record<result: record<additional_fields: record, advanced_price: list<record>, avail_sale: bool, avail_view: bool, backorders: string, categories_ids: list<string>, cost_price: float, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, dimensions_unit: string, group_items: list<record>, group_price: list<record>, height: float, id: string, images: list<record>, inventory: list<record>, is_downloadable: bool, is_stock_managed: bool, is_virtual: bool, length: float, manage_stock: string, meta_description: string, meta_keywords: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, price: float, product_options: list<record>, quantity: float, related_products_ids: list<string>, seo_url: string, short_description: string, sort_order: int, special_price: record<additional_fields: record, avail: bool, created_at: record, custom_fields: record, expired_at: record, modified_at: record, value: float>, stores_ids: list<string>, tax_class_id: string, tier_price: list<record>, type: string, u_brand: string, u_brand_id: string, u_model: string, u_mpn: string, u_sku: string, u_upc: string, url: string, weight: float, weight_unit: string, width: float>, return_code: int, return_message: string>"
    product-list: "record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, product: list<record>, products_count: int>, return_code: int, return_message: string>"
    product-manufacturer-add: "record<result: record<manufacturer_id: string>, return_code: int, return_message: string>"
    product-option-add: "record<result: record<option_id: string, product_option_id: string>, return_code: int, return_message: string>"
    product-option-assign: "record<result: record<product_option_id: string>, return_code: int, return_message: string>"
    product-option-list: "record<result: record<option: list<record>>, return_code: int, return_message: string>"
    product-option-value-add: "record<result: record<option_value_id: string>, return_code: int, return_message: string>"
    product-option-value-assign: "record<result: record<product_option_value_id: string>, return_code: int, return_message: string>"
    product-option-value-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    product-price-add: "record<result: record<status: string>, return_code: int, return_message: string>"
    product-price-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    product-price-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    product-review-list: "record<result: record<reviews: list<record>, total_count: int>, return_code: int, return_message: string>"
    product-store-assign: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    product-tax-add: "record<result: record<tax_class_id: string>, return_code: int, return_message: string>"
    product-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    product-variant-add: "record<result: record<product_variant_id: string>, return_code: int, return_message: string>"
    product-variant-count: "record<result: record<variants_count: string>, return_code: int, return_message: string>"
    product-variant-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    product-variant-image-add: "record<result: record<id: string, image_path: string>, return_code: int, return_message: string>"
    product-variant-image-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    product-variant-info: "record<result: record<additional_fields: record, advanced_price: list<record>, avail_sale: bool, avail_view: bool, backorders: string, categories_ids: list<string>, cost_price: float, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, dimensions_unit: string, group_items: list<record>, group_price: list<record>, height: float, id: string, images: list<record>, inventory: list<record>, is_downloadable: bool, is_stock_managed: bool, is_virtual: bool, length: float, manage_stock: string, meta_description: string, meta_keywords: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, price: float, product_options: list<record>, quantity: float, related_products_ids: list<string>, seo_url: string, short_description: string, sort_order: int, special_price: record<additional_fields: record, avail: bool, created_at: record, custom_fields: record, expired_at: record, modified_at: record, value: float>, stores_ids: list<string>, tax_class_id: string, tier_price: list<record>, type: string, u_brand: string, u_brand_id: string, u_model: string, u_mpn: string, u_sku: string, u_upc: string, url: string, weight: float, weight_unit: string, width: float>, return_code: int, return_message: string>"
    product-variant-list: "record<result: record<variant: list<record>>, return_code: int, return_message: string>"
    product-variant-price-add: "record<result: record<status: string>, return_code: int, return_message: string>"
    product-variant-price-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    product-variant-price-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    product-variant-update: "record<result: record<updated_items: int>, return_code: int, return_message: string>"
    subscriber-list: "record<result: record<subscribers: list<record>, total_count: int>, return_code: int, return_message: string>"
    tax-class-info: "record<result: record<additional_fields: record, avail: bool, custom_fields: record, id: string, name: string, tax: float, tax_rates: list<record>, tax_type: int>, return_code: int, return_message: string>"
    webhook-count: "record<result: record<webhook_count: int>, return_code: int, return_message: string>"
    webhook-create: "record<result: record<id: string>, return_code: int, return_message: string>"
    webhook-delete: "record<result: record<deleted: string>, return_code: int, return_message: string>"
    webhook-events: "record<result: record<events: list<record>>, return_code: int, return_message: string>"
    webhook-list: "record<result: record<webhook: list<record>>, return_code: int, return_message: string>"
    webhook-update: "record<result: record<updated: string>, return_code: int, return_message: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["account-cart-add" "account-cart-list" "account-config-update" "account-failed-webhooks" "account-supported-platforms" "attribute-add" "attribute-assign-group" "attribute-assign-set" "attribute-attributeset-list" "attribute-count" "attribute-delete" "attribute-group-list" "attribute-info" "attribute-list" "attribute-type-list" "attribute-unassign-group" "attribute-unassign-set" "attribute-update" "basket-info" "basket-item-add" "basket-live-shipping-service-create" "basket-live-shipping-service-delete" "basket-live-shipping-service-list" "bridge-delete" "bridge-download" "bridge-update" "cart-bridge" "cart-catalog-price-rules-count" "cart-catalog-price-rules-list" "cart-clear-cache" "cart-config" "cart-config-update" "cart-coupon-add" "cart-coupon-condition-add" "cart-coupon-count" "cart-coupon-delete" "cart-coupon-list" "cart-create" "cart-delete" "cart-disconnect" "cart-giftcard-add" "cart-giftcard-count" "cart-giftcard-list" "cart-info" "cart-list" "cart-meta-data-list" "cart-meta-data-set" "cart-meta-data-unset" "cart-methods" "cart-plugin-list" "cart-script-add" "cart-script-delete" "cart-script-list" "cart-shipping-zones-list" "cart-validate" "category-add" "category-assign" "category-count" "category-delete" "category-find" "category-image-add" "category-image-delete" "category-info" "category-list" "category-unassign" "category-update" "customer-add" "customer-attribute-list" "customer-count" "customer-find" "customer-group-add" "customer-group-list" "customer-info" "customer-list" "customer-update" "order-abandoned-list" "order-add" "order-count" "order-financial-status-list" "order-find" "order-fulfillment-status-list" "order-info" "order-list" "order-preestimate-shipping-list" "order-refund-add" "order-shipment-add" "order-shipment-delete" "order-shipment-info" "order-shipment-list" "order-shipment-tracking-add" "order-shipment-update" "order-status-list" "order-transaction-list" "order-update" "product-add" "product-attribute-list" "product-attribute-value-set" "product-attribute-value-unset" "product-brand-list" "product-child-item-find" "product-child-item-info" "product-child-item-list" "product-count" "product-currency-add" "product-currency-list" "product-delete" "product-fields" "product-find" "product-image-add" "product-image-delete" "product-image-update" "product-info" "product-list" "product-manufacturer-add" "product-option-add" "product-option-assign" "product-option-list" "product-option-value-add" "product-option-value-assign" "product-option-value-update" "product-price-add" "product-price-delete" "product-price-update" "product-review-list" "product-store-assign" "product-tax-add" "product-update" "product-variant-add" "product-variant-count" "product-variant-delete" "product-variant-image-add" "product-variant-image-delete" "product-variant-info" "product-variant-list" "product-variant-price-add" "product-variant-price-delete" "product-variant-price-update" "product-variant-update" "subscriber-list" "tax-class-info" "webhook-count" "webhook-create" "webhook-delete" "webhook-events" "webhook-list" "webhook-update" "commands"] | sort) } | get name | first)
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

# Add store to the account
#
# POST /account.cart.add.json
# Returns: record<result: record<store_key: string>, return_code: int, return_message: string>
# operationId: AccountCartAdd
export def "account-cart-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --3dcart-access-token: string # 3DCart Token
  --3dcart-private-key: string # 3DCart Private Key
  --3dcartapi-api-key: string # 3DCart API Key
  --amazon-access-key-id: string # Amazon Secret Key Id
  --amazon-access-token: string # MWS Auth Token. Access token authorizing the app to access resources on behalf of a user
  --amazon-marketplaces-ids: string # Amazon Marketplace IDs comma separated string
  --amazon-secret-key: string # Amazon Secret Key
  --amazon-seller-id: string # Amazon Seller ID (Merchant token)
  --amazon-sp-api-environment: string # Amazon SP API environment (default: production)
  amazon_sp_aws_region: string@amazon-sp-aws-region-completer # Amazon AWS Region
  amazon_sp_aws_role_arn: string # Amazon AWS Role ARN
  amazon_sp_aws_user_key_id: string # Amazon AWS user access key ID
  amazon_sp_aws_user_secret: string # Amazon AWS user secret access key
  amazon_sp_client_id: string # Amazon SP API app client id
  amazon_sp_client_secret: string # Amazon SP API app client secret
  amazon_sp_refresh_token: string # Amazon SP API OAuth refresh token
  --aspdotnetstorefront-api-pass: string # AspDotNetStorefront API Password
  --aspdotnetstorefront-api-user: string # It's a AspDotNetStorefront account for which API is available
  --bigcommerceapi-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --bigcommerceapi-admin-account: string # It's a BigCommerce account for which API is enabled
  --bigcommerceapi-api-key: string # Bigcommerce API Key
  --bigcommerceapi-api-path: string # BigCommerce API URL
  --bigcommerceapi-client-id: string # Client ID of the requesting app
  --bigcommerceapi-context: string # API Path section unique to the store
  --bridge-url: string # This parameter allows to set up store with custom bridge url (also you must use store_root parameter if a bridge folder is not in the root folder of the store)
  cart_id: string@cart-id-completer # Store’s identifier which you can get from cart_list method
  --commercehq-api-key: string # CommerceHQ api key
  --commercehq-api-password: string # CommerceHQ api password
  --db-tables-prefix: string # DB tables prefix
  --demandware-api-password: string # Demandware api password
  --demandware-client-id: string # Demandware client id
  --demandware-user-name: string # Demandware user name
  --demandware-user-password: string # Demandware user password
  --ebay-access-token: string # Used to authenticate API requests.
  --ebay-client-id: string # Application ID (AppID).
  --ebay-client-secret: string # Shared Secret from eBay application
  --ebay-environment: string # eBay environment (default: production)
  --ebay-refresh-token: string # Used to renew the access token.
  --ebay-runame: string # The RuName value that eBay assigns to your application.
  --ebay-site-id: int # eBay global ID (default: 0)
  --ecwid-acess-token: string # Access token authorizing the app to access resources on behalf of a user
  --ecwid-store-id: string # Store Id
  --etsy-access-token: string # Access token authorizing the app to access resources on behalf of a user
  etsy_client_id: string # Etsy Client Id
  --etsy-keystring: string # Etsy keystring
  etsy_refresh_token: string # Etsy Refresh token
  --etsy-shared-secret: string # Etsy shared secret
  --etsy-token-secret: string # Secret token authorizing the app to access resources on behalf of a user
  --ftp-host: string # FTP connection host
  --ftp-password: string # FTP Password
  --ftp-port: int # FTP Port
  --ftp-store-dir: string # FTP Store dir
  --ftp-user: string # FTP User
  --hybris-client-id: string # Omni Commerce Connector Client ID
  --hybris-client-secret: string # Omni Commerce Connector Client Secret
  --hybris-password: string # User password
  --hybris-username: string # User Name
  --hybris-websites: list # Websites to stores mapping data — item shape: {storeIds: list<string>, uid: string, url: string}
  --lightspeed-api-key: string # LightSpeed api key
  --lightspeed-api-secret: string # LightSpeed api secret
  --magento-access-token: string # Magento Access Token
  --magento-consumer-key: string # Magento Consumer Key
  --magento-consumer-secret: string # Magento Consumer Secret
  --magento-token-secret: string # Magento Token Secret
  --mercado-libre-app-id: string # Mercado Libre App ID
  --mercado-libre-app-secret-key: string # Mercado Libre App Secret Key
  --mercado-libre-refresh-token: string # Mercado Libre Refresh Token
  --neto-api-key: string # Neto API Key
  --neto-api-username: string # Neto User Name
  --prestashop-webservice-key: string # Prestashop webservice key
  --shopify-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --shopify-api-key: string # Shopify API Key
  --shopify-api-password: string # Shopify API Password
  --shopify-shared-secret: string # Shared secret
  --shopware-access-key: string # Shopware access key
  --shopware-api-key: string # Shopware api key
  --shopware-api-secret: string # Shopware client secret access key
  --squarespace-api-key: string # Squarespace API Key
  --store-key: string # Set this parameter if bridge is already uploaded to store
  --store-root: string # Absolute path to the store root directory (used with "bridge_url" parameter)
  store_url: string # A web address of a store that you would like to connect to API2Cart
  --validate-version: oneof<nothing, bool> # Specify if api2cart should validate cart version (default: false)
  --verify: oneof<nothing, bool> # Enables or disables cart's verification (default: true)
  --volusion-login: string # It's a Volusion account for which API is enabled
  --volusion-password: string # Volusion API Password
  --walmart-channel-type: string # Walmart WM_CONSUMER.CHANNEL.TYPE header
  --walmart-client-id: string # Walmart client ID
  --walmart-client-secret: string # Walmart client secret
  --walmart-environment: string # Walmart environment (default: production)
  --wc-consumer-key: string # Woocommerce consumer key
  --wc-consumer-secret: string # Woocommerce consumer secret
  --wix-app-id: string # Wix App ID
  --wix-app-secret-key: string # Wix App Secret Key
  --wix-refresh-token: string # Wix refresh token
  --zid-access-token: string # Zid Access Token
  --zid-authorization: string # Zid Authorization
  --zid-client-id: int # Zid Client ID
  --zid-client-secret: string # Zid Client Secret
  --zid-refresh-token: string # Zid refresh token
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account.cart.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: "3dcart_access_token", var: "3dcart_access_token"}, {name: "3dcart_private_key", var: "3dcart_private_key"}, {name: "3dcartapi_api_key", var: "3dcartapi_api_key"}, {name: amazon_access_key_id, var: amazon_access_key_id}, {name: amazon_access_token, var: amazon_access_token}, {name: amazon_marketplaces_ids, var: amazon_marketplaces_ids}, {name: amazon_secret_key, var: amazon_secret_key}, {name: amazon_seller_id, var: amazon_seller_id}, {name: amazon_sp_api_environment, var: amazon_sp_api_environment}, {name: amazon_sp_aws_region, var: amazon_sp_aws_region}, {name: amazon_sp_aws_role_arn, var: amazon_sp_aws_role_arn}, {name: amazon_sp_aws_user_key_id, var: amazon_sp_aws_user_key_id}, {name: amazon_sp_aws_user_secret, var: amazon_sp_aws_user_secret}, {name: amazon_sp_client_id, var: amazon_sp_client_id}, {name: amazon_sp_client_secret, var: amazon_sp_client_secret}, {name: amazon_sp_refresh_token, var: amazon_sp_refresh_token}, {name: aspdotnetstorefront_api_pass, var: aspdotnetstorefront_api_pass}, {name: aspdotnetstorefront_api_user, var: aspdotnetstorefront_api_user}, {name: bigcommerceapi_access_token, var: bigcommerceapi_access_token}, {name: bigcommerceapi_admin_account, var: bigcommerceapi_admin_account}, {name: bigcommerceapi_api_key, var: bigcommerceapi_api_key}, {name: bigcommerceapi_api_path, var: bigcommerceapi_api_path}, {name: bigcommerceapi_client_id, var: bigcommerceapi_client_id}, {name: bigcommerceapi_context, var: bigcommerceapi_context}, {name: bridge_url, var: bridge_url}, {name: cart_id, var: cart_id}, {name: commercehq_api_key, var: commercehq_api_key}, {name: commercehq_api_password, var: commercehq_api_password}, {name: db_tables_prefix, var: db_tables_prefix}, {name: demandware_api_password, var: demandware_api_password}, {name: demandware_client_id, var: demandware_client_id}, {name: demandware_user_name, var: demandware_user_name}, {name: demandware_user_password, var: demandware_user_password}, {name: ebay_access_token, var: ebay_access_token}, {name: ebay_client_id, var: ebay_client_id}, {name: ebay_client_secret, var: ebay_client_secret}, {name: ebay_environment, var: ebay_environment}, {name: ebay_refresh_token, var: ebay_refresh_token}, {name: ebay_runame, var: ebay_runame}, {name: ebay_site_id, var: ebay_site_id}, {name: ecwid_acess_token, var: ecwid_acess_token}, {name: ecwid_store_id, var: ecwid_store_id}, {name: etsy_access_token, var: etsy_access_token}, {name: etsy_client_id, var: etsy_client_id}, {name: etsy_keystring, var: etsy_keystring}, {name: etsy_refresh_token, var: etsy_refresh_token}, {name: etsy_shared_secret, var: etsy_shared_secret}, {name: etsy_token_secret, var: etsy_token_secret}, {name: ftp_host, var: ftp_host}, {name: ftp_password, var: ftp_password}, {name: ftp_port, var: ftp_port}, {name: ftp_store_dir, var: ftp_store_dir}, {name: ftp_user, var: ftp_user}, {name: hybris_client_id, var: hybris_client_id}, {name: hybris_client_secret, var: hybris_client_secret}, {name: hybris_password, var: hybris_password}, {name: hybris_username, var: hybris_username}, {name: hybris_websites, var: hybris_websites}, {name: lightspeed_api_key, var: lightspeed_api_key}, {name: lightspeed_api_secret, var: lightspeed_api_secret}, {name: magento_access_token, var: magento_access_token}, {name: magento_consumer_key, var: magento_consumer_key}, {name: magento_consumer_secret, var: magento_consumer_secret}, {name: magento_token_secret, var: magento_token_secret}, {name: mercado_libre_app_id, var: mercado_libre_app_id}, {name: mercado_libre_app_secret_key, var: mercado_libre_app_secret_key}, {name: mercado_libre_refresh_token, var: mercado_libre_refresh_token}, {name: neto_api_key, var: neto_api_key}, {name: neto_api_username, var: neto_api_username}, {name: prestashop_webservice_key, var: prestashop_webservice_key}, {name: shopify_access_token, var: shopify_access_token}, {name: shopify_api_key, var: shopify_api_key}, {name: shopify_api_password, var: shopify_api_password}, {name: shopify_shared_secret, var: shopify_shared_secret}, {name: shopware_access_key, var: shopware_access_key}, {name: shopware_api_key, var: shopware_api_key}, {name: shopware_api_secret, var: shopware_api_secret}, {name: squarespace_api_key, var: squarespace_api_key}, {name: store_key, var: store_key}, {name: store_root, var: store_root}, {name: store_url, var: store_url}, {name: validate_version, var: validate_version}, {name: verify, var: verify}, {name: volusion_login, var: volusion_login}, {name: volusion_password, var: volusion_password}, {name: walmart_channel_type, var: walmart_channel_type}, {name: walmart_client_id, var: walmart_client_id}, {name: walmart_client_secret, var: walmart_client_secret}, {name: walmart_environment, var: walmart_environment}, {name: wc_consumer_key, var: wc_consumer_key}, {name: wc_consumer_secret, var: wc_consumer_secret}, {name: wix_app_id, var: wix_app_id}, {name: wix_app_secret_key, var: wix_app_secret_key}, {name: wix_refresh_token, var: wix_refresh_token}, {name: zid_access_token, var: zid_access_token}, {name: zid_authorization, var: zid_authorization}, {name: zid_client_id, var: zid_client_id}, {name: zid_client_secret, var: zid_client_secret}, {name: zid_refresh_token, var: zid_refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    "3dcart_access_token": $3dcart_access_token, "3dcart_private_key": $3dcart_private_key, "3dcartapi_api_key": $3dcartapi_api_key, amazon_access_key_id: $amazon_access_key_id, amazon_access_token: $amazon_access_token, amazon_marketplaces_ids: $amazon_marketplaces_ids, amazon_secret_key: $amazon_secret_key, amazon_seller_id: $amazon_seller_id, amazon_sp_api_environment: $amazon_sp_api_environment, amazon_sp_aws_region: $amazon_sp_aws_region, amazon_sp_aws_role_arn: $amazon_sp_aws_role_arn, amazon_sp_aws_user_key_id: $amazon_sp_aws_user_key_id, amazon_sp_aws_user_secret: $amazon_sp_aws_user_secret, amazon_sp_client_id: $amazon_sp_client_id, amazon_sp_client_secret: $amazon_sp_client_secret, amazon_sp_refresh_token: $amazon_sp_refresh_token, aspdotnetstorefront_api_pass: $aspdotnetstorefront_api_pass, aspdotnetstorefront_api_user: $aspdotnetstorefront_api_user, bigcommerceapi_access_token: $bigcommerceapi_access_token, bigcommerceapi_admin_account: $bigcommerceapi_admin_account, bigcommerceapi_api_key: $bigcommerceapi_api_key, bigcommerceapi_api_path: $bigcommerceapi_api_path, bigcommerceapi_client_id: $bigcommerceapi_client_id, bigcommerceapi_context: $bigcommerceapi_context, bridge_url: $bridge_url, cart_id: $cart_id, commercehq_api_key: $commercehq_api_key, commercehq_api_password: $commercehq_api_password, db_tables_prefix: $db_tables_prefix, demandware_api_password: $demandware_api_password, demandware_client_id: $demandware_client_id, demandware_user_name: $demandware_user_name, demandware_user_password: $demandware_user_password, ebay_access_token: $ebay_access_token, ebay_client_id: $ebay_client_id, ebay_client_secret: $ebay_client_secret, ebay_environment: $ebay_environment, ebay_refresh_token: $ebay_refresh_token, ebay_runame: $ebay_runame, ebay_site_id: $ebay_site_id, ecwid_acess_token: $ecwid_acess_token, ecwid_store_id: $ecwid_store_id, etsy_access_token: $etsy_access_token, etsy_client_id: $etsy_client_id, etsy_keystring: $etsy_keystring, etsy_refresh_token: $etsy_refresh_token, etsy_shared_secret: $etsy_shared_secret, etsy_token_secret: $etsy_token_secret, ftp_host: $ftp_host, ftp_password: $ftp_password, ftp_port: $ftp_port, ftp_store_dir: $ftp_store_dir, ftp_user: $ftp_user, hybris_client_id: $hybris_client_id, hybris_client_secret: $hybris_client_secret, hybris_password: $hybris_password, hybris_username: $hybris_username, hybris_websites: $hybris_websites, lightspeed_api_key: $lightspeed_api_key, lightspeed_api_secret: $lightspeed_api_secret, magento_access_token: $magento_access_token, magento_consumer_key: $magento_consumer_key, magento_consumer_secret: $magento_consumer_secret, magento_token_secret: $magento_token_secret, mercado_libre_app_id: $mercado_libre_app_id, mercado_libre_app_secret_key: $mercado_libre_app_secret_key, mercado_libre_refresh_token: $mercado_libre_refresh_token, neto_api_key: $neto_api_key, neto_api_username: $neto_api_username, prestashop_webservice_key: $prestashop_webservice_key, shopify_access_token: $shopify_access_token, shopify_api_key: $shopify_api_key, shopify_api_password: $shopify_api_password, shopify_shared_secret: $shopify_shared_secret, shopware_access_key: $shopware_access_key, shopware_api_key: $shopware_api_key, shopware_api_secret: $shopware_api_secret, squarespace_api_key: $squarespace_api_key, store_key: $store_key, store_root: $store_root, store_url: $store_url, validate_version: $validate_version, verify: $verify, volusion_login: $volusion_login, volusion_password: $volusion_password, walmart_channel_type: $walmart_channel_type, walmart_client_id: $walmart_client_id, walmart_client_secret: $walmart_client_secret, walmart_environment: $walmart_environment, wc_consumer_key: $wc_consumer_key, wc_consumer_secret: $wc_consumer_secret, wix_app_id: $wix_app_id, wix_app_secret_key: $wix_app_secret_key, wix_refresh_token: $wix_refresh_token, zid_access_token: $zid_access_token, zid_authorization: $zid_authorization, zid_client_id: $zid_client_id, zid_client_secret: $zid_client_secret, zid_refresh_token: $zid_refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of carts.
#
# GET /account.cart.list.json
# Returns: record<result: record<carts: list<record>, carts_count: int>, return_code: int, return_message: string>
# operationId: AccountCartList
export def "account-cart-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --request-from-date: string # Retrieve entities from their creation date
  --request-to-date: string # Retrieve entities to their creation date
  --store-url: string # A web address of a store
  --store-key: string # Find store by store key
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account.cart.list.json"
    query: [{name: params, var: params}, {name: exclude, var: exclude}, {name: request_from_date, var: request_from_date}, {name: request_to_date, var: request_to_date}, {name: store_url, var: store_url}, {name: store_key, var: store_key}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    params: $params, exclude: $exclude, request_from_date: $request_from_date, request_to_date: $request_to_date, store_url: $store_url, store_key: $store_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update configs in the API2Cart database.
#
# PUT /account.config.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: AccountConfigUpdate
export def "account-config-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-store-key: string # Update store key
  --bridge-url: string # This parameter allows to set up store with custom bridge url (also you must use store_root parameter if a bridge folder is not in the root folder of the store)
  --store-root: string # Absolute path to the store root directory (used with "bridge_url" parameter)
  --db-tables-prefix: string # DB tables prefix
  --3dcart-private-key: string # 3DCart Private Key
  --3dcart-access-token: string # 3DCart Token
  --3dcartapi-api-key: string # 3DCart API Key
  --amazon-sp-client-id: string # Amazon SP API app client id
  --amazon-sp-client-secret: string # Amazon SP API app client secret
  --amazon-sp-aws-user-key-id: string # Amazon AWS user access key ID
  --amazon-sp-aws-user-secret: string # Amazon AWS user secret access key
  --amazon-sp-aws-region: string # Amazon AWS Region
  --amazon-sp-aws-role-arn: string # Amazon AWS Role ARN
  --amazon-sp-refresh-token: string # Amazon SP API OAuth refresh token
  --amazon-sp-api-environment: string # Amazon SP API environment (default: production)
  --amazon-access-token: string # MWS Auth Token. Access token authorizing the app to access resources on behalf of a user
  --amazon-seller-id: string # Amazon Seller ID (Merchant token)
  --amazon-marketplaces-ids: string # Amazon Marketplace IDs comma separated string
  --amazon-secret-key: string # Amazon Secret Key
  --amazon-access-key-id: string # Amazon Secret Key Id
  --aspdotnetstorefront-api-user: string # It's a AspDotNetStorefront account for which API is available
  --aspdotnetstorefront-api-pass: string # AspDotNetStorefront API Password
  --bigcommerceapi-admin-account: string # It's a BigCommerce account for which API is enabled
  --bigcommerceapi-api-path: string # BigCommerce API URL
  --bigcommerceapi-api-key: string # Bigcommerce API Key
  --bigcommerceapi-client-id: string # Client ID of the requesting app
  --bigcommerceapi-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --bigcommerceapi-context: string # API Path section unique to the store
  --demandware-client-id: string # Demandware client id
  --demandware-api-password: string # Demandware api password
  --demandware-user-name: string # Demandware user name
  --demandware-user-password: string # Demandware user password
  --ebay-client-id: string # Application ID (AppID).
  --ebay-client-secret: string # Shared Secret from eBay application
  --ebay-runame: string # The RuName value that eBay assigns to your application.
  --ebay-access-token: string # Used to authenticate API requests.
  --ebay-refresh-token: string # Used to renew the access token.
  --ebay-environment: string # eBay environment
  --ebay-site-id: int # eBay global ID (default: 0)
  --ecwid-acess-token: string # Access token authorizing the app to access resources on behalf of a user
  --ecwid-store-id: string # Store Id
  --etsy-keystring: string # Etsy keystring
  --etsy-shared-secret: string # Etsy shared secret
  --etsy-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --etsy-token-secret: string # Secret token authorizing the app to access resources on behalf of a user
  --etsy-client-id: string # Etsy Client Id
  --etsy-refresh-token: string # Etsy Refresh token
  --neto-api-key: string # Neto API Key
  --neto-api-username: string # Neto User Name
  --shopify-api-key: string # Shopify API Key
  --shopify-api-password: string # Shopify API Password
  --shopify-shared-secret: string # Shared secret
  --shopify-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --shopware-access-key: string # Shopware access key
  --shopware-api-key: string # Shopware api key
  --shopware-api-secret: string # Shopware client secret access key
  --volusion-login: string # It's a Volusion account for which API is enabled
  --volusion-password: string # Volusion API Password
  --walmart-client-id: string # Walmart client ID
  --walmart-client-secret: string # Walmart client secret
  --walmart-environment: string # Walmart environment (default: production)
  --walmart-channel-type: string # Walmart WM_CONSUMER.CHANNEL.TYPE header
  --squarespace-api-key: string # Squarespace API Key
  --hybris-client-id: string # Omni Commerce Connector Client ID
  --hybris-client-secret: string # Omni Commerce Connector Client Secret
  --hybris-username: string # User Name
  --hybris-password: string # User password
  --hybris-websites: list<string> # Websites to stores mapping data
  --lightspeed-api-key: string # LightSpeed api key
  --lightspeed-api-secret: string # LightSpeed api secret
  --commercehq-api-key: string # CommerceHQ api key
  --commercehq-api-password: string # CommerceHQ api password
  --wc-consumer-key: string # Woocommerce consumer key
  --wc-consumer-secret: string # Woocommerce consumer secret
  --magento-consumer-key: string # Magento Consumer Key
  --magento-consumer-secret: string # Magento Consumer Secret
  --magento-access-token: string # Magento Access Token
  --magento-token-secret: string # Magento Token Secret
  --prestashop-webservice-key: string # Prestashop webservice key
  --wix-app-id: string # Wix App ID
  --wix-app-secret-key: string # Wix App Secret Key
  --wix-refresh-token: string # Wix refresh token
  --mercado-libre-app-id: string # Mercado Libre App ID
  --mercado-libre-app-secret-key: string # Mercado Libre App Secret Key
  --mercado-libre-refresh-token: string # Mercado Libre Refresh Token
  --zid-client-id: int # Zid Client ID
  --zid-client-secret: string # Zid Client Secret
  --zid-access-token: string # Zid Access Token
  --zid-authorization: string # Zid Authorization
  --zid-refresh-token: string # Zid refresh token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/account.config.update.json"
    query: [{name: new_store_key, var: new_store_key}, {name: bridge_url, var: bridge_url}, {name: store_root, var: store_root}, {name: db_tables_prefix, var: db_tables_prefix}, {name: "3dcart_private_key", var: "3dcart_private_key"}, {name: "3dcart_access_token", var: "3dcart_access_token"}, {name: "3dcartapi_api_key", var: "3dcartapi_api_key"}, {name: amazon_sp_client_id, var: amazon_sp_client_id}, {name: amazon_sp_client_secret, var: amazon_sp_client_secret}, {name: amazon_sp_aws_user_key_id, var: amazon_sp_aws_user_key_id}, {name: amazon_sp_aws_user_secret, var: amazon_sp_aws_user_secret}, {name: amazon_sp_aws_region, var: amazon_sp_aws_region}, {name: amazon_sp_aws_role_arn, var: amazon_sp_aws_role_arn}, {name: amazon_sp_refresh_token, var: amazon_sp_refresh_token}, {name: amazon_sp_api_environment, var: amazon_sp_api_environment}, {name: amazon_access_token, var: amazon_access_token}, {name: amazon_seller_id, var: amazon_seller_id}, {name: amazon_marketplaces_ids, var: amazon_marketplaces_ids}, {name: amazon_secret_key, var: amazon_secret_key}, {name: amazon_access_key_id, var: amazon_access_key_id}, {name: aspdotnetstorefront_api_user, var: aspdotnetstorefront_api_user}, {name: aspdotnetstorefront_api_pass, var: aspdotnetstorefront_api_pass}, {name: bigcommerceapi_admin_account, var: bigcommerceapi_admin_account}, {name: bigcommerceapi_api_path, var: bigcommerceapi_api_path}, {name: bigcommerceapi_api_key, var: bigcommerceapi_api_key}, {name: bigcommerceapi_client_id, var: bigcommerceapi_client_id}, {name: bigcommerceapi_access_token, var: bigcommerceapi_access_token}, {name: bigcommerceapi_context, var: bigcommerceapi_context}, {name: demandware_client_id, var: demandware_client_id}, {name: demandware_api_password, var: demandware_api_password}, {name: demandware_user_name, var: demandware_user_name}, {name: demandware_user_password, var: demandware_user_password}, {name: ebay_client_id, var: ebay_client_id}, {name: ebay_client_secret, var: ebay_client_secret}, {name: ebay_runame, var: ebay_runame}, {name: ebay_access_token, var: ebay_access_token}, {name: ebay_refresh_token, var: ebay_refresh_token}, {name: ebay_environment, var: ebay_environment}, {name: ebay_site_id, var: ebay_site_id}, {name: ecwid_acess_token, var: ecwid_acess_token}, {name: ecwid_store_id, var: ecwid_store_id}, {name: etsy_keystring, var: etsy_keystring}, {name: etsy_shared_secret, var: etsy_shared_secret}, {name: etsy_access_token, var: etsy_access_token}, {name: etsy_token_secret, var: etsy_token_secret}, {name: etsy_client_id, var: etsy_client_id}, {name: etsy_refresh_token, var: etsy_refresh_token}, {name: neto_api_key, var: neto_api_key}, {name: neto_api_username, var: neto_api_username}, {name: shopify_api_key, var: shopify_api_key}, {name: shopify_api_password, var: shopify_api_password}, {name: shopify_shared_secret, var: shopify_shared_secret}, {name: shopify_access_token, var: shopify_access_token}, {name: shopware_access_key, var: shopware_access_key}, {name: shopware_api_key, var: shopware_api_key}, {name: shopware_api_secret, var: shopware_api_secret}, {name: volusion_login, var: volusion_login}, {name: volusion_password, var: volusion_password}, {name: walmart_client_id, var: walmart_client_id}, {name: walmart_client_secret, var: walmart_client_secret}, {name: walmart_environment, var: walmart_environment}, {name: walmart_channel_type, var: walmart_channel_type}, {name: squarespace_api_key, var: squarespace_api_key}, {name: hybris_client_id, var: hybris_client_id}, {name: hybris_client_secret, var: hybris_client_secret}, {name: hybris_username, var: hybris_username}, {name: hybris_password, var: hybris_password}, {name: hybris_websites, var: hybris_websites, style: csv}, {name: lightspeed_api_key, var: lightspeed_api_key}, {name: lightspeed_api_secret, var: lightspeed_api_secret}, {name: commercehq_api_key, var: commercehq_api_key}, {name: commercehq_api_password, var: commercehq_api_password}, {name: wc_consumer_key, var: wc_consumer_key}, {name: wc_consumer_secret, var: wc_consumer_secret}, {name: magento_consumer_key, var: magento_consumer_key}, {name: magento_consumer_secret, var: magento_consumer_secret}, {name: magento_access_token, var: magento_access_token}, {name: magento_token_secret, var: magento_token_secret}, {name: prestashop_webservice_key, var: prestashop_webservice_key}, {name: wix_app_id, var: wix_app_id}, {name: wix_app_secret_key, var: wix_app_secret_key}, {name: wix_refresh_token, var: wix_refresh_token}, {name: mercado_libre_app_id, var: mercado_libre_app_id}, {name: mercado_libre_app_secret_key, var: mercado_libre_app_secret_key}, {name: mercado_libre_refresh_token, var: mercado_libre_refresh_token}, {name: zid_client_id, var: zid_client_id}, {name: zid_client_secret, var: zid_client_secret}, {name: zid_access_token, var: zid_access_token}, {name: zid_authorization, var: zid_authorization}, {name: zid_refresh_token, var: zid_refresh_token}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    new_store_key: $new_store_key, bridge_url: $bridge_url, store_root: $store_root, db_tables_prefix: $db_tables_prefix, "3dcart_private_key": $3dcart_private_key, "3dcart_access_token": $3dcart_access_token, "3dcartapi_api_key": $3dcartapi_api_key, amazon_sp_client_id: $amazon_sp_client_id, amazon_sp_client_secret: $amazon_sp_client_secret, amazon_sp_aws_user_key_id: $amazon_sp_aws_user_key_id, amazon_sp_aws_user_secret: $amazon_sp_aws_user_secret, amazon_sp_aws_region: $amazon_sp_aws_region, amazon_sp_aws_role_arn: $amazon_sp_aws_role_arn, amazon_sp_refresh_token: $amazon_sp_refresh_token, amazon_sp_api_environment: $amazon_sp_api_environment, amazon_access_token: $amazon_access_token, amazon_seller_id: $amazon_seller_id, amazon_marketplaces_ids: $amazon_marketplaces_ids, amazon_secret_key: $amazon_secret_key, amazon_access_key_id: $amazon_access_key_id, aspdotnetstorefront_api_user: $aspdotnetstorefront_api_user, aspdotnetstorefront_api_pass: $aspdotnetstorefront_api_pass, bigcommerceapi_admin_account: $bigcommerceapi_admin_account, bigcommerceapi_api_path: $bigcommerceapi_api_path, bigcommerceapi_api_key: $bigcommerceapi_api_key, bigcommerceapi_client_id: $bigcommerceapi_client_id, bigcommerceapi_access_token: $bigcommerceapi_access_token, bigcommerceapi_context: $bigcommerceapi_context, demandware_client_id: $demandware_client_id, demandware_api_password: $demandware_api_password, demandware_user_name: $demandware_user_name, demandware_user_password: $demandware_user_password, ebay_client_id: $ebay_client_id, ebay_client_secret: $ebay_client_secret, ebay_runame: $ebay_runame, ebay_access_token: $ebay_access_token, ebay_refresh_token: $ebay_refresh_token, ebay_environment: $ebay_environment, ebay_site_id: $ebay_site_id, ecwid_acess_token: $ecwid_acess_token, ecwid_store_id: $ecwid_store_id, etsy_keystring: $etsy_keystring, etsy_shared_secret: $etsy_shared_secret, etsy_access_token: $etsy_access_token, etsy_token_secret: $etsy_token_secret, etsy_client_id: $etsy_client_id, etsy_refresh_token: $etsy_refresh_token, neto_api_key: $neto_api_key, neto_api_username: $neto_api_username, shopify_api_key: $shopify_api_key, shopify_api_password: $shopify_api_password, shopify_shared_secret: $shopify_shared_secret, shopify_access_token: $shopify_access_token, shopware_access_key: $shopware_access_key, shopware_api_key: $shopware_api_key, shopware_api_secret: $shopware_api_secret, volusion_login: $volusion_login, volusion_password: $volusion_password, walmart_client_id: $walmart_client_id, walmart_client_secret: $walmart_client_secret, walmart_environment: $walmart_environment, walmart_channel_type: $walmart_channel_type, squarespace_api_key: $squarespace_api_key, hybris_client_id: $hybris_client_id, hybris_client_secret: $hybris_client_secret, hybris_username: $hybris_username, hybris_password: $hybris_password, hybris_websites: $hybris_websites, lightspeed_api_key: $lightspeed_api_key, lightspeed_api_secret: $lightspeed_api_secret, commercehq_api_key: $commercehq_api_key, commercehq_api_password: $commercehq_api_password, wc_consumer_key: $wc_consumer_key, wc_consumer_secret: $wc_consumer_secret, magento_consumer_key: $magento_consumer_key, magento_consumer_secret: $magento_consumer_secret, magento_access_token: $magento_access_token, magento_token_secret: $magento_token_secret, prestashop_webservice_key: $prestashop_webservice_key, wix_app_id: $wix_app_id, wix_app_secret_key: $wix_app_secret_key, wix_refresh_token: $wix_refresh_token, mercado_libre_app_id: $mercado_libre_app_id, mercado_libre_app_secret_key: $mercado_libre_app_secret_key, mercado_libre_refresh_token: $mercado_libre_refresh_token, zid_client_id: $zid_client_id, zid_client_secret: $zid_client_secret, zid_access_token: $zid_access_token, zid_authorization: $zid_authorization, zid_refresh_token: $zid_refresh_token
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webhooks that was not delivered to the callback.
#
# GET /account.failed_webhooks.json
# Returns: record<result: record<all_failed_webhook: string, webhook: list<record>>, return_code: int, return_message: string>
# operationId: AccountFailedWebhooks
export def "account-failed-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --ids: string # List of сomma-separated webhook ids
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account.failed_webhooks.json"
    query: [{name: count, var: count}, {name: start, var: start}, {name: ids, var: ids}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    count: $count, start: $start, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of supported platforms
#
# GET /account.supported_platforms.json
# Returns: record<result: record<supported_platforms: list<record>>, return_code: int, return_message: string>
# operationId: AccountSupportedPlatforms
export def "account-supported-platforms" [
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
    path: "/account.supported_platforms.json"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new attribute
#
# POST /attribute.add.json
# Returns: record<result: record<id: string>, return_code: int, return_message: string>
# operationId: AttributeAdd
export def "attribute-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Defines attribute's type (required)
  --code: string # Entity code
  --name: string # Defines attributes's name (required)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --visible: oneof<nothing, bool> # Set visibility status (default: false)
  --required: oneof<nothing, bool> # Defines if the option is required (default: false)
  --position: int # Attribute`s position (default: 0)
  --attribute-group-id: string # Filter by attribute_group_id
  --is-global: string # Attribute saving scope (default: Store)
  --is-searchable: oneof<nothing, bool> # Use attribute in Quick Search (default: false)
  --is-filterable: string # Use In Layered Navigation (default: No)
  --is-comparable: oneof<nothing, bool> # Comparable on Front-end (default: false)
  --is-html-allowed-on-front: oneof<nothing, bool> # Allow HTML Tags on Frontend (default: false)
  --is-filterable-in-search: oneof<nothing, bool> # Use In Search Results Layered Navigation (default: false)
  --is-configurable: oneof<nothing, bool> # Use To Create Configurable Product (default: false)
  --is-visible-in-advanced-search: oneof<nothing, bool> # Use in Advanced Search (default: false)
  --is-used-for-promo-rules: oneof<nothing, bool> # Use for Promo Rule Conditions (default: false)
  --used-in-product-listing: oneof<nothing, bool> # Used in Product Listing (default: false)
  --used-for-sort-by: oneof<nothing, bool> # Used for Sorting in Product Listing (default: false)
  --apply-to: string # Types of products which can have this attribute (default: all_types)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/attribute.add.json"
    query: [{name: type, var: type, required: true}, {name: code, var: code}, {name: name, var: name, required: true}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: visible, var: visible}, {name: required, var: required}, {name: position, var: position}, {name: attribute_group_id, var: attribute_group_id}, {name: is_global, var: is_global}, {name: is_searchable, var: is_searchable}, {name: is_filterable, var: is_filterable}, {name: is_comparable, var: is_comparable}, {name: is_html_allowed_on_front, var: is_html_allowed_on_front}, {name: is_filterable_in_search, var: is_filterable_in_search}, {name: is_configurable, var: is_configurable}, {name: is_visible_in_advanced_search, var: is_visible_in_advanced_search}, {name: is_used_for_promo_rules, var: is_used_for_promo_rules}, {name: used_in_product_listing, var: used_in_product_listing}, {name: used_for_sort_by, var: used_for_sort_by}, {name: apply_to, var: apply_to}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    type: $type, code: $code, name: $name, store_id: $store_id, lang_id: $lang_id, visible: $visible, required: $required, position: $position, attribute_group_id: $attribute_group_id, is_global: $is_global, is_searchable: $is_searchable, is_filterable: $is_filterable, is_comparable: $is_comparable, is_html_allowed_on_front: $is_html_allowed_on_front, is_filterable_in_search: $is_filterable_in_search, is_configurable: $is_configurable, is_visible_in_advanced_search: $is_visible_in_advanced_search, is_used_for_promo_rules: $is_used_for_promo_rules, used_in_product_listing: $used_in_product_listing, used_for_sort_by: $used_for_sort_by, apply_to: $apply_to
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign attribute to the group
#
# POST /attribute.assign.group.json
# Returns: record<result: record<assigned: string>, return_code: int, return_message: string>
# operationId: AttributeAssignGroup
export def "attribute-assign-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --group-id: string # Attribute group_id (required)
  --attribute-set-id: string # Attribute set id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/attribute.assign.group.json"
    query: [{name: id, var: id, required: true}, {name: group_id, var: group_id, required: true}, {name: attribute_set_id, var: attribute_set_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, group_id: $group_id, attribute_set_id: $attribute_set_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign attribute to the attribute set
#
# POST /attribute.assign.set.json
# Returns: record<result: record<assigned: string>, return_code: int, return_message: string>
# operationId: AttributeAssignSet
export def "attribute-assign-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --group-id: string # Attribute group_id
  --attribute-set-id: string # Attribute set id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/attribute.assign.set.json"
    query: [{name: id, var: id, required: true}, {name: group_id, var: group_id}, {name: attribute_set_id, var: attribute_set_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, group_id: $group_id, attribute_set_id: $attribute_set_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attribute_set list
#
# GET /attribute.attributeset.list.json
# Returns: record<result: table<additional_fields: record, assigned_attribute_ids: list, attribute_set_id: string, custom_fields: record, id: string, name: string, position: int>, return_code: int, return_message: string>
# operationId: AttributeAttributesetList
export def "attribute-attributeset-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attribute.attributeset.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, params: $params, exclude: $exclude, response_fields: $response_fields
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attributes count
#
# GET /attribute.count.json
# Returns: record<result: record<attributes_count: int>, return_code: int, return_message: string>
# operationId: AttributeCount
export def "attribute-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Defines attribute's type
  --store-id: string # Store Id
  --lang-id: string # Language id
  --visible: oneof<nothing, bool> # Filter items by visibility status
  --required: oneof<nothing, bool> # Defines if the option is required
  --system: oneof<nothing, bool> # True if attribute is system
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attribute.count.json"
    query: [{name: type, var: type}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: visible, var: visible}, {name: required, var: required}, {name: system, var: system}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    type: $type, store_id: $store_id, lang_id: $lang_id, visible: $visible, required: $required, system: $system
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attribute from store
#
# DELETE /attribute.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: AttributeDelete
export def "attribute-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --id: string # Entity id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/attribute.delete.json"
    query: [{name: store_id, var: store_id}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id, id: $id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attribute group list
#
# GET /attribute.group.list.json
# Returns: record<result: table<additional_fields: record, assigned_attribute_ids: list, attribute_set_id: string, custom_fields: record, id: string, name: string, position: int>, return_code: int, return_message: string>
# operationId: AttributeGroupList
export def "attribute-group-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --attribute-set-id: string # Attribute set id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attribute.group.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: lang_id, var: lang_id}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}, {name: attribute_set_id, var: attribute_set_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, lang_id: $lang_id, params: $params, exclude: $exclude, response_fields: $response_fields, attribute_set_id: $attribute_set_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attribute info
#
# GET /attribute.info.json
# Returns: record<result: record<additional_fields: record, code: string, custom_fields: record, default_values: list<string>, id: string, lang_id: string, name: string, position: int, required: bool, store_id: string, system: bool, type: string, values: list<string>, visible: bool>, return_code: int, return_message: string>
# operationId: AttributeInfo
export def "attribute-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attribute.info.json"
    query: [{name: id, var: id, required: true}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, store_id: $store_id, lang_id: $lang_id, params: $params, exclude: $exclude, response_fields: $response_fields
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attributes list
#
# GET /attribute.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, attribute: list<record>, attributes_count: int, custom_fields: record>, return_code: int, return_message: string>
# operationId: AttributeList
export def "attribute-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --type: string # Defines attribute's type
  --attribute-ids: string # Filter attributes by ids
  --store-id: string # Store Id
  --lang-id: string # Retrieves attributes on specified language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,code,type)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --visible: oneof<nothing, bool> # Filter items by visibility status
  --required: oneof<nothing, bool> # Defines if the option is required
  --system: oneof<nothing, bool> # True if attribute is system
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attribute.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: type, var: type}, {name: attribute_ids, var: attribute_ids}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}, {name: visible, var: visible}, {name: required, var: required}, {name: system, var: system}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, type: $type, attribute_ids: $attribute_ids, store_id: $store_id, lang_id: $lang_id, params: $params, exclude: $exclude, response_fields: $response_fields, visible: $visible, required: $required, system: $system
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of supported attributes types
#
# GET /attribute.type.list.json
# Returns: record<result: record<attribute_type: list<string>>, return_code: int, return_message: string>
# operationId: AttributeTypeList
export def "attribute-type-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attribute.type.list.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign attribute from group
#
# POST /attribute.unassign.group.json
# Returns: record<result: record<unassigned: string>, return_code: int, return_message: string>
# operationId: AttributeUnassignGroup
export def "attribute-unassign-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --group-id: string # Customer group_id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/attribute.unassign.group.json"
    query: [{name: id, var: id, required: true}, {name: group_id, var: group_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, group_id: $group_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign attribute from attribute set
#
# POST /attribute.unassign.set.json
# Returns: record<result: record<unassigned: string>, return_code: int, return_message: string>
# operationId: AttributeUnassignSet
export def "attribute-unassign-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --attribute-set-id: string # Attribute set id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/attribute.unassign.set.json"
    query: [{name: id, var: id, required: true}, {name: attribute_set_id, var: attribute_set_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, attribute_set_id: $attribute_set_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update attribute data
#
# POST /attribute.update.json
# Returns: record<result: record<updated: bool>, return_code: int, return_message: string>
# operationId: AttributeUpdate
export def "attribute-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --name: string # Defines new attributes's name (required)
  --store-id: string # Store Id
  --lang-id: string # Language id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/attribute.update.json"
    query: [{name: id, var: id, required: true}, {name: name, var: name, required: true}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, name: $name, store_id: $store_id, lang_id: $lang_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve basket information.
#
# GET /basket.info.json
# Returns: record<result: record<additional_fields: record, basket_products: list<record>, basket_url: string, created_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, currency: record<additional_fields: record, avail: bool, custom_fields: record, default: bool, id: string, iso3: string, name: string, rate: float, symbol_left: string, symbol_right: string>, custom_fields: record, customer: record<additional_fields: record, custom_fields: record, email: string, first_name: string, id: string, last_name: string, phone: string>, id: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>>, return_code: int, return_message: string>
# operationId: BasketInfo
export def "basket-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --store-id: string # Store Id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/basket.info.json"
    query: [{name: id, var: id, required: true}, {name: store_id, var: store_id}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, store_id: $store_id, params: $params, exclude: $exclude, response_fields: $response_fields
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add item to basket
#
# POST /basket.item.add.json
# Returns: record<result: record<added: bool>, return_code: int, return_message: string>
# operationId: BasketItemAdd
export def "basket-item-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Retrieves orders specified by customer id (required)
  --product-id: string # Defines id of the product which should be added to the basket (required)
  --variant-id: string # Defines product's variants specified by variant id
  --quantity: float # Defines new items quantity (default: 0)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/basket.item.add.json"
    query: [{name: customer_id, var: customer_id, required: true}, {name: product_id, var: product_id, required: true}, {name: variant_id, var: variant_id}, {name: quantity, var: quantity}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    customer_id: $customer_id, product_id: $product_id, variant_id: $variant_id, quantity: $quantity, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create live shipping rate service. (Beta)
#
# POST /basket.live_shipping_service.create.json
# Returns: record<result: record<id: int>, return_code: int, return_message: string>
# operationId: BasketLiveShippingServiceCreate
export def "basket-live-shipping-service-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --name: string # Shipping Service Name (required)
  --callback: string # Callback url that returns shipping rates. It should be able to accept POST requests with json data. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/basket.live_shipping_service.create.json"
    query: [{name: store_id, var: store_id}, {name: name, var: name, required: true}, {name: callback, var: callback, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id, name: $name, callback: $callback
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete live shipping rate service. (Beta)
#
# DELETE /basket.live_shipping_service.delete.json
# Returns: record<result: record<status: bool>, return_code: int, return_message: string>
# operationId: BasketLiveShippingServiceDelete
export def "basket-live-shipping-service-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Entity id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/basket.live_shipping_service.delete.json"
    query: [{name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of live shipping rate services. (Beta)
#
# GET /basket.live_shipping_service.list.json
# Returns: record<result: record<live_shipping_services: list<record>>, return_code: int, return_message: string>
# operationId: BasketLiveShippingServiceList
export def "basket-live-shipping-service-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/basket.live_shipping_service.list.json"
    query: [{name: store_id, var: store_id}, {name: start, var: start}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id, start: $start, count: $count
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete bridge from the store.
#
# POST /bridge.delete.json
# Returns: record<result: record<deleted: bool>, return_code: int, return_message: string>
# operationId: BridgeDelete
export def "bridge-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/bridge.delete.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download bridge for store
#
# GET /bridge.download.file
# Returns: binary
# operationId: BridgeDownload
export def "bridge-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --whitelabel: oneof<nothing, bool> # Identifies if there is a necessity to download whitelabel bridge. (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/bridge.download.file"
    query: [{name: whitelabel, var: whitelabel}]
    accept: ["application/zip"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    whitelabel: $whitelabel
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update bridge in the store.
#
# POST /bridge.update.json
# Returns: record<result: record<updated: bool>, return_code: int, return_message: string>
# operationId: BridgeUpdate
export def "bridge-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/bridge.update.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bridge key and store key
#
# GET /cart.bridge.json
# Returns: record<result: record<bridge: string, store_key: string>, return_code: int, return_message: string>
# operationId: CartBridge
export def "cart-bridge" [
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
    path: "/cart.bridge.json"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get count of cart catalog price rules discounts.
#
# GET /cart.catalog_price_rules.count.json
# Returns: record<result: record<catalog_price_rules_count: string>, return_code: int, return_message: string>
# operationId: CartCatalogPriceRulesCount
export def "cart-catalog-price-rules-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.catalog_price_rules.count.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cart catalog price rules discounts.
#
# GET /cart.catalog_price_rules.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, catalog_price_rules: list<record>, catalog_price_rules_count: int, custom_fields: record>, return_code: int, return_message: string>
# operationId: CartCatalogPriceRulesList
export def "cart-catalog-price-rules-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --ids: string # Retrieves catalog_price_rules by ids
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.catalog_price_rules.list.json"
    query: [{name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: ids, var: ids}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    page_cursor: $page_cursor, start: $start, count: $count, ids: $ids, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear cache on store.
#
# POST /cart.clear_cache.json
# Returns: record<result: record<cache_cleared: string>, return_code: int, return_message: string>
# operationId: CartClearCache
export def "cart-clear-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-type: string # Defines which cache should be cleared. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/cart.clear_cache.json"
    query: [{name: cache_type, var: cache_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    cache_type: $cache_type
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of cart configs
#
# GET /cart.config.json
# Returns: record<result: record<db_prefix: string, store_name: string, store_url: string>, return_code: int, return_message: string>
# operationId: CartConfig
export def "cart-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: store_name,store_url,db_prefix)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.config.json"
    query: [{name: params, var: params}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    params: $params, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this API method to update custom data in client database.
#
# PUT /cart.config.update.json
# DEPRECATED
# Returns: record<result: record, return_code: int, return_message: string>
# operationId: CartConfigUpdate
@deprecated
export def "cart-config-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # This parameter sets the list of params to the shopping cart.
  --db-tables-prefix: string # This parameter is deprecated for this method. Please, use this parameter in method account.config.update
  --store-id: string # Store Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/cart.config.update.json"
    body: {content_type: "application/json", kind: json, fields: [{name: custom_fields, var: custom_fields}, {name: db_tables_prefix, var: db_tables_prefix}, {name: store_id, var: store_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    custom_fields: $custom_fields, db_tables_prefix: $db_tables_prefix, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new coupon
#
# POST /cart.coupon.add.json
# Returns: record<result: record<coupon_id: string>, return_code: int, return_message: string>
# operationId: CartCouponAdd
export def "cart-coupon-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action_amount: float # Defines the discount amount value.
  action_apply_to: string@action-apply-to-completer # Defines where discount should be applied
  --action-condition-entity: string # Defines entity for action condition.
  --action-condition-key: string # Defines entity attribute code for action condition.
  --action-condition-operator: string # Defines condition operator.
  --action-condition-value: string # Defines condition attribute value/s. Can be comma separated string.
  action_scope: string@action-scope-completer # Specify how discount should be applied. If scope=matching_items, then discount will be applied to each of the items that match action conditions. Scope order means that discount will be applied once.
  action_type: string@action-type-completer # Coupon discount type
  code: string # Coupon code
  --codes: list<string> # Entity codes
  --date-end: string # Defines when discount code will be expired.
  --date-start: string # Defines when discount code will be available. (default: now)
  --name: string # Coupon name
  --store-id: string # Store Id
  --usage-limit: int # Usage limit for coupon.
  --usage-limit-per-customer: int # Usage limit per customer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cart.coupon.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: action_amount, var: action_amount}, {name: action_apply_to, var: action_apply_to}, {name: action_condition_entity, var: action_condition_entity}, {name: action_condition_key, var: action_condition_key}, {name: action_condition_operator, var: action_condition_operator}, {name: action_condition_value, var: action_condition_value}, {name: action_scope, var: action_scope}, {name: action_type, var: action_type}, {name: code, var: code}, {name: codes, var: codes}, {name: date_end, var: date_end}, {name: date_start, var: date_start}, {name: name, var: name}, {name: store_id, var: store_id}, {name: usage_limit, var: usage_limit}, {name: usage_limit_per_customer, var: usage_limit_per_customer}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    action_amount: $action_amount, action_apply_to: $action_apply_to, action_condition_entity: $action_condition_entity, action_condition_key: $action_condition_key, action_condition_operator: $action_condition_operator, action_condition_value: $action_condition_value, action_scope: $action_scope, action_type: $action_type, code: $code, codes: $codes, date_end: $date_end, date_start: $date_start, name: $name, store_id: $store_id, usage_limit: $usage_limit, usage_limit_per_customer: $usage_limit_per_customer
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new coupon condition
#
# POST /cart.coupon.condition.add.json
# Returns: record<result: record<status: bool>, return_code: int, return_message: string>
# operationId: CartCouponConditionAdd
export def "cart-coupon-condition-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --coupon-id: string # Coupon Id (required)
  --target: string # Defines condition operator (default: coupon_prerequisite)
  --entity: string@entity-completer # Defines condition entity type (required)
  --key: string@key-completer # Defines condition entity attribute key (required)
  --operator: string@operator-completer # Defines condition operator (required)
  --value: string # Defines condition value, can be comma separated according to the operator. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/cart.coupon.condition.add.json"
    query: [{name: store_id, var: store_id}, {name: coupon_id, var: coupon_id, required: true}, {name: target, var: target}, {name: entity, var: entity, required: true}, {name: key, var: key, required: true}, {name: operator, var: operator, required: true}, {name: value, var: value, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id, coupon_id: $coupon_id, target: $target, entity: $entity, key: $key, operator: $operator, value: $value
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cart coupons count.
#
# GET /cart.coupon.count.json
# Returns: record<result: record<coupons_count: string>, return_code: int, return_message: string>
# operationId: CartCouponCount
export def "cart-coupon-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --date-start-from: string # Filter entity by date_start (greater or equal)
  --date-start-to: string # Filter entity by date_start (less or equal)
  --date-end-from: string # Filter entity by date_end (greater or equal)
  --date-end-to: string # Filter entity by date_end (less or equal)
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.coupon.count.json"
    query: [{name: store_id, var: store_id}, {name: date_start_from, var: date_start_from}, {name: date_start_to, var: date_start_to}, {name: date_end_from, var: date_end_from}, {name: date_end_to, var: date_end_to}, {name: avail, var: avail}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id, date_start_from: $date_start_from, date_start_to: $date_start_to, date_end_from: $date_end_from, date_end_to: $date_end_to, avail: $avail
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete coupon
#
# DELETE /cart.coupon.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: CartCouponDelete
export def "cart-coupon-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/cart.coupon.delete.json"
    query: [{name: id, var: id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cart coupon discounts.
#
# GET /cart.coupon.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, coupon: list<record>, coupon_count: int, custom_fields: record>, return_code: int, return_message: string>
# operationId: CartCouponList
export def "cart-coupon-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --coupons-ids: string # Filter coupons by ids
  --store-id: string # Filter coupons by store id
  --date-start-from: string # Filter entity by date_start (greater or equal)
  --date-start-to: string # Filter entity by date_start (less or equal)
  --date-end-from: string # Filter entity by date_end (greater or equal)
  --date-end-to: string # Filter entity by date_end (less or equal)
  --avail: oneof<nothing, bool> # Filter coupons by avail status
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,code,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.coupon.list.json"
    query: [{name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: coupons_ids, var: coupons_ids}, {name: store_id, var: store_id}, {name: date_start_from, var: date_start_from}, {name: date_start_to, var: date_start_to}, {name: date_end_from, var: date_end_from}, {name: date_end_to, var: date_end_to}, {name: avail, var: avail}, {name: lang_id, var: lang_id}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    page_cursor: $page_cursor, start: $start, count: $count, coupons_ids: $coupons_ids, store_id: $store_id, date_start_from: $date_start_from, date_start_to: $date_start_to, date_end_from: $date_end_from, date_end_to: $date_end_to, avail: $avail, lang_id: $lang_id, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add store to the account
#
# POST /cart.create.json
# DEPRECATED
# Returns: record<result: record<store_key: string>, return_code: int, return_message: string>
# operationId: CartCreate
@deprecated
export def "cart-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cart-id: string@cart-id-completer # Store’s identifier which you can get from cart_list method (required)
  --store-url: string # A web address of a store that you would like to connect to API2Cart (required)
  --bridge-url: string # This parameter allows to set up store with custom bridge url (also you must use store_root parameter if a bridge folder is not in the root folder of the store)
  --store-root: string # Absolute path to the store root directory (used with "bridge_url" parameter)
  --store-key: string # Set this parameter if bridge is already uploaded to store
  --shared-secret: string # Shared secret
  --validate-version: oneof<nothing, bool> # Specify if api2cart should validate cart version (default: false)
  --verify: oneof<nothing, bool> # Enables or disables cart's verification (default: true)
  --db-tables-prefix: string # DB tables prefix
  --ftp-host: string # FTP connection host
  --ftp-user: string # FTP User
  --ftp-password: string # FTP Password
  --ftp-port: int # FTP Port
  --ftp-store-dir: string # FTP Store dir
  --api-key-3dcart: string # 3DCart API Key
  --admin-account: string # It's a BigCommerce account for which API is enabled
  --api-path: string # BigCommerce API URL
  --api-key: string # Bigcommerce API Key
  --client-id: string # Client ID of the requesting app
  --access-token: string # Access token authorizing the app to access resources on behalf of a user
  --context: string # API Path section unique to the store
  --qp-access-token: string # Access token authorizing the app to access resources on behalf of a user (spec name: access_token)
  --api-key-shopify: string # Shopify API Key
  --api-password: string # Shopify API Password
  --access-token-shopify: string # Access token authorizing the app to access resources on behalf of a user
  --qp-api-key: string # Neto API Key (spec name: apiKey)
  --api-username: string # Neto User Name
  --encrypted-password: string # Volusion API Password
  --login: string # It's a Volusion account for which API is enabled
  --api-user-adnsf: string # It's a AspDotNetStorefront account for which API is available
  --api-pass: string # AspDotNetStorefront API Password
  --access-key-scelite: string # Shopping Cart Elite Access Key
  --api-key-scelite: string # Shopping Cart Elite API Key
  --api-secret-key-scelite: string # Shopping Cart Elite API Secret Key
  --private-key: string # 3DCart Application Private Key
  --app-token: string # 3DCart Token from Application
  --etsy-keystring: string # Etsy keystring
  --etsy-shared-secret: string # Etsy shared secret
  --token-secret: string # Secret token authorizing the app to access resources on behalf of a user
  --etsy-client-id: string # Etsy Client Id (required)
  --etsy-refresh-token: string # Etsy Refresh token (required)
  --ebay-client-id: string # Application ID (AppID).
  --ebay-client-secret: string # Shared Secret from eBay application
  --ebay-runame: string # The RuName value that eBay assigns to your application.
  --ebay-access-token: string # Used to authenticate API requests.
  --ebay-refresh-token: string # Used to renew the access token.
  --ebay-environment: string # eBay environment (default: production)
  --ebay-site-id: int # eBay global ID (default: 0)
  --dw-client-id: string # Demandware client id
  --dw-api-pass: string # Demandware api password
  --demandware-user-name: string # Demandware user name
  --demandware-user-password: string # Demandware user password
  --store-id: string # Store Id (required)
  --seller-id: string # Seller Id
  --amazon-secret-key: string # Amazon Secret Key
  --amazon-access-key-id: string # Amazon Secret Key Id
  --marketplaces-ids: string # Comma separated marketplaces ids
  --environment: string # default: production
  --hybris-client-id: string # Omni Commerce Connector Client ID
  --hybris-client-secret: string # Omni Commerce Connector Client Secret
  --hybris-username: string # User Name
  --hybris-password: string # User password
  --hybris-websites: list<string> # Websites to stores mapping data
  --walmart-client-id: string # Walmart client ID
  --walmart-client-secret: string # Walmart client secret
  --walmart-environment: string # Walmart environment (default: production)
  --walmart-channel-type: string # Walmart WM_CONSUMER.CHANNEL.TYPE header
  --lightspeed-api-key: string # LightSpeed api key
  --lightspeed-api-secret: string # LightSpeed api secret
  --shopware-access-key: string # Shopware access key
  --shopware-api-key: string # Shopware api key
  --shopware-api-secret: string # Shopware client secret access key
  --commercehq-api-key: string # CommerceHQ api key
  --commercehq-api-password: string # CommerceHQ api password
  --3dcart-private-key: string # 3DCart Private Key
  --3dcart-access-token: string # 3DCart Token
  --wc-consumer-key: string # Woocommerce consumer key
  --wc-consumer-secret: string # Woocommerce consumer secret
  --magento-consumer-key: string # Magento Consumer Key
  --magento-consumer-secret: string # Magento Consumer Secret
  --magento-access-token: string # Magento Access Token
  --magento-token-secret: string # Magento Token Secret
  --prestashop-webservice-key: string # Prestashop webservice key
  --wix-app-id: string # Wix App ID
  --wix-app-secret-key: string # Wix App Secret Key
  --wix-refresh-token: string # Wix refresh token
  --mercado-libre-app-id: string # Mercado Libre App ID
  --mercado-libre-app-secret-key: string # Mercado Libre App Secret Key
  --mercado-libre-refresh-token: string # Mercado Libre Refresh Token
  --zid-client-id: int # Zid Client ID
  --zid-client-secret: string # Zid Client Secret
  --zid-access-token: string # Zid Access Token
  --zid-authorization: string # Zid Authorization
  --zid-refresh-token: string # Zid refresh token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/cart.create.json"
    query: [{name: cart_id, var: cart_id, required: true}, {name: store_url, var: store_url, required: true}, {name: bridge_url, var: bridge_url}, {name: store_root, var: store_root}, {name: store_key, var: store_key}, {name: shared_secret, var: shared_secret}, {name: validate_version, var: validate_version}, {name: verify, var: verify}, {name: db_tables_prefix, var: db_tables_prefix}, {name: ftp_host, var: ftp_host}, {name: ftp_user, var: ftp_user}, {name: ftp_password, var: ftp_password}, {name: ftp_port, var: ftp_port}, {name: ftp_store_dir, var: ftp_store_dir}, {name: apiKey_3dcart, var: api_key_3dcart}, {name: AdminAccount, var: admin_account}, {name: ApiPath, var: api_path}, {name: ApiKey, var: api_key}, {name: client_id, var: client_id}, {name: accessToken, var: access_token}, {name: context, var: context}, {name: access_token, var: qp_access_token}, {name: apiKey_shopify, var: api_key_shopify}, {name: apiPassword, var: api_password}, {name: accessToken_shopify, var: access_token_shopify}, {name: apiKey, var: qp_api_key}, {name: apiUsername, var: api_username}, {name: EncryptedPassword, var: encrypted_password}, {name: Login, var: login}, {name: apiUser_adnsf, var: api_user_adnsf}, {name: apiPass, var: api_pass}, {name: accessKey_scelite, var: access_key_scelite}, {name: apiKey_scelite, var: api_key_scelite}, {name: apiSecretKey_scelite, var: api_secret_key_scelite}, {name: privateKey, var: private_key}, {name: appToken, var: app_token}, {name: etsy_keystring, var: etsy_keystring}, {name: etsy_shared_secret, var: etsy_shared_secret}, {name: tokenSecret, var: token_secret}, {name: etsy_client_id, var: etsy_client_id, required: true}, {name: etsy_refresh_token, var: etsy_refresh_token, required: true}, {name: ebay_client_id, var: ebay_client_id}, {name: ebay_client_secret, var: ebay_client_secret}, {name: ebay_runame, var: ebay_runame}, {name: ebay_access_token, var: ebay_access_token}, {name: ebay_refresh_token, var: ebay_refresh_token}, {name: ebay_environment, var: ebay_environment}, {name: ebay_site_id, var: ebay_site_id}, {name: dw_client_id, var: dw_client_id}, {name: dw_api_pass, var: dw_api_pass}, {name: demandware_user_name, var: demandware_user_name}, {name: demandware_user_password, var: demandware_user_password}, {name: store_id, var: store_id, required: true}, {name: seller_id, var: seller_id}, {name: amazon_secret_key, var: amazon_secret_key}, {name: amazon_access_key_id, var: amazon_access_key_id}, {name: marketplaces_ids, var: marketplaces_ids}, {name: environment, var: environment}, {name: hybris_client_id, var: hybris_client_id}, {name: hybris_client_secret, var: hybris_client_secret}, {name: hybris_username, var: hybris_username}, {name: hybris_password, var: hybris_password}, {name: hybris_websites, var: hybris_websites, style: csv}, {name: walmart_client_id, var: walmart_client_id}, {name: walmart_client_secret, var: walmart_client_secret}, {name: walmart_environment, var: walmart_environment}, {name: walmart_channel_type, var: walmart_channel_type}, {name: lightspeed_api_key, var: lightspeed_api_key}, {name: lightspeed_api_secret, var: lightspeed_api_secret}, {name: shopware_access_key, var: shopware_access_key}, {name: shopware_api_key, var: shopware_api_key}, {name: shopware_api_secret, var: shopware_api_secret}, {name: commercehq_api_key, var: commercehq_api_key}, {name: commercehq_api_password, var: commercehq_api_password}, {name: "3dcart_private_key", var: "3dcart_private_key"}, {name: "3dcart_access_token", var: "3dcart_access_token"}, {name: wc_consumer_key, var: wc_consumer_key}, {name: wc_consumer_secret, var: wc_consumer_secret}, {name: magento_consumer_key, var: magento_consumer_key}, {name: magento_consumer_secret, var: magento_consumer_secret}, {name: magento_access_token, var: magento_access_token}, {name: magento_token_secret, var: magento_token_secret}, {name: prestashop_webservice_key, var: prestashop_webservice_key}, {name: wix_app_id, var: wix_app_id}, {name: wix_app_secret_key, var: wix_app_secret_key}, {name: wix_refresh_token, var: wix_refresh_token}, {name: mercado_libre_app_id, var: mercado_libre_app_id}, {name: mercado_libre_app_secret_key, var: mercado_libre_app_secret_key}, {name: mercado_libre_refresh_token, var: mercado_libre_refresh_token}, {name: zid_client_id, var: zid_client_id}, {name: zid_client_secret, var: zid_client_secret}, {name: zid_access_token, var: zid_access_token}, {name: zid_authorization, var: zid_authorization}, {name: zid_refresh_token, var: zid_refresh_token}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    cart_id: $cart_id, store_url: $store_url, bridge_url: $bridge_url, store_root: $store_root, store_key: $store_key, shared_secret: $shared_secret, validate_version: $validate_version, verify: $verify, db_tables_prefix: $db_tables_prefix, ftp_host: $ftp_host, ftp_user: $ftp_user, ftp_password: $ftp_password, ftp_port: $ftp_port, ftp_store_dir: $ftp_store_dir, api_key_3dcart: $api_key_3dcart, admin_account: $admin_account, api_path: $api_path, api_key: $api_key, client_id: $client_id, access_token: $access_token, context: $context, qp_access_token: $qp_access_token, api_key_shopify: $api_key_shopify, api_password: $api_password, access_token_shopify: $access_token_shopify, qp_api_key: $qp_api_key, api_username: $api_username, encrypted_password: $encrypted_password, login: $login, api_user_adnsf: $api_user_adnsf, api_pass: $api_pass, access_key_scelite: $access_key_scelite, api_key_scelite: $api_key_scelite, api_secret_key_scelite: $api_secret_key_scelite, private_key: $private_key, app_token: $app_token, etsy_keystring: $etsy_keystring, etsy_shared_secret: $etsy_shared_secret, token_secret: $token_secret, etsy_client_id: $etsy_client_id, etsy_refresh_token: $etsy_refresh_token, ebay_client_id: $ebay_client_id, ebay_client_secret: $ebay_client_secret, ebay_runame: $ebay_runame, ebay_access_token: $ebay_access_token, ebay_refresh_token: $ebay_refresh_token, ebay_environment: $ebay_environment, ebay_site_id: $ebay_site_id, dw_client_id: $dw_client_id, dw_api_pass: $dw_api_pass, demandware_user_name: $demandware_user_name, demandware_user_password: $demandware_user_password, store_id: $store_id, seller_id: $seller_id, amazon_secret_key: $amazon_secret_key, amazon_access_key_id: $amazon_access_key_id, marketplaces_ids: $marketplaces_ids, environment: $environment, hybris_client_id: $hybris_client_id, hybris_client_secret: $hybris_client_secret, hybris_username: $hybris_username, hybris_password: $hybris_password, hybris_websites: $hybris_websites, walmart_client_id: $walmart_client_id, walmart_client_secret: $walmart_client_secret, walmart_environment: $walmart_environment, walmart_channel_type: $walmart_channel_type, lightspeed_api_key: $lightspeed_api_key, lightspeed_api_secret: $lightspeed_api_secret, shopware_access_key: $shopware_access_key, shopware_api_key: $shopware_api_key, shopware_api_secret: $shopware_api_secret, commercehq_api_key: $commercehq_api_key, commercehq_api_password: $commercehq_api_password, "3dcart_private_key": $3dcart_private_key, "3dcart_access_token": $3dcart_access_token, wc_consumer_key: $wc_consumer_key, wc_consumer_secret: $wc_consumer_secret, magento_consumer_key: $magento_consumer_key, magento_consumer_secret: $magento_consumer_secret, magento_access_token: $magento_access_token, magento_token_secret: $magento_token_secret, prestashop_webservice_key: $prestashop_webservice_key, wix_app_id: $wix_app_id, wix_app_secret_key: $wix_app_secret_key, wix_refresh_token: $wix_refresh_token, mercado_libre_app_id: $mercado_libre_app_id, mercado_libre_app_secret_key: $mercado_libre_app_secret_key, mercado_libre_refresh_token: $mercado_libre_refresh_token, zid_client_id: $zid_client_id, zid_client_secret: $zid_client_secret, zid_access_token: $zid_access_token, zid_authorization: $zid_authorization, zid_refresh_token: $zid_refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove store from API2Cart
#
# DELETE /cart.delete.json
# Returns: record<result: record<store: string>, return_code: int, return_message: string>
# operationId: CartDelete
export def "cart-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-bridge: oneof<nothing, bool> # Identifies if there is a necessity to delete bridge (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/cart.delete.json"
    query: [{name: delete_bridge, var: delete_bridge}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    delete_bridge: $delete_bridge
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disconnect with the store and clear store session data.
#
# GET /cart.disconnect.json
# DEPRECATED
# Returns: record<result: record<connection: string>, return_code: int, return_message: string>
# operationId: CartDisconnect
@deprecated
export def "cart-disconnect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-bridge: oneof<nothing, bool> # Identifies if there is a necessity to delete bridge (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.disconnect.json"
    query: [{name: delete_bridge, var: delete_bridge}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    delete_bridge: $delete_bridge
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new gift card
#
# POST /cart.giftcard.add.json
# Returns: record<result: record<code: string, id: string>, return_code: int, return_message: string>
# operationId: CartGiftcardAdd
export def "cart-giftcard-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # Defines the gift card amount value. (required)
  --code: string # Gift card code
  --owner-email: string # Gift card owner email
  --recipient-email: string # Gift card recipient email
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/cart.giftcard.add.json"
    query: [{name: amount, var: amount, required: true}, {name: code, var: code}, {name: owner_email, var: owner_email}, {name: recipient_email, var: recipient_email}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    amount: $amount, code: $code, owner_email: $owner_email, recipient_email: $recipient_email
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get gift cards count.
#
# GET /cart.giftcard.count.json
# Returns: record<result: record<gift_cards_count: string>, return_code: int, return_message: string>
# operationId: CartGiftcardCount
export def "cart-giftcard-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.giftcard.count.json"
    query: [{name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get gift cards list.
#
# GET /cart.giftcard.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, gift_card: list<record>>, return_code: int, return_message: string>
# operationId: CartGiftcardList
export def "cart-giftcard-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --store-id: string # Store Id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,code,name)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.giftcard.list.json"
    query: [{name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: store_id, var: store_id}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    page_cursor: $page_cursor, start: $start, count: $count, store_id: $store_id, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cart information
#
# GET /cart.info.json
# Returns: record<result: record<additional_fields: record, custom_fields: record, db_prefix: string, name: string, shipping_zones: list<record>, stores_info: list<record>, url: string, version: string, warehouses: list<record>>, return_code: int, return_message: string>
# operationId: CartInfo
export def "cart-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: store_name,store_url,db_prefix)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.info.json"
    query: [{name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    params: $params, response_fields: $response_fields, exclude: $exclude, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of supported carts
#
# GET /cart.list.json
# DEPRECATED
# Returns: record<result: record<supported_carts: list<record>>, return_code: int, return_message: string>
# operationId: CartList
@deprecated
export def "cart-list" [
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
    path: "/cart.list.json"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get entity meta data
#
# GET /cart.meta_data.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, items: list<record>, total_count: int>, return_code: int, return_message: string>
# operationId: CartMetaDataList
export def "cart-meta-data-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Entity Id (required)
  --entity: string # Entity (default: product)
  --store-id: string # Store Id
  --key: string # Key
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: key,value)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.meta_data.list.json"
    query: [{name: entity_id, var: entity_id, required: true}, {name: entity, var: entity}, {name: store_id, var: store_id}, {name: key, var: key}, {name: count, var: count}, {name: page_cursor, var: page_cursor}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    entity_id: $entity_id, entity: $entity, store_id: $store_id, key: $key, count: $count, page_cursor: $page_cursor, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set meta data for a specific entity
#
# POST /cart.meta_data.set.json
# Returns: record<result: record<id: string>, return_code: int, return_message: string>
# operationId: CartMetaDataSet
export def "cart-meta-data-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Entity Id (required)
  --entity: string # Entity (default: product)
  --store-id: string # Store Id
  --key: string # Key (required)
  --value: string # Value (required)
  --namespace: string # Metafield namespace (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/cart.meta_data.set.json"
    query: [{name: entity_id, var: entity_id, required: true}, {name: entity, var: entity}, {name: store_id, var: store_id}, {name: key, var: key, required: true}, {name: value, var: value, required: true}, {name: namespace, var: namespace, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    entity_id: $entity_id, entity: $entity, store_id: $store_id, key: $key, value: $value, namespace: $namespace
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unset meta data for a specific entity
#
# DELETE /cart.meta_data.unset.json
# Returns: record<result: record<status: bool>, return_code: int, return_message: string>
# operationId: CartMetaDataUnset
export def "cart-meta-data-unset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Entity Id (required)
  --entity: string # Entity (default: product)
  --store-id: string # Store Id
  --key: string # Key (required)
  --id: string # Entity id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/cart.meta_data.unset.json"
    query: [{name: entity_id, var: entity_id, required: true}, {name: entity, var: entity}, {name: store_id, var: store_id}, {name: key, var: key, required: true}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    entity_id: $entity_id, entity: $entity, store_id: $store_id, key: $key, id: $id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of cart methods
#
# GET /cart.methods.json
# Returns: record<result: record<method: list<string>>, return_code: int, return_message: string>
# operationId: CartMethods
export def "cart-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.methods.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of installed plugins
#
# GET /cart.plugin.list.json
# Returns: record<result: record<all_plugins: int, plugins: list<record>>, return_code: int, return_message: string>
# operationId: CartPluginList
export def "cart-plugin-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-key: string # Set this parameter if bridge is already uploaded to store
  --store-id: string # Store Id
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.plugin.list.json"
    query: [{name: store_key, var: store_key}, {name: store_id, var: store_id}, {name: start, var: start}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_key: $store_key, store_id: $store_id, start: $start, count: $count
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new script to the storefront
#
# POST /cart.script.add.json
# Returns: record<result: record<script_id: string>, return_code: int, return_message: string>
# operationId: CartScriptAdd
export def "cart-script-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The user-friendly script name
  --description: string # The user-friendly description
  --html: string # An html string containing exactly one `script` tag.
  --src: string # The URL of the remote script
  --load-method: string # The load method to use for the script
  --scope: string # The page or pages on the online store where the script should be included (default: storefront)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/cart.script.add.json"
    query: [{name: name, var: name}, {name: description, var: description}, {name: html, var: html}, {name: src, var: src}, {name: load_method, var: load_method}, {name: scope, var: scope}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    name: $name, description: $description, html: $html, src: $src, load_method: $load_method, scope: $scope, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove script from the storefront
#
# DELETE /cart.script.delete.json
# Returns: record<result: record<deleted: bool>, return_code: int, return_message: string>
# operationId: CartScriptDelete
export def "cart-script-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/cart.script.delete.json"
    query: [{name: id, var: id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scripts installed to the storefront
#
# GET /cart.script.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, scripts: list<record>, total_count: int>, return_code: int, return_message: string>
# operationId: CartScriptList
export def "cart-script-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --script-ids: string # Retrieves only scripts with specific ids
  --store-id: string # Store Id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.script.list.json"
    query: [{name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: script_ids, var: script_ids}, {name: store_id, var: store_id}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    page_cursor: $page_cursor, start: $start, count: $count, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, script_ids: $script_ids, store_id: $store_id, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of shipping zones
#
# GET /cart.shipping_zones.list.json
# Returns: record<result: record<additional_fields: record, code: string, country: string, country_iso2_codes: list<string>, custom_fields: record, id: string, name: string>, return_code: int, return_message: string>
# operationId: CartShippingZonesList
export def "cart-shipping-zones-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,enabled)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.shipping_zones.list.json"
    query: [{name: store_id, var: store_id}, {name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id, start: $start, count: $count, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check store availability, bridge connection for the downloadable carts, identify DB prefix, validate API accesses for API carts.
#
# GET /cart.validate.json
# Returns: record<result: record<status: string>, return_code: int, return_message: string>
# operationId: CartValidate
export def "cart-validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate-version: oneof<nothing, bool> # Specify if api2cart should validate cart version (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cart.validate.json"
    query: [{name: validate_version, var: validate_version}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    validate_version: $validate_version
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new category in store
#
# POST /category.add.json
# Returns: record<result: record<category_id: string>, return_code: int, return_message: string>
# operationId: CategoryAdd
export def "category-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Defines category's name that has to be added (required)
  --parent-id: string # Adds categories specified by parent id
  --stores-ids: string # Create category in the stores that is specified by comma-separated stores' id (default: 0)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
  --sort-order: int # Sort number in the list (default: 0)
  --created-time: string # Entity's date creation
  --modified-time: string # Entity's date modification
  --description: string # Defines category's description
  --meta-title: string # Defines unique meta title for each entity
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --seo-url: string # Defines unique category's URL for SEO
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/category.add.json"
    query: [{name: name, var: name, required: true}, {name: parent_id, var: parent_id}, {name: stores_ids, var: stores_ids}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: avail, var: avail}, {name: sort_order, var: sort_order}, {name: created_time, var: created_time}, {name: modified_time, var: modified_time}, {name: description, var: description}, {name: meta_title, var: meta_title}, {name: meta_description, var: meta_description}, {name: meta_keywords, var: meta_keywords}, {name: seo_url, var: seo_url}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    name: $name, parent_id: $parent_id, stores_ids: $stores_ids, store_id: $store_id, lang_id: $lang_id, avail: $avail, sort_order: $sort_order, created_time: $created_time, modified_time: $modified_time, description: $description, meta_title: $meta_title, meta_description: $meta_description, meta_keywords: $meta_keywords, seo_url: $seo_url
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign category to product
#
# POST /category.assign.json
# Returns: record<result: record, return_code: int, return_message: string>
# operationId: CategoryAssign
export def "category-assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines category assign to the product, specified by product id (required)
  --category-id: string # Defines category assign, specified by category id (required)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/category.assign.json"
    query: [{name: product_id, var: product_id, required: true}, {name: category_id, var: category_id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, category_id: $category_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count categories in store.
#
# GET /category.count.json
# Returns: record<result: record<categories_count: int>, return_code: int, return_message: string>
# operationId: CategoryCount
export def "category-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-id: string # Counts categories specified by parent id
  --store-id: string # Counts category specified by store id
  --lang-id: string # Counts category specified by language id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/category.count.json"
    query: [{name: parent_id, var: parent_id}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: avail, var: avail}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    parent_id: $parent_id, store_id: $store_id, lang_id: $lang_id, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, avail: $avail
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete category in store
#
# DELETE /category.delete.json
# Returns: record<result: record<deleted: bool>, return_code: int, return_message: string>
# operationId: CategoryDelete
export def "category-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines category removal, specified by category id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/category.delete.json"
    query: [{name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search category in store. "Laptop" is specified here by default.
#
# GET /category.find.json
# Returns: record<result: record<category: list<record>>, return_code: int, return_message: string>
# operationId: CategoryFind
export def "category-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find-value: string # Entity search that is specified by some value (required)
  --find-where: string # Entity search that is specified by the comma-separated unique fields (default: name)
  --find-params: string # Entity search that is specified by comma-separated parameters (default: whole_words)
  --store-id: string # Store Id
  --lang-id: string # Language id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/category.find.json"
    query: [{name: find_value, var: find_value, required: true}, {name: find_where, var: find_where}, {name: find_params, var: find_params}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    find_value: $find_value, find_where: $find_where, find_params: $find_params, store_id: $store_id, lang_id: $lang_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add image to category
#
# POST /category.image.add.json
# Returns: record<result: record<image_path: string>, return_code: int, return_message: string>
# operationId: CategoryImageAdd
export def "category-image-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: string # Defines category id where the image should be added (required)
  --image-name: string # Defines image's name (required)
  --url: string # Defines URL of the image that has to be added (required)
  --label: string # Defines alternative text that has to be attached to the picture
  --mime: string # Mime type of image http://en.wikipedia.org/wiki/Internet_media_type.
  --type: string@type-completer-1 # Defines image's types that are specified by comma-separated list (required)
  --position: int # Defines image’s position in the list (default: 0)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/category.image.add.json"
    query: [{name: category_id, var: category_id, required: true}, {name: image_name, var: image_name, required: true}, {name: url, var: url, required: true}, {name: label, var: label}, {name: mime, var: mime}, {name: type, var: type, required: true}, {name: position, var: position}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    category_id: $category_id, image_name: $image_name, url: $url, label: $label, mime: $mime, type: $type, position: $position, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete image
#
# DELETE /category.image.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: CategoryImageDelete
export def "category-image-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: string # Defines category id where the image should be deleted (required)
  --image-id: string # Define image id (required)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/category.image.delete.json"
    query: [{name: category_id, var: category_id, required: true}, {name: image_id, var: image_id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    category_id: $category_id, image_id: $image_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get category info about category ID*** or specify other category ID.
#
# GET /category.info.json
# Returns: record<result: record<additional_fields: record, avail: bool, created_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, id: string, images: list<record>, keywords: string, meta_description: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, parent_id: string, path: string, seo_url: string, short_description: string, sort_order: int, stores_ids: list<string>>, return_code: int, return_message: string>
# operationId: CategoryInfo
export def "category-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Retrieves category's info specified by category id (required)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,parent_id,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Retrieves category info specified by store id
  --lang-id: string # Retrieves category info specified by language id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/category.info.json"
    query: [{name: id, var: id, required: true}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, params: $params, response_fields: $response_fields, exclude: $exclude, store_id: $store_id, lang_id: $lang_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of categories from store.
#
# GET /category.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, categories_count: int, category: list<record>, custom_fields: record>, return_code: int, return_message: string>
# operationId: CategoryList
export def "category-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --parent-id: string # Retrieves categories specified by parent id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,parent_id,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Retrieves categories specified by store id
  --lang-id: string # Retrieves categorys specified by language id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/category.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: page_cursor, var: page_cursor}, {name: parent_id, var: parent_id}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: avail, var: avail}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, page_cursor: $page_cursor, parent_id: $parent_id, params: $params, response_fields: $response_fields, exclude: $exclude, store_id: $store_id, lang_id: $lang_id, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, avail: $avail
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign category to product
#
# POST /category.unassign.json
# Returns: record<result: record, return_code: int, return_message: string>
# operationId: CategoryUnassign
export def "category-unassign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: string # Defines category unassign, specified by category id (required)
  --product-id: string # Defines category unassign to the product, specified by product id (required)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/category.unassign.json"
    query: [{name: category_id, var: category_id, required: true}, {name: product_id, var: product_id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    category_id: $category_id, product_id: $product_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update category in store
#
# PUT /category.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: CategoryUpdate
export def "category-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines category update specified by category id (required)
  --name: string # Defines new category’s name
  --parent-id: string # Defines new parent category id
  --stores-ids: string # Update category in the stores that is specified by comma-separated stores' id (default: 0)
  --avail: oneof<nothing, bool> # Defines category's visibility status
  --sort-order: int # Sort number in the list
  --modified-time: string # Entity's date modification
  --description: string # Defines new category's description
  --meta-title: string # Defines unique meta title for each entity
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --seo-url: string # Defines unique category's URL for SEO
  --lang-id: string # Language id
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/category.update.json"
    query: [{name: id, var: id, required: true}, {name: name, var: name}, {name: parent_id, var: parent_id}, {name: stores_ids, var: stores_ids}, {name: avail, var: avail}, {name: sort_order, var: sort_order}, {name: modified_time, var: modified_time}, {name: description, var: description}, {name: meta_title, var: meta_title}, {name: meta_description, var: meta_description}, {name: meta_keywords, var: meta_keywords}, {name: seo_url, var: seo_url}, {name: lang_id, var: lang_id}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, name: $name, parent_id: $parent_id, stores_ids: $stores_ids, avail: $avail, sort_order: $sort_order, modified_time: $modified_time, description: $description, meta_title: $meta_title, meta_description: $meta_description, meta_keywords: $meta_keywords, seo_url: $seo_url, lang_id: $lang_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add customer into store.
#
# POST /customer.add.json
# Returns: record<result: record<customer_id: string>, return_code: int, return_message: string>
# operationId: CustomerAdd
export def "customer-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: list # item shape: {address_book_address1?: string, address_book_address2?: string, address_book_city?: string, address_book_company?: string, address_book_country?: string, address_book_default?: bool, address_book_fax?: string, address_book_first_name?: string, address_book_gender?: string, address_book_last_name?: string, address_book_phone?: string, address_book_postcode?: string, address_book_region?: string, address_book_state?: string, address_book_type?: string, address_book_website?: string}
  --birth-day: string # Defines customer's birthday
  --company: string # Defines customer's company
  --created-time: string # Entity's date creation
  email: string # Defines customer's email
  --fax: string # Defines customer's fax
  first_name: string # Defines customer's first name
  --gender: string # Defines customer's gender
  --group: string # Defines the group where the customer
  --last-login: string # Defines customer's last login time
  last_name: string # Defines customer's last name
  --login: string # Specifies customer's login name
  --modified-time: string # Entity's date modification
  --news-letter-subscription: oneof<nothing, bool> # Defines whether the newsletter subscription is available for the user (default: false)
  --password: string # Defines customer's unique password
  --phone: string # Defines customer's phone number
  --status: string # Defines customer's status (default: enabled)
  --store-id: string # Store Id
  --website: string # Link to customer website
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customer.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: birth_day, var: birth_day}, {name: company, var: company}, {name: created_time, var: created_time}, {name: email, var: email}, {name: fax, var: fax}, {name: first_name, var: first_name}, {name: gender, var: gender}, {name: group, var: group}, {name: last_login, var: last_login}, {name: last_name, var: last_name}, {name: login, var: login}, {name: modified_time, var: modified_time}, {name: news_letter_subscription, var: news_letter_subscription}, {name: password, var: password}, {name: phone, var: phone}, {name: status, var: status}, {name: store_id, var: store_id}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    address: $address, birth_day: $birth_day, company: $company, created_time: $created_time, email: $email, fax: $fax, first_name: $first_name, gender: $gender, group: $group, last_login: $last_login, last_name: $last_name, login: $login, modified_time: $modified_time, news_letter_subscription: $news_letter_subscription, password: $password, phone: $phone, status: $status, store_id: $store_id, website: $website
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attributes for specific customer
#
# GET /customer.attribute.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, items: list<record>, total_count: int>, return_code: int, return_message: string>
# operationId: CustomerAttributeList
export def "customer-attribute-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --customer-id: string # Retrieves orders specified by customer id (required)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer.attribute.list.json"
    query: [{name: count, var: count}, {name: page_cursor, var: page_cursor}, {name: customer_id, var: customer_id, required: true}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    count: $count, page_cursor: $page_cursor, customer_id: $customer_id, store_id: $store_id, lang_id: $lang_id, params: $params, exclude: $exclude, response_fields: $response_fields
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get number of customers from store.
#
# GET /customer.count.json
# Returns: record<result: record<customers_count: int>, return_code: int, return_message: string>
# operationId: CustomerCount
export def "customer-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string # Customer group_id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --store-id: string # Counts customer specified by store id
  --customer-list-id: string # The numeric ID of the customer list in Demandware.
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer.count.json"
    query: [{name: group_id, var: group_id}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: store_id, var: store_id}, {name: customer_list_id, var: customer_list_id}, {name: avail, var: avail}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    group_id: $group_id, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, store_id: $store_id, customer_list_id: $customer_list_id, avail: $avail
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find customers in store.
#
# GET /customer.find.json
# Returns: record<result: record<email: string, first_name: string, id: string, last_name: string>, return_code: int, return_message: string>
# operationId: CustomerFind
export def "customer-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find-value: string # Entity search that is specified by some value (required)
  --find-where: string # Entity search that is specified by the comma-separated unique fields (default: email)
  --find-params: string # Entity search that is specified by comma-separated parameters (default: whole_words)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer.find.json"
    query: [{name: find_value, var: find_value, required: true}, {name: find_where, var: find_where}, {name: find_params, var: find_params}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    find_value: $find_value, find_where: $find_where, find_params: $find_params, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create customer group.
#
# POST /customer.group.add.json
# Returns: record<result: record, return_code: int, return_message: string>
# operationId: CustomerGroupAdd
export def "customer-group-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Customer group name (required)
  --store-id: string # Store Id
  --stores-ids: string # Assign customer group to the stores that is specified by comma-separated stores' id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/customer.group.add.json"
    query: [{name: name, var: name, required: true}, {name: store_id, var: store_id}, {name: stores_ids, var: stores_ids}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    name: $name, store_id: $store_id, stores_ids: $stores_ids
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of customers groups.
#
# GET /customer.group.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, group: list<record>, group_count: int>, return_code: int, return_message: string>
# operationId: CustomerGroupList
export def "customer-group-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --group-ids: string # Groups that will be assigned to a customer
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,additional_fields)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer.group.list.json"
    query: [{name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: group_ids, var: group_ids}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    page_cursor: $page_cursor, start: $start, count: $count, store_id: $store_id, lang_id: $lang_id, group_ids: $group_ids, params: $params, exclude: $exclude, response_fields: $response_fields
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get customers' details from store.
#
# GET /customer.info.json
# Returns: record<result: record<additional_fields: record, address_book: list<record>, birth_day: record<additional_fields: record, custom_fields: record, format: string, value: string>, company: string, created_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, email: string, fax: string, first_name: string, gender: string, group: list<record>, id: string, ip_address: string, last_login: record<additional_fields: record, custom_fields: record, format: string, value: string>, last_name: string, last_order_id: string, login: string, modified_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, news_letter_subscription: bool, orders_count: int, phone: string, status: string, stores_ids: list<string>, website: string>, return_code: int, return_message: string>
# operationId: CustomerInfo
export def "customer-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Retrieves customer's info specified by customer id (required)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,email,first_name,last_name)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Retrieves customer info specified by store id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer.info.json"
    query: [{name: id, var: id, required: true}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, params: $params, response_fields: $response_fields, exclude: $exclude, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of customers from store.
#
# GET /customer.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, customer: list<record>, customers_count: int>, return_code: int, return_message: string>
# operationId: CustomerList
export def "customer-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,email,first_name,last_name)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --group-id: string # Customer group_id
  --store-id: string # Retrieves customers specified by store id
  --customer-list-id: string # The numeric ID of the customer list in Demandware.
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer.list.json"
    query: [{name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: group_id, var: group_id}, {name: store_id, var: store_id}, {name: customer_list_id, var: customer_list_id}, {name: avail, var: avail}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    page_cursor: $page_cursor, start: $start, count: $count, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, params: $params, response_fields: $response_fields, exclude: $exclude, group_id: $group_id, store_id: $store_id, customer_list_id: $customer_list_id, avail: $avail
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update information of customer in store.
#
# PUT /customer.update.json
# Returns: record<result: record<updated: string>, return_code: int, return_message: string>
# operationId: CustomerUpdate
export def "customer-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --group-id: string # Customer group_id
  --group-ids: string # Groups that will be assigned to a customer
  --first-name: string # Defines customer's first name
  --last-name: string # Defines customer's last name
  --news-letter-subscription: oneof<nothing, bool> # Defines whether the newsletter subscription is available for the user
  --tags: string # Customer tags
  --address-book-id-x: string # The ID of the address.
  --address-book-first-name-x: string # Specifies customer's first name in the address book
  --address-book-last-name-x: string # Specifies customer's last name in the address book
  --address-book-company-x: string # Specifies customer's company name in the address book
  --address-book-phone-x: string # Specifies customer's phone number in the address book
  --address-book-address1-x: string # Specifies customer's first address in the address book
  --address-book-address2-x: string # Specifies customer's second address in the address book
  --address-book-city-x: string # Specifies customer's city in the address book
  --address-book-country-x: string # ISO code or name of country
  --address-book-state-x: string # ISO code or name of state.
  --address-book-postcode-x: string # Specifies customer's postcode
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/customer.update.json"
    query: [{name: id, var: id, required: true}, {name: group_id, var: group_id}, {name: group_ids, var: group_ids}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: news_letter_subscription, var: news_letter_subscription}, {name: tags, var: tags}, {name: "address_book_id_{x}", var: address_book_id_x}, {name: "address_book_first_name_{x}", var: address_book_first_name_x}, {name: "address_book_last_name_{x}", var: address_book_last_name_x}, {name: "address_book_company_{x}", var: address_book_company_x}, {name: "address_book_phone_{x}", var: address_book_phone_x}, {name: "address_book_address1_{x}", var: address_book_address1_x}, {name: "address_book_address2_{x}", var: address_book_address2_x}, {name: "address_book_city_{x}", var: address_book_city_x}, {name: "address_book_country_{x}", var: address_book_country_x}, {name: "address_book_state_{x}", var: address_book_state_x}, {name: "address_book_postcode_{x}", var: address_book_postcode_x}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, group_id: $group_id, group_ids: $group_ids, first_name: $first_name, last_name: $last_name, news_letter_subscription: $news_letter_subscription, tags: $tags, address_book_id_x: $address_book_id_x, address_book_first_name_x: $address_book_first_name_x, address_book_last_name_x: $address_book_last_name_x, address_book_company_x: $address_book_company_x, address_book_phone_x: $address_book_phone_x, address_book_address1_x: $address_book_address1_x, address_book_address2_x: $address_book_address2_x, address_book_city_x: $address_book_city_x, address_book_country_x: $address_book_country_x, address_book_state_x: $address_book_state_x, address_book_postcode_x: $address_book_postcode_x
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of orders that were left by customers before completing the order.
#
# GET /order.abandoned.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, order: list<record>>, return_code: int, return_message: string>
# operationId: OrderAbandonedList
export def "order-abandoned-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Retrieves orders specified by customer id
  --customer-email: string # Retrieves orders specified by customer email
  --created-to: string # Retrieve entities to their creation date
  --created-from: string # Retrieve entities from their creation date
  --modified-to: string # Retrieve entities to their modification date
  --modified-from: string # Retrieve entities from their modification date
  --skip-empty-email: oneof<nothing, bool> # Filter empty emails (default: false)
  --store-id: string # Store Id
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: customer,totals,items)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.abandoned.list.json"
    query: [{name: customer_id, var: customer_id}, {name: customer_email, var: customer_email}, {name: created_to, var: created_to}, {name: created_from, var: created_from}, {name: modified_to, var: modified_to}, {name: modified_from, var: modified_from}, {name: skip_empty_email, var: skip_empty_email}, {name: store_id, var: store_id}, {name: page_cursor, var: page_cursor}, {name: count, var: count}, {name: start, var: start}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    customer_id: $customer_id, customer_email: $customer_email, created_to: $created_to, created_from: $created_from, modified_to: $modified_to, modified_from: $modified_from, skip_empty_email: $skip_empty_email, store_id: $store_id, page_cursor: $page_cursor, count: $count, start: $start, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new order to the cart.
#
# POST /order.add.json
# Returns: record<result: record<order_id: string>, return_code: int, return_message: string>
# operationId: OrderAdd
export def "order-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-comment: string # Specifies admin's order comment
  --admin-private-comment: string # Specifies private admin's order comment
  bill_address_1: string # Specifies first billing address
  --bill-address-2: string # Specifies second billing address
  bill_city: string # Specifies billing city
  --bill-company: string # Specifies billing company
  bill_country: string # Specifies billing country code
  --bill-fax: string # Specifies billing fax
  bill_first_name: string # Specifies billing first name
  bill_last_name: string # Specifies billing last name
  --bill-phone: string # Specifies billing phone
  bill_postcode: string # Specifies billing postcode
  bill_state: string # Specifies billing state code
  --channel-id: string # Channel ID
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --comment: string # Specifies order comment
  --coupon-discount: float # Specifies order's coupon discount
  --coupons: list<string> # Coupons that will be applied to order
  --create-invoice: oneof<nothing, bool> # Defines whether the invoice is created automatically along with the order (default: false)
  --currency: string # Currency code of order
  --customer-birthday: string # Specifies customer’s birthday
  customer_email: string # Defines the customer specified by email for whom order has to be created
  --customer-fax: string # Specifies customer’s fax
  --customer-first-name: string # Specifies customer's first name
  --customer-last-name: string # Specifies customer’s last name
  --customer-phone: string # Specifies customer’s phone
  --date: string # Specifies an order creation date in format Y-m-d H:i:s
  --date-finished: string # Specifies order's finished date
  --date-modified: string # Specifies order's modification date
  --discount: float # Specifies order's discount
  --external-source: string # Identifying the system used to generate the order
  --financial-status: string # Create order with financial status
  --fulfillment-status: string # Create order with fulfillment status
  --gift-certificate-discount: float # Discounts for order with gift certificates
  --id: string # Defines order's id
  --inventory-behaviour: string # The behaviour to use when updating inventory.Values description:bypass = Do not claim inventory decrement_ignoring_policy = Ignore the product's inventory policy and claim amountsdecrement_obeying_policy = Obey the product's inventory policy. (default: bypass)
  --note-attributes: list # Defines note attributes — item shape: {name?: string, value?: string}
  --order-id: string # Defines the order id if it is supported by the cart
  order_item: list # item shape: {order_item_allow_refund_items_separately?: bool, order_item_allow_ship_items_separately?: bool, order_item_id: string, order_item_model?: string, order_item_name: string, order_item_option?: list, order_item_parent?: int, order_item_parent_option_name?: string, order_item_price: float, order_item_price_includes_tax?: bool, order_item_property?: list, order_item_quantity: int, order_item_tax?: float, order_item_variant_id?: string, order_item_weight?: float}
  --order-payment-method: string # Defines order payment method.Setting order_payment_method on Shopify will also change financial_status field value to 'paid'
  --order-shipping-method: string # Defines order shipping method
  order_status: string # Defines order status.
  --prices-inc-tax: oneof<nothing, bool> # Indicates whether prices and subtotal includes tax. (default: false)
  --send-admin-notifications: oneof<nothing, bool> # Notify admin when new order was created. (default: false)
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after order was created (default: false)
  --shipp-address-1: string # Specifies first shipping address
  --shipp-address-2: string # Specifies second address line of a shipping street address
  --shipp-city: string # Specifies shipping city
  --shipp-company: string # Specifies shipping company
  --shipp-country: string # Specifies shipping country code
  --shipp-fax: string # Specifies shipping fax
  --shipp-first-name: string # Specifies shipping first name
  --shipp-last-name: string # Specifies shipping last name
  --shipp-phone: string # Specifies shipping phone
  --shipp-postcode: string # Specifies shipping postcode
  --shipp-state: string # Specifies shipping state code
  --shipping-price: float # Specifies order's shipping price (default: 0)
  --shipping-tax: float # Specifies order's shipping price tax
  --store-id: string # Defines store id where the order should be assigned
  --subtotal-price: float # Total price of all ordered products multiplied by their number, excluding tax, shipping price and discounts
  --tags: string # Order tags
  --tax-price: float # The value of tax cost for order (default: 0)
  --total-paid: float # Defines total paid amount for the order
  --total-price: float # Defines order's total price
  --total-weight: int # Defines the sum of all line item weights in grams for the order
  --transaction-id: string # Payment transaction id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/order.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: admin_comment, var: admin_comment}, {name: admin_private_comment, var: admin_private_comment}, {name: bill_address_1, var: bill_address_1}, {name: bill_address_2, var: bill_address_2}, {name: bill_city, var: bill_city}, {name: bill_company, var: bill_company}, {name: bill_country, var: bill_country}, {name: bill_fax, var: bill_fax}, {name: bill_first_name, var: bill_first_name}, {name: bill_last_name, var: bill_last_name}, {name: bill_phone, var: bill_phone}, {name: bill_postcode, var: bill_postcode}, {name: bill_state, var: bill_state}, {name: channel_id, var: channel_id}, {name: clear_cache, var: clear_cache}, {name: comment, var: comment}, {name: coupon_discount, var: coupon_discount}, {name: coupons, var: coupons}, {name: create_invoice, var: create_invoice}, {name: currency, var: currency}, {name: customer_birthday, var: customer_birthday}, {name: customer_email, var: customer_email}, {name: customer_fax, var: customer_fax}, {name: customer_first_name, var: customer_first_name}, {name: customer_last_name, var: customer_last_name}, {name: customer_phone, var: customer_phone}, {name: date, var: date}, {name: date_finished, var: date_finished}, {name: date_modified, var: date_modified}, {name: discount, var: discount}, {name: external_source, var: external_source}, {name: financial_status, var: financial_status}, {name: fulfillment_status, var: fulfillment_status}, {name: gift_certificate_discount, var: gift_certificate_discount}, {name: id, var: id}, {name: inventory_behaviour, var: inventory_behaviour}, {name: note_attributes, var: note_attributes}, {name: order_id, var: order_id}, {name: order_item, var: order_item}, {name: order_payment_method, var: order_payment_method}, {name: order_shipping_method, var: order_shipping_method}, {name: order_status, var: order_status}, {name: prices_inc_tax, var: prices_inc_tax}, {name: send_admin_notifications, var: send_admin_notifications}, {name: send_notifications, var: send_notifications}, {name: shipp_address_1, var: shipp_address_1}, {name: shipp_address_2, var: shipp_address_2}, {name: shipp_city, var: shipp_city}, {name: shipp_company, var: shipp_company}, {name: shipp_country, var: shipp_country}, {name: shipp_fax, var: shipp_fax}, {name: shipp_first_name, var: shipp_first_name}, {name: shipp_last_name, var: shipp_last_name}, {name: shipp_phone, var: shipp_phone}, {name: shipp_postcode, var: shipp_postcode}, {name: shipp_state, var: shipp_state}, {name: shipping_price, var: shipping_price}, {name: shipping_tax, var: shipping_tax}, {name: store_id, var: store_id}, {name: subtotal_price, var: subtotal_price}, {name: tags, var: tags}, {name: tax_price, var: tax_price}, {name: total_paid, var: total_paid}, {name: total_price, var: total_price}, {name: total_weight, var: total_weight}, {name: transaction_id, var: transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    admin_comment: $admin_comment, admin_private_comment: $admin_private_comment, bill_address_1: $bill_address_1, bill_address_2: $bill_address_2, bill_city: $bill_city, bill_company: $bill_company, bill_country: $bill_country, bill_fax: $bill_fax, bill_first_name: $bill_first_name, bill_last_name: $bill_last_name, bill_phone: $bill_phone, bill_postcode: $bill_postcode, bill_state: $bill_state, channel_id: $channel_id, clear_cache: $clear_cache, comment: $comment, coupon_discount: $coupon_discount, coupons: $coupons, create_invoice: $create_invoice, currency: $currency, customer_birthday: $customer_birthday, customer_email: $customer_email, customer_fax: $customer_fax, customer_first_name: $customer_first_name, customer_last_name: $customer_last_name, customer_phone: $customer_phone, date: $date, date_finished: $date_finished, date_modified: $date_modified, discount: $discount, external_source: $external_source, financial_status: $financial_status, fulfillment_status: $fulfillment_status, gift_certificate_discount: $gift_certificate_discount, id: $id, inventory_behaviour: $inventory_behaviour, note_attributes: $note_attributes, order_id: $order_id, order_item: $order_item, order_payment_method: $order_payment_method, order_shipping_method: $order_shipping_method, order_status: $order_status, prices_inc_tax: $prices_inc_tax, send_admin_notifications: $send_admin_notifications, send_notifications: $send_notifications, shipp_address_1: $shipp_address_1, shipp_address_2: $shipp_address_2, shipp_city: $shipp_city, shipp_company: $shipp_company, shipp_country: $shipp_country, shipp_fax: $shipp_fax, shipp_first_name: $shipp_first_name, shipp_last_name: $shipp_last_name, shipp_phone: $shipp_phone, shipp_postcode: $shipp_postcode, shipp_state: $shipp_state, shipping_price: $shipping_price, shipping_tax: $shipping_tax, store_id: $store_id, subtotal_price: $subtotal_price, tags: $tags, tax_price: $tax_price, total_paid: $total_paid, total_price: $total_price, total_weight: $total_weight, transaction_id: $transaction_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count orders in store
#
# GET /order.count.json
# Returns: record<result: record<orders_count: int>, return_code: int, return_message: string>
# operationId: OrderCount
export def "order-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Counts orders quantity specified by customer id
  --customer-email: string # Counts orders quantity specified by customer email
  --order-status: string # Counts orders quantity specified by order status
  --order-status-ids: list<string> # Retrieves orders specified by order statuses
  --created-to: string # Retrieve entities to their creation date
  --created-from: string # Retrieve entities from their creation date
  --modified-to: string # Retrieve entities to their modification date
  --modified-from: string # Retrieve entities from their modification date
  --store-id: string # Counts orders quantity specified by store id
  --ids: string # Counts orders specified by ids
  --order-ids: string # Counts orders specified by order ids
  --ebay-order-status: string # Counts orders quantity specified by order status
  --financial-status: string # Counts orders quantity specified by financial status
  --fulfillment-status: string # Create order with fulfillment status
  --shipping-method: string # Retrieve entities according to shipping method
  --delivery-method: string # Retrieves order with delivery method
  --ship-node-type: string # Retrieves order with ship node type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.count.json"
    query: [{name: customer_id, var: customer_id}, {name: customer_email, var: customer_email}, {name: order_status, var: order_status}, {name: order_status_ids, var: order_status_ids, style: csv}, {name: created_to, var: created_to}, {name: created_from, var: created_from}, {name: modified_to, var: modified_to}, {name: modified_from, var: modified_from}, {name: store_id, var: store_id}, {name: ids, var: ids}, {name: order_ids, var: order_ids}, {name: ebay_order_status, var: ebay_order_status}, {name: financial_status, var: financial_status}, {name: fulfillment_status, var: fulfillment_status}, {name: shipping_method, var: shipping_method}, {name: delivery_method, var: delivery_method}, {name: ship_node_type, var: ship_node_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    customer_id: $customer_id, customer_email: $customer_email, order_status: $order_status, order_status_ids: $order_status_ids, created_to: $created_to, created_from: $created_from, modified_to: $modified_to, modified_from: $modified_from, store_id: $store_id, ids: $ids, order_ids: $order_ids, ebay_order_status: $ebay_order_status, financial_status: $financial_status, fulfillment_status: $fulfillment_status, shipping_method: $shipping_method, delivery_method: $delivery_method, ship_node_type: $ship_node_type
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve list of financial statuses
#
# GET /order.financial_status.list.json
# Returns: record<result: record<order_financial_statuses: list<record>>, return_code: int, return_message: string>
# operationId: OrderFinancialStatusList
export def "order-financial-status-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.financial_status.list.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method is deprecated and won't be supported in the future. Please use "order.list" instead.
#
# GET /order.find.json
# DEPRECATED
# Returns: record<result: record<order: list<record>>, return_code: int, return_message: string>
# operationId: OrderFind
@deprecated
export def "order-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Retrieves orders specified by customer id
  --customer-email: string # Retrieves orders specified by customer email
  --order-status: string # Retrieves orders specified by order status
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: order_id,customer,totals,address,items,bundles,status)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-to: string # Retrieve entities to their creation date
  --created-from: string # Retrieve entities from their creation date
  --modified-to: string # Retrieve entities to their modification date
  --modified-from: string # Retrieve entities from their modification date
  --financial-status: string # Retrieves orders specified by financial status
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.find.json"
    query: [{name: customer_id, var: customer_id}, {name: customer_email, var: customer_email}, {name: order_status, var: order_status}, {name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: exclude, var: exclude}, {name: created_to, var: created_to}, {name: created_from, var: created_from}, {name: modified_to, var: modified_to}, {name: modified_from, var: modified_from}, {name: financial_status, var: financial_status}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    customer_id: $customer_id, customer_email: $customer_email, order_status: $order_status, start: $start, count: $count, params: $params, exclude: $exclude, created_to: $created_to, created_from: $created_from, modified_to: $modified_to, modified_from: $modified_from, financial_status: $financial_status
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve list of fulfillment statuses
#
# GET /order.fulfillment_status.list.json
# Returns: record<result: record<order_fulfillment_statuses: list<record>>, return_code: int, return_message: string>
# operationId: OrderFulfillmentStatusList
export def "order-fulfillment-status-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.fulfillment_status.list.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Info about a specific order by ID
#
# GET /order.info.json
# Returns: record<result: record<additional_fields: record, basket_id: string, billing_address: record<additional_fields: record, address1: string, address2: string, city: string, company: string, country: record, custom_fields: record, default: bool, fax: string, first_name: string, gender: string, id: string, last_name: string, phone: string, postcode: string, region: string, state: record, type: string, website: string>, bundles: list<record>, channel_id: string, comment: string, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, currency: record<additional_fields: record, avail: bool, custom_fields: record, default: bool, id: string, iso3: string, name: string, rate: float, symbol_left: string, symbol_right: string>, custom_fields: record, customer: record<additional_fields: record, custom_fields: record, email: string, first_name: string, id: string, last_name: string, phone: string>, discounts: list<record>, finished_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, gift_message: string, id: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, order_details_url: string, order_id: string, order_products: list<record>, payment_method: record<additional_fields: record, custom_fields: record, name: string>, refunds: list<record>, shipping_address: record<additional_fields: record, address1: string, address2: string, city: string, company: string, country: record, custom_fields: record, default: bool, fax: string, first_name: string, gender: string, id: string, last_name: string, phone: string, postcode: string, region: string, state: record, type: string, website: string>, shipping_method: record<additional_fields: record, custom_fields: record, name: string>, shipping_methods: list<record>, status: record<additional_fields: record, custom_fields: record, history: list, id: string, name: string, refund_info: record>, store_id: string, total: record<additional_fields: record, custom_fields: record, shipping_ex_tax: float, subtotal_ex_tax: float, total: float, total_discount: float, total_paid: float, total_tax: float, wrapping_ex_tax: float>, totals: record<additional_fields: record, custom_fields: record, discount: float, shipping: float, subtotal: float, tax: float, total: float>, warehouses_ids: list<string>>, return_code: int, return_message: string>
# operationId: OrderInfo
export def "order-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # Retrieves order’s info specified by order id
  --id: string # Retrieves order info specified by id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: order_id,customer,totals,address,items,bundles,status)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Defines store id where the order should be found
  --enable-cache: oneof<nothing, bool> # If the value is 'true' and order exist in our cache, we will return order.info response from cache (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.info.json"
    query: [{name: order_id, var: order_id}, {name: id, var: id}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: store_id, var: store_id}, {name: enable_cache, var: enable_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    order_id: $order_id, id: $id, params: $params, response_fields: $response_fields, exclude: $exclude, store_id: $store_id, enable_cache: $enable_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of orders from store.
#
# GET /order.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, order: list<record>, orders_count: int>, return_code: int, return_message: string>
# operationId: OrderList
export def "order-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Retrieves orders specified by customer id
  --customer-email: string # Retrieves orders specified by customer email
  --phone: string # Filter orders by customer's phone number
  --order-status: string # Retrieves orders specified by order status
  --order-status-ids: list<string> # Retrieves orders specified by order statuses
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --page-cursor: string # Used to retrieve orders via cursor-based pagination (it can't be used with any other filtering parameter)
  --sort-by: string # Set field to sort by (default: order_id)
  --sort-direction: string # Set sorting direction (default: asc)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: order_id,customer,totals,address,items,bundles,status)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-to: string # Retrieve entities to their creation date
  --created-from: string # Retrieve entities from their creation date
  --modified-to: string # Retrieve entities to their modification date
  --modified-from: string # Retrieve entities from their modification date
  --store-id: string # Store Id
  --ids: string # Retrieves orders specified by ids
  --order-ids: string # Retrieves orders specified by order ids
  --ebay-order-status: string # Retrieves orders specified by order status
  --basket-id: string # Retrieves order’s info specified by basket id.
  --financial-status: string # Retrieves orders specified by financial status
  --fulfillment-status: string # Create order with fulfillment status
  --shipping-method: string # Retrieve entities according to shipping method
  --skip-order-ids: string # Skipped orders by ids
  --since-id: int # Retrieve entities starting from the specified id.
  --is-deleted: oneof<nothing, bool> # Filter deleted orders
  --shipping-country-iso3: string # Retrieve entities according to shipping country
  --enable-cache: oneof<nothing, bool> # If the value is 'true', we will cache orders for a 15 minutes in order to increase speed and reduce requests throttling for some methods and shoping platforms (for example order.shipment.add) (default: false)
  --delivery-method: string # Retrieves order with delivery method
  --ship-node-type: string # Retrieves order with ship node type
  --currency-id: string # Currency Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.list.json"
    query: [{name: customer_id, var: customer_id}, {name: customer_email, var: customer_email}, {name: phone, var: phone}, {name: order_status, var: order_status}, {name: order_status_ids, var: order_status_ids, style: csv}, {name: start, var: start}, {name: count, var: count}, {name: page_cursor, var: page_cursor}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: created_to, var: created_to}, {name: created_from, var: created_from}, {name: modified_to, var: modified_to}, {name: modified_from, var: modified_from}, {name: store_id, var: store_id}, {name: ids, var: ids}, {name: order_ids, var: order_ids}, {name: ebay_order_status, var: ebay_order_status}, {name: basket_id, var: basket_id}, {name: financial_status, var: financial_status}, {name: fulfillment_status, var: fulfillment_status}, {name: shipping_method, var: shipping_method}, {name: skip_order_ids, var: skip_order_ids}, {name: since_id, var: since_id}, {name: is_deleted, var: is_deleted}, {name: shipping_country_iso3, var: shipping_country_iso3}, {name: enable_cache, var: enable_cache}, {name: delivery_method, var: delivery_method}, {name: ship_node_type, var: ship_node_type}, {name: currency_id, var: currency_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    customer_id: $customer_id, customer_email: $customer_email, phone: $phone, order_status: $order_status, order_status_ids: $order_status_ids, start: $start, count: $count, page_cursor: $page_cursor, sort_by: $sort_by, sort_direction: $sort_direction, params: $params, response_fields: $response_fields, exclude: $exclude, created_to: $created_to, created_from: $created_from, modified_to: $modified_to, modified_from: $modified_from, store_id: $store_id, ids: $ids, order_ids: $order_ids, ebay_order_status: $ebay_order_status, basket_id: $basket_id, financial_status: $financial_status, fulfillment_status: $fulfillment_status, shipping_method: $shipping_method, skip_order_ids: $skip_order_ids, since_id: $since_id, is_deleted: $is_deleted, shipping_country_iso3: $shipping_country_iso3, enable_cache: $enable_cache, delivery_method: $delivery_method, ship_node_type: $ship_node_type, currency_id: $currency_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve list of order preestimated shipping methods
#
# POST /order.preestimate_shipping.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, preestimate_shippings: list<record>, preestimate_shippings_count: int>, return_code: int, return_message: string>
# operationId: OrderPreestimateShippingList
export def "order-preestimate-shipping-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-email: string # Retrieves orders specified by customer email
  --customer-id: string # Retrieves orders specified by customer id
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  order_item: list # item shape: {order_item_id: string, order_item_model?: string, order_item_option?: list, order_item_quantity: int, order_item_variant_id?: string, order_item_weight?: float}
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --shipp-address-1: string # Specifies first shipping address
  --shipp-city: string # Specifies shipping city
  shipp_country: string # Specifies shipping country code
  --shipp-postcode: string # Specifies shipping postcode
  --shipp-state: string # Specifies shipping state code
  --store-id: string # Store Id
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/order.preestimate_shipping.list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: customer_email, var: customer_email}, {name: customer_id, var: customer_id}, {name: exclude, var: exclude}, {name: order_item, var: order_item}, {name: params, var: params}, {name: shipp_address_1, var: shipp_address_1}, {name: shipp_city, var: shipp_city}, {name: shipp_country, var: shipp_country}, {name: shipp_postcode, var: shipp_postcode}, {name: shipp_state, var: shipp_state}, {name: store_id, var: store_id}, {name: warehouse_id, var: warehouse_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    customer_email: $customer_email, customer_id: $customer_id, exclude: $exclude, order_item: $order_item, params: $params, shipp_address_1: $shipp_address_1, shipp_city: $shipp_city, shipp_country: $shipp_country, shipp_postcode: $shipp_postcode, shipp_state: $shipp_state, store_id: $store_id, warehouse_id: $warehouse_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a refund to the order.
#
# POST /order.refund.add.json
# Returns: record<result: record<refund_id: string>, return_code: int, return_message: string>
# operationId: OrderRefundAdd
export def "order-refund-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Specifies an order creation date in format Y-m-d H:i:s
  --fee-price: float # Specifies refund's fee price
  --is-online: oneof<nothing, bool> # Indicates whether refund type is online (default: false)
  --item-restock: oneof<nothing, bool> # Boolean, whether or not to add the line items back to the store inventory. (default: false)
  --items: list # Defines items in the order that will be refunded — item shape: {order_product_id?: string, price?: float, quantity?: int}
  --message: string # Refund reason, or some else message which assigned to refund.
  --order-id: string # Defines the order for which the refund will be created.
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after refund was created (default: false)
  --shipping-price: float # Defines refund shipping amount.
  --total-price: float # Defines order refund amount.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/order.refund.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: date, var: date}, {name: fee_price, var: fee_price}, {name: is_online, var: is_online}, {name: item_restock, var: item_restock}, {name: items, var: items}, {name: message, var: message}, {name: order_id, var: order_id}, {name: send_notifications, var: send_notifications}, {name: shipping_price, var: shipping_price}, {name: total_price, var: total_price}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    date: $date, fee_price: $fee_price, is_online: $is_online, item_restock: $item_restock, items: $items, message: $message, order_id: $order_id, send_notifications: $send_notifications, shipping_price: $shipping_price, total_price: $total_price
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a shipment to the order.
#
# POST /order.shipment.add.json
# Returns: record<result: record<shipment_id: string>, return_code: int, return_message: string>
# operationId: OrderShipmentAdd
export def "order-shipment-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --adjust-stock: oneof<nothing, bool> # This parameter is used for adjust stock. (default: false)
  --enable-cache: oneof<nothing, bool> # If the value is 'true' and order exist in our cache, we will use order.info from cache to prepare shipment items. (default: false)
  --is-shipped: oneof<nothing, bool> # Defines shipment's status (default: true)
  --items: list # Defines items in the order that will be shipped — item shape: {order_product_id?: string, quantity?: float}
  --order-id: string # Defines the order for which the shipment will be created
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after shipment was created (default: false)
  --shipment-provider: string # Defines company name that provide tracking of shipment
  --shipping-method: string # Define shipping method
  --store-id: string # Store Id
  --tracking-link: string # Defines custom tracking link
  --tracking-numbers: list # Defines shipment's tracking numbers that have to be added How set tracking numbers to appropriate carrier:tracking_numbers[]=a2c.demo1,a2c.demo2 - set default carriertracking_numbers[carrier_id]=a2c.demo - set appropriate carrierTo get the list of carriers IDs that are available in your store, use the cart.info method — item shape: {carrier_id?: string, tracking_number?: string}
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/order.shipment.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: adjust_stock, var: adjust_stock}, {name: enable_cache, var: enable_cache}, {name: is_shipped, var: is_shipped}, {name: items, var: items}, {name: order_id, var: order_id}, {name: send_notifications, var: send_notifications}, {name: shipment_provider, var: shipment_provider}, {name: shipping_method, var: shipping_method}, {name: store_id, var: store_id}, {name: tracking_link, var: tracking_link}, {name: tracking_numbers, var: tracking_numbers}, {name: warehouse_id, var: warehouse_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    adjust_stock: $adjust_stock, enable_cache: $enable_cache, is_shipped: $is_shipped, items: $items, order_id: $order_id, send_notifications: $send_notifications, shipment_provider: $shipment_provider, shipping_method: $shipping_method, store_id: $store_id, tracking_link: $tracking_link, tracking_numbers: $tracking_numbers, warehouse_id: $warehouse_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete order's shipment.
#
# DELETE /order.shipment.delete.json
# Returns: record<result: record<status: int>, return_code: int, return_message: string>
# operationId: OrderShipmentDelete
export def "order-shipment-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipment-id: string # Shipment id indicates the number of delivery (required)
  --order-id: string # Defines the order for which the shipment will be deleted (required)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/order.shipment.delete.json"
    query: [{name: shipment_id, var: shipment_id, required: true}, {name: order_id, var: order_id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    shipment_id: $shipment_id, order_id: $order_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information of shipment.
#
# GET /order.shipment.info.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, shipment: list<record>, shipment_count: int>, return_code: int, return_message: string>
# operationId: OrderShipmentInfo
export def "order-shipment-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id (required)
  --order-id: string # Defines the order id (required)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,order_id,items,tracking_numbers)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.shipment.info.json"
    query: [{name: id, var: id, required: true}, {name: order_id, var: order_id, required: true}, {name: start, var: start}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, order_id: $order_id, start: $start, params: $params, response_fields: $response_fields, exclude: $exclude, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of shipments by orders.
#
# GET /order.shipment.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, shipment: list<record>, shipment_count: int>, return_code: int, return_message: string>
# operationId: OrderShipmentList
export def "order-shipment-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # Retrieves shipments specified by order id (required)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,order_id,items,tracking_numbers)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.shipment.list.json"
    query: [{name: order_id, var: order_id, required: true}, {name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    order_id: $order_id, page_cursor: $page_cursor, start: $start, count: $count, params: $params, response_fields: $response_fields, exclude: $exclude, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add order shipment's tracking info.
#
# POST /order.shipment.tracking.add.json
# Returns: record<result: record<tracking_id: string>, return_code: int, return_message: string>
# operationId: OrderShipmentTrackingAdd
export def "order-shipment-tracking-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: string # Defines tracking carrier id
  --order-id: string # Defines the order id
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after tracking was created (default: false)
  shipment_id: string # Shipment id indicates the number of delivery
  --store-id: string # Store Id
  --tracking-link: string # Defines custom tracking link
  tracking_number: string # Defines tracking number
  --tracking-provider: string # Defines name of the company which provides shipment tracking
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/order.shipment.tracking.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: carrier_id, var: carrier_id}, {name: order_id, var: order_id}, {name: send_notifications, var: send_notifications}, {name: shipment_id, var: shipment_id}, {name: store_id, var: store_id}, {name: tracking_link, var: tracking_link}, {name: tracking_number, var: tracking_number}, {name: tracking_provider, var: tracking_provider}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    carrier_id: $carrier_id, order_id: $order_id, send_notifications: $send_notifications, shipment_id: $shipment_id, store_id: $store_id, tracking_link: $tracking_link, tracking_number: $tracking_number, tracking_provider: $tracking_provider
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order's shipment information.
#
# PUT /order.shipment.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: OrderShipmentUpdate
export def "order-shipment-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-shipped: oneof<nothing, bool> # Defines shipment's status (default: true)
  --order-id: string # Defines the order that will be updated
  --replace: oneof<nothing, bool> # Allows rewrite tracking numbers (default: true)
  shipment_id: string # Shipment id indicates the number of delivery
  --store-id: string # Store Id
  --tracking-link: string # Defines custom tracking link
  --tracking-numbers: list # Defines shipment's tracking numbers that have to be added How set tracking numbers to appropriate carrier:tracking_numbers[]=a2c.demo1,a2c.demo2 - set default carriertracking_numbers[carrier_id]=a2c.demo - set appropriate carrierTo get the list of carriers IDs that are available in your store, use the cart.info method — item shape: {carrier_id?: string, tracking_number?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/order.shipment.update.json"
    body: {content_type: "application/json", kind: json, fields: [{name: is_shipped, var: is_shipped}, {name: order_id, var: order_id}, {name: replace, var: replace}, {name: shipment_id, var: shipment_id}, {name: store_id, var: store_id}, {name: tracking_link, var: tracking_link}, {name: tracking_numbers, var: tracking_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    is_shipped: $is_shipped, order_id: $order_id, replace: $replace, shipment_id: $shipment_id, store_id: $store_id, tracking_link: $tracking_link, tracking_numbers: $tracking_numbers
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve list of statuses
#
# GET /order.status.list.json
# Returns: record<result: record<cart_order_statuses: list<record>>, return_code: int, return_message: string>
# operationId: OrderStatusList
export def "order-status-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.status.list.json"
    query: [{name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve list of order transaction
#
# GET /order.transaction.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, transactions: list<record>, transactions_count: int>, return_code: int, return_message: string>
# operationId: OrderTransactionList
export def "order-transaction-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --order-ids: string # Retrieves order transactions specified by order ids (required)
  --store-id: string # Store Id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,order_id,amount,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order.transaction.list.json"
    query: [{name: count, var: count}, {name: order_ids, var: order_ids, required: true}, {name: store_id, var: store_id}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: page_cursor, var: page_cursor}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    count: $count, order_ids: $order_ids, store_id: $store_id, params: $params, response_fields: $response_fields, exclude: $exclude, page_cursor: $page_cursor
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing order.
#
# PUT /order.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: OrderUpdate
export def "order-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # Defines the orders specified by order id (required)
  --store-id: string # Defines store id where the order should be found
  --order-status: string # Defines new order's status
  --comment: string # Specifies order comment
  --admin-comment: string # Specifies admin's order comment
  --admin-private-comment: string # Specifies private admin's order comment
  --date-modified: string # Specifies order's modification date
  --date-finished: string # Specifies order's finished date
  --financial-status: string # Update order financial status to specified
  --fulfillment-status: string # Create order with fulfillment status
  --order-payment-method: string # Defines order payment method.Setting order_payment_method on Shopify will also change financial_status field value to 'paid'
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after order was created (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/order.update.json"
    query: [{name: order_id, var: order_id, required: true}, {name: store_id, var: store_id}, {name: order_status, var: order_status}, {name: comment, var: comment}, {name: admin_comment, var: admin_comment}, {name: admin_private_comment, var: admin_private_comment}, {name: date_modified, var: date_modified}, {name: date_finished, var: date_finished}, {name: financial_status, var: financial_status}, {name: fulfillment_status, var: fulfillment_status}, {name: order_payment_method, var: order_payment_method}, {name: send_notifications, var: send_notifications}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    order_id: $order_id, store_id: $store_id, order_status: $order_status, comment: $comment, admin_comment: $admin_comment, admin_private_comment: $admin_private_comment, date_modified: $date_modified, date_finished: $date_finished, financial_status: $financial_status, fulfillment_status: $fulfillment_status, order_payment_method: $order_payment_method, send_notifications: $send_notifications
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new product to store.
#
# POST /product.add.json
# Returns: record<result: record<product_id: string>, return_code: int, return_message: string>
# operationId: ProductAdd
export def "product-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-name: string # Defines product’s attribute name separated with a comma in Magento
  --attribute-set-name: string # Defines product’s attribute set name in Magento (default: Default)
  --avail-from: string # Allows to schedule a time in the future that the item becomes available. The value should be greater than the current date and time.
  --available-for-sale: oneof<nothing, bool> # Specifies the set of visible/invisible products for sale (default: true)
  --available-for-view: oneof<nothing, bool> # Specifies the set of visible/invisible products for users (default: true)
  --backorder-status: string # Set backorder status
  --barcode: string # A barcode is a unique code composed of numbers used as a product identifier.
  --best-offer: list<string> # The price at which Best Offers are automatically accepted.Param structure:best_offer[minimum_offer_price] = decimalbest_offer[auto_accept_price] = decimal
  --brand-name: string # Retrieves brands specified by brand name
  --categories-ids: string # Defines product add that is specified by comma-separated categories id
  --category-id: string # Defines product add that is specified by category id
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --condition: string # The human-readable label for the condition (e.g., "New").
  --cost-price: float # Defines new product's cost price
  --country-of-origin: string # The country where the inventory item was made
  --created-at: string # Defines the date of entity creation
  description: string # Defines product's description that has to be added
  --downloadable: oneof<nothing, bool> # Defines whether the product is downloadable (default: false)
  --ean: string # European Article Number. An EAN is a unique 8 or 13-digit identifier that many industries (such as book publishers) use to identify products.
  --files: list # File Url — item shape: {name: string, url: string}
  --group-prices: list # Defines product's group prices — item shape: {group_id?: string, price?: float}
  --gtin: string # Global Trade Item Number. An GTIN is an identifier for trade items.
  --harmonized-system-code: string # Harmonized System Code. An HSC is a 6-digit identifier that allows participating countries to classify traded goods on a common basis for customs purposes
  --height: float # Defines product's height
  --image-name: string # Defines image's name
  --image-url: string # Image Url
  --isbn: string # International Standard Book Number. An ISBN is a unique identifier for books.
  --lang-id: string # Language id
  --length: float # Defines product's length
  --listing-duration: string # Describes the number of days the seller wants the listing to be active. Look at cart.info method response for allowed values.
  --listing-type: string # Indicates the selling format of the marketplace listing. (default: FixedPrice)
  --manage-stock: oneof<nothing, bool> # Defines inventory tracking for product
  --manufacturer: string # Defines product's manufacturer
  --marketplace-item-properties: string # String containing the JSON representation of the supplied data (default: false)
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --meta-title: string # Defines unique meta title for each entity
  model: string # Defines product's model that has to be added
  --mpn: string # Manufacturer Part Number. A MPN is an identifier of a particular part design or material used.
  name: string # Defines product's name that has to be added
  --old-price: float # Defines product's old price
  --ordered-count: int # Defines how many times the product was ordered (default: 0)
  --package-details: list<string> # If the seller is subscribed to "Business Policies", use the seller_profiles instead of the shipping_details, payment_methods and return_accepted params.Param structure:package_details[measure_unit] = string Allowed measure_unit values: [English or Metric] Default: Metricpackage_details[weigh_unit] = string Allowed weigh_unit values: [kg, g, lbs, oz]package_details[package_depth] = decimalpackage_details[package_length] = decimalpackage_details[package_width] = decimalpackage_details[weight_major] = decimalpackage_details[weight_minor] = decimalpackage_details[shipping_package] = string See cart.info method, param `eBay_shipping_package_details`
  --payment-methods: list<string> # Identifies the payment method (such as PayPal) that the seller will accept when the buyer pays for the item. Look at cart.info method response for allowed values.Param structure:payment_methods[0] = stringpayment_methods[1] = string
  --paypal-email: string # Valid PayPal email address for the PayPal account that the seller will use if they offer PayPal as a payment method for the listing.
  price: float # Defines product's price that has to be added
  --product-class: string # A categorization for the product
  --quantity: float # Defines product's quantity that has to be added (default: 0)
  --return-accepted: oneof<nothing, bool> # Indicates whether the seller allows the buyer to return the item.
  --sales-tax: list<string> # Percent of an item's price to be charged as the sales tax for the order. Look at cart.info method response for allowed values.Param structure:sales_tax[tax_percent] = decimal (##.###)sales_tax[tax_state] = stringsales_tax[shipping_inc_in_tax] = bool
  --search-keywords: string # Defines unique search keywords
  --seller-profiles: record # If the seller is subscribed to "Business Policies", use the seller_profiles instead of the shipping_details, payment_methods and return_accepted params.Param structure:seller_profiles[shipping_profile_id] = integerseller_profiles[payment_profile_id] = integerseller_profiles[return_profile_id] = integer — shape: {payment_profile_id?: string, return_profile_id?: string, shipping_profile_id?: string}
  --seo-url: string # Defines unique URL for SEO
  --shipping-details: list # The shipping details, including flat and calculated shipping costs and shipping insurance costs. Look at cart.info method response for allowed values.Param structure:shipping_details[0][shipping_type] = string shipping_details[0][shipping_service] = stringshipping_details[0][shipping_cost] = decimalshipping_details[1][shipping_type] = string shipping_details[1][shipping_service] = stringshipping_details[1][shipping_cost] = decimal — item shape: {shipping_cost?: float, shipping_service?: string, shipping_type?: string}
  --shipping-template-id: int # The numeric ID of the shipping template associated with the products in Etsy. (default: 0)
  --short-description: string # Defines short description
  --sku: string # Defines product's sku that has to be added
  --special-price: float # Defines product's model that has to be added
  --specifics: list<string> # An array of Item Specific Name/Value pairs used by the seller to provide descriptive details of an item in a structured manner. Param structure: specifics[int][name] = string specifics[int][value] = string
  --sprice-create: string # Defines the date of special price creation
  --sprice-expire: string # Defines the term of special price offer duration
  --sprice-modified: string # Defines the date of special price modification
  --status: string # Defines product's status
  --store-id: string # Store Id
  --stores-ids: string # Assign product to the stores that is specified by comma-separated stores' id (default: 0)
  --tags: string # Product tags
  --tax-class-id: int # Defines tax classes where entity has to be added
  --taxable: oneof<nothing, bool> # Specifies whether a tax is charged (default: true)
  --tier-prices: list # Defines product's tier prices — item shape: {price?: float, quantity?: float}
  --type: string # Defines product's type (default: simple)
  --upc: string # Universal Product Code. A UPC (UPC-A) is a commonly used identifer for many different products.
  --url: string # Defines unique product's URL
  --viewed-count: int # Specifies the number of product's reviews (default: 0)
  --visible: string # Set visibility status
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
  --weight: float # Weight (default: 0)
  --weight-unit: string # Weight Unit
  --wholesale-price: float # Defines product's sale price
  --width: float # Defines product's width
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: attribute_name, var: attribute_name}, {name: attribute_set_name, var: attribute_set_name}, {name: avail_from, var: avail_from}, {name: available_for_sale, var: available_for_sale}, {name: available_for_view, var: available_for_view}, {name: backorder_status, var: backorder_status}, {name: barcode, var: barcode}, {name: best_offer, var: best_offer}, {name: brand_name, var: brand_name}, {name: categories_ids, var: categories_ids}, {name: category_id, var: category_id}, {name: clear_cache, var: clear_cache}, {name: condition, var: condition}, {name: cost_price, var: cost_price}, {name: country_of_origin, var: country_of_origin}, {name: created_at, var: created_at}, {name: description, var: description}, {name: downloadable, var: downloadable}, {name: ean, var: ean}, {name: files, var: files}, {name: group_prices, var: group_prices}, {name: gtin, var: gtin}, {name: harmonized_system_code, var: harmonized_system_code}, {name: height, var: height}, {name: image_name, var: image_name}, {name: image_url, var: image_url}, {name: isbn, var: isbn}, {name: lang_id, var: lang_id}, {name: length, var: length}, {name: listing_duration, var: listing_duration}, {name: listing_type, var: listing_type}, {name: manage_stock, var: manage_stock}, {name: manufacturer, var: manufacturer}, {name: marketplace_item_properties, var: marketplace_item_properties}, {name: meta_description, var: meta_description}, {name: meta_keywords, var: meta_keywords}, {name: meta_title, var: meta_title}, {name: model, var: model}, {name: mpn, var: mpn}, {name: name, var: name}, {name: old_price, var: old_price}, {name: ordered_count, var: ordered_count}, {name: package_details, var: package_details}, {name: payment_methods, var: payment_methods}, {name: paypal_email, var: paypal_email}, {name: price, var: price}, {name: product_class, var: product_class}, {name: quantity, var: quantity}, {name: return_accepted, var: return_accepted}, {name: sales_tax, var: sales_tax}, {name: search_keywords, var: search_keywords}, {name: seller_profiles, var: seller_profiles}, {name: seo_url, var: seo_url}, {name: shipping_details, var: shipping_details}, {name: shipping_template_id, var: shipping_template_id}, {name: short_description, var: short_description}, {name: sku, var: sku}, {name: special_price, var: special_price}, {name: specifics, var: specifics}, {name: sprice_create, var: sprice_create}, {name: sprice_expire, var: sprice_expire}, {name: sprice_modified, var: sprice_modified}, {name: status, var: status}, {name: store_id, var: store_id}, {name: stores_ids, var: stores_ids}, {name: tags, var: tags}, {name: tax_class_id, var: tax_class_id}, {name: taxable, var: taxable}, {name: tier_prices, var: tier_prices}, {name: type, var: type}, {name: upc, var: upc}, {name: url, var: url}, {name: viewed_count, var: viewed_count}, {name: visible, var: visible}, {name: warehouse_id, var: warehouse_id}, {name: weight, var: weight}, {name: weight_unit, var: weight_unit}, {name: wholesale_price, var: wholesale_price}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    attribute_name: $attribute_name, attribute_set_name: $attribute_set_name, avail_from: $avail_from, available_for_sale: $available_for_sale, available_for_view: $available_for_view, backorder_status: $backorder_status, barcode: $barcode, best_offer: $best_offer, brand_name: $brand_name, categories_ids: $categories_ids, category_id: $category_id, clear_cache: $clear_cache, condition: $condition, cost_price: $cost_price, country_of_origin: $country_of_origin, created_at: $created_at, description: $description, downloadable: $downloadable, ean: $ean, files: $files, group_prices: $group_prices, gtin: $gtin, harmonized_system_code: $harmonized_system_code, height: $height, image_name: $image_name, image_url: $image_url, isbn: $isbn, lang_id: $lang_id, length: $length, listing_duration: $listing_duration, listing_type: $listing_type, manage_stock: $manage_stock, manufacturer: $manufacturer, marketplace_item_properties: $marketplace_item_properties, meta_description: $meta_description, meta_keywords: $meta_keywords, meta_title: $meta_title, model: $model, mpn: $mpn, name: $name, old_price: $old_price, ordered_count: $ordered_count, package_details: $package_details, payment_methods: $payment_methods, paypal_email: $paypal_email, price: $price, product_class: $product_class, quantity: $quantity, return_accepted: $return_accepted, sales_tax: $sales_tax, search_keywords: $search_keywords, seller_profiles: $seller_profiles, seo_url: $seo_url, shipping_details: $shipping_details, shipping_template_id: $shipping_template_id, short_description: $short_description, sku: $sku, special_price: $special_price, specifics: $specifics, sprice_create: $sprice_create, sprice_expire: $sprice_expire, sprice_modified: $sprice_modified, status: $status, store_id: $store_id, stores_ids: $stores_ids, tags: $tags, tax_class_id: $tax_class_id, taxable: $taxable, tier_prices: $tier_prices, type: $type, upc: $upc, url: $url, viewed_count: $viewed_count, visible: $visible, warehouse_id: $warehouse_id, weight: $weight, weight_unit: $weight_unit, wholesale_price: $wholesale_price, width: $width
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of attributes and values.
#
# GET /product.attribute.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, attribute: list<record>, custom_fields: record>, return_code: int, return_message: string>
# operationId: ProductAttributeList
export def "product-attribute-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Retrieves attributes specified by product id (required)
  --attribute-id: string # Retrieves info for specified attribute_id
  --variant-id: string # Defines product's variants specified by variant id
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --attribute-group-id: string # Filter by attribute_group_id
  --set-name: string # Retrieves attributes specified by set_name in Magento
  --lang-id: string # Retrieves attributes specified by language id
  --store-id: string # Retrieves attributes specified by store id
  --sort-by: string # Set field to sort by (default: attribute_id)
  --sort-direction: string # Set sorting direction (default: asc)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: attribute_id,name)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.attribute.list.json"
    query: [{name: product_id, var: product_id, required: true}, {name: attribute_id, var: attribute_id}, {name: variant_id, var: variant_id}, {name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: attribute_group_id, var: attribute_group_id}, {name: set_name, var: set_name}, {name: lang_id, var: lang_id}, {name: store_id, var: store_id}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, attribute_id: $attribute_id, variant_id: $variant_id, page_cursor: $page_cursor, start: $start, count: $count, attribute_group_id: $attribute_group_id, set_name: $set_name, lang_id: $lang_id, store_id: $store_id, sort_by: $sort_by, sort_direction: $sort_direction, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set attribute value to product.
#
# POST /product.attribute.value.set.json
# Returns: record<result: record<attribute_id: string, product_id: string, value_id: string>, return_code: int, return_message: string>
# operationId: ProductAttributeValueSet
export def "product-attribute-value-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the attribute should be added (required)
  --attribute-id: string # Filter by attribute_id
  --attribute-group-id: string # Filter by attribute_group_id
  --attribute-name: string # Define attribute name
  --value: string # Define attribute value
  --value-id: int # Define attribute value id
  --lang-id: string # Language id
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.attribute.value.set.json"
    query: [{name: product_id, var: product_id, required: true}, {name: attribute_id, var: attribute_id}, {name: attribute_group_id, var: attribute_group_id}, {name: attribute_name, var: attribute_name}, {name: value, var: value}, {name: value_id, var: value_id}, {name: lang_id, var: lang_id}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, attribute_id: $attribute_id, attribute_group_id: $attribute_group_id, attribute_name: $attribute_name, value: $value, value_id: $value_id, lang_id: $lang_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes attribute value for a product.
#
# POST /product.attribute.value.unset.json
# Returns: record<result: record<success: string>, return_code: int, return_message: string>
# operationId: ProductAttributeValueUnset
export def "product-attribute-value-unset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Product id (required)
  --attribute-id: string # Attribute Id (required)
  --store-id: string # Store Id
  --include-default: oneof<nothing, bool> # Boolean, whether or not to unset default value of the attribute, if applicable (default: false)
  --reindex: oneof<nothing, bool> # Is reindex required (default: true)
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.attribute.value.unset.json"
    query: [{name: product_id, var: product_id, required: true}, {name: attribute_id, var: attribute_id, required: true}, {name: store_id, var: store_id}, {name: include_default, var: include_default}, {name: reindex, var: reindex}, {name: clear_cache, var: clear_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, attribute_id: $attribute_id, store_id: $store_id, include_default: $include_default, reindex: $reindex, clear_cache: $clear_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of brands from your store.
#
# GET /product.brand.list.json
# Returns: record<result: record<product: list<record>>, return_code: int, return_message: string>
# operationId: ProductBrandList
export def "product-brand-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,short_description,active,url)
  --brand-ids: string # Retrieves brands specified by brand ids
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Store Id
  --lang-id: string # Language id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.brand.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: brand_ids, var: brand_ids}, {name: exclude, var: exclude}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: response_fields, var: response_fields}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, params: $params, brand_ids: $brand_ids, exclude: $exclude, store_id: $store_id, lang_id: $lang_id, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, response_fields: $response_fields
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search product child item (bundled item or configurable product variant) in store catalog.
#
# GET /product.child_item.find.json
# Returns: record<result: record<children: list<record>>, return_code: int, return_message: string>
# operationId: ProductChildItemFind
export def "product-child-item-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find-value: string # Entity search that is specified by some value (required)
  --find-where: string # Entity search that is specified by the comma-separated unique fields (default: name)
  --find-params: string # Entity search that is specified by comma-separated parameters (default: whole_words)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.child_item.find.json"
    query: [{name: find_value, var: find_value, required: true}, {name: find_where, var: find_where}, {name: find_params, var: find_params}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    find_value: $find_value, find_where: $find_where, find_params: $find_params, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get child for specific product.
#
# GET /product.child_item.info.json
# Returns: record<result: record<additional_fields: record, advanced_price: list<record>, allow_backorders: bool, avail_for_sale: bool, combination: list<record>, cost_price: float, created_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, default_price: float, default_qty_in_pack: float, dimensions_unit: string, ean: string, full_description: string, gtin: string, height: float, id: string, images: list<record>, in_stock: bool, inventory: list<record>, inventory_level: float, is_qty_in_pack_fixed: bool, isbn: string, length: float, list_price: float, manage_stock: bool, meta_description: string, meta_keywords: string, meta_title: string, min_quantity: float, modified_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, mpn: string, name: string, parent_id: string, short_description: string, sku: string, sort_order: int, tax_class_id: string, upc: string, weight: float, weight_unit: string, wholesale_price: float, width: float>, return_code: int, return_message: string>
# operationId: ProductChildItemInfo
export def "product-child-item-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --product-id: string # Filter by parent product id (required)
  --id: string # Entity id (required)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --currency-id: string # Currency Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.child_item.info.json"
    query: [{name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: product_id, var: product_id, required: true}, {name: id, var: id, required: true}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: currency_id, var: currency_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    params: $params, response_fields: $response_fields, exclude: $exclude, product_id: $product_id, id: $id, store_id: $store_id, lang_id: $lang_id, currency_id: $currency_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get child items list of specific product(s).
#
# GET /product.child_item.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, children: list<record>, custom_fields: record, total_count: int>, return_code: int, return_message: string>
# operationId: ProductChildItemList
export def "product-child-item-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve products child items via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --product-id: string # Filter by parent product id
  --product-ids: string # Filter by parent product ids
  --store-id: string # Store Id
  --lang-id: string # Language id
  --currency-id: string # Currency Id
  --avail-sale: oneof<nothing, bool> # Specifies the set of available/not available products for sale
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.child_item.list.json"
    query: [{name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: product_id, var: product_id}, {name: product_ids, var: product_ids}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: currency_id, var: currency_id}, {name: avail_sale, var: avail_sale}, {name: report_request_id, var: report_request_id}, {name: disable_report_cache, var: disable_report_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    page_cursor: $page_cursor, start: $start, count: $count, params: $params, response_fields: $response_fields, exclude: $exclude, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, product_id: $product_id, product_ids: $product_ids, store_id: $store_id, lang_id: $lang_id, currency_id: $currency_id, avail_sale: $avail_sale, report_request_id: $report_request_id, disable_report_cache: $disable_report_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count products in store.
#
# GET /product.count.json
# Returns: record<result: record<products_count: int>, return_code: int, return_message: string>
# operationId: ProductCount
export def "product-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: string # Counts products specified by category id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --avail-view: oneof<nothing, bool> # Specifies the set of visible/invisible products
  --avail-sale: oneof<nothing, bool> # Specifies the set of available/not available products for sale
  --store-id: string # Counts products specified by store id
  --lang-id: string # Counts products specified by language id
  --product-ids: string # Counts products specified by product ids
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
  --brand-name: string # Retrieves brands specified by brand name
  --product-attributes: list<string> # Defines product attributes
  --status: string # Defines product's status
  --type: string # Defines products's type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.count.json"
    query: [{name: category_id, var: category_id}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: avail_view, var: avail_view}, {name: avail_sale, var: avail_sale}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: product_ids, var: product_ids}, {name: report_request_id, var: report_request_id}, {name: disable_report_cache, var: disable_report_cache}, {name: brand_name, var: brand_name}, {name: product_attributes, var: product_attributes, style: csv}, {name: status, var: status}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    category_id: $category_id, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, avail_view: $avail_view, avail_sale: $avail_sale, store_id: $store_id, lang_id: $lang_id, product_ids: $product_ids, report_request_id: $report_request_id, disable_report_cache: $disable_report_cache, brand_name: $brand_name, product_attributes: $product_attributes, status: $status, type: $type
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add currency and/or set default in store
#
# POST /product.currency.add.json
# Returns: record<result: record<currency_id: string>, return_code: int, return_message: string>
# operationId: ProductCurrencyAdd
export def "product-currency-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iso3: string # Specifies standardized currency code (required)
  --rate: float # Defines the numerical identifier against to the major currency (required)
  --name: string # Defines currency's name
  --avail: oneof<nothing, bool> # Specifies whether the currency is available (default: true)
  --symbol-left: string # Defines the symbol that is located before the currency
  --symbol-right: string # Defines the symbol that is located after the currency
  --default: oneof<nothing, bool> # Specifies currency's default meaning (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.currency.add.json"
    query: [{name: iso3, var: iso3, required: true}, {name: rate, var: rate, required: true}, {name: name, var: name}, {name: avail, var: avail}, {name: symbol_left, var: symbol_left}, {name: symbol_right, var: symbol_right}, {name: default, var: default}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    iso3: $iso3, rate: $rate, name: $name, avail: $avail, symbol_left: $symbol_left, symbol_right: $symbol_right, default: $default
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of currencies
#
# GET /product.currency.list.json
# Returns: record<result: record<currency: list<record>>, return_code: int, return_message: string>
# operationId: ProductCurrencyList
export def "product-currency-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: name,iso3,default,avail)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --default: oneof<nothing, bool> # Specifies the set of default/not default currencies
  --avail: oneof<nothing, bool> # Specifies the set of available/not available currencies
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.currency.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: page_cursor, var: page_cursor}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}, {name: default, var: default}, {name: avail, var: avail}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, params: $params, page_cursor: $page_cursor, exclude: $exclude, response_fields: $response_fields, default: $default, avail: $avail
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Product delete
#
# DELETE /product.delete.json
# Returns: record<result: record<delete_items: int>, return_code: int, return_message: string>
# operationId: ProductDelete
export def "product-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Product id that will be removed (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/product.delete.json"
    query: [{name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all available fields for product item in store.
#
# GET /product.fields.json
# Returns: record<result: record, return_code: int, return_message: string>
# operationId: ProductFields
export def "product-fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.fields.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search product in store catalog. "Apple" is specified here by default.
#
# GET /product.find.json
# Returns: record<result: record<product: list<record>>, return_code: int, return_message: string>
# operationId: ProductFind
export def "product-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find-value: string # Entity search that is specified by some value (required)
  --find-where: string # Entity search that is specified by the comma-separated unique fields (default: name)
  --find-params: string # Entity search that is specified by comma-separated parameters (default: whole_words)
  --find-what: string # Parameter's value specifies the entity that has to be found (default: product)
  --lang-id: string # Search products specified by language id
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.find.json"
    query: [{name: find_value, var: find_value, required: true}, {name: find_where, var: find_where}, {name: find_params, var: find_params}, {name: find_what, var: find_what}, {name: lang_id, var: lang_id}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    find_value: $find_value, find_where: $find_where, find_params: $find_params, find_what: $find_what, lang_id: $lang_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add image to product
#
# POST /product.image.add.json
# Returns: record<result: record<id: string, image_path: string>, return_code: int, return_message: string>
# operationId: ProductImageAdd
export def "product-image-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # Content(body) encoded in base64 of image file
  image_name: string # Defines image's name
  --label: string # Defines alternative text that has to be attached to the picture
  --lang-id: string # Add product image on specified language id
  --mime: string # Mime type of image http://en.wikipedia.org/wiki/Internet_media_type.
  --position: int # Defines image’s position in the list (default: 0)
  --product-id: string # Defines product id where the image should be added
  --product-variant-id: int # Defines product's variants specified by variant id
  --store-id: string # Store Id
  type: string@type-completer-2 # Defines image's types that are specified by comma-separated list
  --url: string # Defines URL of the image that has to be added
  --variant-ids: string # Defines product's variants ids
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product.image.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: image_name, var: image_name}, {name: label, var: label}, {name: lang_id, var: lang_id}, {name: mime, var: mime}, {name: position, var: position}, {name: product_id, var: product_id}, {name: product_variant_id, var: product_variant_id}, {name: store_id, var: store_id}, {name: type, var: type}, {name: url, var: url}, {name: variant_ids, var: variant_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    content: $content, image_name: $image_name, label: $label, lang_id: $lang_id, mime: $mime, position: $position, product_id: $product_id, product_variant_id: $product_variant_id, store_id: $store_id, type: $type, url: $url, variant_ids: $variant_ids
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete image
#
# DELETE /product.image.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: ProductImageDelete
export def "product-image-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the image should be deleted (required)
  --id: string # Entity id (required)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/product.image.delete.json"
    query: [{name: product_id, var: product_id, required: true}, {name: id, var: id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, id: $id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update details of image
#
# PUT /product.image.update.json
# Returns: record<result: record<updated: string>, return_code: int, return_message: string>
# operationId: ProductImageUpdate
export def "product-image-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the image should be updated (required)
  --image-name: string # Defines image's name
  --type: string # Defines image's types that are specified by comma-separated list (default: additional)
  --label: string # Defines alternative text that has to be attached to the picture
  --position: int # Defines image’s position in the list
  --id: string # Defines image update specified by image id (required)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --hidden: oneof<nothing, bool> # Define is hide image
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/product.image.update.json"
    query: [{name: product_id, var: product_id, required: true}, {name: image_name, var: image_name}, {name: type, var: type}, {name: label, var: label}, {name: position, var: position}, {name: id, var: id, required: true}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: hidden, var: hidden}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, image_name: $image_name, type: $type, label: $label, position: $position, id: $id, store_id: $store_id, lang_id: $lang_id, hidden: $hidden
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get product info about product ID *** or specify other product ID.
#
# GET /product.info.json
# Returns: record<result: record<additional_fields: record, advanced_price: list<record>, avail_sale: bool, avail_view: bool, backorders: string, categories_ids: list<string>, cost_price: float, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, dimensions_unit: string, group_items: list<record>, group_price: list<record>, height: float, id: string, images: list<record>, inventory: list<record>, is_downloadable: bool, is_stock_managed: bool, is_virtual: bool, length: float, manage_stock: string, meta_description: string, meta_keywords: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, price: float, product_options: list<record>, quantity: float, related_products_ids: list<string>, seo_url: string, short_description: string, sort_order: int, special_price: record<additional_fields: record, avail: bool, created_at: record, custom_fields: record, expired_at: record, modified_at: record, value: float>, stores_ids: list<string>, tax_class_id: string, tier_price: list<record>, type: string, u_brand: string, u_brand_id: string, u_model: string, u_mpn: string, u_sku: string, u_upc: string, url: string, weight: float, weight_unit: string, width: float>, return_code: int, return_message: string>
# operationId: ProductInfo
export def "product-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Retrieves product's info specified by product id (required)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description,price,categories_ids)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Retrieves product info specified by store id
  --lang-id: string # Retrieves product info specified by language id
  --currency-id: string # Currency Id
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.info.json"
    query: [{name: id, var: id, required: true}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: currency_id, var: currency_id}, {name: report_request_id, var: report_request_id}, {name: disable_report_cache, var: disable_report_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, params: $params, response_fields: $response_fields, exclude: $exclude, store_id: $store_id, lang_id: $lang_id, currency_id: $currency_id, report_request_id: $report_request_id, disable_report_cache: $disable_report_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of products from your store. Returns 10 products by default.
#
# GET /product.list.json
# Returns: record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, product: list<record>, products_count: int>, return_code: int, return_message: string>
# operationId: ProductList
export def "product-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve products via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description,price,categories_ids)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --category-id: string # Retrieves products specified by category id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --avail-view: oneof<nothing, bool> # Specifies the set of visible/invisible products
  --avail-sale: oneof<nothing, bool> # Specifies the set of available/not available products for sale
  --store-id: string # Retrieves products specified by store id
  --lang-id: string # Retrieves products specified by language id
  --currency-id: string # Currency Id
  --product-ids: string # Retrieves products specified by product ids
  --since-id: int # Retrieve entities starting from the specified id.
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
  --sort-by: string # Set field to sort by (default: id)
  --sort-direction: string # Set sorting direction (default: asc)
  --sku: string # Filter by product's sku
  --disable-cache: oneof<nothing, bool> # Disable cache for current request (default: false)
  --brand-name: string # Retrieves brands specified by brand name
  --product-attributes: list<string> # Defines product attributes
  --status: string # Defines product's status
  --type: string # Defines products's type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.list.json"
    query: [{name: page_cursor, var: page_cursor}, {name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}, {name: category_id, var: category_id}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: avail_view, var: avail_view}, {name: avail_sale, var: avail_sale}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: currency_id, var: currency_id}, {name: product_ids, var: product_ids}, {name: since_id, var: since_id}, {name: report_request_id, var: report_request_id}, {name: disable_report_cache, var: disable_report_cache}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: sku, var: sku}, {name: disable_cache, var: disable_cache}, {name: brand_name, var: brand_name}, {name: product_attributes, var: product_attributes, style: csv}, {name: status, var: status}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    page_cursor: $page_cursor, start: $start, count: $count, params: $params, response_fields: $response_fields, exclude: $exclude, category_id: $category_id, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, avail_view: $avail_view, avail_sale: $avail_sale, store_id: $store_id, lang_id: $lang_id, currency_id: $currency_id, product_ids: $product_ids, since_id: $since_id, report_request_id: $report_request_id, disable_report_cache: $disable_report_cache, sort_by: $sort_by, sort_direction: $sort_direction, sku: $sku, disable_cache: $disable_cache, brand_name: $brand_name, product_attributes: $product_attributes, status: $status, type: $type
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add manufacturer to store and assign to product
#
# POST /product.manufacturer.add.json
# Returns: record<result: record<manufacturer_id: string>, return_code: int, return_message: string>
# operationId: ProductManufacturerAdd
export def "product-manufacturer-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines products specified by product id (required)
  --manufacturer: string # Defines product’s manufacturer's name (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.manufacturer.add.json"
    query: [{name: product_id, var: product_id, required: true}, {name: manufacturer, var: manufacturer, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, manufacturer: $manufacturer
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add product option from store.
#
# POST /product.option.add.json
# Returns: record<result: record<option_id: string, product_option_id: string>, return_code: int, return_message: string>
# operationId: ProductOptionAdd
export def "product-option-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Defines option's name (required)
  --type: string@type-completer-3 # Defines option's type that has to be added (required)
  --product-id: string # Defines product id where the option should be added
  --default-option-value: string # Defines default option value that has to be added
  --option-values: string # Defines option values that has to be added
  --description: string # Defines option's description
  --avail: oneof<nothing, bool> # Defines whether the option is available (default: true)
  --sort-order: int # Sort number in the list (default: 0)
  --required: oneof<nothing, bool> # Defines if the option is required (default: false)
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.option.add.json"
    query: [{name: name, var: name, required: true}, {name: type, var: type, required: true}, {name: product_id, var: product_id}, {name: default_option_value, var: default_option_value}, {name: option_values, var: option_values}, {name: description, var: description}, {name: avail, var: avail}, {name: sort_order, var: sort_order}, {name: required, var: required}, {name: clear_cache, var: clear_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    name: $name, type: $type, product_id: $product_id, default_option_value: $default_option_value, option_values: $option_values, description: $description, avail: $avail, sort_order: $sort_order, required: $required, clear_cache: $clear_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign option from product.
#
# POST /product.option.assign.json
# Returns: record<result: record<product_option_id: string>, return_code: int, return_message: string>
# operationId: ProductOptionAssign
export def "product-option-assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the option should be assigned (required)
  --option-id: string # Defines option id which has to be assigned (required)
  --required: oneof<nothing, bool> # Defines if the option is required (default: false)
  --sort-order: int # Sort number in the list (default: 0)
  --option-values: string # Defines option values that has to be assigned
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.option.assign.json"
    query: [{name: product_id, var: product_id, required: true}, {name: option_id, var: option_id, required: true}, {name: required, var: required}, {name: sort_order, var: sort_order}, {name: option_values, var: option_values}, {name: clear_cache, var: clear_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, option_id: $option_id, required: $required, sort_order: $sort_order, option_values: $option_values, clear_cache: $clear_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of options.
#
# GET /product.option.list.json
# Returns: record<result: record<option: list<record>>, return_code: int, return_message: string>
# operationId: ProductOptionList
export def "product-option-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --product-id: string # Retrieves products' options specified by product id
  --lang-id: string # Language id
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.option.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}, {name: product_id, var: product_id}, {name: lang_id, var: lang_id}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, params: $params, exclude: $exclude, response_fields: $response_fields, product_id: $product_id, lang_id: $lang_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add product option item from option.
#
# POST /product.option.value.add.json
# Returns: record<result: record<option_value_id: string>, return_code: int, return_message: string>
# operationId: ProductOptionValueAdd
export def "product-option-value-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the option value should be added (required)
  --option-id: string # Defines option id where the value has to be added (required)
  --option-value: string # Defines option value that has to be added (required)
  --sort-order: int # Sort number in the list (default: 0)
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.option.value.add.json"
    query: [{name: product_id, var: product_id, required: true}, {name: option_id, var: option_id, required: true}, {name: option_value, var: option_value, required: true}, {name: sort_order, var: sort_order}, {name: clear_cache, var: clear_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, option_id: $option_id, option_value: $option_value, sort_order: $sort_order, clear_cache: $clear_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign product option item from product.
#
# POST /product.option.value.assign.json
# Returns: record<result: record<product_option_value_id: string>, return_code: int, return_message: string>
# operationId: ProductOptionValueAssign
export def "product-option-value-assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-option-id: int # Defines product's option id where the value has to be assigned (required)
  --option-value-id: int # Defines value id that has to be assigned (required)
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.option.value.assign.json"
    query: [{name: product_option_id, var: product_option_id, required: true}, {name: option_value_id, var: option_value_id, required: true}, {name: clear_cache, var: clear_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_option_id: $product_option_id, option_value_id: $option_value_id, clear_cache: $clear_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update product option item from option.
#
# PUT /product.option.value.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: ProductOptionValueUpdate
export def "product-option-value-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the option value should be updated (required)
  --option-id: string # Defines option id where the value has to be updated (required)
  --option-value-id: int # Defines value id that has to be assigned (required)
  --option-value: string # Defines option value that has to be added (required)
  --price: float # Defines new product option price
  --quantity: float # Defines new products' options quantity
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/product.option.value.update.json"
    query: [{name: product_id, var: product_id, required: true}, {name: option_id, var: option_id, required: true}, {name: option_value_id, var: option_value_id, required: true}, {name: option_value, var: option_value, required: true}, {name: price, var: price}, {name: quantity, var: quantity}, {name: clear_cache, var: clear_cache}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, option_id: $option_id, option_value_id: $option_value_id, option_value: $option_value, price: $price, quantity: $quantity, clear_cache: $clear_cache
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add some prices to the product.
#
# POST /product.price.add.json
# Returns: record<result: record<status: string>, return_code: int, return_message: string>
# operationId: ProductPriceAdd
export def "product-price-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-prices: list # Defines product's group prices — item shape: {group_id?: string, price?: float}
  --product-id: string # Defines the product to which the price has to be added
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product.price.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: group_prices, var: group_prices}, {name: product_id, var: product_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    group_prices: $group_prices, product_id: $product_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete some prices of the product
#
# DELETE /product.price.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: ProductPriceDelete
export def "product-price-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines the product where the price has to be deleted (required)
  --group-prices: string # Defines product's group prices
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/product.price.delete.json"
    query: [{name: product_id, var: product_id, required: true}, {name: group_prices, var: group_prices}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, group_prices: $group_prices
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update some prices of the product.
#
# PUT /product.price.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: ProductPriceUpdate
export def "product-price-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-prices: list # Defines product's group prices — item shape: {group_id?: string, id?: int, price?: float}
  --product-id: string # Defines the product where the price has to be updated
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/product.price.update.json"
    body: {content_type: "application/json", kind: json, fields: [{name: group_prices, var: group_prices}, {name: product_id, var: product_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    group_prices: $group_prices, product_id: $product_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get reviews of a specific product.
#
# GET /product.review.list.json
# Returns: record<result: record<reviews: list<record>, total_count: int>, return_code: int, return_message: string>
# operationId: ProductReviewList
export def "product-review-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --product-id: string # Product id (required)
  --ids: string # Retrieves reviews specified by ids
  --store-id: string # Store Id
  --status: string # Defines status
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,customer_id,email,message,status,product_id,nick_name,summary,rating,ratings,status,created_time)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.review.list.json"
    query: [{name: start, var: start}, {name: page_cursor, var: page_cursor}, {name: count, var: count}, {name: product_id, var: product_id, required: true}, {name: ids, var: ids}, {name: store_id, var: store_id}, {name: status, var: status}, {name: params, var: params}, {name: exclude, var: exclude}, {name: response_fields, var: response_fields}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, page_cursor: $page_cursor, count: $count, product_id: $product_id, ids: $ids, store_id: $store_id, status: $status, params: $params, exclude: $exclude, response_fields: $response_fields
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign product to store
#
# POST /product.store.assign.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: ProductStoreAssign
export def "product-store-assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines id of the product which should be assigned to a store (required)
  --store-id: string # Defines id of the store product should be assigned to (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/product.store.assign.json"
    query: [{name: product_id, var: product_id, required: true}, {name: store_id, var: store_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add tax class and tax rate to store and assign to product.
#
# POST /product.tax.add.json
# Returns: record<result: record<tax_class_id: string>, return_code: int, return_message: string>
# operationId: ProductTaxAdd
export def "product-tax-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Defines tax class name where tax has to be added
  --product-id: string # Defines products specified by product id
  tax_rates: list # Defines tax rates of specified tax classes — item shape: {name?: string, type?: string, value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product.tax.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: product_id, var: product_id}, {name: tax_rates, var: tax_rates}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    name: $name, product_id: $product_id, tax_rates: $tax_rates
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update price and quantity for a specific product
#
# PUT /product.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: ProductUpdate
export def "product-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines product id that has to be updated (required)
  --model: string # Defines product model that has to be updated
  --old-price: float # Defines product's old price
  --price: float # Defines new product's price
  --special-price: float # Defines new product's special price
  --sprice-create: string # Defines the date of special price creation
  --sprice-expire: string # Defines the term of special price offer duration
  --cost-price: float # Defines new product's cost price
  --retail-price: float # Defines new product's retail price
  --quantity: float # Defines new product's quantity
  --weight: float # Weight
  --increase-quantity: float # Defines the incremental changes in product quantity
  --reduce-quantity: float # Defines the decrement changes in product quantity
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
  --reserve-quantity: float # This parameter allows to reserve/unreserve product quantity.
  --manage-stock: oneof<nothing, bool> # Defines inventory tracking for product
  --backorder-status: string # Set backorder status
  --name: string # Defines product's name that has to be updated
  --sku: string # Defines new product's sku
  --visible: string # Set visibility status
  --manufacturer: string # Defines product's manufacturer
  --manufacturer-id: string # Defines product's manufacturer by manufacturer_id
  --categories-ids: string # Defines product add that is specified by comma-separated categories id
  --description: string # Defines new product's description
  --short-description: string # Defines short description
  --meta-title: string # Defines unique meta title for each entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --meta-description: string # Defines unique meta description of a entity
  --store-id: string # Defines store id where the product should be found
  --lang-id: string # Language id
  --in-stock: oneof<nothing, bool> # Set stock status
  --status: string # Defines product's status
  --seo-url: string # Defines unique URL for SEO
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
  --reindex: oneof<nothing, bool> # Is reindex required (default: true)
  --tags: string # Product tags
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --gtin: string # Global Trade Item Number. An GTIN is an identifier for trade items.
  --taxable: oneof<nothing, bool> # Specifies whether a tax is charged (default: true)
  --product-class: string # A categorization for the product
  --height: float # Defines product's height
  --length: float # Defines product's length
  --width: float # Defines product's width
  --harmonized-system-code: string # Harmonized System Code. An HSC is a 6-digit identifier that allows participating countries to classify traded goods on a common basis for customs purposes
  --country-of-origin: string # The country where the inventory item was made
  --search-keywords: string # Defines unique search keywords
  --barcode: string # A barcode is a unique code composed of numbers used as a product identifier.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/product.update.json"
    query: [{name: id, var: id, required: true}, {name: model, var: model}, {name: old_price, var: old_price}, {name: price, var: price}, {name: special_price, var: special_price}, {name: sprice_create, var: sprice_create}, {name: sprice_expire, var: sprice_expire}, {name: cost_price, var: cost_price}, {name: retail_price, var: retail_price}, {name: quantity, var: quantity}, {name: weight, var: weight}, {name: increase_quantity, var: increase_quantity}, {name: reduce_quantity, var: reduce_quantity}, {name: warehouse_id, var: warehouse_id}, {name: reserve_quantity, var: reserve_quantity}, {name: manage_stock, var: manage_stock}, {name: backorder_status, var: backorder_status}, {name: name, var: name}, {name: sku, var: sku}, {name: visible, var: visible}, {name: manufacturer, var: manufacturer}, {name: manufacturer_id, var: manufacturer_id}, {name: categories_ids, var: categories_ids}, {name: description, var: description}, {name: short_description, var: short_description}, {name: meta_title, var: meta_title}, {name: meta_keywords, var: meta_keywords}, {name: meta_description, var: meta_description}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: in_stock, var: in_stock}, {name: status, var: status}, {name: seo_url, var: seo_url}, {name: report_request_id, var: report_request_id}, {name: disable_report_cache, var: disable_report_cache}, {name: reindex, var: reindex}, {name: tags, var: tags}, {name: clear_cache, var: clear_cache}, {name: gtin, var: gtin}, {name: taxable, var: taxable}, {name: product_class, var: product_class}, {name: height, var: height}, {name: length, var: length}, {name: width, var: width}, {name: harmonized_system_code, var: harmonized_system_code}, {name: country_of_origin, var: country_of_origin}, {name: search_keywords, var: search_keywords}, {name: barcode, var: barcode}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, model: $model, old_price: $old_price, price: $price, special_price: $special_price, sprice_create: $sprice_create, sprice_expire: $sprice_expire, cost_price: $cost_price, retail_price: $retail_price, quantity: $quantity, weight: $weight, increase_quantity: $increase_quantity, reduce_quantity: $reduce_quantity, warehouse_id: $warehouse_id, reserve_quantity: $reserve_quantity, manage_stock: $manage_stock, backorder_status: $backorder_status, name: $name, sku: $sku, visible: $visible, manufacturer: $manufacturer, manufacturer_id: $manufacturer_id, categories_ids: $categories_ids, description: $description, short_description: $short_description, meta_title: $meta_title, meta_keywords: $meta_keywords, meta_description: $meta_description, store_id: $store_id, lang_id: $lang_id, in_stock: $in_stock, status: $status, seo_url: $seo_url, report_request_id: $report_request_id, disable_report_cache: $disable_report_cache, reindex: $reindex, tags: $tags, clear_cache: $clear_cache, gtin: $gtin, taxable: $taxable, product_class: $product_class, height: $height, length: $length, width: $width, harmonized_system_code: $harmonized_system_code, country_of_origin: $country_of_origin, search_keywords: $search_keywords, barcode: $barcode
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add variant to product.
#
# POST /product.variant.add.json
# Returns: record<result: record<product_variant_id: string>, return_code: int, return_message: string>
# operationId: ProductVariantAdd
export def "product-variant-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Defines variant's attributes list — item shape: {attribute_name?: string, attribute_price?: float, attribute_value?: string}
  --available-for-sale: oneof<nothing, bool> # Specifies the set of visible/invisible product's variants for sale (default: true)
  --available-for-view: oneof<nothing, bool> # Specifies the set of visible/invisible product's variants for users (default: true)
  --barcode: string # A barcode is a unique code composed of numbers used as a product identifier.
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --cost-price: float # Defines new product's cost price
  --country-of-origin: string # The country where the inventory item was made
  --created-at: string # Defines the date of entity creation
  --description: string # Specifies variant's description
  --harmonized-system-code: string # Harmonized System Code. An HSC is a 6-digit identifier that allows participating countries to classify traded goods on a common basis for customs purposes
  --height: float # Defines product's height
  --lang-id: string # Language id
  --length: float # Defines product's length
  --manage-stock: oneof<nothing, bool> # Defines inventory tracking for product variant
  --manufacturer: string # Specifies the product variant's manufacturer
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --meta-title: string # Defines unique meta title for each entity
  model: string # Specifies variant's model that has to be added
  --name: string # Defines variant's name that has to be added
  --price: float # Defines new product's variant price
  --product-id: string # Defines product's id where the variant has to be added
  --quantity: float # Defines product variant's quantity that has to be added (default: 0)
  --short-description: string # Defines short description
  --sku: string # Defines variant's sku that has to be added
  --special-price: float # Specifies variant's model that has to be added
  --sprice-create: string # Defines the date of special price creation
  --sprice-expire: string # Defines the term of special price offer duration
  --sprice-modified: string # Defines the date of special price modification
  --store-id: string # Add variants specified by store id
  --tax-class-id: int # Defines tax classes where entity has to be added
  --taxable: oneof<nothing, bool> # Specifies whether a tax is charged (default: true)
  --url: string # Defines unique product variant's URL
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
  --weight: float # Weight (default: 0)
  --weight-unit: string # Weight Unit
  --width: float # Defines product's width
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product.variant.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: available_for_sale, var: available_for_sale}, {name: available_for_view, var: available_for_view}, {name: barcode, var: barcode}, {name: clear_cache, var: clear_cache}, {name: cost_price, var: cost_price}, {name: country_of_origin, var: country_of_origin}, {name: created_at, var: created_at}, {name: description, var: description}, {name: harmonized_system_code, var: harmonized_system_code}, {name: height, var: height}, {name: lang_id, var: lang_id}, {name: length, var: length}, {name: manage_stock, var: manage_stock}, {name: manufacturer, var: manufacturer}, {name: meta_description, var: meta_description}, {name: meta_keywords, var: meta_keywords}, {name: meta_title, var: meta_title}, {name: model, var: model}, {name: name, var: name}, {name: price, var: price}, {name: product_id, var: product_id}, {name: quantity, var: quantity}, {name: short_description, var: short_description}, {name: sku, var: sku}, {name: special_price, var: special_price}, {name: sprice_create, var: sprice_create}, {name: sprice_expire, var: sprice_expire}, {name: sprice_modified, var: sprice_modified}, {name: store_id, var: store_id}, {name: tax_class_id, var: tax_class_id}, {name: taxable, var: taxable}, {name: url, var: url}, {name: warehouse_id, var: warehouse_id}, {name: weight, var: weight}, {name: weight_unit, var: weight_unit}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    attributes: $attributes, available_for_sale: $available_for_sale, available_for_view: $available_for_view, barcode: $barcode, clear_cache: $clear_cache, cost_price: $cost_price, country_of_origin: $country_of_origin, created_at: $created_at, description: $description, harmonized_system_code: $harmonized_system_code, height: $height, lang_id: $lang_id, length: $length, manage_stock: $manage_stock, manufacturer: $manufacturer, meta_description: $meta_description, meta_keywords: $meta_keywords, meta_title: $meta_title, model: $model, name: $name, price: $price, product_id: $product_id, quantity: $quantity, short_description: $short_description, sku: $sku, special_price: $special_price, sprice_create: $sprice_create, sprice_expire: $sprice_expire, sprice_modified: $sprice_modified, store_id: $store_id, tax_class_id: $tax_class_id, taxable: $taxable, url: $url, warehouse_id: $warehouse_id, weight: $weight, weight_unit: $weight_unit, width: $width
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get count variants.
#
# GET /product.variant.count.json
# Returns: record<result: record<variants_count: string>, return_code: int, return_message: string>
# operationId: ProductVariantCount
export def "product-variant-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --category-id: string # Counts products’ variants specified by category id
  --product-id: string # Retrieves products' variants specified by product id (required)
  --store-id: string # Retrieves variants specified by store id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.variant.count.json"
    query: [{name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: category_id, var: category_id}, {name: product_id, var: product_id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, category_id: $category_id, product_id: $product_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete variant.
#
# DELETE /product.variant.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: ProductVariantDelete
export def "product-variant-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines variant removal, specified by variant id (required)
  --product-id: string # Defines product's id where the variant has to be deleted (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/product.variant.delete.json"
    query: [{name: id, var: id, required: true}, {name: product_id, var: product_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, product_id: $product_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add image to product
#
# POST /product.variant.image.add.json
# Returns: record<result: record<id: string, image_path: string>, return_code: int, return_message: string>
# operationId: ProductVariantImageAdd
export def "product-variant-image-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # Content(body) encoded in base64 of image file
  image_name: string # Defines image's name
  --label: string # Defines alternative text that has to be attached to the picture
  --mime: string # Mime type of image http://en.wikipedia.org/wiki/Internet_media_type.
  --option-id: string # Defines option id of the product variant for which the image will be added
  --position: int # Defines image’s position in the list (default: 0)
  --product-id: string # Defines product id where the variant image has to be added
  product_variant_id: int # Defines product's variants specified by variant id
  --store-id: string # Store Id
  type: string@type-completer-2 # Defines image's types that are specified by comma-separated list (default: base)
  --url: string # Defines URL of the image that has to be added
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product.variant.image.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: image_name, var: image_name}, {name: label, var: label}, {name: mime, var: mime}, {name: option_id, var: option_id}, {name: position, var: position}, {name: product_id, var: product_id}, {name: product_variant_id, var: product_variant_id}, {name: store_id, var: store_id}, {name: type, var: type}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    content: $content, image_name: $image_name, label: $label, mime: $mime, option_id: $option_id, position: $position, product_id: $product_id, product_variant_id: $product_variant_id, store_id: $store_id, type: $type, url: $url
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete image to product
#
# DELETE /product.variant.image.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: ProductVariantImageDelete
export def "product-variant-image-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the variant image should be deleted (required)
  --product-variant-id: int # Defines product's variants specified by variant id (required)
  --id: string # Entity id (required)
  --store-id: string # Store Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/product.variant.image.delete.json"
    query: [{name: product_id, var: product_id, required: true}, {name: product_variant_id, var: product_variant_id, required: true}, {name: id, var: id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    product_id: $product_id, product_variant_id: $product_variant_id, id: $id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get variant info.
#
# GET /product.variant.info.json
# Returns: record<result: record<additional_fields: record, advanced_price: list<record>, avail_sale: bool, avail_view: bool, backorders: string, categories_ids: list<string>, cost_price: float, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, dimensions_unit: string, group_items: list<record>, group_price: list<record>, height: float, id: string, images: list<record>, inventory: list<record>, is_downloadable: bool, is_stock_managed: bool, is_virtual: bool, length: float, manage_stock: string, meta_description: string, meta_keywords: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, price: float, product_options: list<record>, quantity: float, related_products_ids: list<string>, seo_url: string, short_description: string, sort_order: int, special_price: record<additional_fields: record, avail: bool, created_at: record, custom_fields: record, expired_at: record, modified_at: record, value: float>, stores_ids: list<string>, tax_class_id: string, tier_price: list<record>, type: string, u_brand: string, u_brand_id: string, u_model: string, u_mpn: string, u_sku: string, u_upc: string, url: string, weight: float, weight_unit: string, width: float>, return_code: int, return_message: string>
# operationId: ProductVariantInfo
export def "product-variant-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description,price)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --id: string # Retrieves variant's info specified by variant id (required)
  --store-id: string # Retrieves variant info specified by store id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.variant.info.json"
    query: [{name: params, var: params}, {name: exclude, var: exclude}, {name: id, var: id, required: true}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    params: $params, exclude: $exclude, id: $id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list variants.
#
# GET /product.variant.list.json
# Returns: record<result: record<variant: list<record>>, return_code: int, return_message: string>
# operationId: ProductVariantList
export def "product-variant-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description,price)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --category-id: string # Retrieves products’ variants specified by category id
  --product-id: string # Retrieves products' variants specified by product id
  --store-id: string # Retrieves variants specified by store id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product.variant.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: params, var: params}, {name: exclude, var: exclude}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: category_id, var: category_id}, {name: product_id, var: product_id}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, params: $params, exclude: $exclude, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, category_id: $category_id, product_id: $product_id, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add some prices to the product variant.
#
# POST /product.variant.price.add.json
# Returns: record<result: record<status: string>, return_code: int, return_message: string>
# operationId: ProductVariantPriceAdd
export def "product-variant-price-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-prices: list # Defines variants's group prices — item shape: {group_id?: string, price?: float}
  --id: string # Defines the variant to which the price has to be added
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product.variant.price.add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: group_prices, var: group_prices}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    group_prices: $group_prices, id: $id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete some prices of the product variant.
#
# DELETE /product.variant.price.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: ProductVariantPriceDelete
export def "product-variant-price-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines the variant where the price has to be deleted (required)
  --group-prices: string # Defines variants's group prices
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/product.variant.price.delete.json"
    query: [{name: id, var: id, required: true}, {name: group_prices, var: group_prices}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, group_prices: $group_prices
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update some prices of the product variant.
#
# PUT /product.variant.price.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: ProductVariantPriceUpdate
export def "product-variant-price-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-prices: list # Defines variants's group prices — item shape: {group_id?: string, id?: int, price?: float}
  --id: string # Defines the variant where the price has to be updated
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/product.variant.price.update.json"
    body: {content_type: "application/json", kind: json, fields: [{name: group_prices, var: group_prices}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    group_prices: $group_prices, id: $id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update variant.
#
# PUT /product.variant.update.json
# Returns: record<result: record<updated_items: int>, return_code: int, return_message: string>
# operationId: ProductVariantUpdate
export def "product-variant-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Defines store id where the variant should be found
  --id: string # Defines variant update specified by variant id (required)
  --product-id: string # Defines product's id where the variant has to be updated (required)
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
  --reserve-quantity: float # This parameter allows to reserve/unreserve product variants quantity.
  --quantity: float # Defines new products' variants quantity
  --increase-quantity: float # Defines the incremental changes in product quantity (default: 0)
  --reduce-quantity: float # Defines the decrement changes in product quantity (default: 0)
  --price: float # Defines new product's variant price
  --special-price: float # Defines new product's variant special price
  --retail-price: float # Defines new product's retail price
  --old-price: float # Defines product's old price
  --cost-price: float # Defines new product's cost price
  --sprice-create: string # Defines the date of special price creation
  --sprice-expire: string # Defines the term of special price offer duration
  --manage-stock: oneof<nothing, bool> # Defines inventory tracking for product variant
  --in-stock: oneof<nothing, bool> # Set stock status
  --name: string # Defines variant's name that has to be updated
  --description: string # Specifies variant's description
  --sku: string # Defines new product's variant sku
  --meta-title: string # Defines unique meta title for each entity
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --short-description: string # Defines short description
  --visible: string # Set visibility status
  --status: string # Defines product variant's status
  --backorder-status: string # Set backorder status
  --weight: float # Weight (default: 0)
  --barcode: string # A barcode is a unique code composed of numbers used as a product identifier.
  --reindex: oneof<nothing, bool> # Is reindex required (default: true)
  --taxable: oneof<nothing, bool> # Specifies whether a tax is charged (default: true)
  --options: list<string> # Defines variant's options list
  --harmonized-system-code: string # Harmonized System Code. An HSC is a 6-digit identifier that allows participating countries to classify traded goods on a common basis for customs purposes
  --country-of-origin: string # The country where the inventory item was made
  --width: float # Defines product's width
  --height: float # Defines product's height
  --length: float # Defines product's length
  --gtin: string # Global Trade Item Number. An GTIN is an identifier for trade items.
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --lang-id: string # Language id
  --model: string # Specifies variant's model that has to be added
  --available-for-sale: oneof<nothing, bool> # Specifies the set of visible/invisible product's variants for sale (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/product.variant.update.json"
    query: [{name: store_id, var: store_id}, {name: id, var: id, required: true}, {name: product_id, var: product_id, required: true}, {name: warehouse_id, var: warehouse_id}, {name: reserve_quantity, var: reserve_quantity}, {name: quantity, var: quantity}, {name: increase_quantity, var: increase_quantity}, {name: reduce_quantity, var: reduce_quantity}, {name: price, var: price}, {name: special_price, var: special_price}, {name: retail_price, var: retail_price}, {name: old_price, var: old_price}, {name: cost_price, var: cost_price}, {name: sprice_create, var: sprice_create}, {name: sprice_expire, var: sprice_expire}, {name: manage_stock, var: manage_stock}, {name: in_stock, var: in_stock}, {name: name, var: name}, {name: description, var: description}, {name: sku, var: sku}, {name: meta_title, var: meta_title}, {name: meta_description, var: meta_description}, {name: meta_keywords, var: meta_keywords}, {name: short_description, var: short_description}, {name: visible, var: visible}, {name: status, var: status}, {name: backorder_status, var: backorder_status}, {name: weight, var: weight}, {name: barcode, var: barcode}, {name: reindex, var: reindex}, {name: taxable, var: taxable}, {name: options, var: options, style: csv}, {name: harmonized_system_code, var: harmonized_system_code}, {name: country_of_origin, var: country_of_origin}, {name: width, var: width}, {name: height, var: height}, {name: length, var: length}, {name: gtin, var: gtin}, {name: clear_cache, var: clear_cache}, {name: lang_id, var: lang_id}, {name: model, var: model}, {name: available_for_sale, var: available_for_sale}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    store_id: $store_id, id: $id, product_id: $product_id, warehouse_id: $warehouse_id, reserve_quantity: $reserve_quantity, quantity: $quantity, increase_quantity: $increase_quantity, reduce_quantity: $reduce_quantity, price: $price, special_price: $special_price, retail_price: $retail_price, old_price: $old_price, cost_price: $cost_price, sprice_create: $sprice_create, sprice_expire: $sprice_expire, manage_stock: $manage_stock, in_stock: $in_stock, name: $name, description: $description, sku: $sku, meta_title: $meta_title, meta_description: $meta_description, meta_keywords: $meta_keywords, short_description: $short_description, visible: $visible, status: $status, backorder_status: $backorder_status, weight: $weight, barcode: $barcode, reindex: $reindex, taxable: $taxable, options: $options, harmonized_system_code: $harmonized_system_code, country_of_origin: $country_of_origin, width: $width, height: $height, length: $length, gtin: $gtin, clear_cache: $clear_cache, lang_id: $lang_id, model: $model, available_for_sale: $available_for_sale
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subscribers list
#
# GET /subscriber.list.json
# Returns: record<result: record<subscribers: list<record>, total_count: int>, return_code: int, return_message: string>
# operationId: SubscriberList
export def "subscriber-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --subscribed: oneof<nothing, bool> # Filter by subscription status
  --store-id: string # Store Id
  --email: string # Filter subscribers by email
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriber.list.json"
    query: [{name: start, var: start}, {name: count, var: count}, {name: subscribed, var: subscribed}, {name: store_id, var: store_id}, {name: email, var: email}, {name: params, var: params}, {name: exclude, var: exclude}, {name: created_from, var: created_from}, {name: created_to, var: created_to}, {name: modified_from, var: modified_from}, {name: modified_to, var: modified_to}, {name: page_cursor, var: page_cursor}, {name: response_fields, var: response_fields}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    start: $start, count: $count, subscribed: $subscribed, store_id: $store_id, email: $email, params: $params, exclude: $exclude, created_from: $created_from, created_to: $created_to, modified_from: $modified_from, modified_to: $modified_to, page_cursor: $page_cursor, response_fields: $response_fields
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get info about tax
#
# GET /tax.class.info.json
# Returns: record<result: record<additional_fields: record, avail: bool, custom_fields: record, id: string, name: string, tax: float, tax_rates: list<record>, tax_type: int>, return_code: int, return_message: string>
# operationId: TaxClassInfo
export def "tax-class-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tax-class-id: string # Retrieves taxes specified by class id (required)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: tax_class_id,name,avail)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tax.class.info.json"
    query: [{name: tax_class_id, var: tax_class_id, required: true}, {name: store_id, var: store_id}, {name: lang_id, var: lang_id}, {name: params, var: params}, {name: response_fields, var: response_fields}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    tax_class_id: $tax_class_id, store_id: $store_id, lang_id: $lang_id, params: $params, response_fields: $response_fields, exclude: $exclude
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count registered webhooks on the store.
#
# GET /webhook.count.json
# Returns: record<result: record<webhook_count: int>, return_code: int, return_message: string>
# operationId: WebhookCount
export def "webhook-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity: string # The entity you want to filter webhooks by (e.g. order or product)
  --action: string # The action you want to filter webhooks by (e.g. order or product)
  --active: oneof<nothing, bool> # The webhook status you want to filter webhooks by
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhook.count.json"
    query: [{name: entity, var: entity}, {name: action, var: action}, {name: active, var: active}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    entity: $entity, action: $action, active: $active
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create webhook on the store and subscribe to it.
#
# POST /webhook.create.json
# Returns: record<result: record<id: string>, return_code: int, return_message: string>
# operationId: WebhookCreate
export def "webhook-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity: string # Specify the entity that you want to enable webhooks for (e.g product, order, customer, category) (required)
  --action: string # Specify what action (event) will trigger the webhook (e.g add, delete, or update) (required)
  --callback: string # Callback url that returns shipping rates. It should be able to accept POST requests with json data.
  --label: string # The name you give to the webhook
  --fields: string # Fields the webhook should send (default: force_all)
  --active: oneof<nothing, bool> # Webhook status (default: true)
  --store-id: string # Defines store id where the webhook should be assigned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/webhook.create.json"
    query: [{name: entity, var: entity, required: true}, {name: action, var: action, required: true}, {name: callback, var: callback}, {name: label, var: label}, {name: fields, var: fields}, {name: active, var: active}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    entity: $entity, action: $action, callback: $callback, label: $label, fields: $fields, active: $active, store_id: $store_id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete registered webhook on the store.
#
# DELETE /webhook.delete.json
# Returns: record<result: record<deleted: string>, return_code: int, return_message: string>
# operationId: WebhookDelete
export def "webhook-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Webhook id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhook.delete.json"
    query: [{name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Webhooks that are available on this store.
#
# GET /webhook.events.json
# Returns: record<result: record<events: list<record>>, return_code: int, return_message: string>
# operationId: WebhookEvents
export def "webhook-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhook.events.json"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List registered webhook on the store.
#
# GET /webhook.list.json
# Returns: record<result: record<webhook: list<record>>, return_code: int, return_message: string>
# operationId: WebhookList
export def "webhook-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,entity,action,callback)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --entity: string # The entity you want to filter webhooks by (e.g. order or product)
  --action: string # The action you want to filter webhooks by (e.g. add, update, or delete)
  --active: oneof<nothing, bool> # The webhook status you want to filter webhooks by
  --ids: string # List of сomma-separated webhook ids
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhook.list.json"
    query: [{name: params, var: params}, {name: start, var: start}, {name: count, var: count}, {name: entity, var: entity}, {name: action, var: action}, {name: active, var: active}, {name: ids, var: ids}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    params: $params, start: $start, count: $count, entity: $entity, action: $action, active: $active, ids: $ids
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Webhooks parameters.
#
# PUT /webhook.update.json
# Returns: record<result: record<updated: string>, return_code: int, return_message: string>
# operationId: WebhookUpdate
export def "webhook-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api_key (x-api-key)
  --token-storekey: string # Auth token for store_key (x-store-key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Webhook id (required)
  --callback: string # Callback url that returns shipping rates. It should be able to accept POST requests with json data.
  --label: string # The name you give to the webhook
  --fields: string # Fields the webhook should send
  --active: oneof<nothing, bool> # Webhook status
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/webhook.update.json"
    query: [{name: id, var: id, required: true}, {name: callback, var: callback}, {name: label, var: label}, {name: fields, var: fields}, {name: active, var: active}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-api-key, var: token_apikey, env: SWAGGER_API2CART_APIKEY_TOKEN}, {scheme: x-store-key, var: token_storekey, env: SWAGGER_API2CART_STOREKEY_TOKEN}]
  } {
    id: $id, callback: $callback, label: $label, fields: $fields, active: $active
    base_url: $base_url, token_apikey: $token_apikey, token_storekey: $token_storekey, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
