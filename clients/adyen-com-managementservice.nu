# Auto-generated client for Management API v1
# Source: https://api.apis.guru/v2/specs/adyen.com/ManagementService/1/openapi.json
# Auth: --token flag or $env.MANAGEMENT_API_TOKEN

const CLIENT = {
  base_url: "https://management-test.adyen.com/v1"
  token_env_var: "MANAGEMENT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: X-API-Key, prefix: ""}
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://management-test.adyen.com/v1"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def communication-format-completer [] { ["http" "json" "soap"] }
def filter-merchant-account-type-completer [] { ["allAccounts" "excludeAccounts" "includeAccounts"] }
def network-type-completer [] { ["LOCAL" "PUBLIC"] }
def ssl-version-completer [] { ["HTTP" "SSL" "SSLv3" "TLS" "TLSv1" "TLSv1.1" "TLSv1.2" "TLSv1.3"] }
def shopper-interaction-completer [] { ["contAuth" "eCommerce" "moto" "pos"] }
def type-completer [] { ["afterpaytouch" "alipay" "alipay_hk" "amex" "applepay" "bcmc" "blik" "cartebancaire" "clearpay" "cup" "diners" "directEbanking" "directdebit_GB" "discover" "ebanking_FI" "eftpos_australia" "elo" "elocredit" "elodebit" "girocard" "giropay" "googlepay" "hiper" "hipercard" "ideal" "interac_card" "jcb" "klarna" "klarna_account" "klarna_paynow" "maestro" "mbway" "mc" "mcdebit" "mealVoucher_FR" "mobilepay" "multibanco" "onlineBanking_PL" "paypal" "payshop" "swish" "trustly" "vipps" "visa" "visadebit" "vpay" "wechatpay" "wechatpay_pos"] }
def status-completer [] { ["active" "closed" "inactive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-companies: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, dataCenters: list, description: string, id: string, name: string, reference: string, status: string>, itemsTotal: int, pagesTotal: int>"
    get-companies-company-id: "record<_links: record<apiCredentials: record<href: string>, self: record<href: string>, users: record<href: string>, webhooks: record<href: string>>, dataCenters: table<livePrefix: string, name: string>, description: string, id: string, name: string, reference: string, status: string>"
    get-companies-company-id-android-apps: "record<data: table<description: string, id: string, label: string, packageName: string, status: string, versionCode: int, versionName: string>>"
    get-companies-company-id-android-certificates: "record<data: table<description: string, extension: string, id: string, name: string, notAfter: string, notBefore: string, status: string>>"
    get-companies-company-id-api-credentials: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, active: bool, allowedIpAddresses: list, allowedOrigins: list, associatedMerchantAccounts: list, clientKey: string, description: string, id: string, roles: list, username: string>, itemsTotal: int, pagesTotal: int>"
    post-companies-company-id-api-credentials: "record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, apiKey: string, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, password: string, roles: list<string>, username: string>"
    get-companies-company-id-api-credentials-api-credential-id: "record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, roles: list<string>, username: string>"
    patch-companies-company-id-api-credentials-api-credential-id: "record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, roles: list<string>, username: string>"
    get-companies-company-id-api-credentials-api-credential-id-allowed-origins: "record<data: table<_links: record, domain: string, id: string>>"
    post-companies-company-id-api-credentials-api-credential-id-allowed-origins: "record<data: table<_links: record, domain: string, id: string>>"
    get-companies-company-id-api-credentials-api-credential-id-allowed-origins-origin-id: "record<_links: record<self: record<href: string>>, domain: string, id: string>"
    post-companies-company-id-api-credentials-api-credential-id-generate-api-key: "record<apiKey: string>"
    post-companies-company-id-api-credentials-api-credential-id-generate-client-key: "record<clientKey: string>"
    get-companies-company-id-billing-entities: "record<data: table<address: record, email: string, id: string, name: string, taxId: string>>"
    get-companies-company-id-merchants: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, captureDelay: string, companyId: string, dataCenters: list, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string>, itemsTotal: int, pagesTotal: int>"
    get-companies-company-id-shipping-locations: "record<data: table<address: record, contact: record, id: string, name: string>>"
    post-companies-company-id-shipping-locations: "record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>"
    get-companies-company-id-terminal-actions: "record<data: table<actionType: string, config: string, confirmedAt: string, id: string, result: string, scheduledAt: string, status: string, terminalId: string>>"
    get-companies-company-id-terminal-actions-action-id: "record<actionType: string, config: string, confirmedAt: string, id: string, result: string, scheduledAt: string, status: string, terminalId: string>"
    get-companies-company-id-terminal-logos: "record<data: string>"
    patch-companies-company-id-terminal-logos: "record<data: string>"
    get-companies-company-id-terminal-models: "record<data: table<id: string, name: string>>"
    get-companies-company-id-terminal-orders: "record<data: table<billingEntity: record, customerOrderReference: string, id: string, items: list, orderDate: string, shippingLocation: record, status: string, trackingUrl: string>>"
    post-companies-company-id-terminal-orders: "record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>"
    get-companies-company-id-terminal-orders-order-id: "record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>"
    patch-companies-company-id-terminal-orders-order-id: "record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>"
    post-companies-company-id-terminal-orders-order-id-cancel: "record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>"
    get-companies-company-id-terminal-products: "record<data: table<description: string, id: string, itemsIncluded: list, name: string, price: record>>"
    get-companies-company-id-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    patch-companies-company-id-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    get-companies-company-id-users: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, accountGroups: list, active: bool, associatedMerchantAccounts: list, authnApps: list, email: string, id: string, name: record, roles: list, timeZoneCode: string, username: string>, itemsTotal: int, pagesTotal: int>"
    post-companies-company-id-users: "record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>"
    get-companies-company-id-users-user-id: "record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>"
    patch-companies-company-id-users-user-id: "record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>"
    get-companies-company-id-webhooks: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, accountReference: string, data: table<_links: record, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>, itemsTotal: int, pagesTotal: int>"
    post-companies-company-id-webhooks: "record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>"
    get-companies-company-id-webhooks-webhook-id: "record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>"
    patch-companies-company-id-webhooks-webhook-id: "record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>"
    post-companies-company-id-webhooks-webhook-id-generate-hmac: "record<hmacKey: string>"
    post-companies-company-id-webhooks-webhook-id-test: "record<data: table<merchantId: string, output: string, requestSent: string, responseCode: string, responseTime: string, status: string>>"
    get-me: "record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, companyName: string, description: string, id: string, roles: list<string>, username: string>"
    get-me-allowed-origins: "record<data: table<_links: record, domain: string, id: string>>"
    post-me-allowed-origins: "record<_links: record<self: record<href: string>>, domain: string, id: string>"
    get-me-allowed-origins-origin-id: "record<_links: record<self: record<href: string>>, domain: string, id: string>"
    get-merchants: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, captureDelay: string, companyId: string, dataCenters: list, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string>, itemsTotal: int, pagesTotal: int>"
    post-merchants: "record<businessLineId: string, companyId: string, description: string, id: string, legalEntityId: string, pricingPlan: string, reference: string>"
    get-merchants-merchant-id: "record<_links: record<apiCredentials: record<href: string>, self: record<href: string>, users: record<href: string>, webhooks: record<href: string>>, captureDelay: string, companyId: string, dataCenters: table<livePrefix: string, name: string>, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string>"
    post-merchants-merchant-id-activate: "record<companyId: string, merchantId: string>"
    get-merchants-merchant-id-api-credentials: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, active: bool, allowedIpAddresses: list, allowedOrigins: list, clientKey: string, description: string, id: string, roles: list, username: string>, itemsTotal: int, pagesTotal: int>"
    post-merchants-merchant-id-api-credentials: "record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, apiKey: string, clientKey: string, description: string, id: string, password: string, roles: list<string>, username: string>"
    get-merchants-merchant-id-api-credentials-api-credential-id: "record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, clientKey: string, description: string, id: string, roles: list<string>, username: string>"
    patch-merchants-merchant-id-api-credentials-api-credential-id: "record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, clientKey: string, description: string, id: string, roles: list<string>, username: string>"
    get-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins: "record<data: table<_links: record, domain: string, id: string>>"
    post-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins: "record<data: table<_links: record, domain: string, id: string>>"
    get-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins-origin-id: "record<_links: record<self: record<href: string>>, domain: string, id: string>"
    post-merchants-merchant-id-api-credentials-api-credential-id-generate-api-key: "record<apiKey: string>"
    post-merchants-merchant-id-api-credentials-api-credential-id-generate-client-key: "record<clientKey: string>"
    get-merchants-merchant-id-billing-entities: "record<data: table<address: record, email: string, id: string, name: string, taxId: string>>"
    get-merchants-merchant-id-payment-method-settings: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<allowed: bool, applePay: record, bcmc: record, businessLineId: string, cartesBancaires: record, countries: list, currencies: list, customRoutingFlags: list, enabled: bool, giroPay: record, googlePay: record, id: string, klarna: record, mealVoucher_FR: record, paypal: record, reference: string, shopperInteraction: string, sofort: record, storeId: string, swish: record, type: string, verificationStatus: string, vipps: record>, itemsTotal: int, pagesTotal: int, typesWithErrors: list<string>>"
    post-merchants-merchant-id-payment-method-settings: "record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>>"
    get-merchants-merchant-id-payment-method-settings-payment-method-id: "record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>>"
    patch-merchants-merchant-id-payment-method-settings-payment-method-id: "record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>>"
    get-merchants-merchant-id-payment-method-settings-payment-method-id-get-apple-pay-domains: "record<domains: list<string>>"
    get-merchants-merchant-id-payout-settings: "record<data: table<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>>"
    post-merchants-merchant-id-payout-settings: "record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>"
    get-merchants-merchant-id-payout-settings-payout-settings-id: "record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>"
    patch-merchants-merchant-id-payout-settings-payout-settings-id: "record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>"
    get-merchants-merchant-id-shipping-locations: "record<data: table<address: record, contact: record, id: string, name: string>>"
    post-merchants-merchant-id-shipping-locations: "record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>"
    get-merchants-merchant-id-stores: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, address: record, businessLineIds: list, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record, status: string>, itemsTotal: int, pagesTotal: int>"
    post-merchants-merchant-id-stores: "record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>"
    get-merchants-merchant-id-stores-reference-terminal-logos: "record<data: string>"
    patch-merchants-merchant-id-stores-reference-terminal-logos: "record<data: string>"
    get-merchants-merchant-id-stores-reference-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    patch-merchants-merchant-id-stores-reference-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    get-merchants-merchant-id-stores-store-id: "record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>"
    patch-merchants-merchant-id-stores-store-id: "record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>"
    get-merchants-merchant-id-terminal-logos: "record<data: string>"
    patch-merchants-merchant-id-terminal-logos: "record<data: string>"
    get-merchants-merchant-id-terminal-models: "record<data: table<id: string, name: string>>"
    get-merchants-merchant-id-terminal-orders: "record<data: table<billingEntity: record, customerOrderReference: string, id: string, items: list, orderDate: string, shippingLocation: record, status: string, trackingUrl: string>>"
    post-merchants-merchant-id-terminal-orders: "record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>"
    get-merchants-merchant-id-terminal-orders-order-id: "record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>"
    patch-merchants-merchant-id-terminal-orders-order-id: "record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>"
    post-merchants-merchant-id-terminal-orders-order-id-cancel: "record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>"
    get-merchants-merchant-id-terminal-products: "record<data: table<description: string, id: string, itemsIncluded: list, name: string, price: record>>"
    get-merchants-merchant-id-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    patch-merchants-merchant-id-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    get-merchants-merchant-id-users: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, accountGroups: list, active: bool, authnApps: list, email: string, id: string, name: record, roles: list, timeZoneCode: string, username: string>, itemsTotal: int, pagesTotal: int>"
    post-merchants-merchant-id-users: "record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>"
    get-merchants-merchant-id-users-user-id: "record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>"
    patch-merchants-merchant-id-users-user-id: "record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>"
    get-merchants-merchant-id-webhooks: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, accountReference: string, data: table<_links: record, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>, itemsTotal: int, pagesTotal: int>"
    post-merchants-merchant-id-webhooks: "record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>"
    get-merchants-merchant-id-webhooks-webhook-id: "record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>"
    patch-merchants-merchant-id-webhooks-webhook-id: "record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>"
    post-merchants-merchant-id-webhooks-webhook-id-generate-hmac: "record<hmacKey: string>"
    post-merchants-merchant-id-webhooks-webhook-id-test: "record<data: table<merchantId: string, output: string, requestSent: string, responseCode: string, responseTime: string, status: string>>"
    get-stores: "record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, address: record, businessLineIds: list, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record, status: string>, itemsTotal: int, pagesTotal: int>"
    post-stores: "record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>"
    get-stores-store-id: "record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>"
    patch-stores-store-id: "record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>"
    get-stores-store-id-terminal-logos: "record<data: string>"
    patch-stores-store-id-terminal-logos: "record<data: string>"
    get-stores-store-id-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    patch-stores-store-id-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    get-terminals: "record<data: table<assigned: bool, bluetoothIp: string, bluetoothMac: string, city: string, companyAccount: string, countryCode: string, deviceModel: string, ethernetIp: string, ethernetMac: string, firmwareVersion: string, iccid: string, id: string, lastActivityDateTime: string, lastTransactionDateTime: string, linkNegotiation: string, serialNumber: string, simStatus: string, status: string, storeStatus: string, wifiIp: string, wifiMac: string, wifiSsid: string>>"
    post-terminals-schedule-actions: "record<actionDetails: any, items: table<id: string, terminalId: string>, scheduledAt: string, storeId: string, terminalIds: list<string>, terminalsWithErrors: record, totalErrors: int, totalScheduled: int>"
    get-terminals-terminal-id-terminal-logos: "record<data: string>"
    patch-terminals-terminal-id-terminal-logos: "record<data: string>"
    get-terminals-terminal-id-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
    patch-terminals-terminal-id-terminal-settings: "record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-companies" "get-companies-company-id" "get-companies-company-id-android-apps" "get-companies-company-id-android-certificates" "get-companies-company-id-api-credentials" "post-companies-company-id-api-credentials" "get-companies-company-id-api-credentials-api-credential-id" "patch-companies-company-id-api-credentials-api-credential-id" "get-companies-company-id-api-credentials-api-credential-id-allowed-origins" "post-companies-company-id-api-credentials-api-credential-id-allowed-origins" "delete-companies-company-id-api-credentials-api-credential-id-allowed-origins-origin-id" "get-companies-company-id-api-credentials-api-credential-id-allowed-origins-origin-id" "post-companies-company-id-api-credentials-api-credential-id-generate-api-key" "post-companies-company-id-api-credentials-api-credential-id-generate-client-key" "get-companies-company-id-billing-entities" "get-companies-company-id-merchants" "get-companies-company-id-shipping-locations" "post-companies-company-id-shipping-locations" "get-companies-company-id-terminal-actions" "get-companies-company-id-terminal-actions-action-id" "get-companies-company-id-terminal-logos" "patch-companies-company-id-terminal-logos" "get-companies-company-id-terminal-models" "get-companies-company-id-terminal-orders" "post-companies-company-id-terminal-orders" "get-companies-company-id-terminal-orders-order-id" "patch-companies-company-id-terminal-orders-order-id" "post-companies-company-id-terminal-orders-order-id-cancel" "get-companies-company-id-terminal-products" "get-companies-company-id-terminal-settings" "patch-companies-company-id-terminal-settings" "get-companies-company-id-users" "post-companies-company-id-users" "get-companies-company-id-users-user-id" "patch-companies-company-id-users-user-id" "get-companies-company-id-webhooks" "post-companies-company-id-webhooks" "delete-companies-company-id-webhooks-webhook-id" "get-companies-company-id-webhooks-webhook-id" "patch-companies-company-id-webhooks-webhook-id" "post-companies-company-id-webhooks-webhook-id-generate-hmac" "post-companies-company-id-webhooks-webhook-id-test" "get-me" "get-me-allowed-origins" "post-me-allowed-origins" "delete-me-allowed-origins-origin-id" "get-me-allowed-origins-origin-id" "get-merchants" "post-merchants" "get-merchants-merchant-id" "post-merchants-merchant-id-activate" "get-merchants-merchant-id-api-credentials" "post-merchants-merchant-id-api-credentials" "get-merchants-merchant-id-api-credentials-api-credential-id" "patch-merchants-merchant-id-api-credentials-api-credential-id" "get-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins" "post-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins" "delete-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins-origin-id" "get-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins-origin-id" "post-merchants-merchant-id-api-credentials-api-credential-id-generate-api-key" "post-merchants-merchant-id-api-credentials-api-credential-id-generate-client-key" "get-merchants-merchant-id-billing-entities" "get-merchants-merchant-id-payment-method-settings" "post-merchants-merchant-id-payment-method-settings" "get-merchants-merchant-id-payment-method-settings-payment-method-id" "patch-merchants-merchant-id-payment-method-settings-payment-method-id" "post-merchants-merchant-id-payment-method-settings-payment-method-id-add-apple-pay-domains" "get-merchants-merchant-id-payment-method-settings-payment-method-id-get-apple-pay-domains" "get-merchants-merchant-id-payout-settings" "post-merchants-merchant-id-payout-settings" "delete-merchants-merchant-id-payout-settings-payout-settings-id" "get-merchants-merchant-id-payout-settings-payout-settings-id" "patch-merchants-merchant-id-payout-settings-payout-settings-id" "get-merchants-merchant-id-shipping-locations" "post-merchants-merchant-id-shipping-locations" "get-merchants-merchant-id-stores" "post-merchants-merchant-id-stores" "get-merchants-merchant-id-stores-reference-terminal-logos" "patch-merchants-merchant-id-stores-reference-terminal-logos" "get-merchants-merchant-id-stores-reference-terminal-settings" "patch-merchants-merchant-id-stores-reference-terminal-settings" "get-merchants-merchant-id-stores-store-id" "patch-merchants-merchant-id-stores-store-id" "get-merchants-merchant-id-terminal-logos" "patch-merchants-merchant-id-terminal-logos" "get-merchants-merchant-id-terminal-models" "get-merchants-merchant-id-terminal-orders" "post-merchants-merchant-id-terminal-orders" "get-merchants-merchant-id-terminal-orders-order-id" "patch-merchants-merchant-id-terminal-orders-order-id" "post-merchants-merchant-id-terminal-orders-order-id-cancel" "get-merchants-merchant-id-terminal-products" "get-merchants-merchant-id-terminal-settings" "patch-merchants-merchant-id-terminal-settings" "get-merchants-merchant-id-users" "post-merchants-merchant-id-users" "get-merchants-merchant-id-users-user-id" "patch-merchants-merchant-id-users-user-id" "get-merchants-merchant-id-webhooks" "post-merchants-merchant-id-webhooks" "delete-merchants-merchant-id-webhooks-webhook-id" "get-merchants-merchant-id-webhooks-webhook-id" "patch-merchants-merchant-id-webhooks-webhook-id" "post-merchants-merchant-id-webhooks-webhook-id-generate-hmac" "post-merchants-merchant-id-webhooks-webhook-id-test" "get-stores" "post-stores" "get-stores-store-id" "patch-stores-store-id" "get-stores-store-id-terminal-logos" "patch-stores-store-id-terminal-logos" "get-stores-store-id-terminal-settings" "patch-stores-store-id-terminal-settings" "get-terminals" "post-terminals-schedule-actions" "get-terminals-terminal-id-terminal-logos" "patch-terminals-terminal-id-terminal-logos" "get-terminals-terminal-id-terminal-settings" "patch-terminals-terminal-id-terminal-settings" "commands"] | sort) } | get name | first)
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

# Get a list of company accounts
#
# GET /companies
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, dataCenters: list, description: string, id: string, name: string, reference: string, status: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-companies
export def "get-companies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies"
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a company account
#
# GET /companies/{companyId}
# Returns: record<_links: record<apiCredentials: record<href: string>, self: record<href: string>, users: record<href: string>, webhooks: record<href: string>>, dataCenters: table<livePrefix: string, name: string>, description: string, id: string, name: string, reference: string, status: string>
# operationId: get-companies-companyId
export def "get-companies-company-id" [
  company_id: string
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
    path: "/companies/{companyId}"
    path_params: [{name: companyId, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of Android apps
#
# GET /companies/{companyId}/androidApps
# Returns: record<data: table<description: string, id: string, label: string, packageName: string, status: string, versionCode: int, versionName: string>>
# operationId: get-companies-companyId-androidApps
export def "get-companies-company-id-android-apps" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 20 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/androidApps"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of Android certificates
#
# GET /companies/{companyId}/androidCertificates
# Returns: record<data: table<description: string, extension: string, id: string, name: string, notAfter: string, notBefore: string, status: string>>
# operationId: get-companies-companyId-androidCertificates
export def "get-companies-company-id-android-certificates" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 20 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/androidCertificates"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of API credentials
#
# GET /companies/{companyId}/apiCredentials
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, active: bool, allowedIpAddresses: list, allowedOrigins: list, associatedMerchantAccounts: list, clientKey: string, description: string, id: string, roles: list, username: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-companies-companyId-apiCredentials
export def "get-companies-company-id-api-credentials" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/apiCredentials"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an API credential.
#
# POST /companies/{companyId}/apiCredentials
# Returns: record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, apiKey: string, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, password: string, roles: list<string>, username: string>
# operationId: post-companies-companyId-apiCredentials
export def "post-companies-company-id-api-credentials" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-origins: list<string> # List of [allowed origins](https://docs.adyen.com/development-resources/client-side-authentication#allowed-origins) for the new API credential.
  --associated-merchant-accounts: list<string> # List of merchant accounts that the API credential has access to.
  --description: string # Description of the API credential.
  --roles: list<string> # List of [roles](https://docs.adyen.com/development-resources/api-credentials#roles-1) of the API credential.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/apiCredentials"
    path_params: [{name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowedOrigins, var: allowed_origins}, {name: associatedMerchantAccounts, var: associated_merchant_accounts}, {name: description, var: description}, {name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, allowed_origins: $allowed_origins, associated_merchant_accounts: $associated_merchant_accounts, description: $description, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an API credential
#
# GET /companies/{companyId}/apiCredentials/{apiCredentialId}
# Returns: record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, roles: list<string>, username: string>
# operationId: get-companies-companyId-apiCredentials-apiCredentialId
export def "get-companies-company-id-api-credentials-api-credential-id" [
  company_id: string
  api_credential_id: string
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
    path: "/companies/{companyId}/apiCredentials/{apiCredentialId}"
    path_params: [{name: companyId, var: company_id}, {name: apiCredentialId, var: api_credential_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, api_credential_id: $api_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an API credential.
#
# PATCH /companies/{companyId}/apiCredentials/{apiCredentialId}
# Returns: record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, roles: list<string>, username: string>
# operationId: patch-companies-companyId-apiCredentials-apiCredentialId
export def "patch-companies-company-id-api-credentials-api-credential-id" [
  company_id: string
  api_credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Indicates if the API credential is enabled.
  --allowed-origins: list<string> # The new list of [allowed origins](https://docs.adyen.com/development-resources/client-side-authentication#allowed-origins) for the API credential.
  --associated-merchant-accounts: list<string> # List of merchant accounts that the API credential has access to.
  --description: string # Description of the API credential.
  --roles: list<string> # List of [roles](https://docs.adyen.com/development-resources/api-credentials#roles-1) of the API credential.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/companies/{companyId}/apiCredentials/{apiCredentialId}"
    path_params: [{name: companyId, var: company_id}, {name: apiCredentialId, var: api_credential_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: allowedOrigins, var: allowed_origins}, {name: associatedMerchantAccounts, var: associated_merchant_accounts}, {name: description, var: description}, {name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, api_credential_id: $api_credential_id, active: $active, allowed_origins: $allowed_origins, associated_merchant_accounts: $associated_merchant_accounts, description: $description, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of allowed origins
#
# GET /companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins
# Returns: record<data: table<_links: record, domain: string, id: string>>
# operationId: get-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins
export def "get-companies-company-id-api-credentials-api-credential-id-allowed-origins" [
  company_id: string
  api_credential_id: string
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
    path: "/companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins"
    path_params: [{name: companyId, var: company_id}, {name: apiCredentialId, var: api_credential_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, api_credential_id: $api_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an allowed origin
#
# POST /companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins
# Returns: record<data: table<_links: record, domain: string, id: string>>
# operationId: post-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins
export def "post-companies-company-id-api-credentials-api-credential-id-allowed-origins" [
  company_id: string
  api_credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {self: record}
  domain: string # Domain of the allowed origin.
  --id: string # Unique identifier of the allowed origin.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins"
    path_params: [{name: companyId, var: company_id}, {name: apiCredentialId, var: api_credential_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: _links, var: links}, {name: domain, var: domain}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, api_credential_id: $api_credential_id, links: $links, domain: $domain, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an allowed origin
#
# DELETE /companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}
# operationId: delete-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins-originId
export def "delete-companies-company-id-api-credentials-api-credential-id-allowed-origins-origin-id" [
  company_id: string
  api_credential_id: string
  origin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}"
    path_params: [{name: companyId, var: company_id}, {name: apiCredentialId, var: api_credential_id}, {name: originId, var: origin_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    company_id: $company_id, api_credential_id: $api_credential_id, origin_id: $origin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an allowed origin
#
# GET /companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}
# Returns: record<_links: record<self: record<href: string>>, domain: string, id: string>
# operationId: get-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins-originId
export def "get-companies-company-id-api-credentials-api-credential-id-allowed-origins-origin-id" [
  company_id: string
  api_credential_id: string
  origin_id: string
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
    path: "/companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}"
    path_params: [{name: companyId, var: company_id}, {name: apiCredentialId, var: api_credential_id}, {name: originId, var: origin_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, api_credential_id: $api_credential_id, origin_id: $origin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate new API key
#
# POST /companies/{companyId}/apiCredentials/{apiCredentialId}/generateApiKey
# Returns: record<apiKey: string>
# operationId: post-companies-companyId-apiCredentials-apiCredentialId-generateApiKey
export def "post-companies-company-id-api-credentials-api-credential-id-generate-api-key" [
  company_id: string
  api_credential_id: string
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
    method: post
    path: "/companies/{companyId}/apiCredentials/{apiCredentialId}/generateApiKey"
    path_params: [{name: companyId, var: company_id}, {name: apiCredentialId, var: api_credential_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, api_credential_id: $api_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate new client key
#
# POST /companies/{companyId}/apiCredentials/{apiCredentialId}/generateClientKey
# Returns: record<clientKey: string>
# operationId: post-companies-companyId-apiCredentials-apiCredentialId-generateClientKey
export def "post-companies-company-id-api-credentials-api-credential-id-generate-client-key" [
  company_id: string
  api_credential_id: string
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
    method: post
    path: "/companies/{companyId}/apiCredentials/{apiCredentialId}/generateClientKey"
    path_params: [{name: companyId, var: company_id}, {name: apiCredentialId, var: api_credential_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, api_credential_id: $api_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of billing entities
#
# GET /companies/{companyId}/billingEntities
# Returns: record<data: table<address: record, email: string, id: string, name: string, taxId: string>>
# operationId: get-companies-companyId-billingEntities
export def "get-companies-company-id-billing-entities" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the billing entity.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/billingEntities"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of merchant accounts
#
# GET /companies/{companyId}/merchants
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, captureDelay: string, companyId: string, dataCenters: list, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-companies-companyId-merchants
export def "get-companies-company-id-merchants" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/merchants"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of shipping locations
#
# GET /companies/{companyId}/shippingLocations
# Returns: record<data: table<address: record, contact: record, id: string, name: string>>
# operationId: get-companies-companyId-shippingLocations
export def "get-companies-company-id-shipping-locations" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the shipping location.
  --offset: int # The number of locations to skip. (format: int32)
  --limit: int # The number of locations to return. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/shippingLocations"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: name, var: name}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, name: $name, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a shipping location
#
# POST /companies/{companyId}/shippingLocations
# Returns: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>
# operationId: post-companies-companyId-shippingLocations
export def "post-companies-company-id-shipping-locations" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {city?: string, companyName?: string, country?: string, postalCode?: string, stateOrProvince?: string, streetAddress?: string, streetAddress2?: string}
  --contact: record # shape: {email?: string, firstName?: string, infix?: string, lastName?: string, phoneNumber?: string}
  --id: string # The unique identifier of the shipping location, for use as `shippingLocationId` when creating an order.
  --name: string # The unique name of the shipping location.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/shippingLocations"
    path_params: [{name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: contact, var: contact}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, address: $address, contact: $contact, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of terminal actions
#
# GET /companies/{companyId}/terminalActions
# Returns: record<data: table<actionType: string, config: string, confirmedAt: string, id: string, result: string, scheduledAt: string, status: string, terminalId: string>>
# operationId: get-companies-companyId-terminalActions
export def "get-companies-company-id-terminal-actions" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 20 items on a page. (format: int32)
  --status: string # Returns terminal actions with the specified status. Allowed values: **pending**, **successful**, **failed**, **cancelled**, **tryLater**.
  --type: string # Returns terminal actions of the specified type. Allowed values: **InstallAndroidApp**, **UninstallAndroidApp**, **InstallAndroidCertificate**, **UninstallAndroidCertificate**.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/terminalActions"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: status, var: status}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, page_number: $page_number, page_size: $page_size, status: $status, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get terminal action
#
# GET /companies/{companyId}/terminalActions/{actionId}
# Returns: record<actionType: string, config: string, confirmedAt: string, id: string, result: string, scheduledAt: string, status: string, terminalId: string>
# operationId: get-companies-companyId-terminalActions-actionId
export def "get-companies-company-id-terminal-actions-action-id" [
  company_id: string
  action_id: string
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
    path: "/companies/{companyId}/terminalActions/{actionId}"
    path_params: [{name: companyId, var: company_id}, {name: actionId, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the terminal logo
#
# GET /companies/{companyId}/terminalLogos
# Returns: record<data: string>
# operationId: get-companies-companyId-terminalLogos
export def "get-companies-company-id-terminal-logos" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/terminalLogos"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: model, var: model, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, model: $model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the terminal logo
#
# PATCH /companies/{companyId}/terminalLogos
# Returns: record<data: string>
# operationId: patch-companies-companyId-terminalLogos
export def "patch-companies-company-id-terminal-logos" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T. (required)
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/companies/{companyId}/terminalLogos"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: model, var: model, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, model: $model, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of terminal models
#
# GET /companies/{companyId}/terminalModels
# Returns: record<data: table<id: string, name: string>>
# operationId: get-companies-companyId-terminalModels
export def "get-companies-company-id-terminal-models" [
  company_id: string
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
    path: "/companies/{companyId}/terminalModels"
    path_params: [{name: companyId, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of orders
#
# GET /companies/{companyId}/terminalOrders
# Returns: record<data: table<billingEntity: record, customerOrderReference: string, id: string, items: list, orderDate: string, shippingLocation: record, status: string, trackingUrl: string>>
# operationId: get-companies-companyId-terminalOrders
export def "get-companies-company-id-terminal-orders" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-order-reference: string # Your purchase order number.
  --status: string # The order status. Possible values (not case-sensitive): Placed, Confirmed, Cancelled, Shipped, Delivered.
  --offset: int # The number of orders to skip. (format: int32)
  --limit: int # The number of orders to return. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/terminalOrders"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: customerOrderReference, var: customer_order_reference}, {name: status, var: status}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, customer_order_reference: $customer_order_reference, status: $status, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an order
#
# POST /companies/{companyId}/terminalOrders
# Returns: record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>
# operationId: post-companies-companyId-terminalOrders
export def "post-companies-company-id-terminal-orders" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-entity-id: string # The identification of the billing entity to use for the order.
  --customer-order-reference: string # The merchant-defined purchase order reference.
  --items: list # The products included in the order. — item shape: {id?: string, installments?: int, name?: string, quantity?: int}
  --shipping-location-id: string # The identification of the shipping location to use for the order.
  --tax-id: string # The tax number of the billing entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/terminalOrders"
    path_params: [{name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingEntityId, var: billing_entity_id}, {name: customerOrderReference, var: customer_order_reference}, {name: items, var: items}, {name: shippingLocationId, var: shipping_location_id}, {name: taxId, var: tax_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, billing_entity_id: $billing_entity_id, customer_order_reference: $customer_order_reference, items: $items, shipping_location_id: $shipping_location_id, tax_id: $tax_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an order
#
# GET /companies/{companyId}/terminalOrders/{orderId}
# Returns: record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>
# operationId: get-companies-companyId-terminalOrders-orderId
export def "get-companies-company-id-terminal-orders-order-id" [
  company_id: string
  order_id: string
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
    path: "/companies/{companyId}/terminalOrders/{orderId}"
    path_params: [{name: companyId, var: company_id}, {name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an order
#
# PATCH /companies/{companyId}/terminalOrders/{orderId}
# Returns: record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>
# operationId: patch-companies-companyId-terminalOrders-orderId
export def "patch-companies-company-id-terminal-orders-order-id" [
  company_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-entity-id: string # The identification of the billing entity to use for the order.
  --customer-order-reference: string # The merchant-defined purchase order reference.
  --items: list # The products included in the order. — item shape: {id?: string, installments?: int, name?: string, quantity?: int}
  --shipping-location-id: string # The identification of the shipping location to use for the order.
  --tax-id: string # The tax number of the billing entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/companies/{companyId}/terminalOrders/{orderId}"
    path_params: [{name: companyId, var: company_id}, {name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingEntityId, var: billing_entity_id}, {name: customerOrderReference, var: customer_order_reference}, {name: items, var: items}, {name: shippingLocationId, var: shipping_location_id}, {name: taxId, var: tax_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, order_id: $order_id, billing_entity_id: $billing_entity_id, customer_order_reference: $customer_order_reference, items: $items, shipping_location_id: $shipping_location_id, tax_id: $tax_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an order
#
# POST /companies/{companyId}/terminalOrders/{orderId}/cancel
# Returns: record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>
# operationId: post-companies-companyId-terminalOrders-orderId-cancel
export def "post-companies-company-id-terminal-orders-order-id-cancel" [
  company_id: string
  order_id: string
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
    method: post
    path: "/companies/{companyId}/terminalOrders/{orderId}/cancel"
    path_params: [{name: companyId, var: company_id}, {name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of terminal products
#
# GET /companies/{companyId}/terminalProducts
# Returns: record<data: table<description: string, id: string, itemsIncluded: list, name: string, price: record>>
# operationId: get-companies-companyId-terminalProducts
export def "get-companies-company-id-terminal-products" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # The country to return products for, in [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) format. For example, **US** (required)
  --terminal-model-id: string # The terminal model to return products for. Use the ID returned in the [GET `/terminalModels`](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/companies/{companyId}/terminalModels) response. For example, **Verifone.M400**
  --offset: int # The number of products to skip. (format: int32)
  --limit: int # The number of products to return. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/terminalProducts"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: country, var: country, required: true}, {name: terminalModelId, var: terminal_model_id}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, country: $country, terminal_model_id: $terminal_model_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get terminal settings
#
# GET /companies/{companyId}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: get-companies-companyId-terminalSettings
export def "get-companies-company-id-terminal-settings" [
  company_id: string
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
    path: "/companies/{companyId}/terminalSettings"
    path_params: [{name: companyId, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update terminal settings
#
# PATCH /companies/{companyId}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: patch-companies-companyId-terminalSettings
export def "patch-companies-company-id-terminal-settings" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholder-receipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list<string>, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list<string>}
  --offline-processing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --pay-at-table: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list<string>}
  --receipt-options: record # shape: {logo?: string, qrCodeData?: string}
  --receipt-printing: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifi-profiles: record # shape: {profiles?: list, settings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/companies/{companyId}/terminalSettings"
    path_params: [{name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cardholderReceipt, var: cardholder_receipt}, {name: connectivity, var: connectivity}, {name: gratuities, var: gratuities}, {name: hardware, var: hardware}, {name: nexo, var: nexo}, {name: offlineProcessing, var: offline_processing}, {name: opi, var: opi}, {name: passcodes, var: passcodes}, {name: payAtTable, var: pay_at_table}, {name: payment, var: payment}, {name: receiptOptions, var: receipt_options}, {name: receiptPrinting, var: receipt_printing}, {name: signature, var: signature}, {name: standalone, var: standalone}, {name: surcharge, var: surcharge}, {name: timeouts, var: timeouts}, {name: wifiProfiles, var: wifi_profiles}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, cardholder_receipt: $cardholder_receipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offline_processing: $offline_processing, opi: $opi, passcodes: $passcodes, pay_at_table: $pay_at_table, payment: $payment, receipt_options: $receipt_options, receipt_printing: $receipt_printing, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifi_profiles: $wifi_profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of users
#
# GET /companies/{companyId}/users
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, accountGroups: list, active: bool, associatedMerchantAccounts: list, authnApps: list, email: string, id: string, name: record, roles: list, timeZoneCode: string, username: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-companies-companyId-users
export def "get-companies-company-id-users" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to return. (format: int32)
  --page-size: int # The number of items to have on a page. Maximum value is **100**. The default is **10** items on a page. (format: int32)
  --username: string # The partial or complete username to select all users that match.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/users"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, page_number: $page_number, page_size: $page_size, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user
#
# POST /companies/{companyId}/users
# Returns: record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>
# operationId: post-companies-companyId-users
export def "post-companies-company-id-users" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-groups: list<string> # The list of [account groups](https://docs.adyen.com/account/account-structure#account-groups) associated with this user.
  --associated-merchant-accounts: list<string> # The list of [merchant accounts](https://docs.adyen.com/account/account-structure#merchant-accounts) associated with this user.
  --authn-apps: list<string> # Set of authn apps to add to this user
  email: string # The email address of the user.
  name: record # shape: {firstName: string, lastName: string}
  --roles: list<string> # The list of [roles](https://docs.adyen.com/account/user-roles) for this user.
  --time-zone-code: string # The [tz database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the time zone of the user. For example, **Europe/Amsterdam**.
  username: string # The username for this user. Allowed length: 255 alphanumeric characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/users"
    path_params: [{name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountGroups, var: account_groups}, {name: associatedMerchantAccounts, var: associated_merchant_accounts}, {name: authnApps, var: authn_apps}, {name: email, var: email}, {name: name, var: name}, {name: roles, var: roles}, {name: timeZoneCode, var: time_zone_code}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, account_groups: $account_groups, associated_merchant_accounts: $associated_merchant_accounts, authn_apps: $authn_apps, email: $email, name: $name, roles: $roles, time_zone_code: $time_zone_code, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user details
#
# GET /companies/{companyId}/users/{userId}
# Returns: record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>
# operationId: get-companies-companyId-users-userId
export def "get-companies-company-id-users-user-id" [
  company_id: string
  user_id: string
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
    path: "/companies/{companyId}/users/{userId}"
    path_params: [{name: companyId, var: company_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user details
#
# PATCH /companies/{companyId}/users/{userId}
# Returns: record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>
# operationId: patch-companies-companyId-users-userId
export def "patch-companies-company-id-users-user-id" [
  company_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-groups: list<string> # The list of [account groups](https://docs.adyen.com/account/account-structure#account-groups) associated with this user.
  --active: oneof<nothing, bool> # Indicates whether this user is active.
  --associated-merchant-accounts: list<string> # The list of [merchant accounts](https://docs.adyen.com/account/account-structure#merchant-accounts) to associate the user with.
  --authn-apps-to-add: list<string> # Set of authn apps to add to this user
  --authn-apps-to-remove: list<string> # Set of authn apps to remove from this user
  --email: string # The email address of the user.
  --name: record # shape: {firstName?: string, lastName?: string}
  --roles: list<string> # The list of [roles](https://docs.adyen.com/account/user-roles) for this user.
  --time-zone-code: string # The [tz database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the time zone of the user. For example, **Europe/Amsterdam**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/companies/{companyId}/users/{userId}"
    path_params: [{name: companyId, var: company_id}, {name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountGroups, var: account_groups}, {name: active, var: active}, {name: associatedMerchantAccounts, var: associated_merchant_accounts}, {name: authnAppsToAdd, var: authn_apps_to_add}, {name: authnAppsToRemove, var: authn_apps_to_remove}, {name: email, var: email}, {name: name, var: name}, {name: roles, var: roles}, {name: timeZoneCode, var: time_zone_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, user_id: $user_id, account_groups: $account_groups, active: $active, associated_merchant_accounts: $associated_merchant_accounts, authn_apps_to_add: $authn_apps_to_add, authn_apps_to_remove: $authn_apps_to_remove, email: $email, name: $name, roles: $roles, time_zone_code: $time_zone_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all webhooks
#
# GET /companies/{companyId}/webhooks
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, accountReference: string, data: table<_links: record, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-companies-companyId-webhooks
export def "get-companies-company-id-webhooks" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/webhooks"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set up a webhook
#
# POST /companies/{companyId}/webhooks
# Returns: record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>
# operationId: post-companies-companyId-webhooks
export def "post-companies-company-id-webhooks" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepts-expired-certificate: oneof<nothing, bool> # Indicates if expired SSL certificates are accepted. Default value: **false**.
  --accepts-self-signed-certificate: oneof<nothing, bool> # Indicates if self-signed SSL certificates are accepted. Default value: **false**.
  --accepts-untrusted-root-certificate: oneof<nothing, bool> # Indicates if untrusted SSL certificates are accepted. Default value: **false**.
  --active: oneof<nothing, bool> # Indicates if the webhook configuration is active. The field must be **true** for us to send webhooks about events related an account.
  --additional-settings: record # shape: {includeEventCodes?: list<string>, properties?: record}
  communication_format: string@communication-format-completer # Format or protocol for receiving webhooks. Possible values: * **soap** * **http** * **json**
  --description: string # Your description for this webhook configuration.
  filter_merchant_account_type: string@filter-merchant-account-type-completer # Shows how merchant accounts are filtered when configuring the webhook. Possible values: * **includeAccounts**: The webhook is configured for the merchant accounts listed in `filterMerchantAccounts`. * **excludeAccounts**: The webhook is not configured for the merchant accounts listed in `filterMerchantAccounts`. * **allAccounts**: Includes all merchant accounts, and does not require specifying `filterMerchantAccounts`.
  filter_merchant_accounts: list<string> # A list of merchant account names that are included or excluded from receiving the webhook. Inclusion or exclusion is based on the value defined for `filterMerchantAccountType`. Required if `filterMerchantAccountType` is either: * **includeAccounts** * **excludeAccounts** Not needed for `filterMerchantAccountType`: **allAccounts**.
  --network-type: string@network-type-completer # Network type for Terminal API notification webhooks. Possible values: * **public** * **local** Default Value: **public**.
  --password: string # Password to access the webhook URL.
  --populate-soap-action-header: oneof<nothing, bool> # Indicates if the SOAP action header needs to be populated. Default value: **false**. Only applies if `communicationFormat`: **soap**.
  --ssl-version: string@ssl-version-completer # SSL version to access the public webhook URL specified in the `url` field. Possible values: * **TLSv1.3** * **TLSv1.2** * **HTTP** - Only allowed on Test environment. If not specified, the webhook will use `sslVersion`: **TLSv1.2**.
  type: string # The type of webhook that is being created. Possible values are: - **standard** - **account-settings-notification** - **banktransfer-notification** - **boletobancario-notification** - **directdebit-notification** - **pending-notification** - **ideal-notification** - **ideal-pending-notification** - **report-notification** - **rreq-notification** Find out more about [standard notification webhooks](https://docs.adyen.com/development-resources/webhooks/understand-notifications#event-codes) and [other types of notifications](https://docs.adyen.com/development-resources/webhooks/understand-notifications#other-notifications).
  url: string # Public URL where webhooks will be sent, for example **https://www.domain.com/webhook-endpoint**.
  --username: string # Username to access the webhook URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/webhooks"
    path_params: [{name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptsExpiredCertificate, var: accepts_expired_certificate}, {name: acceptsSelfSignedCertificate, var: accepts_self_signed_certificate}, {name: acceptsUntrustedRootCertificate, var: accepts_untrusted_root_certificate}, {name: active, var: active, required: true}, {name: additionalSettings, var: additional_settings}, {name: communicationFormat, var: communication_format}, {name: description, var: description}, {name: filterMerchantAccountType, var: filter_merchant_account_type}, {name: filterMerchantAccounts, var: filter_merchant_accounts}, {name: networkType, var: network_type}, {name: password, var: password}, {name: populateSoapActionHeader, var: populate_soap_action_header}, {name: sslVersion, var: ssl_version}, {name: type, var: type}, {name: url, var: url}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, accepts_expired_certificate: $accepts_expired_certificate, accepts_self_signed_certificate: $accepts_self_signed_certificate, accepts_untrusted_root_certificate: $accepts_untrusted_root_certificate, active: $active, additional_settings: $additional_settings, communication_format: $communication_format, description: $description, filter_merchant_account_type: $filter_merchant_account_type, filter_merchant_accounts: $filter_merchant_accounts, network_type: $network_type, password: $password, populate_soap_action_header: $populate_soap_action_header, ssl_version: $ssl_version, type: $type, url: $url, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a webhook
#
# DELETE /companies/{companyId}/webhooks/{webhookId}
# operationId: delete-companies-companyId-webhooks-webhookId
export def "delete-companies-company-id-webhooks-webhook-id" [
  company_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/companies/{companyId}/webhooks/{webhookId}"
    path_params: [{name: companyId, var: company_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    company_id: $company_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webhook
#
# GET /companies/{companyId}/webhooks/{webhookId}
# Returns: record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>
# operationId: get-companies-companyId-webhooks-webhookId
export def "get-companies-company-id-webhooks-webhook-id" [
  company_id: string
  webhook_id: string
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
    path: "/companies/{companyId}/webhooks/{webhookId}"
    path_params: [{name: companyId, var: company_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook
#
# PATCH /companies/{companyId}/webhooks/{webhookId}
# Returns: record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>
# operationId: patch-companies-companyId-webhooks-webhookId
export def "patch-companies-company-id-webhooks-webhook-id" [
  company_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepts-expired-certificate: oneof<nothing, bool> # Indicates if expired SSL certificates are accepted. Default value: **false**.
  --accepts-self-signed-certificate: oneof<nothing, bool> # Indicates if self-signed SSL certificates are accepted. Default value: **false**.
  --accepts-untrusted-root-certificate: oneof<nothing, bool> # Indicates if untrusted SSL certificates are accepted. Default value: **false**.
  --active: oneof<nothing, bool> # Indicates if the webhook configuration is active. The field must be **true** for us to send webhooks about events related an account.
  --additional-settings: record # shape: {includeEventCodes?: list<string>, properties?: record}
  --communication-format: string@communication-format-completer # Format or protocol for receiving webhooks. Possible values: * **soap** * **http** * **json**
  --description: string # Your description for this webhook configuration.
  --filter-merchant-account-type: string@filter-merchant-account-type-completer # Shows how merchant accounts are filtered when configuring the webhook. Possible values: * **includeAccounts**: The webhook is configured for the merchant accounts listed in `filterMerchantAccounts`. * **excludeAccounts**: The webhook is not configured for the merchant accounts listed in `filterMerchantAccounts`. * **allAccounts**: Includes all merchant accounts, and does not require specifying `filterMerchantAccounts`.
  --filter-merchant-accounts: list<string> # A list of merchant account names that are included or excluded from receiving the webhook. Inclusion or exclusion is based on the value defined for `filterMerchantAccountType`. Required if `filterMerchantAccountType` is either: * **includeAccounts** * **excludeAccounts** Not needed for `filterMerchantAccountType`: **allAccounts**.
  --network-type: string@network-type-completer # Network type for Terminal API notification webhooks. Possible values: * **public** * **local** Default Value: **public**.
  --password: string # Password to access the webhook URL.
  --populate-soap-action-header: oneof<nothing, bool> # Indicates if the SOAP action header needs to be populated. Default value: **false**. Only applies if `communicationFormat`: **soap**.
  --ssl-version: string@ssl-version-completer # SSL version to access the public webhook URL specified in the `url` field. Possible values: * **TLSv1.3** * **TLSv1.2** * **HTTP** - Only allowed on Test environment. If not specified, the webhook will use `sslVersion`: **TLSv1.2**.
  --url: string # Public URL where webhooks will be sent, for example **https://www.domain.com/webhook-endpoint**.
  --username: string # Username to access the webhook URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/companies/{companyId}/webhooks/{webhookId}"
    path_params: [{name: companyId, var: company_id}, {name: webhookId, var: webhook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptsExpiredCertificate, var: accepts_expired_certificate}, {name: acceptsSelfSignedCertificate, var: accepts_self_signed_certificate}, {name: acceptsUntrustedRootCertificate, var: accepts_untrusted_root_certificate}, {name: active, var: active}, {name: additionalSettings, var: additional_settings}, {name: communicationFormat, var: communication_format}, {name: description, var: description}, {name: filterMerchantAccountType, var: filter_merchant_account_type}, {name: filterMerchantAccounts, var: filter_merchant_accounts}, {name: networkType, var: network_type}, {name: password, var: password}, {name: populateSoapActionHeader, var: populate_soap_action_header}, {name: sslVersion, var: ssl_version}, {name: url, var: url}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, webhook_id: $webhook_id, accepts_expired_certificate: $accepts_expired_certificate, accepts_self_signed_certificate: $accepts_self_signed_certificate, accepts_untrusted_root_certificate: $accepts_untrusted_root_certificate, active: $active, additional_settings: $additional_settings, communication_format: $communication_format, description: $description, filter_merchant_account_type: $filter_merchant_account_type, filter_merchant_accounts: $filter_merchant_accounts, network_type: $network_type, password: $password, populate_soap_action_header: $populate_soap_action_header, ssl_version: $ssl_version, url: $url, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an HMAC key
#
# POST /companies/{companyId}/webhooks/{webhookId}/generateHmac
# Returns: record<hmacKey: string>
# operationId: post-companies-companyId-webhooks-webhookId-generateHmac
export def "post-companies-company-id-webhooks-webhook-id-generate-hmac" [
  company_id: string
  webhook_id: string
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
    method: post
    path: "/companies/{companyId}/webhooks/{webhookId}/generateHmac"
    path_params: [{name: companyId, var: company_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test a webhook
#
# POST /companies/{companyId}/webhooks/{webhookId}/test
# Returns: record<data: table<merchantId: string, output: string, requestSent: string, responseCode: string, responseTime: string, status: string>>
# operationId: post-companies-companyId-webhooks-webhookId-test
export def "post-companies-company-id-webhooks-webhook-id-test" [
  company_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --merchant-ids: list<string> # List of `merchantId` values for which test webhooks will be sent. The list can have a maximum of 20 `merchantId` values. If not specified, we send sample notifications to all the merchant accounts that the webhook is configured for. If this is more than 20 merchant accounts, use this list to specify a subset of the merchant accounts for which to send test notifications.
  --notification: record # shape: {amount?: record, eventCode?: string, eventDate?: string, merchantReference?: string, paymentMethod?: string, reason?: string, success?: bool}
  --types: list<string> # List of event codes for which to send test notifications. Only the webhook types below are supported. Possible values if webhook `type`: **standard**: * **AUTHORISATION** * **CHARGEBACK_REVERSED** * **ORDER_CLOSED** * **ORDER_OPENED** * **PAIDOUT_REVERSED** * **PAYOUT_THIRDPARTY** * **REFUNDED_REVERSED** * **REFUND_WITH_DATA** * **REPORT_AVAILABLE** * **CUSTOM** - set your custom notification fields in the [`notification`](https://docs.adyen.com/api-explorer/#/ManagementService/v1/post/companies/{companyId}/webhooks/{webhookId}/test__reqParam_notification) object. Possible values if webhook `type`: **banktransfer-notification**: * **PENDING** Possible values if webhook `type`: **report-notification**: * **REPORT_AVAILABLE** Possible values if webhook `type`: **ideal-notification**: * **AUTHORISATION** Possible values if webhook `type`: **pending-notification**: * **PENDING**
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/webhooks/{webhookId}/test"
    path_params: [{name: companyId, var: company_id}, {name: webhookId, var: webhook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: merchantIds, var: merchant_ids}, {name: notification, var: notification}, {name: types, var: types}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    company_id: $company_id, webhook_id: $webhook_id, merchant_ids: $merchant_ids, notification: $notification, types: $types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get API credential details
#
# GET /me
# Returns: record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, companyName: string, description: string, id: string, roles: list<string>, username: string>
# operationId: get-me
export def "get-me" [
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
    path: "/me"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get allowed origins
#
# GET /me/allowedOrigins
# Returns: record<data: table<_links: record, domain: string, id: string>>
# operationId: get-me-allowedOrigins
export def "get-me-allowed-origins" [
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
    path: "/me/allowedOrigins"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add allowed origin
#
# POST /me/allowedOrigins
# Returns: record<_links: record<self: record<href: string>>, domain: string, id: string>
# operationId: post-me-allowedOrigins
export def "post-me-allowed-origins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {self: record}
  domain: string # Domain of the allowed origin.
  --id: string # Unique identifier of the allowed origin.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/me/allowedOrigins"
    body: {content_type: "application/json", kind: json, fields: [{name: _links, var: links}, {name: domain, var: domain}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    links: $links, domain: $domain, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove allowed origin
#
# DELETE /me/allowedOrigins/{originId}
# operationId: delete-me-allowedOrigins-originId
export def "delete-me-allowed-origins-origin-id" [
  origin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/me/allowedOrigins/{originId}"
    path_params: [{name: originId, var: origin_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    origin_id: $origin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get allowed origin details
#
# GET /me/allowedOrigins/{originId}
# Returns: record<_links: record<self: record<href: string>>, domain: string, id: string>
# operationId: get-me-allowedOrigins-originId
export def "get-me-allowed-origins-origin-id" [
  origin_id: string
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
    path: "/me/allowedOrigins/{originId}"
    path_params: [{name: originId, var: origin_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    origin_id: $origin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of merchant accounts
#
# GET /merchants
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, captureDelay: string, companyId: string, dataCenters: list, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-merchants
export def "get-merchants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants"
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a merchant account
#
# POST /merchants
# Returns: record<businessLineId: string, companyId: string, description: string, id: string, legalEntityId: string, pricingPlan: string, reference: string>
# operationId: post-merchants
export def "post-merchants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --business-line-id: string # The unique identifier of the [business line](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businessLines). Required for an Adyen for Platforms Manage integration.
  company_id: string # The unique identifier of the company account.
  --description: string # Your description for the merchant account, maximum 300 characters.
  --legal-entity-id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities). Required for an Adyen for Platforms Manage integration.
  --pricing-plan: string # Sets the pricing plan for the merchant account. Required for an Adyen for Platforms Manage integration. Your Adyen contact will provide the values that you can use.
  --reference: string # Your reference for the merchant account. To make this reference the unique identifier of the merchant account, your Adyen contact can set up a template on your company account. The template can have 6 to 255 characters with upper- and lower-case letters, underscores, and numbers. When your company account has a template, then the `reference` is required and must be unique within the company account.
  --sales-channels: list<string> # List of sales channels that the merchant will process payments with
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants"
    body: {content_type: "application/json", kind: json, fields: [{name: businessLineId, var: business_line_id}, {name: companyId, var: company_id}, {name: description, var: description}, {name: legalEntityId, var: legal_entity_id}, {name: pricingPlan, var: pricing_plan}, {name: reference, var: reference}, {name: salesChannels, var: sales_channels}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    business_line_id: $business_line_id, company_id: $company_id, description: $description, legal_entity_id: $legal_entity_id, pricing_plan: $pricing_plan, reference: $reference, sales_channels: $sales_channels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a merchant account
#
# GET /merchants/{merchantId}
# Returns: record<_links: record<apiCredentials: record<href: string>, self: record<href: string>, users: record<href: string>, webhooks: record<href: string>>, captureDelay: string, companyId: string, dataCenters: table<livePrefix: string, name: string>, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string>
# operationId: get-merchants-merchantId
export def "get-merchants-merchant-id" [
  merchant_id: string
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
    path: "/merchants/{merchantId}"
    path_params: [{name: merchantId, var: merchant_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request to activate a merchant account
#
# POST /merchants/{merchantId}/activate
# Returns: record<companyId: string, merchantId: string>
# operationId: post-merchants-merchantId-activate
export def "post-merchants-merchant-id-activate" [
  merchant_id: string
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
    method: post
    path: "/merchants/{merchantId}/activate"
    path_params: [{name: merchantId, var: merchant_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of API credentials
#
# GET /merchants/{merchantId}/apiCredentials
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, active: bool, allowedIpAddresses: list, allowedOrigins: list, clientKey: string, description: string, id: string, roles: list, username: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-merchants-merchantId-apiCredentials
export def "get-merchants-merchant-id-api-credentials" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/apiCredentials"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an API credential
#
# POST /merchants/{merchantId}/apiCredentials
# Returns: record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, apiKey: string, clientKey: string, description: string, id: string, password: string, roles: list<string>, username: string>
# operationId: post-merchants-merchantId-apiCredentials
export def "post-merchants-merchant-id-api-credentials" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-origins: list<string> # The list of [allowed origins](https://docs.adyen.com/development-resources/client-side-authentication#allowed-origins) for the new API credential.
  --description: string # Description of the API credential.
  --roles: list<string> # List of [roles](https://docs.adyen.com/development-resources/api-credentials#roles-1) for the API credential.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/apiCredentials"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowedOrigins, var: allowed_origins}, {name: description, var: description}, {name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, allowed_origins: $allowed_origins, description: $description, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an API credential
#
# GET /merchants/{merchantId}/apiCredentials/{apiCredentialId}
# Returns: record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, clientKey: string, description: string, id: string, roles: list<string>, username: string>
# operationId: get-merchants-merchantId-apiCredentials-apiCredentialId
export def "get-merchants-merchant-id-api-credentials-api-credential-id" [
  merchant_id: string
  api_credential_id: string
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
    path: "/merchants/{merchantId}/apiCredentials/{apiCredentialId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: apiCredentialId, var: api_credential_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, api_credential_id: $api_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an API credential
#
# PATCH /merchants/{merchantId}/apiCredentials/{apiCredentialId}
# Returns: record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, clientKey: string, description: string, id: string, roles: list<string>, username: string>
# operationId: patch-merchants-merchantId-apiCredentials-apiCredentialId
export def "patch-merchants-merchant-id-api-credentials-api-credential-id" [
  merchant_id: string
  api_credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Indicates if the API credential is enabled.
  --allowed-origins: list<string> # The new list of [allowed origins](https://docs.adyen.com/development-resources/client-side-authentication#allowed-origins) for the API credential.
  --description: string # Description of the API credential.
  --roles: list<string> # List of [roles](https://docs.adyen.com/development-resources/api-credentials#roles-1) for the API credential.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/apiCredentials/{apiCredentialId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: apiCredentialId, var: api_credential_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: allowedOrigins, var: allowed_origins}, {name: description, var: description}, {name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, api_credential_id: $api_credential_id, active: $active, allowed_origins: $allowed_origins, description: $description, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of allowed origins
#
# GET /merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins
# Returns: record<data: table<_links: record, domain: string, id: string>>
# operationId: get-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins
export def "get-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins" [
  merchant_id: string
  api_credential_id: string
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
    path: "/merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins"
    path_params: [{name: merchantId, var: merchant_id}, {name: apiCredentialId, var: api_credential_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, api_credential_id: $api_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an allowed origin
#
# POST /merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins
# Returns: record<data: table<_links: record, domain: string, id: string>>
# operationId: post-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins
export def "post-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins" [
  merchant_id: string
  api_credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {self: record}
  domain: string # Domain of the allowed origin.
  --id: string # Unique identifier of the allowed origin.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins"
    path_params: [{name: merchantId, var: merchant_id}, {name: apiCredentialId, var: api_credential_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: _links, var: links}, {name: domain, var: domain}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, api_credential_id: $api_credential_id, links: $links, domain: $domain, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an allowed origin
#
# DELETE /merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}
# operationId: delete-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins-originId
export def "delete-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins-origin-id" [
  merchant_id: string
  api_credential_id: string
  origin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: apiCredentialId, var: api_credential_id}, {name: originId, var: origin_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    merchant_id: $merchant_id, api_credential_id: $api_credential_id, origin_id: $origin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an allowed origin
#
# GET /merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}
# Returns: record<_links: record<self: record<href: string>>, domain: string, id: string>
# operationId: get-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins-originId
export def "get-merchants-merchant-id-api-credentials-api-credential-id-allowed-origins-origin-id" [
  merchant_id: string
  api_credential_id: string
  origin_id: string
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
    path: "/merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: apiCredentialId, var: api_credential_id}, {name: originId, var: origin_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, api_credential_id: $api_credential_id, origin_id: $origin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate new API key
#
# POST /merchants/{merchantId}/apiCredentials/{apiCredentialId}/generateApiKey
# Returns: record<apiKey: string>
# operationId: post-merchants-merchantId-apiCredentials-apiCredentialId-generateApiKey
export def "post-merchants-merchant-id-api-credentials-api-credential-id-generate-api-key" [
  merchant_id: string
  api_credential_id: string
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
    method: post
    path: "/merchants/{merchantId}/apiCredentials/{apiCredentialId}/generateApiKey"
    path_params: [{name: merchantId, var: merchant_id}, {name: apiCredentialId, var: api_credential_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, api_credential_id: $api_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate new client key
#
# POST /merchants/{merchantId}/apiCredentials/{apiCredentialId}/generateClientKey
# Returns: record<clientKey: string>
# operationId: post-merchants-merchantId-apiCredentials-apiCredentialId-generateClientKey
export def "post-merchants-merchant-id-api-credentials-api-credential-id-generate-client-key" [
  merchant_id: string
  api_credential_id: string
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
    method: post
    path: "/merchants/{merchantId}/apiCredentials/{apiCredentialId}/generateClientKey"
    path_params: [{name: merchantId, var: merchant_id}, {name: apiCredentialId, var: api_credential_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, api_credential_id: $api_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of billing entities
#
# GET /merchants/{merchantId}/billingEntities
# Returns: record<data: table<address: record, email: string, id: string, name: string, taxId: string>>
# operationId: get-merchants-merchantId-billingEntities
export def "get-merchants-merchant-id-billing-entities" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the billing entity.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/billingEntities"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all payment methods
#
# GET /merchants/{merchantId}/paymentMethodSettings
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<allowed: bool, applePay: record, bcmc: record, businessLineId: string, cartesBancaires: record, countries: list, currencies: list, customRoutingFlags: list, enabled: bool, giroPay: record, googlePay: record, id: string, klarna: record, mealVoucher_FR: record, paypal: record, reference: string, shopperInteraction: string, sofort: record, storeId: string, swish: record, type: string, verificationStatus: string, vipps: record>, itemsTotal: int, pagesTotal: int, typesWithErrors: list<string>>
# operationId: get-merchants-merchantId-paymentMethodSettings
export def "get-merchants-merchant-id-payment-method-settings" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The unique identifier of the store for which to return the payment methods.
  --business-line-id: string # The unique identifier of the Business Line for which to return the payment methods.
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
  --page-number: int # The number of the page to fetch. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/paymentMethodSettings"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: storeId, var: store_id}, {name: businessLineId, var: business_line_id}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, store_id: $store_id, business_line_id: $business_line_id, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a payment method
#
# POST /merchants/{merchantId}/paymentMethodSettings
# Returns: record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>>
# operationId: post-merchants-merchantId-paymentMethodSettings
export def "post-merchants-merchant-id-payment-method-settings" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apple-pay: record # shape: {domains?: list<string>}
  --bcmc: record # shape: {enableBcmcMobile?: bool}
  --business-line-id: string # The unique identifier of the business line.
  --cartes-bancaires: record # shape: {siret: string}
  --countries: list<string> # The list of countries where a payment method is available. By default, all countries supported by the payment method.
  --currencies: list<string> # The list of currencies that a payment method supports. By default, all currencies supported by the payment method.
  --custom-routing-flags: list<string> # The list of custom routing flags to route payment to the intended acquirer.
  --giro-pay: record # shape: {supportEmail: string}
  --google-pay: record # shape: {merchantId: string, reuseMerchantId?: bool}
  --klarna: record # shape: {autoCapture?: bool, disputeEmail: string, region?: "NA"|"EU"|"CH"|"AU", supportEmail: string}
  --meal-voucher-fr: record # shape: {conecsId: string, siret: string, subTypes: list<string>}
  --paypal: record # shape: {directCapture?: bool, payerId: string, subject: string}
  --reference: string # Your reference for the payment method. Supported characters a-z, A-Z, 0-9.
  --shopper-interaction: string@shopper-interaction-completer # The sales channel. Required if the merchant account does not have a sales channel. When you provide this field, it overrides the default sales channel set on the merchant account. Possible values: **eCommerce**, **pos**, **contAuth**, and **moto**.
  --sofort: record # shape: {currencyCode: string, logo: string}
  --store-id: string # The ID of the [store](https://docs.adyen.com/api-explorer/#/ManagementService/latest/post/stores__resParam_id), if any.
  --swish: record # shape: {swishNumber?: string}
  --type: string@type-completer # Payment method [variant](https://docs.adyen.com/development-resources/paymentmethodvariant#management-api).
  --vipps: record # shape: {logo: string, subscriptionCancelUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/paymentMethodSettings"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: applePay, var: apple_pay}, {name: bcmc, var: bcmc}, {name: businessLineId, var: business_line_id}, {name: cartesBancaires, var: cartes_bancaires}, {name: countries, var: countries}, {name: currencies, var: currencies}, {name: customRoutingFlags, var: custom_routing_flags}, {name: giroPay, var: giro_pay}, {name: googlePay, var: google_pay}, {name: klarna, var: klarna}, {name: mealVoucher_FR, var: meal_voucher_fr}, {name: paypal, var: paypal}, {name: reference, var: reference}, {name: shopperInteraction, var: shopper_interaction}, {name: sofort, var: sofort}, {name: storeId, var: store_id}, {name: swish, var: swish}, {name: type, var: type}, {name: vipps, var: vipps}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, apple_pay: $apple_pay, bcmc: $bcmc, business_line_id: $business_line_id, cartes_bancaires: $cartes_bancaires, countries: $countries, currencies: $currencies, custom_routing_flags: $custom_routing_flags, giro_pay: $giro_pay, google_pay: $google_pay, klarna: $klarna, meal_voucher_fr: $meal_voucher_fr, paypal: $paypal, reference: $reference, shopper_interaction: $shopper_interaction, sofort: $sofort, store_id: $store_id, swish: $swish, type: $type, vipps: $vipps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payment method details
#
# GET /merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}
# Returns: record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>>
# operationId: get-merchants-merchantId-paymentMethodSettings-paymentMethodId
export def "get-merchants-merchant-id-payment-method-settings-payment-method-id" [
  merchant_id: string
  payment_method_id: string
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
    path: "/merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a payment method
#
# PATCH /merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}
# Returns: record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>>
# operationId: patch-merchants-merchantId-paymentMethodSettings-paymentMethodId
export def "patch-merchants-merchant-id-payment-method-settings-payment-method-id" [
  merchant_id: string
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --countries: list<string> # The list of countries where a payment method is available. By default, all countries supported by the payment method.
  --currencies: list<string> # The list of currencies that a payment method supports. By default, all currencies supported by the payment method.
  --custom-routing-flags: list<string> # Custom routing flags for acquirer routing.
  --enabled: oneof<nothing, bool> # Indicates whether the payment method is enabled (**true**) or disabled (**false**).
  --shopper-statement: record # shape: {doingBusinessAsName?: string, type?: "append"|"dynamic"|"fixed"}
  --store-ids: list<string> # The list of stores for this payment method
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: paymentMethodId, var: payment_method_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: countries, var: countries}, {name: currencies, var: currencies}, {name: customRoutingFlags, var: custom_routing_flags}, {name: enabled, var: enabled}, {name: shopperStatement, var: shopper_statement}, {name: storeIds, var: store_ids}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, payment_method_id: $payment_method_id, countries: $countries, currencies: $currencies, custom_routing_flags: $custom_routing_flags, enabled: $enabled, shopper_statement: $shopper_statement, store_ids: $store_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an Apple Pay domain
#
# POST /merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}/addApplePayDomains
# operationId: post-merchants-merchantId-paymentMethodSettings-paymentMethodId-addApplePayDomains
export def "post-merchants-merchant-id-payment-method-settings-payment-method-id-add-apple-pay-domains" [
  merchant_id: string
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domains: list<string> # The list of merchant domains. Maximum: 99 domains per request. For more information, see [Apple Pay documentation](https://docs.adyen.com/payment-methods/apple-pay/web-drop-in?tab=adyen-certificate-live_1#going-live).
]: any -> any {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}/addApplePayDomains"
    path_params: [{name: merchantId, var: merchant_id}, {name: paymentMethodId, var: payment_method_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: domains, var: domains}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    merchant_id: $merchant_id, payment_method_id: $payment_method_id, domains: $domains
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Apple Pay domains
#
# GET /merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}/getApplePayDomains
# Returns: record<domains: list<string>>
# operationId: get-merchants-merchantId-paymentMethodSettings-paymentMethodId-getApplePayDomains
export def "get-merchants-merchant-id-payment-method-settings-payment-method-id-get-apple-pay-domains" [
  merchant_id: string
  payment_method_id: string
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
    path: "/merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}/getApplePayDomains"
    path_params: [{name: merchantId, var: merchant_id}, {name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of payout settings
#
# GET /merchants/{merchantId}/payoutSettings
# Returns: record<data: table<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>>
# operationId: get-merchants-merchantId-payoutSettings
export def "get-merchants-merchant-id-payout-settings" [
  merchant_id: string
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
    path: "/merchants/{merchantId}/payoutSettings"
    path_params: [{name: merchantId, var: merchant_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a payout setting
#
# POST /merchants/{merchantId}/payoutSettings
# Returns: record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>
# operationId: post-merchants-merchantId-payoutSettings
export def "post-merchants-merchant-id-payout-settings" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Indicates if payouts to this bank account are enabled. Default: **true**. To receive payouts into this bank account, both `enabled` and `allowed` must be **true**.
  --enabled-from-date: string # The date when Adyen starts paying out to this bank account. Format: [ISO 8601](https://www.w3.org/TR/NOTE-datetime), for example, **2019-11-23T12:25:28Z** or **2020-05-27T20:25:28+08:00**. If not specified, the `enabled` field indicates if payouts are enabled for this bank account. If a date is specified and: * `enabled`: **true**, payouts are enabled starting the specified date. * `enabled`: **false**, payouts are disabled until the specified date. On the specified date, `enabled` changes to **true** and this field is reset to **null**.
  transfer_instrument_id: string # The unique identifier of the [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments) that contains the details of the bank account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/payoutSettings"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: enabledFromDate, var: enabled_from_date}, {name: transferInstrumentId, var: transfer_instrument_id}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, enabled: $enabled, enabled_from_date: $enabled_from_date, transfer_instrument_id: $transfer_instrument_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a payout setting
#
# DELETE /merchants/{merchantId}/payoutSettings/{payoutSettingsId}
# operationId: delete-merchants-merchantId-payoutSettings-payoutSettingsId
export def "delete-merchants-merchant-id-payout-settings-payout-settings-id" [
  merchant_id: string
  payout_settings_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/merchants/{merchantId}/payoutSettings/{payoutSettingsId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: payoutSettingsId, var: payout_settings_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    merchant_id: $merchant_id, payout_settings_id: $payout_settings_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a payout setting
#
# GET /merchants/{merchantId}/payoutSettings/{payoutSettingsId}
# Returns: record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>
# operationId: get-merchants-merchantId-payoutSettings-payoutSettingsId
export def "get-merchants-merchant-id-payout-settings-payout-settings-id" [
  merchant_id: string
  payout_settings_id: string
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
    path: "/merchants/{merchantId}/payoutSettings/{payoutSettingsId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: payoutSettingsId, var: payout_settings_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, payout_settings_id: $payout_settings_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a payout setting
#
# PATCH /merchants/{merchantId}/payoutSettings/{payoutSettingsId}
# Returns: record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>
# operationId: patch-merchants-merchantId-payoutSettings-payoutSettingsId
export def "patch-merchants-merchant-id-payout-settings-payout-settings-id" [
  merchant_id: string
  payout_settings_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Indicates if payouts to this bank account are enabled. Default: **true**. To receive payouts into this bank account, both `enabled` and `allowed` must be **true**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/payoutSettings/{payoutSettingsId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: payoutSettingsId, var: payout_settings_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, payout_settings_id: $payout_settings_id, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of shipping locations
#
# GET /merchants/{merchantId}/shippingLocations
# Returns: record<data: table<address: record, contact: record, id: string, name: string>>
# operationId: get-merchants-merchantId-shippingLocations
export def "get-merchants-merchant-id-shipping-locations" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the shipping location.
  --offset: int # The number of locations to skip. (format: int32)
  --limit: int # The number of locations to return. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/shippingLocations"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: name, var: name}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, name: $name, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a shipping location
#
# POST /merchants/{merchantId}/shippingLocations
# Returns: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>
# operationId: post-merchants-merchantId-shippingLocations
export def "post-merchants-merchant-id-shipping-locations" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {city?: string, companyName?: string, country?: string, postalCode?: string, stateOrProvince?: string, streetAddress?: string, streetAddress2?: string}
  --contact: record # shape: {email?: string, firstName?: string, infix?: string, lastName?: string, phoneNumber?: string}
  --id: string # The unique identifier of the shipping location, for use as `shippingLocationId` when creating an order.
  --name: string # The unique name of the shipping location.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/shippingLocations"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: contact, var: contact}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, address: $address, contact: $contact, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of stores
#
# GET /merchants/{merchantId}/stores
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, address: record, businessLineIds: list, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record, status: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-merchants-merchantId-stores
export def "get-merchants-merchant-id-stores" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
  --reference: string # The reference of the store.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/stores"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: reference, var: reference}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, page_number: $page_number, page_size: $page_size, reference: $reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a store
#
# POST /merchants/{merchantId}/stores
# Returns: record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>
# operationId: post-merchants-merchantId-stores
export def "post-merchants-merchant-id-stores" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # shape: {city?: string, country: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
  --business-line-ids: list<string> # The unique identifiers of the [business lines](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businesslines__resParam_id) that the store is associated with. If not specified, the business line of the merchant account is used. Required when there are multiple business lines under the merchant account.
  description: string # Your description of the store.
  --external-reference-id: string # When using the Zip payment method: The location ID that Zip has assigned to your store.
  phone_number: string # The phone number of the store, including '+' and country code.
  --reference: string # Your reference to recognize the store by. Also known as the store code. Allowed characters: Lowercase and uppercase letters without diacritics, numbers 0 through 9, hyphen (-), and underscore (_).
  shopper_statement: string # The store name to be shown on the shopper's bank or credit card statement and on the shopper receipt. Maximum length: 22 characters; can't be all numbers.
  --split-configuration: record # shape: {balanceAccountId?: string, splitConfigurationId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/stores"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: businessLineIds, var: business_line_ids}, {name: description, var: description}, {name: externalReferenceId, var: external_reference_id}, {name: phoneNumber, var: phone_number}, {name: reference, var: reference}, {name: shopperStatement, var: shopper_statement}, {name: splitConfiguration, var: split_configuration}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, address: $address, business_line_ids: $business_line_ids, description: $description, external_reference_id: $external_reference_id, phone_number: $phone_number, reference: $reference, shopper_statement: $shopper_statement, split_configuration: $split_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the terminal logo
#
# GET /merchants/{merchantId}/stores/{reference}/terminalLogos
# Returns: record<data: string>
# operationId: get-merchants-merchantId-stores-reference-terminalLogos
export def "get-merchants-merchant-id-stores-reference-terminal-logos" [
  merchant_id: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/stores/{reference}/terminalLogos"
    path_params: [{name: merchantId, var: merchant_id}, {name: reference, var: reference}]
    query: [{name: model, var: model, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, reference: $reference, model: $model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the terminal logo
#
# PATCH /merchants/{merchantId}/stores/{reference}/terminalLogos
# Returns: record<data: string>
# operationId: patch-merchants-merchantId-stores-reference-terminalLogos
export def "patch-merchants-merchant-id-stores-reference-terminal-logos" [
  merchant_id: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T (required)
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/stores/{reference}/terminalLogos"
    path_params: [{name: merchantId, var: merchant_id}, {name: reference, var: reference}]
    query: [{name: model, var: model, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, reference: $reference, model: $model, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get terminal settings
#
# GET /merchants/{merchantId}/stores/{reference}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: get-merchants-merchantId-stores-reference-terminalSettings
export def "get-merchants-merchant-id-stores-reference-terminal-settings" [
  merchant_id: string
  reference: string
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
    path: "/merchants/{merchantId}/stores/{reference}/terminalSettings"
    path_params: [{name: merchantId, var: merchant_id}, {name: reference, var: reference}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, reference: $reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update terminal settings
#
# PATCH /merchants/{merchantId}/stores/{reference}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: patch-merchants-merchantId-stores-reference-terminalSettings
export def "patch-merchants-merchant-id-stores-reference-terminal-settings" [
  merchant_id: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholder-receipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list<string>, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list<string>}
  --offline-processing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --pay-at-table: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list<string>}
  --receipt-options: record # shape: {logo?: string, qrCodeData?: string}
  --receipt-printing: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifi-profiles: record # shape: {profiles?: list, settings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/stores/{reference}/terminalSettings"
    path_params: [{name: merchantId, var: merchant_id}, {name: reference, var: reference}]
    body: {content_type: "application/json", kind: json, fields: [{name: cardholderReceipt, var: cardholder_receipt}, {name: connectivity, var: connectivity}, {name: gratuities, var: gratuities}, {name: hardware, var: hardware}, {name: nexo, var: nexo}, {name: offlineProcessing, var: offline_processing}, {name: opi, var: opi}, {name: passcodes, var: passcodes}, {name: payAtTable, var: pay_at_table}, {name: payment, var: payment}, {name: receiptOptions, var: receipt_options}, {name: receiptPrinting, var: receipt_printing}, {name: signature, var: signature}, {name: standalone, var: standalone}, {name: surcharge, var: surcharge}, {name: timeouts, var: timeouts}, {name: wifiProfiles, var: wifi_profiles}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, reference: $reference, cardholder_receipt: $cardholder_receipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offline_processing: $offline_processing, opi: $opi, passcodes: $passcodes, pay_at_table: $pay_at_table, payment: $payment, receipt_options: $receipt_options, receipt_printing: $receipt_printing, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifi_profiles: $wifi_profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a store
#
# GET /merchants/{merchantId}/stores/{storeId}
# Returns: record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>
# operationId: get-merchants-merchantId-stores-storeId
export def "get-merchants-merchant-id-stores-store-id" [
  merchant_id: string
  store_id: string
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
    path: "/merchants/{merchantId}/stores/{storeId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a store
#
# PATCH /merchants/{merchantId}/stores/{storeId}
# Returns: record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>
# operationId: patch-merchants-merchantId-stores-storeId
export def "patch-merchants-merchant-id-stores-store-id" [
  merchant_id: string
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {city?: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
  --business-line-ids: list<string> # The unique identifiers of the [business lines](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businesslines__resParam_id) that the store is associated with.
  --description: string # The description of the store.
  --external-reference-id: string # When using the Zip payment method: The location ID that Zip has assigned to your store.
  --split-configuration: record # shape: {balanceAccountId?: string, splitConfigurationId?: string}
  --status: string@status-completer # The status of the store. Possible values are: - **active**: This value is assigned automatically when a store is created. - **inactive**: The maximum [transaction limits and number of Store-and-Forward transactions](https://docs.adyen.com/point-of-sale/determine-account-structure/configure-features#payment-features) for the store are set to 0. This blocks new transactions, but captures are still possible. - **closed**: The terminals of the store are reassigned to the merchant inventory, so they can't process payments. You can change the status from **active** to **inactive**, and from **inactive** to **active** or **closed**. Once **closed**, a store can't be reopened.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/stores/{storeId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: businessLineIds, var: business_line_ids}, {name: description, var: description}, {name: externalReferenceId, var: external_reference_id}, {name: splitConfiguration, var: split_configuration}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, store_id: $store_id, address: $address, business_line_ids: $business_line_ids, description: $description, external_reference_id: $external_reference_id, split_configuration: $split_configuration, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the terminal logo
#
# GET /merchants/{merchantId}/terminalLogos
# Returns: record<data: string>
# operationId: get-merchants-merchantId-terminalLogos
export def "get-merchants-merchant-id-terminal-logos" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/terminalLogos"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: model, var: model, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, model: $model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the terminal logo
#
# PATCH /merchants/{merchantId}/terminalLogos
# Returns: record<data: string>
# operationId: patch-merchants-merchantId-terminalLogos
export def "patch-merchants-merchant-id-terminal-logos" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Allowed values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T. (required)
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/terminalLogos"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: model, var: model, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, model: $model, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of terminal models
#
# GET /merchants/{merchantId}/terminalModels
# Returns: record<data: table<id: string, name: string>>
# operationId: get-merchants-merchantId-terminalModels
export def "get-merchants-merchant-id-terminal-models" [
  merchant_id: string
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
    path: "/merchants/{merchantId}/terminalModels"
    path_params: [{name: merchantId, var: merchant_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of orders
#
# GET /merchants/{merchantId}/terminalOrders
# Returns: record<data: table<billingEntity: record, customerOrderReference: string, id: string, items: list, orderDate: string, shippingLocation: record, status: string, trackingUrl: string>>
# operationId: get-merchants-merchantId-terminalOrders
export def "get-merchants-merchant-id-terminal-orders" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-order-reference: string # Your purchase order number.
  --status: string # The order status. Possible values (not case-sensitive): Placed, Confirmed, Cancelled, Shipped, Delivered.
  --offset: int # The number of orders to skip. (format: int32)
  --limit: int # The number of orders to return. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/terminalOrders"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: customerOrderReference, var: customer_order_reference}, {name: status, var: status}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, customer_order_reference: $customer_order_reference, status: $status, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an order
#
# POST /merchants/{merchantId}/terminalOrders
# Returns: record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>
# operationId: post-merchants-merchantId-terminalOrders
export def "post-merchants-merchant-id-terminal-orders" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-entity-id: string # The identification of the billing entity to use for the order.
  --customer-order-reference: string # The merchant-defined purchase order reference.
  --items: list # The products included in the order. — item shape: {id?: string, installments?: int, name?: string, quantity?: int}
  --shipping-location-id: string # The identification of the shipping location to use for the order.
  --tax-id: string # The tax number of the billing entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/terminalOrders"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingEntityId, var: billing_entity_id}, {name: customerOrderReference, var: customer_order_reference}, {name: items, var: items}, {name: shippingLocationId, var: shipping_location_id}, {name: taxId, var: tax_id}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, billing_entity_id: $billing_entity_id, customer_order_reference: $customer_order_reference, items: $items, shipping_location_id: $shipping_location_id, tax_id: $tax_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an order
#
# GET /merchants/{merchantId}/terminalOrders/{orderId}
# Returns: record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>
# operationId: get-merchants-merchantId-terminalOrders-orderId
export def "get-merchants-merchant-id-terminal-orders-order-id" [
  merchant_id: string
  order_id: string
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
    path: "/merchants/{merchantId}/terminalOrders/{orderId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an order
#
# PATCH /merchants/{merchantId}/terminalOrders/{orderId}
# Returns: record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>
# operationId: patch-merchants-merchantId-terminalOrders-orderId
export def "patch-merchants-merchant-id-terminal-orders-order-id" [
  merchant_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-entity-id: string # The identification of the billing entity to use for the order.
  --customer-order-reference: string # The merchant-defined purchase order reference.
  --items: list # The products included in the order. — item shape: {id?: string, installments?: int, name?: string, quantity?: int}
  --shipping-location-id: string # The identification of the shipping location to use for the order.
  --tax-id: string # The tax number of the billing entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/terminalOrders/{orderId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingEntityId, var: billing_entity_id}, {name: customerOrderReference, var: customer_order_reference}, {name: items, var: items}, {name: shippingLocationId, var: shipping_location_id}, {name: taxId, var: tax_id}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, order_id: $order_id, billing_entity_id: $billing_entity_id, customer_order_reference: $customer_order_reference, items: $items, shipping_location_id: $shipping_location_id, tax_id: $tax_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an order
#
# POST /merchants/{merchantId}/terminalOrders/{orderId}/cancel
# Returns: record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string>
# operationId: post-merchants-merchantId-terminalOrders-orderId-cancel
export def "post-merchants-merchant-id-terminal-orders-order-id-cancel" [
  merchant_id: string
  order_id: string
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
    method: post
    path: "/merchants/{merchantId}/terminalOrders/{orderId}/cancel"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of terminal products
#
# GET /merchants/{merchantId}/terminalProducts
# Returns: record<data: table<description: string, id: string, itemsIncluded: list, name: string, price: record>>
# operationId: get-merchants-merchantId-terminalProducts
export def "get-merchants-merchant-id-terminal-products" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # The country to return products for, in [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) format. For example, **US** (required)
  --terminal-model-id: string # The terminal model to return products for. Use the ID returned in the [GET `/terminalModels`](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/merchants/{merchantId}/terminalModels) response. For example, **Verifone.M400**
  --offset: int # The number of products to skip. (format: int32)
  --limit: int # The number of products to return. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/terminalProducts"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: country, var: country, required: true}, {name: terminalModelId, var: terminal_model_id}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, country: $country, terminal_model_id: $terminal_model_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get terminal settings
#
# GET /merchants/{merchantId}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: get-merchants-merchantId-terminalSettings
export def "get-merchants-merchant-id-terminal-settings" [
  merchant_id: string
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
    path: "/merchants/{merchantId}/terminalSettings"
    path_params: [{name: merchantId, var: merchant_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update terminal settings
#
# PATCH /merchants/{merchantId}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: patch-merchants-merchantId-terminalSettings
export def "patch-merchants-merchant-id-terminal-settings" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholder-receipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list<string>, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list<string>}
  --offline-processing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --pay-at-table: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list<string>}
  --receipt-options: record # shape: {logo?: string, qrCodeData?: string}
  --receipt-printing: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifi-profiles: record # shape: {profiles?: list, settings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/terminalSettings"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cardholderReceipt, var: cardholder_receipt}, {name: connectivity, var: connectivity}, {name: gratuities, var: gratuities}, {name: hardware, var: hardware}, {name: nexo, var: nexo}, {name: offlineProcessing, var: offline_processing}, {name: opi, var: opi}, {name: passcodes, var: passcodes}, {name: payAtTable, var: pay_at_table}, {name: payment, var: payment}, {name: receiptOptions, var: receipt_options}, {name: receiptPrinting, var: receipt_printing}, {name: signature, var: signature}, {name: standalone, var: standalone}, {name: surcharge, var: surcharge}, {name: timeouts, var: timeouts}, {name: wifiProfiles, var: wifi_profiles}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, cardholder_receipt: $cardholder_receipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offline_processing: $offline_processing, opi: $opi, passcodes: $passcodes, pay_at_table: $pay_at_table, payment: $payment, receipt_options: $receipt_options, receipt_printing: $receipt_printing, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifi_profiles: $wifi_profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of users
#
# GET /merchants/{merchantId}/users
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, accountGroups: list, active: bool, authnApps: list, email: string, id: string, name: record, roles: list, timeZoneCode: string, username: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-merchants-merchantId-users
export def "get-merchants-merchant-id-users" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page. Maximum value is **100**. The default is **10** items on a page. (format: int32)
  --username: string # The partial or complete username to select all users that match.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/users"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, page_number: $page_number, page_size: $page_size, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user
#
# POST /merchants/{merchantId}/users
# Returns: record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>
# operationId: post-merchants-merchantId-users
export def "post-merchants-merchant-id-users" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-groups: list<string> # The list of [account groups](https://docs.adyen.com/account/account-structure#account-groups) associated with this user.
  --authn-apps: list<string> # Set of authn apps to add to this user
  email: string # The email address of the user.
  name: record # shape: {firstName: string, lastName: string}
  --roles: list<string> # The list of [roles](https://docs.adyen.com/account/user-roles) for this user.
  --time-zone-code: string # The [tz database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the time zone of the user. For example, **Europe/Amsterdam**.
  username: string # The username for this user. Allowed length: 255 alphanumeric characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/users"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountGroups, var: account_groups}, {name: authnApps, var: authn_apps}, {name: email, var: email}, {name: name, var: name}, {name: roles, var: roles}, {name: timeZoneCode, var: time_zone_code}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, account_groups: $account_groups, authn_apps: $authn_apps, email: $email, name: $name, roles: $roles, time_zone_code: $time_zone_code, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user details
#
# GET /merchants/{merchantId}/users/{userId}
# Returns: record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>
# operationId: get-merchants-merchantId-users-userId
export def "get-merchants-merchant-id-users-user-id" [
  merchant_id: string
  user_id: string
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
    path: "/merchants/{merchantId}/users/{userId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user
#
# PATCH /merchants/{merchantId}/users/{userId}
# Returns: record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string>
# operationId: patch-merchants-merchantId-users-userId
export def "patch-merchants-merchant-id-users-user-id" [
  merchant_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-groups: list<string> # The list of [account groups](https://docs.adyen.com/account/account-structure#account-groups) associated with this user.
  --active: oneof<nothing, bool> # Sets the status of the user to active (**true**) or inactive (**false**).
  --authn-apps-to-add: list<string> # Set of authn apps to add to this user
  --authn-apps-to-remove: list<string> # Set of authn apps to remove from this user
  --email: string # The email address of the user.
  --name: record # shape: {firstName?: string, lastName?: string}
  --roles: list<string> # The list of [roles](https://docs.adyen.com/account/user-roles) for this user.
  --time-zone-code: string # The [tz database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the time zone of the user. For example, **Europe/Amsterdam**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/users/{userId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountGroups, var: account_groups}, {name: active, var: active}, {name: authnAppsToAdd, var: authn_apps_to_add}, {name: authnAppsToRemove, var: authn_apps_to_remove}, {name: email, var: email}, {name: name, var: name}, {name: roles, var: roles}, {name: timeZoneCode, var: time_zone_code}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, user_id: $user_id, account_groups: $account_groups, active: $active, authn_apps_to_add: $authn_apps_to_add, authn_apps_to_remove: $authn_apps_to_remove, email: $email, name: $name, roles: $roles, time_zone_code: $time_zone_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all webhooks
#
# GET /merchants/{merchantId}/webhooks
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, accountReference: string, data: table<_links: record, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-merchants-merchantId-webhooks
export def "get-merchants-merchant-id-webhooks" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/merchants/{merchantId}/webhooks"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set up a webhook
#
# POST /merchants/{merchantId}/webhooks
# Returns: record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>
# operationId: post-merchants-merchantId-webhooks
export def "post-merchants-merchant-id-webhooks" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepts-expired-certificate: oneof<nothing, bool> # Indicates if expired SSL certificates are accepted. Default value: **false**.
  --accepts-self-signed-certificate: oneof<nothing, bool> # Indicates if self-signed SSL certificates are accepted. Default value: **false**.
  --accepts-untrusted-root-certificate: oneof<nothing, bool> # Indicates if untrusted SSL certificates are accepted. Default value: **false**.
  --active: oneof<nothing, bool> # Indicates if the webhook configuration is active. The field must be **true** for us to send webhooks about events related an account.
  --additional-settings: record # shape: {includeEventCodes?: list<string>, properties?: record}
  communication_format: string@communication-format-completer # Format or protocol for receiving webhooks. Possible values: * **soap** * **http** * **json**
  --description: string # Your description for this webhook configuration.
  --network-type: string@network-type-completer # Network type for Terminal API notification webhooks. Possible values: * **public** * **local** Default Value: **public**.
  --password: string # Password to access the webhook URL.
  --populate-soap-action-header: oneof<nothing, bool> # Indicates if the SOAP action header needs to be populated. Default value: **false**. Only applies if `communicationFormat`: **soap**.
  --ssl-version: string@ssl-version-completer # SSL version to access the public webhook URL specified in the `url` field. Possible values: * **TLSv1.3** * **TLSv1.2** * **HTTP** - Only allowed on Test environment. If not specified, the webhook will use `sslVersion`: **TLSv1.2**.
  type: string # The type of webhook that is being created. Possible values are: - **standard** - **account-settings-notification** - **banktransfer-notification** - **boletobancario-notification** - **directdebit-notification** - **pending-notification** - **ideal-notification** - **ideal-pending-notification** - **report-notification** - **rreq-notification** Find out more about [standard notification webhooks](https://docs.adyen.com/development-resources/webhooks/understand-notifications#event-codes) and [other types of notifications](https://docs.adyen.com/development-resources/webhooks/understand-notifications#other-notifications).
  url: string # Public URL where webhooks will be sent, for example **https://www.domain.com/webhook-endpoint**.
  --username: string # Username to access the webhook URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/webhooks"
    path_params: [{name: merchantId, var: merchant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptsExpiredCertificate, var: accepts_expired_certificate}, {name: acceptsSelfSignedCertificate, var: accepts_self_signed_certificate}, {name: acceptsUntrustedRootCertificate, var: accepts_untrusted_root_certificate}, {name: active, var: active, required: true}, {name: additionalSettings, var: additional_settings}, {name: communicationFormat, var: communication_format}, {name: description, var: description}, {name: networkType, var: network_type}, {name: password, var: password}, {name: populateSoapActionHeader, var: populate_soap_action_header}, {name: sslVersion, var: ssl_version}, {name: type, var: type}, {name: url, var: url}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, accepts_expired_certificate: $accepts_expired_certificate, accepts_self_signed_certificate: $accepts_self_signed_certificate, accepts_untrusted_root_certificate: $accepts_untrusted_root_certificate, active: $active, additional_settings: $additional_settings, communication_format: $communication_format, description: $description, network_type: $network_type, password: $password, populate_soap_action_header: $populate_soap_action_header, ssl_version: $ssl_version, type: $type, url: $url, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a webhook
#
# DELETE /merchants/{merchantId}/webhooks/{webhookId}
# operationId: delete-merchants-merchantId-webhooks-webhookId
export def "delete-merchants-merchant-id-webhooks-webhook-id" [
  merchant_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/merchants/{merchantId}/webhooks/{webhookId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    merchant_id: $merchant_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webhook
#
# GET /merchants/{merchantId}/webhooks/{webhookId}
# Returns: record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>
# operationId: get-merchants-merchantId-webhooks-webhookId
export def "get-merchants-merchant-id-webhooks-webhook-id" [
  merchant_id: string
  webhook_id: string
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
    path: "/merchants/{merchantId}/webhooks/{webhookId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook
#
# PATCH /merchants/{merchantId}/webhooks/{webhookId}
# Returns: record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>
# operationId: patch-merchants-merchantId-webhooks-webhookId
export def "patch-merchants-merchant-id-webhooks-webhook-id" [
  merchant_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepts-expired-certificate: oneof<nothing, bool> # Indicates if expired SSL certificates are accepted. Default value: **false**.
  --accepts-self-signed-certificate: oneof<nothing, bool> # Indicates if self-signed SSL certificates are accepted. Default value: **false**.
  --accepts-untrusted-root-certificate: oneof<nothing, bool> # Indicates if untrusted SSL certificates are accepted. Default value: **false**.
  --active: oneof<nothing, bool> # Indicates if the webhook configuration is active. The field must be **true** for us to send webhooks about events related an account.
  --additional-settings: record # shape: {includeEventCodes?: list<string>, properties?: record}
  --communication-format: string@communication-format-completer # Format or protocol for receiving webhooks. Possible values: * **soap** * **http** * **json**
  --description: string # Your description for this webhook configuration.
  --network-type: string@network-type-completer # Network type for Terminal API notification webhooks. Possible values: * **public** * **local** Default Value: **public**.
  --password: string # Password to access the webhook URL.
  --populate-soap-action-header: oneof<nothing, bool> # Indicates if the SOAP action header needs to be populated. Default value: **false**. Only applies if `communicationFormat`: **soap**.
  --ssl-version: string@ssl-version-completer # SSL version to access the public webhook URL specified in the `url` field. Possible values: * **TLSv1.3** * **TLSv1.2** * **HTTP** - Only allowed on Test environment. If not specified, the webhook will use `sslVersion`: **TLSv1.2**.
  --url: string # Public URL where webhooks will be sent, for example **https://www.domain.com/webhook-endpoint**.
  --username: string # Username to access the webhook URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/merchants/{merchantId}/webhooks/{webhookId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: webhookId, var: webhook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptsExpiredCertificate, var: accepts_expired_certificate}, {name: acceptsSelfSignedCertificate, var: accepts_self_signed_certificate}, {name: acceptsUntrustedRootCertificate, var: accepts_untrusted_root_certificate}, {name: active, var: active}, {name: additionalSettings, var: additional_settings}, {name: communicationFormat, var: communication_format}, {name: description, var: description}, {name: networkType, var: network_type}, {name: password, var: password}, {name: populateSoapActionHeader, var: populate_soap_action_header}, {name: sslVersion, var: ssl_version}, {name: url, var: url}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, webhook_id: $webhook_id, accepts_expired_certificate: $accepts_expired_certificate, accepts_self_signed_certificate: $accepts_self_signed_certificate, accepts_untrusted_root_certificate: $accepts_untrusted_root_certificate, active: $active, additional_settings: $additional_settings, communication_format: $communication_format, description: $description, network_type: $network_type, password: $password, populate_soap_action_header: $populate_soap_action_header, ssl_version: $ssl_version, url: $url, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an HMAC key
#
# POST /merchants/{merchantId}/webhooks/{webhookId}/generateHmac
# Returns: record<hmacKey: string>
# operationId: post-merchants-merchantId-webhooks-webhookId-generateHmac
export def "post-merchants-merchant-id-webhooks-webhook-id-generate-hmac" [
  merchant_id: string
  webhook_id: string
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
    method: post
    path: "/merchants/{merchantId}/webhooks/{webhookId}/generateHmac"
    path_params: [{name: merchantId, var: merchant_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test a webhook
#
# POST /merchants/{merchantId}/webhooks/{webhookId}/test
# Returns: record<data: table<merchantId: string, output: string, requestSent: string, responseCode: string, responseTime: string, status: string>>
# operationId: post-merchants-merchantId-webhooks-webhookId-test
export def "post-merchants-merchant-id-webhooks-webhook-id-test" [
  merchant_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification: record # shape: {amount?: record, eventCode?: string, eventDate?: string, merchantReference?: string, paymentMethod?: string, reason?: string, success?: bool}
  --types: list<string> # List of event codes for which to send test notifications. Only the webhook types below are supported. Possible values if webhook `type`: **standard**: * **AUTHORISATION** * **CHARGEBACK_REVERSED** * **ORDER_CLOSED** * **ORDER_OPENED** * **PAIDOUT_REVERSED** * **PAYOUT_THIRDPARTY** * **REFUNDED_REVERSED** * **REFUND_WITH_DATA** * **REPORT_AVAILABLE** * **CUSTOM** - set your custom notification fields in the [`notification`](https://docs.adyen.com/api-explorer/#/ManagementService/v1/post/companies/{companyId}/webhooks/{webhookId}/test__reqParam_notification) object. Possible values if webhook `type`: **banktransfer-notification**: * **PENDING** Possible values if webhook `type`: **report-notification**: * **REPORT_AVAILABLE** Possible values if webhook `type`: **ideal-notification**: * **AUTHORISATION** Possible values if webhook `type`: **pending-notification**: * **PENDING**
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchants/{merchantId}/webhooks/{webhookId}/test"
    path_params: [{name: merchantId, var: merchant_id}, {name: webhookId, var: webhook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: notification, var: notification}, {name: types, var: types}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    merchant_id: $merchant_id, webhook_id: $webhook_id, notification: $notification, types: $types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of stores
#
# GET /stores
# Returns: record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, address: record, businessLineIds: list, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record, status: string>, itemsTotal: int, pagesTotal: int>
# operationId: get-stores
export def "get-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
  --reference: string # The reference of the store.
  --merchant-id: string # The unique identifier of the merchant account.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stores"
    query: [{name: pageNumber, var: page_number}, {name: pageSize, var: page_size}, {name: reference, var: reference}, {name: merchantId, var: merchant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    page_number: $page_number, page_size: $page_size, reference: $reference, merchant_id: $merchant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a store
#
# POST /stores
# Returns: record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>
# operationId: post-stores
export def "post-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # shape: {city?: string, country: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
  --business-line-ids: list<string> # The unique identifiers of the [business lines](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businesslines__resParam_id) that the store is associated with. If not specified, the business line of the merchant account is used. Required when there are multiple business lines under the merchant account.
  description: string # Your description of the store.
  --external-reference-id: string # When using the Zip payment method: The location ID that Zip has assigned to your store.
  merchant_id: string # The unique identifier of the merchant account that the store belongs to.
  phone_number: string # The phone number of the store, including '+' and country code.
  --reference: string # Your reference to recognize the store by. Also known as the store code. Allowed characters: Lowercase and uppercase letters without diacritics, numbers 0 through 9, hyphen (-), and underscore (_).
  shopper_statement: string # The store name to be shown on the shopper's bank or credit card statement and on the shopper receipt. Maximum length: 22 characters; can't be all numbers.
  --split-configuration: record # shape: {balanceAccountId?: string, splitConfigurationId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stores"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: businessLineIds, var: business_line_ids}, {name: description, var: description}, {name: externalReferenceId, var: external_reference_id}, {name: merchantId, var: merchant_id}, {name: phoneNumber, var: phone_number}, {name: reference, var: reference}, {name: shopperStatement, var: shopper_statement}, {name: splitConfiguration, var: split_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address, business_line_ids: $business_line_ids, description: $description, external_reference_id: $external_reference_id, merchant_id: $merchant_id, phone_number: $phone_number, reference: $reference, shopper_statement: $shopper_statement, split_configuration: $split_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a store
#
# GET /stores/{storeId}
# Returns: record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>
# operationId: get-stores-storeId
export def "get-stores-store-id" [
  store_id: string
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
    path: "/stores/{storeId}"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a store
#
# PATCH /stores/{storeId}
# Returns: record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string>
# operationId: patch-stores-storeId
export def "patch-stores-store-id" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {city?: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
  --business-line-ids: list<string> # The unique identifiers of the [business lines](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businesslines__resParam_id) that the store is associated with.
  --description: string # The description of the store.
  --external-reference-id: string # When using the Zip payment method: The location ID that Zip has assigned to your store.
  --split-configuration: record # shape: {balanceAccountId?: string, splitConfigurationId?: string}
  --status: string@status-completer # The status of the store. Possible values are: - **active**: This value is assigned automatically when a store is created. - **inactive**: The maximum [transaction limits and number of Store-and-Forward transactions](https://docs.adyen.com/point-of-sale/determine-account-structure/configure-features#payment-features) for the store are set to 0. This blocks new transactions, but captures are still possible. - **closed**: The terminals of the store are reassigned to the merchant inventory, so they can't process payments. You can change the status from **active** to **inactive**, and from **inactive** to **active** or **closed**. Once **closed**, a store can't be reopened.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/stores/{storeId}"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: businessLineIds, var: business_line_ids}, {name: description, var: description}, {name: externalReferenceId, var: external_reference_id}, {name: splitConfiguration, var: split_configuration}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    store_id: $store_id, address: $address, business_line_ids: $business_line_ids, description: $description, external_reference_id: $external_reference_id, split_configuration: $split_configuration, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the terminal logo
#
# GET /stores/{storeId}/terminalLogos
# Returns: record<data: string>
# operationId: get-stores-storeId-terminalLogos
export def "get-stores-store-id-terminal-logos" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stores/{storeId}/terminalLogos"
    path_params: [{name: storeId, var: store_id}]
    query: [{name: model, var: model, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    store_id: $store_id, model: $model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the terminal logo
#
# PATCH /stores/{storeId}/terminalLogos
# Returns: record<data: string>
# operationId: patch-stores-storeId-terminalLogos
export def "patch-stores-store-id-terminal-logos" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T. (required)
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/stores/{storeId}/terminalLogos"
    path_params: [{name: storeId, var: store_id}]
    query: [{name: model, var: model, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    store_id: $store_id, model: $model, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get terminal settings
#
# GET /stores/{storeId}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: get-stores-storeId-terminalSettings
export def "get-stores-store-id-terminal-settings" [
  store_id: string
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
    path: "/stores/{storeId}/terminalSettings"
    path_params: [{name: storeId, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update terminal settings
#
# PATCH /stores/{storeId}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: patch-stores-storeId-terminalSettings
export def "patch-stores-store-id-terminal-settings" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholder-receipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list<string>, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list<string>}
  --offline-processing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --pay-at-table: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list<string>}
  --receipt-options: record # shape: {logo?: string, qrCodeData?: string}
  --receipt-printing: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifi-profiles: record # shape: {profiles?: list, settings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/stores/{storeId}/terminalSettings"
    path_params: [{name: storeId, var: store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cardholderReceipt, var: cardholder_receipt}, {name: connectivity, var: connectivity}, {name: gratuities, var: gratuities}, {name: hardware, var: hardware}, {name: nexo, var: nexo}, {name: offlineProcessing, var: offline_processing}, {name: opi, var: opi}, {name: passcodes, var: passcodes}, {name: payAtTable, var: pay_at_table}, {name: payment, var: payment}, {name: receiptOptions, var: receipt_options}, {name: receiptPrinting, var: receipt_printing}, {name: signature, var: signature}, {name: standalone, var: standalone}, {name: surcharge, var: surcharge}, {name: timeouts, var: timeouts}, {name: wifiProfiles, var: wifi_profiles}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    store_id: $store_id, cardholder_receipt: $cardholder_receipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offline_processing: $offline_processing, opi: $opi, passcodes: $passcodes, pay_at_table: $pay_at_table, payment: $payment, receipt_options: $receipt_options, receipt_printing: $receipt_printing, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifi_profiles: $wifi_profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of terminals
#
# GET /terminals
# Returns: record<data: table<assigned: bool, bluetoothIp: string, bluetoothMac: string, city: string, companyAccount: string, countryCode: string, deviceModel: string, ethernetIp: string, ethernetMac: string, firmwareVersion: string, iccid: string, id: string, lastActivityDateTime: string, lastTransactionDateTime: string, linkNegotiation: string, serialNumber: string, simStatus: string, status: string, storeStatus: string, wifiIp: string, wifiMac: string, wifiSsid: string>>
# operationId: get-terminals
export def "get-terminals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # Returns terminals with an ID that contains the specified string. If present, other query parameters are ignored.
  --countries: string # Returns terminals located in the countries specified by their [two-letter country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
  --merchant-ids: string # Returns terminals that belong to the merchant accounts specified by their unique merchant account ID.
  --store-ids: string # Returns terminals that are assigned to the [stores](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/stores) specified by their unique store ID.
  --brand-models: string # Returns terminals of the [models](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/companies/{companyId}/terminalModels) specified in the format *brand.model*.
  --page-number: int # The number of the page to fetch. (format: int32)
  --page-size: int # The number of items to have on a page, maximum 100. The default is 20 items on a page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/terminals"
    query: [{name: searchQuery, var: search_query}, {name: countries, var: countries}, {name: merchantIds, var: merchant_ids}, {name: storeIds, var: store_ids}, {name: brandModels, var: brand_models}, {name: pageNumber, var: page_number}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    search_query: $search_query, countries: $countries, merchant_ids: $merchant_ids, store_ids: $store_ids, brand_models: $brand_models, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a terminal action
#
# POST /terminals/scheduleActions
# Returns: record<actionDetails: any, items: table<id: string, terminalId: string>, scheduledAt: string, storeId: string, terminalIds: list<string>, terminalsWithErrors: record, totalErrors: int, totalScheduled: int>
# operationId: post-terminals-scheduleActions
export def "post-terminals-schedule-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-details: any # Information about the action to take.
  --scheduled-at: string # The date and time when the action should happen. Format: [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339), but without the **Z** before the time offset. For example, **2021-11-15T12:16:21+01:00** The action is sent with the first [maintenance call](https://docs.adyen.com/point-of-sale/automating-terminal-management/terminal-actions-api#when-actions-take-effect) after the specified date and time in the time zone of the terminal. An empty value causes the action to be sent as soon as possible: at the next maintenance call.
  --store-id: string # The unique ID of the [store](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/stores). If present, all terminals in the `terminalIds` list must be assigned to this store.
  --terminal-ids: list<string> # A list of unique IDs of the terminals to apply the action to. You can extract the IDs from the [GET `/terminals`](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/terminals) response. Maximum length: 100 IDs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/terminals/scheduleActions"
    body: {content_type: "application/json", kind: json, fields: [{name: actionDetails, var: action_details}, {name: scheduledAt, var: scheduled_at}, {name: storeId, var: store_id}, {name: terminalIds, var: terminal_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    action_details: $action_details, scheduled_at: $scheduled_at, store_id: $store_id, terminal_ids: $terminal_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the terminal logo
#
# GET /terminals/{terminalId}/terminalLogos
# Returns: record<data: string>
# operationId: get-terminals-terminalId-terminalLogos
export def "get-terminals-terminal-id-terminal-logos" [
  terminal_id: string
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
    path: "/terminals/{terminalId}/terminalLogos"
    path_params: [{name: terminalId, var: terminal_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    terminal_id: $terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the logo
#
# PATCH /terminals/{terminalId}/terminalLogos
# Returns: record<data: string>
# operationId: patch-terminals-terminalId-terminalLogos
export def "patch-terminals-terminal-id-terminal-logos" [
  terminal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/terminals/{terminalId}/terminalLogos"
    path_params: [{name: terminalId, var: terminal_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    terminal_id: $terminal_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get terminal settings
#
# GET /terminals/{terminalId}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: get-terminals-terminalId-terminalSettings
export def "get-terminals-terminal-id-terminal-settings" [
  terminal_id: string
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
    path: "/terminals/{terminalId}/terminalSettings"
    path_params: [{name: terminalId, var: terminal_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    terminal_id: $terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update terminal settings
#
# PATCH /terminals/{terminalId}/terminalSettings
# Returns: record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>>
# operationId: patch-terminals-terminalId-terminalSettings
export def "patch-terminals-terminal-id-terminal-settings" [
  terminal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholder-receipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list<string>, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list<string>}
  --offline-processing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --pay-at-table: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list<string>}
  --receipt-options: record # shape: {logo?: string, qrCodeData?: string}
  --receipt-printing: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifi-profiles: record # shape: {profiles?: list, settings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/terminals/{terminalId}/terminalSettings"
    path_params: [{name: terminalId, var: terminal_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cardholderReceipt, var: cardholder_receipt}, {name: connectivity, var: connectivity}, {name: gratuities, var: gratuities}, {name: hardware, var: hardware}, {name: nexo, var: nexo}, {name: offlineProcessing, var: offline_processing}, {name: opi, var: opi}, {name: passcodes, var: passcodes}, {name: payAtTable, var: pay_at_table}, {name: payment, var: payment}, {name: receiptOptions, var: receipt_options}, {name: receiptPrinting, var: receipt_printing}, {name: signature, var: signature}, {name: standalone, var: standalone}, {name: surcharge, var: surcharge}, {name: timeouts, var: timeouts}, {name: wifiProfiles, var: wifi_profiles}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    terminal_id: $terminal_id, cardholder_receipt: $cardholder_receipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offline_processing: $offline_processing, opi: $opi, passcodes: $passcodes, pay_at_table: $pay_at_table, payment: $payment, receipt_options: $receipt_options, receipt_printing: $receipt_printing, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifi_profiles: $wifi_profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
