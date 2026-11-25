# Auto-generated client for Adafruit IO REST API v2.0.0
# Source: https://api.apis.guru/v2/specs/adafruit.com/2.0.0/swagger.json
# Auth: --token flag or $env.ADAFRUIT_IO_REST_API_TOKEN

const CLIENT = {
  base_url: "https://io.adafruit.com/api/v2"
  token_env_var: "ADAFRUIT_IO_REST_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-aio-key, in: header, header_name: X-AIO-Key, prefix: ""}
    {name: x-aio-signature, in: header, header_name: X-AIO-Signature, prefix: ""}
    {name: query-X-AIO-Key, in: query, header_name: X-AIO-Key, prefix: ""}
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

def base-url-completer [] { ["https://io.adafruit.com/api/v2" "http://io.adafruit.com/api/v2"] }
def auth-scheme-completer [] { ["x-aio-key" "x-aio-signature" "query-X-AIO-Key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/csv"] }
def mode-completer [] { ["r" "rw" "w"] }
def scope-completer [] { ["organization" "public" "secret" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    current-user: "record<color: string, created_at: string, id: float, name: string, time_zone: string, updated_at: string, username: string>"
    create-webhook-feed-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    create-raw-webhook-feed-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    all-activities: "table<action: string, created_at: string, data: record, id: float, model: string, updated_at: string, user_id: float>"
    get-activity: "table<action: string, created_at: string, data: record, id: float, model: string, updated_at: string, user_id: float>"
    all-dashboards: "table<blocks: list<record>, description: string, key: string, name: string>"
    create-dashboard: "record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string>"
    all-blocks: "table<block_feeds: list<record>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>"
    create-block: "record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>"
    destroy-block: "string"
    get-block: "record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>"
    update-block: "record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>"
    replace-block: "record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>"
    destroy-dashboard: "string"
    get-dashboard: "record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string>"
    update-dashboard: "record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string>"
    replace-dashboard: "record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string>"
    all-feeds: "table<created_at: string, description: string, details: record<data: record, shared_with: list>, enabled: bool, group: record, groups: list<record>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>"
    create-feed: "record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>"
    get-feed: "record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>"
    update-feed: "record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>"
    replace-feed: "record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>"
    all-data: "table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    create-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    batch-create-data: "table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    chart-data: "record<columns: list<string>, data: list<list<string>>, feed: record<id: int, key: string, name: string>, parameters: record>"
    first-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    last-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    next-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    previous-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    retain-data: "string"
    destroy-data: "string"
    get-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    update-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    replace-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    get-feed-details: "record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>"
    all-groups: "table<created_at: string, description: string, feeds: list<record>, id: float, name: string, updated_at: string>"
    create-group: "record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>"
    destroy-group: "string"
    get-group: "record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>"
    update-group: "record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>"
    replace-group: "record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>"
    add-feed-to-group: "record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>"
    create-group-data: "table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    all-group-feeds: "table<created_at: string, description: string, details: record<data: record, shared_with: list>, enabled: bool, group: record, groups: list<record>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>"
    create-group-feed: "record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>"
    all-group-feed-data: "table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    create-group-feed-data: "record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    batch-create-group-feed-data: "table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>"
    remove-feed-from-group: "record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>"
    get-current-user-throttle: "record<active_data_rate: int, data_rate_limit: int>"
    all-tokens: "table<token: string>"
    create-token: "record<token: string>"
    destroy-token: "string"
    get-token: "record<token: string>"
    update-token: "record<token: string>"
    replace-token: "record<token: string>"
    all-triggers: "table<name: string>"
    create-trigger: "record<name: string>"
    destroy-trigger: "string"
    get-trigger: "record<name: string>"
    update-trigger: "record<name: string>"
    replace-trigger: "record<name: string>"
    all-permissions: "table<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>"
    create-permission: "record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>"
    destroy-permission: "string"
    get-permission: "record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>"
    update-permission: "record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>"
    replace-permission: "record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["current-user" "create-webhook-feed-data" "create-raw-webhook-feed-data" "destroy-activities" "all-activities" "get-activity" "all-dashboards" "create-dashboard" "all-blocks" "create-block" "destroy-block" "get-block" "update-block" "replace-block" "destroy-dashboard" "get-dashboard" "update-dashboard" "replace-dashboard" "all-feeds" "create-feed" "destroy-feed" "get-feed" "update-feed" "replace-feed" "all-data" "create-data" "batch-create-data" "chart-data" "first-data" "last-data" "next-data" "previous-data" "retain-data" "destroy-data" "get-data" "update-data" "replace-data" "get-feed-details" "all-groups" "create-group" "destroy-group" "get-group" "update-group" "replace-group" "add-feed-to-group" "create-group-data" "all-group-feeds" "create-group-feed" "all-group-feed-data" "create-group-feed-data" "batch-create-group-feed-data" "remove-feed-from-group" "get-current-user-throttle" "all-tokens" "create-token" "destroy-token" "get-token" "update-token" "replace-token" "all-triggers" "create-trigger" "destroy-trigger" "get-trigger" "update-trigger" "replace-trigger" "all-permissions" "create-permission" "destroy-permission" "get-permission" "update-permission" "replace-permission" "commands"] | sort) } | get name | first)
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

# Get information about the current user
#
# GET /user
# Returns: record<color: string, created_at: string, id: float, name: string, time_zone: string, updated_at: string, username: string>
# operationId: currentUser
export def "current-user" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user"
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send data to a feed via webhook URL.
#
# POST /webhooks/feed/:token
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: createWebhookFeedData
export def "create-webhook-feed-data" [
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
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/feed/:token"
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send arbitrary data to a feed via webhook URL.
#
# POST /webhooks/feed/:token/raw
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: createRawWebhookFeedData
export def "create-raw-webhook-feed-data" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/webhooks/feed/:token/raw"
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All activities for current user
#
# DELETE /{username}/activities
# operationId: destroyActivities
export def "destroy-activities" [
  username: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/activities"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All activities for current user
#
# GET /{username}/activities
# Returns: table<action: string, created_at: string, data: record, id: float, model: string, updated_at: string, user_id: float>
# operationId: allActivities
export def "all-activities" [
  username: string
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
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/activities"
    path_params: [{name: username, var: username}]
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: limit, var: limit}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, start_time: $start_time, end_time: $end_time, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get activities by type for current user
#
# GET /{username}/activities/{type}
# Returns: table<action: string, created_at: string, data: record, id: float, model: string, updated_at: string, user_id: float>
# operationId: getActivity
export def "get-activity" [
  username: string
  type: string
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
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/activities/{type}"
    path_params: [{name: username, var: username}, {name: type, var: type}]
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: limit, var: limit}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, type: $type, start_time: $start_time, end_time: $end_time, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All dashboards for current user
#
# GET /{username}/dashboards
# Returns: table<blocks: list<record>, description: string, key: string, name: string>
# operationId: allDashboards
export def "all-dashboards" [
  username: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/dashboards"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Dashboard
#
# POST /{username}/dashboards
# Returns: record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string>
# operationId: createDashboard
export def "create-dashboard" [
  username: string
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
  --description: string
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/dashboards"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, description: $description, key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All blocks for current user
#
# GET /{username}/dashboards/{dashboard_id}/blocks
# Returns: table<block_feeds: list<record>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>
# operationId: allBlocks
export def "all-blocks" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/dashboards/{dashboard_id}/blocks"
    path_params: [{name: username, var: username}, {name: dashboard_id, var: dashboard_id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, dashboard_id: $dashboard_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Block
#
# POST /{username}/dashboards/{dashboard_id}/blocks
# Returns: record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>
# operationId: createBlock
export def "create-block" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --block-feeds: list # item shape: {feed_id?: string, group_id?: string}
  --column: float
  --body-dashboard-id: float # (spec name: dashboard_id)
  --description: string
  --key: string
  --name: string
  --properties: record
  --row: float
  --size-x: float
  --size-y: float
  --visual-type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/dashboards/{dashboard_id}/blocks"
    path_params: [{name: username, var: username}, {name: dashboard_id, var: dashboard_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: block_feeds, var: block_feeds}, {name: column, var: column}, {name: dashboard_id, var: body_dashboard_id}, {name: description, var: description}, {name: key, var: key}, {name: name, var: name}, {name: properties, var: properties}, {name: row, var: row}, {name: size_x, var: size_x}, {name: size_y, var: size_y}, {name: visual_type, var: visual_type}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, dashboard_id: $dashboard_id, block_feeds: $block_feeds, column: $column, body_dashboard_id: $body_dashboard_id, description: $description, key: $key, name: $name, properties: $properties, row: $row, size_x: $size_x, size_y: $size_y, visual_type: $visual_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing Block
#
# DELETE /{username}/dashboards/{dashboard_id}/blocks/{id}
# Returns: string
# operationId: destroyBlock
export def "destroy-block" [
  username: string
  dashboard_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/dashboards/{dashboard_id}/blocks/{id}"
    path_params: [{name: username, var: username}, {name: dashboard_id, var: dashboard_id}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, dashboard_id: $dashboard_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Block based on ID
#
# GET /{username}/dashboards/{dashboard_id}/blocks/{id}
# Returns: record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>
# operationId: getBlock
export def "get-block" [
  username: string
  dashboard_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/dashboards/{dashboard_id}/blocks/{id}"
    path_params: [{name: username, var: username}, {name: dashboard_id, var: dashboard_id}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, dashboard_id: $dashboard_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update properties of an existing Block
#
# PATCH /{username}/dashboards/{dashboard_id}/blocks/{id}
# Returns: record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>
# operationId: updateBlock
export def "update-block" [
  username: string
  dashboard_id: string
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
  --accept: string@accept-completer # Response content type
  --block-feeds: list # item shape: {feed_id?: string, group_id?: string}
  --column: float
  --body-dashboard-id: float # (spec name: dashboard_id)
  --description: string
  --key: string
  --name: string
  --properties: record
  --row: float
  --size-x: float
  --size-y: float
  --visual-type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{username}/dashboards/{dashboard_id}/blocks/{id}"
    path_params: [{name: username, var: username}, {name: dashboard_id, var: dashboard_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: block_feeds, var: block_feeds}, {name: column, var: column}, {name: dashboard_id, var: body_dashboard_id}, {name: description, var: description}, {name: key, var: key}, {name: name, var: name}, {name: properties, var: properties}, {name: row, var: row}, {name: size_x, var: size_x}, {name: size_y, var: size_y}, {name: visual_type, var: visual_type}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, dashboard_id: $dashboard_id, id: $id, block_feeds: $block_feeds, column: $column, body_dashboard_id: $body_dashboard_id, description: $description, key: $key, name: $name, properties: $properties, row: $row, size_x: $size_x, size_y: $size_y, visual_type: $visual_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an existing Block
#
# PUT /{username}/dashboards/{dashboard_id}/blocks/{id}
# Returns: record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>
# operationId: replaceBlock
export def "replace-block" [
  username: string
  dashboard_id: string
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
  --accept: string@accept-completer # Response content type
  --block-feeds: list # item shape: {feed_id?: string, group_id?: string}
  --column: float
  --body-dashboard-id: float # (spec name: dashboard_id)
  --description: string
  --key: string
  --name: string
  --properties: record
  --row: float
  --size-x: float
  --size-y: float
  --visual-type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{username}/dashboards/{dashboard_id}/blocks/{id}"
    path_params: [{name: username, var: username}, {name: dashboard_id, var: dashboard_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: block_feeds, var: block_feeds}, {name: column, var: column}, {name: dashboard_id, var: body_dashboard_id}, {name: description, var: description}, {name: key, var: key}, {name: name, var: name}, {name: properties, var: properties}, {name: row, var: row}, {name: size_x, var: size_x}, {name: size_y, var: size_y}, {name: visual_type, var: visual_type}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, dashboard_id: $dashboard_id, id: $id, block_feeds: $block_feeds, column: $column, body_dashboard_id: $body_dashboard_id, description: $description, key: $key, name: $name, properties: $properties, row: $row, size_x: $size_x, size_y: $size_y, visual_type: $visual_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing Dashboard
#
# DELETE /{username}/dashboards/{id}
# Returns: string
# operationId: destroyDashboard
export def "destroy-dashboard" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/dashboards/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Dashboard based on ID
#
# GET /{username}/dashboards/{id}
# Returns: record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string>
# operationId: getDashboard
export def "get-dashboard" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/dashboards/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update properties of an existing Dashboard
#
# PATCH /{username}/dashboards/{id}
# Returns: record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string>
# operationId: updateDashboard
export def "update-dashboard" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --description: string
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{username}/dashboards/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id, description: $description, key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an existing Dashboard
#
# PUT /{username}/dashboards/{id}
# Returns: record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string>
# operationId: replaceDashboard
export def "replace-dashboard" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --description: string
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{username}/dashboards/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id, description: $description, key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All feeds for current user
#
# GET /{username}/feeds
# Returns: table<created_at: string, description: string, details: record<data: record, shared_with: list>, enabled: bool, group: record, groups: list<record>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>
# operationId: allFeeds
export def "all-feeds" [
  username: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Feed
#
# POST /{username}/feeds
# Returns: record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>
# operationId: createFeed
export def "create-feed" [
  username: string
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
  --group-key: string
  --description: string
  --key: string
  --license: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/feeds"
    path_params: [{name: username, var: username}]
    query: [{name: group_key, var: group_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: license, var: license}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, description: $description, key: $key, license: $license, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing Feed
#
# DELETE /{username}/feeds/{feed_key}
# operationId: destroyFeed
export def "destroy-feed" [
  username: string
  feed_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/feeds/{feed_key}"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get feed by feed key
#
# GET /{username}/feeds/{feed_key}
# Returns: record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>
# operationId: getFeed
export def "get-feed" [
  username: string
  feed_key: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update properties of an existing Feed
#
# PATCH /{username}/feeds/{feed_key}
# Returns: record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>
# operationId: updateFeed
export def "update-feed" [
  username: string
  feed_key: string
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
  --description: string
  --key: string
  --license: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{username}/feeds/{feed_key}"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: license, var: license}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, description: $description, key: $key, license: $license, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an existing Feed
#
# PUT /{username}/feeds/{feed_key}
# Returns: record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>
# operationId: replaceFeed
export def "replace-feed" [
  username: string
  feed_key: string
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
  --description: string
  --key: string
  --license: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{username}/feeds/{feed_key}"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: license, var: license}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, description: $description, key: $key, license: $license, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all data for the given feed
#
# GET /{username}/feeds/{feed_key}/data
# Returns: table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: allData
export def "all-data" [
  username: string
  feed_key: string
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
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}/data"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: include, var: include}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, start_time: $start_time, end_time: $end_time, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create new Data
#
# POST /{username}/feeds/{feed_key}/data
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: createData
export def "create-data" [
  username: string
  feed_key: string
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
  --created-at: string # format: dateTime
  --ele: string
  --epoch: float
  --lat: string
  --lon: string
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/feeds/{feed_key}/data"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: ele, var: ele}, {name: epoch, var: epoch}, {name: lat, var: lat}, {name: lon, var: lon}, {name: value, var: value}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, created_at: $created_at, ele: $ele, epoch: $epoch, lat: $lat, lon: $lon, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create multiple new Data records
#
# POST /{username}/feeds/{feed_key}/data/batch
# Returns: table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: batchCreateData
export def "batch-create-data" [
  username: string
  feed_key: string
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/feeds/{feed_key}/data/batch"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Chart data for current feed
#
# GET /{username}/feeds/{feed_key}/data/chart
# Returns: record<columns: list<string>, data: list<list<string>>, feed: record<id: int, key: string, name: string>, parameters: record>
# operationId: chartData
export def "chart-data" [
  username: string
  feed_key: string
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
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --resolution: int # A resolution size in minutes. By giving a resolution value you will get back grouped data points aggregated over resolution-sized intervals. NOTE: time span is preferred over resolution, so if you request a span of time that includes more than max limit points you may get a larger resolution than you requested. Valid resolutions are 1, 5, 10, 30, 60, and 120. (format: int32)
  --hours: int # The number of hours the chart should cover. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}/data/chart"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: resolution, var: resolution}, {name: hours, var: hours}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, start_time: $start_time, end_time: $end_time, resolution: $resolution, hours: $hours
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# First Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/first
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: firstData
export def "first-data" [
  username: string
  feed_key: string
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
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}/data/first"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    query: [{name: include, var: include}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Last Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/last
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: lastData
export def "last-data" [
  username: string
  feed_key: string
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
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}/data/last"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    query: [{name: include, var: include}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Next Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/next
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: nextData
export def "next-data" [
  username: string
  feed_key: string
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
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}/data/next"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    query: [{name: include, var: include}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Previous Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/previous
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: previousData
export def "previous-data" [
  username: string
  feed_key: string
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
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}/data/previous"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    query: [{name: include, var: include}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Last Data in MQTT CSV format
#
# GET /{username}/feeds/{feed_key}/data/retain
# Returns: string
# operationId: retainData
export def "retain-data" [
  username: string
  feed_key: string
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
    method: get
    path: "/{username}/feeds/{feed_key}/data/retain"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    accept: ["text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete existing Data
#
# DELETE /{username}/feeds/{feed_key}/data/{id}
# Returns: string
# operationId: destroyData
export def "destroy-data" [
  username: string
  feed_key: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/feeds/{feed_key}/data/{id}"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns data based on feed key
#
# GET /{username}/feeds/{feed_key}/data/{id}
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: getData
export def "get-data" [
  username: string
  feed_key: string
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
  --accept: string@accept-completer # Response content type
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}/data/{id}"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}, {name: id, var: id}]
    query: [{name: include, var: include}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, id: $id, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update properties of existing Data
#
# PATCH /{username}/feeds/{feed_key}/data/{id}
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: updateData
export def "update-data" [
  username: string
  feed_key: string
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
  --accept: string@accept-completer # Response content type
  --created-at: string # format: dateTime
  --ele: string
  --epoch: float
  --lat: string
  --lon: string
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{username}/feeds/{feed_key}/data/{id}"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: ele, var: ele}, {name: epoch, var: epoch}, {name: lat, var: lat}, {name: lon, var: lon}, {name: value, var: value}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, id: $id, created_at: $created_at, ele: $ele, epoch: $epoch, lat: $lat, lon: $lon, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace existing Data
#
# PUT /{username}/feeds/{feed_key}/data/{id}
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: replaceData
export def "replace-data" [
  username: string
  feed_key: string
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
  --accept: string@accept-completer # Response content type
  --created-at: string # format: dateTime
  --ele: string
  --epoch: float
  --lat: string
  --lon: string
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{username}/feeds/{feed_key}/data/{id}"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: ele, var: ele}, {name: epoch, var: epoch}, {name: lat, var: lat}, {name: lon, var: lon}, {name: value, var: value}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key, id: $id, created_at: $created_at, ele: $ele, epoch: $epoch, lat: $lat, lon: $lon, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get detailed feed by feed key
#
# GET /{username}/feeds/{feed_key}/details
# Returns: record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>
# operationId: getFeedDetails
export def "get-feed-details" [
  username: string
  feed_key: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/feeds/{feed_key}/details"
    path_params: [{name: username, var: username}, {name: feed_key, var: feed_key}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, feed_key: $feed_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All groups for current user
#
# GET /{username}/groups
# Returns: table<created_at: string, description: string, feeds: list<record>, id: float, name: string, updated_at: string>
# operationId: allGroups
export def "all-groups" [
  username: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/groups"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Group
#
# POST /{username}/groups
# Returns: record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>
# operationId: createGroup
export def "create-group" [
  username: string
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
  --description: string
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/groups"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, description: $description, key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing Group
#
# DELETE /{username}/groups/{group_key}
# Returns: string
# operationId: destroyGroup
export def "destroy-group" [
  username: string
  group_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/groups/{group_key}"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Group based on ID
#
# GET /{username}/groups/{group_key}
# Returns: record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>
# operationId: getGroup
export def "get-group" [
  username: string
  group_key: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/groups/{group_key}"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update properties of an existing Group
#
# PATCH /{username}/groups/{group_key}
# Returns: record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>
# operationId: updateGroup
export def "update-group" [
  username: string
  group_key: string
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
  --description: string
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{username}/groups/{group_key}"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, description: $description, key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an existing Group
#
# PUT /{username}/groups/{group_key}
# Returns: record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>
# operationId: replaceGroup
export def "replace-group" [
  username: string
  group_key: string
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
  --description: string
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{username}/groups/{group_key}"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, description: $description, key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an existing Feed to a Group
#
# POST /{username}/groups/{group_key}/add
# Returns: record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>
# operationId: addFeedToGroup
export def "add-feed-to-group" [
  username: string
  group_key: string
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
  --feed-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{username}/groups/{group_key}/add"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    query: [{name: feed_key, var: feed_key}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, feed_key: $feed_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create new data for multiple feeds in a group
#
# POST /{username}/groups/{group_key}/data
# Returns: table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: createGroupData
export def "create-group-data" [
  username: string
  group_key: string
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
  --created-at: string # Optional created_at timestamp which will be applied to all feed values created.
  feeds: list # An array of feed data records with `key` and `value` properties. — item shape: {key: string, value: string}
  --location: record # A location record with `lat`, `lon`, and [optional] `ele` properties. — shape: {ele?: float, lat: float, lon: float}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/groups/{group_key}/data"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: feeds, var: feeds}, {name: location, var: location}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, created_at: $created_at, feeds: $feeds, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All feeds for current user in a given group
#
# GET /{username}/groups/{group_key}/feeds
# Returns: table<created_at: string, description: string, details: record<data: record, shared_with: list>, enabled: bool, group: record, groups: list<record>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>
# operationId: allGroupFeeds
export def "all-group-feeds" [
  username: string
  group_key: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/groups/{group_key}/feeds"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Feed in a Group
#
# POST /{username}/groups/{group_key}/feeds
# Returns: record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>
# operationId: createGroupFeed
export def "create-group-feed" [
  username: string
  group_key: string
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
  --description: string
  --key: string
  --license: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/groups/{group_key}/feeds"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: license, var: license}, {name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, description: $description, key: $key, license: $license, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All data for current feed in a specific group
#
# GET /{username}/groups/{group_key}/feeds/{feed_key}/data
# Returns: table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: allGroupFeedData
export def "all-group-feed-data" [
  username: string
  group_key: string
  feed_key: string
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
  --start-time: string # Start time for filtering data. Returns data created after given time. (format: date-time)
  --end-time: string # End time for filtering data. Returns data created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/groups/{group_key}/feeds/{feed_key}/data"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}, {name: feed_key, var: feed_key}]
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: limit, var: limit}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, feed_key: $feed_key, start_time: $start_time, end_time: $end_time, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create new Data in a feed belonging to a particular group
#
# POST /{username}/groups/{group_key}/feeds/{feed_key}/data
# Returns: record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: createGroupFeedData
export def "create-group-feed-data" [
  username: string
  group_key: string
  feed_key: string
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
  --created-at: string # format: dateTime
  --ele: string
  --epoch: float
  --lat: string
  --lon: string
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/groups/{group_key}/feeds/{feed_key}/data"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}, {name: feed_key, var: feed_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: ele, var: ele}, {name: epoch, var: epoch}, {name: lat, var: lat}, {name: lon, var: lon}, {name: value, var: value}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, feed_key: $feed_key, created_at: $created_at, ele: $ele, epoch: $epoch, lat: $lat, lon: $lon, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create multiple new Data records in a feed belonging to a particular group
#
# POST /{username}/groups/{group_key}/feeds/{feed_key}/data/batch
# Returns: table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string>
# operationId: batchCreateGroupFeedData
export def "batch-create-group-feed-data" [
  username: string
  group_key: string
  feed_key: string
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/groups/{group_key}/feeds/{feed_key}/data/batch"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}, {name: feed_key, var: feed_key}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, feed_key: $feed_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a Feed from a Group
#
# POST /{username}/groups/{group_key}/remove
# Returns: record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string>
# operationId: removeFeedFromGroup
export def "remove-feed-from-group" [
  username: string
  group_key: string
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
  --feed-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{username}/groups/{group_key}/remove"
    path_params: [{name: username, var: username}, {name: group_key, var: group_key}]
    query: [{name: feed_key, var: feed_key}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, group_key: $group_key, feed_key: $feed_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the user's data rate limit and current activity level.
#
# GET /{username}/throttle
# Returns: record<active_data_rate: int, data_rate_limit: int>
# operationId: getCurrentUserThrottle
export def "get-current-user-throttle" [
  username: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/throttle"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All tokens for current user
#
# GET /{username}/tokens
# Returns: table<token: string>
# operationId: allTokens
export def "all-tokens" [
  username: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/tokens"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Token
#
# POST /{username}/tokens
# Returns: record<token: string>
# operationId: createToken
export def "create-token" [
  username: string
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
  --body-token: string # (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/tokens"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing Token
#
# DELETE /{username}/tokens/{id}
# Returns: string
# operationId: destroyToken
export def "destroy-token" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/tokens/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Token based on ID
#
# GET /{username}/tokens/{id}
# Returns: record<token: string>
# operationId: getToken
export def "get-token" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/tokens/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update properties of an existing Token
#
# PATCH /{username}/tokens/{id}
# Returns: record<token: string>
# operationId: updateToken
export def "update-token" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --body-token: string # (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{username}/tokens/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an existing Token
#
# PUT /{username}/tokens/{id}
# Returns: record<token: string>
# operationId: replaceToken
export def "replace-token" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --body-token: string # (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{username}/tokens/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All triggers for current user
#
# GET /{username}/triggers
# Returns: table<name: string>
# operationId: allTriggers
export def "all-triggers" [
  username: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/triggers"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Trigger
#
# POST /{username}/triggers
# Returns: record<name: string>
# operationId: createTrigger
export def "create-trigger" [
  username: string
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
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/triggers"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing Trigger
#
# DELETE /{username}/triggers/{id}
# Returns: string
# operationId: destroyTrigger
export def "destroy-trigger" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/triggers/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Trigger based on ID
#
# GET /{username}/triggers/{id}
# Returns: record<name: string>
# operationId: getTrigger
export def "get-trigger" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/triggers/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update properties of an existing Trigger
#
# PATCH /{username}/triggers/{id}
# Returns: record<name: string>
# operationId: updateTrigger
export def "update-trigger" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{username}/triggers/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an existing Trigger
#
# PUT /{username}/triggers/{id}
# Returns: record<name: string>
# operationId: replaceTrigger
export def "replace-trigger" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{username}/triggers/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All permissions for current user and type
#
# GET /{username}/{type}/{type_id}/acl
# Returns: table<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>
# operationId: allPermissions
export def "all-permissions" [
  username: string
  type: string
  type_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/{type}/{type_id}/acl"
    path_params: [{name: username, var: username}, {name: type, var: type}, {name: type_id, var: type_id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, type: $type, type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Permission
#
# POST /{username}/{type}/{type_id}/acl
# Returns: record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>
# operationId: createPermission
export def "create-permission" [
  username: string
  type: string
  type_id: string
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
  --mode: string@mode-completer # default: r
  --scope: string@scope-completer # default: public
  --scope-value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{username}/{type}/{type_id}/acl"
    path_params: [{name: username, var: username}, {name: type, var: type}, {name: type_id, var: type_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mode, var: mode}, {name: scope, var: scope}, {name: scope_value, var: scope_value}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, type: $type, type_id: $type_id, mode: $mode, scope: $scope, scope_value: $scope_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing Permission
#
# DELETE /{username}/{type}/{type_id}/acl/{id}
# Returns: string
# operationId: destroyPermission
export def "destroy-permission" [
  username: string
  type: string
  type_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/{username}/{type}/{type_id}/acl/{id}"
    path_params: [{name: username, var: username}, {name: type, var: type}, {name: type_id, var: type_id}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, type: $type, type_id: $type_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Permission based on ID
#
# GET /{username}/{type}/{type_id}/acl/{id}
# Returns: record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>
# operationId: getPermission
export def "get-permission" [
  username: string
  type: string
  type_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{username}/{type}/{type_id}/acl/{id}"
    path_params: [{name: username, var: username}, {name: type, var: type}, {name: type_id, var: type_id}, {name: id, var: id}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, type: $type, type_id: $type_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update properties of an existing Permission
#
# PATCH /{username}/{type}/{type_id}/acl/{id}
# Returns: record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>
# operationId: updatePermission
export def "update-permission" [
  username: string
  type: string
  type_id: string
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
  --accept: string@accept-completer # Response content type
  --mode: string@mode-completer # default: r
  --scope: string@scope-completer # default: public
  --scope-value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{username}/{type}/{type_id}/acl/{id}"
    path_params: [{name: username, var: username}, {name: type, var: type}, {name: type_id, var: type_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mode, var: mode}, {name: scope, var: scope}, {name: scope_value, var: scope_value}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, type: $type, type_id: $type_id, id: $id, mode: $mode, scope: $scope, scope_value: $scope_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an existing Permission
#
# PUT /{username}/{type}/{type_id}/acl/{id}
# Returns: record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float>
# operationId: replacePermission
export def "replace-permission" [
  username: string
  type: string
  type_id: string
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
  --accept: string@accept-completer # Response content type
  --mode: string@mode-completer # default: r
  --scope: string@scope-completer # default: public
  --scope-value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{username}/{type}/{type_id}/acl/{id}"
    path_params: [{name: username, var: username}, {name: type, var: type}, {name: type_id, var: type_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mode, var: mode}, {name: scope, var: scope}, {name: scope_value, var: scope_value}]}
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: x-aio-key
  } {
    username: $username, type: $type, type_id: $type_id, id: $id, mode: $mode, scope: $scope, scope_value: $scope_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
