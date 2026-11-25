# Auto-generated client for SwaggerHub Registry API v1.0.66
# Source: https://api.apis.guru/v2/specs/swaggerhub.com/1.0.66/swagger.json
# Auth: --token flag or $env.SWAGGERHUB_REGISTRY_API_TOKEN

const CLIENT = {
  base_url: "https://api.swaggerhub.com"
  token_env_var: "SWAGGERHUB_REGISTRY_API_TOKEN"
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

def base-url-completer [] { ["https://api.swaggerhub.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["ALL" "PUBLISHED" "UNPUBLISHED"] }
def sort-completer [] { ["BEST_MATCH" "CREATED" "NAME" "OWNER" "TITLE" "UPDATED"] }
def order-completer [] { ["ASC" "DESC"] }
def accept-completer [] { ["application/json" "application/yaml"] }
def status-completer [] { ["OPEN" "RESOLVED"] }
def sort-completer-1 [] { ["NAME" "OWNER"] }
def spec-type-completer [] { ["apis" "domains"] }
def spec-type-completer-1 [] { ["ANY" "API" "DOMAIN" "TEMPLATE"] }
def visibility-completer [] { ["ANY" "PRIVATE" "PUBLIC"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-owner-apis: "record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>"
    get-api-versions: "record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>"
    get-api-default-version: "record<version: string>"
    get-definition: "record"
    get-api-comments-v2: "table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string>"
    add-api-comment-v2: "record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string>"
    update-api-comment-v2: "record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string>"
    add-api-comment-reply-v2: "table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>>"
    update-api-comment-reply-v2: "record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>>"
    get-integrations: "record<integrations: table<enabled: bool, id: string, name: string, configType: string>>"
    create-integration: "record<enabled: bool, id: string, name: string>"
    get-integration-by-id: "record<enabled: bool, id: string, name: string>"
    get-lifecycle-settings: "record<published: bool>"
    get-private-settings: "record<private: bool>"
    get-standardization-errors: "record<validation: table<description: string, line: int, severity: string>>"
    get-json-definition: "record"
    get-yaml-definition: "record"
    get-validation: "record<validation: table<description: string, line: int, severity: string>>"
    get-owner-domains: "record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>"
    get-domain-versions: "record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>"
    get-domain-default-version: "record<version: string>"
    get-domain-definition: "record"
    get-domain-comments-v2: "table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string>"
    add-domain-comment-v2: "record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string>"
    update-domain-comment-v2: "record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string>"
    add-domain-comment-reply-v2: "table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>>"
    update-domain-comment-reply-v2: "record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>>"
    get-domain-json-definition: "record"
    get-domain-yaml-definition: "record"
    get-domain-lifecycle-settings: "record<published: bool>"
    get-domain-private-settings: "record<private: bool>"
    get-user-projects: "record<offset: int, projects: table<apis: list, description: string, domains: list, name: string>, totalCount: int>"
    get-org-projects-v2: "record<offset: int, projects: table<apis: list, description: string, domains: list, name: string>, totalCount: int>"
    get-project-v2: "record<apis: list<string>, description: string, domains: list<string>, name: string>"
    get-project-members-v2: "record<members: table<name: string, roles: list, type: string>>"
    search-apis-and-domains: "record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>"
    get-templates: "record<builtIn: bool, defaultVersion: string, id: string, specification: string, title: string>"
    get-template-versions: "record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>"
    get-template-definition: "record"
    get-template-comments: "table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string>"
    get-template-lifecycle-settings: "record<published: bool>"
    get-template-private-settings: "record<private: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["search-apis" "get-owner-apis" "delete-api" "get-api-versions" "save-definition" "rename-api" "get-api-default-version" "set-api-default-version" "delete-api-version" "get-definition" "clone-api" "get-api-comments-v2" "add-api-comment-v2" "update-api-comments-v2" "delete-api-comment-v2" "update-api-comment-v2" "add-api-comment-reply-v2" "delete-api-comment-reply-v2" "update-api-comment-reply-v2" "set-api-comment-status-v2" "fork-api" "get-integrations" "create-integration" "delete-integration" "get-integration-by-id" "patch-integration" "update-integration" "execute-integration" "get-lifecycle-settings" "set-lifecycle-settings" "get-private-settings" "set-private-settings" "get-standardization-errors" "get-json-definition" "get-yaml-definition" "get-validation" "search-domains" "get-owner-domains" "delete-domain" "get-domain-versions" "save-domain-definition" "rename-domain" "get-domain-default-version" "set-domain-default-version" "delete-domain-version" "get-domain-definition" "clone-domain" "get-domain-comments-v2" "add-domain-comment-v2" "update-domain-comments-v2" "delete-domain-comment-v2" "update-domain-comment-v2" "add-domain-comment-reply-v2" "delete-domain-comment-reply-v2" "update-domain-comment-reply-v2" "set-domain-comment-status-v2" "get-domain-json-definition" "get-domain-yaml-definition" "fork-domain" "get-domain-lifecycle-settings" "set-domain-lifecycle-settings" "get-domain-private-settings" "set-domain-private-settings" "get-user-projects" "get-org-projects-v2" "create-project" "delete-project-v2" "get-project-v2" "save-project-v2" "get-project-members-v2" "update-project-members-v2" "add-spec-to-project-v2" "search-apis-and-domains" "get-templates" "delete-template" "get-template-versions" "save-template-definition" "rename-template" "delete-template-version" "get-template-definition" "get-template-comments" "update-template-comments" "fork-template" "get-template-lifecycle-settings" "set-template-lifecycle-settings" "get-template-private-settings" "set-template-private-settings" "commands"] | sort) } | get name | first)
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

# Search APIs
#
# GET /apis
# operationId: searchApis
export def "search-apis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Free text query to match
  --state: string@state-completer # Matches against published state of the spec: * UNPUBLISHED - spec is a draft, a work in progress * PUBLISHED - spec is a stable version ready for consuming from client applications * ANY - either PUBLISHED or UNPUBLISHED (default: ALL)
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> any {
  http-request {
    method: get
    path: "/apis"
    query: [{name: query, var: query}, {name: state, var: state}, {name: page, var: page}, {name: limit, var: limit}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [303]
    auth: bearer
  } {
    query: $query, state: $state, page: $page, limit: $limit, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of APIs of the specified owner
#
# GET /apis/{owner}
# Returns: record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>
# operationId: getOwnerApis
export def "get-owner-apis" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apis/{owner}"
    path_params: [{name: owner, var: owner}]
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, page: $page, limit: $limit, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an API
#
# DELETE /apis/{owner}/{api}
# operationId: deleteApi
export def "delete-api" [
  owner: string
  api: string
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
    path: "/apis/{owner}/{api}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of API versions
#
# GET /apis/{owner}/{api}
# Returns: record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>
# operationId: getApiVersions
export def "get-api-versions" [
  owner: string
  api: string
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
    path: "/apis/{owner}/{api}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update an API
#
# POST /apis/{owner}/{api}
# operationId: saveDefinition
export def "save-definition" [
  owner: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-private: oneof<nothing, bool> # Whether to make the API private (`true`) or public (`false`) (default: false)
  --version: string # API version to create or update. If omitted, the version is extracted from the `info.version` field of the provided OpenAPI definition. Either the `version` parameter or the `info.version` value must be specified, otherwise the request will be rejected. If both are specified, the `version` parameter overrides the `info.version` value. If this API version already exists, it will be updated with the new definition (unless that version has been published - in this case the update will be rejected).
  --force: oneof<nothing, bool> # Force update
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/apis/{owner}/{api}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}]
    query: [{name: isPrivate, var: is_private}, {name: version, var: version}, {name: force, var: force}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200, 201, 205]
    auth: bearer
  } {
    owner: $owner, api: $api, is_private: $is_private, version: $version, force: $force, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename an API
#
# POST /apis/{owner}/{api}/rename
# operationId: renameApi
export def "rename-api" [
  owner: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-name: string # New name (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/apis/{owner}/{api}/rename"
    path_params: [{name: owner, var: owner}, {name: api, var: api}]
    query: [{name: newName, var: new_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, new_name: $new_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the default version of an API
#
# GET /apis/{owner}/{api}/settings/default
# Returns: record<version: string>
# operationId: getApiDefaultVersion
export def "get-api-default-version" [
  owner: string
  api: string
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
    path: "/apis/{owner}/{api}/settings/default"
    path_params: [{name: owner, var: owner}, {name: api, var: api}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the default API version
#
# PUT /apis/{owner}/{api}/settings/default
# operationId: setApiDefaultVersion
export def "set-api-default-version" [
  owner: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  version: string # Version identifier (case-insensitive) (e.g. 1.0.0)
]: any -> any {
  $in | http-request {
    method: put
    path: "/apis/{owner}/{api}/settings/default"
    path_params: [{name: owner, var: owner}, {name: api, var: api}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an API version
#
# DELETE /apis/{owner}/{api}/{version}
# operationId: deleteApiVersion
export def "delete-api-version" [
  owner: string
  api: string
  version: string
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
    path: "/apis/{owner}/{api}/{version}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the OpenAPI definition of the specified API version
#
# GET /apis/{owner}/{api}/{version}
# Returns: record
# operationId: getDefinition
export def "get-definition" [
  owner: string
  api: string
  version: string
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
  --resolved: oneof<nothing, bool> # Set to true to get the resolved version of the API definition. The content of all external $refs will be included in the resulting file. (default: false)
  --flatten: oneof<nothing, bool> # If set to `true`, it creates models from inline schemas in OpenAPI definition. AsyncAPI definitions cannot be flattened. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apis/{owner}/{api}/{version}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    query: [{name: resolved, var: resolved}, {name: flatten, var: flatten}]
    accept: ["application/json", "application/yaml"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, resolved: $resolved, flatten: $flatten
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new API version
#
# POST /apis/{owner}/{api}/{version}/clone
# operationId: cloneApi
export def "clone-api" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --private: oneof<nothing, bool> # Whether the new version should be public (`false`) or private (`true`) (e.g. false)
  --body-version: string # The version identifier for the new version (e.g. 1.0.1) (spec name: version)
]: any -> any {
  $in | http-request {
    method: post
    path: "/apis/{owner}/{api}/{version}/clone"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: private, var: private}, {name: version, var: body_version, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, private: $private, body_version: $body_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get comments for the specified API version
#
# GET /apis/{owner}/{api}/{version}/comments
# Returns: table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string>
# operationId: getApiCommentsV2
export def "get-api-comments-v2" [
  owner: string
  api: string
  version: string
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
    path: "/apis/{owner}/{api}/{version}/comments"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new comment
#
# POST /apis/{owner}/{api}/{version}/comments
# Returns: record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string>
# operationId: addApiCommentV2
export def "add-api-comment-v2" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
  position: int # format: int32
  --replies: list # item shape: {body: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apis/{owner}/{api}/{version}/comments"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: position, var: position}, {name: replies, var: replies}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, body: $body, position: $position, replies: $replies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk update comments
#
# POST /apis/{owner}/{api}/{version}/comments/batch
# operationId: updateApiCommentsV2
export def "update-api-comments-v2" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-comment: list # item shape: {body: string, position: int, replies?: list}
  --add-reply: record
  --delete-comment: list<string>
  --delete-reply: record
  --update-comment: record
  --update-reply: record
  --update-status: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/apis/{owner}/{api}/{version}/comments/batch"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: addComment, var: add_comment}, {name: addReply, var: add_reply}, {name: deleteComment, var: delete_comment}, {name: deleteReply, var: delete_reply}, {name: updateComment, var: update_comment}, {name: updateReply, var: update_reply}, {name: updateStatus, var: update_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, add_comment: $add_comment, add_reply: $add_reply, delete_comment: $delete_comment, delete_reply: $delete_reply, update_comment: $update_comment, update_reply: $update_reply, update_status: $update_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment
#
# DELETE /apis/{owner}/{api}/{version}/comments/{comment}
# operationId: deleteApiCommentV2
export def "delete-api-comment-v2" [
  owner: string
  api: string
  version: string
  comment: string
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
    path: "/apis/{owner}/{api}/{version}/comments/{comment}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: comment, var: comment}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a comment
#
# PATCH /apis/{owner}/{api}/{version}/comments/{comment}
# Returns: record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string>
# operationId: updateApiCommentV2
export def "update-api-comment-v2" [
  owner: string
  api: string
  version: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
  --position: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apis/{owner}/{api}/{version}/comments/{comment}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: comment, var: comment}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, comment: $comment, body: $body, position: $position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reply to a comment
#
# POST /apis/{owner}/{api}/{version}/comments/{comment}/replies
# Returns: table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>>
# operationId: addApiCommentReplyV2
export def "add-api-comment-reply-v2" [
  owner: string
  api: string
  version: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apis/{owner}/{api}/{version}/comments/{comment}/replies"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: comment, var: comment}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, comment: $comment, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment reply
#
# DELETE /apis/{owner}/{api}/{version}/comments/{comment}/replies/{reply}
# operationId: deleteApiCommentReplyV2
export def "delete-api-comment-reply-v2" [
  owner: string
  api: string
  version: string
  comment: string
  reply: string
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
    path: "/apis/{owner}/{api}/{version}/comments/{comment}/replies/{reply}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: comment, var: comment}, {name: reply, var: reply}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, comment: $comment, reply: $reply
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a comment reply
#
# PATCH /apis/{owner}/{api}/{version}/comments/{comment}/replies/{reply}
# Returns: record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>>
# operationId: updateApiCommentReplyV2
export def "update-api-comment-reply-v2" [
  owner: string
  api: string
  version: string
  comment: string
  reply: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apis/{owner}/{api}/{version}/comments/{comment}/replies/{reply}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: comment, var: comment}, {name: reply, var: reply}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, comment: $comment, reply: $reply, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolve or reopen a comment
#
# PUT /apis/{owner}/{api}/{version}/comments/{comment}/status/{status}
# operationId: setApiCommentStatusV2
export def "set-api-comment-status-v2" [
  owner: string
  api: string
  version: string
  comment: string
  status: string@status-completer
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
    method: put
    path: "/apis/{owner}/{api}/{version}/comments/{comment}/status/{status}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: comment, var: comment}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, comment: $comment, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fork an API
#
# POST /apis/{owner}/{api}/{version}/fork
# operationId: forkApi
export def "fork-api" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/creating-api.html). Can be the name of an existing definition, in which case the fork will become a new version in that definition, unless that version already exists. (e.g. api-fork)
  --body-owner: string # The account to fork into. Can be an organization or user name. Case-sensitive. The authenticated user must have permissions to create definitions in this account. (e.g. acme) (spec name: owner)
  --private: oneof<nothing, bool> # Whether the forked version should be public (`false`) or private (`true`). If the value is not set, the original version's setting will be used.
  --project: string # If forking into an organization, you can optionally specify an existing project to add the forked definition to.
  --body-version: string # Version identifier for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/versioning.html#format). If forking into an existing definition, this version must not already exist. (e.g. 1.0.0) (spec name: version)
]: any -> any {
  $in | http-request {
    method: post
    path: "/apis/{owner}/{api}/{version}/fork"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: owner, var: body_owner, required: true}, {name: private, var: private}, {name: project, var: project}, {name: version, var: body_version, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, name: $name, body_owner: $body_owner, private: $private, project: $project, body_version: $body_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all integrations configured for the specified API version
#
# GET /apis/{owner}/{api}/{version}/integrations
# Returns: record<integrations: table<enabled: bool, id: string, name: string, configType: string>>
# operationId: getIntegrations
export def "get-integrations" [
  owner: string
  api: string
  version: string
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
    path: "/apis/{owner}/{api}/{version}/integrations"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an integration for the specified API and version
#
# POST /apis/{owner}/{api}/{version}/integrations
# Returns: record<enabled: bool, id: string, name: string>
# operationId: createIntegration
export def "create-integration" [
  owner: string
  api: string
  version: string
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
    path: "/apis/{owner}/{api}/{version}/integrations"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an integration
#
# DELETE /apis/{owner}/{api}/{version}/integrations/{integrationId}
# operationId: deleteIntegration
export def "delete-integration" [
  owner: string
  api: string
  version: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/apis/{owner}/{api}/{version}/integrations/{integrationId}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: integrationId, var: integration_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get integration settings
#
# GET /apis/{owner}/{api}/{version}/integrations/{integrationId}
# Returns: record<enabled: bool, id: string, name: string>
# operationId: getIntegrationById
export def "get-integration-by-id" [
  owner: string
  api: string
  version: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apis/{owner}/{api}/{version}/integrations/{integrationId}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: integrationId, var: integration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially update integration settings
#
# PATCH /apis/{owner}/{api}/{version}/integrations/{integrationId}
# operationId: patchIntegration
export def "patch-integration" [
  owner: string
  api: string
  version: string
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
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/apis/{owner}/{api}/{version}/integrations/{integrationId}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: integrationId, var: integration_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, integration_id: $integration_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update integration settings
#
# PUT /apis/{owner}/{api}/{version}/integrations/{integrationId}
# operationId: updateIntegration
export def "update-integration" [
  owner: string
  api: string
  version: string
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
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/apis/{owner}/{api}/{version}/integrations/{integrationId}"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: integrationId, var: integration_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, integration_id: $integration_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run an integration
#
# POST /apis/{owner}/{api}/{version}/integrations/{integrationId}/execute
# operationId: executeIntegration
export def "execute-integration" [
  owner: string
  api: string
  version: string
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
  --commit-message: string # Commit message for source control integrations
]: nothing -> any {
  http-request {
    method: post
    path: "/apis/{owner}/{api}/{version}/integrations/{integrationId}/execute"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}, {name: integrationId, var: integration_id}]
    query: [{name: commitMessage, var: commit_message}]
    accept: ["application/json"]
    ok: [200, 205]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, integration_id: $integration_id, commit_message: $commit_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the published status for the specified API and version
#
# GET /apis/{owner}/{api}/{version}/settings/lifecycle
# Returns: record<published: bool>
# operationId: getLifecycleSettings
export def "get-lifecycle-settings" [
  owner: string
  api: string
  version: string
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
    path: "/apis/{owner}/{api}/{version}/settings/lifecycle"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish or unpublish an API version
#
# PUT /apis/{owner}/{api}/{version}/settings/lifecycle
# operationId: setLifecycleSettings
export def "set-lifecycle-settings" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # To publish an API that references _unpublished_ domains, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
  --published: oneof<nothing, bool> # Whether the definition is published (`true`) or unpublished (`false`)
]: any -> any {
  $in | http-request {
    method: put
    path: "/apis/{owner}/{api}/{version}/settings/lifecycle"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    query: [{name: force, var: force}]
    body: {content_type: "application/json", kind: json, fields: [{name: published, var: published}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, force: $force, published: $published
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the visibility (public or private) of API version
#
# GET /apis/{owner}/{api}/{version}/settings/private
# Returns: record<private: bool>
# operationId: getPrivateSettings
export def "get-private-settings" [
  owner: string
  api: string
  version: string
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
    path: "/apis/{owner}/{api}/{version}/settings/private"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the visibility (public or private) of an API version
#
# PUT /apis/{owner}/{api}/{version}/settings/private
# operationId: setPrivateSettings
export def "set-private-settings" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --private: oneof<nothing, bool> # Whether the definition version is private (`true`) or public (`false`)
]: any -> any {
  $in | http-request {
    method: put
    path: "/apis/{owner}/{api}/{version}/settings/private"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: private, var: private, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the standardization errors for a given API definition
#
# GET /apis/{owner}/{api}/{version}/standardization
# Returns: record<validation: table<description: string, line: int, severity: string>>
# operationId: getStandardizationErrors
export def "get-standardization-errors" [
  owner: string
  api: string
  version: string
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
    path: "/apis/{owner}/{api}/{version}/standardization"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the OpenAPI definition for the specified API version in JSON format
#
# GET /apis/{owner}/{api}/{version}/swagger.json
# Returns: record
# operationId: getJsonDefinition
export def "get-json-definition" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resolved: oneof<nothing, bool> # Set to true to get the resolved version of the API definition. The content of all external $refs will be included in the resulting file. (default: false)
  --flatten: oneof<nothing, bool> # If set to `true`, it creates models from inline schemas in OpenAPI definition. AsyncAPI definitions cannot be flattened. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apis/{owner}/{api}/{version}/swagger.json"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    query: [{name: resolved, var: resolved}, {name: flatten, var: flatten}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, resolved: $resolved, flatten: $flatten
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the OpenAPI definition for the specified API version in YAML format
#
# GET /apis/{owner}/{api}/{version}/swagger.yaml
# Returns: record
# operationId: getYamlDefinition
export def "get-yaml-definition" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resolved: oneof<nothing, bool> # Set to true to get the resolved version of the API definition. The content of all external $refs will be included in the resulting file. (default: false)
  --flatten: oneof<nothing, bool> # If set to `true`, it creates models from inline schemas in OpenAPI definition. AsyncAPI definitions cannot be flattened. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apis/{owner}/{api}/{version}/swagger.yaml"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    query: [{name: resolved, var: resolved}, {name: flatten, var: flatten}]
    accept: ["application/yaml"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version, resolved: $resolved, flatten: $flatten
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated Get API Standardization errors and warnings
#
# GET /apis/{owner}/{api}/{version}/validation
# DEPRECATED
# Returns: record<validation: table<description: string, line: int, severity: string>>
# operationId: getValidation
@deprecated
export def "get-validation" [
  owner: string
  api: string
  version: string
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
    path: "/apis/{owner}/{api}/{version}/validation"
    path_params: [{name: owner, var: owner}, {name: api, var: api}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search domains
#
# GET /domains
# operationId: searchDomains
export def "search-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Free text query to match
  --state: string@state-completer # Matches against published state of the spec: * UNPUBLISHED - spec is a draft, a work in progress * PUBLISHED - spec is a stable version ready for consuming from client applications * ANY - either PUBLISHED or UNPUBLISHED (default: ALL)
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> any {
  http-request {
    method: get
    path: "/domains"
    query: [{name: query, var: query}, {name: state, var: state}, {name: page, var: page}, {name: limit, var: limit}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [303]
    auth: bearer
  } {
    query: $query, state: $state, page: $page, limit: $limit, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of domains of the specified owner
#
# GET /domains/{owner}
# Returns: record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>
# operationId: getOwnerDomains
export def "get-owner-domains" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains/{owner}"
    path_params: [{name: owner, var: owner}]
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, page: $page, limit: $limit, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a domain
#
# DELETE /domains/{owner}/{domain}
# operationId: deleteDomain
export def "delete-domain" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If this domain is referenced from other APIs and domains, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  http-request {
    method: delete
    path: "/domains/{owner}/{domain}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of domain versions
#
# GET /domains/{owner}/{domain}
# Returns: record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>
# operationId: getDomainVersions
export def "get-domain-versions" [
  owner: string
  domain: string
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
    path: "/domains/{owner}/{domain}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a domain
#
# POST /domains/{owner}/{domain}
# operationId: saveDomainDefinition
export def "save-domain-definition" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-private: oneof<nothing, bool> # Specifies whether the domain has to be private (default: false)
  --version: string # Domain version. If omitted, will be taken from the `info.version` field in the definition.
  --force: oneof<nothing, bool> # Force update
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/domains/{owner}/{domain}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}]
    query: [{name: isPrivate, var: is_private}, {name: version, var: version}, {name: force, var: force}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200, 201, 205]
    auth: bearer
  } {
    owner: $owner, domain: $domain, is_private: $is_private, version: $version, force: $force, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a domain
#
# POST /domains/{owner}/{domain}/rename
# operationId: renameDomain
export def "rename-domain" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-name: string # New name (required)
  --force: oneof<nothing, bool> # If this domain is referenced from other APIs and domains, this parameter must be true. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  http-request {
    method: post
    path: "/domains/{owner}/{domain}/rename"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}]
    query: [{name: newName, var: new_name, required: true}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, new_name: $new_name, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the default version of a domain
#
# GET /domains/{owner}/{domain}/settings/default
# Returns: record<version: string>
# operationId: getDomainDefaultVersion
export def "get-domain-default-version" [
  owner: string
  domain: string
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
    path: "/domains/{owner}/{domain}/settings/default"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the default version for a domain
#
# PUT /domains/{owner}/{domain}/settings/default
# operationId: setDomainDefaultVersion
export def "set-domain-default-version" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  version: string # Version identifier (case-insensitive) (e.g. 1.0.0)
]: any -> any {
  $in | http-request {
    method: put
    path: "/domains/{owner}/{domain}/settings/default"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a domain version
#
# DELETE /domains/{owner}/{domain}/{version}
# operationId: deleteDomainVersion
export def "delete-domain-version" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If this domain version is referenced from other APIs and domains, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  http-request {
    method: delete
    path: "/domains/{owner}/{domain}/{version}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the OpenAPI definition of the specified domain version
#
# GET /domains/{owner}/{domain}/{version}
# Returns: record
# operationId: getDomainDefinition
export def "get-domain-definition" [
  owner: string
  domain: string
  version: string
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
    path: "/domains/{owner}/{domain}/{version}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    accept: ["application/json", "application/yaml"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new domain version
#
# POST /domains/{owner}/{domain}/{version}/clone
# operationId: cloneDomain
export def "clone-domain" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --private: oneof<nothing, bool> # Whether the new version should be public (`false`) or private (`true`) (e.g. false)
  --body-version: string # The version identifier for the new version (e.g. 1.0.1) (spec name: version)
]: any -> any {
  $in | http-request {
    method: post
    path: "/domains/{owner}/{domain}/{version}/clone"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: private, var: private}, {name: version, var: body_version, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, private: $private, body_version: $body_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get comments for the specified domain version
#
# GET /domains/{owner}/{domain}/{version}/comments
# Returns: table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string>
# operationId: getDomainCommentsV2
export def "get-domain-comments-v2" [
  owner: string
  domain: string
  version: string
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
    path: "/domains/{owner}/{domain}/{version}/comments"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new comment
#
# POST /domains/{owner}/{domain}/{version}/comments
# Returns: record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string>
# operationId: addDomainCommentV2
export def "add-domain-comment-v2" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
  position: int # format: int32
  --replies: list # item shape: {body: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{owner}/{domain}/{version}/comments"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: position, var: position}, {name: replies, var: replies}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, body: $body, position: $position, replies: $replies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk update comments
#
# POST /domains/{owner}/{domain}/{version}/comments/batch
# operationId: updateDomainCommentsV2
export def "update-domain-comments-v2" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-comment: list # item shape: {body: string, position: int, replies?: list}
  --add-reply: record
  --delete-comment: list<string>
  --delete-reply: record
  --update-comment: record
  --update-reply: record
  --update-status: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/domains/{owner}/{domain}/{version}/comments/batch"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: addComment, var: add_comment}, {name: addReply, var: add_reply}, {name: deleteComment, var: delete_comment}, {name: deleteReply, var: delete_reply}, {name: updateComment, var: update_comment}, {name: updateReply, var: update_reply}, {name: updateStatus, var: update_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, add_comment: $add_comment, add_reply: $add_reply, delete_comment: $delete_comment, delete_reply: $delete_reply, update_comment: $update_comment, update_reply: $update_reply, update_status: $update_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment
#
# DELETE /domains/{owner}/{domain}/{version}/comments/{comment}
# operationId: deleteDomainCommentV2
export def "delete-domain-comment-v2" [
  owner: string
  domain: string
  version: string
  comment: string
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
    path: "/domains/{owner}/{domain}/{version}/comments/{comment}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}, {name: comment, var: comment}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a comment
#
# PATCH /domains/{owner}/{domain}/{version}/comments/{comment}
# Returns: record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string>
# operationId: updateDomainCommentV2
export def "update-domain-comment-v2" [
  owner: string
  domain: string
  version: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
  --position: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/domains/{owner}/{domain}/{version}/comments/{comment}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}, {name: comment, var: comment}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, comment: $comment, body: $body, position: $position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reply to a comment
#
# POST /domains/{owner}/{domain}/{version}/comments/{comment}/replies
# Returns: table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>>
# operationId: addDomainCommentReplyV2
export def "add-domain-comment-reply-v2" [
  owner: string
  domain: string
  version: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{owner}/{domain}/{version}/comments/{comment}/replies"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}, {name: comment, var: comment}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, comment: $comment, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment reply
#
# DELETE /domains/{owner}/{domain}/{version}/comments/{comment}/replies/{reply}
# operationId: deleteDomainCommentReplyV2
export def "delete-domain-comment-reply-v2" [
  owner: string
  domain: string
  version: string
  comment: string
  reply: string
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
    path: "/domains/{owner}/{domain}/{version}/comments/{comment}/replies/{reply}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}, {name: comment, var: comment}, {name: reply, var: reply}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, comment: $comment, reply: $reply
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a comment reply
#
# PATCH /domains/{owner}/{domain}/{version}/comments/{comment}/replies/{reply}
# Returns: record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>>
# operationId: updateDomainCommentReplyV2
export def "update-domain-comment-reply-v2" [
  owner: string
  domain: string
  version: string
  comment: string
  reply: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/domains/{owner}/{domain}/{version}/comments/{comment}/replies/{reply}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}, {name: comment, var: comment}, {name: reply, var: reply}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, comment: $comment, reply: $reply, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolve or reopen a comment
#
# PUT /domains/{owner}/{domain}/{version}/comments/{comment}/status/{status}
# operationId: setDomainCommentStatusV2
export def "set-domain-comment-status-v2" [
  owner: string
  domain: string
  version: string
  comment: string
  status: string@status-completer
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
    method: put
    path: "/domains/{owner}/{domain}/{version}/comments/{comment}/status/{status}"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}, {name: comment, var: comment}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, comment: $comment, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the OpenAPI definition for the specified domain version in JSON format
#
# GET /domains/{owner}/{domain}/{version}/domain.json
# Returns: record
# operationId: getDomainJsonDefinition
export def "get-domain-json-definition" [
  owner: string
  domain: string
  version: string
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
    path: "/domains/{owner}/{domain}/{version}/domain.json"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the OpenAPI definition for the specified domain version in YAML format
#
# GET /domains/{owner}/{domain}/{version}/domain.yaml
# Returns: record
# operationId: getDomainYamlDefinition
export def "get-domain-yaml-definition" [
  owner: string
  domain: string
  version: string
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
    path: "/domains/{owner}/{domain}/{version}/domain.yaml"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    accept: ["application/yaml"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fork a domain
#
# POST /domains/{owner}/{domain}/{version}/fork
# operationId: forkDomain
export def "fork-domain" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/creating-api.html). Can be the name of an existing definition, in which case the fork will become a new version in that definition, unless that version already exists. (e.g. api-fork)
  --body-owner: string # The account to fork into. Can be an organization or user name. Case-sensitive. The authenticated user must have permissions to create definitions in this account. (e.g. acme) (spec name: owner)
  --private: oneof<nothing, bool> # Whether the forked version should be public (`false`) or private (`true`). If the value is not set, the original version's setting will be used.
  --project: string # If forking into an organization, you can optionally specify an existing project to add the forked definition to.
  --body-version: string # Version identifier for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/versioning.html#format). If forking into an existing definition, this version must not already exist. (e.g. 1.0.0) (spec name: version)
]: any -> any {
  $in | http-request {
    method: post
    path: "/domains/{owner}/{domain}/{version}/fork"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: owner, var: body_owner, required: true}, {name: private, var: private}, {name: project, var: project}, {name: version, var: body_version, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, name: $name, body_owner: $body_owner, private: $private, project: $project, body_version: $body_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the published status for the specified domain and version
#
# GET /domains/{owner}/{domain}/{version}/settings/lifecycle
# Returns: record<published: bool>
# operationId: getDomainLifecycleSettings
export def "get-domain-lifecycle-settings" [
  owner: string
  domain: string
  version: string
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
    path: "/domains/{owner}/{domain}/{version}/settings/lifecycle"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish or unpublish a domain version
#
# PUT /domains/{owner}/{domain}/{version}/settings/lifecycle
# operationId: setDomainLifecycleSettings
export def "set-domain-lifecycle-settings" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # To publish a domain that references other _unpublished_ domains, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
  --published: oneof<nothing, bool> # Whether the definition is published (`true`) or unpublished (`false`)
]: any -> any {
  $in | http-request {
    method: put
    path: "/domains/{owner}/{domain}/{version}/settings/lifecycle"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    query: [{name: force, var: force}]
    body: {content_type: "application/json", kind: json, fields: [{name: published, var: published}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, force: $force, published: $published
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the visibility (public or private) of a domain version
#
# GET /domains/{owner}/{domain}/{version}/settings/private
# Returns: record<private: bool>
# operationId: getDomainPrivateSettings
export def "get-domain-private-settings" [
  owner: string
  domain: string
  version: string
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
    path: "/domains/{owner}/{domain}/{version}/settings/private"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the visibility (public or private) of a domain version
#
# PUT /domains/{owner}/{domain}/{version}/settings/private
# operationId: setDomainPrivateSettings
export def "set-domain-private-settings" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # To change the visibility from _public_ to _private_ in case this domain is referenced from other _public_ definitions, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
  --private: oneof<nothing, bool> # Whether the definition version is private (`true`) or public (`false`)
]: any -> any {
  $in | http-request {
    method: put
    path: "/domains/{owner}/{domain}/{version}/settings/private"
    path_params: [{name: owner, var: owner}, {name: domain, var: domain}, {name: version, var: version}]
    query: [{name: force, var: force}]
    body: {content_type: "application/json", kind: json, fields: [{name: private, var: private, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, domain: $domain, version: $version, force: $force, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all projects that a user has access to
#
# GET /projects
# Returns: record<offset: int, projects: table<apis: list, description: string, domains: list, name: string>, totalCount: int>
# operationId: getUserProjects
export def "get-user-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-only: oneof<nothing, bool> # Return the project information excluding APIs and domains (default: false - DELETE)
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --sort: string@sort-completer-1 # Sort criteria or result set: * NAME * OWNER (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: nameOnly, var: name_only}, {name: page, var: page}, {name: limit, var: limit}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_only: $name_only, page: $page, limit: $limit, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all projects of an organization
#
# GET /projects/{owner}
# Returns: record<offset: int, projects: table<apis: list, description: string, domains: list, name: string>, totalCount: int>
# operationId: getOrgProjectsV2
export def "get-org-projects-v2" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-only: oneof<nothing, bool> # Return the project information excluding APIs and domains (default: false - DELETE)
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{owner}"
    path_params: [{name: owner, var: owner}]
    query: [{name: nameOnly, var: name_only}, {name: page, var: page}, {name: limit, var: limit}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, name_only: $name_only, page: $page, limit: $limit, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project in an organization
#
# POST /projects/{owner}
# operationId: createProject
export def "create-project" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apis: list<string> # A list of APIs included in this project. The APIs must belong to the same owner as the project. API names are case-sensitive. (default: [], e.g. [petstore])
  --description: string # Project description (default: "", e.g. APIs for core functionality)
  --domains: list<string> # A list of domains included in this project. The domains must belong to the same owner as the project. Domain names are case-sensitive. (default: [], e.g. [common-models])
  --name: string # Project name (e.g. CoreServices)
]: any -> any {
  $in | http-request {
    method: post
    path: "/projects/{owner}"
    path_params: [{name: owner, var: owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: apis, var: apis}, {name: description, var: description}, {name: domains, var: domains}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, apis: $apis, description: $description, domains: $domains, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project
#
# DELETE /projects/{owner}/{projectId}
# operationId: deleteProjectV2
export def "delete-project-v2" [
  owner: string
  project_id: string
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
    path: "/projects/{owner}/{projectId}"
    path_params: [{name: owner, var: owner}, {name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    owner: $owner, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project information
#
# GET /projects/{owner}/{projectId}
# Returns: record<apis: list<string>, description: string, domains: list<string>, name: string>
# operationId: getProjectV2
export def "get-project-v2" [
  owner: string
  project_id: string
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
    path: "/projects/{owner}/{projectId}"
    path_params: [{name: owner, var: owner}, {name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a project
#
# PUT /projects/{owner}/{projectId}
# operationId: saveProjectV2
export def "save-project-v2" [
  owner: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apis: list<string> # A list of APIs included in this project. The APIs must belong to the same owner as the project. API names are case-sensitive. (default: [], e.g. [petstore])
  --description: string # Project description (default: "", e.g. APIs for core functionality)
  --domains: list<string> # A list of domains included in this project. The domains must belong to the same owner as the project. Domain names are case-sensitive. (default: [], e.g. [common-models])
  --name: string # Project name (e.g. CoreServices)
]: any -> any {
  $in | http-request {
    method: put
    path: "/projects/{owner}/{projectId}"
    path_params: [{name: owner, var: owner}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: apis, var: apis}, {name: description, var: description}, {name: domains, var: domains}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, project_id: $project_id, apis: $apis, description: $description, domains: $domains, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project members
#
# GET /projects/{owner}/{projectId}/members
# Returns: record<members: table<name: string, roles: list, type: string>>
# operationId: getProjectMembersV2
export def "get-project-members-v2" [
  owner: string
  project_id: string
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
    path: "/projects/{owner}/{projectId}/members"
    path_params: [{name: owner, var: owner}, {name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a project's members list
#
# PUT /projects/{owner}/{projectId}/members
# operationId: updateProjectMembersV2
export def "update-project-members-v2" [
  owner: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --members: list # e.g. [{name: alex, type: USER}, {name: core-developers, type: TEAM}] — item shape: {name: string, type: "USER"|"TEAM"}
]: any -> any {
  $in | http-request {
    method: put
    path: "/projects/{owner}/{projectId}/members"
    path_params: [{name: owner, var: owner}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: members, var: members}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, project_id: $project_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an API or domain to a project
#
# PUT /projects/{owner}/{projectId}/{specType}/{name}
# operationId: addSpecToProjectV2
export def "add-spec-to-project-v2" [
  owner: string
  project_id: string
  spec_type: string@spec-type-completer
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
]: nothing -> any {
  http-request {
    method: put
    path: "/projects/{owner}/{projectId}/{specType}/{name}"
    path_params: [{name: owner, var: owner}, {name: projectId, var: project_id}, {name: specType, var: spec_type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, project_id: $project_id, spec_type: $spec_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of currently defined APIs, domains, and templates in APIs.json format
#
# GET /specs
# Returns: record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>
# operationId: searchApisAndDomains
export def "search-apis-and-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --spec-type: string@spec-type-completer-1 # Type of definitions to search: * API - APIs only * DOMAIN - domains only * TEMPLATE - templates only * ANY - APIs, domains, and templates (default: ANY)
  --visibility: string@visibility-completer # The visibility of a definition in SwaggerHub: * PUBLIC - can be viewed by anyone * PRIVATE - can only be viewed by you or your organization and those that you are collaborating with or have shared it with * ANY - either PUBLIC or PRIVATE (default: ANY)
  --state: string@state-completer # Matches against published state of the spec: * UNPUBLISHED - spec is a draft, a work in progress * PUBLISHED - spec is a stable version ready for consuming from client applications * ANY - either PUBLISHED or UNPUBLISHED (default: ALL)
  --owner: string # API or domain owner. Can be username or organization name. Case-sensitive.
  --query: string # Free text query to match
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/specs"
    query: [{name: specType, var: spec_type}, {name: visibility, var: visibility}, {name: state, var: state}, {name: owner, var: owner}, {name: query, var: query}, {name: page, var: page}, {name: limit, var: limit}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    spec_type: $spec_type, visibility: $visibility, state: $state, owner: $owner, query: $query, page: $page, limit: $limit, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of templates for an owner
#
# GET /templates
# Returns: record<builtIn: bool, defaultVersion: string, id: string, specification: string, title: string>
# operationId: getTemplates
export def "get-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string # Owner name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates"
    query: [{name: owner, var: owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a template
#
# DELETE /templates/{owner}/{templateId}
# operationId: deleteTemplate
export def "delete-template" [
  owner: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/templates/{owner}/{templateId}"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an APIs.json listing for all template versions for an owner and template
#
# GET /templates/{owner}/{templateId}
# Returns: record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string>
# operationId: getTemplateVersions
export def "get-template-versions" [
  owner: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates/{owner}/{templateId}"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a template
#
# POST /templates/{owner}/{templateId}
# operationId: saveTemplateDefinition
export def "save-template-definition" [
  owner: string
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
  --is-private: oneof<nothing, bool> # Defines whether the API or template has to be private (default: false)
  --version: string # Template version to create or update. If omitted, the version will be taken from the `info.version` field in the definition.
  --force: oneof<nothing, bool> # Force update
  --project-name: string # The project to add the API, domain, or template to
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/templates/{owner}/{templateId}"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}]
    query: [{name: isPrivate, var: is_private}, {name: version, var: version}, {name: force, var: force}, {name: projectName, var: project_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200, 201, 205]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, is_private: $is_private, version: $version, force: $force, project_name: $project_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a template
#
# POST /templates/{owner}/{templateId}/rename
# operationId: renameTemplate
export def "rename-template" [
  owner: string
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
  --new-name: string # New name (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/templates/{owner}/{templateId}/rename"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}]
    query: [{name: newName, var: new_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, new_name: $new_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a particular version of a template
#
# DELETE /templates/{owner}/{templateId}/{version}
# operationId: deleteTemplateVersion
export def "delete-template-version" [
  owner: string
  template_id: string
  version: string
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
    path: "/templates/{owner}/{templateId}/{version}"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a template definition
#
# GET /templates/{owner}/{templateId}/{version}
# Returns: record
# operationId: getTemplateDefinition
export def "get-template-definition" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # If set to `true`, it creates models from inline schemas in OpenAPI definition. AsyncAPI definitions cannot be flattened. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates/{owner}/{templateId}/{version}"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    query: [{name: flatten, var: flatten}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version, flatten: $flatten
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the list of comments for a template
#
# GET /templates/{owner}/{templateId}/{version}/comments
# Returns: table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string>
# operationId: getTemplateComments
export def "get-template-comments" [
  owner: string
  template_id: string
  version: string
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
    path: "/templates/{owner}/{templateId}/{version}/comments"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the list of comments for a template
#
# POST /templates/{owner}/{templateId}/{version}/comments/batch
# operationId: updateTemplateComments
export def "update-template-comments" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-comment: list # item shape: {body: string, position: int, replies?: list}
  --add-reply: record
  --delete-comment: list<string>
  --delete-reply: record
  --update-comment: record
  --update-reply: record
  --update-status: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/templates/{owner}/{templateId}/{version}/comments/batch"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: addComment, var: add_comment}, {name: addReply, var: add_reply}, {name: deleteComment, var: delete_comment}, {name: deleteReply, var: delete_reply}, {name: updateComment, var: update_comment}, {name: updateReply, var: update_reply}, {name: updateStatus, var: update_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version, add_comment: $add_comment, add_reply: $add_reply, delete_comment: $delete_comment, delete_reply: $delete_reply, update_comment: $update_comment, update_reply: $update_reply, update_status: $update_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a fork for a template
#
# POST /templates/{owner}/{templateId}/{version}/fork
# operationId: forkTemplate
export def "fork-template" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/creating-api.html). Can be the name of an existing definition, in which case the fork will become a new version in that definition, unless that version already exists. (e.g. api-fork)
  --body-owner: string # The account to fork into. Can be an organization or user name. Case-sensitive. The authenticated user must have permissions to create definitions in this account. (e.g. acme) (spec name: owner)
  --private: oneof<nothing, bool> # Whether the forked version should be public (`false`) or private (`true`). If the value is not set, the original version's setting will be used.
  --project: string # If forking into an organization, you can optionally specify an existing project to add the forked definition to.
  --body-version: string # Version identifier for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/versioning.html#format). If forking into an existing definition, this version must not already exist. (e.g. 1.0.0) (spec name: version)
]: any -> any {
  $in | http-request {
    method: post
    path: "/templates/{owner}/{templateId}/{version}/fork"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: owner, var: body_owner, required: true}, {name: private, var: private}, {name: project, var: project}, {name: version, var: body_version, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version, name: $name, body_owner: $body_owner, private: $private, project: $project, body_version: $body_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve lifecycle settings for a template
#
# GET /templates/{owner}/{templateId}/{version}/settings/lifecycle
# Returns: record<published: bool>
# operationId: getTemplateLifecycleSettings
export def "get-template-lifecycle-settings" [
  owner: string
  template_id: string
  version: string
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
    path: "/templates/{owner}/{templateId}/{version}/settings/lifecycle"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update lifecycle settings for a template
#
# PUT /templates/{owner}/{templateId}/{version}/settings/lifecycle
# operationId: setTemplateLifecycleSettings
export def "set-template-lifecycle-settings" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force update
  --published: oneof<nothing, bool> # Whether the definition is published (`true`) or unpublished (`false`)
]: any -> any {
  $in | http-request {
    method: put
    path: "/templates/{owner}/{templateId}/{version}/settings/lifecycle"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    query: [{name: force, var: force}]
    body: {content_type: "application/json", kind: json, fields: [{name: published, var: published}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version, force: $force, published: $published
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve visibility settings for a template
#
# GET /templates/{owner}/{templateId}/{version}/settings/private
# Returns: record<private: bool>
# operationId: getTemplatePrivateSettings
export def "get-template-private-settings" [
  owner: string
  template_id: string
  version: string
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
    path: "/templates/{owner}/{templateId}/{version}/settings/private"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update visibility settings for a template
#
# PUT /templates/{owner}/{templateId}/{version}/settings/private
# operationId: setTemplatePrivateSettings
export def "set-template-private-settings" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --private: oneof<nothing, bool> # Whether the definition version is private (`true`) or public (`false`)
]: any -> any {
  $in | http-request {
    method: put
    path: "/templates/{owner}/{templateId}/{version}/settings/private"
    path_params: [{name: owner, var: owner}, {name: templateId, var: template_id}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: private, var: private, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, template_id: $template_id, version: $version, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
