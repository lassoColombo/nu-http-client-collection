# Auto-generated client for BulkSMS JSON REST API v1.0.0
# Source: https://api.apis.guru/v2/specs/bulksms.com/1.0.0/openapi.json
# Auth: --token flag or $env.BULKSMS_JSON_REST_API_TOKEN

const CLIENT = {
  base_url: "https://api.bulksms.com/v1"
  token_env_var: "BULKSMS_JSON_REST_API_TOKEN"
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

def base-url-completer [] { ["https://api.bulksms.com/v1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def sort-order-completer [] { ["ASCENDING"] }
def invoke-option-completer [] { ["MANY" "ONE"] }
def trigger-scope-completer [] { ["RECEIVED" "SENT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-blocked-numbers: "record<id: float, phoneNumber: string>"
    get-messages: "table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>"
    post-messages: "table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>"
    get-messages-send: "table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>"
    get-messages-id: "record<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>"
    get-messages-id-related-received-messages: "table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>"
    get-profile: "record<commerce: record<address: record<city: string, country: string, postalCode: string, region: string, street: list>, bankPaymentReference: string>, company: record<name: string, taxReference: string>, created: string, credits: record<balance: float, isTransferAllowed: bool, limit: int>, id: string, originAddresses: record<allowed: list<string>, isFullControlAllowed: bool>, quota: record<remaining: int, size: int>, username: string>"
    post-rmm-pre-sign-attachment: "record<fetchUrl: string, fields: table<name: string, value: string>, putUrl: string>"
    get-webhooks: "table<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string>"
    post-webhooks: "record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string>"
    get-webhooks-id: "record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string>"
    post-webhooks-id: "record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-blocked-numbers" "post-blocked-numbers" "post-credit-transfer" "get-messages" "post-messages" "get-messages-send" "get-messages-id" "get-messages-id-related-received-messages" "get-profile" "post-rmm-pre-sign-attachment" "get-webhooks" "post-webhooks" "delete-webhooks-id" "get-webhooks-id" "post-webhooks-id" "commands"] | sort) } | get name | first)
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

# List blocked numbers
#
# GET /blocked-numbers
# Returns: record<id: float, phoneNumber: string>
export def "get-blocked-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-id: int # Records with an `id` that is greater or equal to min-id will be returned. The default value is `0`. You can add 1 to an id that you previously retrieved, to return subsequent records. (format: int32)
  --limit: int # The maximum number of records to return. The default value is `10000`. The value cannot be greater than 10000. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/blocked-numbers"
    query: [{name: min-id, var: min_id}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    min_id: $min_id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a blocked number
#
# POST /blocked-numbers
export def "post-blocked-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/blocked-numbers"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer credits to another account
#
# POST /credit/transfer
export def "post-credit-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment-on-from: string # An optional note that will be shown on the credit history of your account. The maximum length of the comment is 100. (e.g. Tranfer to Bobby)
  --comment-on-to: string # An optional note that will be shown on the credit history of the recipient's account. The maximum length of the comment is 100. (e.g. Tranfer from Danny)
  credits: float # The amount of credits to transfer. (e.g. 2345)
  to_user_id: float # The numeric user ID of the account that will receive the credits. The ID must match the username. (e.g. 2345)
  to_username: string # The username of the account that will receive the credits. (e.g. roboto)
]: any -> any {
  $in | http-request {
    method: post
    path: "/credit/transfer"
    body: {content_type: "application/json", kind: json, fields: [{name: commentOnFrom, var: comment_on_from}, {name: commentOnTo, var: comment_on_to}, {name: credits, var: credits}, {name: toUserId, var: to_user_id}, {name: toUsername, var: to_username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    comment_on_from: $comment_on_from, comment_on_to: $comment_on_to, credits: $credits, to_user_id: $to_user_id, to_username: $to_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Messages
#
# GET /messages
# Returns: table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>
export def "get-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # The maximum number of messages that are returned. The default is 1000. The value of `limit` is not a guarantee that a specific number of messages will be in the response, even if there are more messages available. Consider the case where you have 150 messages and you specify `limit=50`. It is possible that only 49 messages will be returned. The way to make sure that there are no more messages is to submit a new call using the `id` filter field with the `<` operator (described below). (format: int)
  --filter: string # See the message filtering for more information.
  --sort-order: string@sort-order-completer # The default value is DESCENDING If the `sortOrder` is DESCENDING, the newest messages be first in the result. ASCENDING places the oldest messages on top of the response.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/messages"
    query: [{name: limit, var: limit}, {name: filter, var: filter}, {name: sortOrder, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, filter: $filter, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send Messages
#
# POST /messages
# Returns: table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>
export def "post-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deduplication-id: int # Safeguards against the possibility of sending the same messages more than once. If a communication failure occurs during a submission, you cannot be sure that the submission was processed; therefore you would have to submit it again. When you post the retry, you must use the `deduplication-id` of the original post. The BulkSMS system uses this ID to check that the request was not previously processed. (If it was previously processed, the submission will succeed, and the behaviour will be indistinguishable to you from a non-duplicated submission). The ID expires after about 12 hours. (format: int32)
  --auto-unicode: oneof<nothing, bool> # Specifies how to deal with message text that contains characters not present in the GSM 03.38 character set. Messages that contain only GSM 03.38 characters are not affected by this setting. If the value is `true` then a message containing non-GSM 03.38 characters will be transmitted as a Unicode SMS (which is most likely more costly). Please note: when `auto-unicode` is `true` and the value of the `encoding` property is specified as `UNICODE`, the message will always be sent as `UNICODE`. If the value is `false` and the `encoding` property is `TEXT` then non-GSM 03.38 characters will be replaced by the `?` character. When using this setting on the API, you should take case to ensure that your message is _clean_. Invisible unicode and unexpected characters could unintentionally convert an message to `UNICODE`. A common mistake is to use the backtick character (\`) which is unicode and will turn your `TEXT` message into a `UNICODE` message. (default: false)
  --schedule-date: string # Allows you to send a message in the future. An example value is `2019-02-18T13:00:00+02:00`. It encodes to `2019-02-18T13%3A00%3A00%2B02%3A00`. Credits are deducted from your account immediately. Once submitted, scheduled messages cannot be changed or cancelled. The date can be a maximum of two years in the future. If the value is in the past, the message will be sent immediately. The date format requires you to supply an offset from UTC. You can decide to use the offset of your timezone, or maybe the zone of the recipient's location is more appropriate. If the destination is a group, the group members are determined at the time that you submit the message; not the time the message is scheduled to be sent. (format: date-time)
  --schedule-description: string # A note that is stored together with a scheduled submission, which could be used to more easily identify the scheduled submission at a later date. The value of this field is ignored if the `schedule-date` is not provided. A value that is longer than 256 characters is truncated.
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages"
    query: [{name: deduplication-id, var: deduplication_id}, {name: auto-unicode, var: auto_unicode}, {name: schedule-date, var: schedule_date}, {name: schedule-description, var: schedule_description}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    deduplication_id: $deduplication_id, auto_unicode: $auto_unicode, schedule_date: $schedule_date, schedule_description: $schedule_description, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send message by simple GET or POST
#
# GET /messages/send
# Returns: table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>
export def "get-messages-send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --to: string # The phone number of the recipient. (required)
  --qp-body: string # The text you want to send. (required) (spec name: body)
  --deduplication-id: int # Refer to the `deduplication-id` parameter. (format: int-32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/messages/send"
    query: [{name: to, var: to, required: true}, {name: body, var: qp_body, required: true}, {name: deduplication-id, var: deduplication_id}]
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    to: $to, qp_body: $qp_body, deduplication_id: $deduplication_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Message
#
# GET /messages/{id}
# Returns: record<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>
export def "get-messages-id" [
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
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Related Messages
#
# GET /messages/{id}/relatedReceivedMessages
# Returns: table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string>
export def "get-messages-id-related-received-messages" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/messages/{id}/relatedReceivedMessages"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get profile
#
# GET /profile
# Returns: record<commerce: record<address: record<city: string, country: string, postalCode: string, region: string, street: list>, bankPaymentReference: string>, company: record<name: string, taxReference: string>, created: string, credits: record<balance: float, isTransferAllowed: bool, limit: int>, id: string, originAddresses: record<allowed: list<string>, isFullControlAllowed: bool>, quota: record<remaining: int, size: int>, username: string>
export def "get-profile" [
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
    path: "/profile"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload an attachment via a signed URL
#
# POST /rmm/pre-sign-attachment
# Returns: record<fetchUrl: string, fields: table<name: string, value: string>, putUrl: string>
export def "post-rmm-pre-sign-attachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-extension: string # The extension of the file. Usually related to the media type. (e.g. pdf)
  --media-type: string # The media type of the file you would like to upload. If you are not sure what value to use here, check out the standard [list of media types](https://www.iana.org/assignments/media-types/media-types.xhtml). (e.g. application/pdf)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rmm/pre-sign-attachment"
    body: {content_type: "application/json", kind: json, fields: [{name: fileExtension, var: file_extension}, {name: mediaType, var: media_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    file_extension: $file_extension, media_type: $media_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webhooks
#
# GET /webhooks
# Returns: table<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string>
export def "get-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a webhook
#
# POST /webhooks
# Returns: record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string>
export def "post-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Indicates whether you want the webhook activated. If the value is `true`, the webhook at the given `url` will be invoked with an empty array (`[]`) as part of the validation process. If the webhook responds with a `2xx` status code, the submission is accepted; if not the webhook is not created (or updated). If the value is `false` the webhook will be inactive, and it will not be invoked when messages are `SENT` or `RECEIVED`. The default value is `true`. (e.g. true)
  --contact-email-address: string # The email address to which emails will be sent if there are problem with invoking the webhook. The value must be a valid email address. If this value is `null`, no email will be sent. It is `null` by default. (e.g. tech_team@example.com)
  --invoke-option: string@invoke-option-completer # Specifies how to invoke your webhook. If the value is `ONE` the array POSTed to your webhook will contain no more than a single message. Use this option if your webhook logic is unable to handle more than one messages at a time. If the value is `MANY` the array POSTed to your webhook can contain up to 10 messages. This is the recommended option. The number of calls made to your webhook would be less and this will speed up your total processing time. If your webhook fails for an invoke that has more than one message, each message in the array will automatically be retried one at a time. This value defaults to `ONE` - but it is recommended that you set this property to `MANY`. (e.g. MANY)
  name: string # A text identifier for the webhook. More than one webhook cannot have the same name. (e.g. My MT Webhook)
  --on-web-app: oneof<nothing, bool> # Indicates whether you want to show this webhook on the Web App. Webhooks shown there can be updated by the user that use the public Web site. The default value is `true`. (e.g. true)
  trigger_scope: string@trigger-scope-completer # Specifies when the webhook will be triggered. Please note the values are case sensitive. If the value is `SENT`, the webhook will be called when a status update becomes available for a message you sent (i.e. a mobile terminating (MT) message). If the value is `RECEIVED`, the webhook will be called when a message is received (i.e. a mobile originating (MO) message). Note that this field forces you to create two separate webhook entries if you want to collect all messages. However, you can use the same `url` for both webhooks if you want. (e.g. SENT)
  url: string # The location of the webhook. In addition to being a [valid URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier#Syntax), the url must also start with `http` or `https`. (e.g. https://www.example.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: contactEmailAddress, var: contact_email_address}, {name: invokeOption, var: invoke_option}, {name: name, var: name}, {name: onWebApp, var: on_web_app}, {name: triggerScope, var: trigger_scope}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    active: $active, contact_email_address: $contact_email_address, invoke_option: $invoke_option, name: $name, on_web_app: $on_web_app, trigger_scope: $trigger_scope, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook
#
# DELETE /webhooks/{id}
export def "delete-webhooks-id" [
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
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read a webhook
#
# GET /webhooks/{id}
# Returns: record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string>
export def "get-webhooks-id" [
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
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook
#
# POST /webhooks/{id}
# Returns: record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string>
export def "post-webhooks-id" [
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
  --active: oneof<nothing, bool> # Indicates whether you want the webhook activated. If the value is `true`, the webhook at the given `url` will be invoked with an empty array (`[]`) as part of the validation process. If the webhook responds with a `2xx` status code, the submission is accepted; if not the webhook is not created (or updated). If the value is `false` the webhook will be inactive, and it will not be invoked when messages are `SENT` or `RECEIVED`. The default value is `true`. (e.g. true)
  --contact-email-address: string # The email address to which emails will be sent if there are problem with invoking the webhook. The value must be a valid email address. If this value is `null`, no email will be sent. It is `null` by default. (e.g. tech_team@example.com)
  --invoke-option: string@invoke-option-completer # Specifies how to invoke your webhook. If the value is `ONE` the array POSTed to your webhook will contain no more than a single message. Use this option if your webhook logic is unable to handle more than one messages at a time. If the value is `MANY` the array POSTed to your webhook can contain up to 10 messages. This is the recommended option. The number of calls made to your webhook would be less and this will speed up your total processing time. If your webhook fails for an invoke that has more than one message, each message in the array will automatically be retried one at a time. This value defaults to `ONE` - but it is recommended that you set this property to `MANY`. (e.g. MANY)
  name: string # A text identifier for the webhook. More than one webhook cannot have the same name. (e.g. My MT Webhook)
  --on-web-app: oneof<nothing, bool> # Indicates whether you want to show this webhook on the Web App. Webhooks shown there can be updated by the user that use the public Web site. The default value is `true`. (e.g. true)
  trigger_scope: string@trigger-scope-completer # Specifies when the webhook will be triggered. Please note the values are case sensitive. If the value is `SENT`, the webhook will be called when a status update becomes available for a message you sent (i.e. a mobile terminating (MT) message). If the value is `RECEIVED`, the webhook will be called when a message is received (i.e. a mobile originating (MO) message). Note that this field forces you to create two separate webhook entries if you want to collect all messages. However, you can use the same `url` for both webhooks if you want. (e.g. SENT)
  url: string # The location of the webhook. In addition to being a [valid URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier#Syntax), the url must also start with `http` or `https`. (e.g. https://www.example.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: contactEmailAddress, var: contact_email_address}, {name: invokeOption, var: invoke_option}, {name: name, var: name}, {name: onWebApp, var: on_web_app}, {name: triggerScope, var: trigger_scope}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, active: $active, contact_email_address: $contact_email_address, invoke_option: $invoke_option, name: $name, on_web_app: $on_web_app, trigger_scope: $trigger_scope, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
