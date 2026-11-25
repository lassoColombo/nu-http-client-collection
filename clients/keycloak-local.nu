# Auto-generated client for Keycloak Admin REST API v1
# Source: https://api.apis.guru/v2/specs/keycloak.local/1/openapi.json
# Auth: --token flag or $env.KEYCLOAK_ADMIN_REST_API_TOKEN

const CLIENT = {
  base_url: "http://keycloak.local"
  token_env_var: "KEYCLOAK_ADMIN_REST_API_TOKEN"
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

def base-url-completer [] { ["http://keycloak.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def policy-completer [] { ["FAIL" "OVERWRITE" "SKIP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-op: "record<builtinProtocolMappers: record, clientImporters: list<record>, clientInstallations: record, componentTypes: record, enums: record, identityProviders: list<record>, memoryInfo: record<free: int, freeFormated: string, freePercentage: int, total: int, totalFormated: string, used: int, usedFormated: string>, passwordPolicies: table<configType: string, defaultValue: string, displayName: string, id: string, multipleSupported: bool>, profileInfo: record<disabledFeatures: list<string>, experimentalFeatures: list<string>, name: string, previewFeatures: list<string>>, protocolMapperTypes: record, providers: record, socialProviders: list<record>, systemInfo: record<fileEncoding: string, javaHome: string, javaRuntime: string, javaVendor: string, javaVersion: string, javaVm: string, javaVmVersion: string, osArchitecture: string, osName: string, osVersion: string, serverTime: string, uptime: string, uptimeMillis: int, userDir: string, userLocale: string, userName: string, userTimezone: string, version: string>, themes: record>"
    get-id-name: "record"
    get-realm: "record<accessCodeLifespan: int, accessCodeLifespanLogin: int, accessCodeLifespanUserAction: int, accessTokenLifespan: int, accessTokenLifespanForImplicitFlow: int, accountTheme: string, actionTokenGeneratedByAdminLifespan: int, actionTokenGeneratedByUserLifespan: int, adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, adminTheme: string, attributes: record, authenticationFlows: table<alias: string, authenticationExecutions: list, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>, authenticatorConfig: table<alias: string, config: record, id: string>, browserFlow: string, browserSecurityHeaders: record, bruteForceProtected: bool, clientAuthenticationFlow: string, clientScopeMappings: record, clientScopes: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list>, clientSessionIdleTimeout: int, clientSessionMaxLifespan: int, clients: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list, defaultRoles: list, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list, origin: string, protocol: string, protocolMappers: list, publicClient: bool, redirectUris: list, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list>, components: record<empty: bool, loadFactor: float, threshold: int>, defaultDefaultClientScopes: list<string>, defaultGroups: list<string>, defaultLocale: string, defaultOptionalClientScopes: list<string>, defaultRoles: list<string>, defaultSignatureAlgorithm: string, directGrantFlow: string, displayName: string, displayNameHtml: string, dockerAuthenticationFlow: string, duplicateEmailsAllowed: bool, editUsernameAllowed: bool, emailTheme: string, enabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>, failureFactor: int, federatedUsers: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, groups: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list, subGroups: list>, id: string, identityProviderMappers: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>, identityProviders: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>, internationalizationEnabled: bool, keycloakVersion: string, loginTheme: string, loginWithEmailAllowed: bool, maxDeltaTimeSeconds: int, maxFailureWaitSeconds: int, minimumQuickLoginWaitSeconds: int, notBefore: int, offlineSessionIdleTimeout: int, offlineSessionMaxLifespan: int, offlineSessionMaxLifespanEnabled: bool, otpPolicyAlgorithm: string, otpPolicyDigits: int, otpPolicyInitialCounter: int, otpPolicyLookAheadWindow: int, otpPolicyPeriod: int, otpPolicyType: string, otpSupportedApplications: list<string>, passwordPolicy: string, permanentLockout: bool, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, quickLoginCheckMilliSeconds: int, realm: string, refreshTokenMaxReuse: int, registrationAllowed: bool, registrationEmailAsUsername: bool, registrationFlow: string, rememberMe: bool, requiredActions: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>, resetCredentialsFlow: string, resetPasswordAllowed: bool, revokeRefreshToken: bool, roles: record<client: record, realm: list<record>>, scopeMappings: table<client: string, clientScope: string, roles: list, self: string>, smtpServer: record, sslRequired: string, ssoSessionIdleTimeout: int, ssoSessionIdleTimeoutRememberMe: int, ssoSessionMaxLifespan: int, ssoSessionMaxLifespanRememberMe: int, supportedLocales: list<string>, userFederationMappers: table<config: record, federationMapperType: string, federationProviderDisplayName: string, id: string, name: string>, userFederationProviders: table<changedSyncPeriod: int, config: record, displayName: string, fullSyncPeriod: int, id: string, lastSync: int, priority: int, providerName: string>, userManagedAccessAllowed: bool, users: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, verifyEmail: bool, waitIncrementSeconds: int, webAuthnPolicyAcceptableAaguids: list<string>, webAuthnPolicyAttestationConveyancePreference: string, webAuthnPolicyAuthenticatorAttachment: string, webAuthnPolicyAvoidSameAuthenticatorRegister: bool, webAuthnPolicyCreateTimeout: int, webAuthnPolicyPasswordlessAcceptableAaguids: list<string>, webAuthnPolicyPasswordlessAttestationConveyancePreference: string, webAuthnPolicyPasswordlessAuthenticatorAttachment: string, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: bool, webAuthnPolicyPasswordlessCreateTimeout: int, webAuthnPolicyPasswordlessRequireResidentKey: string, webAuthnPolicyPasswordlessRpEntityName: string, webAuthnPolicyPasswordlessRpId: string, webAuthnPolicyPasswordlessSignatureAlgorithms: list<string>, webAuthnPolicyPasswordlessUserVerificationRequirement: string, webAuthnPolicyRequireResidentKey: string, webAuthnPolicyRpEntityName: string, webAuthnPolicyRpId: string, webAuthnPolicySignatureAlgorithms: list<string>, webAuthnPolicyUserVerificationRequirement: string>"
    get-realm-admin-events: "table<authDetails: record<clientId: string, ipAddress: string, realmId: string, userId: string>, error: string, operationType: string, realmId: string, representation: string, resourcePath: string, resourceType: string, time: int>"
    get-realm-attack-detection-brute-force-users-user-id: "record"
    get-realm-authentication-authenticator-providers: "list<record>"
    get-realm-authentication-client-authenticator-providers: "list<record>"
    get-realm-authentication-config-description-provider-id: "record<helpText: string, name: string, properties: table<defaultValue: record, helpText: string, label: string, name: string, options: list, secret: bool, type: string>, providerId: string>"
    get-realm-authentication-config-id: "record<alias: string, config: record, id: string>"
    get-realm-authentication-flows: "table<alias: string, authenticationExecutions: list<record>, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>"
    get-realm-authentication-flows-id: "record<alias: string, authenticationExecutions: table<authenticator: string, authenticatorConfig: string, authenticatorFlow: bool, autheticatorFlow: bool, flowAlias: string, priority: int, requirement: string, userSetupAllowed: bool>, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>"
    get-realm-authentication-form-action-providers: "list<record>"
    get-realm-authentication-form-providers: "list<record>"
    get-realm-authentication-per-client-config-description: "record"
    get-realm-authentication-required-actions: "table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>"
    get-realm-authentication-required-actions-alias: "record<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>"
    get-realm-authentication-unregistered-required-actions: "list<record>"
    post-realm-client-description-converter: "record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>>"
    get-realm-client-registration-policy-providers: "table<helpText: string, id: string, metadata: record, properties: list<record>>"
    get-realm-client-scopes: "table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>"
    get-realm-client-scopes-id1-protocol-mappers-models-id2: "record<config: record, id: string, name: string, protocol: string, protocolMapper: string>"
    get-realm-client-scopes-id: "record<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>>"
    get-realm-client-scopes-id-protocol-mappers-models: "table<config: record, id: string, name: string, protocol: string, protocolMapper: string>"
    get-realm-client-scopes-id-protocol-mappers-protocol-protocol: "table<config: record, id: string, name: string, protocol: string, protocolMapper: string>"
    get-realm-client-scopes-id-scope-mappings: "record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>>"
    get-realm-client-scopes-id-scope-mappings-clients-client: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-client-scopes-id-scope-mappings-clients-client-available: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-client-scopes-id-scope-mappings-clients-client-composite: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-client-scopes-id-scope-mappings-realm: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-client-scopes-id-scope-mappings-realm-available: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-client-scopes-id-scope-mappings-realm-composite: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-client-session-stats: "list<record>"
    get-realm-clients: "table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list, policyEnforcementMode: string, resources: list, scopes: list>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: list<record>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>>"
    get-realm-clients-initial-access: "table<count: int, expiration: int, id: string, remainingCount: int, timestamp: int, token: string>"
    post-realm-clients-initial-access: "record<count: int, expiration: int, id: string, remainingCount: int, timestamp: int, token: string>"
    get-realm-clients-id1-protocol-mappers-models-id2: "record<config: record, id: string, name: string, protocol: string, protocolMapper: string>"
    get-realm-clients-id: "record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>>"
    get-realm-clients-id-certificates-attr: "record<certificate: string, kid: string, privateKey: string, publicKey: string>"
    post-realm-clients-id-certificates-attr-download: "string"
    post-realm-clients-id-certificates-attr-generate: "record<certificate: string, kid: string, privateKey: string, publicKey: string>"
    post-realm-clients-id-certificates-attr-generate-and-download: "string"
    post-realm-clients-id-certificates-attr-upload: "record<certificate: string, kid: string, privateKey: string, publicKey: string>"
    post-realm-clients-id-certificates-attr-upload-certificate: "record<certificate: string, kid: string, privateKey: string, publicKey: string>"
    get-realm-clients-id-client-secret: "record<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>"
    post-realm-clients-id-client-secret: "record<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>"
    get-realm-clients-id-default-client-scopes: "table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>"
    get-realm-clients-id-evaluate-scopes-generate-example-access-token: "record<acr: string, address: record<country: string, formatted: string, locality: string, postal_code: string, region: string, street_address: string>, allowed-origins: list<string>, at_hash: string, auth_time: int, authorization: record<permissions: list<record>>, azp: string, birthdate: string, c_hash: string, category: string, claims_locales: string, cnf: record<\"x5t#S256\": string>, email: string, email_verified: bool, exp: int, family_name: string, gender: string, given_name: string, iat: int, iss: string, jti: string, locale: string, middle_name: string, name: string, nbf: int, nickname: string, nonce: string, otherClaims: record, phone_number: string, phone_number_verified: bool, picture: string, preferred_username: string, profile: string, realm_access: record<roles: list<string>, verify_caller: bool>, s_hash: string, scope: string, session_state: string, sub: string, trusted-certs: list<string>, typ: string, updated_at: int, website: string, zoneinfo: string>"
    get-realm-clients-id-evaluate-scopes-protocol-mappers: "table<containerId: string, containerName: string, containerType: string, mapperId: string, mapperName: string, protocolMapper: string>"
    get-realm-clients-id-evaluate-scopes-scope-mappings-role-container-id-granted: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-evaluate-scopes-scope-mappings-role-container-id-not-granted: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    put-realm-clients-id-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    get-realm-clients-id-offline-session-count: "record"
    get-realm-clients-id-offline-sessions: "table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string>"
    get-realm-clients-id-optional-client-scopes: "table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>"
    get-realm-clients-id-protocol-mappers-models: "table<config: record, id: string, name: string, protocol: string, protocolMapper: string>"
    get-realm-clients-id-protocol-mappers-protocol-protocol: "table<config: record, id: string, name: string, protocol: string, protocolMapper: string>"
    post-realm-clients-id-push-revocation: "record<failedRequests: list<string>, successRequests: list<string>>"
    post-realm-clients-id-registration-access-token: "record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>>"
    get-realm-clients-id-roles: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-roles-role-name: "record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-roles-role-name-composites: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-roles-role-name-composites-clients-client: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-roles-role-name-composites-realm: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-roles-role-name-groups: "table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>"
    get-realm-clients-id-roles-role-name-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    put-realm-clients-id-roles-role-name-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    get-realm-clients-id-roles-role-name-users: "table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>"
    get-realm-clients-id-scope-mappings: "record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>>"
    get-realm-clients-id-scope-mappings-clients-client: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-scope-mappings-clients-client-available: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-scope-mappings-clients-client-composite: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-scope-mappings-realm: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-scope-mappings-realm-available: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-scope-mappings-realm-composite: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-clients-id-service-account-user: "record<access: record, attributes: record, clientConsents: table<clientId: string, createdDate: int, grantedClientScopes: list, lastUpdatedDate: int>, clientRoles: record, createdTimestamp: int, credentials: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: table<identityProvider: string, userId: string, userName: string>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>"
    get-realm-clients-id-session-count: "record"
    get-realm-clients-id-test-nodes-available: "record<failedRequests: list<string>, successRequests: list<string>>"
    get-realm-clients-id-user-sessions: "table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string>"
    get-realm-components: "table<config: record<empty: bool, loadFactor: float, threshold: int>, id: string, name: string, parentId: string, providerId: string, providerType: string, subType: string>"
    get-realm-components-id: "record<config: record<empty: bool, loadFactor: float, threshold: int>, id: string, name: string, parentId: string, providerId: string, providerType: string, subType: string>"
    get-realm-components-id-sub-component-types: "table<helpText: string, id: string, metadata: record, properties: list<record>>"
    get-realm-credential-registrators: "list<string>"
    get-realm-default-default-client-scopes: "table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>"
    get-realm-default-groups: "table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>"
    get-realm-default-optional-client-scopes: "table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>"
    get-realm-events: "table<clientId: string, details: record, error: string, ipAddress: string, realmId: string, sessionId: string, time: int, type: string, userId: string>"
    get-realm-events-config: "record<adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>>"
    get-realm-group-by-path-path: "record<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>"
    get-realm-groups: "table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>"
    get-realm-groups-count: "record"
    get-realm-groups-id: "record<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>"
    get-realm-groups-id-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    put-realm-groups-id-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    get-realm-groups-id-members: "table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>"
    get-realm-groups-id-role-mappings: "record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>>"
    get-realm-groups-id-role-mappings-clients-client: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-groups-id-role-mappings-clients-client-available: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-groups-id-role-mappings-clients-client-composite: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-groups-id-role-mappings-realm: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-groups-id-role-mappings-realm-available: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-groups-id-role-mappings-realm-composite: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    post-realm-identity-provider-import-config: "record"
    get-realm-identity-provider-instances: "table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>"
    get-realm-identity-provider-instances-alias: "record<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>"
    get-realm-identity-provider-instances-alias-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    put-realm-identity-provider-instances-alias-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    get-realm-identity-provider-instances-alias-mappers: "table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>"
    get-realm-identity-provider-instances-alias-mappers-id: "record<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>"
    get-realm-keys: "record<active: record, keys: table<algorithm: string, certificate: string, kid: string, providerId: string, providerPriority: int, publicKey: string, status: string, type: string>>"
    post-realm-partial-export: "record<accessCodeLifespan: int, accessCodeLifespanLogin: int, accessCodeLifespanUserAction: int, accessTokenLifespan: int, accessTokenLifespanForImplicitFlow: int, accountTheme: string, actionTokenGeneratedByAdminLifespan: int, actionTokenGeneratedByUserLifespan: int, adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, adminTheme: string, attributes: record, authenticationFlows: table<alias: string, authenticationExecutions: list, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>, authenticatorConfig: table<alias: string, config: record, id: string>, browserFlow: string, browserSecurityHeaders: record, bruteForceProtected: bool, clientAuthenticationFlow: string, clientScopeMappings: record, clientScopes: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list>, clientSessionIdleTimeout: int, clientSessionMaxLifespan: int, clients: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list, defaultRoles: list, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list, origin: string, protocol: string, protocolMappers: list, publicClient: bool, redirectUris: list, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list>, components: record<empty: bool, loadFactor: float, threshold: int>, defaultDefaultClientScopes: list<string>, defaultGroups: list<string>, defaultLocale: string, defaultOptionalClientScopes: list<string>, defaultRoles: list<string>, defaultSignatureAlgorithm: string, directGrantFlow: string, displayName: string, displayNameHtml: string, dockerAuthenticationFlow: string, duplicateEmailsAllowed: bool, editUsernameAllowed: bool, emailTheme: string, enabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>, failureFactor: int, federatedUsers: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, groups: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list, subGroups: list>, id: string, identityProviderMappers: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>, identityProviders: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>, internationalizationEnabled: bool, keycloakVersion: string, loginTheme: string, loginWithEmailAllowed: bool, maxDeltaTimeSeconds: int, maxFailureWaitSeconds: int, minimumQuickLoginWaitSeconds: int, notBefore: int, offlineSessionIdleTimeout: int, offlineSessionMaxLifespan: int, offlineSessionMaxLifespanEnabled: bool, otpPolicyAlgorithm: string, otpPolicyDigits: int, otpPolicyInitialCounter: int, otpPolicyLookAheadWindow: int, otpPolicyPeriod: int, otpPolicyType: string, otpSupportedApplications: list<string>, passwordPolicy: string, permanentLockout: bool, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, quickLoginCheckMilliSeconds: int, realm: string, refreshTokenMaxReuse: int, registrationAllowed: bool, registrationEmailAsUsername: bool, registrationFlow: string, rememberMe: bool, requiredActions: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>, resetCredentialsFlow: string, resetPasswordAllowed: bool, revokeRefreshToken: bool, roles: record<client: record, realm: list<record>>, scopeMappings: table<client: string, clientScope: string, roles: list, self: string>, smtpServer: record, sslRequired: string, ssoSessionIdleTimeout: int, ssoSessionIdleTimeoutRememberMe: int, ssoSessionMaxLifespan: int, ssoSessionMaxLifespanRememberMe: int, supportedLocales: list<string>, userFederationMappers: table<config: record, federationMapperType: string, federationProviderDisplayName: string, id: string, name: string>, userFederationProviders: table<changedSyncPeriod: int, config: record, displayName: string, fullSyncPeriod: int, id: string, lastSync: int, priority: int, providerName: string>, userManagedAccessAllowed: bool, users: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, verifyEmail: bool, waitIncrementSeconds: int, webAuthnPolicyAcceptableAaguids: list<string>, webAuthnPolicyAttestationConveyancePreference: string, webAuthnPolicyAuthenticatorAttachment: string, webAuthnPolicyAvoidSameAuthenticatorRegister: bool, webAuthnPolicyCreateTimeout: int, webAuthnPolicyPasswordlessAcceptableAaguids: list<string>, webAuthnPolicyPasswordlessAttestationConveyancePreference: string, webAuthnPolicyPasswordlessAuthenticatorAttachment: string, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: bool, webAuthnPolicyPasswordlessCreateTimeout: int, webAuthnPolicyPasswordlessRequireResidentKey: string, webAuthnPolicyPasswordlessRpEntityName: string, webAuthnPolicyPasswordlessRpId: string, webAuthnPolicyPasswordlessSignatureAlgorithms: list<string>, webAuthnPolicyPasswordlessUserVerificationRequirement: string, webAuthnPolicyRequireResidentKey: string, webAuthnPolicyRpEntityName: string, webAuthnPolicyRpId: string, webAuthnPolicySignatureAlgorithms: list<string>, webAuthnPolicyUserVerificationRequirement: string>"
    get-realm-roles: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-by-id-role-id: "record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-by-id-role-id-composites: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-by-id-role-id-composites-clients-client: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-by-id-role-id-composites-realm: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-by-id-role-id-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    put-realm-roles-by-id-role-id-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    get-realm-roles-role-name: "record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-role-name-composites: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-role-name-composites-clients-client: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-role-name-composites-realm: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-roles-role-name-groups: "table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>"
    get-realm-roles-role-name-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    put-realm-roles-role-name-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    get-realm-roles-role-name-users: "table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>"
    get-realm-user-storage-id-name: "record"
    post-realm-user-storage-id-sync: "record<added: int, failed: int, ignored: bool, removed: int, status: string, updated: int>"
    post-realm-user-storage-parent-id-mappers-id-sync: "record<added: int, failed: int, ignored: bool, removed: int, status: string, updated: int>"
    get-realm-users: "table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>"
    get-realm-users-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    put-realm-users-management-permissions: "record<enabled: bool, resource: string, scopePermissions: record>"
    get-realm-users-count: "int"
    get-realm-users-id: "record<access: record, attributes: record, clientConsents: table<clientId: string, createdDate: int, grantedClientScopes: list, lastUpdatedDate: int>, clientRoles: record, createdTimestamp: int, credentials: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: table<identityProvider: string, userId: string, userName: string>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>"
    get-realm-users-id-configured-user-storage-credential-types: "list<string>"
    get-realm-users-id-consents: "list<record>"
    get-realm-users-id-credentials: "table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>"
    get-realm-users-id-federated-identity: "table<identityProvider: string, userId: string, userName: string>"
    get-realm-users-id-groups: "table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>"
    get-realm-users-id-groups-count: "record"
    post-realm-users-id-impersonation: "record"
    get-realm-users-id-offline-sessions-client-id: "table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string>"
    get-realm-users-id-role-mappings: "record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>>"
    get-realm-users-id-role-mappings-clients-client: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-users-id-role-mappings-clients-client-available: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-users-id-role-mappings-clients-client-composite: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-users-id-role-mappings-realm: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-users-id-role-mappings-realm-available: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-users-id-role-mappings-realm-composite: "table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>"
    get-realm-users-id-sessions: "table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-op" "post" "get-id-name" "delete-realm" "get-realm" "put-realm" "delete-realm-admin-events" "get-realm-admin-events" "delete-realm-attack-detection-brute-force-users" "delete-realm-attack-detection-brute-force-users-user-id" "get-realm-attack-detection-brute-force-users-user-id" "get-realm-authentication-authenticator-providers" "get-realm-authentication-client-authenticator-providers" "get-realm-authentication-config-description-provider-id" "delete-realm-authentication-config-id" "get-realm-authentication-config-id" "put-realm-authentication-config-id" "post-realm-authentication-executions" "delete-realm-authentication-executions-execution-id" "get-realm-authentication-executions-execution-id" "post-realm-authentication-executions-execution-id-config" "post-realm-authentication-executions-execution-id-lower-priority" "post-realm-authentication-executions-execution-id-raise-priority" "get-realm-authentication-flows" "post-realm-authentication-flows" "post-realm-authentication-flows-flow-alias-copy" "get-realm-authentication-flows-flow-alias-executions" "put-realm-authentication-flows-flow-alias-executions" "post-realm-authentication-flows-flow-alias-executions-execution" "post-realm-authentication-flows-flow-alias-executions-flow" "delete-realm-authentication-flows-id" "get-realm-authentication-flows-id" "put-realm-authentication-flows-id" "get-realm-authentication-form-action-providers" "get-realm-authentication-form-providers" "get-realm-authentication-per-client-config-description" "post-realm-authentication-register-required-action" "get-realm-authentication-required-actions" "delete-realm-authentication-required-actions-alias" "get-realm-authentication-required-actions-alias" "put-realm-authentication-required-actions-alias" "post-realm-authentication-required-actions-alias-lower-priority" "post-realm-authentication-required-actions-alias-raise-priority" "get-realm-authentication-unregistered-required-actions" "post-realm-clear-keys-cache" "post-realm-clear-realm-cache" "post-realm-clear-user-cache" "post-realm-client-description-converter" "get-realm-client-registration-policy-providers" "get-realm-client-scopes" "post-realm-client-scopes" "delete-realm-client-scopes-id1-protocol-mappers-models-id2" "get-realm-client-scopes-id1-protocol-mappers-models-id2" "put-realm-client-scopes-id1-protocol-mappers-models-id2" "delete-realm-client-scopes-id" "get-realm-client-scopes-id" "put-realm-client-scopes-id" "post-realm-client-scopes-id-protocol-mappers-add-models" "get-realm-client-scopes-id-protocol-mappers-models" "post-realm-client-scopes-id-protocol-mappers-models" "get-realm-client-scopes-id-protocol-mappers-protocol-protocol" "get-realm-client-scopes-id-scope-mappings" "delete-realm-client-scopes-id-scope-mappings-clients-client" "get-realm-client-scopes-id-scope-mappings-clients-client" "post-realm-client-scopes-id-scope-mappings-clients-client" "get-realm-client-scopes-id-scope-mappings-clients-client-available" "get-realm-client-scopes-id-scope-mappings-clients-client-composite" "delete-realm-client-scopes-id-scope-mappings-realm" "get-realm-client-scopes-id-scope-mappings-realm" "post-realm-client-scopes-id-scope-mappings-realm" "get-realm-client-scopes-id-scope-mappings-realm-available" "get-realm-client-scopes-id-scope-mappings-realm-composite" "get-realm-client-session-stats" "get-realm-clients" "post-realm-clients" "get-realm-clients-initial-access" "post-realm-clients-initial-access" "delete-realm-clients-initial-access-id" "delete-realm-clients-id1-protocol-mappers-models-id2" "get-realm-clients-id1-protocol-mappers-models-id2" "put-realm-clients-id1-protocol-mappers-models-id2" "delete-realm-clients-id" "get-realm-clients-id" "put-realm-clients-id" "get-realm-clients-id-certificates-attr" "post-realm-clients-id-certificates-attr-download" "post-realm-clients-id-certificates-attr-generate" "post-realm-clients-id-certificates-attr-generate-and-download" "post-realm-clients-id-certificates-attr-upload" "post-realm-clients-id-certificates-attr-upload-certificate" "get-realm-clients-id-client-secret" "post-realm-clients-id-client-secret" "get-realm-clients-id-default-client-scopes" "delete-realm-clients-id-default-client-scopes-client-scope-id" "put-realm-clients-id-default-client-scopes-client-scope-id" "get-realm-clients-id-evaluate-scopes-generate-example-access-token" "get-realm-clients-id-evaluate-scopes-protocol-mappers" "get-realm-clients-id-evaluate-scopes-scope-mappings-role-container-id-granted" "get-realm-clients-id-evaluate-scopes-scope-mappings-role-container-id-not-granted" "get-realm-clients-id-installation-providers-provider-id" "get-realm-clients-id-management-permissions" "put-realm-clients-id-management-permissions" "post-realm-clients-id-nodes" "delete-realm-clients-id-nodes-node" "get-realm-clients-id-offline-session-count" "get-realm-clients-id-offline-sessions" "get-realm-clients-id-optional-client-scopes" "delete-realm-clients-id-optional-client-scopes-client-scope-id" "put-realm-clients-id-optional-client-scopes-client-scope-id" "post-realm-clients-id-protocol-mappers-add-models" "get-realm-clients-id-protocol-mappers-models" "post-realm-clients-id-protocol-mappers-models" "get-realm-clients-id-protocol-mappers-protocol-protocol" "post-realm-clients-id-push-revocation" "post-realm-clients-id-registration-access-token" "get-realm-clients-id-roles" "post-realm-clients-id-roles" "delete-realm-clients-id-roles-role-name" "get-realm-clients-id-roles-role-name" "put-realm-clients-id-roles-role-name" "delete-realm-clients-id-roles-role-name-composites" "get-realm-clients-id-roles-role-name-composites" "post-realm-clients-id-roles-role-name-composites" "get-realm-clients-id-roles-role-name-composites-clients-client" "get-realm-clients-id-roles-role-name-composites-realm" "get-realm-clients-id-roles-role-name-groups" "get-realm-clients-id-roles-role-name-management-permissions" "put-realm-clients-id-roles-role-name-management-permissions" "get-realm-clients-id-roles-role-name-users" "get-realm-clients-id-scope-mappings" "delete-realm-clients-id-scope-mappings-clients-client" "get-realm-clients-id-scope-mappings-clients-client" "post-realm-clients-id-scope-mappings-clients-client" "get-realm-clients-id-scope-mappings-clients-client-available" "get-realm-clients-id-scope-mappings-clients-client-composite" "delete-realm-clients-id-scope-mappings-realm" "get-realm-clients-id-scope-mappings-realm" "post-realm-clients-id-scope-mappings-realm" "get-realm-clients-id-scope-mappings-realm-available" "get-realm-clients-id-scope-mappings-realm-composite" "get-realm-clients-id-service-account-user" "get-realm-clients-id-session-count" "get-realm-clients-id-test-nodes-available" "get-realm-clients-id-user-sessions" "get-realm-components" "post-realm-components" "delete-realm-components-id" "get-realm-components-id" "put-realm-components-id" "get-realm-components-id-sub-component-types" "get-realm-credential-registrators" "get-realm-default-default-client-scopes" "delete-realm-default-default-client-scopes-client-scope-id" "put-realm-default-default-client-scopes-client-scope-id" "get-realm-default-groups" "delete-realm-default-groups-group-id" "put-realm-default-groups-group-id" "get-realm-default-optional-client-scopes" "delete-realm-default-optional-client-scopes-client-scope-id" "put-realm-default-optional-client-scopes-client-scope-id" "delete-realm-events" "get-realm-events" "get-realm-events-config" "put-realm-events-config" "get-realm-group-by-path-path" "get-realm-groups" "post-realm-groups" "get-realm-groups-count" "delete-realm-groups-id" "get-realm-groups-id" "put-realm-groups-id" "post-realm-groups-id-children" "get-realm-groups-id-management-permissions" "put-realm-groups-id-management-permissions" "get-realm-groups-id-members" "get-realm-groups-id-role-mappings" "delete-realm-groups-id-role-mappings-clients-client" "get-realm-groups-id-role-mappings-clients-client" "post-realm-groups-id-role-mappings-clients-client" "get-realm-groups-id-role-mappings-clients-client-available" "get-realm-groups-id-role-mappings-clients-client-composite" "delete-realm-groups-id-role-mappings-realm" "get-realm-groups-id-role-mappings-realm" "post-realm-groups-id-role-mappings-realm" "get-realm-groups-id-role-mappings-realm-available" "get-realm-groups-id-role-mappings-realm-composite" "post-realm-identity-provider-import-config" "get-realm-identity-provider-instances" "post-realm-identity-provider-instances" "delete-realm-identity-provider-instances-alias" "get-realm-identity-provider-instances-alias" "put-realm-identity-provider-instances-alias" "get-realm-identity-provider-instances-alias-export" "get-realm-identity-provider-instances-alias-management-permissions" "put-realm-identity-provider-instances-alias-management-permissions" "get-realm-identity-provider-instances-alias-mapper-types" "get-realm-identity-provider-instances-alias-mappers" "post-realm-identity-provider-instances-alias-mappers" "delete-realm-identity-provider-instances-alias-mappers-id" "get-realm-identity-provider-instances-alias-mappers-id" "put-realm-identity-provider-instances-alias-mappers-id" "get-realm-identity-provider-providers-provider-id" "get-realm-keys" "post-realm-logout-all" "post-realm-partial-export" "post-realm-partial-import" "post-realm-push-revocation" "get-realm-roles" "post-realm-roles" "delete-realm-roles-by-id-role-id" "get-realm-roles-by-id-role-id" "put-realm-roles-by-id-role-id" "delete-realm-roles-by-id-role-id-composites" "get-realm-roles-by-id-role-id-composites" "post-realm-roles-by-id-role-id-composites" "get-realm-roles-by-id-role-id-composites-clients-client" "get-realm-roles-by-id-role-id-composites-realm" "get-realm-roles-by-id-role-id-management-permissions" "put-realm-roles-by-id-role-id-management-permissions" "delete-realm-roles-role-name" "get-realm-roles-role-name" "put-realm-roles-role-name" "delete-realm-roles-role-name-composites" "get-realm-roles-role-name-composites" "post-realm-roles-role-name-composites" "get-realm-roles-role-name-composites-clients-client" "get-realm-roles-role-name-composites-realm" "get-realm-roles-role-name-groups" "get-realm-roles-role-name-management-permissions" "put-realm-roles-role-name-management-permissions" "get-realm-roles-role-name-users" "delete-realm-sessions-session" "post-realm-test-ldap-connection" "post-realm-test-smtp-connection" "get-realm-user-storage-id-name" "post-realm-user-storage-id-remove-imported-users" "post-realm-user-storage-id-sync" "post-realm-user-storage-id-unlink-users" "post-realm-user-storage-parent-id-mappers-id-sync" "get-realm-users" "post-realm-users" "get-realm-users-management-permissions" "put-realm-users-management-permissions" "get-realm-users-count" "delete-realm-users-id" "get-realm-users-id" "put-realm-users-id" "get-realm-users-id-configured-user-storage-credential-types" "get-realm-users-id-consents" "delete-realm-users-id-consents-client" "get-realm-users-id-credentials" "delete-realm-users-id-credentials-credential-id" "post-realm-users-id-credentials-credential-id-move-after-new-previous-credential-id" "post-realm-users-id-credentials-credential-id-move-to-first" "put-realm-users-id-credentials-credential-id-user-label" "put-realm-users-id-disable-credential-types" "put-realm-users-id-execute-actions-email" "get-realm-users-id-federated-identity" "delete-realm-users-id-federated-identity-provider" "post-realm-users-id-federated-identity-provider" "get-realm-users-id-groups" "get-realm-users-id-groups-count" "delete-realm-users-id-groups-group-id" "put-realm-users-id-groups-group-id" "post-realm-users-id-impersonation" "post-realm-users-id-logout" "get-realm-users-id-offline-sessions-client-id" "put-realm-users-id-reset-password" "get-realm-users-id-role-mappings" "delete-realm-users-id-role-mappings-clients-client" "get-realm-users-id-role-mappings-clients-client" "post-realm-users-id-role-mappings-clients-client" "get-realm-users-id-role-mappings-clients-client-available" "get-realm-users-id-role-mappings-clients-client-composite" "delete-realm-users-id-role-mappings-realm" "get-realm-users-id-role-mappings-realm" "post-realm-users-id-role-mappings-realm" "get-realm-users-id-role-mappings-realm-available" "get-realm-users-id-role-mappings-realm-composite" "put-realm-users-id-send-verify-email" "get-realm-users-id-sessions" "commands"] | sort) } | get name | first)
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

# Get themes, social providers, auth providers, and event listeners available on this server
#
# GET /
# Returns: record<builtinProtocolMappers: record, clientImporters: list<record>, clientInstallations: record, componentTypes: record, enums: record, identityProviders: list<record>, memoryInfo: record<free: int, freeFormated: string, freePercentage: int, total: int, totalFormated: string, used: int, usedFormated: string>, passwordPolicies: table<configType: string, defaultValue: string, displayName: string, id: string, multipleSupported: bool>, profileInfo: record<disabledFeatures: list<string>, experimentalFeatures: list<string>, name: string, previewFeatures: list<string>>, protocolMapperTypes: record, providers: record, socialProviders: list<record>, systemInfo: record<fileEncoding: string, javaHome: string, javaRuntime: string, javaVendor: string, javaVersion: string, javaVm: string, javaVmVersion: string, osArchitecture: string, osName: string, osVersion: string, serverTime: string, uptime: string, uptimeMillis: int, userDir: string, userLocale: string, userName: string, userTimezone: string, version: string>, themes: record>
export def "get-op" [
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
    path: "/"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a realm Imports a realm from a full representation of that realm.
#
# POST /
export def "post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-code-lifespan: int # format: int32
  --access-code-lifespan-login: int # format: int32
  --access-code-lifespan-user-action: int # format: int32
  --access-token-lifespan: int # format: int32
  --access-token-lifespan-for-implicit-flow: int # format: int32
  --account-theme: string
  --action-token-generated-by-admin-lifespan: int # format: int32
  --action-token-generated-by-user-lifespan: int # format: int32
  --admin-events-details-enabled: oneof<nothing, bool>
  --admin-events-enabled: oneof<nothing, bool>
  --admin-theme: string
  --attributes: record
  --authentication-flows: list # item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
  --authenticator-config: list # item shape: {alias?: string, config?: record, id?: string}
  --browser-flow: string
  --browser-security-headers: record
  --brute-force-protected: oneof<nothing, bool>
  --client-authentication-flow: string
  --client-scope-mappings: record
  --client-scopes: list # item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
  --client-session-idle-timeout: int # format: int32
  --client-session-max-lifespan: int # format: int32
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
  --components: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --default-default-client-scopes: list<string>
  --default-groups: list<string>
  --default-locale: string
  --default-optional-client-scopes: list<string>
  --default-roles: list<string>
  --default-signature-algorithm: string
  --direct-grant-flow: string
  --display-name: string
  --display-name-html: string
  --docker-authentication-flow: string
  --duplicate-emails-allowed: oneof<nothing, bool>
  --edit-username-allowed: oneof<nothing, bool>
  --email-theme: string
  --enabled: oneof<nothing, bool>
  --enabled-event-types: list<string>
  --events-enabled: oneof<nothing, bool>
  --events-expiration: int # format: int64
  --events-listeners: list<string>
  --failure-factor: int # format: int32
  --federated-users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
  --id: string
  --identity-provider-mappers: list # item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
  --identity-providers: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --internationalization-enabled: oneof<nothing, bool>
  --keycloak-version: string
  --login-theme: string
  --login-with-email-allowed: oneof<nothing, bool>
  --max-delta-time-seconds: int # format: int32
  --max-failure-wait-seconds: int # format: int32
  --minimum-quick-login-wait-seconds: int # format: int32
  --not-before: int # format: int32
  --offline-session-idle-timeout: int # format: int32
  --offline-session-max-lifespan: int # format: int32
  --offline-session-max-lifespan-enabled: oneof<nothing, bool>
  --otp-policy-algorithm: string
  --otp-policy-digits: int # format: int32
  --otp-policy-initial-counter: int # format: int32
  --otp-policy-look-ahead-window: int # format: int32
  --otp-policy-period: int # format: int32
  --otp-policy-type: string
  --otp-supported-applications: list<string>
  --password-policy: string
  --permanent-lockout: oneof<nothing, bool>
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --quick-login-check-milli-seconds: int # format: int64
  --realm: string
  --refresh-token-max-reuse: int # format: int32
  --registration-allowed: oneof<nothing, bool>
  --registration-email-as-username: oneof<nothing, bool>
  --registration-flow: string
  --remember-me: oneof<nothing, bool>
  --required-actions: list # item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
  --reset-credentials-flow: string
  --reset-password-allowed: oneof<nothing, bool>
  --revoke-refresh-token: oneof<nothing, bool>
  --roles: record # shape: {client?: record, realm?: list}
  --scope-mappings: list # item shape: {client?: string, clientScope?: string, roles?: list<string>, self?: string}
  --smtp-server: record
  --ssl-required: string
  --sso-session-idle-timeout: int # format: int32
  --sso-session-idle-timeout-remember-me: int # format: int32
  --sso-session-max-lifespan: int # format: int32
  --sso-session-max-lifespan-remember-me: int # format: int32
  --supported-locales: list<string>
  --user-federation-mappers: list # item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
  --user-federation-providers: list # item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
  --user-managed-access-allowed: oneof<nothing, bool>
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
  --verify-email: oneof<nothing, bool>
  --wait-increment-seconds: int # format: int32
  --web-authn-policy-acceptable-aaguids: list<string>
  --web-authn-policy-attestation-conveyance-preference: string
  --web-authn-policy-authenticator-attachment: string
  --web-authn-policy-avoid-same-authenticator-register: oneof<nothing, bool>
  --web-authn-policy-create-timeout: int # format: int32
  --web-authn-policy-passwordless-acceptable-aaguids: list<string>
  --web-authn-policy-passwordless-attestation-conveyance-preference: string
  --web-authn-policy-passwordless-authenticator-attachment: string
  --web-authn-policy-passwordless-avoid-same-authenticator-register: oneof<nothing, bool>
  --web-authn-policy-passwordless-create-timeout: int # format: int32
  --web-authn-policy-passwordless-require-resident-key: string
  --web-authn-policy-passwordless-rp-entity-name: string
  --web-authn-policy-passwordless-rp-id: string
  --web-authn-policy-passwordless-signature-algorithms: list<string>
  --web-authn-policy-passwordless-user-verification-requirement: string
  --web-authn-policy-require-resident-key: string
  --web-authn-policy-rp-entity-name: string
  --web-authn-policy-rp-id: string
  --web-authn-policy-signature-algorithms: list<string>
  --web-authn-policy-user-verification-requirement: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    body: {content_type: "application/json", kind: json, fields: [{name: accessCodeLifespan, var: access_code_lifespan}, {name: accessCodeLifespanLogin, var: access_code_lifespan_login}, {name: accessCodeLifespanUserAction, var: access_code_lifespan_user_action}, {name: accessTokenLifespan, var: access_token_lifespan}, {name: accessTokenLifespanForImplicitFlow, var: access_token_lifespan_for_implicit_flow}, {name: accountTheme, var: account_theme}, {name: actionTokenGeneratedByAdminLifespan, var: action_token_generated_by_admin_lifespan}, {name: actionTokenGeneratedByUserLifespan, var: action_token_generated_by_user_lifespan}, {name: adminEventsDetailsEnabled, var: admin_events_details_enabled}, {name: adminEventsEnabled, var: admin_events_enabled}, {name: adminTheme, var: admin_theme}, {name: attributes, var: attributes}, {name: authenticationFlows, var: authentication_flows}, {name: authenticatorConfig, var: authenticator_config}, {name: browserFlow, var: browser_flow}, {name: browserSecurityHeaders, var: browser_security_headers}, {name: bruteForceProtected, var: brute_force_protected}, {name: clientAuthenticationFlow, var: client_authentication_flow}, {name: clientScopeMappings, var: client_scope_mappings}, {name: clientScopes, var: client_scopes}, {name: clientSessionIdleTimeout, var: client_session_idle_timeout}, {name: clientSessionMaxLifespan, var: client_session_max_lifespan}, {name: clients, var: clients}, {name: components, var: components}, {name: defaultDefaultClientScopes, var: default_default_client_scopes}, {name: defaultGroups, var: default_groups}, {name: defaultLocale, var: default_locale}, {name: defaultOptionalClientScopes, var: default_optional_client_scopes}, {name: defaultRoles, var: default_roles}, {name: defaultSignatureAlgorithm, var: default_signature_algorithm}, {name: directGrantFlow, var: direct_grant_flow}, {name: displayName, var: display_name}, {name: displayNameHtml, var: display_name_html}, {name: dockerAuthenticationFlow, var: docker_authentication_flow}, {name: duplicateEmailsAllowed, var: duplicate_emails_allowed}, {name: editUsernameAllowed, var: edit_username_allowed}, {name: emailTheme, var: email_theme}, {name: enabled, var: enabled}, {name: enabledEventTypes, var: enabled_event_types}, {name: eventsEnabled, var: events_enabled}, {name: eventsExpiration, var: events_expiration}, {name: eventsListeners, var: events_listeners}, {name: failureFactor, var: failure_factor}, {name: federatedUsers, var: federated_users}, {name: groups, var: groups}, {name: id, var: id}, {name: identityProviderMappers, var: identity_provider_mappers}, {name: identityProviders, var: identity_providers}, {name: internationalizationEnabled, var: internationalization_enabled}, {name: keycloakVersion, var: keycloak_version}, {name: loginTheme, var: login_theme}, {name: loginWithEmailAllowed, var: login_with_email_allowed}, {name: maxDeltaTimeSeconds, var: max_delta_time_seconds}, {name: maxFailureWaitSeconds, var: max_failure_wait_seconds}, {name: minimumQuickLoginWaitSeconds, var: minimum_quick_login_wait_seconds}, {name: notBefore, var: not_before}, {name: offlineSessionIdleTimeout, var: offline_session_idle_timeout}, {name: offlineSessionMaxLifespan, var: offline_session_max_lifespan}, {name: offlineSessionMaxLifespanEnabled, var: offline_session_max_lifespan_enabled}, {name: otpPolicyAlgorithm, var: otp_policy_algorithm}, {name: otpPolicyDigits, var: otp_policy_digits}, {name: otpPolicyInitialCounter, var: otp_policy_initial_counter}, {name: otpPolicyLookAheadWindow, var: otp_policy_look_ahead_window}, {name: otpPolicyPeriod, var: otp_policy_period}, {name: otpPolicyType, var: otp_policy_type}, {name: otpSupportedApplications, var: otp_supported_applications}, {name: passwordPolicy, var: password_policy}, {name: permanentLockout, var: permanent_lockout}, {name: protocolMappers, var: protocol_mappers}, {name: quickLoginCheckMilliSeconds, var: quick_login_check_milli_seconds}, {name: realm, var: realm}, {name: refreshTokenMaxReuse, var: refresh_token_max_reuse}, {name: registrationAllowed, var: registration_allowed}, {name: registrationEmailAsUsername, var: registration_email_as_username}, {name: registrationFlow, var: registration_flow}, {name: rememberMe, var: remember_me}, {name: requiredActions, var: required_actions}, {name: resetCredentialsFlow, var: reset_credentials_flow}, {name: resetPasswordAllowed, var: reset_password_allowed}, {name: revokeRefreshToken, var: revoke_refresh_token}, {name: roles, var: roles}, {name: scopeMappings, var: scope_mappings}, {name: smtpServer, var: smtp_server}, {name: sslRequired, var: ssl_required}, {name: ssoSessionIdleTimeout, var: sso_session_idle_timeout}, {name: ssoSessionIdleTimeoutRememberMe, var: sso_session_idle_timeout_remember_me}, {name: ssoSessionMaxLifespan, var: sso_session_max_lifespan}, {name: ssoSessionMaxLifespanRememberMe, var: sso_session_max_lifespan_remember_me}, {name: supportedLocales, var: supported_locales}, {name: userFederationMappers, var: user_federation_mappers}, {name: userFederationProviders, var: user_federation_providers}, {name: userManagedAccessAllowed, var: user_managed_access_allowed}, {name: users, var: users}, {name: verifyEmail, var: verify_email}, {name: waitIncrementSeconds, var: wait_increment_seconds}, {name: webAuthnPolicyAcceptableAaguids, var: web_authn_policy_acceptable_aaguids}, {name: webAuthnPolicyAttestationConveyancePreference, var: web_authn_policy_attestation_conveyance_preference}, {name: webAuthnPolicyAuthenticatorAttachment, var: web_authn_policy_authenticator_attachment}, {name: webAuthnPolicyAvoidSameAuthenticatorRegister, var: web_authn_policy_avoid_same_authenticator_register}, {name: webAuthnPolicyCreateTimeout, var: web_authn_policy_create_timeout}, {name: webAuthnPolicyPasswordlessAcceptableAaguids, var: web_authn_policy_passwordless_acceptable_aaguids}, {name: webAuthnPolicyPasswordlessAttestationConveyancePreference, var: web_authn_policy_passwordless_attestation_conveyance_preference}, {name: webAuthnPolicyPasswordlessAuthenticatorAttachment, var: web_authn_policy_passwordless_authenticator_attachment}, {name: webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister, var: web_authn_policy_passwordless_avoid_same_authenticator_register}, {name: webAuthnPolicyPasswordlessCreateTimeout, var: web_authn_policy_passwordless_create_timeout}, {name: webAuthnPolicyPasswordlessRequireResidentKey, var: web_authn_policy_passwordless_require_resident_key}, {name: webAuthnPolicyPasswordlessRpEntityName, var: web_authn_policy_passwordless_rp_entity_name}, {name: webAuthnPolicyPasswordlessRpId, var: web_authn_policy_passwordless_rp_id}, {name: webAuthnPolicyPasswordlessSignatureAlgorithms, var: web_authn_policy_passwordless_signature_algorithms}, {name: webAuthnPolicyPasswordlessUserVerificationRequirement, var: web_authn_policy_passwordless_user_verification_requirement}, {name: webAuthnPolicyRequireResidentKey, var: web_authn_policy_require_resident_key}, {name: webAuthnPolicyRpEntityName, var: web_authn_policy_rp_entity_name}, {name: webAuthnPolicyRpId, var: web_authn_policy_rp_id}, {name: webAuthnPolicySignatureAlgorithms, var: web_authn_policy_signature_algorithms}, {name: webAuthnPolicyUserVerificationRequirement, var: web_authn_policy_user_verification_requirement}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    access_code_lifespan: $access_code_lifespan, access_code_lifespan_login: $access_code_lifespan_login, access_code_lifespan_user_action: $access_code_lifespan_user_action, access_token_lifespan: $access_token_lifespan, access_token_lifespan_for_implicit_flow: $access_token_lifespan_for_implicit_flow, account_theme: $account_theme, action_token_generated_by_admin_lifespan: $action_token_generated_by_admin_lifespan, action_token_generated_by_user_lifespan: $action_token_generated_by_user_lifespan, admin_events_details_enabled: $admin_events_details_enabled, admin_events_enabled: $admin_events_enabled, admin_theme: $admin_theme, attributes: $attributes, authentication_flows: $authentication_flows, authenticator_config: $authenticator_config, browser_flow: $browser_flow, browser_security_headers: $browser_security_headers, brute_force_protected: $brute_force_protected, client_authentication_flow: $client_authentication_flow, client_scope_mappings: $client_scope_mappings, client_scopes: $client_scopes, client_session_idle_timeout: $client_session_idle_timeout, client_session_max_lifespan: $client_session_max_lifespan, clients: $clients, components: $components, default_default_client_scopes: $default_default_client_scopes, default_groups: $default_groups, default_locale: $default_locale, default_optional_client_scopes: $default_optional_client_scopes, default_roles: $default_roles, default_signature_algorithm: $default_signature_algorithm, direct_grant_flow: $direct_grant_flow, display_name: $display_name, display_name_html: $display_name_html, docker_authentication_flow: $docker_authentication_flow, duplicate_emails_allowed: $duplicate_emails_allowed, edit_username_allowed: $edit_username_allowed, email_theme: $email_theme, enabled: $enabled, enabled_event_types: $enabled_event_types, events_enabled: $events_enabled, events_expiration: $events_expiration, events_listeners: $events_listeners, failure_factor: $failure_factor, federated_users: $federated_users, groups: $groups, id: $id, identity_provider_mappers: $identity_provider_mappers, identity_providers: $identity_providers, internationalization_enabled: $internationalization_enabled, keycloak_version: $keycloak_version, login_theme: $login_theme, login_with_email_allowed: $login_with_email_allowed, max_delta_time_seconds: $max_delta_time_seconds, max_failure_wait_seconds: $max_failure_wait_seconds, minimum_quick_login_wait_seconds: $minimum_quick_login_wait_seconds, not_before: $not_before, offline_session_idle_timeout: $offline_session_idle_timeout, offline_session_max_lifespan: $offline_session_max_lifespan, offline_session_max_lifespan_enabled: $offline_session_max_lifespan_enabled, otp_policy_algorithm: $otp_policy_algorithm, otp_policy_digits: $otp_policy_digits, otp_policy_initial_counter: $otp_policy_initial_counter, otp_policy_look_ahead_window: $otp_policy_look_ahead_window, otp_policy_period: $otp_policy_period, otp_policy_type: $otp_policy_type, otp_supported_applications: $otp_supported_applications, password_policy: $password_policy, permanent_lockout: $permanent_lockout, protocol_mappers: $protocol_mappers, quick_login_check_milli_seconds: $quick_login_check_milli_seconds, realm: $realm, refresh_token_max_reuse: $refresh_token_max_reuse, registration_allowed: $registration_allowed, registration_email_as_username: $registration_email_as_username, registration_flow: $registration_flow, remember_me: $remember_me, required_actions: $required_actions, reset_credentials_flow: $reset_credentials_flow, reset_password_allowed: $reset_password_allowed, revoke_refresh_token: $revoke_refresh_token, roles: $roles, scope_mappings: $scope_mappings, smtp_server: $smtp_server, ssl_required: $ssl_required, sso_session_idle_timeout: $sso_session_idle_timeout, sso_session_idle_timeout_remember_me: $sso_session_idle_timeout_remember_me, sso_session_max_lifespan: $sso_session_max_lifespan, sso_session_max_lifespan_remember_me: $sso_session_max_lifespan_remember_me, supported_locales: $supported_locales, user_federation_mappers: $user_federation_mappers, user_federation_providers: $user_federation_providers, user_managed_access_allowed: $user_managed_access_allowed, users: $users, verify_email: $verify_email, wait_increment_seconds: $wait_increment_seconds, web_authn_policy_acceptable_aaguids: $web_authn_policy_acceptable_aaguids, web_authn_policy_attestation_conveyance_preference: $web_authn_policy_attestation_conveyance_preference, web_authn_policy_authenticator_attachment: $web_authn_policy_authenticator_attachment, web_authn_policy_avoid_same_authenticator_register: $web_authn_policy_avoid_same_authenticator_register, web_authn_policy_create_timeout: $web_authn_policy_create_timeout, web_authn_policy_passwordless_acceptable_aaguids: $web_authn_policy_passwordless_acceptable_aaguids, web_authn_policy_passwordless_attestation_conveyance_preference: $web_authn_policy_passwordless_attestation_conveyance_preference, web_authn_policy_passwordless_authenticator_attachment: $web_authn_policy_passwordless_authenticator_attachment, web_authn_policy_passwordless_avoid_same_authenticator_register: $web_authn_policy_passwordless_avoid_same_authenticator_register, web_authn_policy_passwordless_create_timeout: $web_authn_policy_passwordless_create_timeout, web_authn_policy_passwordless_require_resident_key: $web_authn_policy_passwordless_require_resident_key, web_authn_policy_passwordless_rp_entity_name: $web_authn_policy_passwordless_rp_entity_name, web_authn_policy_passwordless_rp_id: $web_authn_policy_passwordless_rp_id, web_authn_policy_passwordless_signature_algorithms: $web_authn_policy_passwordless_signature_algorithms, web_authn_policy_passwordless_user_verification_requirement: $web_authn_policy_passwordless_user_verification_requirement, web_authn_policy_require_resident_key: $web_authn_policy_require_resident_key, web_authn_policy_rp_entity_name: $web_authn_policy_rp_entity_name, web_authn_policy_rp_id: $web_authn_policy_rp_id, web_authn_policy_signature_algorithms: $web_authn_policy_signature_algorithms, web_authn_policy_user_verification_requirement: $web_authn_policy_user_verification_requirement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Need this for admin console to display simple name of provider when displaying client detail KEYCLOAK-4328
#
# GET /{id}/name
# Returns: record
export def "get-id-name" [
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
    path: "/{id}/name"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the realm
#
# DELETE /{realm}
export def "delete-realm" [
  realm: string
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
    path: "/{realm}"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the top-level representation of the realm It will not include nested information like User and Client representations.
#
# GET /{realm}
# Returns: record<accessCodeLifespan: int, accessCodeLifespanLogin: int, accessCodeLifespanUserAction: int, accessTokenLifespan: int, accessTokenLifespanForImplicitFlow: int, accountTheme: string, actionTokenGeneratedByAdminLifespan: int, actionTokenGeneratedByUserLifespan: int, adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, adminTheme: string, attributes: record, authenticationFlows: table<alias: string, authenticationExecutions: list, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>, authenticatorConfig: table<alias: string, config: record, id: string>, browserFlow: string, browserSecurityHeaders: record, bruteForceProtected: bool, clientAuthenticationFlow: string, clientScopeMappings: record, clientScopes: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list>, clientSessionIdleTimeout: int, clientSessionMaxLifespan: int, clients: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list, defaultRoles: list, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list, origin: string, protocol: string, protocolMappers: list, publicClient: bool, redirectUris: list, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list>, components: record<empty: bool, loadFactor: float, threshold: int>, defaultDefaultClientScopes: list<string>, defaultGroups: list<string>, defaultLocale: string, defaultOptionalClientScopes: list<string>, defaultRoles: list<string>, defaultSignatureAlgorithm: string, directGrantFlow: string, displayName: string, displayNameHtml: string, dockerAuthenticationFlow: string, duplicateEmailsAllowed: bool, editUsernameAllowed: bool, emailTheme: string, enabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>, failureFactor: int, federatedUsers: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, groups: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list, subGroups: list>, id: string, identityProviderMappers: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>, identityProviders: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>, internationalizationEnabled: bool, keycloakVersion: string, loginTheme: string, loginWithEmailAllowed: bool, maxDeltaTimeSeconds: int, maxFailureWaitSeconds: int, minimumQuickLoginWaitSeconds: int, notBefore: int, offlineSessionIdleTimeout: int, offlineSessionMaxLifespan: int, offlineSessionMaxLifespanEnabled: bool, otpPolicyAlgorithm: string, otpPolicyDigits: int, otpPolicyInitialCounter: int, otpPolicyLookAheadWindow: int, otpPolicyPeriod: int, otpPolicyType: string, otpSupportedApplications: list<string>, passwordPolicy: string, permanentLockout: bool, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, quickLoginCheckMilliSeconds: int, realm: string, refreshTokenMaxReuse: int, registrationAllowed: bool, registrationEmailAsUsername: bool, registrationFlow: string, rememberMe: bool, requiredActions: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>, resetCredentialsFlow: string, resetPasswordAllowed: bool, revokeRefreshToken: bool, roles: record<client: record, realm: list<record>>, scopeMappings: table<client: string, clientScope: string, roles: list, self: string>, smtpServer: record, sslRequired: string, ssoSessionIdleTimeout: int, ssoSessionIdleTimeoutRememberMe: int, ssoSessionMaxLifespan: int, ssoSessionMaxLifespanRememberMe: int, supportedLocales: list<string>, userFederationMappers: table<config: record, federationMapperType: string, federationProviderDisplayName: string, id: string, name: string>, userFederationProviders: table<changedSyncPeriod: int, config: record, displayName: string, fullSyncPeriod: int, id: string, lastSync: int, priority: int, providerName: string>, userManagedAccessAllowed: bool, users: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, verifyEmail: bool, waitIncrementSeconds: int, webAuthnPolicyAcceptableAaguids: list<string>, webAuthnPolicyAttestationConveyancePreference: string, webAuthnPolicyAuthenticatorAttachment: string, webAuthnPolicyAvoidSameAuthenticatorRegister: bool, webAuthnPolicyCreateTimeout: int, webAuthnPolicyPasswordlessAcceptableAaguids: list<string>, webAuthnPolicyPasswordlessAttestationConveyancePreference: string, webAuthnPolicyPasswordlessAuthenticatorAttachment: string, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: bool, webAuthnPolicyPasswordlessCreateTimeout: int, webAuthnPolicyPasswordlessRequireResidentKey: string, webAuthnPolicyPasswordlessRpEntityName: string, webAuthnPolicyPasswordlessRpId: string, webAuthnPolicyPasswordlessSignatureAlgorithms: list<string>, webAuthnPolicyPasswordlessUserVerificationRequirement: string, webAuthnPolicyRequireResidentKey: string, webAuthnPolicyRpEntityName: string, webAuthnPolicyRpId: string, webAuthnPolicySignatureAlgorithms: list<string>, webAuthnPolicyUserVerificationRequirement: string>
export def "get-realm" [
  realm: string
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
    path: "/{realm}"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the top-level information of the realm Any user, roles or client information in the representation will be ignored.
#
# PUT /{realm}
export def "put-realm" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-code-lifespan: int # format: int32
  --access-code-lifespan-login: int # format: int32
  --access-code-lifespan-user-action: int # format: int32
  --access-token-lifespan: int # format: int32
  --access-token-lifespan-for-implicit-flow: int # format: int32
  --account-theme: string
  --action-token-generated-by-admin-lifespan: int # format: int32
  --action-token-generated-by-user-lifespan: int # format: int32
  --admin-events-details-enabled: oneof<nothing, bool>
  --admin-events-enabled: oneof<nothing, bool>
  --admin-theme: string
  --attributes: record
  --authentication-flows: list # item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
  --authenticator-config: list # item shape: {alias?: string, config?: record, id?: string}
  --browser-flow: string
  --browser-security-headers: record
  --brute-force-protected: oneof<nothing, bool>
  --client-authentication-flow: string
  --client-scope-mappings: record
  --client-scopes: list # item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
  --client-session-idle-timeout: int # format: int32
  --client-session-max-lifespan: int # format: int32
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
  --components: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --default-default-client-scopes: list<string>
  --default-groups: list<string>
  --default-locale: string
  --default-optional-client-scopes: list<string>
  --default-roles: list<string>
  --default-signature-algorithm: string
  --direct-grant-flow: string
  --display-name: string
  --display-name-html: string
  --docker-authentication-flow: string
  --duplicate-emails-allowed: oneof<nothing, bool>
  --edit-username-allowed: oneof<nothing, bool>
  --email-theme: string
  --enabled: oneof<nothing, bool>
  --enabled-event-types: list<string>
  --events-enabled: oneof<nothing, bool>
  --events-expiration: int # format: int64
  --events-listeners: list<string>
  --failure-factor: int # format: int32
  --federated-users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
  --id: string
  --identity-provider-mappers: list # item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
  --identity-providers: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --internationalization-enabled: oneof<nothing, bool>
  --keycloak-version: string
  --login-theme: string
  --login-with-email-allowed: oneof<nothing, bool>
  --max-delta-time-seconds: int # format: int32
  --max-failure-wait-seconds: int # format: int32
  --minimum-quick-login-wait-seconds: int # format: int32
  --not-before: int # format: int32
  --offline-session-idle-timeout: int # format: int32
  --offline-session-max-lifespan: int # format: int32
  --offline-session-max-lifespan-enabled: oneof<nothing, bool>
  --otp-policy-algorithm: string
  --otp-policy-digits: int # format: int32
  --otp-policy-initial-counter: int # format: int32
  --otp-policy-look-ahead-window: int # format: int32
  --otp-policy-period: int # format: int32
  --otp-policy-type: string
  --otp-supported-applications: list<string>
  --password-policy: string
  --permanent-lockout: oneof<nothing, bool>
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --quick-login-check-milli-seconds: int # format: int64
  --body-realm: string # (spec name: realm)
  --refresh-token-max-reuse: int # format: int32
  --registration-allowed: oneof<nothing, bool>
  --registration-email-as-username: oneof<nothing, bool>
  --registration-flow: string
  --remember-me: oneof<nothing, bool>
  --required-actions: list # item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
  --reset-credentials-flow: string
  --reset-password-allowed: oneof<nothing, bool>
  --revoke-refresh-token: oneof<nothing, bool>
  --roles: record # shape: {client?: record, realm?: list}
  --scope-mappings: list # item shape: {client?: string, clientScope?: string, roles?: list<string>, self?: string}
  --smtp-server: record
  --ssl-required: string
  --sso-session-idle-timeout: int # format: int32
  --sso-session-idle-timeout-remember-me: int # format: int32
  --sso-session-max-lifespan: int # format: int32
  --sso-session-max-lifespan-remember-me: int # format: int32
  --supported-locales: list<string>
  --user-federation-mappers: list # item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
  --user-federation-providers: list # item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
  --user-managed-access-allowed: oneof<nothing, bool>
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
  --verify-email: oneof<nothing, bool>
  --wait-increment-seconds: int # format: int32
  --web-authn-policy-acceptable-aaguids: list<string>
  --web-authn-policy-attestation-conveyance-preference: string
  --web-authn-policy-authenticator-attachment: string
  --web-authn-policy-avoid-same-authenticator-register: oneof<nothing, bool>
  --web-authn-policy-create-timeout: int # format: int32
  --web-authn-policy-passwordless-acceptable-aaguids: list<string>
  --web-authn-policy-passwordless-attestation-conveyance-preference: string
  --web-authn-policy-passwordless-authenticator-attachment: string
  --web-authn-policy-passwordless-avoid-same-authenticator-register: oneof<nothing, bool>
  --web-authn-policy-passwordless-create-timeout: int # format: int32
  --web-authn-policy-passwordless-require-resident-key: string
  --web-authn-policy-passwordless-rp-entity-name: string
  --web-authn-policy-passwordless-rp-id: string
  --web-authn-policy-passwordless-signature-algorithms: list<string>
  --web-authn-policy-passwordless-user-verification-requirement: string
  --web-authn-policy-require-resident-key: string
  --web-authn-policy-rp-entity-name: string
  --web-authn-policy-rp-id: string
  --web-authn-policy-signature-algorithms: list<string>
  --web-authn-policy-user-verification-requirement: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessCodeLifespan, var: access_code_lifespan}, {name: accessCodeLifespanLogin, var: access_code_lifespan_login}, {name: accessCodeLifespanUserAction, var: access_code_lifespan_user_action}, {name: accessTokenLifespan, var: access_token_lifespan}, {name: accessTokenLifespanForImplicitFlow, var: access_token_lifespan_for_implicit_flow}, {name: accountTheme, var: account_theme}, {name: actionTokenGeneratedByAdminLifespan, var: action_token_generated_by_admin_lifespan}, {name: actionTokenGeneratedByUserLifespan, var: action_token_generated_by_user_lifespan}, {name: adminEventsDetailsEnabled, var: admin_events_details_enabled}, {name: adminEventsEnabled, var: admin_events_enabled}, {name: adminTheme, var: admin_theme}, {name: attributes, var: attributes}, {name: authenticationFlows, var: authentication_flows}, {name: authenticatorConfig, var: authenticator_config}, {name: browserFlow, var: browser_flow}, {name: browserSecurityHeaders, var: browser_security_headers}, {name: bruteForceProtected, var: brute_force_protected}, {name: clientAuthenticationFlow, var: client_authentication_flow}, {name: clientScopeMappings, var: client_scope_mappings}, {name: clientScopes, var: client_scopes}, {name: clientSessionIdleTimeout, var: client_session_idle_timeout}, {name: clientSessionMaxLifespan, var: client_session_max_lifespan}, {name: clients, var: clients}, {name: components, var: components}, {name: defaultDefaultClientScopes, var: default_default_client_scopes}, {name: defaultGroups, var: default_groups}, {name: defaultLocale, var: default_locale}, {name: defaultOptionalClientScopes, var: default_optional_client_scopes}, {name: defaultRoles, var: default_roles}, {name: defaultSignatureAlgorithm, var: default_signature_algorithm}, {name: directGrantFlow, var: direct_grant_flow}, {name: displayName, var: display_name}, {name: displayNameHtml, var: display_name_html}, {name: dockerAuthenticationFlow, var: docker_authentication_flow}, {name: duplicateEmailsAllowed, var: duplicate_emails_allowed}, {name: editUsernameAllowed, var: edit_username_allowed}, {name: emailTheme, var: email_theme}, {name: enabled, var: enabled}, {name: enabledEventTypes, var: enabled_event_types}, {name: eventsEnabled, var: events_enabled}, {name: eventsExpiration, var: events_expiration}, {name: eventsListeners, var: events_listeners}, {name: failureFactor, var: failure_factor}, {name: federatedUsers, var: federated_users}, {name: groups, var: groups}, {name: id, var: id}, {name: identityProviderMappers, var: identity_provider_mappers}, {name: identityProviders, var: identity_providers}, {name: internationalizationEnabled, var: internationalization_enabled}, {name: keycloakVersion, var: keycloak_version}, {name: loginTheme, var: login_theme}, {name: loginWithEmailAllowed, var: login_with_email_allowed}, {name: maxDeltaTimeSeconds, var: max_delta_time_seconds}, {name: maxFailureWaitSeconds, var: max_failure_wait_seconds}, {name: minimumQuickLoginWaitSeconds, var: minimum_quick_login_wait_seconds}, {name: notBefore, var: not_before}, {name: offlineSessionIdleTimeout, var: offline_session_idle_timeout}, {name: offlineSessionMaxLifespan, var: offline_session_max_lifespan}, {name: offlineSessionMaxLifespanEnabled, var: offline_session_max_lifespan_enabled}, {name: otpPolicyAlgorithm, var: otp_policy_algorithm}, {name: otpPolicyDigits, var: otp_policy_digits}, {name: otpPolicyInitialCounter, var: otp_policy_initial_counter}, {name: otpPolicyLookAheadWindow, var: otp_policy_look_ahead_window}, {name: otpPolicyPeriod, var: otp_policy_period}, {name: otpPolicyType, var: otp_policy_type}, {name: otpSupportedApplications, var: otp_supported_applications}, {name: passwordPolicy, var: password_policy}, {name: permanentLockout, var: permanent_lockout}, {name: protocolMappers, var: protocol_mappers}, {name: quickLoginCheckMilliSeconds, var: quick_login_check_milli_seconds}, {name: realm, var: body_realm}, {name: refreshTokenMaxReuse, var: refresh_token_max_reuse}, {name: registrationAllowed, var: registration_allowed}, {name: registrationEmailAsUsername, var: registration_email_as_username}, {name: registrationFlow, var: registration_flow}, {name: rememberMe, var: remember_me}, {name: requiredActions, var: required_actions}, {name: resetCredentialsFlow, var: reset_credentials_flow}, {name: resetPasswordAllowed, var: reset_password_allowed}, {name: revokeRefreshToken, var: revoke_refresh_token}, {name: roles, var: roles}, {name: scopeMappings, var: scope_mappings}, {name: smtpServer, var: smtp_server}, {name: sslRequired, var: ssl_required}, {name: ssoSessionIdleTimeout, var: sso_session_idle_timeout}, {name: ssoSessionIdleTimeoutRememberMe, var: sso_session_idle_timeout_remember_me}, {name: ssoSessionMaxLifespan, var: sso_session_max_lifespan}, {name: ssoSessionMaxLifespanRememberMe, var: sso_session_max_lifespan_remember_me}, {name: supportedLocales, var: supported_locales}, {name: userFederationMappers, var: user_federation_mappers}, {name: userFederationProviders, var: user_federation_providers}, {name: userManagedAccessAllowed, var: user_managed_access_allowed}, {name: users, var: users}, {name: verifyEmail, var: verify_email}, {name: waitIncrementSeconds, var: wait_increment_seconds}, {name: webAuthnPolicyAcceptableAaguids, var: web_authn_policy_acceptable_aaguids}, {name: webAuthnPolicyAttestationConveyancePreference, var: web_authn_policy_attestation_conveyance_preference}, {name: webAuthnPolicyAuthenticatorAttachment, var: web_authn_policy_authenticator_attachment}, {name: webAuthnPolicyAvoidSameAuthenticatorRegister, var: web_authn_policy_avoid_same_authenticator_register}, {name: webAuthnPolicyCreateTimeout, var: web_authn_policy_create_timeout}, {name: webAuthnPolicyPasswordlessAcceptableAaguids, var: web_authn_policy_passwordless_acceptable_aaguids}, {name: webAuthnPolicyPasswordlessAttestationConveyancePreference, var: web_authn_policy_passwordless_attestation_conveyance_preference}, {name: webAuthnPolicyPasswordlessAuthenticatorAttachment, var: web_authn_policy_passwordless_authenticator_attachment}, {name: webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister, var: web_authn_policy_passwordless_avoid_same_authenticator_register}, {name: webAuthnPolicyPasswordlessCreateTimeout, var: web_authn_policy_passwordless_create_timeout}, {name: webAuthnPolicyPasswordlessRequireResidentKey, var: web_authn_policy_passwordless_require_resident_key}, {name: webAuthnPolicyPasswordlessRpEntityName, var: web_authn_policy_passwordless_rp_entity_name}, {name: webAuthnPolicyPasswordlessRpId, var: web_authn_policy_passwordless_rp_id}, {name: webAuthnPolicyPasswordlessSignatureAlgorithms, var: web_authn_policy_passwordless_signature_algorithms}, {name: webAuthnPolicyPasswordlessUserVerificationRequirement, var: web_authn_policy_passwordless_user_verification_requirement}, {name: webAuthnPolicyRequireResidentKey, var: web_authn_policy_require_resident_key}, {name: webAuthnPolicyRpEntityName, var: web_authn_policy_rp_entity_name}, {name: webAuthnPolicyRpId, var: web_authn_policy_rp_id}, {name: webAuthnPolicySignatureAlgorithms, var: web_authn_policy_signature_algorithms}, {name: webAuthnPolicyUserVerificationRequirement, var: web_authn_policy_user_verification_requirement}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, access_code_lifespan: $access_code_lifespan, access_code_lifespan_login: $access_code_lifespan_login, access_code_lifespan_user_action: $access_code_lifespan_user_action, access_token_lifespan: $access_token_lifespan, access_token_lifespan_for_implicit_flow: $access_token_lifespan_for_implicit_flow, account_theme: $account_theme, action_token_generated_by_admin_lifespan: $action_token_generated_by_admin_lifespan, action_token_generated_by_user_lifespan: $action_token_generated_by_user_lifespan, admin_events_details_enabled: $admin_events_details_enabled, admin_events_enabled: $admin_events_enabled, admin_theme: $admin_theme, attributes: $attributes, authentication_flows: $authentication_flows, authenticator_config: $authenticator_config, browser_flow: $browser_flow, browser_security_headers: $browser_security_headers, brute_force_protected: $brute_force_protected, client_authentication_flow: $client_authentication_flow, client_scope_mappings: $client_scope_mappings, client_scopes: $client_scopes, client_session_idle_timeout: $client_session_idle_timeout, client_session_max_lifespan: $client_session_max_lifespan, clients: $clients, components: $components, default_default_client_scopes: $default_default_client_scopes, default_groups: $default_groups, default_locale: $default_locale, default_optional_client_scopes: $default_optional_client_scopes, default_roles: $default_roles, default_signature_algorithm: $default_signature_algorithm, direct_grant_flow: $direct_grant_flow, display_name: $display_name, display_name_html: $display_name_html, docker_authentication_flow: $docker_authentication_flow, duplicate_emails_allowed: $duplicate_emails_allowed, edit_username_allowed: $edit_username_allowed, email_theme: $email_theme, enabled: $enabled, enabled_event_types: $enabled_event_types, events_enabled: $events_enabled, events_expiration: $events_expiration, events_listeners: $events_listeners, failure_factor: $failure_factor, federated_users: $federated_users, groups: $groups, id: $id, identity_provider_mappers: $identity_provider_mappers, identity_providers: $identity_providers, internationalization_enabled: $internationalization_enabled, keycloak_version: $keycloak_version, login_theme: $login_theme, login_with_email_allowed: $login_with_email_allowed, max_delta_time_seconds: $max_delta_time_seconds, max_failure_wait_seconds: $max_failure_wait_seconds, minimum_quick_login_wait_seconds: $minimum_quick_login_wait_seconds, not_before: $not_before, offline_session_idle_timeout: $offline_session_idle_timeout, offline_session_max_lifespan: $offline_session_max_lifespan, offline_session_max_lifespan_enabled: $offline_session_max_lifespan_enabled, otp_policy_algorithm: $otp_policy_algorithm, otp_policy_digits: $otp_policy_digits, otp_policy_initial_counter: $otp_policy_initial_counter, otp_policy_look_ahead_window: $otp_policy_look_ahead_window, otp_policy_period: $otp_policy_period, otp_policy_type: $otp_policy_type, otp_supported_applications: $otp_supported_applications, password_policy: $password_policy, permanent_lockout: $permanent_lockout, protocol_mappers: $protocol_mappers, quick_login_check_milli_seconds: $quick_login_check_milli_seconds, body_realm: $body_realm, refresh_token_max_reuse: $refresh_token_max_reuse, registration_allowed: $registration_allowed, registration_email_as_username: $registration_email_as_username, registration_flow: $registration_flow, remember_me: $remember_me, required_actions: $required_actions, reset_credentials_flow: $reset_credentials_flow, reset_password_allowed: $reset_password_allowed, revoke_refresh_token: $revoke_refresh_token, roles: $roles, scope_mappings: $scope_mappings, smtp_server: $smtp_server, ssl_required: $ssl_required, sso_session_idle_timeout: $sso_session_idle_timeout, sso_session_idle_timeout_remember_me: $sso_session_idle_timeout_remember_me, sso_session_max_lifespan: $sso_session_max_lifespan, sso_session_max_lifespan_remember_me: $sso_session_max_lifespan_remember_me, supported_locales: $supported_locales, user_federation_mappers: $user_federation_mappers, user_federation_providers: $user_federation_providers, user_managed_access_allowed: $user_managed_access_allowed, users: $users, verify_email: $verify_email, wait_increment_seconds: $wait_increment_seconds, web_authn_policy_acceptable_aaguids: $web_authn_policy_acceptable_aaguids, web_authn_policy_attestation_conveyance_preference: $web_authn_policy_attestation_conveyance_preference, web_authn_policy_authenticator_attachment: $web_authn_policy_authenticator_attachment, web_authn_policy_avoid_same_authenticator_register: $web_authn_policy_avoid_same_authenticator_register, web_authn_policy_create_timeout: $web_authn_policy_create_timeout, web_authn_policy_passwordless_acceptable_aaguids: $web_authn_policy_passwordless_acceptable_aaguids, web_authn_policy_passwordless_attestation_conveyance_preference: $web_authn_policy_passwordless_attestation_conveyance_preference, web_authn_policy_passwordless_authenticator_attachment: $web_authn_policy_passwordless_authenticator_attachment, web_authn_policy_passwordless_avoid_same_authenticator_register: $web_authn_policy_passwordless_avoid_same_authenticator_register, web_authn_policy_passwordless_create_timeout: $web_authn_policy_passwordless_create_timeout, web_authn_policy_passwordless_require_resident_key: $web_authn_policy_passwordless_require_resident_key, web_authn_policy_passwordless_rp_entity_name: $web_authn_policy_passwordless_rp_entity_name, web_authn_policy_passwordless_rp_id: $web_authn_policy_passwordless_rp_id, web_authn_policy_passwordless_signature_algorithms: $web_authn_policy_passwordless_signature_algorithms, web_authn_policy_passwordless_user_verification_requirement: $web_authn_policy_passwordless_user_verification_requirement, web_authn_policy_require_resident_key: $web_authn_policy_require_resident_key, web_authn_policy_rp_entity_name: $web_authn_policy_rp_entity_name, web_authn_policy_rp_id: $web_authn_policy_rp_id, web_authn_policy_signature_algorithms: $web_authn_policy_signature_algorithms, web_authn_policy_user_verification_requirement: $web_authn_policy_user_verification_requirement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all admin events
#
# DELETE /{realm}/admin-events
export def "delete-realm-admin-events" [
  realm: string
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
    path: "/{realm}/admin-events"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get admin events Returns all admin events, or filters events based on URL query parameters listed here
#
# GET /{realm}/admin-events
# Returns: table<authDetails: record<clientId: string, ipAddress: string, realmId: string, userId: string>, error: string, operationType: string, realmId: string, representation: string, resourcePath: string, resourceType: string, time: int>
export def "get-realm-admin-events" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-client: string
  --auth-ip-address: string
  --auth-realm: string
  --auth-user: string # user id
  --date-from: string
  --date-to: string
  --first: int # format: int32
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --operation-types: list<string>
  --resource-path: string
  --resource-types: list<string>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/admin-events"
    path_params: [{name: realm, var: realm}]
    query: [{name: authClient, var: auth_client}, {name: authIpAddress, var: auth_ip_address}, {name: authRealm, var: auth_realm}, {name: authUser, var: auth_user}, {name: dateFrom, var: date_from}, {name: dateTo, var: date_to}, {name: first, var: first}, {name: max, var: max}, {name: operationTypes, var: operation_types, style: multi}, {name: resourcePath, var: resource_path}, {name: resourceTypes, var: resource_types, style: multi}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, auth_client: $auth_client, auth_ip_address: $auth_ip_address, auth_realm: $auth_realm, auth_user: $auth_user, date_from: $date_from, date_to: $date_to, first: $first, max: $max, operation_types: $operation_types, resource_path: $resource_path, resource_types: $resource_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear any user login failures for all users This can release temporary disabled users
#
# DELETE /{realm}/attack-detection/brute-force/users
export def "delete-realm-attack-detection-brute-force-users" [
  realm: string
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
    path: "/{realm}/attack-detection/brute-force/users"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear any user login failures for the user This can release temporary disabled user
#
# DELETE /{realm}/attack-detection/brute-force/users/{userId}
export def "delete-realm-attack-detection-brute-force-users-user-id" [
  realm: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/{realm}/attack-detection/brute-force/users/{userId}"
    path_params: [{name: realm, var: realm}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status of a username in brute force detection
#
# GET /{realm}/attack-detection/brute-force/users/{userId}
# Returns: record
export def "get-realm-attack-detection-brute-force-users-user-id" [
  realm: string
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
    path: "/{realm}/attack-detection/brute-force/users/{userId}"
    path_params: [{name: realm, var: realm}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authenticator providers Returns a list of authenticator providers.
#
# GET /{realm}/authentication/authenticator-providers
# Returns: list<record>
export def "get-realm-authentication-authenticator-providers" [
  realm: string
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
    path: "/{realm}/authentication/authenticator-providers"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get client authenticator providers Returns a list of client authenticator providers.
#
# GET /{realm}/authentication/client-authenticator-providers
# Returns: list<record>
export def "get-realm-authentication-client-authenticator-providers" [
  realm: string
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
    path: "/{realm}/authentication/client-authenticator-providers"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authenticator provider’s configuration description
#
# GET /{realm}/authentication/config-description/{providerId}
# Returns: record<helpText: string, name: string, properties: table<defaultValue: record, helpText: string, label: string, name: string, options: list, secret: bool, type: string>, providerId: string>
export def "get-realm-authentication-config-description-provider-id" [
  realm: string
  provider_id: string
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
    path: "/{realm}/authentication/config-description/{providerId}"
    path_params: [{name: realm, var: realm}, {name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete authenticator configuration
#
# DELETE /{realm}/authentication/config/{id}
export def "delete-realm-authentication-config-id" [
  realm: string
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
    path: "/{realm}/authentication/config/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authenticator configuration
#
# GET /{realm}/authentication/config/{id}
# Returns: record<alias: string, config: record, id: string>
export def "get-realm-authentication-config-id" [
  realm: string
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
    path: "/{realm}/authentication/config/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update authenticator configuration
#
# PUT /{realm}/authentication/config/{id}
export def "put-realm-authentication-config-id" [
  realm: string
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
  --alias: string
  --config: record
  --body-id: string # (spec name: id)
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/authentication/config/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}, {name: config, var: config}, {name: id, var: body_id}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, alias: $alias, config: $config, body_id: $body_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new authentication execution
#
# POST /{realm}/authentication/executions
export def "post-realm-authentication-executions" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authenticator: string
  --authenticator-config: string
  --authenticator-flow: oneof<nothing, bool>
  --autheticator-flow: oneof<nothing, bool>
  --flow-id: string
  --id: string
  --parent-flow: string
  --priority: int # format: int32
  --requirement: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/authentication/executions"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: authenticator, var: authenticator}, {name: authenticatorConfig, var: authenticator_config}, {name: authenticatorFlow, var: authenticator_flow}, {name: autheticatorFlow, var: autheticator_flow}, {name: flowId, var: flow_id}, {name: id, var: id}, {name: parentFlow, var: parent_flow}, {name: priority, var: priority}, {name: requirement, var: requirement}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, authenticator: $authenticator, authenticator_config: $authenticator_config, authenticator_flow: $authenticator_flow, autheticator_flow: $autheticator_flow, flow_id: $flow_id, id: $id, parent_flow: $parent_flow, priority: $priority, requirement: $requirement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete execution
#
# DELETE /{realm}/authentication/executions/{executionId}
export def "delete-realm-authentication-executions-execution-id" [
  realm: string
  execution_id: string
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
    path: "/{realm}/authentication/executions/{executionId}"
    path_params: [{name: realm, var: realm}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Single Execution
#
# GET /{realm}/authentication/executions/{executionId}
export def "get-realm-authentication-executions-execution-id" [
  realm: string
  execution_id: string
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
    path: "/{realm}/authentication/executions/{executionId}"
    path_params: [{name: realm, var: realm}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update execution with new configuration
#
# POST /{realm}/authentication/executions/{executionId}/config
export def "post-realm-authentication-executions-execution-id-config" [
  realm: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --config: record
  --id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/authentication/executions/{executionId}/config"
    path_params: [{name: realm, var: realm}, {name: executionId, var: execution_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}, {name: config, var: config}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, execution_id: $execution_id, alias: $alias, config: $config, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lower execution’s priority
#
# POST /{realm}/authentication/executions/{executionId}/lower-priority
export def "post-realm-authentication-executions-execution-id-lower-priority" [
  realm: string
  execution_id: string
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
    method: post
    path: "/{realm}/authentication/executions/{executionId}/lower-priority"
    path_params: [{name: realm, var: realm}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Raise execution’s priority
#
# POST /{realm}/authentication/executions/{executionId}/raise-priority
export def "post-realm-authentication-executions-execution-id-raise-priority" [
  realm: string
  execution_id: string
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
    method: post
    path: "/{realm}/authentication/executions/{executionId}/raise-priority"
    path_params: [{name: realm, var: realm}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authentication flows Returns a list of authentication flows.
#
# GET /{realm}/authentication/flows
# Returns: table<alias: string, authenticationExecutions: list<record>, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>
export def "get-realm-authentication-flows" [
  realm: string
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
    path: "/{realm}/authentication/flows"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new authentication flow
#
# POST /{realm}/authentication/flows
export def "post-realm-authentication-flows" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --authentication-executions: list # item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
  --built-in: oneof<nothing, bool>
  --description: string
  --id: string
  --provider-id: string
  --top-level: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/authentication/flows"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}, {name: authenticationExecutions, var: authentication_executions}, {name: builtIn, var: built_in}, {name: description, var: description}, {name: id, var: id}, {name: providerId, var: provider_id}, {name: topLevel, var: top_level}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, authentication_executions: $authentication_executions, built_in: $built_in, description: $description, id: $id, provider_id: $provider_id, top_level: $top_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy existing authentication flow under a new name The new name is given as 'newName' attribute of the passed JSON object
#
# POST /{realm}/authentication/flows/{flowAlias}/copy
export def "post-realm-authentication-flows-flow-alias-copy" [
  realm: string
  flow_alias: string
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
    method: post
    path: "/{realm}/authentication/flows/{flowAlias}/copy"
    path_params: [{name: realm, var: realm}, {name: flowAlias, var: flow_alias}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, flow_alias: $flow_alias, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authentication executions for a flow
#
# GET /{realm}/authentication/flows/{flowAlias}/executions
export def "get-realm-authentication-flows-flow-alias-executions" [
  realm: string
  flow_alias: string
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
    path: "/{realm}/authentication/flows/{flowAlias}/executions"
    path_params: [{name: realm, var: realm}, {name: flowAlias, var: flow_alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, flow_alias: $flow_alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update authentication executions of a flow
#
# PUT /{realm}/authentication/flows/{flowAlias}/executions
export def "put-realm-authentication-flows-flow-alias-executions" [
  realm: string
  flow_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --authentication-config: string
  --authentication-flow: oneof<nothing, bool>
  --configurable: oneof<nothing, bool>
  --display-name: string
  --flow-id: string
  --id: string
  --index: int # format: int32
  --level: int # format: int32
  --provider-id: string
  --requirement: string
  --requirement-choices: list<string>
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/authentication/flows/{flowAlias}/executions"
    path_params: [{name: realm, var: realm}, {name: flowAlias, var: flow_alias}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}, {name: authenticationConfig, var: authentication_config}, {name: authenticationFlow, var: authentication_flow}, {name: configurable, var: configurable}, {name: displayName, var: display_name}, {name: flowId, var: flow_id}, {name: id, var: id}, {name: index, var: index}, {name: level, var: level}, {name: providerId, var: provider_id}, {name: requirement, var: requirement}, {name: requirementChoices, var: requirement_choices}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, flow_alias: $flow_alias, alias: $alias, authentication_config: $authentication_config, authentication_flow: $authentication_flow, configurable: $configurable, display_name: $display_name, flow_id: $flow_id, id: $id, index: $index, level: $level, provider_id: $provider_id, requirement: $requirement, requirement_choices: $requirement_choices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new authentication execution to a flow
#
# POST /{realm}/authentication/flows/{flowAlias}/executions/execution
export def "post-realm-authentication-flows-flow-alias-executions-execution" [
  realm: string
  flow_alias: string
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
    method: post
    path: "/{realm}/authentication/flows/{flowAlias}/executions/execution"
    path_params: [{name: realm, var: realm}, {name: flowAlias, var: flow_alias}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, flow_alias: $flow_alias, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new flow with new execution to existing flow
#
# POST /{realm}/authentication/flows/{flowAlias}/executions/flow
export def "post-realm-authentication-flows-flow-alias-executions-flow" [
  realm: string
  flow_alias: string
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
    method: post
    path: "/{realm}/authentication/flows/{flowAlias}/executions/flow"
    path_params: [{name: realm, var: realm}, {name: flowAlias, var: flow_alias}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, flow_alias: $flow_alias, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an authentication flow
#
# DELETE /{realm}/authentication/flows/{id}
export def "delete-realm-authentication-flows-id" [
  realm: string
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
    path: "/{realm}/authentication/flows/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authentication flow for id
#
# GET /{realm}/authentication/flows/{id}
# Returns: record<alias: string, authenticationExecutions: table<authenticator: string, authenticatorConfig: string, authenticatorFlow: bool, autheticatorFlow: bool, flowAlias: string, priority: int, requirement: string, userSetupAllowed: bool>, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>
export def "get-realm-authentication-flows-id" [
  realm: string
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
    path: "/{realm}/authentication/flows/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an authentication flow
#
# PUT /{realm}/authentication/flows/{id}
export def "put-realm-authentication-flows-id" [
  realm: string
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
  --alias: string
  --authentication-executions: list # item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
  --built-in: oneof<nothing, bool>
  --description: string
  --body-id: string # (spec name: id)
  --provider-id: string
  --top-level: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/authentication/flows/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}, {name: authenticationExecutions, var: authentication_executions}, {name: builtIn, var: built_in}, {name: description, var: description}, {name: id, var: body_id}, {name: providerId, var: provider_id}, {name: topLevel, var: top_level}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, alias: $alias, authentication_executions: $authentication_executions, built_in: $built_in, description: $description, body_id: $body_id, provider_id: $provider_id, top_level: $top_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get form action providers Returns a list of form action providers.
#
# GET /{realm}/authentication/form-action-providers
# Returns: list<record>
export def "get-realm-authentication-form-action-providers" [
  realm: string
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
    path: "/{realm}/authentication/form-action-providers"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get form providers Returns a list of form providers.
#
# GET /{realm}/authentication/form-providers
# Returns: list<record>
export def "get-realm-authentication-form-providers" [
  realm: string
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
    path: "/{realm}/authentication/form-providers"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configuration descriptions for all clients
#
# GET /{realm}/authentication/per-client-config-description
# Returns: record
export def "get-realm-authentication-per-client-config-description" [
  realm: string
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
    path: "/{realm}/authentication/per-client-config-description"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a new required actions
#
# POST /{realm}/authentication/register-required-action
export def "post-realm-authentication-register-required-action" [
  realm: string
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
    method: post
    path: "/{realm}/authentication/register-required-action"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get required actions Returns a list of required actions.
#
# GET /{realm}/authentication/required-actions
# Returns: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>
export def "get-realm-authentication-required-actions" [
  realm: string
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
    path: "/{realm}/authentication/required-actions"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete required action
#
# DELETE /{realm}/authentication/required-actions/{alias}
export def "delete-realm-authentication-required-actions-alias" [
  realm: string
  alias: string
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
    path: "/{realm}/authentication/required-actions/{alias}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get required action for alias
#
# GET /{realm}/authentication/required-actions/{alias}
# Returns: record<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>
export def "get-realm-authentication-required-actions-alias" [
  realm: string
  alias: string
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
    path: "/{realm}/authentication/required-actions/{alias}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update required action
#
# PUT /{realm}/authentication/required-actions/{alias}
export def "put-realm-authentication-required-actions-alias" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-alias: string # (spec name: alias)
  --config: record
  --default-action: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --name: string
  --priority: int # format: int32
  --provider-id: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/authentication/required-actions/{alias}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: body_alias}, {name: config, var: config}, {name: defaultAction, var: default_action}, {name: enabled, var: enabled}, {name: name, var: name}, {name: priority, var: priority}, {name: providerId, var: provider_id}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, body_alias: $body_alias, config: $config, default_action: $default_action, enabled: $enabled, name: $name, priority: $priority, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lower required action’s priority
#
# POST /{realm}/authentication/required-actions/{alias}/lower-priority
export def "post-realm-authentication-required-actions-alias-lower-priority" [
  realm: string
  alias: string
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
    method: post
    path: "/{realm}/authentication/required-actions/{alias}/lower-priority"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Raise required action’s priority
#
# POST /{realm}/authentication/required-actions/{alias}/raise-priority
export def "post-realm-authentication-required-actions-alias-raise-priority" [
  realm: string
  alias: string
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
    method: post
    path: "/{realm}/authentication/required-actions/{alias}/raise-priority"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unregistered required actions Returns a list of unregistered required actions.
#
# GET /{realm}/authentication/unregistered-required-actions
# Returns: list<record>
export def "get-realm-authentication-unregistered-required-actions" [
  realm: string
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
    path: "/{realm}/authentication/unregistered-required-actions"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear cache of external public keys (Public keys of clients or Identity providers)
#
# POST /{realm}/clear-keys-cache
export def "post-realm-clear-keys-cache" [
  realm: string
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
    method: post
    path: "/{realm}/clear-keys-cache"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear realm cache
#
# POST /{realm}/clear-realm-cache
export def "post-realm-clear-realm-cache" [
  realm: string
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
    method: post
    path: "/{realm}/clear-realm-cache"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear user cache
#
# POST /{realm}/clear-user-cache
export def "post-realm-clear-user-cache" [
  realm: string
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
    method: post
    path: "/{realm}/clear-user-cache"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Base path for importing clients under this realm.
#
# POST /{realm}/client-description-converter
# Returns: record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>>
export def "post-realm-client-description-converter" [
  realm: string
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
    method: post
    path: "/{realm}/client-description-converter"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Base path for retrieve providers with the configProperties properly filled
#
# GET /{realm}/client-registration-policy/providers
# Returns: table<helpText: string, id: string, metadata: record, properties: list<record>>
export def "get-realm-client-registration-policy-providers" [
  realm: string
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
    path: "/{realm}/client-registration-policy/providers"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get client scopes belonging to the realm Returns a list of client scopes belonging to the realm
#
# GET /{realm}/client-scopes
# Returns: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>
export def "get-realm-client-scopes" [
  realm: string
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
    path: "/{realm}/client-scopes"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new client scope Client Scope’s name must be unique!
#
# POST /{realm}/client-scopes
export def "post-realm-client-scopes" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --id: string
  --name: string
  --protocol: string
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/client-scopes"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: description, var: description}, {name: id, var: id}, {name: name, var: name}, {name: protocol, var: protocol}, {name: protocolMappers, var: protocol_mappers}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, attributes: $attributes, description: $description, id: $id, name: $name, protocol: $protocol, protocol_mappers: $protocol_mappers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the mapper
#
# DELETE /{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}
export def "delete-realm-client-scopes-id1-protocol-mappers-models-id2" [
  realm: string
  id1: string
  id2: string
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
    path: "/{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}"
    path_params: [{name: realm, var: realm}, {name: id1, var: id1}, {name: id2, var: id2}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id1: $id1, id2: $id2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mapper by id
#
# GET /{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}
# Returns: record<config: record, id: string, name: string, protocol: string, protocolMapper: string>
export def "get-realm-client-scopes-id1-protocol-mappers-models-id2" [
  realm: string
  id1: string
  id2: string
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
    path: "/{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}"
    path_params: [{name: realm, var: realm}, {name: id1, var: id1}, {name: id2, var: id2}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id1: $id1, id2: $id2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the mapper
#
# PUT /{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}
export def "put-realm-client-scopes-id1-protocol-mappers-models-id2" [
  realm: string
  id1: string
  id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --name: string
  --protocol: string
  --protocol-mapper: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}"
    path_params: [{name: realm, var: realm}, {name: id1, var: id1}, {name: id2, var: id2}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: id, var: id}, {name: name, var: name}, {name: protocol, var: protocol}, {name: protocolMapper, var: protocol_mapper}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id1: $id1, id2: $id2, config: $config, id: $id, name: $name, protocol: $protocol, protocol_mapper: $protocol_mapper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the client scope
#
# DELETE /{realm}/client-scopes/{id}
export def "delete-realm-client-scopes-id" [
  realm: string
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
    path: "/{realm}/client-scopes/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get representation of the client scope
#
# GET /{realm}/client-scopes/{id}
# Returns: record<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>>
export def "get-realm-client-scopes-id" [
  realm: string
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
    path: "/{realm}/client-scopes/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the client scope
#
# PUT /{realm}/client-scopes/{id}
export def "put-realm-client-scopes-id" [
  realm: string
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
  --attributes: record
  --description: string
  --body-id: string # (spec name: id)
  --name: string
  --protocol: string
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/client-scopes/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: description, var: description}, {name: id, var: body_id}, {name: name, var: name}, {name: protocol, var: protocol}, {name: protocolMappers, var: protocol_mappers}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, attributes: $attributes, description: $description, body_id: $body_id, name: $name, protocol: $protocol, protocol_mappers: $protocol_mappers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create multiple mappers
#
# POST /{realm}/client-scopes/{id}/protocol-mappers/add-models
export def "post-realm-client-scopes-id-protocol-mappers-add-models" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/client-scopes/{id}/protocol-mappers/add-models"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mappers
#
# GET /{realm}/client-scopes/{id}/protocol-mappers/models
# Returns: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>
export def "get-realm-client-scopes-id-protocol-mappers-models" [
  realm: string
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
    path: "/{realm}/client-scopes/{id}/protocol-mappers/models"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a mapper
#
# POST /{realm}/client-scopes/{id}/protocol-mappers/models
export def "post-realm-client-scopes-id-protocol-mappers-models" [
  realm: string
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
  --config: record
  --body-id: string # (spec name: id)
  --name: string
  --protocol: string
  --protocol-mapper: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/client-scopes/{id}/protocol-mappers/models"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: id, var: body_id}, {name: name, var: name}, {name: protocol, var: protocol}, {name: protocolMapper, var: protocol_mapper}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, config: $config, body_id: $body_id, name: $name, protocol: $protocol, protocol_mapper: $protocol_mapper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mappers by name for a specific protocol
#
# GET /{realm}/client-scopes/{id}/protocol-mappers/protocol/{protocol}
# Returns: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>
export def "get-realm-client-scopes-id-protocol-mappers-protocol-protocol" [
  realm: string
  id: string
  protocol: string
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
    path: "/{realm}/client-scopes/{id}/protocol-mappers/protocol/{protocol}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: protocol, var: protocol}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, protocol: $protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all scope mappings for the client
#
# GET /{realm}/client-scopes/{id}/scope-mappings
# Returns: record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>>
export def "get-realm-client-scopes-id-scope-mappings" [
  realm: string
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
    path: "/{realm}/client-scopes/{id}/scope-mappings"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove client-level roles from the client’s scope.
#
# DELETE /{realm}/client-scopes/{id}/scope-mappings/clients/{client}
export def "delete-realm-client-scopes-id-scope-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    method: delete
    path: "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the roles associated with a client’s scope Returns roles for the client.
#
# GET /{realm}/client-scopes/{id}/scope-mappings/clients/{client}
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-client-scopes-id-scope-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add client-level roles to the client’s scope
#
# POST /{realm}/client-scopes/{id}/scope-mappings/clients/{client}
export def "post-realm-client-scopes-id-scope-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The available client-level roles Returns the roles for the client that can be associated with the client’s scope
#
# GET /{realm}/client-scopes/{id}/scope-mappings/clients/{client}/available
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-client-scopes-id-scope-mappings-clients-client-available" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}/available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective client roles Returns the roles for the client that are associated with the client’s scope.
#
# GET /{realm}/client-scopes/{id}/scope-mappings/clients/{client}/composite
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-client-scopes-id-scope-mappings-clients-client-composite" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}/composite"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a set of realm-level roles from the client’s scope
#
# DELETE /{realm}/client-scopes/{id}/scope-mappings/realm
export def "delete-realm-client-scopes-id-scope-mappings-realm" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/{realm}/client-scopes/{id}/scope-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles associated with the client’s scope
#
# GET /{realm}/client-scopes/{id}/scope-mappings/realm
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-client-scopes-id-scope-mappings-realm" [
  realm: string
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
    path: "/{realm}/client-scopes/{id}/scope-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a set of realm-level roles to the client’s scope
#
# POST /{realm}/client-scopes/{id}/scope-mappings/realm
export def "post-realm-client-scopes-id-scope-mappings-realm" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/client-scopes/{id}/scope-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles that are available to attach to this client’s scope
#
# GET /{realm}/client-scopes/{id}/scope-mappings/realm/available
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-client-scopes-id-scope-mappings-realm-available" [
  realm: string
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
    path: "/{realm}/client-scopes/{id}/scope-mappings/realm/available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective realm-level roles associated with the client’s scope What this does is recurse any composite roles associated with the client’s scope and adds the roles to this lists.
#
# GET /{realm}/client-scopes/{id}/scope-mappings/realm/composite
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-client-scopes-id-scope-mappings-realm-composite" [
  realm: string
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
    path: "/{realm}/client-scopes/{id}/scope-mappings/realm/composite"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get client session stats Returns a JSON map.
#
# GET /{realm}/client-session-stats
# Returns: list<record>
export def "get-realm-client-session-stats" [
  realm: string
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
    path: "/{realm}/client-session-stats"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get clients belonging to the realm Returns a list of clients belonging to the realm
#
# GET /{realm}/clients
# Returns: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list, policyEnforcementMode: string, resources: list, scopes: list>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: list<record>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>>
export def "get-realm-clients" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # filter by clientId
  --first: int # the first result (format: int32)
  --max: int # the max results to return (format: int32)
  --search: oneof<nothing, bool> # whether this is a search query or a getClientById query
  --viewable-only: oneof<nothing, bool> # filter clients that cannot be viewed in full by admin
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients"
    path_params: [{name: realm, var: realm}]
    query: [{name: clientId, var: client_id}, {name: first, var: first}, {name: max, var: max}, {name: search, var: search}, {name: viewableOnly, var: viewable_only}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, client_id: $client_id, first: $first, max: $max, search: $search, viewable_only: $viewable_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new client Client’s client_id must be unique!
#
# POST /{realm}/clients
export def "post-realm-clients" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --admin-url: string
  --always-display-in-console: oneof<nothing, bool>
  --attributes: record
  --authentication-flow-binding-overrides: record
  --authorization-services-enabled: oneof<nothing, bool>
  --authorization-settings: record # shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
  --body-base-url: string # (spec name: baseUrl)
  --bearer-only: oneof<nothing, bool>
  --client-authenticator-type: string
  --client-id: string
  --consent-required: oneof<nothing, bool>
  --default-client-scopes: list<string>
  --default-roles: list<string>
  --description: string
  --direct-access-grants-enabled: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --frontchannel-logout: oneof<nothing, bool>
  --full-scope-allowed: oneof<nothing, bool>
  --id: string
  --implicit-flow-enabled: oneof<nothing, bool>
  --name: string
  --node-re-registration-timeout: int # format: int32
  --not-before: int # format: int32
  --optional-client-scopes: list<string>
  --origin: string
  --protocol: string
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --public-client: oneof<nothing, bool>
  --redirect-uris: list<string>
  --registered-nodes: record
  --registration-access-token: string
  --root-url: string
  --secret: string
  --service-accounts-enabled: oneof<nothing, bool>
  --standard-flow-enabled: oneof<nothing, bool>
  --surrogate-auth-required: oneof<nothing, bool>
  --web-origins: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/clients"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: adminUrl, var: admin_url}, {name: alwaysDisplayInConsole, var: always_display_in_console}, {name: attributes, var: attributes}, {name: authenticationFlowBindingOverrides, var: authentication_flow_binding_overrides}, {name: authorizationServicesEnabled, var: authorization_services_enabled}, {name: authorizationSettings, var: authorization_settings}, {name: baseUrl, var: body_base_url}, {name: bearerOnly, var: bearer_only}, {name: clientAuthenticatorType, var: client_authenticator_type}, {name: clientId, var: client_id}, {name: consentRequired, var: consent_required}, {name: defaultClientScopes, var: default_client_scopes}, {name: defaultRoles, var: default_roles}, {name: description, var: description}, {name: directAccessGrantsEnabled, var: direct_access_grants_enabled}, {name: enabled, var: enabled}, {name: frontchannelLogout, var: frontchannel_logout}, {name: fullScopeAllowed, var: full_scope_allowed}, {name: id, var: id}, {name: implicitFlowEnabled, var: implicit_flow_enabled}, {name: name, var: name}, {name: nodeReRegistrationTimeout, var: node_re_registration_timeout}, {name: notBefore, var: not_before}, {name: optionalClientScopes, var: optional_client_scopes}, {name: origin, var: origin}, {name: protocol, var: protocol}, {name: protocolMappers, var: protocol_mappers}, {name: publicClient, var: public_client}, {name: redirectUris, var: redirect_uris}, {name: registeredNodes, var: registered_nodes}, {name: registrationAccessToken, var: registration_access_token}, {name: rootUrl, var: root_url}, {name: secret, var: secret}, {name: serviceAccountsEnabled, var: service_accounts_enabled}, {name: standardFlowEnabled, var: standard_flow_enabled}, {name: surrogateAuthRequired, var: surrogate_auth_required}, {name: webOrigins, var: web_origins}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, access: $access, admin_url: $admin_url, always_display_in_console: $always_display_in_console, attributes: $attributes, authentication_flow_binding_overrides: $authentication_flow_binding_overrides, authorization_services_enabled: $authorization_services_enabled, authorization_settings: $authorization_settings, body_base_url: $body_base_url, bearer_only: $bearer_only, client_authenticator_type: $client_authenticator_type, client_id: $client_id, consent_required: $consent_required, default_client_scopes: $default_client_scopes, default_roles: $default_roles, description: $description, direct_access_grants_enabled: $direct_access_grants_enabled, enabled: $enabled, frontchannel_logout: $frontchannel_logout, full_scope_allowed: $full_scope_allowed, id: $id, implicit_flow_enabled: $implicit_flow_enabled, name: $name, node_re_registration_timeout: $node_re_registration_timeout, not_before: $not_before, optional_client_scopes: $optional_client_scopes, origin: $origin, protocol: $protocol, protocol_mappers: $protocol_mappers, public_client: $public_client, redirect_uris: $redirect_uris, registered_nodes: $registered_nodes, registration_access_token: $registration_access_token, root_url: $root_url, secret: $secret, service_accounts_enabled: $service_accounts_enabled, standard_flow_enabled: $standard_flow_enabled, surrogate_auth_required: $surrogate_auth_required, web_origins: $web_origins
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/clients-initial-access
#
# Returns: table<count: int, expiration: int, id: string, remainingCount: int, timestamp: int, token: string>
export def "get-realm-clients-initial-access" [
  realm: string
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
    path: "/{realm}/clients-initial-access"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new initial access token.
#
# POST /{realm}/clients-initial-access
# Returns: record<count: int, expiration: int, id: string, remainingCount: int, timestamp: int, token: string>
export def "post-realm-clients-initial-access" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # format: int32
  --expiration: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{realm}/clients-initial-access"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: expiration, var: expiration}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, count: $count, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/clients-initial-access/{id}
export def "delete-realm-clients-initial-access-id" [
  realm: string
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
    path: "/{realm}/clients-initial-access/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the mapper
#
# DELETE /{realm}/clients/{id1}/protocol-mappers/models/{id2}
export def "delete-realm-clients-id1-protocol-mappers-models-id2" [
  realm: string
  id1: string
  id2: string
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
    path: "/{realm}/clients/{id1}/protocol-mappers/models/{id2}"
    path_params: [{name: realm, var: realm}, {name: id1, var: id1}, {name: id2, var: id2}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id1: $id1, id2: $id2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mapper by id
#
# GET /{realm}/clients/{id1}/protocol-mappers/models/{id2}
# Returns: record<config: record, id: string, name: string, protocol: string, protocolMapper: string>
export def "get-realm-clients-id1-protocol-mappers-models-id2" [
  realm: string
  id1: string
  id2: string
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
    path: "/{realm}/clients/{id1}/protocol-mappers/models/{id2}"
    path_params: [{name: realm, var: realm}, {name: id1, var: id1}, {name: id2, var: id2}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id1: $id1, id2: $id2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the mapper
#
# PUT /{realm}/clients/{id1}/protocol-mappers/models/{id2}
export def "put-realm-clients-id1-protocol-mappers-models-id2" [
  realm: string
  id1: string
  id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --name: string
  --protocol: string
  --protocol-mapper: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/clients/{id1}/protocol-mappers/models/{id2}"
    path_params: [{name: realm, var: realm}, {name: id1, var: id1}, {name: id2, var: id2}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: id, var: id}, {name: name, var: name}, {name: protocol, var: protocol}, {name: protocolMapper, var: protocol_mapper}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id1: $id1, id2: $id2, config: $config, id: $id, name: $name, protocol: $protocol, protocol_mapper: $protocol_mapper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the client
#
# DELETE /{realm}/clients/{id}
export def "delete-realm-clients-id" [
  realm: string
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
    path: "/{realm}/clients/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get representation of the client
#
# GET /{realm}/clients/{id}
# Returns: record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>>
export def "get-realm-clients-id" [
  realm: string
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
    path: "/{realm}/clients/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the client
#
# PUT /{realm}/clients/{id}
export def "put-realm-clients-id" [
  realm: string
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
  --access: record
  --admin-url: string
  --always-display-in-console: oneof<nothing, bool>
  --attributes: record
  --authentication-flow-binding-overrides: record
  --authorization-services-enabled: oneof<nothing, bool>
  --authorization-settings: record # shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
  --body-base-url: string # (spec name: baseUrl)
  --bearer-only: oneof<nothing, bool>
  --client-authenticator-type: string
  --client-id: string
  --consent-required: oneof<nothing, bool>
  --default-client-scopes: list<string>
  --default-roles: list<string>
  --description: string
  --direct-access-grants-enabled: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --frontchannel-logout: oneof<nothing, bool>
  --full-scope-allowed: oneof<nothing, bool>
  --body-id: string # (spec name: id)
  --implicit-flow-enabled: oneof<nothing, bool>
  --name: string
  --node-re-registration-timeout: int # format: int32
  --not-before: int # format: int32
  --optional-client-scopes: list<string>
  --origin: string
  --protocol: string
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --public-client: oneof<nothing, bool>
  --redirect-uris: list<string>
  --registered-nodes: record
  --registration-access-token: string
  --root-url: string
  --secret: string
  --service-accounts-enabled: oneof<nothing, bool>
  --standard-flow-enabled: oneof<nothing, bool>
  --surrogate-auth-required: oneof<nothing, bool>
  --web-origins: list<string>
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/clients/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: adminUrl, var: admin_url}, {name: alwaysDisplayInConsole, var: always_display_in_console}, {name: attributes, var: attributes}, {name: authenticationFlowBindingOverrides, var: authentication_flow_binding_overrides}, {name: authorizationServicesEnabled, var: authorization_services_enabled}, {name: authorizationSettings, var: authorization_settings}, {name: baseUrl, var: body_base_url}, {name: bearerOnly, var: bearer_only}, {name: clientAuthenticatorType, var: client_authenticator_type}, {name: clientId, var: client_id}, {name: consentRequired, var: consent_required}, {name: defaultClientScopes, var: default_client_scopes}, {name: defaultRoles, var: default_roles}, {name: description, var: description}, {name: directAccessGrantsEnabled, var: direct_access_grants_enabled}, {name: enabled, var: enabled}, {name: frontchannelLogout, var: frontchannel_logout}, {name: fullScopeAllowed, var: full_scope_allowed}, {name: id, var: body_id}, {name: implicitFlowEnabled, var: implicit_flow_enabled}, {name: name, var: name}, {name: nodeReRegistrationTimeout, var: node_re_registration_timeout}, {name: notBefore, var: not_before}, {name: optionalClientScopes, var: optional_client_scopes}, {name: origin, var: origin}, {name: protocol, var: protocol}, {name: protocolMappers, var: protocol_mappers}, {name: publicClient, var: public_client}, {name: redirectUris, var: redirect_uris}, {name: registeredNodes, var: registered_nodes}, {name: registrationAccessToken, var: registration_access_token}, {name: rootUrl, var: root_url}, {name: secret, var: secret}, {name: serviceAccountsEnabled, var: service_accounts_enabled}, {name: standardFlowEnabled, var: standard_flow_enabled}, {name: surrogateAuthRequired, var: surrogate_auth_required}, {name: webOrigins, var: web_origins}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, access: $access, admin_url: $admin_url, always_display_in_console: $always_display_in_console, attributes: $attributes, authentication_flow_binding_overrides: $authentication_flow_binding_overrides, authorization_services_enabled: $authorization_services_enabled, authorization_settings: $authorization_settings, body_base_url: $body_base_url, bearer_only: $bearer_only, client_authenticator_type: $client_authenticator_type, client_id: $client_id, consent_required: $consent_required, default_client_scopes: $default_client_scopes, default_roles: $default_roles, description: $description, direct_access_grants_enabled: $direct_access_grants_enabled, enabled: $enabled, frontchannel_logout: $frontchannel_logout, full_scope_allowed: $full_scope_allowed, body_id: $body_id, implicit_flow_enabled: $implicit_flow_enabled, name: $name, node_re_registration_timeout: $node_re_registration_timeout, not_before: $not_before, optional_client_scopes: $optional_client_scopes, origin: $origin, protocol: $protocol, protocol_mappers: $protocol_mappers, public_client: $public_client, redirect_uris: $redirect_uris, registered_nodes: $registered_nodes, registration_access_token: $registration_access_token, root_url: $root_url, secret: $secret, service_accounts_enabled: $service_accounts_enabled, standard_flow_enabled: $standard_flow_enabled, surrogate_auth_required: $surrogate_auth_required, web_origins: $web_origins
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get key info
#
# GET /{realm}/clients/{id}/certificates/{attr}
# Returns: record<certificate: string, kid: string, privateKey: string, publicKey: string>
export def "get-realm-clients-id-certificates-attr" [
  realm: string
  id: string
  attr: string
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
    path: "/{realm}/clients/{id}/certificates/{attr}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: attr, var: attr}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, attr: $attr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a keystore file for the client, containing private key and public certificate
#
# POST /{realm}/clients/{id}/certificates/{attr}/download
# Returns: string
export def "post-realm-clients-id-certificates-attr-download" [
  realm: string
  id: string
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --key-alias: string
  --key-password: string
  --realm-alias: string
  --realm-certificate: oneof<nothing, bool>
  --store-password: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/clients/{id}/certificates/{attr}/download"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: attr, var: attr}]
    body: {content_type: "application/json", kind: json, fields: [{name: format, var: format}, {name: keyAlias, var: key_alias}, {name: keyPassword, var: key_password}, {name: realmAlias, var: realm_alias}, {name: realmCertificate, var: realm_certificate}, {name: storePassword, var: store_password}]}
    accept: ["application/octet-stream"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, attr: $attr, format: $format, key_alias: $key_alias, key_password: $key_password, realm_alias: $realm_alias, realm_certificate: $realm_certificate, store_password: $store_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a new certificate with new key pair
#
# POST /{realm}/clients/{id}/certificates/{attr}/generate
# Returns: record<certificate: string, kid: string, privateKey: string, publicKey: string>
export def "post-realm-clients-id-certificates-attr-generate" [
  realm: string
  id: string
  attr: string
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
    path: "/{realm}/clients/{id}/certificates/{attr}/generate"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: attr, var: attr}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, attr: $attr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a new keypair and certificate, and get the private key file Generates a keypair and certificate and serves the private key in a specified keystore format.
#
# POST /{realm}/clients/{id}/certificates/{attr}/generate-and-download
# Returns: string
export def "post-realm-clients-id-certificates-attr-generate-and-download" [
  realm: string
  id: string
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --key-alias: string
  --key-password: string
  --realm-alias: string
  --realm-certificate: oneof<nothing, bool>
  --store-password: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/clients/{id}/certificates/{attr}/generate-and-download"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: attr, var: attr}]
    body: {content_type: "application/json", kind: json, fields: [{name: format, var: format}, {name: keyAlias, var: key_alias}, {name: keyPassword, var: key_password}, {name: realmAlias, var: realm_alias}, {name: realmCertificate, var: realm_certificate}, {name: storePassword, var: store_password}]}
    accept: ["application/octet-stream"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, attr: $attr, format: $format, key_alias: $key_alias, key_password: $key_password, realm_alias: $realm_alias, realm_certificate: $realm_certificate, store_password: $store_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload certificate and eventually private key
#
# POST /{realm}/clients/{id}/certificates/{attr}/upload
# Returns: record<certificate: string, kid: string, privateKey: string, publicKey: string>
export def "post-realm-clients-id-certificates-attr-upload" [
  realm: string
  id: string
  attr: string
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
    path: "/{realm}/clients/{id}/certificates/{attr}/upload"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: attr, var: attr}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, attr: $attr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload only certificate, not private key
#
# POST /{realm}/clients/{id}/certificates/{attr}/upload-certificate
# Returns: record<certificate: string, kid: string, privateKey: string, publicKey: string>
export def "post-realm-clients-id-certificates-attr-upload-certificate" [
  realm: string
  id: string
  attr: string
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
    path: "/{realm}/clients/{id}/certificates/{attr}/upload-certificate"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: attr, var: attr}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, attr: $attr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the client secret
#
# GET /{realm}/clients/{id}/client-secret
# Returns: record<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>
export def "get-realm-clients-id-client-secret" [
  realm: string
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
    path: "/{realm}/clients/{id}/client-secret"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a new secret for the client
#
# POST /{realm}/clients/{id}/client-secret
# Returns: record<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>
export def "post-realm-clients-id-client-secret" [
  realm: string
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
    path: "/{realm}/clients/{id}/client-secret"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get default client scopes.
#
# GET /{realm}/clients/{id}/default-client-scopes
# Returns: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>
export def "get-realm-clients-id-default-client-scopes" [
  realm: string
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
    path: "/{realm}/clients/{id}/default-client-scopes"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/clients/{id}/default-client-scopes/{clientScopeId}
export def "delete-realm-clients-id-default-client-scopes-client-scope-id" [
  realm: string
  id: string
  client_scope_id: string
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
    path: "/{realm}/clients/{id}/default-client-scopes/{clientScopeId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: clientScopeId, var: client_scope_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client_scope_id: $client_scope_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{realm}/clients/{id}/default-client-scopes/{clientScopeId}
export def "put-realm-clients-id-default-client-scopes-client-scope-id" [
  realm: string
  id: string
  client_scope_id: string
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
    path: "/{realm}/clients/{id}/default-client-scopes/{clientScopeId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: clientScopeId, var: client_scope_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client_scope_id: $client_scope_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create JSON with payload of example access token
#
# GET /{realm}/clients/{id}/evaluate-scopes/generate-example-access-token
# Returns: record<acr: string, address: record<country: string, formatted: string, locality: string, postal_code: string, region: string, street_address: string>, allowed-origins: list<string>, at_hash: string, auth_time: int, authorization: record<permissions: list<record>>, azp: string, birthdate: string, c_hash: string, category: string, claims_locales: string, cnf: record<"x5t#S256": string>, email: string, email_verified: bool, exp: int, family_name: string, gender: string, given_name: string, iat: int, iss: string, jti: string, locale: string, middle_name: string, name: string, nbf: int, nickname: string, nonce: string, otherClaims: record, phone_number: string, phone_number_verified: bool, picture: string, preferred_username: string, profile: string, realm_access: record<roles: list<string>, verify_caller: bool>, s_hash: string, scope: string, session_state: string, sub: string, trusted-certs: list<string>, typ: string, updated_at: int, website: string, zoneinfo: string>
export def "get-realm-clients-id-evaluate-scopes-generate-example-access-token" [
  realm: string
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
  --scope: string
  --user-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/evaluate-scopes/generate-example-access-token"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: scope, var: scope}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, scope: $scope, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return list of all protocol mappers, which will be used when generating tokens issued for particular client.
#
# GET /{realm}/clients/{id}/evaluate-scopes/protocol-mappers
# Returns: table<containerId: string, containerName: string, containerType: string, mapperId: string, mapperName: string, protocolMapper: string>
export def "get-realm-clients-id-evaluate-scopes-protocol-mappers" [
  realm: string
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
  --scope: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/evaluate-scopes/protocol-mappers"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: scope, var: scope}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective scope mapping of all roles of particular role container, which this client is defacto allowed to have in the accessToken issued for him.
#
# GET /{realm}/clients/{id}/evaluate-scopes/scope-mappings/{roleContainerId}/granted
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-evaluate-scopes-scope-mappings-role-container-id-granted" [
  realm: string
  id: string
  role_container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/evaluate-scopes/scope-mappings/{roleContainerId}/granted"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: roleContainerId, var: role_container_id}]
    query: [{name: scope, var: scope}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_container_id: $role_container_id, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get roles, which this client doesn’t have scope for and can’t have them in the accessToken issued for him.
#
# GET /{realm}/clients/{id}/evaluate-scopes/scope-mappings/{roleContainerId}/not-granted
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-evaluate-scopes-scope-mappings-role-container-id-not-granted" [
  realm: string
  id: string
  role_container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/evaluate-scopes/scope-mappings/{roleContainerId}/not-granted"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: roleContainerId, var: role_container_id}]
    query: [{name: scope, var: scope}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_container_id: $role_container_id, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/clients/{id}/installation/providers/{providerId}
export def "get-realm-clients-id-installation-providers-provider-id" [
  realm: string
  id: string
  provider_id: string
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
    path: "/{realm}/clients/{id}/installation/providers/{providerId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# GET /{realm}/clients/{id}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "get-realm-clients-id-management-permissions" [
  realm: string
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
    path: "/{realm}/clients/{id}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/clients/{id}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "put-realm-clients-id-management-permissions" [
  realm: string
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
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{realm}/clients/{id}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: resource, var: resource}, {name: scopePermissions, var: scope_permissions}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, enabled: $enabled, resource: $resource, scope_permissions: $scope_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a cluster node with the client Manually register cluster node to this client - usually it’s not needed to call this directly as adapter should handle by sending registration request to Keycloak
#
# POST /{realm}/clients/{id}/nodes
export def "post-realm-clients-id-nodes" [
  realm: string
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
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/clients/{id}/nodes"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregister a cluster node from the client
#
# DELETE /{realm}/clients/{id}/nodes/{node}
export def "delete-realm-clients-id-nodes-node" [
  realm: string
  id: string
  node: string
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
    path: "/{realm}/clients/{id}/nodes/{node}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: node, var: node}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, node: $node
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get application offline session count Returns a number of offline user sessions associated with this client { "count": number }
#
# GET /{realm}/clients/{id}/offline-session-count
# Returns: record
export def "get-realm-clients-id-offline-session-count" [
  realm: string
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
    path: "/{realm}/clients/{id}/offline-session-count"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get offline sessions for client Returns a list of offline user sessions associated with this client
#
# GET /{realm}/clients/{id}/offline-sessions
# Returns: table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string>
export def "get-realm-clients-id-offline-sessions" [
  realm: string
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
  --first: int # Paging offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/offline-sessions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: first, var: first}, {name: max, var: max}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, first: $first, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get optional client scopes.
#
# GET /{realm}/clients/{id}/optional-client-scopes
# Returns: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>
export def "get-realm-clients-id-optional-client-scopes" [
  realm: string
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
    path: "/{realm}/clients/{id}/optional-client-scopes"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/clients/{id}/optional-client-scopes/{clientScopeId}
export def "delete-realm-clients-id-optional-client-scopes-client-scope-id" [
  realm: string
  id: string
  client_scope_id: string
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
    path: "/{realm}/clients/{id}/optional-client-scopes/{clientScopeId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: clientScopeId, var: client_scope_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client_scope_id: $client_scope_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{realm}/clients/{id}/optional-client-scopes/{clientScopeId}
export def "put-realm-clients-id-optional-client-scopes-client-scope-id" [
  realm: string
  id: string
  client_scope_id: string
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
    path: "/{realm}/clients/{id}/optional-client-scopes/{clientScopeId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: clientScopeId, var: client_scope_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client_scope_id: $client_scope_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create multiple mappers
#
# POST /{realm}/clients/{id}/protocol-mappers/add-models
export def "post-realm-clients-id-protocol-mappers-add-models" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/clients/{id}/protocol-mappers/add-models"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mappers
#
# GET /{realm}/clients/{id}/protocol-mappers/models
# Returns: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>
export def "get-realm-clients-id-protocol-mappers-models" [
  realm: string
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
    path: "/{realm}/clients/{id}/protocol-mappers/models"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a mapper
#
# POST /{realm}/clients/{id}/protocol-mappers/models
export def "post-realm-clients-id-protocol-mappers-models" [
  realm: string
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
  --config: record
  --body-id: string # (spec name: id)
  --name: string
  --protocol: string
  --protocol-mapper: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/clients/{id}/protocol-mappers/models"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: id, var: body_id}, {name: name, var: name}, {name: protocol, var: protocol}, {name: protocolMapper, var: protocol_mapper}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, config: $config, body_id: $body_id, name: $name, protocol: $protocol, protocol_mapper: $protocol_mapper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mappers by name for a specific protocol
#
# GET /{realm}/clients/{id}/protocol-mappers/protocol/{protocol}
# Returns: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>
export def "get-realm-clients-id-protocol-mappers-protocol-protocol" [
  realm: string
  id: string
  protocol: string
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
    path: "/{realm}/clients/{id}/protocol-mappers/protocol/{protocol}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: protocol, var: protocol}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, protocol: $protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push the client’s revocation policy to its admin URL If the client has an admin URL, push revocation policy to it.
#
# POST /{realm}/clients/{id}/push-revocation
# Returns: record<failedRequests: list<string>, successRequests: list<string>>
export def "post-realm-clients-id-push-revocation" [
  realm: string
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
    path: "/{realm}/clients/{id}/push-revocation"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a new registration access token for the client
#
# POST /{realm}/clients/{id}/registration-access-token
# Returns: record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>>
export def "post-realm-clients-id-registration-access-token" [
  realm: string
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
    path: "/{realm}/clients/{id}/registration-access-token"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for the realm or client
#
# GET /{realm}/clients/{id}/roles
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-roles" [
  realm: string
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
  --brief-representation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/roles"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: briefRepresentation, var: brief_representation}, {name: first, var: first}, {name: max, var: max}, {name: search, var: search}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, brief_representation: $brief_representation, first: $first, max: $max, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new role for the realm or client
#
# POST /{realm}/clients/{id}/roles
export def "post-realm-clients-id-roles" [
  realm: string
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
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --body-id: string # (spec name: id)
  --name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/clients/{id}/roles"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: clientRole, var: client_role}, {name: composite, var: composite}, {name: composites, var: composites}, {name: containerId, var: container_id}, {name: description, var: description}, {name: id, var: body_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, attributes: $attributes, client_role: $client_role, composite: $composite, composites: $composites, container_id: $container_id, description: $description, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role by name
#
# DELETE /{realm}/clients/{id}/roles/{role-name}
export def "delete-realm-clients-id-roles-role-name" [
  realm: string
  id: string
  role_name: string
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
    path: "/{realm}/clients/{id}/roles/{role-name}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a role by name
#
# GET /{realm}/clients/{id}/roles/{role-name}
# Returns: record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-roles-role-name" [
  realm: string
  id: string
  role_name: string
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
    path: "/{realm}/clients/{id}/roles/{role-name}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role by name
#
# PUT /{realm}/clients/{id}/roles/{role-name}
export def "put-realm-clients-id-roles-role-name" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --body-id: string # (spec name: id)
  --name: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/clients/{id}/roles/{role-name}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: clientRole, var: client_role}, {name: composite, var: composite}, {name: composites, var: composites}, {name: containerId, var: container_id}, {name: description, var: description}, {name: id, var: body_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name, attributes: $attributes, client_role: $client_role, composite: $composite, composites: $composites, container_id: $container_id, description: $description, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove roles from the role’s composite
#
# DELETE /{realm}/clients/{id}/roles/{role-name}/composites
export def "delete-realm-clients-id-roles-role-name-composites" [
  realm: string
  id: string
  role_name: string
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
    method: delete
    path: "/{realm}/clients/{id}/roles/{role-name}/composites"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get composites of the role
#
# GET /{realm}/clients/{id}/roles/{role-name}/composites
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-roles-role-name-composites" [
  realm: string
  id: string
  role_name: string
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
    path: "/{realm}/clients/{id}/roles/{role-name}/composites"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a composite to the role
#
# POST /{realm}/clients/{id}/roles/{role-name}/composites
export def "post-realm-clients-id-roles-role-name-composites" [
  realm: string
  id: string
  role_name: string
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
    path: "/{realm}/clients/{id}/roles/{role-name}/composites"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An app-level roles for the specified app for the role’s composite
#
# GET /{realm}/clients/{id}/roles/{role-name}/composites/clients/{client}
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-roles-role-name-composites-clients-client" [
  realm: string
  id: string
  role_name: string
  client: string
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
    path: "/{realm}/clients/{id}/roles/{role-name}/composites/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles of the role’s composite
#
# GET /{realm}/clients/{id}/roles/{role-name}/composites/realm
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-roles-role-name-composites-realm" [
  realm: string
  id: string
  role_name: string
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
    path: "/{realm}/clients/{id}/roles/{role-name}/composites/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return List of Groups that have the specified role name
#
# GET /{realm}/clients/{id}/roles/{role-name}/groups
# Returns: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>
export def "get-realm-clients-id-roles-role-name-groups" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool> # if false, return a full representation of the GroupRepresentation objects
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/roles/{role-name}/groups"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    query: [{name: briefRepresentation, var: brief_representation}, {name: first, var: first}, {name: max, var: max}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name, brief_representation: $brief_representation, first: $first, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# GET /{realm}/clients/{id}/roles/{role-name}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "get-realm-clients-id-roles-role-name-management-permissions" [
  realm: string
  id: string
  role_name: string
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
    path: "/{realm}/clients/{id}/roles/{role-name}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/clients/{id}/roles/{role-name}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "put-realm-clients-id-roles-role-name-management-permissions" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{realm}/clients/{id}/roles/{role-name}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: resource, var: resource}, {name: scopePermissions, var: scope_permissions}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name, enabled: $enabled, resource: $resource, scope_permissions: $scope_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return List of Users that have the specified role name
#
# GET /{realm}/clients/{id}/roles/{role-name}/users
# Returns: table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>
export def "get-realm-clients-id-roles-role-name-users" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/roles/{role-name}/users"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: role-name, var: role_name}]
    query: [{name: first, var: first}, {name: max, var: max}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, role_name: $role_name, first: $first, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all scope mappings for the client
#
# GET /{realm}/clients/{id}/scope-mappings
# Returns: record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>>
export def "get-realm-clients-id-scope-mappings" [
  realm: string
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
    path: "/{realm}/clients/{id}/scope-mappings"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove client-level roles from the client’s scope.
#
# DELETE /{realm}/clients/{id}/scope-mappings/clients/{client}
export def "delete-realm-clients-id-scope-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    method: delete
    path: "/{realm}/clients/{id}/scope-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the roles associated with a client’s scope Returns roles for the client.
#
# GET /{realm}/clients/{id}/scope-mappings/clients/{client}
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-scope-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/clients/{id}/scope-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add client-level roles to the client’s scope
#
# POST /{realm}/clients/{id}/scope-mappings/clients/{client}
export def "post-realm-clients-id-scope-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/clients/{id}/scope-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The available client-level roles Returns the roles for the client that can be associated with the client’s scope
#
# GET /{realm}/clients/{id}/scope-mappings/clients/{client}/available
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-scope-mappings-clients-client-available" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/clients/{id}/scope-mappings/clients/{client}/available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective client roles Returns the roles for the client that are associated with the client’s scope.
#
# GET /{realm}/clients/{id}/scope-mappings/clients/{client}/composite
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-scope-mappings-clients-client-composite" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/clients/{id}/scope-mappings/clients/{client}/composite"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a set of realm-level roles from the client’s scope
#
# DELETE /{realm}/clients/{id}/scope-mappings/realm
export def "delete-realm-clients-id-scope-mappings-realm" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/{realm}/clients/{id}/scope-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles associated with the client’s scope
#
# GET /{realm}/clients/{id}/scope-mappings/realm
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-scope-mappings-realm" [
  realm: string
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
    path: "/{realm}/clients/{id}/scope-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a set of realm-level roles to the client’s scope
#
# POST /{realm}/clients/{id}/scope-mappings/realm
export def "post-realm-clients-id-scope-mappings-realm" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/clients/{id}/scope-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles that are available to attach to this client’s scope
#
# GET /{realm}/clients/{id}/scope-mappings/realm/available
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-scope-mappings-realm-available" [
  realm: string
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
    path: "/{realm}/clients/{id}/scope-mappings/realm/available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective realm-level roles associated with the client’s scope What this does is recurse any composite roles associated with the client’s scope and adds the roles to this lists.
#
# GET /{realm}/clients/{id}/scope-mappings/realm/composite
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-clients-id-scope-mappings-realm-composite" [
  realm: string
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
    path: "/{realm}/clients/{id}/scope-mappings/realm/composite"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user dedicated to the service account
#
# GET /{realm}/clients/{id}/service-account-user
# Returns: record<access: record, attributes: record, clientConsents: table<clientId: string, createdDate: int, grantedClientScopes: list, lastUpdatedDate: int>, clientRoles: record, createdTimestamp: int, credentials: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: table<identityProvider: string, userId: string, userName: string>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>
export def "get-realm-clients-id-service-account-user" [
  realm: string
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
    path: "/{realm}/clients/{id}/service-account-user"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get application session count Returns a number of user sessions associated with this client { "count": number }
#
# GET /{realm}/clients/{id}/session-count
# Returns: record
export def "get-realm-clients-id-session-count" [
  realm: string
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
    path: "/{realm}/clients/{id}/session-count"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test if registered cluster nodes are available Tests availability by sending 'ping' request to all cluster nodes.
#
# GET /{realm}/clients/{id}/test-nodes-available
# Returns: record<failedRequests: list<string>, successRequests: list<string>>
export def "get-realm-clients-id-test-nodes-available" [
  realm: string
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
    path: "/{realm}/clients/{id}/test-nodes-available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user sessions for client Returns a list of user sessions associated with this client
#
# GET /{realm}/clients/{id}/user-sessions
# Returns: table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string>
export def "get-realm-clients-id-user-sessions" [
  realm: string
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
  --first: int # Paging offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/clients/{id}/user-sessions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: first, var: first}, {name: max, var: max}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, first: $first, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/components
#
# Returns: table<config: record<empty: bool, loadFactor: float, threshold: int>, id: string, name: string, parentId: string, providerId: string, providerType: string, subType: string>
export def "get-realm-components" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --parent: string
  --type: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/components"
    path_params: [{name: realm, var: realm}]
    query: [{name: name, var: name}, {name: parent, var: parent}, {name: type, var: type}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, name: $name, parent: $parent, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{realm}/components
export def "post-realm-components" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --id: string
  --name: string
  --parent-id: string
  --provider-id: string
  --provider-type: string
  --sub-type: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/components"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: id, var: id}, {name: name, var: name}, {name: parentId, var: parent_id}, {name: providerId, var: provider_id}, {name: providerType, var: provider_type}, {name: subType, var: sub_type}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, config: $config, id: $id, name: $name, parent_id: $parent_id, provider_id: $provider_id, provider_type: $provider_type, sub_type: $sub_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/components/{id}
export def "delete-realm-components-id" [
  realm: string
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
    path: "/{realm}/components/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/components/{id}
#
# Returns: record<config: record<empty: bool, loadFactor: float, threshold: int>, id: string, name: string, parentId: string, providerId: string, providerType: string, subType: string>
export def "get-realm-components-id" [
  realm: string
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
    path: "/{realm}/components/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{realm}/components/{id}
export def "put-realm-components-id" [
  realm: string
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
  --config: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --body-id: string # (spec name: id)
  --name: string
  --parent-id: string
  --provider-id: string
  --provider-type: string
  --sub-type: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/components/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: id, var: body_id}, {name: name, var: name}, {name: parentId, var: parent_id}, {name: providerId, var: provider_id}, {name: providerType, var: provider_type}, {name: subType, var: sub_type}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, config: $config, body_id: $body_id, name: $name, parent_id: $parent_id, provider_id: $provider_id, provider_type: $provider_type, sub_type: $sub_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of subcomponent types that are available to configure for a particular parent component.
#
# GET /{realm}/components/{id}/sub-component-types
# Returns: table<helpText: string, id: string, metadata: record, properties: list<record>>
export def "get-realm-components-id-sub-component-types" [
  realm: string
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
  --type: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/components/{id}/sub-component-types"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: type, var: type}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/credential-registrators
#
# Returns: list<string>
export def "get-realm-credential-registrators" [
  realm: string
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
    path: "/{realm}/credential-registrators"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm default client scopes.
#
# GET /{realm}/default-default-client-scopes
# Returns: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>
export def "get-realm-default-default-client-scopes" [
  realm: string
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
    path: "/{realm}/default-default-client-scopes"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/default-default-client-scopes/{clientScopeId}
export def "delete-realm-default-default-client-scopes-client-scope-id" [
  realm: string
  client_scope_id: string
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
    path: "/{realm}/default-default-client-scopes/{clientScopeId}"
    path_params: [{name: realm, var: realm}, {name: clientScopeId, var: client_scope_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, client_scope_id: $client_scope_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{realm}/default-default-client-scopes/{clientScopeId}
export def "put-realm-default-default-client-scopes-client-scope-id" [
  realm: string
  client_scope_id: string
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
    path: "/{realm}/default-default-client-scopes/{clientScopeId}"
    path_params: [{name: realm, var: realm}, {name: clientScopeId, var: client_scope_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, client_scope_id: $client_scope_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group hierarchy.
#
# GET /{realm}/default-groups
# Returns: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>
export def "get-realm-default-groups" [
  realm: string
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
    path: "/{realm}/default-groups"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/default-groups/{groupId}
export def "delete-realm-default-groups-group-id" [
  realm: string
  group_id: string
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
    path: "/{realm}/default-groups/{groupId}"
    path_params: [{name: realm, var: realm}, {name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{realm}/default-groups/{groupId}
export def "put-realm-default-groups-group-id" [
  realm: string
  group_id: string
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
    path: "/{realm}/default-groups/{groupId}"
    path_params: [{name: realm, var: realm}, {name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm optional client scopes.
#
# GET /{realm}/default-optional-client-scopes
# Returns: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>>
export def "get-realm-default-optional-client-scopes" [
  realm: string
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
    path: "/{realm}/default-optional-client-scopes"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/default-optional-client-scopes/{clientScopeId}
export def "delete-realm-default-optional-client-scopes-client-scope-id" [
  realm: string
  client_scope_id: string
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
    path: "/{realm}/default-optional-client-scopes/{clientScopeId}"
    path_params: [{name: realm, var: realm}, {name: clientScopeId, var: client_scope_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, client_scope_id: $client_scope_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{realm}/default-optional-client-scopes/{clientScopeId}
export def "put-realm-default-optional-client-scopes-client-scope-id" [
  realm: string
  client_scope_id: string
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
    path: "/{realm}/default-optional-client-scopes/{clientScopeId}"
    path_params: [{name: realm, var: realm}, {name: clientScopeId, var: client_scope_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, client_scope_id: $client_scope_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all events
#
# DELETE /{realm}/events
export def "delete-realm-events" [
  realm: string
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
    path: "/{realm}/events"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get events Returns all events, or filters them based on URL query parameters listed here
#
# GET /{realm}/events
# Returns: table<clientId: string, details: record, error: string, ipAddress: string, realmId: string, sessionId: string, time: int, type: string, userId: string>
export def "get-realm-events" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client: string # App or oauth client name
  --date-from: string # From date
  --date-to: string # To date
  --first: int # Paging offset (format: int32)
  --ip-address: string # IP address
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --type: list<string> # The types of events to return
  --user: string # User id
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/events"
    path_params: [{name: realm, var: realm}]
    query: [{name: client, var: client}, {name: dateFrom, var: date_from}, {name: dateTo, var: date_to}, {name: first, var: first}, {name: ipAddress, var: ip_address}, {name: max, var: max}, {name: type, var: type, style: multi}, {name: user, var: user}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, client: $client, date_from: $date_from, date_to: $date_to, first: $first, ip_address: $ip_address, max: $max, type: $type, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the events provider configuration Returns JSON object with events provider configuration
#
# GET /{realm}/events/config
# Returns: record<adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>>
export def "get-realm-events-config" [
  realm: string
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
    path: "/{realm}/events/config"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the events provider Change the events provider and/or its configuration
#
# PUT /{realm}/events/config
export def "put-realm-events-config" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-events-details-enabled: oneof<nothing, bool>
  --admin-events-enabled: oneof<nothing, bool>
  --enabled-event-types: list<string>
  --events-enabled: oneof<nothing, bool>
  --events-expiration: int # format: int64
  --events-listeners: list<string>
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/events/config"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminEventsDetailsEnabled, var: admin_events_details_enabled}, {name: adminEventsEnabled, var: admin_events_enabled}, {name: enabledEventTypes, var: enabled_event_types}, {name: eventsEnabled, var: events_enabled}, {name: eventsExpiration, var: events_expiration}, {name: eventsListeners, var: events_listeners}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, admin_events_details_enabled: $admin_events_details_enabled, admin_events_enabled: $admin_events_enabled, enabled_event_types: $enabled_event_types, events_enabled: $events_enabled, events_expiration: $events_expiration, events_listeners: $events_listeners
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/group-by-path/{path}
#
# Returns: record<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>
export def "get-realm-group-by-path-path" [
  realm: string
  path: string
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
    path: "/{realm}/group-by-path/{path}"
    path_params: [{name: realm, var: realm}, {name: path, var: path}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group hierarchy.
#
# GET /{realm}/groups
# Returns: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>
export def "get-realm-groups" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/groups"
    path_params: [{name: realm, var: realm}]
    query: [{name: briefRepresentation, var: brief_representation}, {name: first, var: first}, {name: max, var: max}, {name: search, var: search}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, brief_representation: $brief_representation, first: $first, max: $max, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create or add a top level realm groupSet or create child.
#
# POST /{realm}/groups
export def "post-realm-groups" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --client-roles: record
  --id: string
  --name: string
  --path: string
  --realm-roles: list<string>
  --sub-groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/groups"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: attributes, var: attributes}, {name: clientRoles, var: client_roles}, {name: id, var: id}, {name: name, var: name}, {name: path, var: path}, {name: realmRoles, var: realm_roles}, {name: subGroups, var: sub_groups}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, access: $access, attributes: $attributes, client_roles: $client_roles, id: $id, name: $name, path: $path, realm_roles: $realm_roles, sub_groups: $sub_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the groups counts.
#
# GET /{realm}/groups/count
# Returns: record
export def "get-realm-groups-count" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
  --top: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/groups/count"
    path_params: [{name: realm, var: realm}]
    query: [{name: search, var: search}, {name: top, var: top}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, search: $search, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/groups/{id}
export def "delete-realm-groups-id" [
  realm: string
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
    path: "/{realm}/groups/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/groups/{id}
#
# Returns: record<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>
export def "get-realm-groups-id" [
  realm: string
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
    path: "/{realm}/groups/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update group, ignores subgroups.
#
# PUT /{realm}/groups/{id}
export def "put-realm-groups-id" [
  realm: string
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
  --access: record
  --attributes: record
  --client-roles: record
  --body-id: string # (spec name: id)
  --name: string
  --path: string
  --realm-roles: list<string>
  --sub-groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/groups/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: attributes, var: attributes}, {name: clientRoles, var: client_roles}, {name: id, var: body_id}, {name: name, var: name}, {name: path, var: path}, {name: realmRoles, var: realm_roles}, {name: subGroups, var: sub_groups}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, access: $access, attributes: $attributes, client_roles: $client_roles, body_id: $body_id, name: $name, path: $path, realm_roles: $realm_roles, sub_groups: $sub_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set or create child.
#
# POST /{realm}/groups/{id}/children
export def "post-realm-groups-id-children" [
  realm: string
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
  --access: record
  --attributes: record
  --client-roles: record
  --body-id: string # (spec name: id)
  --name: string
  --path: string
  --realm-roles: list<string>
  --sub-groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/groups/{id}/children"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: attributes, var: attributes}, {name: clientRoles, var: client_roles}, {name: id, var: body_id}, {name: name, var: name}, {name: path, var: path}, {name: realmRoles, var: realm_roles}, {name: subGroups, var: sub_groups}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, access: $access, attributes: $attributes, client_roles: $client_roles, body_id: $body_id, name: $name, path: $path, realm_roles: $realm_roles, sub_groups: $sub_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# GET /{realm}/groups/{id}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "get-realm-groups-id-management-permissions" [
  realm: string
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
    path: "/{realm}/groups/{id}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/groups/{id}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "put-realm-groups-id-management-permissions" [
  realm: string
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
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{realm}/groups/{id}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: resource, var: resource}, {name: scopePermissions, var: scope_permissions}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, enabled: $enabled, resource: $resource, scope_permissions: $scope_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users Returns a list of users, filtered according to query parameters
#
# GET /{realm}/groups/{id}/members
# Returns: table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>
export def "get-realm-groups-id-members" [
  realm: string
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
  --brief-representation: oneof<nothing, bool> # Only return basic information (only guaranteed to return id, username, created, first and last name, email, enabled state, email verification state, federation link, and access. Note that it means that namely user attributes, required actions, and not before are not returned.)
  --first: int # Pagination offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/groups/{id}/members"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: briefRepresentation, var: brief_representation}, {name: first, var: first}, {name: max, var: max}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, brief_representation: $brief_representation, first: $first, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get role mappings
#
# GET /{realm}/groups/{id}/role-mappings
# Returns: record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>>
export def "get-realm-groups-id-role-mappings" [
  realm: string
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
    path: "/{realm}/groups/{id}/role-mappings"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete client-level roles from user role mapping
#
# DELETE /{realm}/groups/{id}/role-mappings/clients/{client}
export def "delete-realm-groups-id-role-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    method: delete
    path: "/{realm}/groups/{id}/role-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get client-level role mappings for the user, and the app
#
# GET /{realm}/groups/{id}/role-mappings/clients/{client}
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-groups-id-role-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/groups/{id}/role-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add client-level roles to the user role mapping
#
# POST /{realm}/groups/{id}/role-mappings/clients/{client}
export def "post-realm-groups-id-role-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/groups/{id}/role-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get available client-level roles that can be mapped to the user
#
# GET /{realm}/groups/{id}/role-mappings/clients/{client}/available
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-groups-id-role-mappings-clients-client-available" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/groups/{id}/role-mappings/clients/{client}/available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective client-level role mappings This recurses any composite roles
#
# GET /{realm}/groups/{id}/role-mappings/clients/{client}/composite
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-groups-id-role-mappings-clients-client-composite" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/groups/{id}/role-mappings/clients/{client}/composite"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete realm-level role mappings
#
# DELETE /{realm}/groups/{id}/role-mappings/realm
export def "delete-realm-groups-id-role-mappings-realm" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/{realm}/groups/{id}/role-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level role mappings
#
# GET /{realm}/groups/{id}/role-mappings/realm
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-groups-id-role-mappings-realm" [
  realm: string
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
    path: "/{realm}/groups/{id}/role-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add realm-level role mappings to the user
#
# POST /{realm}/groups/{id}/role-mappings/realm
export def "post-realm-groups-id-role-mappings-realm" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/groups/{id}/role-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles that can be mapped
#
# GET /{realm}/groups/{id}/role-mappings/realm/available
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-groups-id-role-mappings-realm-available" [
  realm: string
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
    path: "/{realm}/groups/{id}/role-mappings/realm/available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective realm-level role mappings This will recurse all composite roles to get the result.
#
# GET /{realm}/groups/{id}/role-mappings/realm/composite
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-groups-id-role-mappings-realm-composite" [
  realm: string
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
    path: "/{realm}/groups/{id}/role-mappings/realm/composite"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import identity provider from uploaded JSON file
#
# POST /{realm}/identity-provider/import-config
# Returns: record
export def "post-realm-identity-provider-import-config" [
  realm: string
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
    path: "/{realm}/identity-provider/import-config"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get identity providers
#
# GET /{realm}/identity-provider/instances
# Returns: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>
export def "get-realm-identity-provider-instances" [
  realm: string
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
    path: "/{realm}/identity-provider/instances"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new identity provider
#
# POST /{realm}/identity-provider/instances
export def "post-realm-identity-provider-instances" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-read-token-role-on-create: oneof<nothing, bool>
  --alias: string
  --config: record
  --display-name: string
  --enabled: oneof<nothing, bool>
  --first-broker-login-flow-alias: string
  --internal-id: string
  --link-only: oneof<nothing, bool>
  --post-broker-login-flow-alias: string
  --provider-id: string
  --store-token: oneof<nothing, bool>
  --trust-email: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/identity-provider/instances"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: addReadTokenRoleOnCreate, var: add_read_token_role_on_create}, {name: alias, var: alias}, {name: config, var: config}, {name: displayName, var: display_name}, {name: enabled, var: enabled}, {name: firstBrokerLoginFlowAlias, var: first_broker_login_flow_alias}, {name: internalId, var: internal_id}, {name: linkOnly, var: link_only}, {name: postBrokerLoginFlowAlias, var: post_broker_login_flow_alias}, {name: providerId, var: provider_id}, {name: storeToken, var: store_token}, {name: trustEmail, var: trust_email}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, add_read_token_role_on_create: $add_read_token_role_on_create, alias: $alias, config: $config, display_name: $display_name, enabled: $enabled, first_broker_login_flow_alias: $first_broker_login_flow_alias, internal_id: $internal_id, link_only: $link_only, post_broker_login_flow_alias: $post_broker_login_flow_alias, provider_id: $provider_id, store_token: $store_token, trust_email: $trust_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the identity provider
#
# DELETE /{realm}/identity-provider/instances/{alias}
export def "delete-realm-identity-provider-instances-alias" [
  realm: string
  alias: string
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
    path: "/{realm}/identity-provider/instances/{alias}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the identity provider
#
# GET /{realm}/identity-provider/instances/{alias}
# Returns: record<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>
export def "get-realm-identity-provider-instances-alias" [
  realm: string
  alias: string
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
    path: "/{realm}/identity-provider/instances/{alias}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the identity provider
#
# PUT /{realm}/identity-provider/instances/{alias}
export def "put-realm-identity-provider-instances-alias" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-read-token-role-on-create: oneof<nothing, bool>
  --body-alias: string # (spec name: alias)
  --config: record
  --display-name: string
  --enabled: oneof<nothing, bool>
  --first-broker-login-flow-alias: string
  --internal-id: string
  --link-only: oneof<nothing, bool>
  --post-broker-login-flow-alias: string
  --provider-id: string
  --store-token: oneof<nothing, bool>
  --trust-email: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/identity-provider/instances/{alias}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    body: {content_type: "application/json", kind: json, fields: [{name: addReadTokenRoleOnCreate, var: add_read_token_role_on_create}, {name: alias, var: body_alias}, {name: config, var: config}, {name: displayName, var: display_name}, {name: enabled, var: enabled}, {name: firstBrokerLoginFlowAlias, var: first_broker_login_flow_alias}, {name: internalId, var: internal_id}, {name: linkOnly, var: link_only}, {name: postBrokerLoginFlowAlias, var: post_broker_login_flow_alias}, {name: providerId, var: provider_id}, {name: storeToken, var: store_token}, {name: trustEmail, var: trust_email}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, add_read_token_role_on_create: $add_read_token_role_on_create, body_alias: $body_alias, config: $config, display_name: $display_name, enabled: $enabled, first_broker_login_flow_alias: $first_broker_login_flow_alias, internal_id: $internal_id, link_only: $link_only, post_broker_login_flow_alias: $post_broker_login_flow_alias, provider_id: $provider_id, store_token: $store_token, trust_email: $trust_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export public broker configuration for identity provider
#
# GET /{realm}/identity-provider/instances/{alias}/export
export def "get-realm-identity-provider-instances-alias-export" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Format to use
]: nothing -> any {
  http-request {
    method: get
    path: "/{realm}/identity-provider/instances/{alias}/export"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    query: [{name: format, var: format}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# GET /{realm}/identity-provider/instances/{alias}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "get-realm-identity-provider-instances-alias-management-permissions" [
  realm: string
  alias: string
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
    path: "/{realm}/identity-provider/instances/{alias}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/identity-provider/instances/{alias}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "put-realm-identity-provider-instances-alias-management-permissions" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{realm}/identity-provider/instances/{alias}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: resource, var: resource}, {name: scopePermissions, var: scope_permissions}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, enabled: $enabled, resource: $resource, scope_permissions: $scope_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mapper types for identity provider
#
# GET /{realm}/identity-provider/instances/{alias}/mapper-types
export def "get-realm-identity-provider-instances-alias-mapper-types" [
  realm: string
  alias: string
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
    path: "/{realm}/identity-provider/instances/{alias}/mapper-types"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mappers for identity provider
#
# GET /{realm}/identity-provider/instances/{alias}/mappers
# Returns: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>
export def "get-realm-identity-provider-instances-alias-mappers" [
  realm: string
  alias: string
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
    path: "/{realm}/identity-provider/instances/{alias}/mappers"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a mapper to identity provider
#
# POST /{realm}/identity-provider/instances/{alias}/mappers
export def "post-realm-identity-provider-instances-alias-mappers" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --identity-provider-alias: string
  --identity-provider-mapper: string
  --name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/identity-provider/instances/{alias}/mappers"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: id, var: id}, {name: identityProviderAlias, var: identity_provider_alias}, {name: identityProviderMapper, var: identity_provider_mapper}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, config: $config, id: $id, identity_provider_alias: $identity_provider_alias, identity_provider_mapper: $identity_provider_mapper, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a mapper for the identity provider
#
# DELETE /{realm}/identity-provider/instances/{alias}/mappers/{id}
export def "delete-realm-identity-provider-instances-alias-mappers-id" [
  realm: string
  alias: string
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
    path: "/{realm}/identity-provider/instances/{alias}/mappers/{id}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mapper by id for the identity provider
#
# GET /{realm}/identity-provider/instances/{alias}/mappers/{id}
# Returns: record<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>
export def "get-realm-identity-provider-instances-alias-mappers-id" [
  realm: string
  alias: string
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
    path: "/{realm}/identity-provider/instances/{alias}/mappers/{id}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a mapper for the identity provider
#
# PUT /{realm}/identity-provider/instances/{alias}/mappers/{id}
export def "put-realm-identity-provider-instances-alias-mappers-id" [
  realm: string
  alias: string
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
  --config: record
  --body-id: string # (spec name: id)
  --identity-provider-alias: string
  --identity-provider-mapper: string
  --name: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/identity-provider/instances/{alias}/mappers/{id}"
    path_params: [{name: realm, var: realm}, {name: alias, var: alias}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: id, var: body_id}, {name: identityProviderAlias, var: identity_provider_alias}, {name: identityProviderMapper, var: identity_provider_mapper}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, alias: $alias, id: $id, config: $config, body_id: $body_id, identity_provider_alias: $identity_provider_alias, identity_provider_mapper: $identity_provider_mapper, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get identity providers
#
# GET /{realm}/identity-provider/providers/{provider_id}
export def "get-realm-identity-provider-providers-provider-id" [
  realm: string
  provider_id: string
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
    path: "/{realm}/identity-provider/providers/{provider_id}"
    path_params: [{name: realm, var: realm}, {name: provider_id, var: provider_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/keys
#
# Returns: record<active: record, keys: table<algorithm: string, certificate: string, kid: string, providerId: string, providerPriority: int, publicKey: string, status: string, type: string>>
export def "get-realm-keys" [
  realm: string
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
    path: "/{realm}/keys"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes all user sessions.
#
# POST /{realm}/logout-all
export def "post-realm-logout-all" [
  realm: string
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
    method: post
    path: "/{realm}/logout-all"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial export of existing realm into a JSON file.
#
# POST /{realm}/partial-export
# Returns: record<accessCodeLifespan: int, accessCodeLifespanLogin: int, accessCodeLifespanUserAction: int, accessTokenLifespan: int, accessTokenLifespanForImplicitFlow: int, accountTheme: string, actionTokenGeneratedByAdminLifespan: int, actionTokenGeneratedByUserLifespan: int, adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, adminTheme: string, attributes: record, authenticationFlows: table<alias: string, authenticationExecutions: list, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>, authenticatorConfig: table<alias: string, config: record, id: string>, browserFlow: string, browserSecurityHeaders: record, bruteForceProtected: bool, clientAuthenticationFlow: string, clientScopeMappings: record, clientScopes: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list>, clientSessionIdleTimeout: int, clientSessionMaxLifespan: int, clients: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list, defaultRoles: list, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list, origin: string, protocol: string, protocolMappers: list, publicClient: bool, redirectUris: list, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list>, components: record<empty: bool, loadFactor: float, threshold: int>, defaultDefaultClientScopes: list<string>, defaultGroups: list<string>, defaultLocale: string, defaultOptionalClientScopes: list<string>, defaultRoles: list<string>, defaultSignatureAlgorithm: string, directGrantFlow: string, displayName: string, displayNameHtml: string, dockerAuthenticationFlow: string, duplicateEmailsAllowed: bool, editUsernameAllowed: bool, emailTheme: string, enabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>, failureFactor: int, federatedUsers: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, groups: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list, subGroups: list>, id: string, identityProviderMappers: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>, identityProviders: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>, internationalizationEnabled: bool, keycloakVersion: string, loginTheme: string, loginWithEmailAllowed: bool, maxDeltaTimeSeconds: int, maxFailureWaitSeconds: int, minimumQuickLoginWaitSeconds: int, notBefore: int, offlineSessionIdleTimeout: int, offlineSessionMaxLifespan: int, offlineSessionMaxLifespanEnabled: bool, otpPolicyAlgorithm: string, otpPolicyDigits: int, otpPolicyInitialCounter: int, otpPolicyLookAheadWindow: int, otpPolicyPeriod: int, otpPolicyType: string, otpSupportedApplications: list<string>, passwordPolicy: string, permanentLockout: bool, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, quickLoginCheckMilliSeconds: int, realm: string, refreshTokenMaxReuse: int, registrationAllowed: bool, registrationEmailAsUsername: bool, registrationFlow: string, rememberMe: bool, requiredActions: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>, resetCredentialsFlow: string, resetPasswordAllowed: bool, revokeRefreshToken: bool, roles: record<client: record, realm: list<record>>, scopeMappings: table<client: string, clientScope: string, roles: list, self: string>, smtpServer: record, sslRequired: string, ssoSessionIdleTimeout: int, ssoSessionIdleTimeoutRememberMe: int, ssoSessionMaxLifespan: int, ssoSessionMaxLifespanRememberMe: int, supportedLocales: list<string>, userFederationMappers: table<config: record, federationMapperType: string, federationProviderDisplayName: string, id: string, name: string>, userFederationProviders: table<changedSyncPeriod: int, config: record, displayName: string, fullSyncPeriod: int, id: string, lastSync: int, priority: int, providerName: string>, userManagedAccessAllowed: bool, users: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, verifyEmail: bool, waitIncrementSeconds: int, webAuthnPolicyAcceptableAaguids: list<string>, webAuthnPolicyAttestationConveyancePreference: string, webAuthnPolicyAuthenticatorAttachment: string, webAuthnPolicyAvoidSameAuthenticatorRegister: bool, webAuthnPolicyCreateTimeout: int, webAuthnPolicyPasswordlessAcceptableAaguids: list<string>, webAuthnPolicyPasswordlessAttestationConveyancePreference: string, webAuthnPolicyPasswordlessAuthenticatorAttachment: string, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: bool, webAuthnPolicyPasswordlessCreateTimeout: int, webAuthnPolicyPasswordlessRequireResidentKey: string, webAuthnPolicyPasswordlessRpEntityName: string, webAuthnPolicyPasswordlessRpId: string, webAuthnPolicyPasswordlessSignatureAlgorithms: list<string>, webAuthnPolicyPasswordlessUserVerificationRequirement: string, webAuthnPolicyRequireResidentKey: string, webAuthnPolicyRpEntityName: string, webAuthnPolicyRpId: string, webAuthnPolicySignatureAlgorithms: list<string>, webAuthnPolicyUserVerificationRequirement: string>
export def "post-realm-partial-export" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --export-clients: oneof<nothing, bool>
  --export-groups-and-roles: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{realm}/partial-export"
    path_params: [{name: realm, var: realm}]
    query: [{name: exportClients, var: export_clients}, {name: exportGroupsAndRoles, var: export_groups_and_roles}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, export_clients: $export_clients, export_groups_and_roles: $export_groups_and_roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial import from a JSON file to an existing realm.
#
# POST /{realm}/partialImport
export def "post-realm-partial-import" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
  --identity-providers: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --if-resource-exists: string
  --policy: string@policy-completer
  --roles: record # shape: {client?: record, realm?: list}
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/partialImport"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: clients, var: clients}, {name: groups, var: groups}, {name: identityProviders, var: identity_providers}, {name: ifResourceExists, var: if_resource_exists}, {name: policy, var: policy}, {name: roles, var: roles}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, clients: $clients, groups: $groups, identity_providers: $identity_providers, if_resource_exists: $if_resource_exists, policy: $policy, roles: $roles, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push the realm’s revocation policy to any client that has an admin url associated with it.
#
# POST /{realm}/push-revocation
export def "post-realm-push-revocation" [
  realm: string
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
    method: post
    path: "/{realm}/push-revocation"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for the realm or client
#
# GET /{realm}/roles
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/roles"
    path_params: [{name: realm, var: realm}]
    query: [{name: briefRepresentation, var: brief_representation}, {name: first, var: first}, {name: max, var: max}, {name: search, var: search}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, brief_representation: $brief_representation, first: $first, max: $max, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new role for the realm or client
#
# POST /{realm}/roles
export def "post-realm-roles" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/roles"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: clientRole, var: client_role}, {name: composite, var: composite}, {name: composites, var: composites}, {name: containerId, var: container_id}, {name: description, var: description}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, attributes: $attributes, client_role: $client_role, composite: $composite, composites: $composites, container_id: $container_id, description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the role
#
# DELETE /{realm}/roles-by-id/{role-id}
export def "delete-realm-roles-by-id-role-id" [
  realm: string
  role_id: string
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
    path: "/{realm}/roles-by-id/{role-id}"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific role’s representation
#
# GET /{realm}/roles-by-id/{role-id}
# Returns: record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles-by-id-role-id" [
  realm: string
  role_id: string
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
    path: "/{realm}/roles-by-id/{role-id}"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the role
#
# PUT /{realm}/roles-by-id/{role-id}
export def "put-realm-roles-by-id-role-id" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/roles-by-id/{role-id}"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: clientRole, var: client_role}, {name: composite, var: composite}, {name: composites, var: composites}, {name: containerId, var: container_id}, {name: description, var: description}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id, attributes: $attributes, client_role: $client_role, composite: $composite, composites: $composites, container_id: $container_id, description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a set of roles from the role’s composite
#
# DELETE /{realm}/roles-by-id/{role-id}/composites
export def "delete-realm-roles-by-id-role-id-composites" [
  realm: string
  role_id: string
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
    method: delete
    path: "/{realm}/roles-by-id/{role-id}/composites"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get role’s children Returns a set of role’s children provided the role is a composite.
#
# GET /{realm}/roles-by-id/{role-id}/composites
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles-by-id-role-id-composites" [
  realm: string
  role_id: string
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
    path: "/{realm}/roles-by-id/{role-id}/composites"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Make the role a composite role by associating some child roles
#
# POST /{realm}/roles-by-id/{role-id}/composites
export def "post-realm-roles-by-id-role-id-composites" [
  realm: string
  role_id: string
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
    path: "/{realm}/roles-by-id/{role-id}/composites"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get client-level roles for the client that are in the role’s composite
#
# GET /{realm}/roles-by-id/{role-id}/composites/clients/{client}
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles-by-id-role-id-composites-clients-client" [
  realm: string
  role_id: string
  client: string
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
    path: "/{realm}/roles-by-id/{role-id}/composites/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles that are in the role’s composite
#
# GET /{realm}/roles-by-id/{role-id}/composites/realm
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles-by-id-role-id-composites-realm" [
  realm: string
  role_id: string
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
    path: "/{realm}/roles-by-id/{role-id}/composites/realm"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# GET /{realm}/roles-by-id/{role-id}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "get-realm-roles-by-id-role-id-management-permissions" [
  realm: string
  role_id: string
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
    path: "/{realm}/roles-by-id/{role-id}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/roles-by-id/{role-id}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "put-realm-roles-by-id-role-id-management-permissions" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{realm}/roles-by-id/{role-id}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: role-id, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: resource, var: resource}, {name: scopePermissions, var: scope_permissions}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_id: $role_id, enabled: $enabled, resource: $resource, scope_permissions: $scope_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role by name
#
# DELETE /{realm}/roles/{role-name}
export def "delete-realm-roles-role-name" [
  realm: string
  role_name: string
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
    path: "/{realm}/roles/{role-name}"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a role by name
#
# GET /{realm}/roles/{role-name}
# Returns: record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles-role-name" [
  realm: string
  role_name: string
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
    path: "/{realm}/roles/{role-name}"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role by name
#
# PUT /{realm}/roles/{role-name}
export def "put-realm-roles-role-name" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/roles/{role-name}"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: clientRole, var: client_role}, {name: composite, var: composite}, {name: composites, var: composites}, {name: containerId, var: container_id}, {name: description, var: description}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name, attributes: $attributes, client_role: $client_role, composite: $composite, composites: $composites, container_id: $container_id, description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove roles from the role’s composite
#
# DELETE /{realm}/roles/{role-name}/composites
export def "delete-realm-roles-role-name-composites" [
  realm: string
  role_name: string
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
    method: delete
    path: "/{realm}/roles/{role-name}/composites"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get composites of the role
#
# GET /{realm}/roles/{role-name}/composites
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles-role-name-composites" [
  realm: string
  role_name: string
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
    path: "/{realm}/roles/{role-name}/composites"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a composite to the role
#
# POST /{realm}/roles/{role-name}/composites
export def "post-realm-roles-role-name-composites" [
  realm: string
  role_name: string
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
    path: "/{realm}/roles/{role-name}/composites"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An app-level roles for the specified app for the role’s composite
#
# GET /{realm}/roles/{role-name}/composites/clients/{client}
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles-role-name-composites-clients-client" [
  realm: string
  role_name: string
  client: string
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
    path: "/{realm}/roles/{role-name}/composites/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles of the role’s composite
#
# GET /{realm}/roles/{role-name}/composites/realm
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-roles-role-name-composites-realm" [
  realm: string
  role_name: string
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
    path: "/{realm}/roles/{role-name}/composites/realm"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return List of Groups that have the specified role name
#
# GET /{realm}/roles/{role-name}/groups
# Returns: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>
export def "get-realm-roles-role-name-groups" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool> # if false, return a full representation of the GroupRepresentation objects
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/roles/{role-name}/groups"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    query: [{name: briefRepresentation, var: brief_representation}, {name: first, var: first}, {name: max, var: max}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name, brief_representation: $brief_representation, first: $first, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# GET /{realm}/roles/{role-name}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "get-realm-roles-role-name-management-permissions" [
  realm: string
  role_name: string
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
    path: "/{realm}/roles/{role-name}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/roles/{role-name}/management/permissions
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "put-realm-roles-role-name-management-permissions" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{realm}/roles/{role-name}/management/permissions"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: resource, var: resource}, {name: scopePermissions, var: scope_permissions}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name, enabled: $enabled, resource: $resource, scope_permissions: $scope_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return List of Users that have the specified role name
#
# GET /{realm}/roles/{role-name}/users
# Returns: table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>
export def "get-realm-roles-role-name-users" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/roles/{role-name}/users"
    path_params: [{name: realm, var: realm}, {name: role-name, var: role_name}]
    query: [{name: first, var: first}, {name: max, var: max}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, role_name: $role_name, first: $first, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a specific user session.
#
# DELETE /{realm}/sessions/{session}
export def "delete-realm-sessions-session" [
  realm: string
  session: string
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
    path: "/{realm}/sessions/{session}"
    path_params: [{name: realm, var: realm}, {name: session, var: session}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, session: $session
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test LDAP connection
#
# POST /{realm}/testLDAPConnection
export def "post-realm-test-ldap-connection" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string
  --bind-credential: string
  --bind-dn: string
  --component-id: string
  --connection-timeout: string
  --connection-url: string
  --start-tls: string
  --use-truststore-spi: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/testLDAPConnection"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: bindCredential, var: bind_credential}, {name: bindDn, var: bind_dn}, {name: componentId, var: component_id}, {name: connectionTimeout, var: connection_timeout}, {name: connectionUrl, var: connection_url}, {name: startTls, var: start_tls}, {name: useTruststoreSpi, var: use_truststore_spi}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, action: $action, bind_credential: $bind_credential, bind_dn: $bind_dn, component_id: $component_id, connection_timeout: $connection_timeout, connection_url: $connection_url, start_tls: $start_tls, use_truststore_spi: $use_truststore_spi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{realm}/testSMTPConnection
export def "post-realm-test-smtp-connection" [
  realm: string
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
    method: post
    path: "/{realm}/testSMTPConnection"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Need this for admin console to display simple name of provider when displaying user detail KEYCLOAK-4328
#
# GET /{realm}/user-storage/{id}/name
# Returns: record
export def "get-realm-user-storage-id-name" [
  realm: string
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
    path: "/{realm}/user-storage/{id}/name"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove imported users
#
# POST /{realm}/user-storage/{id}/remove-imported-users
export def "post-realm-user-storage-id-remove-imported-users" [
  realm: string
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
    method: post
    path: "/{realm}/user-storage/{id}/remove-imported-users"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger sync of users Action can be "triggerFullSync" or "triggerChangedUsersSync"
#
# POST /{realm}/user-storage/{id}/sync
# Returns: record<added: int, failed: int, ignored: bool, removed: int, status: string, updated: int>
export def "post-realm-user-storage-id-sync" [
  realm: string
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
  --action: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{realm}/user-storage/{id}/sync"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: action, var: action}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlink imported users from a storage provider
#
# POST /{realm}/user-storage/{id}/unlink-users
export def "post-realm-user-storage-id-unlink-users" [
  realm: string
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
    method: post
    path: "/{realm}/user-storage/{id}/unlink-users"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger sync of mapper data related to ldap mapper (roles, groups, …​) direction is "fedToKeycloak" or "keycloakToFed"
#
# POST /{realm}/user-storage/{parentId}/mappers/{id}/sync
# Returns: record<added: int, failed: int, ignored: bool, removed: int, status: string, updated: int>
export def "post-realm-user-storage-parent-id-mappers-id-sync" [
  realm: string
  parent_id: string
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
  --direction: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{realm}/user-storage/{parentId}/mappers/{id}/sync"
    path_params: [{name: realm, var: realm}, {name: parentId, var: parent_id}, {name: id, var: id}]
    query: [{name: direction, var: direction}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, parent_id: $parent_id, id: $id, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users Returns a list of users, filtered according to query parameters
#
# GET /{realm}/users
# Returns: table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>
export def "get-realm-users" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool>
  --email: string
  --first: int # format: int32
  --first-name: string
  --last-name: string
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --search: string # A String contained in username, first or last name, or email
  --username: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/users"
    path_params: [{name: realm, var: realm}]
    query: [{name: briefRepresentation, var: brief_representation}, {name: email, var: email}, {name: first, var: first}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: max, var: max}, {name: search, var: search}, {name: username, var: username}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, brief_representation: $brief_representation, email: $email, first: $first, first_name: $first_name, last_name: $last_name, max: $max, search: $search, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user Username must be unique.
#
# POST /{realm}/users
export def "post-realm-users" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --client-consents: list # item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list<string>, lastUpdatedDate?: int}
  --client-roles: record
  --created-timestamp: int # format: int64
  --credentials: list # item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
  --disableable-credential-types: list<string>
  --email: string
  --email-verified: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --federated-identities: list # item shape: {identityProvider?: string, userId?: string, userName?: string}
  --federation-link: string
  --first-name: string
  --groups: list<string>
  --id: string
  --last-name: string
  --not-before: int # format: int32
  --origin: string
  --realm-roles: list<string>
  --required-actions: list<string>
  --self: string
  --service-account-client-id: string
  --username: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/users"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: attributes, var: attributes}, {name: clientConsents, var: client_consents}, {name: clientRoles, var: client_roles}, {name: createdTimestamp, var: created_timestamp}, {name: credentials, var: credentials}, {name: disableableCredentialTypes, var: disableable_credential_types}, {name: email, var: email}, {name: emailVerified, var: email_verified}, {name: enabled, var: enabled}, {name: federatedIdentities, var: federated_identities}, {name: federationLink, var: federation_link}, {name: firstName, var: first_name}, {name: groups, var: groups}, {name: id, var: id}, {name: lastName, var: last_name}, {name: notBefore, var: not_before}, {name: origin, var: origin}, {name: realmRoles, var: realm_roles}, {name: requiredActions, var: required_actions}, {name: self, var: self}, {name: serviceAccountClientId, var: service_account_client_id}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, access: $access, attributes: $attributes, client_consents: $client_consents, client_roles: $client_roles, created_timestamp: $created_timestamp, credentials: $credentials, disableable_credential_types: $disableable_credential_types, email: $email, email_verified: $email_verified, enabled: $enabled, federated_identities: $federated_identities, federation_link: $federation_link, first_name: $first_name, groups: $groups, id: $id, last_name: $last_name, not_before: $not_before, origin: $origin, realm_roles: $realm_roles, required_actions: $required_actions, self: $self, service_account_client_id: $service_account_client_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/users-management-permissions
#
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "get-realm-users-management-permissions" [
  realm: string
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
    path: "/{realm}/users-management-permissions"
    path_params: [{name: realm, var: realm}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{realm}/users-management-permissions
#
# Returns: record<enabled: bool, resource: string, scopePermissions: record>
export def "put-realm-users-management-permissions" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{realm}/users-management-permissions"
    path_params: [{name: realm, var: realm}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: resource, var: resource}, {name: scopePermissions, var: scope_permissions}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, enabled: $enabled, resource: $resource, scope_permissions: $scope_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the number of users that match the given criteria.
#
# GET /{realm}/users/count
# Returns: int
export def "get-realm-users-count" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email filter
  --first-name: string # first name filter
  --last-name: string # last name filter
  --search: string # arbitrary search string for all the fields below
  --username: string # username filter
]: nothing -> any {
  http-request {
    method: get
    path: "/{realm}/users/count"
    path_params: [{name: realm, var: realm}]
    query: [{name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: search, var: search}, {name: username, var: username}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, email: $email, first_name: $first_name, last_name: $last_name, search: $search, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the user
#
# DELETE /{realm}/users/{id}
export def "delete-realm-users-id" [
  realm: string
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
    path: "/{realm}/users/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get representation of the user
#
# GET /{realm}/users/{id}
# Returns: record<access: record, attributes: record, clientConsents: table<clientId: string, createdDate: int, grantedClientScopes: list, lastUpdatedDate: int>, clientRoles: record, createdTimestamp: int, credentials: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: table<identityProvider: string, userId: string, userName: string>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string>
export def "get-realm-users-id" [
  realm: string
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
    path: "/{realm}/users/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the user
#
# PUT /{realm}/users/{id}
export def "put-realm-users-id" [
  realm: string
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
  --access: record
  --attributes: record
  --client-consents: list # item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list<string>, lastUpdatedDate?: int}
  --client-roles: record
  --created-timestamp: int # format: int64
  --credentials: list # item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
  --disableable-credential-types: list<string>
  --email: string
  --email-verified: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --federated-identities: list # item shape: {identityProvider?: string, userId?: string, userName?: string}
  --federation-link: string
  --first-name: string
  --groups: list<string>
  --body-id: string # (spec name: id)
  --last-name: string
  --not-before: int # format: int32
  --origin: string
  --realm-roles: list<string>
  --required-actions: list<string>
  --self: string
  --service-account-client-id: string
  --username: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/users/{id}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: attributes, var: attributes}, {name: clientConsents, var: client_consents}, {name: clientRoles, var: client_roles}, {name: createdTimestamp, var: created_timestamp}, {name: credentials, var: credentials}, {name: disableableCredentialTypes, var: disableable_credential_types}, {name: email, var: email}, {name: emailVerified, var: email_verified}, {name: enabled, var: enabled}, {name: federatedIdentities, var: federated_identities}, {name: federationLink, var: federation_link}, {name: firstName, var: first_name}, {name: groups, var: groups}, {name: id, var: body_id}, {name: lastName, var: last_name}, {name: notBefore, var: not_before}, {name: origin, var: origin}, {name: realmRoles, var: realm_roles}, {name: requiredActions, var: required_actions}, {name: self, var: self}, {name: serviceAccountClientId, var: service_account_client_id}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, access: $access, attributes: $attributes, client_consents: $client_consents, client_roles: $client_roles, created_timestamp: $created_timestamp, credentials: $credentials, disableable_credential_types: $disableable_credential_types, email: $email, email_verified: $email_verified, enabled: $enabled, federated_identities: $federated_identities, federation_link: $federation_link, first_name: $first_name, groups: $groups, body_id: $body_id, last_name: $last_name, not_before: $not_before, origin: $origin, realm_roles: $realm_roles, required_actions: $required_actions, self: $self, service_account_client_id: $service_account_client_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return credential types, which are provided by the user storage where user is stored.
#
# GET /{realm}/users/{id}/configured-user-storage-credential-types
# Returns: list<string>
export def "get-realm-users-id-configured-user-storage-credential-types" [
  realm: string
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
    path: "/{realm}/users/{id}/configured-user-storage-credential-types"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get consents granted by the user
#
# GET /{realm}/users/{id}/consents
# Returns: list<record>
export def "get-realm-users-id-consents" [
  realm: string
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
    path: "/{realm}/users/{id}/consents"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke consent and offline tokens for particular client from user
#
# DELETE /{realm}/users/{id}/consents/{client}
export def "delete-realm-users-id-consents-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/users/{id}/consents/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/users/{id}/credentials
#
# Returns: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>
export def "get-realm-users-id-credentials" [
  realm: string
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
    path: "/{realm}/users/{id}/credentials"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a credential for a user
#
# DELETE /{realm}/users/{id}/credentials/{credentialId}
export def "delete-realm-users-id-credentials-credential-id" [
  realm: string
  id: string
  credential_id: string
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
    path: "/{realm}/users/{id}/credentials/{credentialId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: credentialId, var: credential_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, credential_id: $credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move a credential to a position behind another credential
#
# POST /{realm}/users/{id}/credentials/{credentialId}/moveAfter/{newPreviousCredentialId}
export def "post-realm-users-id-credentials-credential-id-move-after-new-previous-credential-id" [
  realm: string
  id: string
  credential_id: string
  new_previous_credential_id: string
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
    method: post
    path: "/{realm}/users/{id}/credentials/{credentialId}/moveAfter/{newPreviousCredentialId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: credentialId, var: credential_id}, {name: newPreviousCredentialId, var: new_previous_credential_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, credential_id: $credential_id, new_previous_credential_id: $new_previous_credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move a credential to a first position in the credentials list of the user
#
# POST /{realm}/users/{id}/credentials/{credentialId}/moveToFirst
export def "post-realm-users-id-credentials-credential-id-move-to-first" [
  realm: string
  id: string
  credential_id: string
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
    method: post
    path: "/{realm}/users/{id}/credentials/{credentialId}/moveToFirst"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: credentialId, var: credential_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, credential_id: $credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a credential label for a user
#
# PUT /{realm}/users/{id}/credentials/{credentialId}/userLabel
export def "put-realm-users-id-credentials-credential-id-user-label" [
  realm: string
  id: string
  credential_id: string
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
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/users/{id}/credentials/{credentialId}/userLabel"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: credentialId, var: credential_id}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, credential_id: $credential_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable all credentials for a user of a specific type
#
# PUT /{realm}/users/{id}/disable-credential-types
export def "put-realm-users-id-disable-credential-types" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/users/{id}/disable-credential-types"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a update account email to the user An email contains a link the user can click to perform a set of required actions.
#
# PUT /{realm}/users/{id}/execute-actions-email
export def "put-realm-users-id-execute-actions-email" [
  realm: string
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
  --client-id: string # Client id
  --lifespan: int # Number of seconds after which the generated token expires (format: int32)
  --redirect-uri: string # Redirect uri
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/users/{id}/execute-actions-email"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: client_id, var: client_id}, {name: lifespan, var: lifespan}, {name: redirect_uri, var: redirect_uri}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client_id: $client_id, lifespan: $lifespan, redirect_uri: $redirect_uri, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get social logins associated with the user
#
# GET /{realm}/users/{id}/federated-identity
# Returns: table<identityProvider: string, userId: string, userName: string>
export def "get-realm-users-id-federated-identity" [
  realm: string
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
    path: "/{realm}/users/{id}/federated-identity"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a social login provider from user
#
# DELETE /{realm}/users/{id}/federated-identity/{provider}
export def "delete-realm-users-id-federated-identity-provider" [
  realm: string
  id: string
  provider: string
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
    path: "/{realm}/users/{id}/federated-identity/{provider}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: provider, var: provider}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a social login provider to the user
#
# POST /{realm}/users/{id}/federated-identity/{provider}
export def "post-realm-users-id-federated-identity-provider" [
  realm: string
  id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-provider: string
  --user-id: string
  --user-name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/users/{id}/federated-identity/{provider}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: provider, var: provider}]
    body: {content_type: "application/json", kind: json, fields: [{name: identityProvider, var: identity_provider}, {name: userId, var: user_id}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, provider: $provider, identity_provider: $identity_provider, user_id: $user_id, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/users/{id}/groups
#
# Returns: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>>
export def "get-realm-users-id-groups" [
  realm: string
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
  --brief-representation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/users/{id}/groups"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: briefRepresentation, var: brief_representation}, {name: first, var: first}, {name: max, var: max}, {name: search, var: search}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, brief_representation: $brief_representation, first: $first, max: $max, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{realm}/users/{id}/groups/count
#
# Returns: record
export def "get-realm-users-id-groups-count" [
  realm: string
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
  --search: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{realm}/users/{id}/groups/count"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{realm}/users/{id}/groups/{groupId}
export def "delete-realm-users-id-groups-group-id" [
  realm: string
  id: string
  group_id: string
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
    path: "/{realm}/users/{id}/groups/{groupId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{realm}/users/{id}/groups/{groupId}
export def "put-realm-users-id-groups-group-id" [
  realm: string
  id: string
  group_id: string
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
    path: "/{realm}/users/{id}/groups/{groupId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Impersonate the user
#
# POST /{realm}/users/{id}/impersonation
# Returns: record
export def "post-realm-users-id-impersonation" [
  realm: string
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
    path: "/{realm}/users/{id}/impersonation"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove all user sessions associated with the user Also send notification to all clients that have an admin URL to invalidate the sessions for the particular user.
#
# POST /{realm}/users/{id}/logout
export def "post-realm-users-id-logout" [
  realm: string
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
    method: post
    path: "/{realm}/users/{id}/logout"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get offline sessions associated with the user and client
#
# GET /{realm}/users/{id}/offline-sessions/{clientId}
# Returns: table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string>
export def "get-realm-users-id-offline-sessions-client-id" [
  realm: string
  id: string
  client_id: string
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
    path: "/{realm}/users/{id}/offline-sessions/{clientId}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set up a new password for the user.
#
# PUT /{realm}/users/{id}/reset-password
export def "put-realm-users-id-reset-password" [
  realm: string
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
  --created-date: int # format: int64
  --credential-data: string
  --body-id: string # (spec name: id)
  --priority: int # format: int32
  --secret-data: string
  --temporary: oneof<nothing, bool>
  --type: string
  --user-label: string
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/{realm}/users/{id}/reset-password"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdDate, var: created_date}, {name: credentialData, var: credential_data}, {name: id, var: body_id}, {name: priority, var: priority}, {name: secretData, var: secret_data}, {name: temporary, var: temporary}, {name: type, var: type}, {name: userLabel, var: user_label}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, created_date: $created_date, credential_data: $credential_data, body_id: $body_id, priority: $priority, secret_data: $secret_data, temporary: $temporary, type: $type, user_label: $user_label, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get role mappings
#
# GET /{realm}/users/{id}/role-mappings
# Returns: record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>>
export def "get-realm-users-id-role-mappings" [
  realm: string
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
    path: "/{realm}/users/{id}/role-mappings"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete client-level roles from user role mapping
#
# DELETE /{realm}/users/{id}/role-mappings/clients/{client}
export def "delete-realm-users-id-role-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    method: delete
    path: "/{realm}/users/{id}/role-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get client-level role mappings for the user, and the app
#
# GET /{realm}/users/{id}/role-mappings/clients/{client}
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-users-id-role-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/users/{id}/role-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add client-level roles to the user role mapping
#
# POST /{realm}/users/{id}/role-mappings/clients/{client}
export def "post-realm-users-id-role-mappings-clients-client" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/users/{id}/role-mappings/clients/{client}"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get available client-level roles that can be mapped to the user
#
# GET /{realm}/users/{id}/role-mappings/clients/{client}/available
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-users-id-role-mappings-clients-client-available" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/users/{id}/role-mappings/clients/{client}/available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective client-level role mappings This recurses any composite roles
#
# GET /{realm}/users/{id}/role-mappings/clients/{client}/composite
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-users-id-role-mappings-clients-client-composite" [
  realm: string
  id: string
  client: string
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
    path: "/{realm}/users/{id}/role-mappings/clients/{client}/composite"
    path_params: [{name: realm, var: realm}, {name: id, var: id}, {name: client, var: client}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client: $client
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete realm-level role mappings
#
# DELETE /{realm}/users/{id}/role-mappings/realm
export def "delete-realm-users-id-role-mappings-realm" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/{realm}/users/{id}/role-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level role mappings
#
# GET /{realm}/users/{id}/role-mappings/realm
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-users-id-role-mappings-realm" [
  realm: string
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
    path: "/{realm}/users/{id}/role-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add realm-level role mappings to the user
#
# POST /{realm}/users/{id}/role-mappings/realm
export def "post-realm-users-id-role-mappings-realm" [
  realm: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/{realm}/users/{id}/role-mappings/realm"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get realm-level roles that can be mapped
#
# GET /{realm}/users/{id}/role-mappings/realm/available
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-users-id-role-mappings-realm-available" [
  realm: string
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
    path: "/{realm}/users/{id}/role-mappings/realm/available"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effective realm-level role mappings This will recurse all composite roles to get the result.
#
# GET /{realm}/users/{id}/role-mappings/realm/composite
# Returns: table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string>
export def "get-realm-users-id-role-mappings-realm-composite" [
  realm: string
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
    path: "/{realm}/users/{id}/role-mappings/realm/composite"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send an email-verification email to the user An email contains a link the user can click to verify their email address.
#
# PUT /{realm}/users/{id}/send-verify-email
export def "put-realm-users-id-send-verify-email" [
  realm: string
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
  --client-id: string # Client id
  --redirect-uri: string # Redirect uri
]: nothing -> any {
  http-request {
    method: put
    path: "/{realm}/users/{id}/send-verify-email"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    query: [{name: client_id, var: client_id}, {name: redirect_uri, var: redirect_uri}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id, client_id: $client_id, redirect_uri: $redirect_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sessions associated with the user
#
# GET /{realm}/users/{id}/sessions
# Returns: table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string>
export def "get-realm-users-id-sessions" [
  realm: string
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
    path: "/{realm}/users/{id}/sessions"
    path_params: [{name: realm, var: realm}, {name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    realm: $realm, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
