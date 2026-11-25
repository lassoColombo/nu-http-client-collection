# Auto-generated client for Amazon API Gateway v2015-07-09
# Source: https://api.apis.guru/v2/specs/amazonaws.com/apigateway/2015-07-09/openapi.json
# Auth: --token flag or $env.AMAZON_API_GATEWAY_TOKEN

const CLIENT = {
  base_url: "http://apigateway.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_API_GATEWAY_TOKEN"
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
def type-completer [] { ["COGNITO_USER_POOLS" "REQUEST" "TOKEN"] }
def cache-cluster-size-completer [] { ["0.5" "1.6" "118" "13.5" "237" "28.4" "58.2" "6.1"] }
def type-completer-1 [] { ["API" "AUTHORIZER" "METHOD" "MODEL" "PATH_PARAMETER" "QUERY_PARAMETER" "REQUEST_BODY" "REQUEST_HEADER" "RESOURCE" "RESPONSE" "RESPONSE_BODY" "RESPONSE_HEADER"] }
def location-status-completer [] { ["DOCUMENTED" "UNDOCUMENTED"] }
def mode-completer [] { ["merge" "overwrite"] }
def security-policy-completer [] { ["TLS_1_0" "TLS_1_2"] }
def api-key-source-completer [] { ["AUTHORIZER" "HEADER"] }
def response-type-completer [] { ["ACCESS_DENIED" "API_CONFIGURATION_ERROR" "AUTHORIZER_CONFIGURATION_ERROR" "AUTHORIZER_FAILURE" "BAD_REQUEST_BODY" "BAD_REQUEST_PARAMETERS" "DEFAULT_4XX" "DEFAULT_5XX" "EXPIRED_TOKEN" "INTEGRATION_FAILURE" "INTEGRATION_TIMEOUT" "INVALID_API_KEY" "INVALID_SIGNATURE" "MISSING_AUTHENTICATION_TOKEN" "QUOTA_EXCEEDED" "REQUEST_TOO_LARGE" "RESOURCE_NOT_FOUND" "THROTTLED" "UNAUTHORIZED" "UNSUPPORTED_MEDIA_TYPE" "WAF_FILTERED"] }
def type-completer-2 [] { ["AWS" "AWS_PROXY" "HTTP" "HTTP_PROXY" "MOCK"] }
def connection-type-completer [] { ["INTERNET" "VPC_LINK"] }
def content-handling-completer [] { ["CONVERT_TO_BINARY" "CONVERT_TO_TEXT"] }
def format-completer [] { ["csv"] }
def mode-completer-1 [] { ["import"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-api-key: "record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>"
    get-api-keys: "record<warnings: list<string>, position: string, items: table<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list, tags: record>>"
    create-authorizer: "record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>"
    get-authorizers: "record<position: string, items: table<id: string, name: string, type: string, providerARNs: list, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>>"
    create-base-path-mapping: "record<basePath: string, restApiId: string, stage: string>"
    get-base-path-mappings: "record<position: string, items: table<basePath: string, restApiId: string, stage: string>>"
    create-deployment: "record<id: string, description: string, createdDate: string, apiSummary: record>"
    get-deployments: "record<position: string, items: table<id: string, description: string, createdDate: string, apiSummary: record>>"
    create-documentation-part: "record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>"
    get-documentation-parts: "record<position: string, items: table<id: string, location: record, properties: any>>"
    import-documentation-parts: "record<ids: list<string>, warnings: list<string>>"
    create-documentation-version: "record<version: string, createdDate: string, description: string>"
    get-documentation-versions: "record<position: string, items: table<version: string, createdDate: string, description: string>>"
    create-domain-name: "record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>"
    get-domain-names: "record<position: string, items: table<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record, ownershipVerificationCertificateArn: string>>"
    create-model: "record<id: string, name: string, description: string, schema: string, contentType: string>"
    get-models: "record<position: string, items: table<id: string, name: string, description: string, schema: string, contentType: string>>"
    create-request-validator: "record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>"
    get-request-validators: "record<position: string, items: table<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>>"
    create-resource: "record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>"
    create-rest-api: "record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>"
    get-rest-apis: "record<position: string, items: table<id: string, name: string, description: string, createdDate: string, version: string, warnings: list, binaryMediaTypes: list, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record, policy: string, tags: record, disableExecuteApiEndpoint: bool>>"
    create-stage: "record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>"
    get-stages: "record<item: table<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record, canarySettings: record, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>>"
    create-usage-plan: "record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>"
    get-usage-plans: "record<position: string, items: table<id: string, name: string, description: string, apiStages: list, throttle: record, quota: record, productCode: string, tags: record>>"
    create-usage-plan-key: "record<id: string, type: string, value: string, name: string>"
    get-usage-plan-keys: "record<position: string, items: table<id: string, type: string, value: string, name: string>>"
    create-vpc-link: "record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>"
    get-vpc-links: "record<position: string, items: table<id: string, name: string, description: string, targetArns: list, status: string, statusMessage: string, tags: record>>"
    get-api-key: "record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>"
    update-api-key: "record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>"
    get-authorizer: "record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>"
    test-invoke-authorizer: "record<clientStatus: int, log: string, latency: int, principalId: string, policy: string, authorization: record, claims: record>"
    update-authorizer: "record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>"
    get-base-path-mapping: "record<basePath: string, restApiId: string, stage: string>"
    update-base-path-mapping: "record<basePath: string, restApiId: string, stage: string>"
    get-client-certificate: "record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>"
    update-client-certificate: "record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>"
    get-deployment: "record<id: string, description: string, createdDate: string, apiSummary: record>"
    update-deployment: "record<id: string, description: string, createdDate: string, apiSummary: record>"
    get-documentation-part: "record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>"
    update-documentation-part: "record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>"
    get-documentation-version: "record<version: string, createdDate: string, description: string>"
    update-documentation-version: "record<version: string, createdDate: string, description: string>"
    get-domain-name: "record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>"
    update-domain-name: "record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>"
    get-gateway-response: "record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>"
    put-gateway-response: "record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>"
    update-gateway-response: "record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>"
    get-integration: "record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>"
    put-integration: "record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>"
    update-integration: "record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>"
    get-integration-response: "record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>"
    put-integration-response: "record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>"
    update-integration-response: "record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>"
    get-method: "record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>"
    put-method: "record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>"
    test-invoke-method: "record<status: int, body: string, headers: record, multiValueHeaders: record, log: string, latency: int>"
    update-method: "record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>"
    get-method-response: "record<statusCode: string, responseParameters: record, responseModels: record>"
    put-method-response: "record<statusCode: string, responseParameters: record, responseModels: record>"
    update-method-response: "record<statusCode: string, responseParameters: record, responseModels: record>"
    get-model: "record<id: string, name: string, description: string, schema: string, contentType: string>"
    update-model: "record<id: string, name: string, description: string, schema: string, contentType: string>"
    get-request-validator: "record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>"
    update-request-validator: "record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>"
    get-resource: "record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>"
    update-resource: "record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>"
    get-rest-api: "record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>"
    put-rest-api: "record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>"
    update-rest-api: "record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>"
    get-stage: "record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>"
    update-stage: "record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>"
    get-usage-plan: "record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>"
    update-usage-plan: "record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>"
    get-usage-plan-key: "record<id: string, type: string, value: string, name: string>"
    get-vpc-link: "record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>"
    update-vpc-link: "record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>"
    generate-client-certificate: "record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>"
    get-client-certificates: "record<position: string, items: table<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>>"
    get-account: "record<cloudwatchRoleArn: string, throttleSettings: record<burstLimit: int, rateLimit: float>, features: list<string>, apiKeyVersion: string>"
    update-account: "record<cloudwatchRoleArn: string, throttleSettings: record<burstLimit: int, rateLimit: float>, features: list<string>, apiKeyVersion: string>"
    get-export: "record<body: string>"
    get-gateway-responses: "record<position: string, items: table<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>>"
    get-model-template: "record<value: string>"
    get-resources: "record<position: string, items: table<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>>"
    get-sdk: "record<body: string>"
    get-sdk-type: "record<id: string, friendlyName: string, description: string, configurationProperties: table<name: string, friendlyName: string, description: string, required: bool, defaultValue: string>>"
    get-sdk-types: "record<position: string, items: table<id: string, friendlyName: string, description: string, configurationProperties: list>>"
    get-tags: "record<tags: record>"
    get-usage: "record<usagePlanId: string, startDate: string, endDate: string, position: string, items: record>"
    import-api-keys: "record<ids: list<string>, warnings: list<string>>"
    import-rest-api: "record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>"
    update-usage: "record<usagePlanId: string, startDate: string, endDate: string, position: string, items: record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-api-key" "get-api-keys" "create-authorizer" "get-authorizers" "create-base-path-mapping" "get-base-path-mappings" "create-deployment" "get-deployments" "create-documentation-part" "get-documentation-parts" "import-documentation-parts" "create-documentation-version" "get-documentation-versions" "create-domain-name" "get-domain-names" "create-model" "get-models" "create-request-validator" "get-request-validators" "create-resource" "create-rest-api" "get-rest-apis" "create-stage" "get-stages" "create-usage-plan" "get-usage-plans" "create-usage-plan-key" "get-usage-plan-keys" "create-vpc-link" "get-vpc-links" "delete-api-key" "get-api-key" "update-api-key" "delete-authorizer" "get-authorizer" "test-invoke-authorizer" "update-authorizer" "delete-base-path-mapping" "get-base-path-mapping" "update-base-path-mapping" "delete-client-certificate" "get-client-certificate" "update-client-certificate" "delete-deployment" "get-deployment" "update-deployment" "delete-documentation-part" "get-documentation-part" "update-documentation-part" "delete-documentation-version" "get-documentation-version" "update-documentation-version" "delete-domain-name" "get-domain-name" "update-domain-name" "delete-gateway-response" "get-gateway-response" "put-gateway-response" "update-gateway-response" "delete-integration" "get-integration" "put-integration" "update-integration" "delete-integration-response" "get-integration-response" "put-integration-response" "update-integration-response" "delete-method" "get-method" "put-method" "test-invoke-method" "update-method" "delete-method-response" "get-method-response" "put-method-response" "update-method-response" "delete-model" "get-model" "update-model" "delete-request-validator" "get-request-validator" "update-request-validator" "delete-resource" "get-resource" "update-resource" "delete-rest-api" "get-rest-api" "put-rest-api" "update-rest-api" "delete-stage" "get-stage" "update-stage" "delete-usage-plan" "get-usage-plan" "update-usage-plan" "delete-usage-plan-key" "get-usage-plan-key" "delete-vpc-link" "get-vpc-link" "update-vpc-link" "flush-stage-authorizers-cache" "flush-stage-cache" "generate-client-certificate" "get-client-certificates" "get-account" "update-account" "get-export" "get-gateway-responses" "get-model-template" "get-resources" "get-sdk" "get-sdk-type" "get-sdk-types" "get-tags" "tag-resource" "get-usage" "import-api-keys" "import-rest-api" "untag-resource" "update-usage" "commands"] | sort) } | get name | first)
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

# Create an ApiKey resource.
#
# POST /apikeys
# Returns: record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>
# operationId: CreateApiKey
export def "create-api-key" [
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
  --name: string # The name of the ApiKey.
  --description: string # The description of the ApiKey.
  --enabled: oneof<nothing, bool> # Specifies whether the ApiKey can be used by callers.
  --generate-distinct-id: oneof<nothing, bool> # Specifies whether (true) or not (false) the key identifier is distinct from the created API key value. This parameter is deprecated and should not be used.
  --value: string # Specifies a value of the API key.
  --stage-keys: list # DEPRECATED FOR USAGE PLANS - Specifies stages associated with the API key. — item shape: {restApiId?: string, stageName?: string}
  --customer-id: string # An AWS Marketplace customer identifier , when integrating with the AWS SaaS Marketplace.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apikeys"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: enabled, var: enabled}, {name: generateDistinctId, var: generate_distinct_id}, {name: value, var: value}, {name: stageKeys, var: stage_keys}, {name: customerId, var: customer_id}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, enabled: $enabled, generate_distinct_id: $generate_distinct_id, value: $value, stage_keys: $stage_keys, customer_id: $customer_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the current ApiKeys resource.
#
# GET /apikeys
# Returns: record<warnings: list<string>, position: string, items: table<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list, tags: record>>
# operationId: GetApiKeys
export def "get-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --name: string # The name of queried API keys.
  --customer-id: string # The identifier of a customer in AWS Marketplace or an external system, such as a developer portal.
  --include-values: oneof<nothing, bool> # A boolean flag to specify whether (true) or not (false) the result contains key values.
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
    path: "/apikeys"
    query: [{name: position, var: position}, {name: limit, var: limit}, {name: name, var: name}, {name: customerId, var: customer_id}, {name: includeValues, var: include_values}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    position: $position, limit: $limit, name: $name, customer_id: $customer_id, include_values: $include_values, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new Authorizer resource to an existing RestApi resource.
#
# POST /restapis/{restapi_id}/authorizers
# Returns: record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>
# operationId: CreateAuthorizer
export def "create-authorizer" [
  restapi_id: string
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
  name: string # The name of the authorizer.
  type: string@type-completer # The authorizer type. Valid values are TOKEN for a Lambda function using a single authorization token submitted in a custom header, REQUEST for a Lambda function using incoming request parameters, and COGNITO_USER_POOLS for using an Amazon Cognito user pool.
  --provider-ar-ns: list<string> # A list of the Amazon Cognito user pool ARNs for the COGNITO_USER_POOLS authorizer. Each element is of this format: arn:aws:cognito-idp:{region}:{account_id}:userpool/{user_pool_id}. For a TOKEN or REQUEST authorizer, this is not defined.
  --auth-type: string # Optional customer-defined field, used in OpenAPI imports and exports without functional impact.
  --authorizer-uri: string # Specifies the authorizer's Uniform Resource Identifier (URI). For TOKEN or REQUEST authorizers, this must be a well-formed Lambda function URI, for example, arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:{account_id}:function:{lambda_function_name}/invocations. In general, the URI has this form arn:aws:apigateway:{region}:lambda:path/{service_api}, where {region} is the same as the region hosting the Lambda function, path indicates that the remaining substring in the URI should be treated as the path to the resource, including the initial /. For Lambda functions, this is usually of the form /2015-03-31/functions/[FunctionARN]/invocations.
  --authorizer-credentials: string # Specifies the required credentials as an IAM role for API Gateway to invoke the authorizer. To specify an IAM role for API Gateway to assume, use the role's Amazon Resource Name (ARN). To use resource-based permissions on the Lambda function, specify null.
  --identity-source: string # The identity source for which authorization is requested. For a TOKEN or COGNITO_USER_POOLS authorizer, this is required and specifies the request header mapping expression for the custom header holding the authorization token submitted by the client. For example, if the token header name is Auth, the header mapping expression is method.request.header.Auth. For the REQUEST authorizer, this is required when authorization caching is enabled. The value is a comma-separated string of one or more mapping expressions of the specified request parameters. For example, if an Auth header, a Name query string parameter are defined as identity sources, this value is method.request.header.Auth, method.request.querystring.Name. These parameters will be used to derive the authorization caching key and to perform runtime validation of the REQUEST authorizer by verifying all of the identity-related request parameters are present, not null and non-empty. Only when this is true does the authorizer invoke the authorizer Lambda function, otherwise, it returns a 401 Unauthorized response without calling the Lambda function. The valid value is a string of comma-separated mapping expressions of the specified request parameters. When the authorization caching is not enabled, this property is optional.
  --identity-validation-expression: string # A validation expression for the incoming identity token. For TOKEN authorizers, this value is a regular expression. For COGNITO_USER_POOLS authorizers, API Gateway will match the aud field of the incoming token from the client against the specified regular expression. It will invoke the authorizer's Lambda function when there is a match. Otherwise, it will return a 401 Unauthorized response without calling the Lambda function. The validation expression does not apply to the REQUEST authorizer.
  --authorizer-result-ttl-in-seconds: int # The TTL in seconds of cached authorizer results. If it equals 0, authorization caching is disabled. If it is greater than 0, API Gateway will cache authorizer responses. If this field is not set, the default value is 300. The maximum value is 3600, or 1 hour.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/authorizers"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: type, var: type}, {name: providerARNs, var: provider_ar_ns}, {name: authType, var: auth_type}, {name: authorizerUri, var: authorizer_uri}, {name: authorizerCredentials, var: authorizer_credentials}, {name: identitySource, var: identity_source}, {name: identityValidationExpression, var: identity_validation_expression}, {name: authorizerResultTtlInSeconds, var: authorizer_result_ttl_in_seconds}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, type: $type, provider_ar_ns: $provider_ar_ns, auth_type: $auth_type, authorizer_uri: $authorizer_uri, authorizer_credentials: $authorizer_credentials, identity_source: $identity_source, identity_validation_expression: $identity_validation_expression, authorizer_result_ttl_in_seconds: $authorizer_result_ttl_in_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe an existing Authorizers resource.
#
# GET /restapis/{restapi_id}/authorizers
# Returns: record<position: string, items: table<id: string, name: string, type: string, providerARNs: list, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>>
# operationId: GetAuthorizers
export def "get-authorizers" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/restapis/{restapi_id}/authorizers"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new BasePathMapping resource.
#
# POST /domainnames/{domain_name}/basepathmappings
# Returns: record<basePath: string, restApiId: string, stage: string>
# operationId: CreateBasePathMapping
export def "create-base-path-mapping" [
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
  --base-path: string # The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify a base path name after the domain name.
  rest_api_id: string # The string identifier of the associated RestApi.
  --stage: string # The name of the API's stage that you want to use for this mapping. Specify '(none)' if you want callers to explicitly specify the stage name after any base path name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domainnames/{domain_name}/basepathmappings"
    path_params: [{name: domain_name, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: basePath, var: base_path}, {name: restApiId, var: rest_api_id}, {name: stage, var: stage}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, base_path: $base_path, rest_api_id: $rest_api_id, stage: $stage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents a collection of BasePathMapping resources.
#
# GET /domainnames/{domain_name}/basepathmappings
# Returns: record<position: string, items: table<basePath: string, restApiId: string, stage: string>>
# operationId: GetBasePathMappings
export def "get-base-path-mappings" [
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
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/domainnames/{domain_name}/basepathmappings"
    path_params: [{name: domain_name, var: domain_name}]
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Deployment resource, which makes a specified RestApi callable over the internet.
#
# POST /restapis/{restapi_id}/deployments
# Returns: record<id: string, description: string, createdDate: string, apiSummary: record>
# operationId: CreateDeployment
export def "create-deployment" [
  restapi_id: string
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
  --stage-name: string # The name of the Stage resource for the Deployment resource to create.
  --stage-description: string # The description of the Stage resource for the Deployment resource to create.
  --description: string # The description for the Deployment resource to create.
  --cache-cluster-enabled: oneof<nothing, bool> # Enables a cache cluster for the Stage resource specified in the input.
  --cache-cluster-size: string@cache-cluster-size-completer # Returns the size of the CacheCluster.
  --variables: record # A map that defines the stage variables for the Stage resource that is associated with the new deployment. Variable names can have alphanumeric and underscore characters, and the values must match [A-Za-z0-9-._~:/?#&=,]+.
  --canary-settings: record # The input configuration for a canary deployment. — shape: {percentTraffic?: float, stageVariableOverrides?: record, useStageCache?: bool}
  --tracing-enabled: oneof<nothing, bool> # Specifies whether active tracing with X-ray is enabled for the Stage.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/deployments"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: stageName, var: stage_name}, {name: stageDescription, var: stage_description}, {name: description, var: description}, {name: cacheClusterEnabled, var: cache_cluster_enabled}, {name: cacheClusterSize, var: cache_cluster_size}, {name: variables, var: variables}, {name: canarySettings, var: canary_settings}, {name: tracingEnabled, var: tracing_enabled}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, stage_name: $stage_name, stage_description: $stage_description, description: $description, cache_cluster_enabled: $cache_cluster_enabled, cache_cluster_size: $cache_cluster_size, variables: $variables, canary_settings: $canary_settings, tracing_enabled: $tracing_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Deployments collection.
#
# GET /restapis/{restapi_id}/deployments
# Returns: record<position: string, items: table<id: string, description: string, createdDate: string, apiSummary: record>>
# operationId: GetDeployments
export def "get-deployments" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/restapis/{restapi_id}/deployments"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a documentation part.
#
# POST /restapis/{restapi_id}/documentation/parts
# Returns: record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>
# operationId: CreateDocumentationPart
export def "create-documentation-part" [
  restapi_id: string
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
  location: record # Specifies the target API entity to which the documentation applies. — shape: {type?: "API"|"AUTHORIZER"|"MODEL"|"RESOURCE"|"METHOD"|"PATH_PARAMETER"|"QUERY_PARAMETER"|"REQUEST_HEADER"|"REQUEST_BODY"|"RESPONSE"|"RESPONSE_HEADER"|"RESPONSE_BODY", path?: string, method?: string, statusCode?: string, name?: string}
  properties: string # The new documentation content map of the targeted API entity. Enclosed key-value pairs are API-specific, but only OpenAPI-compliant key-value pairs can be exported and, hence, published.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/documentation/parts"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets documentation parts.
#
# GET /restapis/{restapi_id}/documentation/parts
# Returns: record<position: string, items: table<id: string, location: record, properties: any>>
# operationId: GetDocumentationParts
export def "get-documentation-parts" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The type of API entities of the to-be-retrieved documentation parts.
  --name: string # The name of API entities of the to-be-retrieved documentation parts.
  --path: string # The path of API entities of the to-be-retrieved documentation parts.
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --location-status: string@location-status-completer # The status of the API documentation parts to retrieve. Valid values are DOCUMENTED for retrieving DocumentationPart resources with content and UNDOCUMENTED for DocumentationPart resources without content.
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
    path: "/restapis/{restapi_id}/documentation/parts"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: type, var: type}, {name: name, var: name}, {name: path, var: path}, {name: position, var: position}, {name: limit, var: limit}, {name: locationStatus, var: location_status}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, type: $type, name: $name, path: $path, position: $position, limit: $limit, location_status: $location_status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports documentation parts
#
# PUT /restapis/{restapi_id}/documentation/parts
# Returns: record<ids: list<string>, warnings: list<string>>
# operationId: ImportDocumentationParts
export def "import-documentation-parts" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # A query parameter to indicate whether to overwrite (OVERWRITE) any existing DocumentationParts definition or to merge (MERGE) the new definition into the existing one. The default value is MERGE.
  --failonwarnings: oneof<nothing, bool> # A query parameter to specify whether to rollback the documentation importation (true) or not (false) when a warning is encountered. The default value is false.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # Raw byte array representing the to-be-imported documentation parts. To import from an OpenAPI file, this is a JSON object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restapis/{restapi_id}/documentation/parts"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: mode, var: mode}, {name: failonwarnings, var: failonwarnings}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, mode: $mode, failonwarnings: $failonwarnings, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a documentation version
#
# POST /restapis/{restapi_id}/documentation/versions
# Returns: record<version: string, createdDate: string, description: string>
# operationId: CreateDocumentationVersion
export def "create-documentation-version" [
  restapi_id: string
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
  documentation_version: string # The version identifier of the new snapshot.
  --stage-name: string # The stage name to be associated with the new documentation snapshot.
  --description: string # A description about the new documentation snapshot.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/documentation/versions"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: documentationVersion, var: documentation_version}, {name: stageName, var: stage_name}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, documentation_version: $documentation_version, stage_name: $stage_name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets documentation versions.
#
# GET /restapis/{restapi_id}/documentation/versions
# Returns: record<position: string, items: table<version: string, createdDate: string, description: string>>
# operationId: GetDocumentationVersions
export def "get-documentation-versions" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/restapis/{restapi_id}/documentation/versions"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new domain name.
#
# POST /domainnames
# Returns: record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>
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
  domain_name: string # The name of the DomainName resource.
  --certificate-name: string # The user-friendly name of the certificate that will be used by edge-optimized endpoint for this domain name.
  --certificate-body: string # [Deprecated] The body of the server certificate that will be used by edge-optimized endpoint for this domain name provided by your certificate authority.
  --certificate-private-key: string # [Deprecated] Your edge-optimized endpoint's domain name certificate's private key.
  --certificate-chain: string # [Deprecated] The intermediate certificates and optionally the root certificate, one after the other without any blank lines, used by an edge-optimized endpoint for this domain name. If you include the root certificate, your certificate chain must start with intermediate certificates and end with the root certificate. Use the intermediate certificates that were provided by your certificate authority. Do not include any intermediaries that are not in the chain of trust path.
  --certificate-arn: string # The reference to an AWS-managed certificate that will be used by edge-optimized endpoint for this domain name. AWS Certificate Manager is the only supported source.
  --regional-certificate-name: string # The user-friendly name of the certificate that will be used by regional endpoint for this domain name.
  --regional-certificate-arn: string # The reference to an AWS-managed certificate that will be used by regional endpoint for this domain name. AWS Certificate Manager is the only supported source.
  --endpoint-configuration: record # The endpoint configuration to indicate the types of endpoints an API (RestApi) or its custom domain name (DomainName) has. — shape: {types?: list<string>, vpcEndpointIds?: list<string>}
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
  --security-policy: string@security-policy-completer # The Transport Layer Security (TLS) version + cipher suite for this DomainName. The valid values are TLS_1_0 and TLS_1_2.
  --mutual-tls-authentication: record # The mutual TLS authentication configuration for a custom domain name. If specified, API Gateway performs two-way authentication between the client and the server. Clients must present a trusted certificate to access your API. — shape: {truststoreUri?: string, truststoreVersion?: string}
  --ownership-verification-certificate-arn: string # The ARN of the public certificate issued by ACM to validate ownership of your custom domain. Only required when configuring mutual TLS and using an ACM imported or private CA certificate ARN as the regionalCertificateArn.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domainnames"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: certificateName, var: certificate_name}, {name: certificateBody, var: certificate_body}, {name: certificatePrivateKey, var: certificate_private_key}, {name: certificateChain, var: certificate_chain}, {name: certificateArn, var: certificate_arn}, {name: regionalCertificateName, var: regional_certificate_name}, {name: regionalCertificateArn, var: regional_certificate_arn}, {name: endpointConfiguration, var: endpoint_configuration}, {name: tags, var: tags}, {name: securityPolicy, var: security_policy}, {name: mutualTlsAuthentication, var: mutual_tls_authentication}, {name: ownershipVerificationCertificateArn, var: ownership_verification_certificate_arn}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name, certificate_name: $certificate_name, certificate_body: $certificate_body, certificate_private_key: $certificate_private_key, certificate_chain: $certificate_chain, certificate_arn: $certificate_arn, regional_certificate_name: $regional_certificate_name, regional_certificate_arn: $regional_certificate_arn, endpoint_configuration: $endpoint_configuration, tags: $tags, security_policy: $security_policy, mutual_tls_authentication: $mutual_tls_authentication, ownership_verification_certificate_arn: $ownership_verification_certificate_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents a collection of DomainName resources.
#
# GET /domainnames
# Returns: record<position: string, items: table<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record, ownershipVerificationCertificateArn: string>>
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
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/domainnames"
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new Model resource to an existing RestApi resource.
#
# POST /restapis/{restapi_id}/models
# Returns: record<id: string, name: string, description: string, schema: string, contentType: string>
# operationId: CreateModel
export def "create-model" [
  restapi_id: string
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
  name: string # The name of the model. Must be alphanumeric.
  --description: string # The description of the model.
  --schema: string # The schema for the model. For application/json models, this should be JSON schema draft 4 model.
  content_type: string # The content-type for the model.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/models"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: schema, var: schema}, {name: contentType, var: content_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, schema: $schema, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes existing Models defined for a RestApi resource.
#
# GET /restapis/{restapi_id}/models
# Returns: record<position: string, items: table<id: string, name: string, description: string, schema: string, contentType: string>>
# operationId: GetModels
export def "get-models" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/restapis/{restapi_id}/models"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a RequestValidator of a given RestApi.
#
# POST /restapis/{restapi_id}/requestvalidators
# Returns: record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>
# operationId: CreateRequestValidator
export def "create-request-validator" [
  restapi_id: string
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
  --name: string # The name of the to-be-created RequestValidator.
  --validate-request-body: oneof<nothing, bool> # A Boolean flag to indicate whether to validate request body according to the configured model schema for the method (true) or not (false).
  --validate-request-parameters: oneof<nothing, bool> # A Boolean flag to indicate whether to validate request parameters, true, or not false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/requestvalidators"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: validateRequestBody, var: validate_request_body}, {name: validateRequestParameters, var: validate_request_parameters}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, validate_request_body: $validate_request_body, validate_request_parameters: $validate_request_parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the RequestValidators collection of a given RestApi.
#
# GET /restapis/{restapi_id}/requestvalidators
# Returns: record<position: string, items: table<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>>
# operationId: GetRequestValidators
export def "get-request-validators" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/restapis/{restapi_id}/requestvalidators"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Resource resource.
#
# POST /restapis/{restapi_id}/resources/{parent_id}
# Returns: record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>
# operationId: CreateResource
export def "create-resource" [
  restapi_id: string
  parent_id: string
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
  path_part: string # The last path segment for this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/resources/{parent_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: parent_id, var: parent_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: pathPart, var: path_part}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, parent_id: $parent_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, path_part: $path_part
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new RestApi resource.
#
# POST /restapis
# Returns: record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>
# operationId: CreateRestApi
export def "create-rest-api" [
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
  name: string # The name of the RestApi.
  --description: string # The description of the RestApi.
  --version: string # A version identifier for the API.
  --clone-from: string # The ID of the RestApi that you want to clone from.
  --binary-media-types: list<string> # The list of binary media types supported by the RestApi. By default, the RestApi supports only UTF-8-encoded text payloads.
  --minimum-compression-size: int # A nullable integer that is used to enable compression (with non-negative between 0 and 10485760 (10M) bytes, inclusive) or disable compression (with a null value) on an API. When compression is enabled, compression or decompression is not applied on the payload if the payload size is smaller than this value. Setting it to zero allows compression for any payload size.
  --api-key-source: string@api-key-source-completer # The source of the API key for metering requests according to a usage plan. Valid values are: >HEADER to read the API key from the X-API-Key header of a request. AUTHORIZER to read the API key from the UsageIdentifierKey from a custom authorizer.
  --endpoint-configuration: record # The endpoint configuration to indicate the types of endpoints an API (RestApi) or its custom domain name (DomainName) has. — shape: {types?: list<string>, vpcEndpointIds?: list<string>}
  --policy: string # A stringified JSON policy document that applies to this RestApi regardless of the caller and Method configuration.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
  --disable-execute-api-endpoint: oneof<nothing, bool> # Specifies whether clients can invoke your API by using the default execute-api endpoint. By default, clients can invoke your API with the default https://{api_id}.execute-api.{region}.amazonaws.com endpoint. To require that clients use a custom domain name to invoke your API, disable the default endpoint
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: version, var: version}, {name: cloneFrom, var: clone_from}, {name: binaryMediaTypes, var: binary_media_types}, {name: minimumCompressionSize, var: minimum_compression_size}, {name: apiKeySource, var: api_key_source}, {name: endpointConfiguration, var: endpoint_configuration}, {name: policy, var: policy}, {name: tags, var: tags}, {name: disableExecuteApiEndpoint, var: disable_execute_api_endpoint}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, version: $version, clone_from: $clone_from, binary_media_types: $binary_media_types, minimum_compression_size: $minimum_compression_size, api_key_source: $api_key_source, endpoint_configuration: $endpoint_configuration, policy: $policy, tags: $tags, disable_execute_api_endpoint: $disable_execute_api_endpoint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the RestApis resources for your collection.
#
# GET /restapis
# Returns: record<position: string, items: table<id: string, name: string, description: string, createdDate: string, version: string, warnings: list, binaryMediaTypes: list, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record, policy: string, tags: record, disableExecuteApiEndpoint: bool>>
# operationId: GetRestApis
export def "get-rest-apis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/restapis"
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Stage resource that references a pre-existing Deployment for the API.
#
# POST /restapis/{restapi_id}/stages
# Returns: record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>
# operationId: CreateStage
export def "create-stage" [
  restapi_id: string
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
  stage_name: string # The name for the Stage resource. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  deployment_id: string # The identifier of the Deployment resource for the Stage resource.
  --description: string # The description of the Stage resource.
  --cache-cluster-enabled: oneof<nothing, bool> # Whether cache clustering is enabled for the stage.
  --cache-cluster-size: string@cache-cluster-size-completer # Returns the size of the CacheCluster.
  --variables: record # A map that defines the stage variables for the new Stage resource. Variable names can have alphanumeric and underscore characters, and the values must match [A-Za-z0-9-._~:/?#&=,]+.
  --documentation-version: string # The version of the associated API documentation.
  --canary-settings: record # Configuration settings of a canary deployment. — shape: {percentTraffic?: float, deploymentId?: string, stageVariableOverrides?: record, useStageCache?: bool}
  --tracing-enabled: oneof<nothing, bool> # Specifies whether active tracing with X-ray is enabled for the Stage.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/stages"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: stageName, var: stage_name}, {name: deploymentId, var: deployment_id}, {name: description, var: description}, {name: cacheClusterEnabled, var: cache_cluster_enabled}, {name: cacheClusterSize, var: cache_cluster_size}, {name: variables, var: variables}, {name: documentationVersion, var: documentation_version}, {name: canarySettings, var: canary_settings}, {name: tracingEnabled, var: tracing_enabled}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, stage_name: $stage_name, deployment_id: $deployment_id, description: $description, cache_cluster_enabled: $cache_cluster_enabled, cache_cluster_size: $cache_cluster_size, variables: $variables, documentation_version: $documentation_version, canary_settings: $canary_settings, tracing_enabled: $tracing_enabled, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more Stage resources.
#
# GET /restapis/{restapi_id}/stages
# Returns: record<item: table<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record, canarySettings: record, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>>
# operationId: GetStages
export def "get-stages" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-id: string # The stages' deployment identifiers.
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
    path: "/restapis/{restapi_id}/stages"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: deploymentId, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload.
#
# POST /usageplans
# Returns: record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>
# operationId: CreateUsagePlan
export def "create-usage-plan" [
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
  name: string # The name of the usage plan.
  --description: string # The description of the usage plan.
  --api-stages: list # The associated API stages of the usage plan. — item shape: {apiId?: string, stage?: string, throttle?: record}
  --throttle: record # The API request rate limits. — shape: {burstLimit?: int, rateLimit?: float}
  --quota: record # Quotas configured for a usage plan. — shape: {limit?: int, offset?: int, period?: "DAY"|"WEEK"|"MONTH"}
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usageplans"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: apiStages, var: api_stages}, {name: throttle, var: throttle}, {name: quota, var: quota}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, api_stages: $api_stages, throttle: $throttle, quota: $quota, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the usage plans of the caller's account.
#
# GET /usageplans
# Returns: record<position: string, items: table<id: string, name: string, description: string, apiStages: list, throttle: record, quota: record, productCode: string, tags: record>>
# operationId: GetUsagePlans
export def "get-usage-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --key-id: string # The identifier of the API key associated with the usage plans.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/usageplans"
    query: [{name: position, var: position}, {name: keyId, var: key_id}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    position: $position, key_id: $key_id, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a usage plan key for adding an existing API key to a usage plan.
#
# POST /usageplans/{usageplanId}/keys
# Returns: record<id: string, type: string, value: string, name: string>
# operationId: CreateUsagePlanKey
export def "create-usage-plan-key" [
  usageplan_id: string
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
  key_id: string # The identifier of a UsagePlanKey resource for a plan customer.
  key_type: string # The type of a UsagePlanKey resource for a plan customer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usageplans/{usageplanId}/keys"
    path_params: [{name: usageplanId, var: usageplan_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyId, var: key_id}, {name: keyType, var: key_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, key_id: $key_id, key_type: $key_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the usage plan keys representing the API keys added to a specified usage plan.
#
# GET /usageplans/{usageplanId}/keys
# Returns: record<position: string, items: table<id: string, type: string, value: string, name: string>>
# operationId: GetUsagePlanKeys
export def "get-usage-plan-keys" [
  usageplan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --name: string # A query parameter specifying the name of the to-be-returned usage plan keys.
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
    path: "/usageplans/{usageplanId}/keys"
    path_params: [{name: usageplanId, var: usageplan_id}]
    query: [{name: position, var: position}, {name: limit, var: limit}, {name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, position: $position, limit: $limit, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
#
# POST /vpclinks
# Returns: record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>
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
  name: string # The name used to label and identify the VPC link.
  --description: string # The description of the VPC link.
  target_arns: list<string> # The ARN of the network load balancer of the VPC targeted by the VPC link. The network load balancer must be owned by the same AWS account of the API owner.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/vpclinks"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: targetArns, var: target_arns}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, target_arns: $target_arns, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the VpcLinks collection under the caller's account in a selected region.
#
# GET /vpclinks
# Returns: record<position: string, items: table<id: string, name: string, description: string, targetArns: list, status: string, statusMessage: string, tags: record>>
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
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/vpclinks"
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the ApiKey resource.
#
# DELETE /apikeys/{api_Key}
# operationId: DeleteApiKey
export def "delete-api-key" [
  api_key: string
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
    path: "/apikeys/{api_Key}"
    path_params: [{name: api_Key, var: api_key}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    api_key: $api_key, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the current ApiKey resource.
#
# GET /apikeys/{api_Key}
# Returns: record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>
# operationId: GetApiKey
export def "get-api-key" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-value: oneof<nothing, bool> # A boolean flag to specify whether (true) or not (false) the result contains the key value.
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
    path: "/apikeys/{api_Key}"
    path_params: [{name: api_Key, var: api_key}]
    query: [{name: includeValue, var: include_value}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, include_value: $include_value, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about an ApiKey resource.
#
# PATCH /apikeys/{api_Key}
# Returns: record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>
# operationId: UpdateApiKey
export def "update-api-key" [
  api_key: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apikeys/{api_Key}"
    path_params: [{name: api_Key, var: api_key}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Authorizer resource.
#
# DELETE /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: DeleteAuthorizer
export def "delete-authorizer" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}/authorizers/{authorizer_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: authorizer_id, var: authorizer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, authorizer_id: $authorizer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe an existing Authorizer resource.
#
# GET /restapis/{restapi_id}/authorizers/{authorizer_id}
# Returns: record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>
# operationId: GetAuthorizer
export def "get-authorizer" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}/authorizers/{authorizer_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: authorizer_id, var: authorizer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, authorizer_id: $authorizer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate the execution of an Authorizer in your RestApi with headers, parameters, and an incoming request body.
#
# POST /restapis/{restapi_id}/authorizers/{authorizer_id}
# Returns: record<clientStatus: int, log: string, latency: int, principalId: string, policy: string, authorization: record, claims: record>
# operationId: TestInvokeAuthorizer
export def "test-invoke-authorizer" [
  restapi_id: string
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
  --headers: record # A key-value map of headers to simulate an incoming invocation request. This is where the incoming authorization token, or identity source, should be specified.
  --multi-value-headers: record # The headers as a map from string to list of values to simulate an incoming invocation request. This is where the incoming authorization token, or identity source, may be specified.
  --path-with-query-string: string # The URI path, including query string, of the simulated invocation request. Use this to specify path parameters and query string parameters.
  --body: string # The simulated request body of an incoming invocation request.
  --stage-variables: record # A key-value map of stage variables to simulate an invocation on a deployed Stage.
  --additional-context: record # A key-value map of additional context variables.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/authorizers/{authorizer_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: authorizer_id, var: authorizer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: headers, var: headers}, {name: multiValueHeaders, var: multi_value_headers}, {name: pathWithQueryString, var: path_with_query_string}, {name: body, var: body}, {name: stageVariables, var: stage_variables}, {name: additionalContext, var: additional_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, authorizer_id: $authorizer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, headers: $headers, multi_value_headers: $multi_value_headers, path_with_query_string: $path_with_query_string, body: $body, stage_variables: $stage_variables, additional_context: $additional_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Authorizer resource.
#
# PATCH /restapis/{restapi_id}/authorizers/{authorizer_id}
# Returns: record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>
# operationId: UpdateAuthorizer
export def "update-authorizer" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/authorizers/{authorizer_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: authorizer_id, var: authorizer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, authorizer_id: $authorizer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the BasePathMapping resource.
#
# DELETE /domainnames/{domain_name}/basepathmappings/{base_path}
# operationId: DeleteBasePathMapping
export def "delete-base-path-mapping" [
  domain_name: string
  base_path: string
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
    path: "/domainnames/{domain_name}/basepathmappings/{base_path}"
    path_params: [{name: domain_name, var: domain_name}, {name: base_path, var: base_path}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    domain_name: $domain_name, base_path: $base_path, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe a BasePathMapping resource.
#
# GET /domainnames/{domain_name}/basepathmappings/{base_path}
# Returns: record<basePath: string, restApiId: string, stage: string>
# operationId: GetBasePathMapping
export def "get-base-path-mapping" [
  domain_name: string
  base_path: string
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
    path: "/domainnames/{domain_name}/basepathmappings/{base_path}"
    path_params: [{name: domain_name, var: domain_name}, {name: base_path, var: base_path}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, base_path: $base_path, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about the BasePathMapping resource.
#
# PATCH /domainnames/{domain_name}/basepathmappings/{base_path}
# Returns: record<basePath: string, restApiId: string, stage: string>
# operationId: UpdateBasePathMapping
export def "update-base-path-mapping" [
  domain_name: string
  base_path: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/domainnames/{domain_name}/basepathmappings/{base_path}"
    path_params: [{name: domain_name, var: domain_name}, {name: base_path, var: base_path}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, base_path: $base_path, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the ClientCertificate resource.
#
# DELETE /clientcertificates/{clientcertificate_id}
# operationId: DeleteClientCertificate
export def "delete-client-certificate" [
  clientcertificate_id: string
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
    path: "/clientcertificates/{clientcertificate_id}"
    path_params: [{name: clientcertificate_id, var: clientcertificate_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    clientcertificate_id: $clientcertificate_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the current ClientCertificate resource.
#
# GET /clientcertificates/{clientcertificate_id}
# Returns: record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>
# operationId: GetClientCertificate
export def "get-client-certificate" [
  clientcertificate_id: string
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
    path: "/clientcertificates/{clientcertificate_id}"
    path_params: [{name: clientcertificate_id, var: clientcertificate_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientcertificate_id: $clientcertificate_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about an ClientCertificate resource.
#
# PATCH /clientcertificates/{clientcertificate_id}
# Returns: record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>
# operationId: UpdateClientCertificate
export def "update-client-certificate" [
  clientcertificate_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/clientcertificates/{clientcertificate_id}"
    path_params: [{name: clientcertificate_id, var: clientcertificate_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientcertificate_id: $clientcertificate_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Deployment resource. Deleting a deployment will only succeed if there are no Stage resources associated with it.
#
# DELETE /restapis/{restapi_id}/deployments/{deployment_id}
# operationId: DeleteDeployment
export def "delete-deployment" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}/deployments/{deployment_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: deployment_id, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Deployment resource.
#
# GET /restapis/{restapi_id}/deployments/{deployment_id}
# Returns: record<id: string, description: string, createdDate: string, apiSummary: record>
# operationId: GetDeployment
export def "get-deployment" [
  restapi_id: string
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
  --embed: list<string> # A query parameter to retrieve the specified embedded resources of the returned Deployment resource in the response. In a REST API call, this embed parameter value is a list of comma-separated strings, as in GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the "apisummary" string. For example, GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary.
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
    path: "/restapis/{restapi_id}/deployments/{deployment_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: deployment_id, var: deployment_id}]
    query: [{name: embed, var: embed, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, deployment_id: $deployment_id, embed: $embed, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about a Deployment resource.
#
# PATCH /restapis/{restapi_id}/deployments/{deployment_id}
# Returns: record<id: string, description: string, createdDate: string, apiSummary: record>
# operationId: UpdateDeployment
export def "update-deployment" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/deployments/{deployment_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: deployment_id, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a documentation part
#
# DELETE /restapis/{restapi_id}/documentation/parts/{part_id}
# operationId: DeleteDocumentationPart
export def "delete-documentation-part" [
  restapi_id: string
  part_id: string
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
    path: "/restapis/{restapi_id}/documentation/parts/{part_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: part_id, var: part_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, part_id: $part_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a documentation part.
#
# GET /restapis/{restapi_id}/documentation/parts/{part_id}
# Returns: record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>
# operationId: GetDocumentationPart
export def "get-documentation-part" [
  restapi_id: string
  part_id: string
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
    path: "/restapis/{restapi_id}/documentation/parts/{part_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: part_id, var: part_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, part_id: $part_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a documentation part.
#
# PATCH /restapis/{restapi_id}/documentation/parts/{part_id}
# Returns: record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>
# operationId: UpdateDocumentationPart
export def "update-documentation-part" [
  restapi_id: string
  part_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/documentation/parts/{part_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: part_id, var: part_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, part_id: $part_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a documentation version.
#
# DELETE /restapis/{restapi_id}/documentation/versions/{doc_version}
# operationId: DeleteDocumentationVersion
export def "delete-documentation-version" [
  restapi_id: string
  doc_version: string
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
    path: "/restapis/{restapi_id}/documentation/versions/{doc_version}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: doc_version, var: doc_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, doc_version: $doc_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a documentation version.
#
# GET /restapis/{restapi_id}/documentation/versions/{doc_version}
# Returns: record<version: string, createdDate: string, description: string>
# operationId: GetDocumentationVersion
export def "get-documentation-version" [
  restapi_id: string
  doc_version: string
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
    path: "/restapis/{restapi_id}/documentation/versions/{doc_version}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: doc_version, var: doc_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, doc_version: $doc_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a documentation version.
#
# PATCH /restapis/{restapi_id}/documentation/versions/{doc_version}
# Returns: record<version: string, createdDate: string, description: string>
# operationId: UpdateDocumentationVersion
export def "update-documentation-version" [
  restapi_id: string
  doc_version: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/documentation/versions/{doc_version}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: doc_version, var: doc_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, doc_version: $doc_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the DomainName resource.
#
# DELETE /domainnames/{domain_name}
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
    path: "/domainnames/{domain_name}"
    path_params: [{name: domain_name, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
#
# GET /domainnames/{domain_name}
# Returns: record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>
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
    path: "/domainnames/{domain_name}"
    path_params: [{name: domain_name, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about the DomainName resource.
#
# PATCH /domainnames/{domain_name}
# Returns: record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/domainnames/{domain_name}"
    path_params: [{name: domain_name, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears any customization of a GatewayResponse of a specified response type on the given RestApi and resets it with the default settings.
#
# DELETE /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: DeleteGatewayResponse
export def "delete-gateway-response" [
  restapi_id: string
  response_type: string@response-type-completer
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
    path: "/restapis/{restapi_id}/gatewayresponses/{response_type}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: response_type, var: response_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, response_type: $response_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a GatewayResponse of a specified response type on the given RestApi.
#
# GET /restapis/{restapi_id}/gatewayresponses/{response_type}
# Returns: record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>
# operationId: GetGatewayResponse
export def "get-gateway-response" [
  restapi_id: string
  response_type: string@response-type-completer
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
    path: "/restapis/{restapi_id}/gatewayresponses/{response_type}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: response_type, var: response_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, response_type: $response_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a customization of a GatewayResponse of a specified response type and status code on the given RestApi.
#
# PUT /restapis/{restapi_id}/gatewayresponses/{response_type}
# Returns: record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>
# operationId: PutGatewayResponse
export def "put-gateway-response" [
  restapi_id: string
  response_type: string@response-type-completer
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
  --status-code: string # The status code.
  --response-parameters: record # Response parameters (paths, query strings and headers) of the GatewayResponse as a string-to-string map of key-value pairs.
  --response-templates: record # Response templates of the GatewayResponse as a string-to-string map of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restapis/{restapi_id}/gatewayresponses/{response_type}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: response_type, var: response_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: statusCode, var: status_code}, {name: responseParameters, var: response_parameters}, {name: responseTemplates, var: response_templates}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, response_type: $response_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, status_code: $status_code, response_parameters: $response_parameters, response_templates: $response_templates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a GatewayResponse of a specified response type on the given RestApi.
#
# PATCH /restapis/{restapi_id}/gatewayresponses/{response_type}
# Returns: record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>
# operationId: UpdateGatewayResponse
export def "update-gateway-response" [
  restapi_id: string
  response_type: string@response-type-completer
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/gatewayresponses/{response_type}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: response_type, var: response_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, response_type: $response_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents a delete integration.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: DeleteIntegration
export def "delete-integration" [
  restapi_id: string
  resource_id: string
  http_method: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the integration settings.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# Returns: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>
# operationId: GetIntegration
export def "get-integration" [
  restapi_id: string
  resource_id: string
  http_method: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets up a method's integration.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# Returns: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>
# operationId: PutIntegration
export def "put-integration" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  type: string@type-completer-2 # The integration type. The valid value is HTTP for integrating an API method with an HTTP backend; AWS with any AWS service endpoints; MOCK for testing without actually invoking the backend; HTTP_PROXY for integrating with the HTTP proxy integration; AWS_PROXY for integrating with the Lambda proxy integration.
  --body-http-method: string # The HTTP method for the integration. (spec name: httpMethod)
  --uri: string # Specifies Uniform Resource Identifier (URI) of the integration endpoint. For HTTP or HTTP_PROXY integrations, the URI must be a fully formed, encoded HTTP(S) URL according to the RFC-3986 specification, for either standard integration, where connectionType is not VPC_LINK, or private integration, where connectionType is VPC_LINK. For a private HTTP integration, the URI is not used for routing. For AWS or AWS_PROXY integrations, the URI is of the form arn:aws:apigateway:{region}:{subdomain.service|service}:path|action/{service_api}. Here, {Region} is the API Gateway region (e.g., us-east-1); {service} is the name of the integrated Amazon Web Services service (e.g., s3); and {subdomain} is a designated subdomain supported by certain Amazon Web Services service for fast host-name lookup. action can be used for an Amazon Web Services service action-based API, using an Action={name}&{p1}={v1}&p2={v2}... query string. The ensuing {service_api} refers to a supported action {name} plus any required input parameters. Alternatively, path can be used for an Amazon Web Services service path-based API. The ensuing service_api refers to the path to an Amazon Web Services service resource, including the region of the integrated Amazon Web Services service, if applicable. For example, for integration with the S3 API of GetObject, the uri can be either arn:aws:apigateway:us-west-2:s3:action/GetObject&Bucket={bucket}&Key={key} or arn:aws:apigateway:us-west-2:s3:path/{bucket}/{key}.
  --connection-type: string@connection-type-completer # The type of the network connection to the integration endpoint. The valid value is INTERNET for connections through the public routable internet or VPC_LINK for private connections between API Gateway and a network load balancer in a VPC. The default value is INTERNET.
  --connection-id: string # The ID of the VpcLink used for the integration. Specify this value only if you specify VPC_LINK as the connection type.
  --credentials: string # Specifies whether credentials are required for a put integration.
  --request-parameters: record # A key-value map specifying request parameters that are passed from the method request to the back end. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the back end. The method request parameter value must match the pattern of method.request.{location}.{name}, where location is querystring, path, or header and name must be a valid and unique method request parameter name.
  --request-templates: record # Represents a map of Velocity templates that are applied on the request payload based on the value of the Content-Type header sent by the client. The content type value is the key in this map, and the template (as a String) is the value.
  --passthrough-behavior: string # Specifies the pass-through behavior for incoming requests based on the Content-Type header in the request, and the available mapping templates specified as the requestTemplates property on the Integration resource. There are three valid values: WHEN_NO_MATCH, WHEN_NO_TEMPLATES, and NEVER.
  --cache-namespace: string # Specifies a group of related cached parameters. By default, API Gateway uses the resource ID as the cacheNamespace. You can specify the same cacheNamespace across resources to return the same cached data for requests to different resources.
  --cache-key-parameters: list<string> # A list of request parameters whose values API Gateway caches. To be valid values for cacheKeyParameters, these parameters must also be specified for Method requestParameters.
  --content-handling: string@content-handling-completer # Specifies how to handle request payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT, with the following behaviors: If this property is not defined, the request payload will be passed through from the method request to integration request without modification, provided that the passthroughBehavior is configured to support payload pass-through.
  --timeout-in-millis: int # Custom timeout between 50 and 29,000 milliseconds. The default value is 29,000 milliseconds or 29 seconds.
  --tls-config: record # Specifies the TLS configuration for an integration. — shape: {insecureSkipVerification?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: httpMethod, var: body_http_method}, {name: uri, var: uri}, {name: connectionType, var: connection_type}, {name: connectionId, var: connection_id}, {name: credentials, var: credentials}, {name: requestParameters, var: request_parameters}, {name: requestTemplates, var: request_templates}, {name: passthroughBehavior, var: passthrough_behavior}, {name: cacheNamespace, var: cache_namespace}, {name: cacheKeyParameters, var: cache_key_parameters}, {name: contentHandling, var: content_handling}, {name: timeoutInMillis, var: timeout_in_millis}, {name: tlsConfig, var: tls_config}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, type: $type, body_http_method: $body_http_method, uri: $uri, connection_type: $connection_type, connection_id: $connection_id, credentials: $credentials, request_parameters: $request_parameters, request_templates: $request_templates, passthrough_behavior: $passthrough_behavior, cache_namespace: $cache_namespace, cache_key_parameters: $cache_key_parameters, content_handling: $content_handling, timeout_in_millis: $timeout_in_millis, tls_config: $tls_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents an update integration.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# Returns: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>
# operationId: UpdateIntegration
export def "update-integration" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents a delete integration response.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: DeleteIntegrationResponse
export def "delete-integration-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}, {name: status_code, var: status_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, status_code: $status_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents a get integration response.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# Returns: record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>
# operationId: GetIntegrationResponse
export def "get-integration-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}, {name: status_code, var: status_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, status_code: $status_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents a put integration.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# Returns: record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>
# operationId: PutIntegrationResponse
export def "put-integration-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --selection-pattern: string # Specifies the selection pattern of a put integration response.
  --response-parameters: record # A key-value map specifying response parameters that are passed to the method response from the back end. The key is a method response header parameter name and the mapped value is an integration response header value, a static value enclosed within a pair of single quotes, or a JSON expression from the integration response body. The mapping key must match the pattern of method.response.header.{name}, where name is a valid and unique header name. The mapped non-static value must match the pattern of integration.response.header.{name} or integration.response.body.{JSON-expression}, where name must be a valid and unique response header name and JSON-expression a valid JSON expression without the $ prefix.
  --response-templates: record # Specifies a put integration response's templates.
  --content-handling: string@content-handling-completer # Specifies how to handle response payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT, with the following behaviors: If this property is not defined, the response payload will be passed through from the integration response to the method response without modification.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}, {name: status_code, var: status_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: selectionPattern, var: selection_pattern}, {name: responseParameters, var: response_parameters}, {name: responseTemplates, var: response_templates}, {name: contentHandling, var: content_handling}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, status_code: $status_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, selection_pattern: $selection_pattern, response_parameters: $response_parameters, response_templates: $response_templates, content_handling: $content_handling
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents an update integration response.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# Returns: record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>
# operationId: UpdateIntegrationResponse
export def "update-integration-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}, {name: status_code, var: status_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, status_code: $status_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Method resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: DeleteMethod
export def "delete-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe an existing Method resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# Returns: record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>
# operationId: GetMethod
export def "get-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a method to an existing Resource resource.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# Returns: record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>
# operationId: PutMethod
export def "put-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  authorization_type: string # The method's authorization type. Valid values are NONE for open access, AWS_IAM for using AWS IAM permissions, CUSTOM for using a custom authorizer, or COGNITO_USER_POOLS for using a Cognito user pool.
  --authorizer-id: string # Specifies the identifier of an Authorizer to use on this Method, if the type is CUSTOM or COGNITO_USER_POOLS. The authorizer identifier is generated by API Gateway when you created the authorizer.
  --api-key-required: oneof<nothing, bool> # Specifies whether the method required a valid ApiKey.
  --operation-name: string # A human-friendly operation identifier for the method. For example, you can assign the operationName of ListPets for the GET /pets method in the PetStore example.
  --request-parameters: record # A key-value map defining required or optional method request parameters that can be accepted by API Gateway. A key defines a method request parameter name matching the pattern of method.request.{location}.{name}, where location is querystring, path, or header and name is a valid and unique parameter name. The value associated with the key is a Boolean flag indicating whether the parameter is required (true) or optional (false). The method request parameter names defined here are available in Integration to be mapped to integration request parameters or body-mapping templates.
  --request-models: record # Specifies the Model resources used for the request's content type. Request models are represented as a key/value map, with a content type as the key and a Model name as the value.
  --request-validator-id: string # The identifier of a RequestValidator for validating the method request.
  --authorization-scopes: list<string> # A list of authorization scopes configured on the method. The scopes are used with a COGNITO_USER_POOLS authorizer to authorize the method invocation. The authorization works by matching the method scopes against the scopes parsed from the access token in the incoming request. The method invocation is authorized if any method scopes matches a claimed scope in the access token. Otherwise, the invocation is not authorized. When the method scope is configured, the client must provide an access token instead of an identity token for authorization purposes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizationType, var: authorization_type}, {name: authorizerId, var: authorizer_id}, {name: apiKeyRequired, var: api_key_required}, {name: operationName, var: operation_name}, {name: requestParameters, var: request_parameters}, {name: requestModels, var: request_models}, {name: requestValidatorId, var: request_validator_id}, {name: authorizationScopes, var: authorization_scopes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authorization_type: $authorization_type, authorizer_id: $authorizer_id, api_key_required: $api_key_required, operation_name: $operation_name, request_parameters: $request_parameters, request_models: $request_models, request_validator_id: $request_validator_id, authorization_scopes: $authorization_scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate the invocation of a Method in your RestApi with headers, parameters, and an incoming request body.
#
# POST /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# Returns: record<status: int, body: string, headers: record, multiValueHeaders: record, log: string, latency: int>
# operationId: TestInvokeMethod
export def "test-invoke-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --path-with-query-string: string # The URI path, including query string, of the simulated invocation request. Use this to specify path parameters and query string parameters.
  --body: string # The simulated request body of an incoming invocation request.
  --headers: record # A key-value map of headers to simulate an incoming invocation request.
  --multi-value-headers: record # The headers as a map from string to list of values to simulate an incoming invocation request.
  --client-certificate-id: string # A ClientCertificate identifier to use in the test invocation. API Gateway will use the certificate when making the HTTPS request to the defined back-end endpoint.
  --stage-variables: record # A key-value map of stage variables to simulate an invocation on a deployed Stage.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: pathWithQueryString, var: path_with_query_string}, {name: body, var: body}, {name: headers, var: headers}, {name: multiValueHeaders, var: multi_value_headers}, {name: clientCertificateId, var: client_certificate_id}, {name: stageVariables, var: stage_variables}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, path_with_query_string: $path_with_query_string, body: $body, headers: $headers, multi_value_headers: $multi_value_headers, client_certificate_id: $client_certificate_id, stage_variables: $stage_variables
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Method resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# Returns: record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>
# operationId: UpdateMethod
export def "update-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing MethodResponse resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: DeleteMethodResponse
export def "delete-method-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}, {name: status_code, var: status_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, status_code: $status_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a MethodResponse resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# Returns: record<statusCode: string, responseParameters: record, responseModels: record>
# operationId: GetMethodResponse
export def "get-method-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}, {name: status_code, var: status_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, status_code: $status_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a MethodResponse to an existing Method resource.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# Returns: record<statusCode: string, responseParameters: record, responseModels: record>
# operationId: PutMethodResponse
export def "put-method-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --response-parameters: record # A key-value map specifying required or optional response parameters that API Gateway can send back to the caller. A key defines a method response header name and the associated value is a Boolean flag indicating whether the method response parameter is required or not. The method response header names must match the pattern of method.response.header.{name}, where name is a valid and unique header name. The response parameter names defined here are available in the integration response to be mapped from an integration response header expressed in integration.response.header.{name}, a static value enclosed within a pair of single quotes (e.g., 'application/json'), or a JSON expression from the back-end response payload in the form of integration.response.body.{JSON-expression}, where JSON-expression is a valid JSON expression without the $ prefix.)
  --response-models: record # Specifies the Model resources used for the response's content type. Response models are represented as a key/value map, with a content type as the key and a Model name as the value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}, {name: status_code, var: status_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: responseParameters, var: response_parameters}, {name: responseModels, var: response_models}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, status_code: $status_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, response_parameters: $response_parameters, response_models: $response_models
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing MethodResponse resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# Returns: record<statusCode: string, responseParameters: record, responseModels: record>
# operationId: UpdateMethodResponse
export def "update-method-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}, {name: http_method, var: http_method}, {name: status_code, var: status_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, http_method: $http_method, status_code: $status_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a model.
#
# DELETE /restapis/{restapi_id}/models/{model_name}
# operationId: DeleteModel
export def "delete-model" [
  restapi_id: string
  model_name: string
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
    path: "/restapis/{restapi_id}/models/{model_name}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: model_name, var: model_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, model_name: $model_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing model defined for a RestApi resource.
#
# GET /restapis/{restapi_id}/models/{model_name}
# Returns: record<id: string, name: string, description: string, schema: string, contentType: string>
# operationId: GetModel
export def "get-model" [
  restapi_id: string
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # A query parameter of a Boolean value to resolve (true) all external model references and returns a flattened model schema or not (false) The default is false.
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
    path: "/restapis/{restapi_id}/models/{model_name}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: model_name, var: model_name}]
    query: [{name: flatten, var: flatten}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, model_name: $model_name, flatten: $flatten, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about a model.
#
# PATCH /restapis/{restapi_id}/models/{model_name}
# Returns: record<id: string, name: string, description: string, schema: string, contentType: string>
# operationId: UpdateModel
export def "update-model" [
  restapi_id: string
  model_name: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/models/{model_name}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: model_name, var: model_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, model_name: $model_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a RequestValidator of a given RestApi.
#
# DELETE /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# operationId: DeleteRequestValidator
export def "delete-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
    path: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: requestvalidator_id, var: requestvalidator_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, requestvalidator_id: $requestvalidator_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a RequestValidator of a given RestApi.
#
# GET /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# Returns: record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>
# operationId: GetRequestValidator
export def "get-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
    path: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: requestvalidator_id, var: requestvalidator_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, requestvalidator_id: $requestvalidator_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a RequestValidator of a given RestApi.
#
# PATCH /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# Returns: record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>
# operationId: UpdateRequestValidator
export def "update-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: requestvalidator_id, var: requestvalidator_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, requestvalidator_id: $requestvalidator_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Resource resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}
# operationId: DeleteResource
export def "delete-resource" [
  restapi_id: string
  resource_id: string
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
    path: "/restapis/{restapi_id}/resources/{resource_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about a resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}
# Returns: record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>
# operationId: GetResource
export def "get-resource" [
  restapi_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: list<string> # A query parameter to retrieve the specified resources embedded in the returned Resource representation in the response. This embed parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded Method resources this way. The query parameter value must be a single-valued list and contain the "methods" string. For example, GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods.
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
    path: "/restapis/{restapi_id}/resources/{resource_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}]
    query: [{name: embed, var: embed, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, embed: $embed, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about a Resource resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}
# Returns: record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>
# operationId: UpdateResource
export def "update-resource" [
  restapi_id: string
  resource_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/resources/{resource_id}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: resource_id, var: resource_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, resource_id: $resource_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified API.
#
# DELETE /restapis/{restapi_id}
# operationId: DeleteRestApi
export def "delete-rest-api" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the RestApi resource in the collection.
#
# GET /restapis/{restapi_id}
# Returns: record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>
# operationId: GetRestApi
export def "get-rest-api" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
#
# PUT /restapis/{restapi_id}
# Returns: record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>
# operationId: PutRestApi
export def "put-rest-api" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # The mode query parameter to specify the update mode. Valid values are "merge" and "overwrite". By default, the update mode is "merge".
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback the API update (true) or not (false) when a warning is encountered. The default value is false.
  --parameters: record # Custom header parameters as part of the request. For example, to exclude DocumentationParts from an imported API, set ignore=documentation as a parameters value, as in the AWS CLI command of aws apigateway import-rest-api --parameters ignore=documentation --body 'file:///path/to/imported-api-body.json'.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The PUT request body containing external API definitions. Currently, only OpenAPI definition JSON/YAML files are supported. The maximum size of the API definition file is 6MB.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restapis/{restapi_id}"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: mode, var: mode}, {name: failonwarnings, var: failonwarnings}, {name: parameters, var: parameters, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, mode: $mode, failonwarnings: $failonwarnings, parameters: $parameters, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about the specified API.
#
# PATCH /restapis/{restapi_id}
# Returns: record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>
# operationId: UpdateRestApi
export def "update-rest-api" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}"
    path_params: [{name: restapi_id, var: restapi_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Stage resource.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}
# operationId: DeleteStage
export def "delete-stage" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}/stages/{stage_name}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: stage_name, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Stage resource.
#
# GET /restapis/{restapi_id}/stages/{stage_name}
# Returns: record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>
# operationId: GetStage
export def "get-stage" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}/stages/{stage_name}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: stage_name, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about a Stage resource.
#
# PATCH /restapis/{restapi_id}/stages/{stage_name}
# Returns: record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>
# operationId: UpdateStage
export def "update-stage" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/restapis/{restapi_id}/stages/{stage_name}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: stage_name, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a usage plan of a given plan Id.
#
# DELETE /usageplans/{usageplanId}
# operationId: DeleteUsagePlan
export def "delete-usage-plan" [
  usageplan_id: string
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
    path: "/usageplans/{usageplanId}"
    path_params: [{name: usageplanId, var: usageplan_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a usage plan of a given plan identifier.
#
# GET /usageplans/{usageplanId}
# Returns: record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>
# operationId: GetUsagePlan
export def "get-usage-plan" [
  usageplan_id: string
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
    path: "/usageplans/{usageplanId}"
    path_params: [{name: usageplanId, var: usageplan_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a usage plan of a given plan Id.
#
# PATCH /usageplans/{usageplanId}
# Returns: record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>
# operationId: UpdateUsagePlan
export def "update-usage-plan" [
  usageplan_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/usageplans/{usageplanId}"
    path_params: [{name: usageplanId, var: usageplan_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a usage plan key and remove the underlying API key from the associated usage plan.
#
# DELETE /usageplans/{usageplanId}/keys/{keyId}
# operationId: DeleteUsagePlanKey
export def "delete-usage-plan-key" [
  usageplan_id: string
  key_id: string
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
    path: "/usageplans/{usageplanId}/keys/{keyId}"
    path_params: [{name: usageplanId, var: usageplan_id}, {name: keyId, var: key_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, key_id: $key_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a usage plan key of a given key identifier.
#
# GET /usageplans/{usageplanId}/keys/{keyId}
# Returns: record<id: string, type: string, value: string, name: string>
# operationId: GetUsagePlanKey
export def "get-usage-plan-key" [
  usageplan_id: string
  key_id: string
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
    path: "/usageplans/{usageplanId}/keys/{keyId}"
    path_params: [{name: usageplanId, var: usageplan_id}, {name: keyId, var: key_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, key_id: $key_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing VpcLink of a specified identifier.
#
# DELETE /vpclinks/{vpclink_id}
# operationId: DeleteVpcLink
export def "delete-vpc-link" [
  vpclink_id: string
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
    path: "/vpclinks/{vpclink_id}"
    path_params: [{name: vpclink_id, var: vpclink_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    vpclink_id: $vpclink_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a specified VPC link under the caller's account in a region.
#
# GET /vpclinks/{vpclink_id}
# Returns: record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>
# operationId: GetVpcLink
export def "get-vpc-link" [
  vpclink_id: string
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
    path: "/vpclinks/{vpclink_id}"
    path_params: [{name: vpclink_id, var: vpclink_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vpclink_id: $vpclink_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing VpcLink of a specified identifier.
#
# PATCH /vpclinks/{vpclink_id}
# Returns: record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>
# operationId: UpdateVpcLink
export def "update-vpc-link" [
  vpclink_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/vpclinks/{vpclink_id}"
    path_params: [{name: vpclink_id, var: vpclink_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vpclink_id: $vpclink_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Flushes all authorizer cache entries on a stage.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}/cache/authorizers
# operationId: FlushStageAuthorizersCache
export def "flush-stage-authorizers-cache" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers"
    path_params: [{name: restapi_id, var: restapi_id}, {name: stage_name, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Flushes a stage's cache.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}/cache/data
# operationId: FlushStageCache
export def "flush-stage-cache" [
  restapi_id: string
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
    path: "/restapis/{restapi_id}/stages/{stage_name}/cache/data"
    path_params: [{name: restapi_id, var: restapi_id}, {name: stage_name, var: stage_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    restapi_id: $restapi_id, stage_name: $stage_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a ClientCertificate resource.
#
# POST /clientcertificates
# Returns: record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>
# operationId: GenerateClientCertificate
export def "generate-client-certificate" [
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
  --description: string # The description of the ClientCertificate.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clientcertificates"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a collection of ClientCertificate resources.
#
# GET /clientcertificates
# Returns: record<position: string, items: table<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>>
# operationId: GetClientCertificates
export def "get-client-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/clientcertificates"
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the current Account resource.
#
# GET /account
# Returns: record<cloudwatchRoleArn: string, throttleSettings: record<burstLimit: int, rateLimit: float>, features: list<string>, apiKeyVersion: string>
# operationId: GetAccount
export def "get-account" [
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
    path: "/account"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about the current Account resource.
#
# PATCH /account
# Returns: record<cloudwatchRoleArn: string, throttleSettings: record<burstLimit: int, rateLimit: float>, features: list<string>, apiKeyVersion: string>
# operationId: UpdateAccount
export def "update-account" [
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports a deployed version of a RestApi in a specified format.
#
# GET /restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}
# Returns: record<body: string>
# operationId: GetExport
export def "get-export" [
  restapi_id: string
  stage_name: string
  export_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # A key-value map of query string parameters that specify properties of the export, depending on the requested exportType. For exportType oas30 and swagger, any combination of the following parameters are supported: extensions='integrations' or extensions='apigateway' will export the API with x-amazon-apigateway-integration extensions. extensions='authorizers' will export the API with x-amazon-apigateway-authorizer extensions. postman will export the API with Postman extensions, allowing for import to the Postman tool
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --hdr-accept: string # The content-type of the export, for example application/json. Currently application/json and application/yaml are supported for exportType ofoas30 and swagger. This should be specified in the Accept header for direct API requests. (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: stage_name, var: stage_name}, {name: export_type, var: export_type}]
    query: [{name: parameters, var: parameters, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: Accept, var: hdr_accept}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, stage_name: $stage_name, export_type: $export_type, parameters: $parameters, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the GatewayResponses collection on the given RestApi. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default GatewayResponses collection for the supported response types.
#
# GET /restapis/{restapi_id}/gatewayresponses
# Returns: record<position: string, items: table<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>>
# operationId: GetGatewayResponses
export def "get-gateway-responses" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set. The GatewayResponse collection does not support pagination and the position does not apply here.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The GatewayResponses collection does not support pagination and the limit does not apply here.
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
    path: "/restapis/{restapi_id}/gatewayresponses"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a sample mapping template that can be used to transform a payload into the structure of a model.
#
# GET /restapis/{restapi_id}/models/{model_name}/default_template
# Returns: record<value: string>
# operationId: GetModelTemplate
export def "get-model-template" [
  restapi_id: string
  model_name: string
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
    path: "/restapis/{restapi_id}/models/{model_name}/default_template"
    path_params: [{name: restapi_id, var: restapi_id}, {name: model_name, var: model_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, model_name: $model_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about a collection of Resource resources.
#
# GET /restapis/{restapi_id}/resources
# Returns: record<position: string, items: table<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>>
# operationId: GetResources
export def "get-resources" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --embed: list<string> # A query parameter used to retrieve the specified resources embedded in the returned Resources resource in the response. This embed parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded Method resources this way. The query parameter value must be a single-valued list and contain the "methods" string. For example, GET /restapis/{restapi_id}/resources?embed=methods.
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
    path: "/restapis/{restapi_id}/resources"
    path_params: [{name: restapi_id, var: restapi_id}]
    query: [{name: position, var: position}, {name: limit, var: limit}, {name: embed, var: embed, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, position: $position, limit: $limit, embed: $embed, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a client SDK for a RestApi and Stage.
#
# GET /restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}
# Returns: record<body: string>
# operationId: GetSdk
export def "get-sdk" [
  restapi_id: string
  stage_name: string
  sdk_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # A string-to-string key-value map of query parameters sdkType-dependent properties of the SDK. For sdkType of objectivec or swift, a parameter named classPrefix is required. For sdkType of android, parameters named groupId, artifactId, artifactVersion, and invokerPackage are required. For sdkType of java, parameters named serviceName and javaPackageName are required.
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
    path: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}"
    path_params: [{name: restapi_id, var: restapi_id}, {name: stage_name, var: stage_name}, {name: sdk_type, var: sdk_type}]
    query: [{name: parameters, var: parameters, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restapi_id: $restapi_id, stage_name: $stage_name, sdk_type: $sdk_type, parameters: $parameters, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an SDK type.
#
# GET /sdktypes/{sdktype_id}
# Returns: record<id: string, friendlyName: string, description: string, configurationProperties: table<name: string, friendlyName: string, description: string, required: bool, defaultValue: string>>
# operationId: GetSdkType
export def "get-sdk-type" [
  sdktype_id: string
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
    path: "/sdktypes/{sdktype_id}"
    path_params: [{name: sdktype_id, var: sdktype_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sdktype_id: $sdktype_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets SDK types
#
# GET /sdktypes
# Returns: record<position: string, items: table<id: string, friendlyName: string, description: string, configurationProperties: list>>
# operationId: GetSdkTypes
export def "get-sdk-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/sdktypes"
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Tags collection for a given resource.
#
# GET /tags/{resource_arn}
# Returns: record<tags: record>
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
  --position: string # (Not currently supported) The current pagination position in the paged result set.
  --limit: int # (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/tags/{resource_arn}"
    path_params: [{name: resource_arn, var: resource_arn}]
    query: [{name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or updates a tag on a given resource.
#
# PUT /tags/{resource_arn}
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
  tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> any {
  $in | http-request {
    method: put
    path: "/tags/{resource_arn}"
    path_params: [{name: resource_arn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the usage data of a usage plan in a specified time interval.
#
# GET /usageplans/{usageplanId}/usage
# Returns: record<usagePlanId: string, startDate: string, endDate: string, position: string, items: record>
# operationId: GetUsage
export def "get-usage" [
  usageplan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key-id: string # The Id of the API key associated with the resultant usage data.
  --start-date: string # The starting date (e.g., 2016-01-01) of the usage data. (required)
  --end-date: string # The ending date (e.g., 2016-12-31) of the usage data. (required)
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
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
    path: "/usageplans/{usageplanId}/usage"
    path_params: [{name: usageplanId, var: usageplan_id}]
    query: [{name: keyId, var: key_id}, {name: startDate, var: start_date, required: true}, {name: endDate, var: end_date, required: true}, {name: position, var: position}, {name: limit, var: limit}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, key_id: $key_id, start_date: $start_date, end_date: $end_date, position: $position, limit: $limit, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import API keys from an external source, such as a CSV-formatted file.
#
# POST /apikeys
# Returns: record<ids: list<string>, warnings: list<string>>
# operationId: ImportApiKeys
export def "import-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # A query parameter to specify the input format to imported API keys. Currently, only the csv format is supported. (required)
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback ApiKey importation (true) or not (false) when error is encountered.
  --mode: string@mode-completer-1 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The payload of the POST request to import API keys. For the payload format, see API Key File Format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apikeys"
    query: [{name: format, var: format, required: true, default: csv}, {name: failonwarnings, var: failonwarnings}, {name: mode, var: mode, required: true, default: import}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    format: $format, failonwarnings: $failonwarnings, mode: $mode, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A feature of the API Gateway control service for creating a new API from an external API definition file.
#
# POST /restapis
# Returns: record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>
# operationId: ImportRestApi
export def "import-rest-api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  --parameters: record # A key-value map of context-specific query string parameters specifying the behavior of different API importing operations. The following shows operation-specific parameters and their supported values. To exclude DocumentationParts from the import, set parameters as ignore=documentation. To configure the endpoint type, set parameters as endpointConfigurationTypes=EDGE, endpointConfigurationTypes=REGIONAL, or endpointConfigurationTypes=PRIVATE. The default endpoint type is EDGE. To handle imported basepath, set parameters as basepath=ignore, basepath=prepend or basepath=split. For example, the AWS CLI command to exclude documentation from the imported API is: The AWS CLI command to set the regional endpoint on the imported API is:
  --mode: string@mode-completer-1 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The POST request body containing external API definitions. Currently, only OpenAPI definition JSON/YAML files are supported. The maximum size of the API definition file is 6MB.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restapis"
    query: [{name: failonwarnings, var: failonwarnings}, {name: parameters, var: parameters, style: multi}, {name: mode, var: mode, required: true, default: import}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    failonwarnings: $failonwarnings, parameters: $parameters, mode: $mode, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a tag from a given resource.
#
# DELETE /tags/{resource_arn}
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
  --tag-keys: list<string> # The Tag keys to delete. (required)
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
    path: "/tags/{resource_arn}"
    path_params: [{name: resource_arn, var: resource_arn}]
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

# Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
#
# PATCH /usageplans/{usageplanId}/keys/{keyId}/usage
# Returns: record<usagePlanId: string, startDate: string, endDate: string, position: string, items: record>
# operationId: UpdateUsage
export def "update-usage" [
  usageplan_id: string
  key_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/usageplans/{usageplanId}/keys/{keyId}/usage"
    path_params: [{name: usageplanId, var: usageplan_id}, {name: keyId, var: key_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: patchOperations, var: patch_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    usageplan_id: $usageplan_id, key_id: $key_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, patch_operations: $patch_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
