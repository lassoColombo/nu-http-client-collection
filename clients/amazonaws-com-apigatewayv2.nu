# Auto-generated client for AmazonApiGatewayV2 v2018-11-29
# Source: https://api.apis.guru/v2/specs/amazonaws.com/apigatewayv2/2018-11-29/openapi.json
# Auth: --token flag or $env.AMAZONAPIGATEWAYV2_TOKEN

const CLIENT = {
  base_url: "http://apigateway.us-east-1.amazonaws.com"
  token_env_var: "AMAZONAPIGATEWAYV2_TOKEN"
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

def base-url-completer [] { ["http://apigateway.us-east-1.amazonaws.com" "http://apigateway.us-east-2.amazonaws.com" "http://apigateway.us-west-1.amazonaws.com" "http://apigateway.us-west-2.amazonaws.com" "http://apigateway.us-gov-west-1.amazonaws.com" "http://apigateway.us-gov-east-1.amazonaws.com" "http://apigateway.ca-central-1.amazonaws.com" "http://apigateway.eu-north-1.amazonaws.com" "http://apigateway.eu-west-1.amazonaws.com" "http://apigateway.eu-west-2.amazonaws.com" "http://apigateway.eu-west-3.amazonaws.com" "http://apigateway.eu-central-1.amazonaws.com" "http://apigateway.eu-south-1.amazonaws.com" "http://apigateway.af-south-1.amazonaws.com" "http://apigateway.ap-northeast-1.amazonaws.com" "http://apigateway.ap-northeast-2.amazonaws.com" "http://apigateway.ap-northeast-3.amazonaws.com" "http://apigateway.ap-southeast-1.amazonaws.com" "http://apigateway.ap-southeast-2.amazonaws.com" "http://apigateway.ap-east-1.amazonaws.com" "http://apigateway.ap-south-1.amazonaws.com" "http://apigateway.sa-east-1.amazonaws.com" "http://apigateway.me-south-1.amazonaws.com" "https://apigateway.us-east-1.amazonaws.com" "https://apigateway.us-east-2.amazonaws.com" "https://apigateway.us-west-1.amazonaws.com" "https://apigateway.us-west-2.amazonaws.com" "https://apigateway.us-gov-west-1.amazonaws.com" "https://apigateway.us-gov-east-1.amazonaws.com" "https://apigateway.ca-central-1.amazonaws.com" "https://apigateway.eu-north-1.amazonaws.com" "https://apigateway.eu-west-1.amazonaws.com" "https://apigateway.eu-west-2.amazonaws.com" "https://apigateway.eu-west-3.amazonaws.com" "https://apigateway.eu-central-1.amazonaws.com" "https://apigateway.eu-south-1.amazonaws.com" "https://apigateway.af-south-1.amazonaws.com" "https://apigateway.ap-northeast-1.amazonaws.com" "https://apigateway.ap-northeast-2.amazonaws.com" "https://apigateway.ap-northeast-3.amazonaws.com" "https://apigateway.ap-southeast-1.amazonaws.com" "https://apigateway.ap-southeast-2.amazonaws.com" "https://apigateway.ap-east-1.amazonaws.com" "https://apigateway.ap-south-1.amazonaws.com" "https://apigateway.sa-east-1.amazonaws.com" "https://apigateway.me-south-1.amazonaws.com" "http://apigateway.cn-north-1.amazonaws.com.cn" "http://apigateway.cn-northwest-1.amazonaws.com.cn" "https://apigateway.cn-north-1.amazonaws.com.cn" "https://apigateway.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def protocol-type-completer [] { ["HTTP" "WEBSOCKET"] }
def authorizer-type-completer [] { ["JWT" "REQUEST"] }
def connection-type-completer [] { ["INTERNET" "VPC_LINK"] }
def content-handling-strategy-completer [] { ["CONVERT_TO_BINARY" "CONVERT_TO_TEXT"] }
def integration-type-completer [] { ["AWS" "AWS_PROXY" "HTTP" "HTTP_PROXY" "MOCK"] }
def passthrough-behavior-completer [] { ["NEVER" "WHEN_NO_MATCH" "WHEN_NO_TEMPLATES"] }
def authorization-type-completer [] { ["AWS_IAM" "CUSTOM" "JWT" "NONE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-api: "record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>"
    get-apis: "record<Items: table<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list>, NextToken: string>"
    import-api: "record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>"
    create-api-mapping: "record<ApiId: string, ApiMappingId: string, ApiMappingKey: string, Stage: string>"
    get-api-mappings: "record<Items: table<ApiId: string, ApiMappingId: string, ApiMappingKey: string, Stage: string>, NextToken: string>"
    create-authorizer: "record<AuthorizerCredentialsArn: string, AuthorizerId: string, AuthorizerPayloadFormatVersion: string, AuthorizerResultTtlInSeconds: int, AuthorizerType: string, AuthorizerUri: string, EnableSimpleResponses: bool, IdentitySource: list<string>, IdentityValidationExpression: string, JwtConfiguration: record<Audience: list<string>, Issuer: string>, Name: string>"
    get-authorizers: "record<Items: table<AuthorizerCredentialsArn: string, AuthorizerId: string, AuthorizerPayloadFormatVersion: string, AuthorizerResultTtlInSeconds: int, AuthorizerType: string, AuthorizerUri: string, EnableSimpleResponses: bool, IdentitySource: list, IdentityValidationExpression: string, JwtConfiguration: record, Name: string>, NextToken: string>"
    create-deployment: "record<AutoDeployed: bool, CreatedDate: string, DeploymentId: string, DeploymentStatus: string, DeploymentStatusMessage: string, Description: string>"
    get-deployments: "record<Items: table<AutoDeployed: bool, CreatedDate: string, DeploymentId: string, DeploymentStatus: string, DeploymentStatusMessage: string, Description: string>, NextToken: string>"
    create-domain-name: "record<ApiMappingSelectionExpression: string, DomainName: string, DomainNameConfigurations: table<ApiGatewayDomainName: string, CertificateArn: string, CertificateName: string, CertificateUploadDate: string, DomainNameStatus: string, DomainNameStatusMessage: string, EndpointType: string, HostedZoneId: string, SecurityPolicy: string, OwnershipVerificationCertificateArn: string>, MutualTlsAuthentication: record<TruststoreUri: string, TruststoreVersion: string, TruststoreWarnings: list<string>>, Tags: record>"
    get-domain-names: "record<Items: table<ApiMappingSelectionExpression: string, DomainName: string, DomainNameConfigurations: list, MutualTlsAuthentication: record, Tags: record>, NextToken: string>"
    create-integration: "record<ApiGatewayManaged: bool, ConnectionId: string, ConnectionType: string, ContentHandlingStrategy: string, CredentialsArn: string, Description: string, IntegrationId: string, IntegrationMethod: string, IntegrationResponseSelectionExpression: string, IntegrationSubtype: string, IntegrationType: string, IntegrationUri: string, PassthroughBehavior: string, PayloadFormatVersion: string, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: string, TimeoutInMillis: int, TlsConfig: record<ServerNameToVerify: string>>"
    get-integrations: "record<Items: table<ApiGatewayManaged: bool, ConnectionId: string, ConnectionType: string, ContentHandlingStrategy: string, CredentialsArn: string, Description: string, IntegrationId: string, IntegrationMethod: string, IntegrationResponseSelectionExpression: string, IntegrationSubtype: string, IntegrationType: string, IntegrationUri: string, PassthroughBehavior: string, PayloadFormatVersion: string, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: string, TimeoutInMillis: int, TlsConfig: record>, NextToken: string>"
    create-integration-response: "record<ContentHandlingStrategy: string, IntegrationResponseId: string, IntegrationResponseKey: string, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: string>"
    get-integration-responses: "record<Items: table<ContentHandlingStrategy: string, IntegrationResponseId: string, IntegrationResponseKey: string, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: string>, NextToken: string>"
    create-model: "record<ContentType: string, Description: string, ModelId: string, Name: string, Schema: string>"
    get-models: "record<Items: table<ContentType: string, Description: string, ModelId: string, Name: string, Schema: string>, NextToken: string>"
    create-route: "record<ApiGatewayManaged: bool, ApiKeyRequired: bool, AuthorizationScopes: list<string>, AuthorizationType: string, AuthorizerId: string, ModelSelectionExpression: string, OperationName: string, RequestModels: record, RequestParameters: record, RouteId: string, RouteKey: string, RouteResponseSelectionExpression: string, Target: string>"
    get-routes: "record<Items: table<ApiGatewayManaged: bool, ApiKeyRequired: bool, AuthorizationScopes: list, AuthorizationType: string, AuthorizerId: string, ModelSelectionExpression: string, OperationName: string, RequestModels: record, RequestParameters: record, RouteId: string, RouteKey: string, RouteResponseSelectionExpression: string, Target: string>, NextToken: string>"
    create-route-response: "record<ModelSelectionExpression: string, ResponseModels: record, ResponseParameters: record, RouteResponseId: string, RouteResponseKey: string>"
    get-route-responses: "record<Items: table<ModelSelectionExpression: string, ResponseModels: record, ResponseParameters: record, RouteResponseId: string, RouteResponseKey: string>, NextToken: string>"
    create-stage: "record<AccessLogSettings: record<DestinationArn: string, Format: string>, ApiGatewayManaged: bool, AutoDeploy: bool, ClientCertificateId: string, CreatedDate: string, DefaultRouteSettings: record<DataTraceEnabled: bool, DetailedMetricsEnabled: bool, LoggingLevel: string, ThrottlingBurstLimit: int, ThrottlingRateLimit: float>, DeploymentId: string, Description: string, LastDeploymentStatusMessage: string, LastUpdatedDate: string, RouteSettings: record, StageName: string, StageVariables: record, Tags: record>"
    get-stages: "record<Items: table<AccessLogSettings: record, ApiGatewayManaged: bool, AutoDeploy: bool, ClientCertificateId: string, CreatedDate: string, DefaultRouteSettings: record, DeploymentId: string, Description: string, LastDeploymentStatusMessage: string, LastUpdatedDate: string, RouteSettings: record, StageName: string, StageVariables: record, Tags: record>, NextToken: string>"
    create-vpc-link: "record<CreatedDate: string, Name: string, SecurityGroupIds: list<string>, SubnetIds: list<string>, Tags: record, VpcLinkId: string, VpcLinkStatus: string, VpcLinkStatusMessage: string, VpcLinkVersion: string>"
    get-vpc-links: "record<Items: table<CreatedDate: string, Name: string, SecurityGroupIds: list, SubnetIds: list, Tags: record, VpcLinkId: string, VpcLinkStatus: string, VpcLinkStatusMessage: string, VpcLinkVersion: string>, NextToken: string>"
    get-api: "record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>"
    reimport-api: "record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>"
    update-api: "record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>"
    get-api-mapping: "record<ApiId: string, ApiMappingId: string, ApiMappingKey: string, Stage: string>"
    update-api-mapping: "record<ApiId: string, ApiMappingId: string, ApiMappingKey: string, Stage: string>"
    get-authorizer: "record<AuthorizerCredentialsArn: string, AuthorizerId: string, AuthorizerPayloadFormatVersion: string, AuthorizerResultTtlInSeconds: int, AuthorizerType: string, AuthorizerUri: string, EnableSimpleResponses: bool, IdentitySource: list<string>, IdentityValidationExpression: string, JwtConfiguration: record<Audience: list<string>, Issuer: string>, Name: string>"
    update-authorizer: "record<AuthorizerCredentialsArn: string, AuthorizerId: string, AuthorizerPayloadFormatVersion: string, AuthorizerResultTtlInSeconds: int, AuthorizerType: string, AuthorizerUri: string, EnableSimpleResponses: bool, IdentitySource: list<string>, IdentityValidationExpression: string, JwtConfiguration: record<Audience: list<string>, Issuer: string>, Name: string>"
    get-deployment: "record<AutoDeployed: bool, CreatedDate: string, DeploymentId: string, DeploymentStatus: string, DeploymentStatusMessage: string, Description: string>"
    update-deployment: "record<AutoDeployed: bool, CreatedDate: string, DeploymentId: string, DeploymentStatus: string, DeploymentStatusMessage: string, Description: string>"
    get-domain-name: "record<ApiMappingSelectionExpression: string, DomainName: string, DomainNameConfigurations: table<ApiGatewayDomainName: string, CertificateArn: string, CertificateName: string, CertificateUploadDate: string, DomainNameStatus: string, DomainNameStatusMessage: string, EndpointType: string, HostedZoneId: string, SecurityPolicy: string, OwnershipVerificationCertificateArn: string>, MutualTlsAuthentication: record<TruststoreUri: string, TruststoreVersion: string, TruststoreWarnings: list<string>>, Tags: record>"
    update-domain-name: "record<ApiMappingSelectionExpression: string, DomainName: string, DomainNameConfigurations: table<ApiGatewayDomainName: string, CertificateArn: string, CertificateName: string, CertificateUploadDate: string, DomainNameStatus: string, DomainNameStatusMessage: string, EndpointType: string, HostedZoneId: string, SecurityPolicy: string, OwnershipVerificationCertificateArn: string>, MutualTlsAuthentication: record<TruststoreUri: string, TruststoreVersion: string, TruststoreWarnings: list<string>>, Tags: record>"
    get-integration: "record<ApiGatewayManaged: bool, ConnectionId: string, ConnectionType: string, ContentHandlingStrategy: string, CredentialsArn: string, Description: string, IntegrationId: string, IntegrationMethod: string, IntegrationResponseSelectionExpression: string, IntegrationSubtype: string, IntegrationType: string, IntegrationUri: string, PassthroughBehavior: string, PayloadFormatVersion: string, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: string, TimeoutInMillis: int, TlsConfig: record<ServerNameToVerify: string>>"
    update-integration: "record<ApiGatewayManaged: bool, ConnectionId: string, ConnectionType: string, ContentHandlingStrategy: string, CredentialsArn: string, Description: string, IntegrationId: string, IntegrationMethod: string, IntegrationResponseSelectionExpression: string, IntegrationSubtype: string, IntegrationType: string, IntegrationUri: string, PassthroughBehavior: string, PayloadFormatVersion: string, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: string, TimeoutInMillis: int, TlsConfig: record<ServerNameToVerify: string>>"
    get-integration-response: "record<ContentHandlingStrategy: string, IntegrationResponseId: string, IntegrationResponseKey: string, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: string>"
    update-integration-response: "record<ContentHandlingStrategy: string, IntegrationResponseId: string, IntegrationResponseKey: string, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: string>"
    get-model: "record<ContentType: string, Description: string, ModelId: string, Name: string, Schema: string>"
    update-model: "record<ContentType: string, Description: string, ModelId: string, Name: string, Schema: string>"
    get-route: "record<ApiGatewayManaged: bool, ApiKeyRequired: bool, AuthorizationScopes: list<string>, AuthorizationType: string, AuthorizerId: string, ModelSelectionExpression: string, OperationName: string, RequestModels: record, RequestParameters: record, RouteId: string, RouteKey: string, RouteResponseSelectionExpression: string, Target: string>"
    update-route: "record<ApiGatewayManaged: bool, ApiKeyRequired: bool, AuthorizationScopes: list<string>, AuthorizationType: string, AuthorizerId: string, ModelSelectionExpression: string, OperationName: string, RequestModels: record, RequestParameters: record, RouteId: string, RouteKey: string, RouteResponseSelectionExpression: string, Target: string>"
    get-route-response: "record<ModelSelectionExpression: string, ResponseModels: record, ResponseParameters: record, RouteResponseId: string, RouteResponseKey: string>"
    update-route-response: "record<ModelSelectionExpression: string, ResponseModels: record, ResponseParameters: record, RouteResponseId: string, RouteResponseKey: string>"
    get-stage: "record<AccessLogSettings: record<DestinationArn: string, Format: string>, ApiGatewayManaged: bool, AutoDeploy: bool, ClientCertificateId: string, CreatedDate: string, DefaultRouteSettings: record<DataTraceEnabled: bool, DetailedMetricsEnabled: bool, LoggingLevel: string, ThrottlingBurstLimit: int, ThrottlingRateLimit: float>, DeploymentId: string, Description: string, LastDeploymentStatusMessage: string, LastUpdatedDate: string, RouteSettings: record, StageName: string, StageVariables: record, Tags: record>"
    update-stage: "record<AccessLogSettings: record<DestinationArn: string, Format: string>, ApiGatewayManaged: bool, AutoDeploy: bool, ClientCertificateId: string, CreatedDate: string, DefaultRouteSettings: record<DataTraceEnabled: bool, DetailedMetricsEnabled: bool, LoggingLevel: string, ThrottlingBurstLimit: int, ThrottlingRateLimit: float>, DeploymentId: string, Description: string, LastDeploymentStatusMessage: string, LastUpdatedDate: string, RouteSettings: record, StageName: string, StageVariables: record, Tags: record>"
    delete-vpc-link: "record"
    get-vpc-link: "record<CreatedDate: string, Name: string, SecurityGroupIds: list<string>, SubnetIds: list<string>, Tags: record, VpcLinkId: string, VpcLinkStatus: string, VpcLinkStatusMessage: string, VpcLinkVersion: string>"
    update-vpc-link: "record<CreatedDate: string, Name: string, SecurityGroupIds: list<string>, SubnetIds: list<string>, Tags: record, VpcLinkId: string, VpcLinkStatus: string, VpcLinkStatusMessage: string, VpcLinkVersion: string>"
    export-api: "record<body: string>"
    get-model-template: "record<Value: string>"
    get-tags: "record<Tags: record>"
    tag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-api" "get-apis" "import-api" "create-api-mapping" "get-api-mappings" "create-authorizer" "get-authorizers" "create-deployment" "get-deployments" "create-domain-name" "get-domain-names" "create-integration" "get-integrations" "create-integration-response" "get-integration-responses" "create-model" "get-models" "create-route" "get-routes" "create-route-response" "get-route-responses" "create-stage" "get-stages" "create-vpc-link" "get-vpc-links" "delete-access-log-settings" "delete-api" "get-api" "reimport-api" "update-api" "delete-api-mapping" "get-api-mapping" "update-api-mapping" "delete-authorizer" "get-authorizer" "update-authorizer" "delete-cors-configuration" "delete-deployment" "get-deployment" "update-deployment" "delete-domain-name" "get-domain-name" "update-domain-name" "delete-integration" "get-integration" "update-integration" "delete-integration-response" "get-integration-response" "update-integration-response" "delete-model" "get-model" "update-model" "delete-route" "get-route" "update-route" "delete-route-request-parameter" "delete-route-response" "get-route-response" "update-route-response" "delete-route-settings" "delete-stage" "get-stage" "update-stage" "delete-vpc-link" "get-vpc-link" "update-vpc-link" "export-api" "reset-authorizers-cache" "get-model-template" "get-tags" "tag-resource" "untag-resource" "commands"] | sort) } | get name | first)
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

# Creates an Api resource.
#
# POST /v2/apis
# Returns: record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>
# operationId: CreateApi
export def "create-api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --api-key-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --cors-configuration: record # Represents a CORS configuration. Supported only for HTTP APIs. See Configuring CORS (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-cors.html) for more information. — shape: {AllowCredentials?: bool, AllowHeaders?: list<string>, AllowMethods?: list<string>, AllowOrigins?: list<string>, ExposeHeaders?: list<string>, MaxAge?: int}
  --credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --description: string # A string with a length between [0-1024].
  --disable-schema-validation: oneof<nothing, bool> # Avoid validating models when creating a deployment. Supported only for WebSocket APIs.
  --disable-execute-api-endpoint: oneof<nothing, bool> # Specifies whether clients can invoke your API by using the default execute-api endpoint. By default, clients can invoke your API with the default https://{api_id}.execute-api.{region}.amazonaws.com endpoint. To require that clients use a custom domain name to invoke your API, disable the default endpoint.
  name: string # A string with a length between [1-128].
  protocol_type: string@protocol-type-completer # Represents a protocol type.
  --route-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --route-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --tags: record # Represents a collection of tags associated with the resource.
  --target: string # A string representation of a URI with a length between [1-2048].
  --version: string # A string with a length between [1-64].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiKeySelectionExpression, var: api_key_selection_expression}, {name: corsConfiguration, var: cors_configuration}, {name: credentialsArn, var: credentials_arn}, {name: description, var: description}, {name: disableSchemaValidation, var: disable_schema_validation}, {name: disableExecuteApiEndpoint, var: disable_execute_api_endpoint}, {name: name, var: name}, {name: protocolType, var: protocol_type}, {name: routeKey, var: route_key}, {name: routeSelectionExpression, var: route_selection_expression}, {name: tags, var: tags}, {name: target, var: target}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, api_key_selection_expression: $api_key_selection_expression, cors_configuration: $cors_configuration, credentials_arn: $credentials_arn, description: $description, disable_schema_validation: $disable_schema_validation, disable_execute_api_endpoint: $disable_execute_api_endpoint, name: $name, protocol_type: $protocol_type, route_key: $route_key, route_selection_expression: $route_selection_expression, tags: $tags, target: $target, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a collection of Api resources.
#
# GET /v2/apis
# Returns: record<Items: table<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list>, NextToken: string>
# operationId: GetApis
export def "get-apis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports an API.
#
# PUT /v2/apis
# Returns: record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>
# operationId: ImportApi
export def "import-api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basepath: string # Specifies how to interpret the base path of the API during import. Valid values are ignore, prepend, and split. The default value is ignore. To learn more, see Set the OpenAPI basePath Property (https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-import-api-basePath.html). Supported only for HTTP APIs.
  --fail-on-warnings: oneof<nothing, bool> # Specifies whether to rollback the API creation when a warning is encountered. By default, API creation continues if a warning is encountered.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The OpenAPI definition. Supported only for HTTP APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/apis"
    query: [{name: basepath, var: basepath}, {name: failOnWarnings, var: fail_on_warnings}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    basepath: $basepath, fail_on_warnings: $fail_on_warnings, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an API mapping.
#
# POST /v2/domainnames/{domainName}/apimappings
# Returns: record<ApiId: string, ApiMappingId: string, ApiMappingKey: string, Stage: string>
# operationId: CreateApiMapping
export def "create-api-mapping" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  api_id: string # The identifier.
  --api-mapping-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  stage: string # A string with a length between [1-128].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/domainnames/{domainName}/apimappings"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiId, var: api_id}, {name: apiMappingKey, var: api_mapping_key}, {name: stage, var: stage}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, api_id: $api_id, api_mapping_key: $api_mapping_key, stage: $stage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets API mappings.
#
# GET /v2/domainnames/{domainName}/apimappings
# Returns: record<Items: table<ApiId: string, ApiMappingId: string, ApiMappingKey: string, Stage: string>, NextToken: string>
# operationId: GetApiMappings
export def "get-api-mappings" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/domainnames/{domainName}/apimappings"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Authorizer for an API.
#
# POST /v2/apis/{apiId}/authorizers
# Returns: record<AuthorizerCredentialsArn: string, AuthorizerId: string, AuthorizerPayloadFormatVersion: string, AuthorizerResultTtlInSeconds: int, AuthorizerType: string, AuthorizerUri: string, EnableSimpleResponses: bool, IdentitySource: list<string>, IdentityValidationExpression: string, JwtConfiguration: record<Audience: list<string>, Issuer: string>, Name: string>
# operationId: CreateAuthorizer
export def "create-authorizer" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authorizer-credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --authorizer-payload-format-version: string # A string with a length between [1-64].
  --authorizer-result-ttl-in-seconds: int # An integer with a value between [0-3600].
  authorizer_type: string@authorizer-type-completer # The authorizer type. Specify REQUEST for a Lambda function using incoming request parameters. Specify JWT to use JSON Web Tokens (supported only for HTTP APIs).
  --authorizer-uri: string # A string representation of a URI with a length between [1-2048].
  --enable-simple-responses: oneof<nothing, bool> # Specifies whether a Lambda authorizer returns a response in a simple format. By default, a Lambda authorizer must return an IAM policy. If enabled, the Lambda authorizer can return a boolean value instead of an IAM policy. Supported only for HTTP APIs. To learn more, see Working with AWS Lambda authorizers for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html)
  identity_source: list<string> # The identity source for which authorization is requested. For the REQUEST authorizer, this is required when authorization caching is enabled. The value is a comma-separated string of one or more mapping expressions of the specified request parameters. For example, if an Auth header, a Name query string parameter are defined as identity sources, this value is $method.request.header.Auth, $method.request.querystring.Name. These parameters will be used to derive the authorization caching key and to perform runtime validation of the REQUEST authorizer by verifying all of the identity-related request parameters are present, not null and non-empty. Only when this is true does the authorizer invoke the authorizer Lambda function, otherwise, it returns a 401 Unauthorized response without calling the Lambda function. The valid value is a string of comma-separated mapping expressions of the specified request parameters. When the authorization caching is not enabled, this property is optional.
  --identity-validation-expression: string # A string with a length between [0-1024].
  --jwt-configuration: record # Represents the configuration of a JWT authorizer. Required for the JWT authorizer type. Supported only for HTTP APIs. — shape: {Audience?: list<string>, Issuer?: string}
  name: string # A string with a length between [1-128].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis/{apiId}/authorizers"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizerCredentialsArn, var: authorizer_credentials_arn}, {name: authorizerPayloadFormatVersion, var: authorizer_payload_format_version}, {name: authorizerResultTtlInSeconds, var: authorizer_result_ttl_in_seconds}, {name: authorizerType, var: authorizer_type}, {name: authorizerUri, var: authorizer_uri}, {name: enableSimpleResponses, var: enable_simple_responses}, {name: identitySource, var: identity_source}, {name: identityValidationExpression, var: identity_validation_expression}, {name: jwtConfiguration, var: jwt_configuration}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authorizer_credentials_arn: $authorizer_credentials_arn, authorizer_payload_format_version: $authorizer_payload_format_version, authorizer_result_ttl_in_seconds: $authorizer_result_ttl_in_seconds, authorizer_type: $authorizer_type, authorizer_uri: $authorizer_uri, enable_simple_responses: $enable_simple_responses, identity_source: $identity_source, identity_validation_expression: $identity_validation_expression, jwt_configuration: $jwt_configuration, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Authorizers for an API.
#
# GET /v2/apis/{apiId}/authorizers
# Returns: record<Items: table<AuthorizerCredentialsArn: string, AuthorizerId: string, AuthorizerPayloadFormatVersion: string, AuthorizerResultTtlInSeconds: int, AuthorizerType: string, AuthorizerUri: string, EnableSimpleResponses: bool, IdentitySource: list, IdentityValidationExpression: string, JwtConfiguration: record, Name: string>, NextToken: string>
# operationId: GetAuthorizers
export def "get-authorizers" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/authorizers"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Deployment for an API.
#
# POST /v2/apis/{apiId}/deployments
# Returns: record<AutoDeployed: bool, CreatedDate: string, DeploymentId: string, DeploymentStatus: string, DeploymentStatusMessage: string, Description: string>
# operationId: CreateDeployment
export def "create-deployment" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A string with a length between [0-1024].
  --stage-name: string # A string with a length between [1-128].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis/{apiId}/deployments"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: stageName, var: stage_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, stage_name: $stage_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Deployments for an API.
#
# GET /v2/apis/{apiId}/deployments
# Returns: record<Items: table<AutoDeployed: bool, CreatedDate: string, DeploymentId: string, DeploymentStatus: string, DeploymentStatusMessage: string, Description: string>, NextToken: string>
# operationId: GetDeployments
export def "get-deployments" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/deployments"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a domain name.
#
# POST /v2/domainnames
# Returns: record<ApiMappingSelectionExpression: string, DomainName: string, DomainNameConfigurations: table<ApiGatewayDomainName: string, CertificateArn: string, CertificateName: string, CertificateUploadDate: string, DomainNameStatus: string, DomainNameStatusMessage: string, EndpointType: string, HostedZoneId: string, SecurityPolicy: string, OwnershipVerificationCertificateArn: string>, MutualTlsAuthentication: record<TruststoreUri: string, TruststoreVersion: string, TruststoreWarnings: list<string>>, Tags: record>
# operationId: CreateDomainName
export def "create-domain-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # A string with a length between [1-512].
  --domain-name-configurations: list # The domain name configurations. — item shape: {ApiGatewayDomainName?: string, CertificateArn?: string, CertificateName?: string, CertificateUploadDate?: string, DomainNameStatus?: "AVAILABLE"|"UPDATING"|"PENDING_CERTIFICATE_REIMPORT"|"PENDING_OWNERSHIP_VERIFICATION", DomainNameStatusMessage?: string, EndpointType?: "REGIONAL"|"EDGE", HostedZoneId?: string, SecurityPolicy?: "TLS_1_0"|"TLS_1_2", OwnershipVerificationCertificateArn?: string}
  --mutual-tls-authentication: record # The mutual TLS authentication configuration for a custom domain name. — shape: {TruststoreUri?: string, TruststoreVersion?: string}
  --tags: record # Represents a collection of tags associated with the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/domainnames"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: domainNameConfigurations, var: domain_name_configurations}, {name: mutualTlsAuthentication, var: mutual_tls_authentication}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name, domain_name_configurations: $domain_name_configurations, mutual_tls_authentication: $mutual_tls_authentication, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the domain names for an AWS account.
#
# GET /v2/domainnames
# Returns: record<Items: table<ApiMappingSelectionExpression: string, DomainName: string, DomainNameConfigurations: list, MutualTlsAuthentication: record, Tags: record>, NextToken: string>
# operationId: GetDomainNames
export def "get-domain-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/domainnames"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Integration.
#
# POST /v2/apis/{apiId}/integrations
# Returns: record<ApiGatewayManaged: bool, ConnectionId: string, ConnectionType: string, ContentHandlingStrategy: string, CredentialsArn: string, Description: string, IntegrationId: string, IntegrationMethod: string, IntegrationResponseSelectionExpression: string, IntegrationSubtype: string, IntegrationType: string, IntegrationUri: string, PassthroughBehavior: string, PayloadFormatVersion: string, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: string, TimeoutInMillis: int, TlsConfig: record<ServerNameToVerify: string>>
# operationId: CreateIntegration
export def "create-integration" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --connection-id: string # A string with a length between [1-1024].
  --connection-type: string@connection-type-completer # Represents a connection type.
  --content-handling-strategy: string@content-handling-strategy-completer # Specifies how to handle response payload content type conversions. Supported only for WebSocket APIs.
  --credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --description: string # A string with a length between [0-1024].
  --integration-method: string # A string with a length between [1-64].
  --integration-subtype: string # A string with a length between [1-128].
  integration_type: string@integration-type-completer # Represents an API method integration type.
  --integration-uri: string # A string representation of a URI with a length between [1-2048].
  --passthrough-behavior: string@passthrough-behavior-completer # Represents passthrough behavior for an integration response. Supported only for WebSocket APIs.
  --payload-format-version: string # A string with a length between [1-64].
  --request-parameters: record # For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the backend. The method request parameter value must match the pattern of method.request.{location}.{name} , where {location} is querystring, path, or header; and {name} must be a valid and unique method request parameter name. For HTTP API integrations with a specified integrationSubtype, request parameters are a key-value map specifying parameters that are passed to AWS_PROXY integrations. You can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Working with AWS service integrations for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html). For HTTP API integrations without a specified integrationSubtype request parameters are a key-value map specifying how to transform HTTP requests before sending them to the backend. The key should follow the pattern <action>:<header|querystring|path>.<location> where action can be append, overwrite or remove. For values, you can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Transforming API requests and responses (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html).
  --request-templates: record # A mapping of identifier keys to templates. The value is an actual template script. The key is typically a SelectionKey which is chosen based on evaluating a selection expression.
  --response-parameters: record # Supported only for HTTP APIs. You use response parameters to transform the HTTP response from a backend integration before returning the response to clients.
  --template-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --timeout-in-millis: int # An integer with a value between [50-30000].
  --tls-config: record # The TLS configuration for a private integration. If you specify a TLS configuration, private integration traffic uses the HTTPS protocol. Supported only for HTTP APIs. — shape: {ServerNameToVerify?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis/{apiId}/integrations"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: connectionType, var: connection_type}, {name: contentHandlingStrategy, var: content_handling_strategy}, {name: credentialsArn, var: credentials_arn}, {name: description, var: description}, {name: integrationMethod, var: integration_method}, {name: integrationSubtype, var: integration_subtype}, {name: integrationType, var: integration_type}, {name: integrationUri, var: integration_uri}, {name: passthroughBehavior, var: passthrough_behavior}, {name: payloadFormatVersion, var: payload_format_version}, {name: requestParameters, var: request_parameters}, {name: requestTemplates, var: request_templates}, {name: responseParameters, var: response_parameters}, {name: templateSelectionExpression, var: template_selection_expression}, {name: timeoutInMillis, var: timeout_in_millis}, {name: tlsConfig, var: tls_config}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connection_id: $connection_id, connection_type: $connection_type, content_handling_strategy: $content_handling_strategy, credentials_arn: $credentials_arn, description: $description, integration_method: $integration_method, integration_subtype: $integration_subtype, integration_type: $integration_type, integration_uri: $integration_uri, passthrough_behavior: $passthrough_behavior, payload_format_version: $payload_format_version, request_parameters: $request_parameters, request_templates: $request_templates, response_parameters: $response_parameters, template_selection_expression: $template_selection_expression, timeout_in_millis: $timeout_in_millis, tls_config: $tls_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Integrations for an API.
#
# GET /v2/apis/{apiId}/integrations
# Returns: record<Items: table<ApiGatewayManaged: bool, ConnectionId: string, ConnectionType: string, ContentHandlingStrategy: string, CredentialsArn: string, Description: string, IntegrationId: string, IntegrationMethod: string, IntegrationResponseSelectionExpression: string, IntegrationSubtype: string, IntegrationType: string, IntegrationUri: string, PassthroughBehavior: string, PayloadFormatVersion: string, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: string, TimeoutInMillis: int, TlsConfig: record>, NextToken: string>
# operationId: GetIntegrations
export def "get-integrations" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/integrations"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an IntegrationResponses.
#
# POST /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses
# Returns: record<ContentHandlingStrategy: string, IntegrationResponseId: string, IntegrationResponseKey: string, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: string>
# operationId: CreateIntegrationResponse
export def "create-integration-response" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-handling-strategy: string@content-handling-strategy-completer # Specifies how to handle response payload content type conversions. Supported only for WebSocket APIs.
  integration_response_key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --response-parameters: record # For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the backend. The method request parameter value must match the pattern of method.request.{location}.{name} , where {location} is querystring, path, or header; and {name} must be a valid and unique method request parameter name. For HTTP API integrations with a specified integrationSubtype, request parameters are a key-value map specifying parameters that are passed to AWS_PROXY integrations. You can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Working with AWS service integrations for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html). For HTTP API integrations without a specified integrationSubtype request parameters are a key-value map specifying how to transform HTTP requests before sending them to the backend. The key should follow the pattern <action>:<header|querystring|path>.<location> where action can be append, overwrite or remove. For values, you can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Transforming API requests and responses (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html).
  --response-templates: record # A mapping of identifier keys to templates. The value is an actual template script. The key is typically a SelectionKey which is chosen based on evaluating a selection expression.
  --template-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses"
    path_params: [{name: apiId, var: api_id}, {name: integrationId, var: integration_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentHandlingStrategy, var: content_handling_strategy}, {name: integrationResponseKey, var: integration_response_key}, {name: responseParameters, var: response_parameters}, {name: responseTemplates, var: response_templates}, {name: templateSelectionExpression, var: template_selection_expression}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, integration_id: $integration_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, content_handling_strategy: $content_handling_strategy, integration_response_key: $integration_response_key, response_parameters: $response_parameters, response_templates: $response_templates, template_selection_expression: $template_selection_expression
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the IntegrationResponses for an Integration.
#
# GET /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses
# Returns: record<Items: table<ContentHandlingStrategy: string, IntegrationResponseId: string, IntegrationResponseKey: string, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: string>, NextToken: string>
# operationId: GetIntegrationResponses
export def "get-integration-responses" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses"
    path_params: [{name: apiId, var: api_id}, {name: integrationId, var: integration_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, integration_id: $integration_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Model for an API.
#
# POST /v2/apis/{apiId}/models
# Returns: record<ContentType: string, Description: string, ModelId: string, Name: string, Schema: string>
# operationId: CreateModel
export def "create-model" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-type: string # A string with a length between [1-256].
  --description: string # A string with a length between [0-1024].
  name: string # A string with a length between [1-128].
  schema: string # A string with a length between [0-32768].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis/{apiId}/models"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: description, var: description}, {name: name, var: name}, {name: schema, var: schema}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, content_type: $content_type, description: $description, name: $name, schema: $schema
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Models for an API.
#
# GET /v2/apis/{apiId}/models
# Returns: record<Items: table<ContentType: string, Description: string, ModelId: string, Name: string, Schema: string>, NextToken: string>
# operationId: GetModels
export def "get-models" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/models"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Route for an API.
#
# POST /v2/apis/{apiId}/routes
# Returns: record<ApiGatewayManaged: bool, ApiKeyRequired: bool, AuthorizationScopes: list<string>, AuthorizationType: string, AuthorizerId: string, ModelSelectionExpression: string, OperationName: string, RequestModels: record, RequestParameters: record, RouteId: string, RouteKey: string, RouteResponseSelectionExpression: string, Target: string>
# operationId: CreateRoute
export def "create-route" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --api-key-required: oneof<nothing, bool> # Specifies whether an API key is required for the route. Supported only for WebSocket APIs.
  --authorization-scopes: list<string> # A list of authorization scopes configured on a route. The scopes are used with a JWT authorizer to authorize the method invocation. The authorization works by matching the route scopes against the scopes parsed from the access token in the incoming request. The method invocation is authorized if any route scope matches a claimed scope in the access token. Otherwise, the invocation is not authorized. When the route scope is configured, the client must provide an access token instead of an identity token for authorization purposes.
  --authorization-type: string@authorization-type-completer # The authorization type. For WebSocket APIs, valid values are NONE for open access, AWS_IAM for using AWS IAM permissions, and CUSTOM for using a Lambda authorizer. For HTTP APIs, valid values are NONE for open access, JWT for using JSON Web Tokens, AWS_IAM for using AWS IAM permissions, and CUSTOM for using a Lambda authorizer.
  --authorizer-id: string # The identifier.
  --model-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --operation-name: string # A string with a length between [1-64].
  --request-models: record # The route models.
  --request-parameters: record # The route parameters.
  route_key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --route-response-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --target: string # A string with a length between [1-128].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis/{apiId}/routes"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiKeyRequired, var: api_key_required}, {name: authorizationScopes, var: authorization_scopes}, {name: authorizationType, var: authorization_type}, {name: authorizerId, var: authorizer_id}, {name: modelSelectionExpression, var: model_selection_expression}, {name: operationName, var: operation_name}, {name: requestModels, var: request_models}, {name: requestParameters, var: request_parameters}, {name: routeKey, var: route_key}, {name: routeResponseSelectionExpression, var: route_response_selection_expression}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, api_key_required: $api_key_required, authorization_scopes: $authorization_scopes, authorization_type: $authorization_type, authorizer_id: $authorizer_id, model_selection_expression: $model_selection_expression, operation_name: $operation_name, request_models: $request_models, request_parameters: $request_parameters, route_key: $route_key, route_response_selection_expression: $route_response_selection_expression, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Routes for an API.
#
# GET /v2/apis/{apiId}/routes
# Returns: record<Items: table<ApiGatewayManaged: bool, ApiKeyRequired: bool, AuthorizationScopes: list, AuthorizationType: string, AuthorizerId: string, ModelSelectionExpression: string, OperationName: string, RequestModels: record, RequestParameters: record, RouteId: string, RouteKey: string, RouteResponseSelectionExpression: string, Target: string>, NextToken: string>
# operationId: GetRoutes
export def "get-routes" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/routes"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a RouteResponse for a Route.
#
# POST /v2/apis/{apiId}/routes/{routeId}/routeresponses
# Returns: record<ModelSelectionExpression: string, ResponseModels: record, ResponseParameters: record, RouteResponseId: string, RouteResponseKey: string>
# operationId: CreateRouteResponse
export def "create-route-response" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --model-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --response-models: record # The route models.
  --response-parameters: record # The route parameters.
  route_response_key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis/{apiId}/routes/{routeId}/routeresponses"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: modelSelectionExpression, var: model_selection_expression}, {name: responseModels, var: response_models}, {name: responseParameters, var: response_parameters}, {name: routeResponseKey, var: route_response_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, model_selection_expression: $model_selection_expression, response_models: $response_models, response_parameters: $response_parameters, route_response_key: $route_response_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the RouteResponses for a Route.
#
# GET /v2/apis/{apiId}/routes/{routeId}/routeresponses
# Returns: record<Items: table<ModelSelectionExpression: string, ResponseModels: record, ResponseParameters: record, RouteResponseId: string, RouteResponseKey: string>, NextToken: string>
# operationId: GetRouteResponses
export def "get-route-responses" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/routes/{routeId}/routeresponses"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Stage for an API.
#
# POST /v2/apis/{apiId}/stages
# Returns: record<AccessLogSettings: record<DestinationArn: string, Format: string>, ApiGatewayManaged: bool, AutoDeploy: bool, ClientCertificateId: string, CreatedDate: string, DefaultRouteSettings: record<DataTraceEnabled: bool, DetailedMetricsEnabled: bool, LoggingLevel: string, ThrottlingBurstLimit: int, ThrottlingRateLimit: float>, DeploymentId: string, Description: string, LastDeploymentStatusMessage: string, LastUpdatedDate: string, RouteSettings: record, StageName: string, StageVariables: record, Tags: record>
# operationId: CreateStage
export def "create-stage" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --access-log-settings: record # Settings for logging access in a stage. — shape: {DestinationArn?: string, Format?: string}
  --auto-deploy: oneof<nothing, bool> # Specifies whether updates to an API automatically trigger a new deployment. The default value is false.
  --client-certificate-id: string # The identifier.
  --default-route-settings: record # Represents a collection of route settings. — shape: {DataTraceEnabled?: bool, DetailedMetricsEnabled?: bool, LoggingLevel?: "ERROR"|"INFO"|"OFF", ThrottlingBurstLimit?: int, ThrottlingRateLimit?: float}
  --deployment-id: string # The identifier.
  --description: string # A string with a length between [0-1024].
  --route-settings: record # The route settings map.
  stage_name: string # A string with a length between [1-128].
  --stage-variables: record # The stage variable map.
  --tags: record # Represents a collection of tags associated with the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apis/{apiId}/stages"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessLogSettings, var: access_log_settings}, {name: autoDeploy, var: auto_deploy}, {name: clientCertificateId, var: client_certificate_id}, {name: defaultRouteSettings, var: default_route_settings}, {name: deploymentId, var: deployment_id}, {name: description, var: description}, {name: routeSettings, var: route_settings}, {name: stageName, var: stage_name}, {name: stageVariables, var: stage_variables}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, access_log_settings: $access_log_settings, auto_deploy: $auto_deploy, client_certificate_id: $client_certificate_id, default_route_settings: $default_route_settings, deployment_id: $deployment_id, description: $description, route_settings: $route_settings, stage_name: $stage_name, stage_variables: $stage_variables, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Stages for an API.
#
# GET /v2/apis/{apiId}/stages
# Returns: record<Items: table<AccessLogSettings: record, ApiGatewayManaged: bool, AutoDeploy: bool, ClientCertificateId: string, CreatedDate: string, DefaultRouteSettings: record, DeploymentId: string, Description: string, LastDeploymentStatusMessage: string, LastUpdatedDate: string, RouteSettings: record, StageName: string, StageVariables: record, Tags: record>, NextToken: string>
# operationId: GetStages
export def "get-stages" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/stages"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a VPC link.
#
# POST /v2/vpclinks
# Returns: record<CreatedDate: string, Name: string, SecurityGroupIds: list<string>, SubnetIds: list<string>, Tags: record, VpcLinkId: string, VpcLinkStatus: string, VpcLinkStatusMessage: string, VpcLinkVersion: string>
# operationId: CreateVpcLink
export def "create-vpc-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A string with a length between [1-128].
  --security-group-ids: list<string> # A list of security group IDs for the VPC link.
  subnet_ids: list<string> # A list of subnet IDs to include in the VPC link.
  --tags: record # Represents a collection of tags associated with the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/vpclinks"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: securityGroupIds, var: security_group_ids}, {name: subnetIds, var: subnet_ids}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, security_group_ids: $security_group_ids, subnet_ids: $subnet_ids, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a collection of VPC links.
#
# GET /v2/vpclinks
# Returns: record<Items: table<CreatedDate: string, Name: string, SecurityGroupIds: list, SubnetIds: list, Tags: record, VpcLinkId: string, VpcLinkStatus: string, VpcLinkStatusMessage: string, VpcLinkVersion: string>, NextToken: string>
# operationId: GetVpcLinks
export def "get-vpc-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vpclinks"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the AccessLogSettings for a Stage. To disable access logging for a Stage, delete its AccessLogSettings.
#
# DELETE /v2/apis/{apiId}/stages/{stageName}/accesslogsettings
# operationId: DeleteAccessLogSettings
export def "delete-access-log-settings" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/stages/{stageName}/accesslogsettings"
    path_params: [{name: apiId, var: api_id}, {name: stageName, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Api resource.
#
# DELETE /v2/apis/{apiId}
# operationId: DeleteApi
export def "delete-api" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Api resource.
#
# GET /v2/apis/{apiId}
# Returns: record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>
# operationId: GetApi
export def "get-api" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts an Api resource.
#
# PUT /v2/apis/{apiId}
# Returns: record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>
# operationId: ReimportApi
export def "reimport-api" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basepath: string # Specifies how to interpret the base path of the API during import. Valid values are ignore, prepend, and split. The default value is ignore. To learn more, see Set the OpenAPI basePath Property (https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-import-api-basePath.html). Supported only for HTTP APIs.
  --fail-on-warnings: oneof<nothing, bool> # Specifies whether to rollback the API creation when a warning is encountered. By default, API creation continues if a warning is encountered.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The OpenAPI definition. Supported only for HTTP APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: basepath, var: basepath}, {name: failOnWarnings, var: fail_on_warnings}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_id: $api_id, basepath: $basepath, fail_on_warnings: $fail_on_warnings, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Api resource.
#
# PATCH /v2/apis/{apiId}
# Returns: record<ApiEndpoint: string, ApiGatewayManaged: bool, ApiId: string, ApiKeySelectionExpression: string, CorsConfiguration: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreatedDate: string, Description: string, DisableSchemaValidation: bool, DisableExecuteApiEndpoint: bool, ImportInfo: list<string>, Name: string, ProtocolType: string, RouteSelectionExpression: string, Tags: record, Version: string, Warnings: list<string>>
# operationId: UpdateApi
export def "update-api" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --api-key-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --cors-configuration: record # Represents a CORS configuration. Supported only for HTTP APIs. See Configuring CORS (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-cors.html) for more information. — shape: {AllowCredentials?: bool, AllowHeaders?: list<string>, AllowMethods?: list<string>, AllowOrigins?: list<string>, ExposeHeaders?: list<string>, MaxAge?: int}
  --credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --description: string # A string with a length between [0-1024].
  --disable-schema-validation: oneof<nothing, bool> # Avoid validating models when creating a deployment. Supported only for WebSocket APIs.
  --disable-execute-api-endpoint: oneof<nothing, bool> # Specifies whether clients can invoke your API by using the default execute-api endpoint. By default, clients can invoke your API with the default https://{api_id}.execute-api.{region}.amazonaws.com endpoint. To require that clients use a custom domain name to invoke your API, disable the default endpoint.
  --name: string # A string with a length between [1-128].
  --route-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --route-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --target: string # A string representation of a URI with a length between [1-2048].
  --version: string # A string with a length between [1-64].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiKeySelectionExpression, var: api_key_selection_expression}, {name: corsConfiguration, var: cors_configuration}, {name: credentialsArn, var: credentials_arn}, {name: description, var: description}, {name: disableSchemaValidation, var: disable_schema_validation}, {name: disableExecuteApiEndpoint, var: disable_execute_api_endpoint}, {name: name, var: name}, {name: routeKey, var: route_key}, {name: routeSelectionExpression, var: route_selection_expression}, {name: target, var: target}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, api_key_selection_expression: $api_key_selection_expression, cors_configuration: $cors_configuration, credentials_arn: $credentials_arn, description: $description, disable_schema_validation: $disable_schema_validation, disable_execute_api_endpoint: $disable_execute_api_endpoint, name: $name, route_key: $route_key, route_selection_expression: $route_selection_expression, target: $target, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an API mapping.
#
# DELETE /v2/domainnames/{domainName}/apimappings/{apiMappingId}
# operationId: DeleteApiMapping
export def "delete-api-mapping" [
  domain_name: string
  api_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}"
    path_params: [{name: domainName, var: domain_name}, {name: apiMappingId, var: api_mapping_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, api_mapping_id: $api_mapping_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an API mapping.
#
# GET /v2/domainnames/{domainName}/apimappings/{apiMappingId}
# Returns: record<ApiId: string, ApiMappingId: string, ApiMappingKey: string, Stage: string>
# operationId: GetApiMapping
export def "get-api-mapping" [
  domain_name: string
  api_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}"
    path_params: [{name: domainName, var: domain_name}, {name: apiMappingId, var: api_mapping_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, api_mapping_id: $api_mapping_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The API mapping.
#
# PATCH /v2/domainnames/{domainName}/apimappings/{apiMappingId}
# Returns: record<ApiId: string, ApiMappingId: string, ApiMappingKey: string, Stage: string>
# operationId: UpdateApiMapping
export def "update-api-mapping" [
  domain_name: string
  api_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  api_id: string # The identifier.
  --api-mapping-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --stage: string # A string with a length between [1-128].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}"
    path_params: [{name: domainName, var: domain_name}, {name: apiMappingId, var: api_mapping_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiId, var: api_id}, {name: apiMappingKey, var: api_mapping_key}, {name: stage, var: stage}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, api_mapping_id: $api_mapping_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, api_id: $api_id, api_mapping_key: $api_mapping_key, stage: $stage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Authorizer.
#
# DELETE /v2/apis/{apiId}/authorizers/{authorizerId}
# operationId: DeleteAuthorizer
export def "delete-authorizer" [
  api_id: string
  authorizer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/authorizers/{authorizerId}"
    path_params: [{name: apiId, var: api_id}, {name: authorizerId, var: authorizer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, authorizer_id: $authorizer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Authorizer.
#
# GET /v2/apis/{apiId}/authorizers/{authorizerId}
# Returns: record<AuthorizerCredentialsArn: string, AuthorizerId: string, AuthorizerPayloadFormatVersion: string, AuthorizerResultTtlInSeconds: int, AuthorizerType: string, AuthorizerUri: string, EnableSimpleResponses: bool, IdentitySource: list<string>, IdentityValidationExpression: string, JwtConfiguration: record<Audience: list<string>, Issuer: string>, Name: string>
# operationId: GetAuthorizer
export def "get-authorizer" [
  api_id: string
  authorizer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/authorizers/{authorizerId}"
    path_params: [{name: apiId, var: api_id}, {name: authorizerId, var: authorizer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, authorizer_id: $authorizer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Authorizer.
#
# PATCH /v2/apis/{apiId}/authorizers/{authorizerId}
# Returns: record<AuthorizerCredentialsArn: string, AuthorizerId: string, AuthorizerPayloadFormatVersion: string, AuthorizerResultTtlInSeconds: int, AuthorizerType: string, AuthorizerUri: string, EnableSimpleResponses: bool, IdentitySource: list<string>, IdentityValidationExpression: string, JwtConfiguration: record<Audience: list<string>, Issuer: string>, Name: string>
# operationId: UpdateAuthorizer
export def "update-authorizer" [
  api_id: string
  authorizer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authorizer-credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --authorizer-payload-format-version: string # A string with a length between [1-64].
  --authorizer-result-ttl-in-seconds: int # An integer with a value between [0-3600].
  --authorizer-type: string@authorizer-type-completer # The authorizer type. Specify REQUEST for a Lambda function using incoming request parameters. Specify JWT to use JSON Web Tokens (supported only for HTTP APIs).
  --authorizer-uri: string # A string representation of a URI with a length between [1-2048].
  --enable-simple-responses: oneof<nothing, bool> # Specifies whether a Lambda authorizer returns a response in a simple format. By default, a Lambda authorizer must return an IAM policy. If enabled, the Lambda authorizer can return a boolean value instead of an IAM policy. Supported only for HTTP APIs. To learn more, see Working with AWS Lambda authorizers for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html)
  --identity-source: list<string> # The identity source for which authorization is requested. For the REQUEST authorizer, this is required when authorization caching is enabled. The value is a comma-separated string of one or more mapping expressions of the specified request parameters. For example, if an Auth header, a Name query string parameter are defined as identity sources, this value is $method.request.header.Auth, $method.request.querystring.Name. These parameters will be used to derive the authorization caching key and to perform runtime validation of the REQUEST authorizer by verifying all of the identity-related request parameters are present, not null and non-empty. Only when this is true does the authorizer invoke the authorizer Lambda function, otherwise, it returns a 401 Unauthorized response without calling the Lambda function. The valid value is a string of comma-separated mapping expressions of the specified request parameters. When the authorization caching is not enabled, this property is optional.
  --identity-validation-expression: string # A string with a length between [0-1024].
  --jwt-configuration: record # Represents the configuration of a JWT authorizer. Required for the JWT authorizer type. Supported only for HTTP APIs. — shape: {Audience?: list<string>, Issuer?: string}
  --name: string # A string with a length between [1-128].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}/authorizers/{authorizerId}"
    path_params: [{name: apiId, var: api_id}, {name: authorizerId, var: authorizer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizerCredentialsArn, var: authorizer_credentials_arn}, {name: authorizerPayloadFormatVersion, var: authorizer_payload_format_version}, {name: authorizerResultTtlInSeconds, var: authorizer_result_ttl_in_seconds}, {name: authorizerType, var: authorizer_type}, {name: authorizerUri, var: authorizer_uri}, {name: enableSimpleResponses, var: enable_simple_responses}, {name: identitySource, var: identity_source}, {name: identityValidationExpression, var: identity_validation_expression}, {name: jwtConfiguration, var: jwt_configuration}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, authorizer_id: $authorizer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authorizer_credentials_arn: $authorizer_credentials_arn, authorizer_payload_format_version: $authorizer_payload_format_version, authorizer_result_ttl_in_seconds: $authorizer_result_ttl_in_seconds, authorizer_type: $authorizer_type, authorizer_uri: $authorizer_uri, enable_simple_responses: $enable_simple_responses, identity_source: $identity_source, identity_validation_expression: $identity_validation_expression, jwt_configuration: $jwt_configuration, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a CORS configuration.
#
# DELETE /v2/apis/{apiId}/cors
# operationId: DeleteCorsConfiguration
export def "delete-cors-configuration" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/cors"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Deployment.
#
# DELETE /v2/apis/{apiId}/deployments/{deploymentId}
# operationId: DeleteDeployment
export def "delete-deployment" [
  api_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/deployments/{deploymentId}"
    path_params: [{name: apiId, var: api_id}, {name: deploymentId, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Deployment.
#
# GET /v2/apis/{apiId}/deployments/{deploymentId}
# Returns: record<AutoDeployed: bool, CreatedDate: string, DeploymentId: string, DeploymentStatus: string, DeploymentStatusMessage: string, Description: string>
# operationId: GetDeployment
export def "get-deployment" [
  api_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/deployments/{deploymentId}"
    path_params: [{name: apiId, var: api_id}, {name: deploymentId, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Deployment.
#
# PATCH /v2/apis/{apiId}/deployments/{deploymentId}
# Returns: record<AutoDeployed: bool, CreatedDate: string, DeploymentId: string, DeploymentStatus: string, DeploymentStatusMessage: string, Description: string>
# operationId: UpdateDeployment
export def "update-deployment" [
  api_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A string with a length between [0-1024].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}/deployments/{deploymentId}"
    path_params: [{name: apiId, var: api_id}, {name: deploymentId, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a domain name.
#
# DELETE /v2/domainnames/{domainName}
# operationId: DeleteDomainName
export def "delete-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/domainnames/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a domain name.
#
# GET /v2/domainnames/{domainName}
# Returns: record<ApiMappingSelectionExpression: string, DomainName: string, DomainNameConfigurations: table<ApiGatewayDomainName: string, CertificateArn: string, CertificateName: string, CertificateUploadDate: string, DomainNameStatus: string, DomainNameStatusMessage: string, EndpointType: string, HostedZoneId: string, SecurityPolicy: string, OwnershipVerificationCertificateArn: string>, MutualTlsAuthentication: record<TruststoreUri: string, TruststoreVersion: string, TruststoreWarnings: list<string>>, Tags: record>
# operationId: GetDomainName
export def "get-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/domainnames/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a domain name.
#
# PATCH /v2/domainnames/{domainName}
# Returns: record<ApiMappingSelectionExpression: string, DomainName: string, DomainNameConfigurations: table<ApiGatewayDomainName: string, CertificateArn: string, CertificateName: string, CertificateUploadDate: string, DomainNameStatus: string, DomainNameStatusMessage: string, EndpointType: string, HostedZoneId: string, SecurityPolicy: string, OwnershipVerificationCertificateArn: string>, MutualTlsAuthentication: record<TruststoreUri: string, TruststoreVersion: string, TruststoreWarnings: list<string>>, Tags: record>
# operationId: UpdateDomainName
export def "update-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --domain-name-configurations: list # The domain name configurations. — item shape: {ApiGatewayDomainName?: string, CertificateArn?: string, CertificateName?: string, CertificateUploadDate?: string, DomainNameStatus?: "AVAILABLE"|"UPDATING"|"PENDING_CERTIFICATE_REIMPORT"|"PENDING_OWNERSHIP_VERIFICATION", DomainNameStatusMessage?: string, EndpointType?: "REGIONAL"|"EDGE", HostedZoneId?: string, SecurityPolicy?: "TLS_1_0"|"TLS_1_2", OwnershipVerificationCertificateArn?: string}
  --mutual-tls-authentication: record # The mutual TLS authentication configuration for a custom domain name. — shape: {TruststoreUri?: string, TruststoreVersion?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/domainnames/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainNameConfigurations, var: domain_name_configurations}, {name: mutualTlsAuthentication, var: mutual_tls_authentication}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name_configurations: $domain_name_configurations, mutual_tls_authentication: $mutual_tls_authentication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Integration.
#
# DELETE /v2/apis/{apiId}/integrations/{integrationId}
# operationId: DeleteIntegration
export def "delete-integration" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/integrations/{integrationId}"
    path_params: [{name: apiId, var: api_id}, {name: integrationId, var: integration_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, integration_id: $integration_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Integration.
#
# GET /v2/apis/{apiId}/integrations/{integrationId}
# Returns: record<ApiGatewayManaged: bool, ConnectionId: string, ConnectionType: string, ContentHandlingStrategy: string, CredentialsArn: string, Description: string, IntegrationId: string, IntegrationMethod: string, IntegrationResponseSelectionExpression: string, IntegrationSubtype: string, IntegrationType: string, IntegrationUri: string, PassthroughBehavior: string, PayloadFormatVersion: string, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: string, TimeoutInMillis: int, TlsConfig: record<ServerNameToVerify: string>>
# operationId: GetIntegration
export def "get-integration" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/integrations/{integrationId}"
    path_params: [{name: apiId, var: api_id}, {name: integrationId, var: integration_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, integration_id: $integration_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Integration.
#
# PATCH /v2/apis/{apiId}/integrations/{integrationId}
# Returns: record<ApiGatewayManaged: bool, ConnectionId: string, ConnectionType: string, ContentHandlingStrategy: string, CredentialsArn: string, Description: string, IntegrationId: string, IntegrationMethod: string, IntegrationResponseSelectionExpression: string, IntegrationSubtype: string, IntegrationType: string, IntegrationUri: string, PassthroughBehavior: string, PayloadFormatVersion: string, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: string, TimeoutInMillis: int, TlsConfig: record<ServerNameToVerify: string>>
# operationId: UpdateIntegration
export def "update-integration" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --connection-id: string # A string with a length between [1-1024].
  --connection-type: string@connection-type-completer # Represents a connection type.
  --content-handling-strategy: string@content-handling-strategy-completer # Specifies how to handle response payload content type conversions. Supported only for WebSocket APIs.
  --credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --description: string # A string with a length between [0-1024].
  --integration-method: string # A string with a length between [1-64].
  --integration-subtype: string # A string with a length between [1-128].
  --integration-type: string@integration-type-completer # Represents an API method integration type.
  --integration-uri: string # A string representation of a URI with a length between [1-2048].
  --passthrough-behavior: string@passthrough-behavior-completer # Represents passthrough behavior for an integration response. Supported only for WebSocket APIs.
  --payload-format-version: string # A string with a length between [1-64].
  --request-parameters: record # For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the backend. The method request parameter value must match the pattern of method.request.{location}.{name} , where {location} is querystring, path, or header; and {name} must be a valid and unique method request parameter name. For HTTP API integrations with a specified integrationSubtype, request parameters are a key-value map specifying parameters that are passed to AWS_PROXY integrations. You can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Working with AWS service integrations for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html). For HTTP API integrations without a specified integrationSubtype request parameters are a key-value map specifying how to transform HTTP requests before sending them to the backend. The key should follow the pattern <action>:<header|querystring|path>.<location> where action can be append, overwrite or remove. For values, you can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Transforming API requests and responses (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html).
  --request-templates: record # A mapping of identifier keys to templates. The value is an actual template script. The key is typically a SelectionKey which is chosen based on evaluating a selection expression.
  --response-parameters: record # Supported only for HTTP APIs. You use response parameters to transform the HTTP response from a backend integration before returning the response to clients.
  --template-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --timeout-in-millis: int # An integer with a value between [50-30000].
  --tls-config: record # The TLS configuration for a private integration. If you specify a TLS configuration, private integration traffic uses the HTTPS protocol. Supported only for HTTP APIs. — shape: {ServerNameToVerify?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}/integrations/{integrationId}"
    path_params: [{name: apiId, var: api_id}, {name: integrationId, var: integration_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: connectionType, var: connection_type}, {name: contentHandlingStrategy, var: content_handling_strategy}, {name: credentialsArn, var: credentials_arn}, {name: description, var: description}, {name: integrationMethod, var: integration_method}, {name: integrationSubtype, var: integration_subtype}, {name: integrationType, var: integration_type}, {name: integrationUri, var: integration_uri}, {name: passthroughBehavior, var: passthrough_behavior}, {name: payloadFormatVersion, var: payload_format_version}, {name: requestParameters, var: request_parameters}, {name: requestTemplates, var: request_templates}, {name: responseParameters, var: response_parameters}, {name: templateSelectionExpression, var: template_selection_expression}, {name: timeoutInMillis, var: timeout_in_millis}, {name: tlsConfig, var: tls_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, integration_id: $integration_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connection_id: $connection_id, connection_type: $connection_type, content_handling_strategy: $content_handling_strategy, credentials_arn: $credentials_arn, description: $description, integration_method: $integration_method, integration_subtype: $integration_subtype, integration_type: $integration_type, integration_uri: $integration_uri, passthrough_behavior: $passthrough_behavior, payload_format_version: $payload_format_version, request_parameters: $request_parameters, request_templates: $request_templates, response_parameters: $response_parameters, template_selection_expression: $template_selection_expression, timeout_in_millis: $timeout_in_millis, tls_config: $tls_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an IntegrationResponses.
#
# DELETE /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}
# operationId: DeleteIntegrationResponse
export def "delete-integration-response" [
  api_id: string
  integration_id: string
  integration_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}"
    path_params: [{name: apiId, var: api_id}, {name: integrationId, var: integration_id}, {name: integrationResponseId, var: integration_response_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, integration_id: $integration_id, integration_response_id: $integration_response_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an IntegrationResponses.
#
# GET /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}
# Returns: record<ContentHandlingStrategy: string, IntegrationResponseId: string, IntegrationResponseKey: string, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: string>
# operationId: GetIntegrationResponse
export def "get-integration-response" [
  api_id: string
  integration_id: string
  integration_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}"
    path_params: [{name: apiId, var: api_id}, {name: integrationId, var: integration_id}, {name: integrationResponseId, var: integration_response_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, integration_id: $integration_id, integration_response_id: $integration_response_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an IntegrationResponses.
#
# PATCH /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}
# Returns: record<ContentHandlingStrategy: string, IntegrationResponseId: string, IntegrationResponseKey: string, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: string>
# operationId: UpdateIntegrationResponse
export def "update-integration-response" [
  api_id: string
  integration_id: string
  integration_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-handling-strategy: string@content-handling-strategy-completer # Specifies how to handle response payload content type conversions. Supported only for WebSocket APIs.
  --integration-response-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --response-parameters: record # For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the backend. The method request parameter value must match the pattern of method.request.{location}.{name} , where {location} is querystring, path, or header; and {name} must be a valid and unique method request parameter name. For HTTP API integrations with a specified integrationSubtype, request parameters are a key-value map specifying parameters that are passed to AWS_PROXY integrations. You can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Working with AWS service integrations for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html). For HTTP API integrations without a specified integrationSubtype request parameters are a key-value map specifying how to transform HTTP requests before sending them to the backend. The key should follow the pattern <action>:<header|querystring|path>.<location> where action can be append, overwrite or remove. For values, you can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Transforming API requests and responses (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html).
  --response-templates: record # A mapping of identifier keys to templates. The value is an actual template script. The key is typically a SelectionKey which is chosen based on evaluating a selection expression.
  --template-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}"
    path_params: [{name: apiId, var: api_id}, {name: integrationId, var: integration_id}, {name: integrationResponseId, var: integration_response_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentHandlingStrategy, var: content_handling_strategy}, {name: integrationResponseKey, var: integration_response_key}, {name: responseParameters, var: response_parameters}, {name: responseTemplates, var: response_templates}, {name: templateSelectionExpression, var: template_selection_expression}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, integration_id: $integration_id, integration_response_id: $integration_response_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, content_handling_strategy: $content_handling_strategy, integration_response_key: $integration_response_key, response_parameters: $response_parameters, response_templates: $response_templates, template_selection_expression: $template_selection_expression
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Model.
#
# DELETE /v2/apis/{apiId}/models/{modelId}
# operationId: DeleteModel
export def "delete-model" [
  api_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/models/{modelId}"
    path_params: [{name: apiId, var: api_id}, {name: modelId, var: model_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, model_id: $model_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Model.
#
# GET /v2/apis/{apiId}/models/{modelId}
# Returns: record<ContentType: string, Description: string, ModelId: string, Name: string, Schema: string>
# operationId: GetModel
export def "get-model" [
  api_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/models/{modelId}"
    path_params: [{name: apiId, var: api_id}, {name: modelId, var: model_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, model_id: $model_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Model.
#
# PATCH /v2/apis/{apiId}/models/{modelId}
# Returns: record<ContentType: string, Description: string, ModelId: string, Name: string, Schema: string>
# operationId: UpdateModel
export def "update-model" [
  api_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-type: string # A string with a length between [1-256].
  --description: string # A string with a length between [0-1024].
  --name: string # A string with a length between [1-128].
  --schema: string # A string with a length between [0-32768].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}/models/{modelId}"
    path_params: [{name: apiId, var: api_id}, {name: modelId, var: model_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: description, var: description}, {name: name, var: name}, {name: schema, var: schema}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, model_id: $model_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, content_type: $content_type, description: $description, name: $name, schema: $schema
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Route.
#
# DELETE /v2/apis/{apiId}/routes/{routeId}
# operationId: DeleteRoute
export def "delete-route" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/routes/{routeId}"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Route.
#
# GET /v2/apis/{apiId}/routes/{routeId}
# Returns: record<ApiGatewayManaged: bool, ApiKeyRequired: bool, AuthorizationScopes: list<string>, AuthorizationType: string, AuthorizerId: string, ModelSelectionExpression: string, OperationName: string, RequestModels: record, RequestParameters: record, RouteId: string, RouteKey: string, RouteResponseSelectionExpression: string, Target: string>
# operationId: GetRoute
export def "get-route" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/routes/{routeId}"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Route.
#
# PATCH /v2/apis/{apiId}/routes/{routeId}
# Returns: record<ApiGatewayManaged: bool, ApiKeyRequired: bool, AuthorizationScopes: list<string>, AuthorizationType: string, AuthorizerId: string, ModelSelectionExpression: string, OperationName: string, RequestModels: record, RequestParameters: record, RouteId: string, RouteKey: string, RouteResponseSelectionExpression: string, Target: string>
# operationId: UpdateRoute
export def "update-route" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --api-key-required: oneof<nothing, bool> # Specifies whether an API key is required for the route. Supported only for WebSocket APIs.
  --authorization-scopes: list<string> # A list of authorization scopes configured on a route. The scopes are used with a JWT authorizer to authorize the method invocation. The authorization works by matching the route scopes against the scopes parsed from the access token in the incoming request. The method invocation is authorized if any route scope matches a claimed scope in the access token. Otherwise, the invocation is not authorized. When the route scope is configured, the client must provide an access token instead of an identity token for authorization purposes.
  --authorization-type: string@authorization-type-completer # The authorization type. For WebSocket APIs, valid values are NONE for open access, AWS_IAM for using AWS IAM permissions, and CUSTOM for using a Lambda authorizer. For HTTP APIs, valid values are NONE for open access, JWT for using JSON Web Tokens, AWS_IAM for using AWS IAM permissions, and CUSTOM for using a Lambda authorizer.
  --authorizer-id: string # The identifier.
  --model-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --operation-name: string # A string with a length between [1-64].
  --request-models: record # The route models.
  --request-parameters: record # The route parameters.
  --route-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --route-response-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --target: string # A string with a length between [1-128].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}/routes/{routeId}"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiKeyRequired, var: api_key_required}, {name: authorizationScopes, var: authorization_scopes}, {name: authorizationType, var: authorization_type}, {name: authorizerId, var: authorizer_id}, {name: modelSelectionExpression, var: model_selection_expression}, {name: operationName, var: operation_name}, {name: requestModels, var: request_models}, {name: requestParameters, var: request_parameters}, {name: routeKey, var: route_key}, {name: routeResponseSelectionExpression, var: route_response_selection_expression}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, api_key_required: $api_key_required, authorization_scopes: $authorization_scopes, authorization_type: $authorization_type, authorizer_id: $authorizer_id, model_selection_expression: $model_selection_expression, operation_name: $operation_name, request_models: $request_models, request_parameters: $request_parameters, route_key: $route_key, route_response_selection_expression: $route_response_selection_expression, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a route request parameter.
#
# DELETE /v2/apis/{apiId}/routes/{routeId}/requestparameters/{requestParameterKey}
# operationId: DeleteRouteRequestParameter
export def "delete-route-request-parameter" [
  api_id: string
  route_id: string
  request_parameter_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/routes/{routeId}/requestparameters/{requestParameterKey}"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}, {name: requestParameterKey, var: request_parameter_key}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, request_parameter_key: $request_parameter_key, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a RouteResponse.
#
# DELETE /v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}
# operationId: DeleteRouteResponse
export def "delete-route-response" [
  api_id: string
  route_id: string
  route_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}, {name: routeResponseId, var: route_response_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, route_response_id: $route_response_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a RouteResponse.
#
# GET /v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}
# Returns: record<ModelSelectionExpression: string, ResponseModels: record, ResponseParameters: record, RouteResponseId: string, RouteResponseKey: string>
# operationId: GetRouteResponse
export def "get-route-response" [
  api_id: string
  route_id: string
  route_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}, {name: routeResponseId, var: route_response_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, route_response_id: $route_response_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a RouteResponse.
#
# PATCH /v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}
# Returns: record<ModelSelectionExpression: string, ResponseModels: record, ResponseParameters: record, RouteResponseId: string, RouteResponseKey: string>
# operationId: UpdateRouteResponse
export def "update-route-response" [
  api_id: string
  route_id: string
  route_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --model-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --response-models: record # The route models.
  --response-parameters: record # The route parameters.
  --route-response-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}"
    path_params: [{name: apiId, var: api_id}, {name: routeId, var: route_id}, {name: routeResponseId, var: route_response_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: modelSelectionExpression, var: model_selection_expression}, {name: responseModels, var: response_models}, {name: responseParameters, var: response_parameters}, {name: routeResponseKey, var: route_response_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, route_id: $route_id, route_response_id: $route_response_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, model_selection_expression: $model_selection_expression, response_models: $response_models, response_parameters: $response_parameters, route_response_key: $route_response_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the RouteSettings for a stage.
#
# DELETE /v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}
# operationId: DeleteRouteSettings
export def "delete-route-settings" [
  api_id: string
  stage_name: string
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}"
    path_params: [{name: apiId, var: api_id}, {name: stageName, var: stage_name}, {name: routeKey, var: route_key}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, stage_name: $stage_name, route_key: $route_key, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Stage.
#
# DELETE /v2/apis/{apiId}/stages/{stageName}
# operationId: DeleteStage
export def "delete-stage" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/stages/{stageName}"
    path_params: [{name: apiId, var: api_id}, {name: stageName, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Stage.
#
# GET /v2/apis/{apiId}/stages/{stageName}
# Returns: record<AccessLogSettings: record<DestinationArn: string, Format: string>, ApiGatewayManaged: bool, AutoDeploy: bool, ClientCertificateId: string, CreatedDate: string, DefaultRouteSettings: record<DataTraceEnabled: bool, DetailedMetricsEnabled: bool, LoggingLevel: string, ThrottlingBurstLimit: int, ThrottlingRateLimit: float>, DeploymentId: string, Description: string, LastDeploymentStatusMessage: string, LastUpdatedDate: string, RouteSettings: record, StageName: string, StageVariables: record, Tags: record>
# operationId: GetStage
export def "get-stage" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/stages/{stageName}"
    path_params: [{name: apiId, var: api_id}, {name: stageName, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Stage.
#
# PATCH /v2/apis/{apiId}/stages/{stageName}
# Returns: record<AccessLogSettings: record<DestinationArn: string, Format: string>, ApiGatewayManaged: bool, AutoDeploy: bool, ClientCertificateId: string, CreatedDate: string, DefaultRouteSettings: record<DataTraceEnabled: bool, DetailedMetricsEnabled: bool, LoggingLevel: string, ThrottlingBurstLimit: int, ThrottlingRateLimit: float>, DeploymentId: string, Description: string, LastDeploymentStatusMessage: string, LastUpdatedDate: string, RouteSettings: record, StageName: string, StageVariables: record, Tags: record>
# operationId: UpdateStage
export def "update-stage" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --access-log-settings: record # Settings for logging access in a stage. — shape: {DestinationArn?: string, Format?: string}
  --auto-deploy: oneof<nothing, bool> # Specifies whether updates to an API automatically trigger a new deployment. The default value is false.
  --client-certificate-id: string # The identifier.
  --default-route-settings: record # Represents a collection of route settings. — shape: {DataTraceEnabled?: bool, DetailedMetricsEnabled?: bool, LoggingLevel?: "ERROR"|"INFO"|"OFF", ThrottlingBurstLimit?: int, ThrottlingRateLimit?: float}
  --deployment-id: string # The identifier.
  --description: string # A string with a length between [0-1024].
  --route-settings: record # The route settings map.
  --stage-variables: record # The stage variable map.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/apis/{apiId}/stages/{stageName}"
    path_params: [{name: apiId, var: api_id}, {name: stageName, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessLogSettings, var: access_log_settings}, {name: autoDeploy, var: auto_deploy}, {name: clientCertificateId, var: client_certificate_id}, {name: defaultRouteSettings, var: default_route_settings}, {name: deploymentId, var: deployment_id}, {name: description, var: description}, {name: routeSettings, var: route_settings}, {name: stageVariables, var: stage_variables}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, access_log_settings: $access_log_settings, auto_deploy: $auto_deploy, client_certificate_id: $client_certificate_id, default_route_settings: $default_route_settings, deployment_id: $deployment_id, description: $description, route_settings: $route_settings, stage_variables: $stage_variables
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a VPC link.
#
# DELETE /v2/vpclinks/{vpcLinkId}
# Returns: record
# operationId: DeleteVpcLink
export def "delete-vpc-link" [
  vpc_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/vpclinks/{vpcLinkId}"
    path_params: [{name: vpcLinkId, var: vpc_link_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    vpc_link_id: $vpc_link_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a VPC link.
#
# GET /v2/vpclinks/{vpcLinkId}
# Returns: record<CreatedDate: string, Name: string, SecurityGroupIds: list<string>, SubnetIds: list<string>, Tags: record, VpcLinkId: string, VpcLinkStatus: string, VpcLinkStatusMessage: string, VpcLinkVersion: string>
# operationId: GetVpcLink
export def "get-vpc-link" [
  vpc_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/vpclinks/{vpcLinkId}"
    path_params: [{name: vpcLinkId, var: vpc_link_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vpc_link_id: $vpc_link_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a VPC link.
#
# PATCH /v2/vpclinks/{vpcLinkId}
# Returns: record<CreatedDate: string, Name: string, SecurityGroupIds: list<string>, SubnetIds: list<string>, Tags: record, VpcLinkId: string, VpcLinkStatus: string, VpcLinkStatusMessage: string, VpcLinkVersion: string>
# operationId: UpdateVpcLink
export def "update-vpc-link" [
  vpc_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --name: string # A string with a length between [1-128].
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/vpclinks/{vpcLinkId}"
    path_params: [{name: vpcLinkId, var: vpc_link_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vpc_link_id: $vpc_link_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v2/apis/{apiId}/exports/{specification}
#
# Returns: record<body: string>
# operationId: ExportApi
export def "export-api" [
  api_id: string
  specification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --export-version: string # The version of the API Gateway export algorithm. API Gateway uses the latest version by default. Currently, the only supported version is 1.0.
  --include-extensions: oneof<nothing, bool> # Specifies whether to include API Gateway extensions (https://docs.aws.amazon.com//apigateway/latest/developerguide/api-gateway-swagger-extensions.html) in the exported API definition. API Gateway extensions are included by default.
  --output-type: string # The output type of the exported definition file. Valid values are JSON and YAML. (required)
  --stage-name: string # The name of the API stage to export. If you don't specify this property, a representation of the latest API configuration is exported.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/exports/{specification}"
    path_params: [{name: apiId, var: api_id}, {name: specification, var: specification}]
    query: [{name: exportVersion, var: export_version}, {name: includeExtensions, var: include_extensions}, {name: outputType, var: output_type, required: true}, {name: stageName, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, specification: $specification, export_version: $export_version, include_extensions: $include_extensions, output_type: $output_type, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets all authorizer cache entries on a stage. Supported only for HTTP APIs.
#
# DELETE /v2/apis/{apiId}/stages/{stageName}/cache/authorizers
# operationId: ResetAuthorizersCache
export def "reset-authorizers-cache" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/apis/{apiId}/stages/{stageName}/cache/authorizers"
    path_params: [{name: apiId, var: api_id}, {name: stageName, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_id: $api_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a model template.
#
# GET /v2/apis/{apiId}/models/{modelId}/template
# Returns: record<Value: string>
# operationId: GetModelTemplate
export def "get-model-template" [
  api_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/apis/{apiId}/models/{modelId}/template"
    path_params: [{name: apiId, var: api_id}, {name: modelId, var: model_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, model_id: $model_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a collection of Tag resources.
#
# GET /v2/tags/{resource-arn}
# Returns: record<Tags: record>
# operationId: GetTags
export def "get-tags" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Tag resource to represent a tag.
#
# POST /v2/tags/{resource-arn}
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --tags: record # Represents a collection of tags associated with the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Tag.
#
# DELETE /v2/tags/{resource-arn}
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # The Tag keys to delete (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
