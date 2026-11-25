# Auto-generated client for Wowza Streaming Cloud REST API Reference Documentation v1
# Source: https://api.apis.guru/v2/specs/wowza.com/1/swagger.json
# Auth: --token flag or $env.WOWZA_STREAMING_CLOUD_REST_API_REFERENCE_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "https://api-sandbox.cloud.wowza.com/api/v1"
  token_env_var: "WOWZA_STREAMING_CLOUD_REST_API_REFERENCE_DOCUMENTATION_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: wsc-access-key, in: header, header_name: wsc-access-key, prefix: ""}
    {name: wsc-api-key, in: header, header_name: wsc-api-key, prefix: ""}
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

def base-url-completer [] { ["https://api-sandbox.cloud.wowza.com/api/v1"] }
def auth-scheme-completer [] { ["wsc-access-key" "wsc-api-key" "none"] }

# Completers for enum parameters
def interval-completer [] { ["#d" "#h" "#m" "#s" "day" "hour" "minute" "month" "second"] }
def transcoder-type-completer [] { ["passthrough" "transcoded"] }
def billing-mode-completer [] { ["pay_as_you_go" "twentyfour_seven"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    specs: "record<basePath: string, consumes: list<string>, definitions: record, externalDocs: record, host: string, info: record, paths: record, produces: list<string>, schemes: list<string>, security: list<record>, securityDefinitions: record, swagger: string, tags: list<record>, x-tagGroups: list<record>>"
    list-live-streams: "record<live_streams: table<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list, delivery_type: string, direct_playback_urls: list, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>>"
    create-live-stream: "record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>>"
    show-live-stream: "record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>>"
    update-live-stream: "record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>>"
    regenerate-connection-code-live-stream: "record<live_stream: record<connection_code: string>>"
    reset-live-stream: "record<live_stream: record<state: string>>"
    start-live-stream: "record<live_stream: record<state: string>>"
    show-live-stream-state: "record<live_stream: record<state: string>>"
    show-live-stream-stats: "record<live_stream: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>>"
    stop-live-stream: "record<live_stream: record<state: string>>"
    show-live-stream-thumbnail-url: "record<live_stream: record<thumbnail_url: string>>"
    list-players: "record<players: table<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>>"
    show-player: "record<player: record<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>>"
    update-player: "record<player: record<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>>"
    request-player-rebuild: "record<player: record<state: string>>"
    show-player-state: "record<player: record<state: string>>"
    list-player-urls: "record<urls: table<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>>"
    create-player-url: "record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>>"
    show-player-url: "record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>>"
    update-player-url: "record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>>"
    list-recordings: "record<recordings: table<created_at: string, download_url: string, duration: int, file_name: string, file_size: int, id: string, reason: string, starts_at: string, state: string, transcoder_id: string, transcoder_name: string, transcoding_uptime_id: string, updated_at: string>>"
    show-recording: "record<recording: record<created_at: string, download_url: string, duration: int, file_name: string, file_size: int, id: string, reason: string, starts_at: string, state: string, transcoder_id: string, transcoder_name: string, transcoding_uptime_id: string, updated_at: string>>"
    show-recording-state: "record<recording: record<state: string>>"
    list-schedules: "record<schedules: table<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>>"
    create-schedule: "record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>>"
    show-schedule: "record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>>"
    update-schedule: "record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>>"
    disable-schedule: "record<schedule: record<state: string>>"
    enable-schedule: "record<schedule: record<state: string>>"
    show-schedule-state: "record<schedule: record<state: string>>"
    list-stream-sources: "record<stream_sources: table<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>"
    create-stream-source: "record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>"
    add-stream-source: "record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>"
    show-stream-source: "record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>"
    update-stream-source: "record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>"
    list-stream-targets: "record<stream_targets: table<chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, hds_playback_url: string, hls_playback_url: string, id: string, location: string, name: string, primary_url: string, provider: string, rtmp_playback_url: string, stream_name: string, type: string, updated_at: string, username: string>>"
    create-stream-target: "record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>>"
    add-stream-target: "record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>>"
    show-stream-target: "record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>>"
    update-stream-target: "record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>>"
    show-stream-target-metrics-current: "record<id: string, metrics: record<average_bytes_in: float, average_total_connections: float, created_at: string, dropped_connections: int, maximum_total_connections: int, minimum_total_connections: int, new_connections: int>>"
    show-stream-target-metrics-historic: "record<id: string, interval: string, metrics: table<average_bytes_in: float, average_total_connections: float, created_at: string, dropped_connections: int, maximum_total_connections: int, minimum_total_connections: int, new_connections: int>>"
    regenerate-connection-code-stream-target: "record<stream_target: record<connection_code: string>>"
    show-stream-target-geoblock: "record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>>"
    update-stream-target-geoblock: "record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>>"
    create-stream-target-geoblock: "record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>>"
    list-stream-target-properties: "record<properties: table<key: string, section: string, stream_target_id: string, value: string>>"
    create-stream-target-property: "record<property: record<key: string, section: string, stream_target_id: string, value: string>>"
    show-stream-target-property: "record<property: record<key: string, section: string, stream_target_id: string, value: string>>"
    show-stream-target-token-auth: "record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>>"
    update-stream-target-token-auth: "record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>>"
    create-stream-target-token-auth: "record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>>"
    list-transcoders: "record<transcoders: table<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list, description: string, direct_playback_urls: list, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>>"
    create-transcoder: "record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>>"
    show-transcoder: "record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>>"
    update-transcoder: "record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>>"
    disable-all-stream-targets-transcoder: "record<transcoder: record<stream_targets: record<state: string>>>"
    enable-all-stream-targets-transcoder: "record<transcoder: record<stream_targets: record<state: string>>>"
    list-transcoder-recordings: "record<transcoder: record<recordings: list<record>>>"
    reset-transcoder: "record<transcoder: record<state: string>>"
    list-transcoder-schedules: "record<transcoder: record<schedules: list<record>>>"
    start-transcoder: "record<transcoder: record<state: string, transcoding_uptime_id: string>>"
    show-transcoder-state: "record<transcoder: record<state: string, transcoding_uptime_id: string, uptime_id: string>>"
    show-transcoder-stats: "record<transcoder: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>>"
    stop-transcoder: "record<transcoder: record<state: string, transcoding_uptime_id: string>>"
    show-transcoder-thumbnail-url: "record<transcoder: record<thumbnail_url: string>>"
    list-transcoder-outputs: "record<outputs: table<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>>"
    create-transcoder-output: "record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>>"
    show-transcoder-output: "record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>>"
    update-transcoder-output: "record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>>"
    add-stream-target-to-transcoder-output: "record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>>"
    list-transcoder-output-output-stream-targets: "record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>"
    create-transcoder-output-output-stream-target: "record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>>"
    show-transcoder-output-output-stream-target: "record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>>"
    update-transcoder-output-output-stream-target: "record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>>"
    disable-transcoder-output-output-stream-target: "record<stream_target: record<state: string>>"
    enable-transcoder-output-output-stream-target: "record<stream_target: record<state: string>>"
    restart-transcoder-output-output-stream-target: "record<stream_target: record<state: string>>"
    list-transcoder-properties: "record<properties: table<key: string, section: string, transcoder_id: string, value: string>>"
    create-transcoder-property: "record<property: record<key: string, section: string, transcoder_id: string, value: string>>"
    show-transcoder-property: "record<property: record<key: string, section: string, transcoder_id: string, value: string>>"
    index-uptimes: "record<uptimes: table<billed: bool, created_at: string, ended_at: string, id: string, running: bool, started_at: string, transcoder_id: string, updated_at: string>>"
    show-uptime: "record<billed: bool, created_at: string, ended_at: string, id: string, running: bool, started_at: string, transcoder_id: string, updated_at: string>"
    show-uptime-metrics-current: "record<current: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>, limits: record<fields: string>>"
    show-uptime-metrics-historic: "record<historic: table<audio_codec: record, bits_in_rate: record, bits_out_rate: record, cpu_idle: record, created_at: string, frame_rate: record, height: record, keyframe_interval: record, video_codec: record, width: record>, limits: record<fields: string, from: string, to: string>>"
    usage-network-stream-sources-index: "record<stream_sources: table<bytes_billed: int, bytes_used: int, deleted: bool, id: string, name: string>>"
    usage-network-stream-targets-index: "record<stream_targets: record<bytes_billed: int, bytes_used: int, deleted: bool, id: string, name: string, protocols: record<zones: record>>, total: record<bytes_billed: int, bytes_used: int, protocols: record<zones: record>>>"
    usage-network-transcoders-index: "record<transcoders: table<bytes_billed: int, bytes_used: int, deleted: bool, id: int, name: string>>"
    usage-storage-peak-recording-index: "record<peak_recording: record<bytes_total: int>>"
    usage-time-transcoders-index: "record<transcoders: table<deleted: bool, id: int, name: string, seconds_billed: int, seconds_used: int>>"
    show-viewer-data-stream-target: "record<stream_target: record<countries: list<record>, country_list: list<string>, percentage_viewers: int, percentage_viewing_time: int, protocols: list<record>, rendition_list: list<string>, renditions: list<record>, seconds_avg_viewing_time: int, seconds_total_viewing_time: int, total_unique_viewers: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["specs" "list-live-streams" "create-live-stream" "delete-live-stream" "show-live-stream" "update-live-stream" "regenerate-connection-code-live-stream" "reset-live-stream" "start-live-stream" "show-live-stream-state" "show-live-stream-stats" "stop-live-stream" "show-live-stream-thumbnail-url" "list-players" "show-player" "update-player" "request-player-rebuild" "show-player-state" "list-player-urls" "create-player-url" "delete-player-url" "show-player-url" "update-player-url" "list-recordings" "delete-recording" "show-recording" "show-recording-state" "list-schedules" "create-schedule" "delete-schedule" "show-schedule" "update-schedule" "disable-schedule" "enable-schedule" "show-schedule-state" "list-stream-sources" "create-stream-source" "add-stream-source" "delete-stream-source" "show-stream-source" "update-stream-source" "list-stream-targets" "create-stream-target" "add-stream-target" "delete-stream-target" "show-stream-target" "update-stream-target" "show-stream-target-metrics-current" "show-stream-target-metrics-historic" "regenerate-connection-code-stream-target" "show-stream-target-geoblock" "update-stream-target-geoblock" "create-stream-target-geoblock" "list-stream-target-properties" "create-stream-target-property" "delete-stream-target-property" "show-stream-target-property" "show-stream-target-token-auth" "update-stream-target-token-auth" "create-stream-target-token-auth" "list-transcoders" "create-transcoder" "delete-transcoder" "show-transcoder" "update-transcoder" "disable-all-stream-targets-transcoder" "enable-all-stream-targets-transcoder" "list-transcoder-recordings" "reset-transcoder" "list-transcoder-schedules" "start-transcoder" "show-transcoder-state" "show-transcoder-stats" "stop-transcoder" "show-transcoder-thumbnail-url" "list-transcoder-outputs" "create-transcoder-output" "delete-transcoder-output" "show-transcoder-output" "update-transcoder-output" "add-stream-target-to-transcoder-output" "remove-stream-target-to-transcoder-output" "list-transcoder-output-output-stream-targets" "create-transcoder-output-output-stream-target" "delete-transcoder-output-output-stream-target" "show-transcoder-output-output-stream-target" "update-transcoder-output-output-stream-target" "disable-transcoder-output-output-stream-target" "enable-transcoder-output-output-stream-target" "restart-transcoder-output-output-stream-target" "list-transcoder-properties" "create-transcoder-property" "delete-transcoder-property" "show-transcoder-property" "index-uptimes" "show-uptime" "show-uptime-metrics-current" "show-uptime-metrics-historic" "usage-network-stream-sources-index" "usage-network-stream-targets-index" "usage-network-transcoders-index" "usage-storage-peak-recording-index" "usage-time-transcoders-index" "show-viewer-data-stream-target" "commands"] | sort) } | get name | first)
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

# Fetch Swagger information
#
# GET /api/v1/specs
# Returns: record<basePath: string, consumes: list<string>, definitions: record, externalDocs: record, host: string, info: record, paths: record, produces: list<string>, schemes: list<string>, security: list<record>, securityDefinitions: record, swagger: string, tags: list<record>, x-tagGroups: list<record>>
# operationId: specs
export def "specs" [
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
    path: "/api/v1/specs"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all live streams
#
# GET /live_streams
# Returns: record<live_streams: table<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list, delivery_type: string, direct_playback_urls: list, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>>
# operationId: listLiveStreams
export def "list-live-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/live_streams"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a live stream
#
# POST /live_streams
# Returns: record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>>
# operationId: createLiveStream
export def "create-live-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  live_stream: record # shape: {aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: "pay_as_you_go"|"twentyfour_seven", broadcast_location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method?: "pull"|"cdn"|"push", delivery_protocols?: list<string>, ... (29 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/live_streams"
    body: {content_type: "application/json", kind: json, fields: [{name: live_stream, var: live_stream}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    live_stream: $live_stream
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a live stream
#
# DELETE /live_streams/{id}
# operationId: deleteLiveStream
export def "delete-live-stream" [
  id: string
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
    path: "/live_streams/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a live stream
#
# GET /live_streams/{id}
# Returns: record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>>
# operationId: showLiveStream
export def "show-live-stream" [
  id: string
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
    path: "/live_streams/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a live stream
#
# PATCH /live_streams/{id}
# Returns: record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>>
# operationId: updateLiveStream
export def "update-live-stream" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  live_stream: record # shape: {aspect_ratio_height: int, aspect_ratio_width: int, closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method?: "pull"|"cdn"|"push", delivery_protocols?: list<string>, disable_authentication?: bool, encoder: "wowza_streaming_engine"|"wowza_gocoder"|"media_ds"|"axis"|"epiphan"|"hauppauge"|"jvc"|"live_u"|"matrox"|"newtek_tricaster"|"osprey"|"sony"|"telestream_wirecast"|"teradek_cube"|"vmix"|"x_split"|"ipcamera"|"other_rtmp"|"other_rtsp", hosted_page_description?: string, ... (22 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/live_streams/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: live_stream, var: live_stream}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id, live_stream: $live_stream
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerate the connection code for a live stream
#
# PUT /live_streams/{id}/regenerate_connection_code
# Returns: record<live_stream: record<connection_code: string>>
# operationId: regenerateConnectionCodeLiveStream
export def "regenerate-connection-code-live-stream" [
  id: string
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
    method: put
    path: "/live_streams/{id}/regenerate_connection_code"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset a live stream
#
# PUT /live_streams/{id}/reset
# Returns: record<live_stream: record<state: string>>
# operationId: resetLiveStream
export def "reset-live-stream" [
  id: string
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
    method: put
    path: "/live_streams/{id}/reset"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a live stream
#
# PUT /live_streams/{id}/start
# Returns: record<live_stream: record<state: string>>
# operationId: startLiveStream
export def "start-live-stream" [
  id: string
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
    method: put
    path: "/live_streams/{id}/start"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the state of a live stream
#
# GET /live_streams/{id}/state
# Returns: record<live_stream: record<state: string>>
# operationId: showLiveStreamState
export def "show-live-stream-state" [
  id: string
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
    path: "/live_streams/{id}/state"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch metrics for an active live stream
#
# GET /live_streams/{id}/stats
# Returns: record<live_stream: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>>
# operationId: showLiveStreamStats
export def "show-live-stream-stats" [
  id: string
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
    path: "/live_streams/{id}/stats"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a live stream
#
# PUT /live_streams/{id}/stop
# Returns: record<live_stream: record<state: string>>
# operationId: stopLiveStream
export def "stop-live-stream" [
  id: string
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
    method: put
    path: "/live_streams/{id}/stop"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the thumbnail URL of a live stream
#
# GET /live_streams/{id}/thumbnail_url
# Returns: record<live_stream: record<thumbnail_url: string>>
# operationId: showLiveStreamThumbnailUrl
export def "show-live-stream-thumbnail-url" [
  id: string
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
    path: "/live_streams/{id}/thumbnail_url"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all players
#
# GET /players
# Returns: record<players: table<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>>
# operationId: listPlayers
export def "list-players" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/players"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a player
#
# GET /players/{id}
# Returns: record<player: record<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>>
# operationId: showPlayer
export def "show-player" [
  id: string
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
    path: "/players/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a player
#
# PATCH /players/{id}
# Returns: record<player: record<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>>
# operationId: updatePlayer
export def "update-player" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  player: record # shape: {countdown?: bool, countdown_at?: string, hosted_page?: bool, hosted_page_description?: string, hosted_page_logo_image?: string, hosted_page_sharing_icons?: bool, hosted_page_title?: string, logo_image?: string, logo_position?: string, remove_hosted_page_logo_image?: bool, remove_logo_image?: bool, remove_video_poster_image?: bool, responsive?: bool, type?: string, video_poster_image?: string, width?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/players/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: player, var: player}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id, player: $player
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rebuild player code
#
# POST /players/{id}/rebuild
# Returns: record<player: record<state: string>>
# operationId: requestPlayerRebuild
export def "request-player-rebuild" [
  id: string
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
    path: "/players/{id}/rebuild"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the state of a player
#
# GET /players/{id}/state
# Returns: record<player: record<state: string>>
# operationId: showPlayerState
export def "show-player-state" [
  id: string
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
    path: "/players/{id}/state"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all player URLs
#
# GET /players/{player_id}/urls
# Returns: record<urls: table<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>>
# operationId: listPlayerUrls
export def "list-player-urls" [
  player_id: string
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
    path: "/players/{player_id}/urls"
    path_params: [{name: player_id, var: player_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    player_id: $player_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a player URL
#
# POST /players/{player_id}/urls
# Returns: record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>>
# operationId: createPlayerUrl
export def "create-player-url" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: record # shape: {bitrate?: int, height?: int, label?: string, url?: string, width?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/players/{player_id}/urls"
    path_params: [{name: player_id, var: player_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    player_id: $player_id, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a player URL
#
# DELETE /players/{player_id}/urls/{id}
# operationId: deletePlayerUrl
export def "delete-player-url" [
  player_id: string
  id: string
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
    path: "/players/{player_id}/urls/{id}"
    path_params: [{name: player_id, var: player_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    player_id: $player_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a player URL
#
# GET /players/{player_id}/urls/{id}
# Returns: record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>>
# operationId: showPlayerUrl
export def "show-player-url" [
  player_id: string
  id: string
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
    path: "/players/{player_id}/urls/{id}"
    path_params: [{name: player_id, var: player_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    player_id: $player_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a player URL
#
# PATCH /players/{player_id}/urls/{id}
# Returns: record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>>
# operationId: updatePlayerUrl
export def "update-player-url" [
  player_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: record # shape: {bitrate?: int, height?: int, label?: string, url?: string, width?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/players/{player_id}/urls/{id}"
    path_params: [{name: player_id, var: player_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    player_id: $player_id, id: $id, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all recordings
#
# GET /recordings
# Returns: record<recordings: table<created_at: string, download_url: string, duration: int, file_name: string, file_size: int, id: string, reason: string, starts_at: string, state: string, transcoder_id: string, transcoder_name: string, transcoding_uptime_id: string, updated_at: string>>
# operationId: listRecordings
export def "list-recordings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recordings"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a recording
#
# DELETE /recordings/{id}
# operationId: deleteRecording
export def "delete-recording" [
  id: string
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
    path: "/recordings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a recording
#
# GET /recordings/{id}
# Returns: record<recording: record<created_at: string, download_url: string, duration: int, file_name: string, file_size: int, id: string, reason: string, starts_at: string, state: string, transcoder_id: string, transcoder_name: string, transcoding_uptime_id: string, updated_at: string>>
# operationId: showRecording
export def "show-recording" [
  id: string
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
    path: "/recordings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the state of a recording
#
# GET /recordings/{id}/state
# Returns: record<recording: record<state: string>>
# operationId: showRecordingState
export def "show-recording-state" [
  id: string
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
    path: "/recordings/{id}/state"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all schedules
#
# GET /schedules
# Returns: record<schedules: table<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>>
# operationId: listSchedules
export def "list-schedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/schedules"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a schedule
#
# POST /schedules
# Returns: record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>>
# operationId: createSchedule
export def "create-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule: record # shape: {action_type: "start"|"stop"|"start_stop", end_repeat?: string, name: string, recurrence_data?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", recurrence_type: "once"|"recur", start_repeat?: string, start_transcoder?: string, stop_transcoder?: string, transcoder_id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/schedules"
    body: {content_type: "application/json", kind: json, fields: [{name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a schedule
#
# DELETE /schedules/{id}
# operationId: deleteSchedule
export def "delete-schedule" [
  id: string
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
    path: "/schedules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a schedule
#
# GET /schedules/{id}
# Returns: record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>>
# operationId: showSchedule
export def "show-schedule" [
  id: string
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
    path: "/schedules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a schedule
#
# PATCH /schedules/{id}
# Returns: record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>>
# operationId: updateSchedule
export def "update-schedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule: record # shape: {action_type: "start"|"stop"|"start_stop", end_repeat?: string, name: string, recurrence_data?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", start_repeat?: string, start_transcoder?: string, stop_transcoder?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/schedules/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a schedule
#
# PUT /schedules/{id}/disable
# Returns: record<schedule: record<state: string>>
# operationId: disableSchedule
export def "disable-schedule" [
  id: string
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
    method: put
    path: "/schedules/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a schedule
#
# PUT /schedules/{id}/enable
# Returns: record<schedule: record<state: string>>
# operationId: enableSchedule
export def "enable-schedule" [
  id: string
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
    method: put
    path: "/schedules/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the state of a schedule
#
# GET /schedules/{id}/state
# Returns: record<schedule: record<state: string>>
# operationId: showScheduleState
export def "show-schedule-state" [
  id: string
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
    path: "/schedules/{id}/state"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all stream sources
#
# GET /stream_sources
# Returns: record<stream_sources: table<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>
# operationId: listStreamSources
export def "list-stream-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stream_sources"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a stream source
#
# POST /stream_sources
# Returns: record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>
# operationId: createStreamSource
export def "create-stream-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_source: record # shape: {backup_ip_address?: string, ip_address?: string, location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", location_method: "region"|"ip_address", name: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stream_sources"
    body: {content_type: "application/json", kind: json, fields: [{name: stream_source, var: stream_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_source: $stream_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated operation
#
# POST /stream_sources/add
# DEPRECATED
# Returns: record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>
# operationId: addStreamSource
@deprecated
export def "add-stream-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_source: record # shape: {backup_ip_address?: string, ip_address?: string, location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", location_method: "region"|"ip_address", name: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stream_sources/add"
    body: {content_type: "application/json", kind: json, fields: [{name: stream_source, var: stream_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_source: $stream_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a stream source
#
# DELETE /stream_sources/{id}
# operationId: deleteStreamSource
export def "delete-stream-source" [
  id: string
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
    path: "/stream_sources/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a stream source
#
# GET /stream_sources/{id}
# Returns: record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>
# operationId: showStreamSource
export def "show-stream-source" [
  id: string
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
    path: "/stream_sources/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a stream source
#
# PATCH /stream_sources/{id}
# Returns: record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>>
# operationId: updateStreamSource
export def "update-stream-source" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_source: record # shape: {name: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/stream_sources/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: stream_source, var: stream_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id, stream_source: $stream_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all stream targets
#
# GET /stream_targets
# Returns: record<stream_targets: table<chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, hds_playback_url: string, hls_playback_url: string, id: string, location: string, name: string, primary_url: string, provider: string, rtmp_playback_url: string, stream_name: string, type: string, updated_at: string, username: string>>
# operationId: listStreamTargets
export def "list-stream-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stream_targets"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a stream target
#
# POST /stream_targets
# Returns: record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>>
# operationId: createStreamTarget
export def "create-stream-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_target: record # shape: {backup_url?: string, chunk_size?: "2"|"4"|"6"|"8"|"10", enable_hls?: bool, enabled?: bool, hds_playback_url?: string, hls_playback_url?: string, ingest_ip_whitelist?: list<string>, location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", name: string, password?: string, primary_url: string, ... (11 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stream_targets"
    body: {content_type: "application/json", kind: json, fields: [{name: stream_target, var: stream_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target: $stream_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated operation
#
# POST /stream_targets/add
# DEPRECATED
# Returns: record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>>
# operationId: addStreamTarget
@deprecated
export def "add-stream-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_target: record # shape: {chunk_size?: "2"|"4"|"6"|"8"|"10", location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", name: string, provider?: string, type?: string, use_cors?: bool, use_https?: bool, use_secure_ingest?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stream_targets/add"
    body: {content_type: "application/json", kind: json, fields: [{name: stream_target, var: stream_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target: $stream_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a stream target
#
# DELETE /stream_targets/{id}
# operationId: deleteStreamTarget
export def "delete-stream-target" [
  id: string
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
    path: "/stream_targets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a stream target
#
# GET /stream_targets/{id}
# Returns: record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>>
# operationId: showStreamTarget
export def "show-stream-target" [
  id: string
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
    path: "/stream_targets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a stream target
#
# PATCH /stream_targets/{id}
# Returns: record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>>
# operationId: updateStreamTarget
export def "update-stream-target" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_target: record # shape: {backup_url?: string, chunk_size?: "2"|"4"|"6"|"8"|"10", enabled?: bool, hds_playback_url?: string, hls_playback_url?: string, ingest_ip_whitelist?: list<string>, name?: string, password?: string, primary_url?: string, provider?: string, rtmp_playback_url?: string, source_url?: string, stream_name?: string, username?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/stream_targets/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: stream_target, var: stream_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id, stream_target: $stream_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch current health metrics for an active Wowza ultra low latency stream target
#
# GET /stream_targets/{id}/metrics/current
# Returns: record<id: string, metrics: record<average_bytes_in: float, average_total_connections: float, created_at: string, dropped_connections: int, maximum_total_connections: int, minimum_total_connections: int, new_connections: int>>
# operationId: showStreamTargetMetricsCurrent
export def "show-stream-target-metrics-current" [
  id: string
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
    path: "/stream_targets/{id}/metrics/current"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch historic health metrics for a Wowza ultra low latency stream target
#
# GET /stream_targets/{id}/metrics/historic
# Returns: record<id: string, interval: string, metrics: table<average_bytes_in: float, average_total_connections: float, created_at: string, dropped_connections: int, maximum_total_connections: int, minimum_total_connections: int, new_connections: int>>
# operationId: showStreamTargetMetricsHistoric
export def "show-stream-target-metrics-historic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The start of the range of time used to aggregate the metrics. Express the value by using the ISO 8601 standard of YYYY-MM-DDTHH:MM:SSZ where HH is a 24-hour clock in UTC.
  --to: string # The end of the range of time used to aggregate the metrics. Express the value by using the ISO 8601 standard of YYYY-MM-DDTHH:MM:SSZ where HH is a 24-hour clock in UTC.
  --interval: string@interval-completer # The length of time for a block of metrics. The default is **10m** (10 minutes).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stream_targets/{id}/metrics/historic"
    path_params: [{name: id, var: id}]
    query: [{name: from, var: from}, {name: to, var: to}, {name: interval, var: interval}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id, from: $from, to: $to, interval: $interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerate the connection code for a stream target
#
# PUT /stream_targets/{id}/regenerate_connection_code
# Returns: record<stream_target: record<connection_code: string>>
# operationId: regenerateConnectionCodeStreamTarget
export def "regenerate-connection-code-stream-target" [
  id: string
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
    method: put
    path: "/stream_targets/{id}/regenerate_connection_code"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch geo-blocking for a stream target
#
# GET /stream_targets/{stream_target_id}/geoblock
# Returns: record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>>
# operationId: showStreamTargetGeoblock
export def "show-stream-target-geoblock" [
  stream_target_id: string
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
    path: "/stream_targets/{stream_target_id}/geoblock"
    path_params: [{name: stream_target_id, var: stream_target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update geo-blocking for a stream target
#
# PATCH /stream_targets/{stream_target_id}/geoblock
# Returns: record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>>
# operationId: updateStreamTargetGeoblock
export def "update-stream-target-geoblock" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  geoblock: record # shape: {countries?: list<string>, type: "disabled"|"allow"|"deny", whitelist?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/stream_targets/{stream_target_id}/geoblock"
    path_params: [{name: stream_target_id, var: stream_target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: geoblock, var: geoblock}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id, geoblock: $geoblock
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create geo-blocking for a stream target
#
# POST /stream_targets/{stream_target_id}/geoblock
# Returns: record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>>
# operationId: createStreamTargetGeoblock
export def "create-stream-target-geoblock" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  geoblock: record # shape: {countries?: list<string>, type: "disabled"|"allow"|"deny", whitelist?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stream_targets/{stream_target_id}/geoblock"
    path_params: [{name: stream_target_id, var: stream_target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: geoblock, var: geoblock}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id, geoblock: $geoblock
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all properties of a stream target
#
# GET /stream_targets/{stream_target_id}/properties
# Returns: record<properties: table<key: string, section: string, stream_target_id: string, value: string>>
# operationId: listStreamTargetProperties
export def "list-stream-target-properties" [
  stream_target_id: string
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
    path: "/stream_targets/{stream_target_id}/properties"
    path_params: [{name: stream_target_id, var: stream_target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a property for a stream target
#
# POST /stream_targets/{stream_target_id}/properties
# Returns: record<property: record<key: string, section: string, stream_target_id: string, value: string>>
# operationId: createStreamTargetProperty
export def "create-stream-target-property" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  property: record # shape: {key: "chunkSize"|"playSSL"|"relativePlaylists"|"sendSSL", section: "hls"|"playlist", value: "2"|"4"|"6"|"8"|"10"|"true"|"false"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stream_targets/{stream_target_id}/properties"
    path_params: [{name: stream_target_id, var: stream_target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: property, var: property}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id, property: $property
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a stream target property
#
# DELETE /stream_targets/{stream_target_id}/properties/{id}
# operationId: deleteStreamTargetProperty
export def "delete-stream-target-property" [
  stream_target_id: string
  id: string
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
    path: "/stream_targets/{stream_target_id}/properties/{id}"
    path_params: [{name: stream_target_id, var: stream_target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a property of a stream target
#
# GET /stream_targets/{stream_target_id}/properties/{id}
# Returns: record<property: record<key: string, section: string, stream_target_id: string, value: string>>
# operationId: showStreamTargetProperty
export def "show-stream-target-property" [
  stream_target_id: string
  id: string
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
    path: "/stream_targets/{stream_target_id}/properties/{id}"
    path_params: [{name: stream_target_id, var: stream_target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch token authorization for a stream target
#
# GET /stream_targets/{stream_target_id}/token_auth
# Returns: record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>>
# operationId: showStreamTargetTokenAuth
export def "show-stream-target-token-auth" [
  stream_target_id: string
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
    path: "/stream_targets/{stream_target_id}/token_auth"
    path_params: [{name: stream_target_id, var: stream_target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update token authorization for a stream target
#
# PATCH /stream_targets/{stream_target_id}/token_auth
# Returns: record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>>
# operationId: updateStreamTargetTokenAuth
export def "update-stream-target-token-auth" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  token_auth: record # shape: {enabled?: bool, trusted_shared_secret?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/stream_targets/{stream_target_id}/token_auth"
    path_params: [{name: stream_target_id, var: stream_target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: token_auth, var: token_auth}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id, token_auth: $token_auth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create token authorization for a stream target
#
# POST /stream_targets/{stream_target_id}/token_auth
# Returns: record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>>
# operationId: createStreamTargetTokenAuth
export def "create-stream-target-token-auth" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  token_auth: record # shape: {enabled: bool, trusted_shared_secret: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stream_targets/{stream_target_id}/token_auth"
    path_params: [{name: stream_target_id, var: stream_target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: token_auth, var: token_auth}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    stream_target_id: $stream_target_id, token_auth: $token_auth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all transcoders
#
# GET /transcoders
# Returns: record<transcoders: table<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list, description: string, direct_playback_urls: list, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>>
# operationId: listTranscoders
export def "list-transcoders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transcoders"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transcoder
#
# POST /transcoders
# Returns: record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>>
# operationId: createTranscoder
export def "create-transcoder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  transcoder: record # shape: {billing_mode: "pay_as_you_go"|"twentyfour_seven", broadcast_location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", buffer_size?: "0"|"1000"|"2000"|"3000"|"4000"|"5000"|"6000"|"7000"|"8000", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method: "pull"|"cdn"|"push", ... (24 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transcoders"
    body: {content_type: "application/json", kind: json, fields: [{name: transcoder, var: transcoder}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder: $transcoder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a transcoder
#
# DELETE /transcoders/{id}
# operationId: deleteTranscoder
export def "delete-transcoder" [
  id: string
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
    path: "/transcoders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a transcoder
#
# GET /transcoders/{id}
# Returns: record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>>
# operationId: showTranscoder
export def "show-transcoder" [
  id: string
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
    path: "/transcoders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a transcoder
#
# PATCH /transcoders/{id}
# Returns: record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>>
# operationId: updateTranscoder
export def "update-transcoder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  transcoder: record # shape: {broadcast_location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", buffer_size?: "0"|"1000"|"2000"|"3000"|"4000"|"5000"|"6000"|"7000"|"8000", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method: "pull"|"cdn"|"push", delivery_protocols?: list<string>, description?: string, ... (22 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transcoders/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: transcoder, var: transcoder}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id, transcoder: $transcoder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a transcoder's stream targets
#
# PUT /transcoders/{id}/disable_all_stream_targets
# Returns: record<transcoder: record<stream_targets: record<state: string>>>
# operationId: disableAllStreamTargetsTranscoder
export def "disable-all-stream-targets-transcoder" [
  id: string
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
    method: put
    path: "/transcoders/{id}/disable_all_stream_targets"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a transcoder's stream targets
#
# PUT /transcoders/{id}/enable_all_stream_targets
# Returns: record<transcoder: record<stream_targets: record<state: string>>>
# operationId: enableAllStreamTargetsTranscoder
export def "enable-all-stream-targets-transcoder" [
  id: string
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
    method: put
    path: "/transcoders/{id}/enable_all_stream_targets"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a transcoder's recordings
#
# GET /transcoders/{id}/recordings
# Returns: record<transcoder: record<recordings: list<record>>>
# operationId: listTranscoderRecordings
export def "list-transcoder-recordings" [
  id: string
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
    path: "/transcoders/{id}/recordings"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset a transcoder
#
# PUT /transcoders/{id}/reset
# Returns: record<transcoder: record<state: string>>
# operationId: resetTranscoder
export def "reset-transcoder" [
  id: string
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
    method: put
    path: "/transcoders/{id}/reset"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch transcoder's schedules
#
# GET /transcoders/{id}/schedules
# Returns: record<transcoder: record<schedules: list<record>>>
# operationId: listTranscoderSchedules
export def "list-transcoder-schedules" [
  id: string
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
    path: "/transcoders/{id}/schedules"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a transcoder
#
# PUT /transcoders/{id}/start
# Returns: record<transcoder: record<state: string, transcoding_uptime_id: string>>
# operationId: startTranscoder
export def "start-transcoder" [
  id: string
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
    method: put
    path: "/transcoders/{id}/start"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the state and uptime ID of a transcoder
#
# GET /transcoders/{id}/state
# Returns: record<transcoder: record<state: string, transcoding_uptime_id: string, uptime_id: string>>
# operationId: showTranscoderState
export def "show-transcoder-state" [
  id: string
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
    path: "/transcoders/{id}/state"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch statistics for a current transcoder
#
# GET /transcoders/{id}/stats
# Returns: record<transcoder: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>>
# operationId: showTranscoderStats
export def "show-transcoder-stats" [
  id: string
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
    path: "/transcoders/{id}/stats"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a transcoder
#
# PUT /transcoders/{id}/stop
# Returns: record<transcoder: record<state: string, transcoding_uptime_id: string>>
# operationId: stopTranscoder
export def "stop-transcoder" [
  id: string
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
    method: put
    path: "/transcoders/{id}/stop"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the thumbnail URL of a transcoder
#
# GET /transcoders/{id}/thumbnail_url
# Returns: record<transcoder: record<thumbnail_url: string>>
# operationId: showTranscoderThumbnailUrl
export def "show-transcoder-thumbnail-url" [
  id: string
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
    path: "/transcoders/{id}/thumbnail_url"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all outputs of a transcoder
#
# GET /transcoders/{transcoder_id}/outputs
# Returns: record<outputs: table<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>>
# operationId: listTranscoderOutputs
export def "list-transcoder-outputs" [
  transcoder_id: string
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
    path: "/transcoders/{transcoder_id}/outputs"
    path_params: [{name: transcoder_id, var: transcoder_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an output
#
# POST /transcoders/{transcoder_id}/outputs
# Returns: record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>>
# operationId: createTranscoderOutput
export def "create-transcoder-output" [
  transcoder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  output: record # shape: {aspect_ratio_height?: int, aspect_ratio_width?: int, bitrate_audio?: int, bitrate_video?: int, framerate_reduction?: "0"|"1/2"|"1/4"|"1/25"|"1/30"|"1/50"|"1/60", h264_profile?: "main"|"baseline"|"high", keyframes?: "follow_source"|"25"|"30"|"50"|"60"|"100"|"120", passthrough_audio?: bool, passthrough_video?: bool, stream_format: "audiovideo"|"videoonly"|"audioonly"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transcoders/{transcoder_id}/outputs"
    path_params: [{name: transcoder_id, var: transcoder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: output, var: output}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output: $output
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an output
#
# DELETE /transcoders/{transcoder_id}/outputs/{id}
# operationId: deleteTranscoderOutput
export def "delete-transcoder-output" [
  transcoder_id: string
  id: string
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
    path: "/transcoders/{transcoder_id}/outputs/{id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an output
#
# GET /transcoders/{transcoder_id}/outputs/{id}
# Returns: record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>>
# operationId: showTranscoderOutput
export def "show-transcoder-output" [
  transcoder_id: string
  id: string
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
    path: "/transcoders/{transcoder_id}/outputs/{id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an output
#
# PATCH /transcoders/{transcoder_id}/outputs/{id}
# Returns: record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>>
# operationId: updateTranscoderOutput
export def "update-transcoder-output" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  output: record # shape: {aspect_ratio_height?: int, aspect_ratio_width?: int, bitrate_audio?: int, bitrate_video?: int, framerate_reduction?: "0"|"1/2"|"1/4"|"1/25"|"1/30"|"1/50"|"1/60", h264_profile?: "main"|"baseline"|"high", keyframes?: "follow_source"|"25"|"30"|"50"|"60"|"100"|"120", passthrough_audio?: bool, passthrough_video?: bool, stream_format: "audiovideo"|"videoonly"|"audioonly"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transcoders/{transcoder_id}/outputs/{id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: output, var: output}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id, output: $output
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated operation
#
# POST /transcoders/{transcoder_id}/outputs/{id}/add_stream_target
# DEPRECATED
# Returns: record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>>
# operationId: addStreamTargetToTranscoderOutput
@deprecated
export def "add-stream-target-to-transcoder-output" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  output_stream_target: record # shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transcoders/{transcoder_id}/outputs/{id}/add_stream_target"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: output_stream_target, var: output_stream_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id, output_stream_target: $output_stream_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated operation
#
# DELETE /transcoders/{transcoder_id}/outputs/{id}/remove_stream_target
# DEPRECATED
# operationId: removeStreamTargetToTranscoderOutput
@deprecated
export def "remove-stream-target-to-transcoder-output" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  output_stream_target: record # shape: {stream_target_id: string}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/transcoders/{transcoder_id}/outputs/{id}/remove_stream_target"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: output_stream_target, var: output_stream_target}]}
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id, output_stream_target: $output_stream_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all output stream targets of an output of a transcoder
#
# GET /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets
# Returns: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>
# operationId: listTranscoderOutputOutputStreamTargets
export def "list-transcoder-output-output-stream-targets" [
  transcoder_id: string
  output_id: string
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
    path: "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: output_id, var: output_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output_id: $output_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an output stream target
#
# POST /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets
# Returns: record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>>
# operationId: createTranscoderOutputOutputStreamTarget
export def "create-transcoder-output-output-stream-target" [
  transcoder_id: string
  output_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  output_stream_target: record # shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: output_id, var: output_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: output_stream_target, var: output_stream_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output_id: $output_id, output_stream_target: $output_stream_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an output stream target
#
# DELETE /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}
# operationId: deleteTranscoderOutputOutputStreamTarget
export def "delete-transcoder-output-output-stream-target" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
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
    path: "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: output_id, var: output_id}, {name: stream_target_id, var: stream_target_id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output_id: $output_id, stream_target_id: $stream_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an output stream target
#
# GET /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}
# Returns: record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>>
# operationId: showTranscoderOutputOutputStreamTarget
export def "show-transcoder-output-output-stream-target" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
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
    path: "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: output_id, var: output_id}, {name: stream_target_id, var: stream_target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output_id: $output_id, stream_target_id: $stream_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an output stream target
#
# PATCH /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}
# Returns: record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>>
# operationId: updateTranscoderOutputOutputStreamTarget
export def "update-transcoder-output-output-stream-target" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  output_stream_target: record # shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: output_id, var: output_id}, {name: stream_target_id, var: stream_target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: output_stream_target, var: output_stream_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output_id: $output_id, stream_target_id: $stream_target_id, output_stream_target: $output_stream_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable an output stream target
#
# PUT /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/disable
# Returns: record<stream_target: record<state: string>>
# operationId: disableTranscoderOutputOutputStreamTarget
export def "disable-transcoder-output-output-stream-target" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
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
    method: put
    path: "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/disable"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: output_id, var: output_id}, {name: stream_target_id, var: stream_target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output_id: $output_id, stream_target_id: $stream_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable an output stream target
#
# PUT /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/enable
# Returns: record<stream_target: record<state: string>>
# operationId: enableTranscoderOutputOutputStreamTarget
export def "enable-transcoder-output-output-stream-target" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
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
    method: put
    path: "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/enable"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: output_id, var: output_id}, {name: stream_target_id, var: stream_target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output_id: $output_id, stream_target_id: $stream_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restart an output stream target
#
# PUT /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/restart
# Returns: record<stream_target: record<state: string>>
# operationId: restartTranscoderOutputOutputStreamTarget
export def "restart-transcoder-output-output-stream-target" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
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
    method: put
    path: "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/restart"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: output_id, var: output_id}, {name: stream_target_id, var: stream_target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, output_id: $output_id, stream_target_id: $stream_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a transcoder's properties
#
# GET /transcoders/{transcoder_id}/properties
# Returns: record<properties: table<key: string, section: string, transcoder_id: string, value: string>>
# operationId: listTranscoderProperties
export def "list-transcoder-properties" [
  transcoder_id: string
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
    path: "/transcoders/{transcoder_id}/properties"
    path_params: [{name: transcoder_id, var: transcoder_id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a property for a transcoder
#
# POST /transcoders/{transcoder_id}/properties
# Returns: record<property: record<key: string, section: string, transcoder_id: string, value: string>>
# operationId: createTranscoderProperty
export def "create-transcoder-property" [
  transcoder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  property: record # shape: {key: string, section: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transcoders/{transcoder_id}/properties"
    path_params: [{name: transcoder_id, var: transcoder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: property, var: property}]}
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, property: $property
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a transcoder's property
#
# DELETE /transcoders/{transcoder_id}/properties/{id}
# operationId: deleteTranscoderProperty
export def "delete-transcoder-property" [
  transcoder_id: string
  id: string
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
    path: "/transcoders/{transcoder_id}/properties/{id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a property for a transcoder
#
# GET /transcoders/{transcoder_id}/properties/{id}
# Returns: record<property: record<key: string, section: string, transcoder_id: string, value: string>>
# operationId: showTranscoderProperty
export def "show-transcoder-property" [
  transcoder_id: string
  id: string
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
    path: "/transcoders/{transcoder_id}/properties/{id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all uptime records for a transcoder
#
# GET /transcoders/{transcoder_id}/uptimes
# Returns: record<uptimes: table<billed: bool, created_at: string, ended_at: string, id: string, running: bool, started_at: string, transcoder_id: string, updated_at: string>>
# operationId: indexUptimes
export def "index-uptimes" [
  transcoder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transcoders/{transcoder_id}/uptimes"
    path_params: [{name: transcoder_id, var: transcoder_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an uptime record
#
# GET /transcoders/{transcoder_id}/uptimes/{id}
# Returns: record<billed: bool, created_at: string, ended_at: string, id: string, running: bool, started_at: string, transcoder_id: string, updated_at: string>
# operationId: showUptime
export def "show-uptime" [
  transcoder_id: string
  id: string
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
    path: "/transcoders/{transcoder_id}/uptimes/{id}"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch current stream health metrics for an active transcoder
#
# GET /transcoders/{transcoder_id}/uptimes/{id}/metrics/current
# Returns: record<current: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>, limits: record<fields: string>>
# operationId: showUptimeMetricsCurrent
export def "show-uptime-metrics-current" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # A comma-separated list of fields to return.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transcoders/{transcoder_id}/uptimes/{id}/metrics/current"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch historic stream health metrics for a transcoder
#
# GET /transcoders/{transcoder_id}/uptimes/{id}/metrics/historic
# Returns: record<historic: table<audio_codec: record, bits_in_rate: record, bits_out_rate: record, cpu_idle: record, created_at: string, frame_rate: record, height: record, keyframe_interval: record, video_codec: record, width: record>, limits: record<fields: string, from: string, to: string>>
# operationId: showUptimeMetricsHistoric
export def "show-uptime-metrics-historic" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # A comma-separated list of fields to return.
  --from: string # The start of the range of time used to aggregate the metrics. Express the value by using the ISO 8601 standard of YYYY-MM-DDTHH:MM:SSZ where HH is a 24-hour clock in UTC.
  --to: string # The end of the range of time used to aggregate the metrics. Express the value by using the ISO 8601 standard of YYYY-MM-DDTHH:MM:SSZ where HH is a 24-hour clock in UTC.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transcoders/{transcoder_id}/uptimes/{id}/metrics/historic"
    path_params: [{name: transcoder_id, var: transcoder_id}, {name: id, var: id}]
    query: [{name: fields, var: fields}, {name: from, var: from}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    transcoder_id: $transcoder_id, id: $id, fields: $fields, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch network usage for all stream sources
#
# GET /usage/network/stream_sources
# Returns: record<stream_sources: table<bytes_billed: int, bytes_used: int, deleted: bool, id: string, name: string>>
# operationId: usageNetworkStreamSourcesIndex
export def "usage-network-stream-sources-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/usage/network/stream_sources"
    query: [{name: from, var: from}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch network usage for all stream targets
#
# GET /usage/network/stream_targets
# Returns: record<stream_targets: record<bytes_billed: int, bytes_used: int, deleted: bool, id: string, name: string, protocols: record<zones: record>>, total: record<bytes_billed: int, bytes_used: int, protocols: record<zones: record>>>
# operationId: usageNetworkStreamTargetsIndex
export def "usage-network-stream-targets-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/usage/network/stream_targets"
    query: [{name: from, var: from}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch network usage for all transcoders
#
# GET /usage/network/transcoders
# Returns: record<transcoders: table<bytes_billed: int, bytes_used: int, deleted: bool, id: int, name: string>>
# operationId: usageNetworkTranscodersIndex
export def "usage-network-transcoders-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
  --transcoder-type: string@transcoder-type-completer # The type of transcoder. The default is transcoded.
  --billing-mode: string@billing-mode-completer # The billing mode for the transcoder. The default is pay_as_you_go.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/usage/network/transcoders"
    query: [{name: from, var: from}, {name: to, var: to}, {name: transcoder_type, var: transcoder_type}, {name: billing_mode, var: billing_mode}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    from: $from, to: $to, transcoder_type: $transcoder_type, billing_mode: $billing_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch peak recording storage
#
# GET /usage/storage/peak_recording
# Returns: record<peak_recording: record<bytes_total: int>>
# operationId: usageStoragePeakRecordingIndex
export def "usage-storage-peak-recording-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/usage/storage/peak_recording"
    query: [{name: from, var: from}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch stream processing time
#
# GET /usage/time/transcoders
# Returns: record<transcoders: table<deleted: bool, id: int, name: string, seconds_billed: int, seconds_used: int>>
# operationId: usageTimeTranscodersIndex
export def "usage-time-transcoders-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
  --transcoder-type: string@transcoder-type-completer # The type of transcoder. The default is transcoded.
  --billing-mode: string@billing-mode-completer # The billing mode for the transcoder. The default is pay_as_you_go.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/usage/time/transcoders"
    query: [{name: from, var: from}, {name: to, var: to}, {name: transcoder_type, var: transcoder_type}, {name: billing_mode, var: billing_mode}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    from: $from, to: $to, transcoder_type: $transcoder_type, billing_mode: $billing_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch viewer data for a stream target
#
# GET /usage/viewer_data/stream_targets/{id}
# Returns: record<stream_target: record<countries: list<record>, country_list: list<string>, percentage_viewers: int, percentage_viewing_time: int, protocols: list<record>, rendition_list: list<string>, renditions: list<record>, seconds_avg_viewing_time: int, seconds_total_viewing_time: int, total_unique_viewers: int>>
# operationId: showViewerDataStreamTarget
export def "show-viewer-data-stream-target" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/usage/viewer_data/stream_targets/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: from, var: from}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: wsc-api-key
  } {
    id: $id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
