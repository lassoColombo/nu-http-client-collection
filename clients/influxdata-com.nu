# Auto-generated client for Influx OSS API Service v2.0.0
# Source: https://api.apis.guru/v2/specs/influxdata.com/2.0.0/openapi.json
# Auth: --token flag or $env.INFLUX_OSS_API_SERVICE_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/api/v2"
  token_env_var: "INFLUX_OSS_API_SERVICE_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
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

def base-url-completer [] { ["https://api.apis.guru/api/v2" ""] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["active" "inactive"] }
def schema-type-completer [] { ["explicit" "implicit"] }
def sort-by-completer [] { ["CreatedAt" "ID" "UpdatedAt"] }
def include-completer [] { ["properties"] }
def type-completer [] { ["flux"] }
def accept-encoding-completer [] { ["gzip" "identity"] }
def content-type-completer [] { ["application/json" "application/vnd.flux"] }
def accept-completer [] { ["application/json" "application/vnd.influx.arrow" "text/csv"] }
def content-type-completer-1 [] { ["application/json"] }
def type-completer-1 [] { ["prometheus"] }
def type-completer-2 [] { ["self" "v1" "v2"] }
def accept-completer-1 [] { ["application/json" "application/octet-stream" "application/toml"] }
def accept-completer-2 [] { ["application/json" "application/x-yaml"] }
def precision-completer [] { ["ms" "ns" "s" "us"] }
def content-encoding-completer [] { ["gzip" "identity"] }
def content-type-completer-2 [] { ["application/vnd.influx.arrow" "text/plain" "text/plain; charset=utf-8"] }
def accept-completer-3 [] { ["application/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-routes: "record<authorizations: string, buckets: string, dashboards: string, external: record<statusFeed: string>, flags: string, me: string, orgs: string, query: record<analyze: string, ast: string, self: string, suggestions: string>, setup: string, signin: string, signout: string, sources: string, system: record<debug: string, health: string, metrics: string>, tasks: string, telegrafs: string, users: string, variables: string, write: string>"
    get-authorizations: "record<authorizations: table<description: string, status: string, createdAt: string, id: string, links: record, org: string, orgID: string, permissions: list, token: string, updatedAt: string, user: string, userID: string>, links: record<next: string, prev: string, self: string>>"
    post-authorizations: "record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string>"
    get-authorizations-id: "record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string>"
    patch-authorizations-id: "record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string>"
    get-buckets: "record<buckets: table<createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, retentionRules: list, rp: string, schemaType: string, type: string, updatedAt: string>, links: record<next: string, prev: string, self: string>>"
    post-buckets: "record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string>"
    get-buckets-id: "record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string>"
    patch-buckets-id: "record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string>"
    get-buckets-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-buckets-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-buckets-id-members: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-buckets-id-members: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-buckets-id-owners: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-buckets-id-owners: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-checks: "record<checks: list<record>, links: record<next: string, prev: string, self: string>>"
    create-check: "record"
    get-checks-id: "record"
    patch-checks-id: "record"
    put-checks-id: "record"
    get-checks-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-checks-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-checks-id-query: "record<flux: string>"
    get-dashboards: "record<dashboards: table<description: string, name: string, orgID: string, cells: list, id: string, labels: list, links: record, meta: record>, links: record<next: string, prev: string, self: string>>"
    patch-dashboards-id: "record<description: string, name: string, orgID: string, cells: table<h: int, id: string, links: record, viewID: string, w: int, x: int, y: int>, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<cells: string, labels: string, members: string, org: string, owners: string, self: string>, meta: record<createdAt: string, updatedAt: string>>"
    post-dashboards-id-cells: "record<h: int, id: string, links: record<self: string, view: string>, viewID: string, w: int, x: int, y: int>"
    put-dashboards-id-cells: "record<description: string, name: string, orgID: string, cells: table<h: int, id: string, links: record, viewID: string, w: int, x: int, y: int>, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<cells: string, labels: string, members: string, org: string, owners: string, self: string>, meta: record<createdAt: string, updatedAt: string>>"
    patch-dashboards-id-cells-id: "record<h: int, id: string, links: record<self: string, view: string>, viewID: string, w: int, x: int, y: int>"
    get-dashboards-id-cells-id-view: "record<id: string, links: record<self: string>, name: string, properties: any>"
    patch-dashboards-id-cells-id-view: "record<id: string, links: record<self: string>, name: string, properties: any>"
    get-dashboards-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-dashboards-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-dashboards-id-members: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-dashboards-id-members: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-dashboards-id-owners: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-dashboards-id-owners: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-dbr-ps: "record<content: table<bucketID: string, database: string, default: bool, id: string, links: record, org: string, orgID: string, retention_policy: string>>"
    post-dbrp: "record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string>"
    get-dbr-ps-id: "record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string>"
    patch-dbrpid: "record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string>"
    get-documents-templates: "record<documents: table<id: string, labels: list, links: record, meta: record>>"
    post-documents-templates: "record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>>"
    get-documents-templates-id: "record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>>"
    put-documents-templates-id: "record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>>"
    get-documents-templates-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-documents-templates-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-flags: "record"
    get-health: "record<checks: list<any>, commit: string, message: string, name: string, status: string, version: string>"
    get-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-labels-id: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    patch-labels-id: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-me: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>"
    get-notification-endpoints: "record<links: record<next: string, prev: string, self: string>, notificationEndpoints: list<record>>"
    create-notification-endpoint: "record"
    get-notification-endpoints-id: "record"
    patch-notification-endpoints-id: "record"
    put-notification-endpoints-id: "record"
    get-notification-endpoints-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-notification-endpoint-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-notification-rules: "record<links: record<next: string, prev: string, self: string>, notificationRules: list<record>>"
    create-notification-rule: "record"
    get-notification-rules-id: "record"
    patch-notification-rules-id: "record"
    put-notification-rules-id: "record"
    get-notification-rules-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-notification-rule-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-notification-rules-id-query: "record<flux: string>"
    get-orgs: "record<links: record<next: string, prev: string, self: string>, orgs: table<createdAt: string, description: string, id: string, links: record, name: string, status: string, updatedAt: string>>"
    post-orgs: "record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>"
    get-orgs-id: "record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>"
    patch-orgs-id: "record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>"
    get-orgs-id-members: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-orgs-id-members: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-orgs-id-owners: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-orgs-id-owners: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-orgs-id-secrets: "record<secrets: list<string>, links: record<org: string, self: string>>"
    post-query: "binary"
    post-query-analyze: "record<errors: table<character: int, column: int, line: int, message: string>>"
    post-query-ast: "record<ast: record<files: list<record>, package: string, path: string, type: string>>"
    get-query-suggestions: "record<funcs: table<name: string, params: record>>"
    get-query-suggestions-name: "record<name: string, params: record>"
    get-ready: "record<started: string, status: string, up: string>"
    get-scrapers: "record<configurations: table<allowInsecure: bool, bucketID: string, name: string, orgID: string, type: string, url: string, bucket: string, id: string, links: record, org: string>>"
    post-scrapers: "record<allowInsecure: bool, bucketID: string, name: string, orgID: string, type: string, url: string, bucket: string, id: string, links: record<bucket: string, members: string, organization: string, owners: string, self: string>, org: string>"
    get-scrapers-id: "record<allowInsecure: bool, bucketID: string, name: string, orgID: string, type: string, url: string, bucket: string, id: string, links: record<bucket: string, members: string, organization: string, owners: string, self: string>, org: string>"
    patch-scrapers-id: "record<allowInsecure: bool, bucketID: string, name: string, orgID: string, type: string, url: string, bucket: string, id: string, links: record<bucket: string, members: string, organization: string, owners: string, self: string>, org: string>"
    get-scrapers-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-scrapers-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-scrapers-id-members: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-scrapers-id-members: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-scrapers-id-owners: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-scrapers-id-owners: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-setup: "record<allowed: bool>"
    post-setup: "record<auth: record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: list<record>, token: string, updatedAt: string, user: string, userID: string>, bucket: record<createdAt: string, description: string, id: string, labels: list<record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: list<record>, rp: string, schemaType: string, type: string, updatedAt: string>, org: record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>, user: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>>"
    get-sources: "record<links: record<self: string>, sources: table<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list, links: record, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>>"
    post-sources: "record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>"
    get-sources-id: "record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>"
    patch-sources-id: "record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>"
    get-sources-id-buckets: "record<buckets: table<createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, retentionRules: list, rp: string, schemaType: string, type: string, updatedAt: string>, links: record<next: string, prev: string, self: string>>"
    get-sources-id-health: "record<checks: list<any>, commit: string, message: string, name: string, status: string, version: string>"
    list-stacks: "record<stacks: table<createdAt: string, events: list, id: string, orgID: string>>"
    create-stack: "record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string>"
    read-stack: "record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string>"
    update-stack: "record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string>"
    uninstall-stack: "record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string>"
    get-tasks: "record<links: record<next: string, prev: string, self: string>, tasks: table<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: list, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>>"
    post-tasks: "record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>"
    get-tasks-id: "record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>"
    patch-tasks-id: "record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>"
    get-tasks-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-tasks-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-tasks-id-logs: "record<events: table<message: string, runID: string, time: string>>"
    get-tasks-id-members: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-tasks-id-members: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-tasks-id-owners: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-tasks-id-owners: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-tasks-id-runs: "record<links: record<next: string, prev: string, self: string>, runs: table<finishedAt: string, id: string, links: record, log: list, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>>"
    post-tasks-id-runs: "record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>"
    get-tasks-id-runs-id: "record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>"
    get-tasks-id-runs-id-logs: "record<events: table<message: string, runID: string, time: string>>"
    post-tasks-id-runs-id-retry: "record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>"
    get-telegraf-plugins: "record<os: string, plugins: table<config: string, description: string, name: string, type: string>, version: string>"
    get-telegrafs: "record<configurations: table<config: string, description: string, metadata: record, name: string, orgID: string, id: string, labels: list, links: record>>"
    post-telegrafs: "record<config: string, description: string, metadata: record<buckets: list<string>>, name: string, orgID: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, owners: string, self: string>>"
    get-telegrafs-id: "record<config: string, description: string, metadata: record<buckets: list<string>>, name: string, orgID: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, owners: string, self: string>>"
    put-telegrafs-id: "record<config: string, description: string, metadata: record<buckets: list<string>>, name: string, orgID: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, owners: string, self: string>>"
    get-telegrafs-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-telegrafs-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    get-telegrafs-id-members: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-telegrafs-id-members: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    get-telegrafs-id-owners: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>"
    post-telegrafs-id-owners: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>"
    apply-template: "record<diff: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labelMappings: list<record>, labels: list<record>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>, errors: table<fields: list, indexes: list, kind: string, reason: string>, sources: list<string>, stackID: string, summary: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labelMappings: list<record>, labels: list<record>, missingEnvRefs: list<string>, missingSecrets: list<string>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>>"
    export-template: "table<apiVersion: string, kind: string, meta: record<name: string>, spec: record>"
    get-users: "record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string>>"
    post-users: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>"
    get-users-id: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>"
    patch-users-id: "record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>"
    get-variables: "record<variables: table<arguments: record, createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, selected: list, updatedAt: string>>"
    post-variables: "record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string>"
    get-variables-id: "record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string>"
    patch-variables-id: "record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string>"
    put-variables-id: "record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string>"
    get-variables-id-labels: "record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
    post-variables-id-labels: "record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-routes" "get-authorizations" "post-authorizations" "delete-authorizations-id" "get-authorizations-id" "patch-authorizations-id" "get-buckets" "post-buckets" "delete-buckets-id" "get-buckets-id" "patch-buckets-id" "get-buckets-id-labels" "post-buckets-id-labels" "delete-buckets-id-labels-id" "get-buckets-id-members" "post-buckets-id-members" "delete-buckets-id-members-id" "get-buckets-id-owners" "post-buckets-id-owners" "delete-buckets-id-owners-id" "get-checks" "create-check" "delete-checks-id" "get-checks-id" "patch-checks-id" "put-checks-id" "get-checks-id-labels" "post-checks-id-labels" "delete-checks-id-labels-id" "get-checks-id-query" "get-dashboards" "post-dashboards" "delete-dashboards-id" "get-dashboards-id" "patch-dashboards-id" "post-dashboards-id-cells" "put-dashboards-id-cells" "delete-dashboards-id-cells-id" "patch-dashboards-id-cells-id" "get-dashboards-id-cells-id-view" "patch-dashboards-id-cells-id-view" "get-dashboards-id-labels" "post-dashboards-id-labels" "delete-dashboards-id-labels-id" "get-dashboards-id-members" "post-dashboards-id-members" "delete-dashboards-id-members-id" "get-dashboards-id-owners" "post-dashboards-id-owners" "delete-dashboards-id-owners-id" "get-dbr-ps" "post-dbrp" "delete-dbrpid" "get-dbr-ps-id" "patch-dbrpid" "post-delete" "get-documents-templates" "post-documents-templates" "delete-documents-templates-id" "get-documents-templates-id" "put-documents-templates-id" "get-documents-templates-id-labels" "post-documents-templates-id-labels" "delete-documents-templates-id-labels-id" "get-flags" "get-health" "get-labels" "post-labels" "delete-labels-id" "get-labels-id" "patch-labels-id" "get-me" "put-me-password" "get-notification-endpoints" "create-notification-endpoint" "delete-notification-endpoints-id" "get-notification-endpoints-id" "patch-notification-endpoints-id" "put-notification-endpoints-id" "get-notification-endpoints-id-labels" "post-notification-endpoint-id-labels" "delete-notification-endpoints-id-labels-id" "get-notification-rules" "create-notification-rule" "delete-notification-rules-id" "get-notification-rules-id" "patch-notification-rules-id" "put-notification-rules-id" "get-notification-rules-id-labels" "post-notification-rule-id-labels" "delete-notification-rules-id-labels-id" "get-notification-rules-id-query" "get-orgs" "post-orgs" "delete-orgs-id" "get-orgs-id" "patch-orgs-id" "get-orgs-id-members" "post-orgs-id-members" "delete-orgs-id-members-id" "get-orgs-id-owners" "post-orgs-id-owners" "delete-orgs-id-owners-id" "get-orgs-id-secrets" "patch-orgs-id-secrets" "post-orgs-id-secrets" "post-query" "post-query-analyze" "post-query-ast" "get-query-suggestions" "get-query-suggestions-name" "get-ready" "get-scrapers" "post-scrapers" "delete-scrapers-id" "get-scrapers-id" "patch-scrapers-id" "get-scrapers-id-labels" "post-scrapers-id-labels" "delete-scrapers-id-labels-id" "get-scrapers-id-members" "post-scrapers-id-members" "delete-scrapers-id-members-id" "get-scrapers-id-owners" "post-scrapers-id-owners" "delete-scrapers-id-owners-id" "get-setup" "post-setup" "post-signin" "post-signout" "get-sources" "post-sources" "delete-sources-id" "get-sources-id" "patch-sources-id" "get-sources-id-buckets" "get-sources-id-health" "list-stacks" "create-stack" "delete-stack" "read-stack" "update-stack" "uninstall-stack" "get-tasks" "post-tasks" "delete-tasks-id" "get-tasks-id" "patch-tasks-id" "get-tasks-id-labels" "post-tasks-id-labels" "delete-tasks-id-labels-id" "get-tasks-id-logs" "get-tasks-id-members" "post-tasks-id-members" "delete-tasks-id-members-id" "get-tasks-id-owners" "post-tasks-id-owners" "delete-tasks-id-owners-id" "get-tasks-id-runs" "post-tasks-id-runs" "delete-tasks-id-runs-id" "get-tasks-id-runs-id" "get-tasks-id-runs-id-logs" "post-tasks-id-runs-id-retry" "get-telegraf-plugins" "get-telegrafs" "post-telegrafs" "delete-telegrafs-id" "get-telegrafs-id" "put-telegrafs-id" "get-telegrafs-id-labels" "post-telegrafs-id-labels" "delete-telegrafs-id-labels-id" "get-telegrafs-id-members" "post-telegrafs-id-members" "delete-telegrafs-id-members-id" "get-telegrafs-id-owners" "post-telegrafs-id-owners" "delete-telegrafs-id-owners-id" "apply-template" "export-template" "get-users" "post-users" "delete-users-id" "get-users-id" "patch-users-id" "post-users-id-password" "get-variables" "post-variables" "delete-variables-id" "get-variables-id" "patch-variables-id" "put-variables-id" "get-variables-id-labels" "post-variables-id-labels" "delete-variables-id-labels-id" "post-write" "commands"] | sort) } | get name | first)
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

# List all top level routes
#
# GET /
# Returns: record<authorizations: string, buckets: string, dashboards: string, external: record<statusFeed: string>, flags: string, me: string, orgs: string, query: record<analyze: string, ast: string, self: string, suggestions: string>, setup: string, signin: string, signout: string, sources: string, system: record<debug: string, health: string, metrics: string>, tasks: string, telegrafs: string, users: string, variables: string, write: string>
# operationId: GetRoutes
export def "get-routes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all authorizations
#
# GET /authorizations
# Returns: record<authorizations: table<description: string, status: string, createdAt: string, id: string, links: record, org: string, orgID: string, permissions: list, token: string, updatedAt: string, user: string, userID: string>, links: record<next: string, prev: string, self: string>>
# operationId: GetAuthorizations
export def "get-authorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # Only show authorizations that belong to a user ID.
  --user: string # Only show authorizations that belong to a user name.
  --org-id: string # Only show authorizations that belong to an organization ID.
  --org: string # Only show authorizations that belong to a organization name.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authorizations"
    query: [{name: userID, var: user_id}, {name: user, var: user}, {name: orgID, var: org_id}, {name: org, var: org}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    user_id: $user_id, user: $user, org_id: $org_id, org: $org, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an authorization
#
# POST /authorizations
# Returns: record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string>
# operationId: PostAuthorizations
export def "post-authorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # A description of the token.
  --status: string@status-completer # If inactive the token is inactive and requests using the token will be rejected. (default: active)
  org_id: string # ID of org that authorization is scoped to.
  permissions: list # List of permissions for an auth. An auth must have at least one Permission. — item shape: {action: "read"|"write", resource: record}
  --user-id: string # ID of user that authorization is scoped to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorizations"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: status, var: status}, {name: orgID, var: org_id}, {name: permissions, var: permissions}, {name: userID, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, description: $description, status: $status, org_id: $org_id, permissions: $permissions, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an authorization
#
# DELETE /authorizations/{authID}
# operationId: DeleteAuthorizationsID
export def "delete-authorizations-id" [
  auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/authorizations/{authID}"
    path_params: [{name: authID, var: auth_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    auth_id: $auth_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an authorization
#
# GET /authorizations/{authID}
# Returns: record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string>
# operationId: GetAuthorizationsID
export def "get-authorizations-id" [
  auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authorizations/{authID}"
    path_params: [{name: authID, var: auth_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    auth_id: $auth_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an authorization to be active or inactive
#
# PATCH /authorizations/{authID}
# Returns: record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string>
# operationId: PatchAuthorizationsID
export def "patch-authorizations-id" [
  auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # A description of the token.
  --status: string@status-completer # If inactive the token is inactive and requests using the token will be rejected. (default: active)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/authorizations/{authID}"
    path_params: [{name: authID, var: auth_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    auth_id: $auth_id, zap_trace_span: $zap_trace_span, description: $description, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all buckets
#
# GET /buckets
# Returns: record<buckets: table<createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, retentionRules: list, rp: string, schemaType: string, type: string, updatedAt: string>, links: record<next: string, prev: string, self: string>>
# operationId: GetBuckets
export def "get-buckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --after: string # The last resource ID from which to seek from (but not including). This is to be used instead of `offset`.
  --org: string # The name of the organization.
  --org-id: string # The organization ID.
  --name: string # Only returns buckets with a specific name.
  --id: string # Only returns buckets with a specific ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/buckets"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: after, var: after}, {name: org, var: org}, {name: orgID, var: org_id}, {name: name, var: name}, {name: id, var: id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    offset: $offset, limit: $limit, after: $after, org: $org, org_id: $org_id, name: $name, id: $id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a bucket
#
# POST /buckets
# Returns: record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string>
# operationId: PostBuckets
export def "post-buckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  name: string
  org_id: string
  retention_rules: list # Rules to expire or retain data. No rules means data never expires. — item shape: {everySeconds: int, shardGroupDurationSeconds?: int, type: "expire"}
  --rp: string
  --schema-type: string@schema-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/buckets"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: orgID, var: org_id}, {name: retentionRules, var: retention_rules}, {name: rp, var: rp}, {name: schemaType, var: schema_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, description: $description, name: $name, org_id: $org_id, retention_rules: $retention_rules, rp: $rp, schema_type: $schema_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a bucket
#
# DELETE /buckets/{bucketID}
# operationId: DeleteBucketsID
export def "delete-buckets-id" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/buckets/{bucketID}"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a bucket
#
# GET /buckets/{bucketID}
# Returns: record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string>
# operationId: GetBucketsID
export def "get-buckets-id" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/buckets/{bucketID}"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a bucket
#
# PATCH /buckets/{bucketID}
# Returns: record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string>
# operationId: PatchBucketsID
export def "patch-buckets-id" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --retention-rules: list # Updates to rules to expire or retain data. No rules means no updates. — item shape: {everySeconds?: int, shardGroupDurationSeconds?: int, type: "expire"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/buckets/{bucketID}"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: retentionRules, var: retention_rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span, description: $description, name: $name, retention_rules: $retention_rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a bucket
#
# GET /buckets/{bucketID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetBucketsIDLabels
export def "get-buckets-id-labels" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/buckets/{bucketID}/labels"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a bucket
#
# POST /buckets/{bucketID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostBucketsIDLabels
export def "post-buckets-id-labels" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/buckets/{bucketID}/labels"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label from a bucket
#
# DELETE /buckets/{bucketID}/labels/{labelID}
# operationId: DeleteBucketsIDLabelsID
export def "delete-buckets-id-labels-id" [
  bucket_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/buckets/{bucketID}/labels/{labelID}"
    path_params: [{name: bucketID, var: bucket_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    bucket_id: $bucket_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all users with member privileges for a bucket
#
# GET /buckets/{bucketID}/members
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetBucketsIDMembers
export def "get-buckets-id-members" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/buckets/{bucketID}/members"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a member to a bucket
#
# POST /buckets/{bucketID}/members
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostBucketsIDMembers
export def "post-buckets-id-members" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/buckets/{bucketID}/members"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a member from a bucket
#
# DELETE /buckets/{bucketID}/members/{userID}
# operationId: DeleteBucketsIDMembersID
export def "delete-buckets-id-members-id" [
  bucket_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/buckets/{bucketID}/members/{userID}"
    path_params: [{name: bucketID, var: bucket_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    bucket_id: $bucket_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all owners of a bucket
#
# GET /buckets/{bucketID}/owners
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetBucketsIDOwners
export def "get-buckets-id-owners" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/buckets/{bucketID}/owners"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an owner to a bucket
#
# POST /buckets/{bucketID}/owners
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostBucketsIDOwners
export def "post-buckets-id-owners" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/buckets/{bucketID}/owners"
    path_params: [{name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    bucket_id: $bucket_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an owner from a bucket
#
# DELETE /buckets/{bucketID}/owners/{userID}
# operationId: DeleteBucketsIDOwnersID
export def "delete-buckets-id-owners-id" [
  bucket_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/buckets/{bucketID}/owners/{userID}"
    path_params: [{name: bucketID, var: bucket_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    bucket_id: $bucket_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all checks
#
# GET /checks
# Returns: record<checks: list<record>, links: record<next: string, prev: string, self: string>>
# operationId: GetChecks
export def "get-checks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --org-id: string # Only show checks that belong to a specific organization ID. (required)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/checks"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: orgID, var: org_id, required: true}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    offset: $offset, limit: $limit, org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new check
#
# POST /checks
# Returns: record
# operationId: CreateCheck
export def "create-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/checks"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a check
#
# DELETE /checks/{checkID}
# operationId: DeleteChecksID
export def "delete-checks-id" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/checks/{checkID}"
    path_params: [{name: checkID, var: check_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    check_id: $check_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a check
#
# GET /checks/{checkID}
# Returns: record
# operationId: GetChecksID
export def "get-checks-id" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/checks/{checkID}"
    path_params: [{name: checkID, var: check_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    check_id: $check_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a check
#
# PATCH /checks/{checkID}
# Returns: record
# operationId: PatchChecksID
export def "patch-checks-id" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/checks/{checkID}"
    path_params: [{name: checkID, var: check_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    check_id: $check_id, zap_trace_span: $zap_trace_span, description: $description, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a check
#
# PUT /checks/{checkID}
# Returns: record
# operationId: PutChecksID
export def "put-checks-id" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/checks/{checkID}"
    path_params: [{name: checkID, var: check_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    check_id: $check_id, zap_trace_span: $zap_trace_span, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a check
#
# GET /checks/{checkID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetChecksIDLabels
export def "get-checks-id-labels" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/checks/{checkID}/labels"
    path_params: [{name: checkID, var: check_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    check_id: $check_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a check
#
# POST /checks/{checkID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostChecksIDLabels
export def "post-checks-id-labels" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/checks/{checkID}/labels"
    path_params: [{name: checkID, var: check_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    check_id: $check_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete label from a check
#
# DELETE /checks/{checkID}/labels/{labelID}
# operationId: DeleteChecksIDLabelsID
export def "delete-checks-id-labels-id" [
  check_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/checks/{checkID}/labels/{labelID}"
    path_params: [{name: checkID, var: check_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    check_id: $check_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a check query
#
# GET /checks/{checkID}/query
# Returns: record<flux: string>
# operationId: GetChecksIDQuery
export def "get-checks-id-query" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/checks/{checkID}/query"
    path_params: [{name: checkID, var: check_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    check_id: $check_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all dashboards
#
# GET /dashboards
# Returns: record<dashboards: table<description: string, name: string, orgID: string, cells: list, id: string, labels: list, links: record, meta: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetDashboards
export def "get-dashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --descending: oneof<nothing, bool> # default: false
  --owner: string # A user identifier. Returns only dashboards where this user has the `owner` role.
  --sort-by: string@sort-by-completer # The column to sort by.
  --id: list<string> # A list of dashboard identifiers. Returns only the listed dashboards. If both `id` and `owner` are specified, only `id` is used.
  --org-id: string # The identifier of the organization.
  --org: string # The name of the organization.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboards"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: descending, var: descending}, {name: owner, var: owner}, {name: sortBy, var: sort_by}, {name: id, var: id, style: multi}, {name: orgID, var: org_id}, {name: org, var: org}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    offset: $offset, limit: $limit, descending: $descending, owner: $owner, sort_by: $sort_by, id: $id, org_id: $org_id, org: $org, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a dashboard
#
# POST /dashboards
# operationId: PostDashboards
export def "post-dashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # The user-facing description of the dashboard.
  name: string # The user-facing name of the dashboard.
  org_id: string # The ID of the organization that owns the dashboard.
]: any -> any {
  $in | http-request {
    method: post
    path: "/dashboards"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: orgID, var: org_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, description: $description, name: $name, org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a dashboard
#
# DELETE /dashboards/{dashboardID}
# operationId: DeleteDashboardsID
export def "delete-dashboards-id" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/dashboards/{dashboardID}"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Dashboard
#
# GET /dashboards/{dashboardID}
# operationId: GetDashboardsID
export def "get-dashboards-id" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Includes the cell view properties in the response if set to `properties`
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: get
    path: "/dashboards/{dashboardID}"
    path_params: [{name: dashboardID, var: dashboard_id}]
    query: [{name: include, var: include}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dashboard_id: $dashboard_id, include: $include, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a dashboard
#
# PATCH /dashboards/{dashboardID}
# Returns: record<description: string, name: string, orgID: string, cells: table<h: int, id: string, links: record, viewID: string, w: int, x: int, y: int>, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<cells: string, labels: string, members: string, org: string, owners: string, self: string>, meta: record<createdAt: string, updatedAt: string>>
# operationId: PatchDashboardsID
export def "patch-dashboards-id" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --cells: record # shape: {h?: int, id?: string, links?: record, viewID?: string, w?: int, x?: int, y?: int, name?: string, properties?: any}
  --description: string # optional, when provided will replace the description
  --name: string # optional, when provided will replace the name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dashboards/{dashboardID}"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: cells, var: cells}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span, cells: $cells, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a dashboard cell
#
# POST /dashboards/{dashboardID}/cells
# Returns: record<h: int, id: string, links: record<self: string, view: string>, viewID: string, w: int, x: int, y: int>
# operationId: PostDashboardsIDCells
export def "post-dashboards-id-cells" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --h: int # format: int32
  --name: string
  --using-view: string # Makes a copy of the provided view.
  --w: int # format: int32
  --x: int # format: int32
  --y: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dashboards/{dashboardID}/cells"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: h, var: h}, {name: name, var: name}, {name: usingView, var: using_view}, {name: w, var: w}, {name: x, var: x}, {name: y, var: y}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span, h: $h, name: $name, using_view: $using_view, w: $w, x: $x, y: $y
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace cells in a dashboard
#
# PUT /dashboards/{dashboardID}/cells
# Returns: record<description: string, name: string, orgID: string, cells: table<h: int, id: string, links: record, viewID: string, w: int, x: int, y: int>, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<cells: string, labels: string, members: string, org: string, owners: string, self: string>, meta: record<createdAt: string, updatedAt: string>>
# operationId: PutDashboardsIDCells
export def "put-dashboards-id-cells" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/dashboards/{dashboardID}/cells"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a dashboard cell
#
# DELETE /dashboards/{dashboardID}/cells/{cellID}
# operationId: DeleteDashboardsIDCellsID
export def "delete-dashboards-id-cells-id" [
  dashboard_id: string
  cell_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/dashboards/{dashboardID}/cells/{cellID}"
    path_params: [{name: dashboardID, var: dashboard_id}, {name: cellID, var: cell_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    dashboard_id: $dashboard_id, cell_id: $cell_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the non-positional information related to a cell
#
# PATCH /dashboards/{dashboardID}/cells/{cellID}
# Returns: record<h: int, id: string, links: record<self: string, view: string>, viewID: string, w: int, x: int, y: int>
# operationId: PatchDashboardsIDCellsID
export def "patch-dashboards-id-cells-id" [
  dashboard_id: string
  cell_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --h: int # format: int32
  --w: int # format: int32
  --x: int # format: int32
  --y: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dashboards/{dashboardID}/cells/{cellID}"
    path_params: [{name: dashboardID, var: dashboard_id}, {name: cellID, var: cell_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: h, var: h}, {name: w, var: w}, {name: x, var: x}, {name: y, var: y}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dashboard_id: $dashboard_id, cell_id: $cell_id, zap_trace_span: $zap_trace_span, h: $h, w: $w, x: $x, y: $y
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the view for a cell
#
# GET /dashboards/{dashboardID}/cells/{cellID}/view
# Returns: record<id: string, links: record<self: string>, name: string, properties: any>
# operationId: GetDashboardsIDCellsIDView
export def "get-dashboards-id-cells-id-view" [
  dashboard_id: string
  cell_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboards/{dashboardID}/cells/{cellID}/view"
    path_params: [{name: dashboardID, var: dashboard_id}, {name: cellID, var: cell_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dashboard_id: $dashboard_id, cell_id: $cell_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the view for a cell
#
# PATCH /dashboards/{dashboardID}/cells/{cellID}/view
# Returns: record<id: string, links: record<self: string>, name: string, properties: any>
# operationId: PatchDashboardsIDCellsIDView
export def "patch-dashboards-id-cells-id-view" [
  dashboard_id: string
  cell_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  properties: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dashboards/{dashboardID}/cells/{cellID}/view"
    path_params: [{name: dashboardID, var: dashboard_id}, {name: cellID, var: cell_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dashboard_id: $dashboard_id, cell_id: $cell_id, zap_trace_span: $zap_trace_span, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a dashboard
#
# GET /dashboards/{dashboardID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetDashboardsIDLabels
export def "get-dashboards-id-labels" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboards/{dashboardID}/labels"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a dashboard
#
# POST /dashboards/{dashboardID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostDashboardsIDLabels
export def "post-dashboards-id-labels" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dashboards/{dashboardID}/labels"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label from a dashboard
#
# DELETE /dashboards/{dashboardID}/labels/{labelID}
# operationId: DeleteDashboardsIDLabelsID
export def "delete-dashboards-id-labels-id" [
  dashboard_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/dashboards/{dashboardID}/labels/{labelID}"
    path_params: [{name: dashboardID, var: dashboard_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    dashboard_id: $dashboard_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all dashboard members
#
# GET /dashboards/{dashboardID}/members
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetDashboardsIDMembers
export def "get-dashboards-id-members" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboards/{dashboardID}/members"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a member to a dashboard
#
# POST /dashboards/{dashboardID}/members
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostDashboardsIDMembers
export def "post-dashboards-id-members" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dashboards/{dashboardID}/members"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a member from a dashboard
#
# DELETE /dashboards/{dashboardID}/members/{userID}
# operationId: DeleteDashboardsIDMembersID
export def "delete-dashboards-id-members-id" [
  dashboard_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/dashboards/{dashboardID}/members/{userID}"
    path_params: [{name: dashboardID, var: dashboard_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    dashboard_id: $dashboard_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all dashboard owners
#
# GET /dashboards/{dashboardID}/owners
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetDashboardsIDOwners
export def "get-dashboards-id-owners" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboards/{dashboardID}/owners"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an owner to a dashboard
#
# POST /dashboards/{dashboardID}/owners
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostDashboardsIDOwners
export def "post-dashboards-id-owners" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dashboards/{dashboardID}/owners"
    path_params: [{name: dashboardID, var: dashboard_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    dashboard_id: $dashboard_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an owner from a dashboard
#
# DELETE /dashboards/{dashboardID}/owners/{userID}
# operationId: DeleteDashboardsIDOwnersID
export def "delete-dashboards-id-owners-id" [
  dashboard_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/dashboards/{dashboardID}/owners/{userID}"
    path_params: [{name: dashboardID, var: dashboard_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    dashboard_id: $dashboard_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all database retention policy mappings
#
# GET /dbrps
# Returns: record<content: table<bucketID: string, database: string, default: bool, id: string, links: record, org: string, orgID: string, retention_policy: string>>
# operationId: GetDBRPs
export def "get-dbr-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Specifies the organization ID to filter on (required)
  --id: string # Specifies the mapping ID to filter on
  --bucket-id: string # Specifies the bucket ID to filter on
  --default: oneof<nothing, bool> # Specifies filtering on default
  --db: string # Specifies the database to filter on
  --rp: string # Specifies the retention policy to filter on
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dbrps"
    query: [{name: orgID, var: org_id, required: true}, {name: id, var: id}, {name: bucketID, var: bucket_id}, {name: default, var: default}, {name: db, var: db}, {name: rp, var: rp}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, id: $id, bucket_id: $bucket_id, default: $default, db: $db, rp: $rp, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a database retention policy mapping
#
# POST /dbrps
# Returns: record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string>
# operationId: PostDBRP
export def "post-dbrp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  bucket_id: string # the bucket ID used as target for the translation.
  database: string # InfluxDB v1 database
  --default: oneof<nothing, bool> # Specify if this mapping represents the default retention policy for the database specificed.
  --links: record
  --org: string # the organization that owns this mapping.
  --org-id: string # the organization ID that owns this mapping.
  retention_policy: string # InfluxDB v1 retention policy
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dbrps"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketID, var: bucket_id}, {name: database, var: database}, {name: default, var: default}, {name: links, var: links}, {name: org, var: org}, {name: orgID, var: org_id}, {name: retention_policy, var: retention_policy}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, bucket_id: $bucket_id, database: $database, default: $default, links: $links, org: $org, org_id: $org_id, retention_policy: $retention_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a database retention policy
#
# DELETE /dbrps/{dbrpID}
# operationId: DeleteDBRPID
export def "delete-dbrpid" [
  dbrp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Specifies the organization ID of the mapping (required)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/dbrps/{dbrpID}"
    path_params: [{name: dbrpID, var: dbrp_id}]
    query: [{name: orgID, var: org_id, required: true}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    dbrp_id: $dbrp_id, org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a database retention policy mapping
#
# GET /dbrps/{dbrpID}
# Returns: record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string>
# operationId: GetDBRPsID
export def "get-dbr-ps-id" [
  dbrp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Specifies the organization ID of the mapping (required)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dbrps/{dbrpID}"
    path_params: [{name: dbrpID, var: dbrp_id}]
    query: [{name: orgID, var: org_id, required: true}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dbrp_id: $dbrp_id, org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a database retention policy mapping
#
# PATCH /dbrps/{dbrpID}
# Returns: record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string>
# operationId: PatchDBRPID
export def "patch-dbrpid" [
  dbrp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Specifies the organization ID of the mapping (required)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --database: string # InfluxDB v1 database
  --default: oneof<nothing, bool>
  --links: record
  --retention-policy: string # InfluxDB v1 retention policy
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dbrps/{dbrpID}"
    path_params: [{name: dbrpID, var: dbrp_id}]
    query: [{name: orgID, var: org_id, required: true}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: database, var: database}, {name: default, var: default}, {name: links, var: links}, {name: retention_policy, var: retention_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dbrp_id: $dbrp_id, org_id: $org_id, zap_trace_span: $zap_trace_span, database: $database, default: $default, links: $links, retention_policy: $retention_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete time series data from InfluxDB
#
# POST /delete
# operationId: PostDelete
export def "post-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # Specifies the organization to delete data from.
  --bucket: string # Specifies the bucket to delete data from.
  --org-id: string # Specifies the organization ID of the resource.
  --bucket-id: string # Specifies the bucket ID to delete data from.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --predicate: string # InfluxQL-like delete statement (e.g. tag1="value1" and (tag2="value2" and tag3!="value3"))
  start: string # RFC3339Nano (format: date-time)
  stop: string # RFC3339Nano (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/delete"
    query: [{name: org, var: org}, {name: bucket, var: bucket}, {name: orgID, var: org_id}, {name: bucketID, var: bucket_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: predicate, var: predicate}, {name: start, var: start}, {name: stop, var: stop}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org, bucket: $bucket, org_id: $org_id, bucket_id: $bucket_id, zap_trace_span: $zap_trace_span, predicate: $predicate, start: $start, stop: $stop
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all templates
#
# GET /documents/templates
# Returns: record<documents: table<id: string, labels: list, links: record, meta: record>>
# operationId: GetDocumentsTemplates
export def "get-documents-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # Specifies the name of the organization of the template.
  --org-id: string # Specifies the organization ID of the template.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents/templates"
    query: [{name: org, var: org}, {name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org: $org, org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a template
#
# POST /documents/templates
# Returns: record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>>
# operationId: PostDocumentsTemplates
export def "post-documents-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  content: record
  --labels: list<string> # An array of label IDs to be added as labels to the document.
  meta: record # shape: {description?: string, name: string, templateID?: string, type?: string, version: string}
  --org: string # The organization Name. Specify either `orgID` or `org`.
  --org-id: string # The organization Name. Specify either `orgID` or `org`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/documents/templates"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: labels, var: labels}, {name: meta, var: meta}, {name: org, var: org}, {name: orgID, var: org_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, content: $content, labels: $labels, meta: $meta, org: $org, org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a template
#
# DELETE /documents/templates/{templateID}
# operationId: DeleteDocumentsTemplatesID
export def "delete-documents-templates-id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/documents/templates/{templateID}"
    path_params: [{name: templateID, var: template_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    template_id: $template_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a template
#
# GET /documents/templates/{templateID}
# Returns: record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>>
# operationId: GetDocumentsTemplatesID
export def "get-documents-templates-id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents/templates/{templateID}"
    path_params: [{name: templateID, var: template_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a template
#
# PUT /documents/templates/{templateID}
# Returns: record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>>
# operationId: PutDocumentsTemplatesID
export def "put-documents-templates-id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content: record
  --meta: record # shape: {description?: string, name: string, templateID?: string, type?: string, version: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/documents/templates/{templateID}"
    path_params: [{name: templateID, var: template_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: meta, var: meta}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, zap_trace_span: $zap_trace_span, content: $content, meta: $meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a template
#
# GET /documents/templates/{templateID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetDocumentsTemplatesIDLabels
export def "get-documents-templates-id-labels" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents/templates/{templateID}/labels"
    path_params: [{name: templateID, var: template_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a template
#
# POST /documents/templates/{templateID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostDocumentsTemplatesIDLabels
export def "post-documents-templates-id-labels" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/documents/templates/{templateID}/labels"
    path_params: [{name: templateID, var: template_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    template_id: $template_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label from a template
#
# DELETE /documents/templates/{templateID}/labels/{labelID}
# operationId: DeleteDocumentsTemplatesIDLabelsID
export def "delete-documents-templates-id-labels-id" [
  template_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/documents/templates/{templateID}/labels/{labelID}"
    path_params: [{name: templateID, var: template_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    template_id: $template_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the feature flags for the currently authenticated user
#
# GET /flags
# Returns: record
# operationId: GetFlags
export def "get-flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/flags"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the health of an instance
#
# GET /health
# Returns: record<checks: list<any>, commit: string, message: string, name: string, status: string, version: string>
# operationId: GetHealth
export def "get-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/health"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels
#
# GET /labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetLabels
export def "get-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The organization ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/labels"
    query: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a label
#
# POST /labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostLabels
export def "post-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  org_id: string
  --properties: record # Key/Value pairs associated with this label. Keys can be removed by sending an update with an empty value. (e.g. {color: ffb3b3, description: this is a description})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/labels"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: orgID, var: org_id}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    name: $name, org_id: $org_id, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label
#
# DELETE /labels/{labelID}
# operationId: DeleteLabelsID
export def "delete-labels-id" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/labels/{labelID}"
    path_params: [{name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a label
#
# GET /labels/{labelID}
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetLabelsID
export def "get-labels-id" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/labels/{labelID}"
    path_params: [{name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a label
#
# PATCH /labels/{labelID}
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PatchLabelsID
export def "patch-labels-id" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --name: string
  --properties: record # Key/Value pairs associated with this label. Keys can be removed by sending an update with an empty value. (e.g. {color: ffb3b3, description: this is a description})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/labels/{labelID}"
    path_params: [{name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    label_id: $label_id, zap_trace_span: $zap_trace_span, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the currently authenticated user
#
# GET /me
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>
# operationId: GetMe
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a password
#
# PUT /me/password
# operationId: PutMePassword
export def "put-me-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  password: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/me/password"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all notification endpoints
#
# GET /notificationEndpoints
# Returns: record<links: record<next: string, prev: string, self: string>, notificationEndpoints: list<record>>
# operationId: GetNotificationEndpoints
export def "get-notification-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --org-id: string # Only show notification endpoints that belong to specific organization ID. (required)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notificationEndpoints"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: orgID, var: org_id, required: true}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    offset: $offset, limit: $limit, org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a notification endpoint
#
# POST /notificationEndpoints
# Returns: record
# operationId: CreateNotificationEndpoint
export def "create-notification-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notificationEndpoints"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a notification endpoint
#
# DELETE /notificationEndpoints/{endpointID}
# operationId: DeleteNotificationEndpointsID
export def "delete-notification-endpoints-id" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/notificationEndpoints/{endpointID}"
    path_params: [{name: endpointID, var: endpoint_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    endpoint_id: $endpoint_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a notification endpoint
#
# GET /notificationEndpoints/{endpointID}
# Returns: record
# operationId: GetNotificationEndpointsID
export def "get-notification-endpoints-id" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notificationEndpoints/{endpointID}"
    path_params: [{name: endpointID, var: endpoint_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    endpoint_id: $endpoint_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a notification endpoint
#
# PATCH /notificationEndpoints/{endpointID}
# Returns: record
# operationId: PatchNotificationEndpointsID
export def "patch-notification-endpoints-id" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/notificationEndpoints/{endpointID}"
    path_params: [{name: endpointID, var: endpoint_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    endpoint_id: $endpoint_id, zap_trace_span: $zap_trace_span, description: $description, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a notification endpoint
#
# PUT /notificationEndpoints/{endpointID}
# Returns: record
# operationId: PutNotificationEndpointsID
export def "put-notification-endpoints-id" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/notificationEndpoints/{endpointID}"
    path_params: [{name: endpointID, var: endpoint_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    endpoint_id: $endpoint_id, zap_trace_span: $zap_trace_span, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a notification endpoint
#
# GET /notificationEndpoints/{endpointID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetNotificationEndpointsIDLabels
export def "get-notification-endpoints-id-labels" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notificationEndpoints/{endpointID}/labels"
    path_params: [{name: endpointID, var: endpoint_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    endpoint_id: $endpoint_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a notification endpoint
#
# POST /notificationEndpoints/{endpointID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostNotificationEndpointIDLabels
export def "post-notification-endpoint-id-labels" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notificationEndpoints/{endpointID}/labels"
    path_params: [{name: endpointID, var: endpoint_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    endpoint_id: $endpoint_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label from a notification endpoint
#
# DELETE /notificationEndpoints/{endpointID}/labels/{labelID}
# operationId: DeleteNotificationEndpointsIDLabelsID
export def "delete-notification-endpoints-id-labels-id" [
  endpoint_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/notificationEndpoints/{endpointID}/labels/{labelID}"
    path_params: [{name: endpointID, var: endpoint_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    endpoint_id: $endpoint_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all notification rules
#
# GET /notificationRules
# Returns: record<links: record<next: string, prev: string, self: string>, notificationRules: list<record>>
# operationId: GetNotificationRules
export def "get-notification-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --org-id: string # Only show notification rules that belong to a specific organization ID. (required)
  --check-id: string # Only show notifications that belong to the specific check ID.
  --tag: string # Only return notification rules that "would match" statuses which contain the tag key value pairs provided. (e.g. env:prod)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notificationRules"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: orgID, var: org_id, required: true}, {name: checkID, var: check_id}, {name: tag, var: tag}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    offset: $offset, limit: $limit, org_id: $org_id, check_id: $check_id, tag: $tag, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a notification rule
#
# POST /notificationRules
# Returns: record
# operationId: CreateNotificationRule
export def "create-notification-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notificationRules"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a notification rule
#
# DELETE /notificationRules/{ruleID}
# operationId: DeleteNotificationRulesID
export def "delete-notification-rules-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/notificationRules/{ruleID}"
    path_params: [{name: ruleID, var: rule_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    rule_id: $rule_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a notification rule
#
# GET /notificationRules/{ruleID}
# Returns: record
# operationId: GetNotificationRulesID
export def "get-notification-rules-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notificationRules/{ruleID}"
    path_params: [{name: ruleID, var: rule_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a notification rule
#
# PATCH /notificationRules/{ruleID}
# Returns: record
# operationId: PatchNotificationRulesID
export def "patch-notification-rules-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/notificationRules/{ruleID}"
    path_params: [{name: ruleID, var: rule_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id, zap_trace_span: $zap_trace_span, description: $description, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a notification rule
#
# PUT /notificationRules/{ruleID}
# Returns: record
# operationId: PutNotificationRulesID
export def "put-notification-rules-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/notificationRules/{ruleID}"
    path_params: [{name: ruleID, var: rule_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id, zap_trace_span: $zap_trace_span, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a notification rule
#
# GET /notificationRules/{ruleID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetNotificationRulesIDLabels
export def "get-notification-rules-id-labels" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notificationRules/{ruleID}/labels"
    path_params: [{name: ruleID, var: rule_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a notification rule
#
# POST /notificationRules/{ruleID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostNotificationRuleIDLabels
export def "post-notification-rule-id-labels" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notificationRules/{ruleID}/labels"
    path_params: [{name: ruleID, var: rule_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    rule_id: $rule_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete label from a notification rule
#
# DELETE /notificationRules/{ruleID}/labels/{labelID}
# operationId: DeleteNotificationRulesIDLabelsID
export def "delete-notification-rules-id-labels-id" [
  rule_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/notificationRules/{ruleID}/labels/{labelID}"
    path_params: [{name: ruleID, var: rule_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    rule_id: $rule_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a notification rule query
#
# GET /notificationRules/{ruleID}/query
# Returns: record<flux: string>
# operationId: GetNotificationRulesIDQuery
export def "get-notification-rules-id-query" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notificationRules/{ruleID}/query"
    path_params: [{name: ruleID, var: rule_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all organizations
#
# GET /orgs
# Returns: record<links: record<next: string, prev: string, self: string>, orgs: table<createdAt: string, description: string, id: string, links: record, name: string, status: string, updatedAt: string>>
# operationId: GetOrgs
export def "get-orgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --descending: oneof<nothing, bool> # default: false
  --org: string # Filter organizations to a specific organization name.
  --org-id: string # Filter organizations to a specific organization ID.
  --user-id: string # Filter organizations to a specific user ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orgs"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: descending, var: descending}, {name: org, var: org}, {name: orgID, var: org_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    offset: $offset, limit: $limit, descending: $descending, org: $org, org_id: $org_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an organization
#
# POST /orgs
# Returns: record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>
# operationId: PostOrgs
export def "post-orgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an organization
#
# DELETE /orgs/{orgID}
# operationId: DeleteOrgsID
export def "delete-orgs-id" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/orgs/{orgID}"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an organization
#
# GET /orgs/{orgID}
# Returns: record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>
# operationId: GetOrgsID
export def "get-orgs-id" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{orgID}"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an organization
#
# PATCH /orgs/{orgID}
# Returns: record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>
# operationId: PatchOrgsID
export def "patch-orgs-id" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # New description to set on the organization
  --name: string # New name to set on the organization
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/orgs/{orgID}"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all members of an organization
#
# GET /orgs/{orgID}/members
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetOrgsIDMembers
export def "get-orgs-id-members" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{orgID}/members"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a member to an organization
#
# POST /orgs/{orgID}/members
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostOrgsIDMembers
export def "post-orgs-id-members" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs/{orgID}/members"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a member from an organization
#
# DELETE /orgs/{orgID}/members/{userID}
# operationId: DeleteOrgsIDMembersID
export def "delete-orgs-id-members-id" [
  org_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/orgs/{orgID}/members/{userID}"
    path_params: [{name: orgID, var: org_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org_id: $org_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all owners of an organization
#
# GET /orgs/{orgID}/owners
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetOrgsIDOwners
export def "get-orgs-id-owners" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{orgID}/owners"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an owner to an organization
#
# POST /orgs/{orgID}/owners
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostOrgsIDOwners
export def "post-orgs-id-owners" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs/{orgID}/owners"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an owner from an organization
#
# DELETE /orgs/{orgID}/owners/{userID}
# operationId: DeleteOrgsIDOwnersID
export def "delete-orgs-id-owners-id" [
  org_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/orgs/{orgID}/owners/{userID}"
    path_params: [{name: orgID, var: org_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org_id: $org_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all secret keys for an organization
#
# GET /orgs/{orgID}/secrets
# Returns: record<secrets: list<string>, links: record<org: string, self: string>>
# operationId: GetOrgsIDSecrets
export def "get-orgs-id-secrets" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{orgID}/secrets"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update secrets in an organization
#
# PATCH /orgs/{orgID}/secrets
# operationId: PatchOrgsIDSecrets
export def "patch-orgs-id-secrets" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/orgs/{orgID}/secrets"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete secrets from an organization
#
# POST /orgs/{orgID}/secrets/delete
# operationId: PostOrgsIDSecrets
export def "post-orgs-id-secrets" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --secrets: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/orgs/{orgID}/secrets/delete"
    path_params: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: secrets, var: secrets}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span, secrets: $secrets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query InfluxDB
#
# POST /query
# Returns: binary
# operationId: PostQuery
export def "post-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --org: string # Specifies the name of the organization executing the query. Takes either the ID or Name interchangeably. If both `orgID` and `org` are specified, `org` takes precedence.
  --org-id: string # Specifies the ID of the organization executing the query. If both `orgID` and `org` are specified, `org` takes precedence.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --accept-encoding: string@accept-encoding-completer # The Accept-Encoding request HTTP header advertises which content encoding, usually a compression algorithm, the client is able to understand. (default: identity)
  --content-type: string@content-type-completer
  --dialect: record # Dialect are options to change the default CSV output format; https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions — shape: {annotations?: list<string>, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano", delimiter?: string, header?: bool}
  --extern: record # Represents a source from a single file — shape: {body?: list, imports?: list, name?: string, package?: record, type?: string}
  --now: string # Specifies the time that should be reported as "now" in the query. Default is the server's now time. (format: date-time)
  --params: record # Enumeration of key/value pairs that respresent parameters to be injected into query (can only specify either this field or extern and not both)
  query: string # Query script to execute.
  --type: string@type-completer # The type of query. Must be "flux".
  --bucket: string # Bucket is to be used instead of the database and retention policy specified in the InfluxQL query.
]: any -> any {
  $in | http-request {
    method: post
    path: "/query"
    query: [{name: org, var: org}, {name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}, {name: Accept-Encoding, var: accept_encoding}, {name: Content-Type, var: content_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dialect, var: dialect}, {name: extern, var: extern}, {name: now, var: now}, {name: params, var: params}, {name: query, var: query}, {name: type, var: type}, {name: bucket, var: bucket}]}
    accept: ["application/vnd.influx.arrow", "text/csv", "application/json"]
    ok: [200]
    auth: basic
  } {
    org: $org, org_id: $org_id, zap_trace_span: $zap_trace_span, accept_encoding: $accept_encoding, content_type: $content_type, dialect: $dialect, extern: $extern, now: $now, params: $params, query: $query, type: $type, bucket: $bucket
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Analyze an InfluxQL or Flux query
#
# POST /query/analyze
# Returns: record<errors: table<character: int, column: int, line: int, message: string>>
# operationId: PostQueryAnalyze
export def "post-query-analyze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content-type: string@content-type-completer-1
  --dialect: record # Dialect are options to change the default CSV output format; https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions — shape: {annotations?: list<string>, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano", delimiter?: string, header?: bool}
  --extern: record # Represents a source from a single file — shape: {body?: list, imports?: list, name?: string, package?: record, type?: string}
  --now: string # Specifies the time that should be reported as "now" in the query. Default is the server's now time. (format: date-time)
  --params: record # Enumeration of key/value pairs that respresent parameters to be injected into query (can only specify either this field or extern and not both)
  query: string # Query script to execute.
  --type: string@type-completer # The type of query. Must be "flux".
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/query/analyze"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}, {name: Content-Type, var: content_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dialect, var: dialect}, {name: extern, var: extern}, {name: now, var: now}, {name: params, var: params}, {name: query, var: query}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, content_type: $content_type, dialect: $dialect, extern: $extern, now: $now, params: $params, query: $query, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an Abstract Syntax Tree (AST) from a query
#
# POST /query/ast
# Returns: record<ast: record<files: list<record>, package: string, path: string, type: string>>
# operationId: PostQueryAst
export def "post-query-ast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content-type: string@content-type-completer-1
  query: string # Flux query script to be analyzed
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/query/ast"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}, {name: Content-Type, var: content_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, content_type: $content_type, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve query suggestions
#
# GET /query/suggestions
# Returns: record<funcs: table<name: string, params: record>>
# operationId: GetQuerySuggestions
export def "get-query-suggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/suggestions"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve query suggestions for a branching suggestion
#
# GET /query/suggestions/{name}
# Returns: record<name: string, params: record>
# operationId: GetQuerySuggestionsName
export def "get-query-suggestions-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/suggestions/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    name: $name, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the readiness of an instance at startup
#
# GET /ready
# Returns: record<started: string, status: string, up: string>
# operationId: GetReady
export def "get-ready" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ready"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all scraper targets
#
# GET /scrapers
# Returns: record<configurations: table<allowInsecure: bool, bucketID: string, name: string, orgID: string, type: string, url: string, bucket: string, id: string, links: record, org: string>>
# operationId: GetScrapers
export def "get-scrapers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Specifies the name of the scraper target.
  --id: list<string> # List of scraper target IDs to return. If both `id` and `owner` are specified, only `id` is used.
  --org-id: string # Specifies the organization ID of the scraper target.
  --org: string # Specifies the organization name of the scraper target.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scrapers"
    query: [{name: name, var: name}, {name: id, var: id, style: multi}, {name: orgID, var: org_id}, {name: org, var: org}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    name: $name, id: $id, org_id: $org_id, org: $org, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a scraper target
#
# POST /scrapers
# Returns: record<allowInsecure: bool, bucketID: string, name: string, orgID: string, type: string, url: string, bucket: string, id: string, links: record<bucket: string, members: string, organization: string, owners: string, self: string>, org: string>
# operationId: PostScrapers
export def "post-scrapers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --allow-insecure: oneof<nothing, bool> # Skip TLS verification on endpoint. (default: false)
  --bucket-id: string # The ID of the bucket to write to.
  --name: string # The name of the scraper target.
  --org-id: string # The organization ID.
  --type: string@type-completer-1 # The type of the metrics to be parsed.
  --url: string # The URL of the metrics endpoint. (e.g. http://localhost:9090/metrics)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scrapers"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowInsecure, var: allow_insecure}, {name: bucketID, var: bucket_id}, {name: name, var: name}, {name: orgID, var: org_id}, {name: type, var: type}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, allow_insecure: $allow_insecure, bucket_id: $bucket_id, name: $name, org_id: $org_id, type: $type, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a scraper target
#
# DELETE /scrapers/{scraperTargetID}
# operationId: DeleteScrapersID
export def "delete-scrapers-id" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/scrapers/{scraperTargetID}"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a scraper target
#
# GET /scrapers/{scraperTargetID}
# Returns: record<allowInsecure: bool, bucketID: string, name: string, orgID: string, type: string, url: string, bucket: string, id: string, links: record<bucket: string, members: string, organization: string, owners: string, self: string>, org: string>
# operationId: GetScrapersID
export def "get-scrapers-id" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scrapers/{scraperTargetID}"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a scraper target
#
# PATCH /scrapers/{scraperTargetID}
# Returns: record<allowInsecure: bool, bucketID: string, name: string, orgID: string, type: string, url: string, bucket: string, id: string, links: record<bucket: string, members: string, organization: string, owners: string, self: string>, org: string>
# operationId: PatchScrapersID
export def "patch-scrapers-id" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --allow-insecure: oneof<nothing, bool> # Skip TLS verification on endpoint. (default: false)
  --bucket-id: string # The ID of the bucket to write to.
  --name: string # The name of the scraper target.
  --org-id: string # The organization ID.
  --type: string@type-completer-1 # The type of the metrics to be parsed.
  --url: string # The URL of the metrics endpoint. (e.g. http://localhost:9090/metrics)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/scrapers/{scraperTargetID}"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowInsecure, var: allow_insecure}, {name: bucketID, var: bucket_id}, {name: name, var: name}, {name: orgID, var: org_id}, {name: type, var: type}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span, allow_insecure: $allow_insecure, bucket_id: $bucket_id, name: $name, org_id: $org_id, type: $type, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a scraper target
#
# GET /scrapers/{scraperTargetID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetScrapersIDLabels
export def "get-scrapers-id-labels" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scrapers/{scraperTargetID}/labels"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a scraper target
#
# POST /scrapers/{scraperTargetID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostScrapersIDLabels
export def "post-scrapers-id-labels" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scrapers/{scraperTargetID}/labels"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/labels/{labelID}
# operationId: DeleteScrapersIDLabelsID
export def "delete-scrapers-id-labels-id" [
  scraper_target_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/scrapers/{scraperTargetID}/labels/{labelID}"
    path_params: [{name: scraperTargetID, var: scraper_target_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all users with member privileges for a scraper target
#
# GET /scrapers/{scraperTargetID}/members
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetScrapersIDMembers
export def "get-scrapers-id-members" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scrapers/{scraperTargetID}/members"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a member to a scraper target
#
# POST /scrapers/{scraperTargetID}/members
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostScrapersIDMembers
export def "post-scrapers-id-members" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scrapers/{scraperTargetID}/members"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a member from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/members/{userID}
# operationId: DeleteScrapersIDMembersID
export def "delete-scrapers-id-members-id" [
  scraper_target_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/scrapers/{scraperTargetID}/members/{userID}"
    path_params: [{name: scraperTargetID, var: scraper_target_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all owners of a scraper target
#
# GET /scrapers/{scraperTargetID}/owners
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetScrapersIDOwners
export def "get-scrapers-id-owners" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scrapers/{scraperTargetID}/owners"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an owner to a scraper target
#
# POST /scrapers/{scraperTargetID}/owners
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostScrapersIDOwners
export def "post-scrapers-id-owners" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scrapers/{scraperTargetID}/owners"
    path_params: [{name: scraperTargetID, var: scraper_target_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an owner from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/owners/{userID}
# operationId: DeleteScrapersIDOwnersID
export def "delete-scrapers-id-owners-id" [
  scraper_target_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/scrapers/{scraperTargetID}/owners/{userID}"
    path_params: [{name: scraperTargetID, var: scraper_target_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    scraper_target_id: $scraper_target_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if database has default user, org, bucket
#
# GET /setup
# Returns: record<allowed: bool>
# operationId: GetSetup
export def "get-setup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set up initial user, org and bucket
#
# POST /setup
# Returns: record<auth: record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: list<record>, token: string, updatedAt: string, user: string, userID: string>, bucket: record<createdAt: string, description: string, id: string, labels: list<record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: list<record>, rp: string, schemaType: string, type: string, updatedAt: string>, org: record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>, user: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>>
# operationId: PostSetup
@deprecated --flag retention-period-hrs
export def "post-setup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  bucket: string
  org: string
  --password: string
  --retention-period-hrs: int # Retention period *in nanoseconds* for the new bucket. This key's name has been misleading since OSS 2.0 GA, please transition to use `retentionPeriodSeconds` (DEPRECATED)
  --retention-period-seconds: int # format: int64
  --body-token: string # Authentication token to set on the initial user. If not specified, the server will generate a token. (spec name: token)
  username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: bucket}, {name: org, var: org}, {name: password, var: password}, {name: retentionPeriodHrs, var: retention_period_hrs}, {name: retentionPeriodSeconds, var: retention_period_seconds}, {name: token, var: body_token}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, bucket: $bucket, org: $org, password: $password, retention_period_hrs: $retention_period_hrs, retention_period_seconds: $retention_period_seconds, body_token: $body_token, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange basic auth credentials for session
#
# POST /signin
# operationId: PostSignin
export def "post-signin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: post
    path: "/signin"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Expire the current session
#
# POST /signout
# operationId: PostSignout
export def "post-signout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: post
    path: "/signout"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all sources
#
# GET /sources
# Returns: record<links: record<self: string>, sources: table<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list, links: record, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>>
# operationId: GetSources
export def "get-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sources"
    query: [{name: org, var: org}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org: $org, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a source
#
# POST /sources
# Returns: record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>
# operationId: PostSources
export def "post-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --default: oneof<nothing, bool>
  --default-rp: string
  --id: string
  --insecure-skip-verify: oneof<nothing, bool>
  --links: record # shape: {buckets?: string, health?: string, query?: string, self?: string}
  --meta-url: string # format: uri
  --name: string
  --org-id: string
  --password: string
  --shared-secret: string
  --telegraf: string
  --body-token: string # (spec name: token)
  --type: string@type-completer-2
  --url: string # format: uri
  --username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sources"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: defaultRP, var: default_rp}, {name: id, var: id}, {name: insecureSkipVerify, var: insecure_skip_verify}, {name: links, var: links}, {name: metaUrl, var: meta_url}, {name: name, var: name}, {name: orgID, var: org_id}, {name: password, var: password}, {name: sharedSecret, var: shared_secret}, {name: telegraf, var: telegraf}, {name: token, var: body_token}, {name: type, var: type}, {name: url, var: url}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, default: $default, default_rp: $default_rp, id: $id, insecure_skip_verify: $insecure_skip_verify, links: $links, meta_url: $meta_url, name: $name, org_id: $org_id, password: $password, shared_secret: $shared_secret, telegraf: $telegraf, body_token: $body_token, type: $type, url: $url, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a source
#
# DELETE /sources/{sourceID}
# operationId: DeleteSourcesID
export def "delete-sources-id" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/sources/{sourceID}"
    path_params: [{name: sourceID, var: source_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    source_id: $source_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a source
#
# GET /sources/{sourceID}
# Returns: record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>
# operationId: GetSourcesID
export def "get-sources-id" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sources/{sourceID}"
    path_params: [{name: sourceID, var: source_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    source_id: $source_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Source
#
# PATCH /sources/{sourceID}
# Returns: record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>
# operationId: PatchSourcesID
export def "patch-sources-id" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --default: oneof<nothing, bool>
  --default-rp: string
  --id: string
  --insecure-skip-verify: oneof<nothing, bool>
  --links: record # shape: {buckets?: string, health?: string, query?: string, self?: string}
  --meta-url: string # format: uri
  --name: string
  --org-id: string
  --password: string
  --shared-secret: string
  --telegraf: string
  --body-token: string # (spec name: token)
  --type: string@type-completer-2
  --url: string # format: uri
  --username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sources/{sourceID}"
    path_params: [{name: sourceID, var: source_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: defaultRP, var: default_rp}, {name: id, var: id}, {name: insecureSkipVerify, var: insecure_skip_verify}, {name: links, var: links}, {name: metaUrl, var: meta_url}, {name: name, var: name}, {name: orgID, var: org_id}, {name: password, var: password}, {name: sharedSecret, var: shared_secret}, {name: telegraf, var: telegraf}, {name: token, var: body_token}, {name: type, var: type}, {name: url, var: url}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    source_id: $source_id, zap_trace_span: $zap_trace_span, default: $default, default_rp: $default_rp, id: $id, insecure_skip_verify: $insecure_skip_verify, links: $links, meta_url: $meta_url, name: $name, org_id: $org_id, password: $password, shared_secret: $shared_secret, telegraf: $telegraf, body_token: $body_token, type: $type, url: $url, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get buckets in a source
#
# GET /sources/{sourceID}/buckets
# Returns: record<buckets: table<createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, retentionRules: list, rp: string, schemaType: string, type: string, updatedAt: string>, links: record<next: string, prev: string, self: string>>
# operationId: GetSourcesIDBuckets
export def "get-sources-id-buckets" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sources/{sourceID}/buckets"
    path_params: [{name: sourceID, var: source_id}]
    query: [{name: org, var: org}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    source_id: $source_id, org: $org, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the health of a source
#
# GET /sources/{sourceID}/health
# Returns: record<checks: list<any>, commit: string, message: string, name: string, status: string, version: string>
# operationId: GetSourcesIDHealth
export def "get-sources-id-health" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sources/{sourceID}/health"
    path_params: [{name: sourceID, var: source_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    source_id: $source_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all installed InfluxDB templates
#
# GET /stacks
# Returns: record<stacks: table<createdAt: string, events: list, id: string, orgID: string>>
# operationId: ListStacks
export def "list-stacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The organization id of the stacks (required)
  --name: string # A collection of names to filter the list by.
  --stack-id: string # A collection of stackIDs to filter the list by.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stacks"
    query: [{name: orgID, var: org_id, required: true}, {name: name, var: name}, {name: stackID, var: stack_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, name: $name, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new stack
#
# POST /stacks
# Returns: record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string>
# operationId: CreateStack
export def "create-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --name: string
  --org-id: string
  --urls: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stacks"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: orgID, var: org_id}, {name: urls, var: urls}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    description: $description, name: $name, org_id: $org_id, urls: $urls
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a stack and associated resources
#
# DELETE /stacks/{stack_id}
# operationId: DeleteStack
export def "delete-stack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The identifier of the organization. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/stacks/{stack_id}"
    path_params: [{name: stack_id, var: stack_id}]
    query: [{name: orgID, var: org_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    stack_id: $stack_id, org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a stack
#
# GET /stacks/{stack_id}
# Returns: record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string>
# operationId: ReadStack
export def "read-stack" [
  stack_id: string
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
    path: "/stacks/{stack_id}"
    path_params: [{name: stack_id, var: stack_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an InfluxDB Stack
#
# PATCH /stacks/{stack_id}
# Returns: record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string>
# operationId: UpdateStack
export def "update-stack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-resources: list # item shape: {kind: string, resourceID: string, templateMetaName?: string}
  --description: string # nullable
  --name: string # nullable
  --template-ur-ls: list<string> # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/stacks/{stack_id}"
    path_params: [{name: stack_id, var: stack_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalResources, var: additional_resources}, {name: description, var: description}, {name: name, var: name}, {name: templateURLs, var: template_ur_ls}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    stack_id: $stack_id, additional_resources: $additional_resources, description: $description, name: $name, template_ur_ls: $template_ur_ls
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uninstall an InfluxDB Stack
#
# POST /stacks/{stack_id}/uninstall
# Returns: record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string>
# operationId: UninstallStack
export def "uninstall-stack" [
  stack_id: string
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
    path: "/stacks/{stack_id}/uninstall"
    path_params: [{name: stack_id, var: stack_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all tasks
#
# GET /tasks
# Returns: record<links: record<next: string, prev: string, self: string>, tasks: table<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: list, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>>
# operationId: GetTasks
export def "get-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Returns task with a specific name.
  --after: string # Return tasks after a specified ID.
  --user: string # Filter tasks to a specific user ID.
  --org: string # Filter tasks to a specific organization name.
  --org-id: string # Filter tasks to a specific organization ID.
  --status: string@status-completer # Filter tasks by a status--"inactive" or "active".
  --limit: int # The number of tasks to return (default: 100)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks"
    query: [{name: name, var: name}, {name: after, var: after}, {name: user, var: user}, {name: org, var: org}, {name: orgID, var: org_id}, {name: status, var: status}, {name: limit, var: limit}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    name: $name, after: $after, user: $user, org: $org, org_id: $org_id, status: $status, limit: $limit, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new task
#
# POST /tasks
# Returns: record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>
# operationId: PostTasks
export def "post-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # An optional description of the task.
  flux: string # The Flux script to run for this task.
  --org: string # The name of the organization that owns this Task.
  --org-id: string # The ID of the organization that owns this Task.
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: flux, var: flux}, {name: org, var: org}, {name: orgID, var: org_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, description: $description, flux: $flux, org: $org, org_id: $org_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a task
#
# DELETE /tasks/{taskID}
# operationId: DeleteTasksID
export def "delete-tasks-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/tasks/{taskID}"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a task
#
# GET /tasks/{taskID}
# Returns: record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>
# operationId: GetTasksID
export def "get-tasks-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{taskID}"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a task
#
# PATCH /tasks/{taskID}
# Returns: record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>
# operationId: PatchTasksID
export def "patch-tasks-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --cron: string # Override the 'cron' option in the flux script.
  --description: string # An optional description of the task.
  --every: string # Override the 'every' option in the flux script.
  --flux: string # The Flux script to run for this task.
  --name: string # Override the 'name' option in the flux script.
  --offset: string # Override the 'offset' option in the flux script.
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tasks/{taskID}"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: cron, var: cron}, {name: description, var: description}, {name: every, var: every}, {name: flux, var: flux}, {name: name, var: name}, {name: offset, var: offset}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span, cron: $cron, description: $description, every: $every, flux: $flux, name: $name, offset: $offset, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a task
#
# GET /tasks/{taskID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetTasksIDLabels
export def "get-tasks-id-labels" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{taskID}/labels"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a task
#
# POST /tasks/{taskID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostTasksIDLabels
export def "post-tasks-id-labels" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{taskID}/labels"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label from a task
#
# DELETE /tasks/{taskID}/labels/{labelID}
# operationId: DeleteTasksIDLabelsID
export def "delete-tasks-id-labels-id" [
  task_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/tasks/{taskID}/labels/{labelID}"
    path_params: [{name: taskID, var: task_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    task_id: $task_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all logs for a task
#
# GET /tasks/{taskID}/logs
# Returns: record<events: table<message: string, runID: string, time: string>>
# operationId: GetTasksIDLogs
export def "get-tasks-id-logs" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{taskID}/logs"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all task members
#
# GET /tasks/{taskID}/members
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetTasksIDMembers
export def "get-tasks-id-members" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{taskID}/members"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a member to a task
#
# POST /tasks/{taskID}/members
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostTasksIDMembers
export def "post-tasks-id-members" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{taskID}/members"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a member from a task
#
# DELETE /tasks/{taskID}/members/{userID}
# operationId: DeleteTasksIDMembersID
export def "delete-tasks-id-members-id" [
  task_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/tasks/{taskID}/members/{userID}"
    path_params: [{name: taskID, var: task_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    task_id: $task_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all owners of a task
#
# GET /tasks/{taskID}/owners
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetTasksIDOwners
export def "get-tasks-id-owners" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{taskID}/owners"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an owner to a task
#
# POST /tasks/{taskID}/owners
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostTasksIDOwners
export def "post-tasks-id-owners" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{taskID}/owners"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an owner from a task
#
# DELETE /tasks/{taskID}/owners/{userID}
# operationId: DeleteTasksIDOwnersID
export def "delete-tasks-id-owners-id" [
  task_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/tasks/{taskID}/owners/{userID}"
    path_params: [{name: taskID, var: task_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    task_id: $task_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List runs for a task
#
# GET /tasks/{taskID}/runs
# Returns: record<links: record<next: string, prev: string, self: string>, runs: table<finishedAt: string, id: string, links: record, log: list, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>>
# operationId: GetTasksIDRuns
export def "get-tasks-id-runs" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Returns runs after a specific ID.
  --limit: int # The number of runs to return (default: 100)
  --after-time: string # Filter runs to those scheduled after this time, RFC3339 (format: date-time)
  --before-time: string # Filter runs to those scheduled before this time, RFC3339 (format: date-time)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{taskID}/runs"
    path_params: [{name: taskID, var: task_id}]
    query: [{name: after, var: after}, {name: limit, var: limit}, {name: afterTime, var: after_time}, {name: beforeTime, var: before_time}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, after: $after, limit: $limit, after_time: $after_time, before_time: $before_time, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Manually start a task run, overriding the current schedule
#
# POST /tasks/{taskID}/runs
# Returns: record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>
# operationId: PostTasksIDRuns
export def "post-tasks-id-runs" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --scheduled-for: string # Time used for run's "now" option, RFC3339. Default is the server's now time. (nullable, format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{taskID}/runs"
    path_params: [{name: taskID, var: task_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: scheduledFor, var: scheduled_for}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    task_id: $task_id, zap_trace_span: $zap_trace_span, scheduled_for: $scheduled_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a running task
#
# DELETE /tasks/{taskID}/runs/{runID}
# operationId: DeleteTasksIDRunsID
export def "delete-tasks-id-runs-id" [
  task_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/tasks/{taskID}/runs/{runID}"
    path_params: [{name: taskID, var: task_id}, {name: runID, var: run_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    task_id: $task_id, run_id: $run_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single run for a task
#
# GET /tasks/{taskID}/runs/{runID}
# Returns: record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>
# operationId: GetTasksIDRunsID
export def "get-tasks-id-runs-id" [
  task_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{taskID}/runs/{runID}"
    path_params: [{name: taskID, var: task_id}, {name: runID, var: run_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, run_id: $run_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all logs for a run
#
# GET /tasks/{taskID}/runs/{runID}/logs
# Returns: record<events: table<message: string, runID: string, time: string>>
# operationId: GetTasksIDRunsIDLogs
export def "get-tasks-id-runs-id-logs" [
  task_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{taskID}/runs/{runID}/logs"
    path_params: [{name: taskID, var: task_id}, {name: runID, var: run_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, run_id: $run_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retry a task run
#
# POST /tasks/{taskID}/runs/{runID}/retry
# Returns: record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>
# operationId: PostTasksIDRunsIDRetry
export def "post-tasks-id-runs-id-retry" [
  task_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{taskID}/runs/{runID}/retry"
    path_params: [{name: taskID, var: task_id}, {name: runID, var: run_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json; charset=utf-8", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    task_id: $task_id, run_id: $run_id, zap_trace_span: $zap_trace_span, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Telegraf plugins
#
# GET /telegraf/plugins
# Returns: record<os: string, plugins: table<config: string, description: string, name: string, type: string>, version: string>
# operationId: GetTelegrafPlugins
export def "get-telegraf-plugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type of plugin desired.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/telegraf/plugins"
    query: [{name: type, var: type}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    type: $type, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Telegraf configurations
#
# GET /telegrafs
# Returns: record<configurations: table<config: string, description: string, metadata: record, name: string, orgID: string, id: string, labels: list, links: record>>
# operationId: GetTelegrafs
export def "get-telegrafs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The organization ID the Telegraf config belongs to.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/telegrafs"
    query: [{name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Telegraf configuration
#
# POST /telegrafs
# Returns: record<config: string, description: string, metadata: record<buckets: list<string>>, name: string, orgID: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, owners: string, self: string>>
# operationId: PostTelegrafs
export def "post-telegrafs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --config: string
  --description: string
  --metadata: record # shape: {buckets?: list<string>}
  --name: string
  --org-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/telegrafs"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: description, var: description}, {name: metadata, var: metadata}, {name: name, var: name}, {name: orgID, var: org_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, config: $config, description: $description, metadata: $metadata, name: $name, org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Telegraf configuration
#
# DELETE /telegrafs/{telegrafID}
# operationId: DeleteTelegrafsID
export def "delete-telegrafs-id" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/telegrafs/{telegrafID}"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Telegraf configuration
#
# GET /telegrafs/{telegrafID}
# Returns: record<config: string, description: string, metadata: record<buckets: list<string>>, name: string, orgID: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, owners: string, self: string>>
# operationId: GetTelegrafsID
export def "get-telegrafs-id" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --hdr-accept: string@accept-completer-1 # default: application/toml (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/telegrafs/{telegrafID}"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}, {name: Accept, var: hdr_accept}]
    accept: ["application/json", "application/octet-stream", "application/toml"]
    ok: [200]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Telegraf configuration
#
# PUT /telegrafs/{telegrafID}
# Returns: record<config: string, description: string, metadata: record<buckets: list<string>>, name: string, orgID: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, owners: string, self: string>>
# operationId: PutTelegrafsID
export def "put-telegrafs-id" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --config: string
  --description: string
  --metadata: record # shape: {buckets?: list<string>}
  --name: string
  --org-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/telegrafs/{telegrafID}"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: description, var: description}, {name: metadata, var: metadata}, {name: name, var: name}, {name: orgID, var: org_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span, config: $config, description: $description, metadata: $metadata, name: $name, org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a Telegraf config
#
# GET /telegrafs/{telegrafID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetTelegrafsIDLabels
export def "get-telegrafs-id-labels" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/telegrafs/{telegrafID}/labels"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a Telegraf config
#
# POST /telegrafs/{telegrafID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostTelegrafsIDLabels
export def "post-telegrafs-id-labels" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/telegrafs/{telegrafID}/labels"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/labels/{labelID}
# operationId: DeleteTelegrafsIDLabelsID
export def "delete-telegrafs-id-labels-id" [
  telegraf_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/telegrafs/{telegrafID}/labels/{labelID}"
    path_params: [{name: telegrafID, var: telegraf_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    telegraf_id: $telegraf_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all users with member privileges for a Telegraf config
#
# GET /telegrafs/{telegrafID}/members
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetTelegrafsIDMembers
export def "get-telegrafs-id-members" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/telegrafs/{telegrafID}/members"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a member to a Telegraf config
#
# POST /telegrafs/{telegrafID}/members
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostTelegrafsIDMembers
export def "post-telegrafs-id-members" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/telegrafs/{telegrafID}/members"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a member from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/members/{userID}
# operationId: DeleteTelegrafsIDMembersID
export def "delete-telegrafs-id-members-id" [
  telegraf_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/telegrafs/{telegrafID}/members/{userID}"
    path_params: [{name: telegrafID, var: telegraf_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    telegraf_id: $telegraf_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all owners of a Telegraf configuration
#
# GET /telegrafs/{telegrafID}/owners
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>>
# operationId: GetTelegrafsIDOwners
export def "get-telegrafs-id-owners" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/telegrafs/{telegrafID}/owners"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an owner to a Telegraf configuration
#
# POST /telegrafs/{telegrafID}/owners
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string>
# operationId: PostTelegrafsIDOwners
export def "post-telegrafs-id-owners" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/telegrafs/{telegrafID}/owners"
    path_params: [{name: telegrafID, var: telegraf_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    telegraf_id: $telegraf_id, zap_trace_span: $zap_trace_span, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an owner from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/owners/{userID}
# operationId: DeleteTelegrafsIDOwnersID
export def "delete-telegrafs-id-owners-id" [
  telegraf_id: string
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/telegrafs/{telegrafID}/owners/{userID}"
    path_params: [{name: telegrafID, var: telegraf_id}, {name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    telegraf_id: $telegraf_id, user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply or dry-run an InfluxDB Template
#
# POST /templates/apply
# Returns: record<diff: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labelMappings: list<record>, labels: list<record>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>, errors: table<fields: list, indexes: list, kind: string, reason: string>, sources: list<string>, stackID: string, summary: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labelMappings: list<record>, labels: list<record>, missingEnvRefs: list<string>, missingSecrets: list<string>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>>
# operationId: ApplyTemplate
export def "apply-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list
  --body-dry-run: oneof<nothing, bool> # (spec name: dryRun)
  --env-refs: record
  --org-id: string
  --remotes: list # item shape: {contentType?: string, url: string}
  --secrets: record
  --stack-id: string
  --template: record # shape: {contentType?: string, contents?: list, sources?: list<string>}
  --templates: list # item shape: {contentType?: string, contents?: list, sources?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/apply"
    body: {content_type: "application/json", kind: json, fields: [{name: actions, var: actions}, {name: dryRun, var: body_dry_run}, {name: envRefs, var: env_refs}, {name: orgID, var: org_id}, {name: remotes, var: remotes}, {name: secrets, var: secrets}, {name: stackID, var: stack_id}, {name: template, var: template}, {name: templates, var: templates}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    actions: $actions, body_dry_run: $body_dry_run, env_refs: $env_refs, org_id: $org_id, remotes: $remotes, secrets: $secrets, stack_id: $stack_id, template: $template, templates: $templates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export a new Influx Template
#
# POST /templates/export
# Returns: table<apiVersion: string, kind: string, meta: record<name: string>, spec: record>
# operationId: ExportTemplate
export def "export-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --org-i-ds: list # item shape: {orgID?: string, resourceFilters?: record}
  --resources: record # shape: {id: string, kind: "Bucket"|"Check"|"CheckDeadman"|"CheckThreshold"|"Dashboard"|"Label"|"NotificationEndpoint"|"NotificationEndpointHTTP"|"NotificationEndpointPagerDuty"|"NotificationEndpointSlack"|"NotificationRule"|"Task"|"Telegraf"|"Variable", name?: string}
  --stack-id: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/export"
    body: {content_type: "application/json", kind: json, fields: [{name: orgIDs, var: org_i_ds}, {name: resources, var: resources}, {name: stackID, var: stack_id}]}
    accept: ["application/json", "application/x-yaml"]
    ok: [200]
    auth: basic
  } {
    org_i_ds: $org_i_ds, resources: $resources, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all users
#
# GET /users
# Returns: record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string>>
# operationId: GetUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --after: string # The last resource ID from which to seek from (but not including). This is to be used instead of `offset`.
  --name: string
  --id: string
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: after, var: after}, {name: name, var: name}, {name: id, var: id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    offset: $offset, limit: $limit, after: $after, name: $name, id: $id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a user
#
# POST /users
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>
# operationId: PostUsers
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  --oauth-id: string
  --status: string@status-completer # If inactive the user is inactive. (default: active)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: oauthID, var: oauth_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, name: $name, oauth_id: $oauth_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user
#
# DELETE /users/{userID}
# operationId: DeleteUsersID
export def "delete-users-id" [
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{userID}"
    path_params: [{name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a user
#
# GET /users/{userID}
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>
# operationId: GetUsersID
export def "get-users-id" [
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userID}"
    path_params: [{name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    user_id: $user_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user
#
# PATCH /users/{userID}
# Returns: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>
# operationId: PatchUsersID
export def "patch-users-id" [
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  --oauth-id: string
  --status: string@status-completer # If inactive the user is inactive. (default: active)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{userID}"
    path_params: [{name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: oauthID, var: oauth_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    user_id: $user_id, zap_trace_span: $zap_trace_span, name: $name, oauth_id: $oauth_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a password
#
# POST /users/{userID}/password
# operationId: PostUsersIDPassword
export def "post-users-id-password" [
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  password: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{userID}/password"
    path_params: [{name: userID, var: user_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    user_id: $user_id, zap_trace_span: $zap_trace_span, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all variables
#
# GET /variables
# Returns: record<variables: table<arguments: record, createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, selected: list, updatedAt: string>>
# operationId: GetVariables
export def "get-variables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --org-id: string # The organization ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/variables"
    query: [{name: org, var: org}, {name: orgID, var: org_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org: $org, org_id: $org_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a variable
#
# POST /variables
# Returns: record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string>
# operationId: PostVariables
export def "post-variables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --created-at: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  org_id: string
  --selected: list<string>
  --updated-at: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/variables"
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: arguments, var: arguments}, {name: createdAt, var: created_at}, {name: description, var: description}, {name: labels, var: labels}, {name: name, var: name}, {name: orgID, var: org_id}, {name: selected, var: selected}, {name: updatedAt, var: updated_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    zap_trace_span: $zap_trace_span, arguments: $arguments, created_at: $created_at, description: $description, labels: $labels, name: $name, org_id: $org_id, selected: $selected, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a variable
#
# DELETE /variables/{variableID}
# operationId: DeleteVariablesID
export def "delete-variables-id" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/variables/{variableID}"
    path_params: [{name: variableID, var: variable_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    variable_id: $variable_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a variable
#
# GET /variables/{variableID}
# Returns: record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string>
# operationId: GetVariablesID
export def "get-variables-id" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/variables/{variableID}"
    path_params: [{name: variableID, var: variable_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    variable_id: $variable_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a variable
#
# PATCH /variables/{variableID}
# Returns: record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string>
# operationId: PatchVariablesID
export def "patch-variables-id" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --created-at: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  org_id: string
  --selected: list<string>
  --updated-at: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/variables/{variableID}"
    path_params: [{name: variableID, var: variable_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: arguments, var: arguments}, {name: createdAt, var: created_at}, {name: description, var: description}, {name: labels, var: labels}, {name: name, var: name}, {name: orgID, var: org_id}, {name: selected, var: selected}, {name: updatedAt, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    variable_id: $variable_id, zap_trace_span: $zap_trace_span, arguments: $arguments, created_at: $created_at, description: $description, labels: $labels, name: $name, org_id: $org_id, selected: $selected, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace a variable
#
# PUT /variables/{variableID}
# Returns: record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string>
# operationId: PutVariablesID
export def "put-variables-id" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --created-at: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  org_id: string
  --selected: list<string>
  --updated-at: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/variables/{variableID}"
    path_params: [{name: variableID, var: variable_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: arguments, var: arguments}, {name: createdAt, var: created_at}, {name: description, var: description}, {name: labels, var: labels}, {name: name, var: name}, {name: orgID, var: org_id}, {name: selected, var: selected}, {name: updatedAt, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    variable_id: $variable_id, zap_trace_span: $zap_trace_span, arguments: $arguments, created_at: $created_at, description: $description, labels: $labels, name: $name, org_id: $org_id, selected: $selected, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all labels for a variable
#
# GET /variables/{variableID}/labels
# Returns: record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: GetVariablesIDLabels
export def "get-variables-id-labels" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/variables/{variableID}/labels"
    path_params: [{name: variableID, var: variable_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    variable_id: $variable_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a label to a variable
#
# POST /variables/{variableID}/labels
# Returns: record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>>
# operationId: PostVariablesIDLabels
export def "post-variables-id-labels" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/variables/{variableID}/labels"
    path_params: [{name: variableID, var: variable_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelID, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    variable_id: $variable_id, zap_trace_span: $zap_trace_span, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a label from a variable
#
# DELETE /variables/{variableID}/labels/{labelID}
# operationId: DeleteVariablesIDLabelsID
export def "delete-variables-id-labels-id" [
  variable_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  http-request {
    method: delete
    path: "/variables/{variableID}/labels/{labelID}"
    path_params: [{name: variableID, var: variable_id}, {name: labelID, var: label_id}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    variable_id: $variable_id, label_id: $label_id, zap_trace_span: $zap_trace_span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Write time series data into InfluxDB
#
# POST /write
# operationId: PostWrite
export def "post-write" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # Specifies the destination organization for writes. Takes either the ID or Name interchangeably. If both `orgID` and `org` are specified, `org` takes precedence. (required)
  --org-id: string # Specifies the ID of the destination organization for writes. If both `orgID` and `org` are specified, `org` takes precedence.
  --bucket: string # The destination bucket for writes. (required)
  --precision: string@precision-completer # The precision for the unix timestamps within the body line-protocol.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content-encoding: string@content-encoding-completer # When present, its value indicates to the database that compression is applied to the line-protocol body. (default: identity)
  --content-type: string@content-type-completer-2 # Content-Type is used to indicate the format of the data sent to the server. (default: text/plain; charset=utf-8)
  --content-length: int # Content-Length is an entity header is indicating the size of the entity-body, in bytes, sent to the database. If the length is greater than the database max body configuration option, a 413 response is sent.
  --hdr-accept: string@accept-completer-3 # Specifies the return content format. (default: application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/write"
    query: [{name: org, var: org, required: true}, {name: orgID, var: org_id}, {name: bucket, var: bucket, required: true}, {name: precision, var: precision}]
    header: [{name: Zap-Trace-Span, var: zap_trace_span}, {name: Content-Encoding, var: content_encoding}, {name: Content-Type, var: content_type}, {name: Content-Length, var: content_length}, {name: Accept, var: hdr_accept}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org, org_id: $org_id, bucket: $bucket, precision: $precision, zap_trace_span: $zap_trace_span, content_encoding: $content_encoding, content_type: $content_type, content_length: $content_length, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
