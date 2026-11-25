# Auto-generated client for Checkout API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Checkout-API/1.0/openapi.json
# Auth: --token flag or $env.CHECKOUT_API_TOKEN
# Auth (appKey): --token-appkey flag or $env.CHECKOUT_API_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.CHECKOUT_API_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "CHECKOUT_API_TOKEN"
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
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken" "none"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let return_types = {
    add-merchant-context-data: "record<salesAssociateId: string>"
    add-coupons: "record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int>"
    post-api-checkout-pub-order-form-order-form-id-items: "record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int>"
    remove-all-items: "record"
    items-update: "record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int>"
    clearorder-form-messages: "record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int>"
    place-order-from-existing-order-form: "record"
    cart-simulation: "record<country: string, items: table<availability: string, id: string, listPrice: int, measurementUnit: string, offerings: list, parentAssemblyBinding: string, parentItemIndex: int, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, tax: int, unitMultiplier: int>, logisticsInfo: table<addressId: string, deliveryChannels: list, itemIndex: int, itemMetadata: record, messages: list, pickupPoints: list, purchaseConditions: record, quantity: int, selectedDeliveryChannel: string, selectedSla: string, shipsTo: list, slas: list, subscriptionData: record, totals: list>, marketingData: record, paymentData: record<availableAccounts: list<any>, availableAssociations: record, availableTokens: list<any>, giftCardMessages: list<any>, giftCards: list<any>, installmentOptions: list<any>, paymentSystems: list<record>, payments: list<any>>, postalCode: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<any>, teaser: list<any>>, selectableGifts: list<any>>"
    place-order: "record<orderForm: string, orders: table<allowCancelation: bool, allowChangeSeller: bool, allowEdition: bool, checkedInPickupPointId: string, clientProfileData: record, creationDate: string, followUpEmail: string, hostName: string, isCheckedIn: bool, isCompleted: bool, isUserDataVisible: bool, itemMetadata: record, items: list, lastChange: string, merchantName: string, orderFormCreationDate: string, orderGroup: string, orderId: string, paymentData: record, ratesAndBenefitsData: record, roundingError: int, salesAssociateId: string, salesChannel: string, sellerOrderId: string, sellers: list, shippingData: record, state: string, storeId: string, timeZoneCreationDate: string, timeZoneLastChange: string, totals: list, userType: string, value: int>, transactionData: record<gatewayCallbackTemplatePath: string, merchantTransactions: list<record>, receiverUri: string>>"
    get-client-profile-by-email: "record<availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, isComplete: bool, profileProvider: string, userProfile: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: string, profileErrorOnLoading: string, stateInscription: string, tradeName: string>, userProfileId: string>"
    get-sellers-by-region: "record<id: string, sellers: table<id: string, logo: string, name: string>>"
    removeallpersonaldata: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["process-order" "create-a-new-cart" "get-cart-information-by-id" "add-client-preferences" "add-client-profile" "add-marketing-data" "add-merchant-context-data" "add-payment-data" "add-shipping-address" "add-coupons" "set-multiple-custom-field-values" "removesinglecustomfieldvalue" "set-single-custom-field-value" "get-cart-installments" "post-api-checkout-pub-order-form-order-form-id-items" "remove-all-items" "items-update" "price-change" "clearorder-form-messages" "ignore-profile-data" "place-order-from-existing-order-form" "cart-simulation" "place-order" "list-pickup-ppoints-by-location" "get-address-by-postal-code" "get-client-profile-by-email" "get-sellers-by-region" "getorder-formconfiguration" "updateorder-formconfiguration" "get-window-to-change-seller" "update-window-to-change-seller" "removeallpersonaldata" "commands"] | sort) } | get name | first)
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

# Process order
#
# POST /api/checkout/pub/gatewayCallback/{orderGroup}
# operationId: ProcessOrder
export def "process-order" [
  order_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --cookie: string # VTEX Chekout cookie associated with a specific order. Use the `Vtex_CHKO_Auth` and the `CheckoutDataAccess` cookies returned by the [Place order](https://developers.vtex.com/vtex-rest-api/reference/order-placement-1#placeorder) or [Place order from existing cart](https://developers.vtex.com/vtex-rest-api/reference/order-placement-1#placeorderfromexistingorderform) API requests, like a browser would. (required, default: Vtex_CHKO_Auth=0e/RpYIEZu19BuwXB4tZ7eIGu9HT8vdUAHWQDHDpxMc=; CheckoutDataAccess=0e/PoiTEZu19BuwXB4tZ7eIGu9HT8vdUAHWQDHDpxMc=)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/checkout/pub/gatewayCallback/{orderGroup}"
    path_params: [{name: orderGroup, var: order_group}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Cookie, var: cookie, required: true, default: "Vtex_CHKO_Auth=0e/RpYIEZu19BuwXB4tZ7eIGu9HT8vdUAHWQDHDpxMc=; CheckoutDataAccess=0e/PoiTEZu19BuwXB4tZ7eIGu9HT8vdUAHWQDHDpxMc="}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_group: $order_group, content_type: $content_type, hdr_accept: $hdr_accept, cookie: $cookie
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current or create a new cart
#
# GET /api/checkout/pub/orderForm
# operationId: CreateANewCart
export def "create-a-new-cart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-new-cart: oneof<nothing, bool> # Use this query parameter to create a new empty shopping cart. (default: true)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/checkout/pub/orderForm"
    query: [{name: forceNewCart, var: force_new_cart}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    force_new_cart: $force_new_cart, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cart information by ID
#
# GET /api/checkout/pub/orderForm/{orderFormId}
# operationId: GetCartInformationById
export def "get-cart-information-by-id" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --refresh-outdated-data: oneof<nothing, bool> # It is possible to use the [Update cart items request](https://developers.vtex.com/vtex-rest-api/reference/cart-update#itemsupdate) so as to allow outdated information in the `orderForm`, which may improve performance in some cases. To guarantee that all cart information is updated, send this request with this parameter as `true`. We recommend doing this in the final stages of the shopping experience, starting from the checkout page. (default: true)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/checkout/pub/orderForm/{orderFormId}"
    path_params: [{name: orderFormId, var: order_form_id}]
    query: [{name: refreshOutdatedData, var: refresh_outdated_data}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, refresh_outdated_data: $refresh_outdated_data, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add client preferences
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/clientPreferencesData
# operationId: AddClientPreferences
export def "add-client-preferences" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --locale: string # Locale chosen by the shopper. Determines website language. (default: EN)
  --optin-news-letter: oneof<nothing, bool> # Indicates whether the shopper opted in to receive the store's news letter. (default: false)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/attachments/clientPreferencesData"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: locale, var: locale}, {name: optinNewsLetter, var: optin_news_letter}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, locale: $locale, optin_news_letter: $optin_news_letter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add client profile
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/clientProfileData
# operationId: AddClientProfile
export def "add-client-profile" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --corporate-document: string # Corporate document, if the customer is a legal entity. (default: 12345678000100)
  --corporate-name: string # Company name, if the customer is a legal entity. (default: company-name)
  --corporate-phone: string # Corporate phone number, if the customer is a legal entity. (default: +551100988887777)
  document: string # Document number informed by the customer. (default: 123456789)
  document_type: string # Type of the document informed by the customer. (default: cpf)
  email: string # Customer's email address. (default: customer@examplemail.com)
  first_name: string # Customer's first name. (default: first-name)
  --is-corporate: oneof<nothing, bool> # `true` if the customer is a legal entity. (default: false)
  last_name: string # Customer's last name. (default: last-name)
  --phone: string # Customer's phone number. (default: +55110988887777)
  --state-inscription: string # State inscription, if the customer is a legal entity. (default: 12345678)
  --trade-name: string # Trade name, if the customer is a legal entity. (default: trade-name)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/attachments/clientProfileData"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: corporateDocument, var: corporate_document}, {name: corporateName, var: corporate_name}, {name: corporatePhone, var: corporate_phone}, {name: document, var: document}, {name: documentType, var: document_type}, {name: email, var: email}, {name: firstName, var: first_name}, {name: isCorporate, var: is_corporate}, {name: lastName, var: last_name}, {name: phone, var: phone}, {name: stateInscription, var: state_inscription}, {name: tradeName, var: trade_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, corporate_document: $corporate_document, corporate_name: $corporate_name, corporate_phone: $corporate_phone, document: $document, document_type: $document_type, email: $email, first_name: $first_name, is_corporate: $is_corporate, last_name: $last_name, phone: $phone, state_inscription: $state_inscription, trade_name: $trade_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add marketing data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/marketingData
# operationId: AddMarketingData
export def "add-marketing-data" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --coupon: string # Sending an existing coupon code in this field will return the corresponding discount in the purchase. Use the [cart simulation](https://developers.vtex.com/vtex-rest-api/reference/orderform#orderformsimulation) request to check which coupons might apply before placing the order. (default: free-shipping)
  --marketing-tags: list<string> # Marketing tags. (default: [tag1, tag2])
  --utm-campaign: string # UTM campaign (default: Black friday)
  --utm-medium: string # UTM medium. (default: CPC)
  --utm-source: string # UTM source. (default: Facebook)
  --utmi-campaign: string # utmi_campaign (internal utm) (default: utmi_campaign-exmaple)
  --utmi-page: string # utmi_page (internal utm) (default: utmi_page-example)
  --utmi-part: string # utmi_part (internal utm) (default: utmi_part-exmaple)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/attachments/marketingData"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: coupon, var: coupon}, {name: marketingTags, var: marketing_tags}, {name: utmCampaign, var: utm_campaign}, {name: utmMedium, var: utm_medium}, {name: utmSource, var: utm_source}, {name: utmiCampaign, var: utmi_campaign}, {name: utmiPage, var: utmi_page}, {name: utmiPart, var: utmi_part}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, coupon: $coupon, marketing_tags: $marketing_tags, utm_campaign: $utm_campaign, utm_medium: $utm_medium, utm_source: $utm_source, utmi_campaign: $utmi_campaign, utmi_page: $utmi_page, utmi_part: $utmi_part
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add merchant context data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/merchantContextData
# Returns: record<salesAssociateId: string>
# operationId: AddMerchantContextData
export def "add-merchant-context-data" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  sales_associate_data: record # Sales Associate information. — shape: {salesAssociateId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/attachments/merchantContextData"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: salesAssociateData, var: sales_associate_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, sales_associate_data: $sales_associate_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add payment data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/paymentData
# operationId: AddPaymentData
export def "add-payment-data" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --payments: list # Array with information on each payment chosen by the shopper. — item shape: {group?: string, hasDefaultBillingAddress?: bool, installments?: int, installmentsInterestRate?: float, installmentsValue?: int, paymentSystem?: int, paymentSystemName?: string, referenceValue?: int, value?: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/attachments/paymentData"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: payments, var: payments}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, payments: $payments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add shipping address and select delivery option
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/shippingData
# operationId: AddShippingAddress
export def "add-shipping-address" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --clear-address-if-postal-code-not-found: oneof<nothing, bool> # This field should be sent as `false` to prevent the address information from being filled in automatically based on the `postalCode` information. (e.g. false)
  --logistics-info: list # Array with logistics information on each item of the `items` array in the `orderForm`. — item shape: {itemIndex?: int, selectedDeliveryChannel?: string, selectedSla?: string}
  --selected-addresses: list # List of objects with addresses information. — item shape: {addressType?: string, city?: string, complement?: string, country?: string, geoCoordinates?: list<float>, neighborhood?: string, number?: string, postalCode?: string, receiverName?: string, reference?: string, state?: string, street?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/attachments/shippingData"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clearAddressIfPostalCodeNotFound, var: clear_address_if_postal_code_not_found}, {name: logisticsInfo, var: logistics_info}, {name: selectedAddresses, var: selected_addresses}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, clear_address_if_postal_code_not_found: $clear_address_if_postal_code_not_found, logistics_info: $logistics_info, selected_addresses: $selected_addresses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add coupons to the cart
#
# POST /api/checkout/pub/orderForm/{orderFormId}/coupons
# Returns: record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int>
# operationId: AddCoupons
export def "add-coupons" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --text: string # Sending an existing coupon code in this field will return the corresponding discount in the purchase. Use the [cart simulation](https://developers.vtex.com/vtex-rest-api/reference/orderform#orderformsimulation) request to check which coupons might apply before placing the order. (default: freeshipping)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/coupons"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set multiple custom field values
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}
# operationId: SetMultipleCustomFieldValues
export def "set-multiple-custom-field-values" [
  order_form_id: string
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
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/checkout/pub/orderForm/{orderFormId}/customData/{appId}"
    path_params: [{name: orderFormId, var: order_form_id}, {name: appId, var: app_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, app_id: $app_id, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove single custom field value
#
# DELETE /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}/{appFieldName}
# operationId: Removesinglecustomfieldvalue
export def "removesinglecustomfieldvalue" [
  order_form_id: string
  app_id: string
  app_field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
    path: "/api/checkout/pub/orderForm/{orderFormId}/customData/{appId}/{appFieldName}"
    path_params: [{name: orderFormId, var: order_form_id}, {name: appId, var: app_id}, {name: appFieldName, var: app_field_name}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, app_id: $app_id, app_field_name: $app_field_name, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set single custom field value
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}/{appFieldName}
# operationId: SetSingleCustomFieldValue
export def "set-single-custom-field-value" [
  order_form_id: string
  app_id: string
  app_field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  value: string # The value you want to set to the specified field.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/checkout/pub/orderForm/{orderFormId}/customData/{appId}/{appFieldName}"
    path_params: [{name: orderFormId, var: order_form_id}, {name: appId, var: app_id}, {name: appFieldName, var: app_field_name}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, app_id: $app_id, app_field_name: $app_field_name, content_type: $content_type, hdr_accept: $hdr_accept, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cart installments
#
# GET /api/checkout/pub/orderForm/{orderFormId}/installments
# operationId: GetCartInstallments
export def "get-cart-installments" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payment-system: int # ID of the payment method to be consulted for installments. (required)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/checkout/pub/orderForm/{orderFormId}/installments"
    path_params: [{name: orderFormId, var: order_form_id}]
    query: [{name: paymentSystem, var: payment_system, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, payment_system: $payment_system, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add cart items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items
# Returns: record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int>
# operationId: Items
export def "post-api-checkout-pub-order-form-order-form-id-items" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-outdated-data: list # In order to optimize performance, this parameter allows some information to not be updated when there are changes in the minicart. For instance, if a shopper adds another unit of a given SKU to the cart, it may not be necessary to recalculate payment information, which could impact performance. This array accepts strings and currently the only possible value is `”paymentData”`. (default: [paymentData])
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --order-items: list # Array containing the cart items. Each object inside this array corresponds to a different item. — item shape: {id: string, index: int, price?: int, quantity: int, seller: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/items"
    path_params: [{name: orderFormId, var: order_form_id}]
    query: [{name: allowedOutdatedData, var: allowed_outdated_data, style: multi}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: orderItems, var: order_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, allowed_outdated_data: $allowed_outdated_data, content_type: $content_type, hdr_accept: $hdr_accept, order_items: $order_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove all items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items/removeAll
# Returns: record
# operationId: RemoveAllItems
export def "remove-all-items" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/items/removeAll"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update cart items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items/update
# Returns: record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int>
# operationId: ItemsUpdate
export def "items-update" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-outdated-data: list # In order to optimize performance, this parameter allows some information to not be updated when there are changes in the minicart. For instance, if a shopper adds another unit of a given SKU to the cart, it may not be necessary to recalculate payment information, which could impact performance. This array accepts strings and currently the only possible value is `”paymentData”`. (default: [paymentData])
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --order-items: list # Array containing the cart items. Each object inside this array corresponds to a different item. — item shape: {index: int, quantity: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/items/update"
    path_params: [{name: orderFormId, var: order_form_id}]
    query: [{name: allowedOutdatedData, var: allowed_outdated_data, style: multi}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: orderItems, var: order_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, allowed_outdated_data: $allowed_outdated_data, content_type: $content_type, hdr_accept: $hdr_accept, order_items: $order_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change price
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/items/{itemIndex}/price
# operationId: PriceChange
export def "price-change" [
  order_form_id: string
  item_index: string
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
  price: int # The new price of the item. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/checkout/pub/orderForm/{orderFormId}/items/{itemIndex}/price"
    path_params: [{name: orderFormId, var: order_form_id}, {name: itemIndex, var: item_index}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: price, var: price}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CHECKOUT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CHECKOUT_API_APPTOKEN_TOKEN}]
  } {
    order_form_id: $order_form_id, item_index: $item_index, content_type: $content_type, hdr_accept: $hdr_accept, price: $price
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear orderForm messages
#
# POST /api/checkout/pub/orderForm/{orderFormId}/messages/clear
# Returns: record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int>
# operationId: ClearorderFormMessages
export def "clearorder-form-messages" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/messages/clear"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ignore profile data
#
# PATCH /api/checkout/pub/orderForm/{orderFormId}/profile
# operationId: IgnoreProfileData
export def "ignore-profile-data" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --ignore-profile-data: oneof<nothing, bool> # Indicates whether profile data should be ignored. (default: false)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/checkout/pub/orderForm/{orderFormId}/profile"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ignoreProfileData, var: ignore_profile_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, ignore_profile_data: $ignore_profile_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Place order from an existing cart
#
# POST /api/checkout/pub/orderForm/{orderFormId}/transaction
# Returns: record
# operationId: PlaceOrderFromExistingOrderForm
export def "place-order-from-existing-order-form" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  interest_value: int # Interest rate to be used in case it applies. (default: 0)
  --optin-news-letter: oneof<nothing, bool> # True if the shopper opted to receive the newsletter. (default: false)
  reference_id: string # ID of the `orderForm` corresponding to the cart from which to place the order. This is the same as the `orderFormId` parameter. (default: 41a22925298a4ddca95318131a25b000)
  reference_value: int # Reference value of the order for calculating interest if that is the case. Can be equal to the total value and does not separate cents. For example, $24.99 is represented `2499`. (default: 6800)
  --save-personal-data: oneof<nothing, bool> # `true` if the shopper's data provided during checkout should be saved for future reference. (default: false)
  value: int # Total value of the order without separating cents. For example, $24.99 is represented `2499`. (default: 6800)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForm/{orderFormId}/transaction"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: interestValue, var: interest_value}, {name: optinNewsLetter, var: optin_news_letter}, {name: referenceId, var: reference_id}, {name: referenceValue, var: reference_value}, {name: savePersonalData, var: save_personal_data}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept, interest_value: $interest_value, optin_news_letter: $optin_news_letter, reference_id: $reference_id, reference_value: $reference_value, save_personal_data: $save_personal_data, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cart simulation
#
# POST /api/checkout/pub/orderForms/simulation
# Returns: record<country: string, items: table<availability: string, id: string, listPrice: int, measurementUnit: string, offerings: list, parentAssemblyBinding: string, parentItemIndex: int, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, tax: int, unitMultiplier: int>, logisticsInfo: table<addressId: string, deliveryChannels: list, itemIndex: int, itemMetadata: record, messages: list, pickupPoints: list, purchaseConditions: record, quantity: int, selectedDeliveryChannel: string, selectedSla: string, shipsTo: list, slas: list, subscriptionData: record, totals: list>, marketingData: record, paymentData: record<availableAccounts: list<any>, availableAssociations: record, availableTokens: list<any>, giftCardMessages: list<any>, giftCards: list<any>, installmentOptions: list<any>, paymentSystems: list<record>, payments: list<any>>, postalCode: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<any>, teaser: list<any>>, selectableGifts: list<any>>
# operationId: CartSimulation
export def "cart-simulation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rnb-behavior: int # This parameter defines which promotions apply to the simulation. Use `0` for simulations at cart stage, which means all promotions apply. In case of window simulation use `1`, which indicates promotions that apply nominal discounts over the total purchase value shouldn't be considered on the simulation. Note that if this not sent, the parameter is `1`. (default: 0)
  --sc: int # Trade Policy (Sales Channel) identification. (e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --country: string # Three letter ISO code of the country of the shipping address. This value must be sent along with the `postalCode` or `geoCoordinates` values. (e.g. BRA)
  --geo-coordinates: list<float> # Array containing two floats with geocoordinates, first longitude, then latitude. (default: [-47.924747467041016, -15.832582473754883])
  --items: list # Array containing information about the SKUs inside the cart to be simulated. — item shape: {id?: string, quantity?: int, seller?: string}
  --postal-code: string # Postal code. (e.g. 12345-000)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForms/simulation"
    query: [{name: RnbBehavior, var: rnb_behavior}, {name: sc, var: sc}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: geoCoordinates, var: geo_coordinates}, {name: items, var: items}, {name: postalCode, var: postal_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    rnb_behavior: $rnb_behavior, sc: $sc, content_type: $content_type, hdr_accept: $hdr_accept, country: $country, geo_coordinates: $geo_coordinates, items: $items, postal_code: $postal_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Place order
#
# PUT /api/checkout/pub/orders
# Returns: record<orderForm: string, orders: table<allowCancelation: bool, allowChangeSeller: bool, allowEdition: bool, checkedInPickupPointId: string, clientProfileData: record, creationDate: string, followUpEmail: string, hostName: string, isCheckedIn: bool, isCompleted: bool, isUserDataVisible: bool, itemMetadata: record, items: list, lastChange: string, merchantName: string, orderFormCreationDate: string, orderGroup: string, orderId: string, paymentData: record, ratesAndBenefitsData: record, roundingError: int, salesAssociateId: string, salesChannel: string, sellerOrderId: string, sellers: list, shippingData: record, state: string, storeId: string, timeZoneCreationDate: string, timeZoneLastChange: string, totals: list, userType: string, value: int>, transactionData: record<gatewayCallbackTemplatePath: string, merchantTransactions: list<record>, receiverUri: string>>
# operationId: PlaceOrder
export def "place-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy (Sales Channel) identification. This query can be used to create an order for a specific sales channel. (e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  client_profile_data: record # Customer's profile information. The `email` functions as a customer's ID. For customers already in your database, sending only the email address is enough to register the order to the shopper’s existing account. > If the shopper exists in you database but is not logged in, sending other profile information along with the email will cause the platform to fail placing the order. This happens because this action is interpreted as an attempt to edit profile data, which is not possible unless the customer is logged in to the store. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document?: string, documentType?: string, email: string, firstName?: string, isCorporate?: bool, lastName?: string, phone?: string, stateInscription?: string, tradeName?: string}
  items: list # Array of objects containing information on each of the order's items. — item shape: {attachments?: list<string>, bundleItems?: list, commission?: int, freightCommission?: int, id: string, isGift?: bool, itemAttachment?: record, measurementUnit?: string, price?: int, priceTags?: list, quantity: int, seller: string, unitMultiplier?: int}
  --marketing-data: record # shape: {coupon?: string, utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  --open-text-field: string # Optional field meant to hold additional information about the order. We recommend using this field for text, not data formats such as `JSON` even if escaped. For that purpose, see [Creating customizable fields](https://developers.vtex.com/vtex-rest-api/docs/creating-customizable-fields-in-the-cart-with-checkout-api-1) (default: open-text-example)
  payment_data: record # Payment infomation. — shape: {giftCardMessages?: list, giftCards?: list, paymentSystems?: list, payments: list, updateStatus?: string}
  --sales-associate-data: record # Sales Associate information. — shape: {salesAssociateId?: string}
  shipping_data: record # Shipping information. — shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/checkout/pub/orders"
    query: [{name: sc, var: sc}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientProfileData, var: client_profile_data}, {name: items, var: items}, {name: marketingData, var: marketing_data}, {name: openTextField, var: open_text_field}, {name: paymentData, var: payment_data}, {name: salesAssociateData, var: sales_associate_data}, {name: shippingData, var: shipping_data}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CHECKOUT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CHECKOUT_API_APPTOKEN_TOKEN}]
  } {
    sc: $sc, content_type: $content_type, hdr_accept: $hdr_accept, client_profile_data: $client_profile_data, items: $items, marketing_data: $marketing_data, open_text_field: $open_text_field, payment_data: $payment_data, sales_associate_data: $sales_associate_data, shipping_data: $shipping_data
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pickup points by location
#
# GET /api/checkout/pub/pickup-points
# operationId: ListPickupPpointsByLocation
export def "list-pickup-ppoints-by-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --geo-coordinates: list<float> # Geocoordinates (first longitude, then latitude) around which to search for pickup points. If you use this type of search, do not pass postal and country codes. (default: [-47.924747467041016, -15.832582473754883])
  --postal-code: string # Postal code around which to search for pickup points. If you use this type of search, make sure to pass a `countryCode` and do not pass `geoCoordinates`. (default: 1234000)
  --country-code: string # Three letter country code refering to the `postalCode` field. Pass the country code only if you are searching pickup points by postal code. (default: BRA)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/checkout/pub/pickup-points"
    query: [{name: geoCoordinates, var: geo_coordinates, style: multi}, {name: postalCode, var: postal_code}, {name: countryCode, var: country_code}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    geo_coordinates: $geo_coordinates, postal_code: $postal_code, country_code: $country_code, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get address by postal code
#
# GET /api/checkout/pub/postal-code/{countryCode}/{postalCode}
# operationId: GetAddressByPostalCode
export def "get-address-by-postal-code" [
  country_code: string
  postal_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
    path: "/api/checkout/pub/postal-code/{countryCode}/{postalCode}"
    path_params: [{name: countryCode, var: country_code}, {name: postalCode, var: postal_code}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    country_code: $country_code, postal_code: $postal_code, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get client profile by email
#
# GET /api/checkout/pub/profiles
# Returns: record<availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, isComplete: bool, profileProvider: string, userProfile: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: string, profileErrorOnLoading: string, stateInscription: string, tradeName: string>, userProfileId: string>
# operationId: GetClientProfileByEmail
export def "get-client-profile-by-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Client's email address to be searched. (required, default: clark.kent@examplemail.com)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/checkout/pub/profiles"
    query: [{name: email, var: email, required: true, default: "clark.kent@examplemail.com"}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    email: $email, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sellers by region or address
#
# GET /api/checkout/pub/regions/{regionId}
# Returns: record<id: string, sellers: table<id: string, logo: string, name: string>>
# operationId: GetSellersByRegion
export def "get-sellers-by-region" [
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Three letter country code refering to the `postalCode` field. (required, default: BRA)
  --postal-code: string # Postal code corresponding to the shopper's location. (default: 1234000)
  --geo-coordinates: list<float> # Geocoordinates (first longitude, semicolon, then latitude) corresponding to the shopper's location. (default: [-47.924747467041016, -15.832582473754883])
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/checkout/pub/regions/{regionId}"
    path_params: [{name: regionId, var: region_id}]
    query: [{name: country, var: country, required: true, default: BRA}, {name: postalCode, var: postal_code}, {name: geoCoordinates, var: geo_coordinates, style: multi}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    region_id: $region_id, country: $country, postal_code: $postal_code, geo_coordinates: $geo_coordinates, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get orderForm configuration
#
# GET /api/checkout/pvt/configuration/orderForm
# operationId: GetorderFormconfiguration
export def "getorder-formconfiguration" [
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
    path: "/api/checkout/pvt/configuration/orderForm"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CHECKOUT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CHECKOUT_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update orderForm configuration
#
# POST /api/checkout/pvt/configuration/orderForm
# operationId: UpdateorderFormconfiguration
export def "updateorder-formconfiguration" [
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
  --allow-manual-price: oneof<nothing, bool> # Allows the editing of SKU prices right in the cart. (nullable)
  --allow-multiple-deliveries: oneof<nothing, bool> # On the same purchase, allows the selection of items from multiple delivery channels. (nullable)
  --apps: list # Array of objects containing Apps configuration information. (nullable) — item shape: {fields?: list<string>, id?: string, major?: int}
  decimal_digits_precision: int # Number of price digits. (format: int32)
  --mask-first-purchase-data: oneof<nothing, bool> # Allows, on a first purchase, masking client's data. It could be useful when a shared cart is used and the client doesn't want to share its data.
  --max-number-of-white-label-sellers: int # Allows the input of a limit of white label sellers involved on the cart.
  minimum_quantity_accumulated_for_items: int # Minimum SKU quantity by cart. (format: int32)
  --minimum-value-accumulated: int # Minimum cart value. (nullable)
  payment_configuration: record # Payment Configuration object (e.g. {allowInstallmentsMerge: false, requiresAuthenticationForPreAuthorizedPaymentOption: false}) — shape: {allowInstallmentsMerge?: bool, requiresAuthenticationForPreAuthorizedPaymentOption: bool}
  --payment-system-to-check-first-installment: string # If you want to apply a first installment discount to a particular payment system, set this field to that payment system's ID. Learn more: [Configuring a discount for orders prepaid in full](https://help.vtex.com/en/tutorial/configurar-desconto-de-preco-a-vista--7Lfcj9Wb5dpYfA2gKkACIt). (e.g. 6)
  --recaptcha-validation: string # Configures reCAPTCHA validation for the account, defining in which situations the shopper will be prompted to validate a purchase with reCAPTCHA. Learn more about [reCAPTCHA validation for VTEX stores](https://help.vtex.com/tutorial/recaptcha-no-checkout--18Te3oDd7f4qcjKu9jhNzP) Possible values are: - `"never"`: no purchases are validated with reCAPTCHA. - `"always"`: every purchase is validated with reCAPTCHA. - `"vtexCriteria"`: only some purchases are validated with reCAPTCHA in order to minimize friction and improve shopping experience. VTEX’s algorithm determines which sessions are trustworthy and which should be validated with reCAPTCHA. This is the recommended option. (default: vtexCriteria)
  --tax-configuration: record # External tax service configuration. (nullable) — shape: {appId?: string, authorizationHeader?: string, url?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/checkout/pvt/configuration/orderForm"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowManualPrice, var: allow_manual_price}, {name: allowMultipleDeliveries, var: allow_multiple_deliveries}, {name: apps, var: apps}, {name: decimalDigitsPrecision, var: decimal_digits_precision}, {name: maskFirstPurchaseData, var: mask_first_purchase_data}, {name: maxNumberOfWhiteLabelSellers, var: max_number_of_white_label_sellers}, {name: minimumQuantityAccumulatedForItems, var: minimum_quantity_accumulated_for_items}, {name: minimumValueAccumulated, var: minimum_value_accumulated}, {name: paymentConfiguration, var: payment_configuration}, {name: paymentSystemToCheckFirstInstallment, var: payment_system_to_check_first_installment}, {name: recaptchaValidation, var: recaptcha_validation}, {name: taxConfiguration, var: tax_configuration}]}
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CHECKOUT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CHECKOUT_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, allow_manual_price: $allow_manual_price, allow_multiple_deliveries: $allow_multiple_deliveries, apps: $apps, decimal_digits_precision: $decimal_digits_precision, mask_first_purchase_data: $mask_first_purchase_data, max_number_of_white_label_sellers: $max_number_of_white_label_sellers, minimum_quantity_accumulated_for_items: $minimum_quantity_accumulated_for_items, minimum_value_accumulated: $minimum_value_accumulated, payment_configuration: $payment_configuration, payment_system_to_check_first_installment: $payment_system_to_check_first_installment, recaptcha_validation: $recaptcha_validation, tax_configuration: $tax_configuration
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get window to change seller
#
# GET /api/checkout/pvt/configuration/window-to-change-seller
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
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CHECKOUT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CHECKOUT_API_APPTOKEN_TOKEN}]
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
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: CHECKOUT_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: CHECKOUT_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, waiting_time: $waiting_time
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove all personal data
#
# GET /checkout/changeToAnonymousUser/{orderFormId}
# Returns: record
# operationId: Removeallpersonaldata
export def "removeallpersonaldata" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
    path: "/checkout/changeToAnonymousUser/{orderFormId}"
    path_params: [{name: orderFormId, var: order_form_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    order_form_id: $order_form_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
