# Auto-generated client for Customer Credit API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Customer-Credit-API/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.CUSTOMER_CREDIT_API_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.CUSTOMER_CREDIT_API_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "CUSTOMER_CREDIT_API_TOKEN"
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
    searchallaccounts: "record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>>"
    openan-account: "string"
    openor-change-account: "string"
    retrievea-accountby-id: "record<account: string, balance: float, creditLimit: float, description: string, email: string, lastUpdate: string>"
    updateemailanddescriptionofaaccount: "string"
    changecreditlimitofan-account: "record"
    addanaccount-holder: "record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>>"
    deleteanaccountholder: "record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>>"
    searchallinvoicesofa-account: "record<data: table<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float>, summary: record<count: int, total: float>>"
    cancel-invoice: "record"
    retrieve-invoiceby-id: "record<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float>"
    change-invoice: "record"
    markaninvoiceas-paid: "string"
    postponeaninvoice: "record"
    accountstatements: "record<currentBalance: float, intervalBalance: float, previousBalance: float, statements: table<date: string, description: string, value: float>>"
    changetoleranceofanaccount: "record"
    partialor-total-refunda-settlement: "record<id: string, value: float>"
    createor-update-settlement: "record<id: string, value: float>"
    searchallinvoices: "record<data: table<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float>, summary: record<count: int, total: float>>"
    retrievestoreconfiguration: "record<dailyInterestRate: float, invoicePostponementLimit: int, taxRate: float, tolerancePercent: float>"
    createorchangestoreconfiguration: "record<dailyInterestRate: float, invoicePostponementLimit: int, taxRate: float, tolerancePercent: float>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["searchallaccounts" "openan-account" "openor-change-account" "closean-account" "retrievea-accountby-id" "updateemailanddescriptionofaaccount" "changecreditlimitofan-account" "addanaccount-holder" "deleteanaccountholder" "searchallinvoicesofa-account" "cancel-invoice" "retrieve-invoiceby-id" "change-invoice" "markaninvoiceas-paid" "postponeaninvoice" "accountstatements" "decreasebalanceofanaccount" "changetoleranceofanaccount" "createa-pre-authorization" "cancela-pre-authorization" "createa-pre-authorizationusingid" "partialor-total-refunda-settlement" "createor-update-settlement" "searchallinvoices" "retrievestoreconfiguration" "createorchangestoreconfiguration" "commands"] | sort) } | get name | first)
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

# Search all accounts
#
# GET /api/creditcontrol/accounts
# Returns: record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>>
# operationId: Searchallaccounts
export def "searchallaccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/creditcontrol/accounts"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open an Account
#
# POST /api/creditcontrol/accounts
# Returns: string
# operationId: OpenanAccount
export def "openan-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  credit_limit: string # default: 500
  description: string # default: example
  document: string # default: 99999999999
  document_type: string # default: CPF
  email: string # default: email@domain.com
  tolerance: string # default: 1
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/creditcontrol/accounts"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: creditLimit, var: credit_limit}, {name: description, var: description}, {name: document, var: document}, {name: documentType, var: document_type}, {name: email, var: email}, {name: tolerance, var: tolerance}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type, credit_limit: $credit_limit, description: $description, document: $document, document_type: $document_type, email: $email, tolerance: $tolerance
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open or Change Account
#
# PUT /api/creditcontrol/accounts/{accountId}
# Returns: string
# operationId: OpenorChangeAccount
export def "openor-change-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --credit-limit: int # If the user don't set a credit limit, the system will define 100 for default (default: 100.0)
  --document: string # default: 00221292404
  email: string # default: email@email.com
  id: string # default: teste
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: creditLimit, var: credit_limit}, {name: document, var: document}, {name: email, var: email}, {name: id, var: id}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    account_id: $account_id, hdr_accept: $hdr_accept, content_type: $content_type, credit_limit: $credit_limit, document: $document, email: $email, id: $id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close an Account
#
# DELETE /api/creditcontrol/accounts/{creditAccountId}
# operationId: CloseanAccount
export def "closean-account" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --document: string # default: 99999999999
  --document-type: string # default: CPF
  --email: string # default: email@domain.com
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/creditcontrol/accounts/{creditAccountId}"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: documentType, var: document_type}, {name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, hdr_accept: $hdr_accept, content_type: $content_type, document: $document, document_type: $document_type, email: $email
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Account by Id
#
# GET /api/creditcontrol/accounts/{creditAccountId}
# Returns: record<account: string, balance: float, creditLimit: float, description: string, email: string, lastUpdate: string>
# operationId: RetrieveaAccountbyId
export def "retrievea-accountby-id" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/creditcontrol/accounts/{creditAccountId}"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update email and description of a account
#
# PUT /api/creditcontrol/accounts/{creditAccountId}
# Returns: string
# operationId: Updateemailanddescriptionofaaccount
export def "updateemailanddescriptionofaaccount" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  description: string # default: example
  email: string # default: email@domain.com
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{creditAccountId}"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: email, var: email}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, hdr_accept: $hdr_accept, content_type: $content_type, description: $description, email: $email
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change credit limit of an Account
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/creditlimit
# Returns: record
# operationId: ChangecreditlimitofanAccount
export def "changecreditlimitofan-account" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  value: int # format: number, default: 500.0
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{creditAccountId}/creditlimit"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, hdr_accept: $hdr_accept, content_type: $content_type, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an account Holder
#
# POST /api/creditcontrol/accounts/{creditAccountId}/holders
# Returns: record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>>
# operationId: AddanaccountHolder
export def "addanaccount-holder" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  claims: record # e.g. {email: USER-EMAIL} — shape: {email: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/creditcontrol/accounts/{creditAccountId}/holders"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: claims, var: claims}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, hdr_accept: $hdr_accept, content_type: $content_type, claims: $claims
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an account holder
#
# DELETE /api/creditcontrol/accounts/{creditAccountId}/holders/{holderId}
# Returns: record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>>
# operationId: Deleteanaccountholder
export def "deleteanaccountholder" [
  credit_account_id: string
  holder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/creditcontrol/accounts/{creditAccountId}/holders/{holderId}"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: holderId, var: holder_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, holder_id: $holder_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve invoice by creditAccountId
#
# GET /api/creditcontrol/accounts/{creditAccountId}/invoices
# Returns: record<data: table<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float>, summary: record<count: int, total: float>>
# operationId: SearchallinvoicesofaAccount
export def "searchallinvoicesofa-account" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/creditcontrol/accounts/{creditAccountId}/invoices"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel Invoice
#
# DELETE /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}
# Returns: record
# operationId: CancelInvoice
export def "cancel-invoice" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: invoiceId, var: invoice_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, invoice_id: $invoice_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Invoice by Id
#
# GET /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}
# Returns: record<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float>
# operationId: RetrieveInvoicebyId
export def "retrieve-invoiceby-id" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: invoiceId, var: invoice_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, invoice_id: $invoice_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Invoice
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}
# Returns: record
# operationId: ChangeInvoice
export def "change-invoice" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-id: string # Invoice's identification (default: insert identifier here)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  observation: string # default: example
  payment_link: string # default: example
  status: string # Invoice's status. It must be completed with "Paid", "Cancelled" or "Open" value. (default: Paid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: invoiceId, var: invoice_id}]
    query: [{name: friendlyId, var: friendly_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: observation, var: observation}, {name: paymentLink, var: payment_link}, {name: status, var: status}]}
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, invoice_id: $invoice_id, friendly_id: $friendly_id, hdr_accept: $hdr_accept, content_type: $content_type, observation: $observation, payment_link: $payment_link, status: $status
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark an invoice as Paid
#
# POST /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}/payments
# Returns: string
# operationId: MarkaninvoiceasPaid
export def "markaninvoiceas-paid" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  value: string # default: example
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}/payments"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: invoiceId, var: invoice_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, invoice_id: $invoice_id, hdr_accept: $hdr_accept, content_type: $content_type, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Postpone an invoice
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}/postponement
# Returns: record
# operationId: Postponeaninvoice
export def "postponeaninvoice" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  due_days: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}/postponement"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: invoiceId, var: invoice_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: dueDays, var: due_days}]}
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, invoice_id: $invoice_id, hdr_accept: $hdr_accept, content_type: $content_type, due_days: $due_days
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account statements
#
# GET /api/creditcontrol/accounts/{creditAccountId}/statements
# Returns: record<currentBalance: float, intervalBalance: float, previousBalance: float, statements: table<date: string, description: string, value: float>>
# operationId: Accountstatements
export def "accountstatements" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/creditcontrol/accounts/{creditAccountId}/statements"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decrease balance of an account
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/statements/{statementId}
# operationId: Decreasebalanceofanaccount
export def "decreasebalanceofanaccount" [
  credit_account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  value: string # default: -490.0
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{creditAccountId}/statements/{statementId}"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: statementId, var: statement_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, statement_id: $statement_id, hdr_accept: $hdr_accept, content_type: $content_type, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change tolerance of an account
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/tolerance
# Returns: record
# operationId: Changetoleranceofanaccount
export def "changetoleranceofanaccount" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  value: float # default: 0.2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{creditAccountId}/tolerance"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, hdr_accept: $hdr_accept, content_type: $content_type, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Pre Authorization
#
# POST /api/creditcontrol/accounts/{creditAccountId}/transaction
# operationId: CreateaPreAuthorization
export def "createa-pre-authorization" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  expiration_date: string # date in ISO8601 (UTC) dateformat (optional default is 1(one) day) (default: 1)
  installments: string # default: 1
  --settle: oneof<nothing, bool> # default: false
  value: string # default: 490.0
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/creditcontrol/accounts/{creditAccountId}/transaction"
    path_params: [{name: creditAccountId, var: credit_account_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: expirationDate, var: expiration_date}, {name: installments, var: installments}, {name: settle, var: settle, required: true}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, hdr_accept: $hdr_accept, content_type: $content_type, expiration_date: $expiration_date, installments: $installments, settle: $settle, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a Pre Authorization
#
# DELETE /api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}
# operationId: CancelaPreAuthorization
export def "cancela-pre-authorization" [
  credit_account_id: string
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
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: transactionId, var: transaction_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, transaction_id: $transaction_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Pre Authorization (using id)
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}
# operationId: CreateaPreAuthorization(usingid)
export def "createa-pre-authorizationusingid" [
  credit_account_id: string
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
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  expiration_date: string # date in ISO8601 (UTC) dateformat (optional default is 1(one) day) (default: 1)
  installments: string # default: 1
  --settle: oneof<nothing, bool> # default: false
  value: string # default: 20.0
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: transactionId, var: transaction_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: expirationDate, var: expiration_date}, {name: installments, var: installments}, {name: settle, var: settle, required: true}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, transaction_id: $transaction_id, hdr_accept: $hdr_accept, content_type: $content_type, expiration_date: $expiration_date, installments: $installments, settle: $settle, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial or Total Refund a Settlement
#
# POST /api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}/refunds
# Returns: record<id: string, value: float>
# operationId: PartialorTotalRefundaSettlement
export def "partialor-total-refunda-settlement" [
  credit_account_id: string
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
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  value: string # default: 20
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}/refunds"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: transactionId, var: transaction_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, transaction_id: $transaction_id, hdr_accept: $hdr_accept, content_type: $content_type, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or Update Settlement
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}/settlement
# Returns: record<id: string, value: float>
# operationId: CreateorUpdateSettlement
export def "createor-update-settlement" [
  credit_account_id: string
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
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  value: string # default: 490.0
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}/settlement"
    path_params: [{name: creditAccountId, var: credit_account_id}, {name: transactionId, var: transaction_id}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    credit_account_id: $credit_account_id, transaction_id: $transaction_id, hdr_accept: $hdr_accept, content_type: $content_type, value: $value
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search all invoices
#
# GET /api/creditcontrol/invoices
# Returns: record<data: table<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float>, summary: record<count: int, total: float>>
# operationId: Searchallinvoices
export def "searchallinvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # default: ""
  --to: string # default: ""
  --created-date-from: string # e.g. 
  --created-date-to: string # e.g. 
  --value: float # Invoice's value. It must be completed with a decimal value. (default: 101.22)
  --status: string # Invoice's status. It must be completed with "Paid", "Cancelled" or "Open" value. (default: Paid)
  --friendly-id: string # Invoice's identifier (default: insert identifier here)
  --credit-account-id: string # Credit account's identifier (default: B75F0)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/creditcontrol/invoices"
    query: [{name: from, var: from}, {name: to, var: to}, {name: createdDateFrom, var: created_date_from}, {name: createdDateTo, var: created_date_to}, {name: value, var: value}, {name: status, var: status}, {name: friendlyId, var: friendly_id}, {name: creditAccountId, var: credit_account_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    from: $from, to: $to, created_date_from: $created_date_from, created_date_to: $created_date_to, value: $value, status: $status, friendly_id: $friendly_id, credit_account_id: $credit_account_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve store configuration
#
# GET /api/creditcontrol/storeconfig
# Returns: record<dailyInterestRate: float, invoicePostponementLimit: int, taxRate: float, tolerancePercent: float>
# operationId: Retrievestoreconfiguration
export def "retrievestoreconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/creditcontrol/storeconfig"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or change store configuration
#
# PUT /api/creditcontrol/storeconfig
# Returns: record<dailyInterestRate: float, invoicePostponementLimit: int, taxRate: float, tolerancePercent: float>
# operationId: Createorchangestoreconfiguration
export def "createorchangestoreconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (required, default: application/json) (spec name: Accept)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json (required, default: application/json)
  --automatic-checking-account-creation-enabled: oneof<nothing, bool> # default: false
  daily_interest_rate: string # default: 0.6
  default_credit_value: string # default: 150.0
  invoice_postponement_limit: string # default: 2
  max_postponement_days: string # default: 3
  max_pre_authorization_growth_rate: string # default: 0.1
  --my-credits-enabled: oneof<nothing, bool> # default: true
  --notifications-settings: record # shape: {daysAfter?: list, daysPrior?: list}
  --postponement-enabled: oneof<nothing, bool> # default: false
  tax_rate: string # default: 0.4
  --tolerance-enabled: oneof<nothing, bool> # default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/creditcontrol/storeconfig"
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: automaticCheckingAccountCreationEnabled, var: automatic_checking_account_creation_enabled, required: true}, {name: dailyInterestRate, var: daily_interest_rate}, {name: defaultCreditValue, var: default_credit_value}, {name: invoicePostponementLimit, var: invoice_postponement_limit}, {name: maxPostponementDays, var: max_postponement_days}, {name: maxPreAuthorizationGrowthRate, var: max_pre_authorization_growth_rate}, {name: myCreditsEnabled, var: my_credits_enabled, required: true}, {name: notificationsSettings, var: notifications_settings}, {name: postponementEnabled, var: postponement_enabled, required: true}, {name: taxRate, var: tax_rate}, {name: toleranceEnabled, var: tolerance_enabled, required: true}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CUSTOMER_CREDIT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CUSTOMER_CREDIT_API_APPTOKEN_TOKEN}]
  } {
    hdr_accept: $hdr_accept, content_type: $content_type, automatic_checking_account_creation_enabled: $automatic_checking_account_creation_enabled, daily_interest_rate: $daily_interest_rate, default_credit_value: $default_credit_value, invoice_postponement_limit: $invoice_postponement_limit, max_postponement_days: $max_postponement_days, max_pre_authorization_growth_rate: $max_pre_authorization_growth_rate, my_credits_enabled: $my_credits_enabled, notifications_settings: $notifications_settings, postponement_enabled: $postponement_enabled, tax_rate: $tax_rate, tolerance_enabled: $tolerance_enabled
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
