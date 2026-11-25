# Auto-generated client for AWS App Mesh v2019-01-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/appmesh/2019-01-25/openapi.json
# Auth: --token flag or $env.AWS_APP_MESH_TOKEN

const CLIENT = {
  base_url: "http://appmesh.us-east-1.amazonaws.com"
  token_env_var: "AWS_APP_MESH_TOKEN"
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

def base-url-completer [] { ["http://appmesh.us-east-1.amazonaws.com" "http://appmesh.us-east-2.amazonaws.com" "http://appmesh.us-west-1.amazonaws.com" "http://appmesh.us-west-2.amazonaws.com" "http://appmesh.us-gov-west-1.amazonaws.com" "http://appmesh.us-gov-east-1.amazonaws.com" "http://appmesh.ca-central-1.amazonaws.com" "http://appmesh.eu-north-1.amazonaws.com" "http://appmesh.eu-west-1.amazonaws.com" "http://appmesh.eu-west-2.amazonaws.com" "http://appmesh.eu-west-3.amazonaws.com" "http://appmesh.eu-central-1.amazonaws.com" "http://appmesh.eu-south-1.amazonaws.com" "http://appmesh.af-south-1.amazonaws.com" "http://appmesh.ap-northeast-1.amazonaws.com" "http://appmesh.ap-northeast-2.amazonaws.com" "http://appmesh.ap-northeast-3.amazonaws.com" "http://appmesh.ap-southeast-1.amazonaws.com" "http://appmesh.ap-southeast-2.amazonaws.com" "http://appmesh.ap-east-1.amazonaws.com" "http://appmesh.ap-south-1.amazonaws.com" "http://appmesh.sa-east-1.amazonaws.com" "http://appmesh.me-south-1.amazonaws.com" "https://appmesh.us-east-1.amazonaws.com" "https://appmesh.us-east-2.amazonaws.com" "https://appmesh.us-west-1.amazonaws.com" "https://appmesh.us-west-2.amazonaws.com" "https://appmesh.us-gov-west-1.amazonaws.com" "https://appmesh.us-gov-east-1.amazonaws.com" "https://appmesh.ca-central-1.amazonaws.com" "https://appmesh.eu-north-1.amazonaws.com" "https://appmesh.eu-west-1.amazonaws.com" "https://appmesh.eu-west-2.amazonaws.com" "https://appmesh.eu-west-3.amazonaws.com" "https://appmesh.eu-central-1.amazonaws.com" "https://appmesh.eu-south-1.amazonaws.com" "https://appmesh.af-south-1.amazonaws.com" "https://appmesh.ap-northeast-1.amazonaws.com" "https://appmesh.ap-northeast-2.amazonaws.com" "https://appmesh.ap-northeast-3.amazonaws.com" "https://appmesh.ap-southeast-1.amazonaws.com" "https://appmesh.ap-southeast-2.amazonaws.com" "https://appmesh.ap-east-1.amazonaws.com" "https://appmesh.ap-south-1.amazonaws.com" "https://appmesh.sa-east-1.amazonaws.com" "https://appmesh.me-south-1.amazonaws.com" "http://appmesh.cn-north-1.amazonaws.com.cn" "http://appmesh.cn-northwest-1.amazonaws.com.cn" "https://appmesh.cn-north-1.amazonaws.com.cn" "https://appmesh.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-gateway-route: "record<gatewayRoute: record<gatewayRouteName: string, meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int>, status: record<status: string>, virtualGatewayName: string>>"
    list-gateway-routes: "record<gatewayRoutes: table<arn: string, createdAt: string, gatewayRouteName: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualGatewayName: string>, nextToken: string>"
    create-mesh: "record<mesh: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: string>>>"
    list-meshes: "record<meshes: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int>, nextToken: string>"
    create-route: "record<route: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, routeName: string, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int, tcpRoute: record>, status: record<status: string>, virtualRouterName: string>>"
    list-routes: "record<nextToken: string, routes: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, routeName: string, version: int, virtualRouterName: string>>"
    create-virtual-gateway: "record<virtualGateway: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, listeners: list, logging: record>, status: record<status: string>, virtualGatewayName: string>>"
    list-virtual-gateways: "record<nextToken: string, virtualGateways: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualGatewayName: string>>"
    create-virtual-node: "record<virtualNode: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, backends: list, listeners: list, logging: record, serviceDiscovery: record>, status: record<status: string>, virtualNodeName: string>>"
    list-virtual-nodes: "record<nextToken: string, virtualNodes: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualNodeName: string>>"
    create-virtual-router: "record<virtualRouter: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<listeners: list>, status: record<status: string>, virtualRouterName: string>>"
    list-virtual-routers: "record<nextToken: string, virtualRouters: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualRouterName: string>>"
    create-virtual-service: "record<virtualService: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<provider: record>, status: record<status: string>, virtualServiceName: string>>"
    list-virtual-services: "record<nextToken: string, virtualServices: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualServiceName: string>>"
    delete-gateway-route: "record<gatewayRoute: record<gatewayRouteName: string, meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int>, status: record<status: string>, virtualGatewayName: string>>"
    describe-gateway-route: "record<gatewayRoute: record<gatewayRouteName: string, meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int>, status: record<status: string>, virtualGatewayName: string>>"
    update-gateway-route: "record<gatewayRoute: record<gatewayRouteName: string, meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int>, status: record<status: string>, virtualGatewayName: string>>"
    delete-mesh: "record<mesh: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: string>>>"
    describe-mesh: "record<mesh: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: string>>>"
    update-mesh: "record<mesh: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: string>>>"
    delete-route: "record<route: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, routeName: string, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int, tcpRoute: record>, status: record<status: string>, virtualRouterName: string>>"
    describe-route: "record<route: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, routeName: string, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int, tcpRoute: record>, status: record<status: string>, virtualRouterName: string>>"
    update-route: "record<route: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, routeName: string, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int, tcpRoute: record>, status: record<status: string>, virtualRouterName: string>>"
    delete-virtual-gateway: "record<virtualGateway: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, listeners: list, logging: record>, status: record<status: string>, virtualGatewayName: string>>"
    describe-virtual-gateway: "record<virtualGateway: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, listeners: list, logging: record>, status: record<status: string>, virtualGatewayName: string>>"
    update-virtual-gateway: "record<virtualGateway: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, listeners: list, logging: record>, status: record<status: string>, virtualGatewayName: string>>"
    delete-virtual-node: "record<virtualNode: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, backends: list, listeners: list, logging: record, serviceDiscovery: record>, status: record<status: string>, virtualNodeName: string>>"
    describe-virtual-node: "record<virtualNode: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, backends: list, listeners: list, logging: record, serviceDiscovery: record>, status: record<status: string>, virtualNodeName: string>>"
    update-virtual-node: "record<virtualNode: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, backends: list, listeners: list, logging: record, serviceDiscovery: record>, status: record<status: string>, virtualNodeName: string>>"
    delete-virtual-router: "record<virtualRouter: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<listeners: list>, status: record<status: string>, virtualRouterName: string>>"
    describe-virtual-router: "record<virtualRouter: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<listeners: list>, status: record<status: string>, virtualRouterName: string>>"
    update-virtual-router: "record<virtualRouter: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<listeners: list>, status: record<status: string>, virtualRouterName: string>>"
    delete-virtual-service: "record<virtualService: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<provider: record>, status: record<status: string>, virtualServiceName: string>>"
    describe-virtual-service: "record<virtualService: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<provider: record>, status: record<status: string>, virtualServiceName: string>>"
    update-virtual-service: "record<virtualService: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<provider: record>, status: record<status: string>, virtualServiceName: string>>"
    list-tags-for-resource: "record<nextToken: string, tags: table<key: string, value: string>>"
    tag-resource: "record"
    untag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-gateway-route" "list-gateway-routes" "create-mesh" "list-meshes" "create-route" "list-routes" "create-virtual-gateway" "list-virtual-gateways" "create-virtual-node" "list-virtual-nodes" "create-virtual-router" "list-virtual-routers" "create-virtual-service" "list-virtual-services" "delete-gateway-route" "describe-gateway-route" "update-gateway-route" "delete-mesh" "describe-mesh" "update-mesh" "delete-route" "describe-route" "update-route" "delete-virtual-gateway" "describe-virtual-gateway" "update-virtual-gateway" "delete-virtual-node" "describe-virtual-node" "update-virtual-node" "delete-virtual-router" "describe-virtual-router" "update-virtual-router" "delete-virtual-service" "describe-virtual-service" "update-virtual-service" "list-tags-for-resource" "tag-resource" "untag-resource" "commands"] | sort) } | get name | first)
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

# Creates a gateway route. A gateway route is attached to a virtual gateway and routes traffic to an existing virtual service. If a route matches a request, it can distribute traffic to a target virtual service. For more information about gateway routes, see Gateway routes (https://docs.aws.amazon.com/app-mesh/latest/userguide/gateway-routes.html).
#
# PUT /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes
# Returns: record<gatewayRoute: record<gatewayRouteName: string, meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int>, status: record<status: string>, virtualGatewayName: string>>
# operationId: CreateGatewayRoute
export def "create-gateway-route" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  gateway_route_name: string # The name to use for the gateway route.
  spec: record # An object that represents a gateway route specification. Specify one gateway route type. — shape: {grpcRoute?: record, http2Route?: record, httpRoute?: record, priority?: int}
  --tags: list # Optional metadata that you can apply to the gateway route to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualGatewayName, var: virtual_gateway_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: gatewayRouteName, var: gateway_route_name}, {name: spec, var: spec}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_gateway_name: $virtual_gateway_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, gateway_route_name: $gateway_route_name, spec: $spec, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of existing gateway routes that are associated to a virtual gateway.
#
# GET /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes
# Returns: record<gatewayRoutes: table<arn: string, createdAt: string, gatewayRouteName: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualGatewayName: string>, nextToken: string>
# operationId: ListGatewayRoutes
export def "list-gateway-routes" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListGatewayRoutes in paginated output. When you use this parameter, ListGatewayRoutes returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListGatewayRoutes request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListGatewayRoutes returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListGatewayRoutes request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualGatewayName, var: virtual_gateway_name}]
    query: [{name: limit, var: limit}, {name: meshOwner, var: mesh_owner}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_gateway_name: $virtual_gateway_name, limit: $limit, mesh_owner: $mesh_owner, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a service mesh. A service mesh is a logical boundary for network traffic between services that are represented by resources within the mesh. After you create your service mesh, you can create virtual services, virtual nodes, virtual routers, and routes to distribute traffic between the applications in your mesh. For more information about service meshes, see Service meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/meshes.html).
#
# PUT /v20190125/meshes
# Returns: record<mesh: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: string>>>
# operationId: CreateMesh
export def "create-mesh" [
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
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  mesh_name: string # The name to use for the service mesh.
  --spec: record # An object that represents the specification of a service mesh. — shape: {egressFilter?: record, serviceDiscovery?: record}
  --tags: list # Optional metadata that you can apply to the service mesh to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: meshName, var: mesh_name}, {name: spec, var: spec}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, mesh_name: $mesh_name, spec: $spec, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of existing service meshes.
#
# GET /v20190125/meshes
# Returns: record<meshes: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int>, nextToken: string>
# operationId: ListMeshes
export def "list-meshes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListMeshes in paginated output. When you use this parameter, ListMeshes returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListMeshes request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListMeshes returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListMeshes request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.
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
    path: "/v20190125/meshes"
    query: [{name: limit, var: limit}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a route that is associated with a virtual router. You can route several different protocols and define a retry policy for a route. Traffic can be routed to one or more virtual nodes. For more information about routes, see Routes (https://docs.aws.amazon.com/app-mesh/latest/userguide/routes.html).
#
# PUT /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes
# Returns: record<route: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, routeName: string, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int, tcpRoute: record>, status: record<status: string>, virtualRouterName: string>>
# operationId: CreateRoute
export def "create-route" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  route_name: string # The name to use for the route.
  spec: record # An object that represents a route specification. Specify one route type. — shape: {grpcRoute?: record, http2Route?: record, httpRoute?: record, priority?: int, tcpRoute?: record}
  --tags: list # Optional metadata that you can apply to the route to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualRouterName, var: virtual_router_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: routeName, var: route_name}, {name: spec, var: spec}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_router_name: $virtual_router_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, route_name: $route_name, spec: $spec, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of existing routes in a service mesh.
#
# GET /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes
# Returns: record<nextToken: string, routes: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, routeName: string, version: int, virtualRouterName: string>>
# operationId: ListRoutes
export def "list-routes" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListRoutes in paginated output. When you use this parameter, ListRoutes returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListRoutes request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListRoutes returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListRoutes request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualRouterName, var: virtual_router_name}]
    query: [{name: limit, var: limit}, {name: meshOwner, var: mesh_owner}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_router_name: $virtual_router_name, limit: $limit, mesh_owner: $mesh_owner, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a virtual gateway. A virtual gateway allows resources outside your mesh to communicate to resources that are inside your mesh. The virtual gateway represents an Envoy proxy running in an Amazon ECS task, in a Kubernetes service, or on an Amazon EC2 instance. Unlike a virtual node, which represents an Envoy running with an application, a virtual gateway represents Envoy deployed by itself. For more information about virtual gateways, see Virtual gateways (https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_gateways.html).
#
# PUT /v20190125/meshes/{meshName}/virtualGateways
# Returns: record<virtualGateway: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, listeners: list, logging: record>, status: record<status: string>, virtualGatewayName: string>>
# operationId: CreateVirtualGateway
export def "create-virtual-gateway" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a service mesh resource. — shape: {backendDefaults?: record, listeners?: list, logging?: record}
  --tags: list # Optional metadata that you can apply to the virtual gateway to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: string, value: string}
  virtual_gateway_name: string # The name to use for the virtual gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualGateways"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}, {name: tags, var: tags}, {name: virtualGatewayName, var: virtual_gateway_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec, tags: $tags, virtual_gateway_name: $virtual_gateway_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of existing virtual gateways in a service mesh.
#
# GET /v20190125/meshes/{meshName}/virtualGateways
# Returns: record<nextToken: string, virtualGateways: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualGatewayName: string>>
# operationId: ListVirtualGateways
export def "list-virtual-gateways" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListVirtualGateways in paginated output. When you use this parameter, ListVirtualGateways returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListVirtualGateways request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListVirtualGateways returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListVirtualGateways request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/v20190125/meshes/{meshName}/virtualGateways"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: limit, var: limit}, {name: meshOwner, var: mesh_owner}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, limit: $limit, mesh_owner: $mesh_owner, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a virtual node within a service mesh. A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS service or a Kubernetes deployment. When you create a virtual node, you can specify the service discovery information for your task group, and whether the proxy running in a task group will communicate with other proxies using Transport Layer Security (TLS). You define a listener for any inbound traffic that your virtual node expects. Any virtual service that your virtual node expects to communicate to is specified as a backend. The response metadata for your new virtual node contains the arn that is associated with the virtual node. Set this value to the full ARN; for example, arn:aws:appmesh:us-west-2:123456789012:myMesh/default/virtualNode/myApp) as the APPMESH_RESOURCE_ARN environment variable for your task group's Envoy proxy container in your task definition or pod spec. This is then mapped to the node.id and node.cluster Envoy parameters. By default, App Mesh uses the name of the resource you specified in APPMESH_RESOURCE_ARN when Envoy is referring to itself in metrics and traces. You can override this behavior by setting the APPMESH_RESOURCE_CLUSTER environment variable with your own name. For more information about virtual nodes, see Virtual nodes (https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_nodes.html). You must be using 1.15.0 or later of the Envoy image when setting these variables. For more information aboutApp Mesh Envoy variables, see Envoy image (https://docs.aws.amazon.com/app-mesh/latest/userguide/envoy.html) in the App Mesh User Guide.
#
# PUT /v20190125/meshes/{meshName}/virtualNodes
# Returns: record<virtualNode: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, backends: list, listeners: list, logging: record, serviceDiscovery: record>, status: record<status: string>, virtualNodeName: string>>
# operationId: CreateVirtualNode
export def "create-virtual-node" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual node. — shape: {backendDefaults?: record, backends?: list, listeners?: list, logging?: record, serviceDiscovery?: record}
  --tags: list # Optional metadata that you can apply to the virtual node to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: string, value: string}
  virtual_node_name: string # The name to use for the virtual node.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualNodes"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}, {name: tags, var: tags}, {name: virtualNodeName, var: virtual_node_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec, tags: $tags, virtual_node_name: $virtual_node_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of existing virtual nodes.
#
# GET /v20190125/meshes/{meshName}/virtualNodes
# Returns: record<nextToken: string, virtualNodes: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualNodeName: string>>
# operationId: ListVirtualNodes
export def "list-virtual-nodes" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListVirtualNodes in paginated output. When you use this parameter, ListVirtualNodes returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListVirtualNodes request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListVirtualNodes returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListVirtualNodes request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/v20190125/meshes/{meshName}/virtualNodes"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: limit, var: limit}, {name: meshOwner, var: mesh_owner}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, limit: $limit, mesh_owner: $mesh_owner, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a virtual router within a service mesh. Specify a listener for any inbound traffic that your virtual router receives. Create a virtual router for each protocol and port that you need to route. Virtual routers handle traffic for one or more virtual services within your mesh. After you create your virtual router, create and associate routes for your virtual router that direct incoming requests to different virtual nodes. For more information about virtual routers, see Virtual routers (https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_routers.html).
#
# PUT /v20190125/meshes/{meshName}/virtualRouters
# Returns: record<virtualRouter: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<listeners: list>, status: record<status: string>, virtualRouterName: string>>
# operationId: CreateVirtualRouter
export def "create-virtual-router" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual router. — shape: {listeners?: list}
  --tags: list # Optional metadata that you can apply to the virtual router to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: string, value: string}
  virtual_router_name: string # The name to use for the virtual router.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualRouters"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}, {name: tags, var: tags}, {name: virtualRouterName, var: virtual_router_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec, tags: $tags, virtual_router_name: $virtual_router_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of existing virtual routers in a service mesh.
#
# GET /v20190125/meshes/{meshName}/virtualRouters
# Returns: record<nextToken: string, virtualRouters: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualRouterName: string>>
# operationId: ListVirtualRouters
export def "list-virtual-routers" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListVirtualRouters in paginated output. When you use this parameter, ListVirtualRouters returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListVirtualRouters request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListVirtualRouters returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListVirtualRouters request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/v20190125/meshes/{meshName}/virtualRouters"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: limit, var: limit}, {name: meshOwner, var: mesh_owner}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, limit: $limit, mesh_owner: $mesh_owner, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a virtual service within a service mesh. A virtual service is an abstraction of a real service that is provided by a virtual node directly or indirectly by means of a virtual router. Dependent services call your virtual service by its virtualServiceName, and those requests are routed to the virtual node or virtual router that is specified as the provider for the virtual service. For more information about virtual services, see Virtual services (https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_services.html).
#
# PUT /v20190125/meshes/{meshName}/virtualServices
# Returns: record<virtualService: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<provider: record>, status: record<status: string>, virtualServiceName: string>>
# operationId: CreateVirtualService
export def "create-virtual-service" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual service. — shape: {provider?: record}
  --tags: list # Optional metadata that you can apply to the virtual service to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: string, value: string}
  virtual_service_name: string # The name to use for the virtual service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualServices"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}, {name: tags, var: tags}, {name: virtualServiceName, var: virtual_service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec, tags: $tags, virtual_service_name: $virtual_service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of existing virtual services in a service mesh.
#
# GET /v20190125/meshes/{meshName}/virtualServices
# Returns: record<nextToken: string, virtualServices: table<arn: string, createdAt: string, lastUpdatedAt: string, meshName: string, meshOwner: string, resourceOwner: string, version: int, virtualServiceName: string>>
# operationId: ListVirtualServices
export def "list-virtual-services" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListVirtualServices in paginated output. When you use this parameter, ListVirtualServices returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListVirtualServices request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListVirtualServices returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListVirtualServices request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/v20190125/meshes/{meshName}/virtualServices"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: limit, var: limit}, {name: meshOwner, var: mesh_owner}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, limit: $limit, mesh_owner: $mesh_owner, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing gateway route.
#
# DELETE /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}
# Returns: record<gatewayRoute: record<gatewayRouteName: string, meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int>, status: record<status: string>, virtualGatewayName: string>>
# operationId: DeleteGatewayRoute
export def "delete-gateway-route" [
  mesh_name: string
  virtual_gateway_name: string
  gateway_route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualGatewayName, var: virtual_gateway_name}, {name: gatewayRouteName, var: gateway_route_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_gateway_name: $virtual_gateway_name, gateway_route_name: $gateway_route_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing gateway route.
#
# GET /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}
# Returns: record<gatewayRoute: record<gatewayRouteName: string, meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int>, status: record<status: string>, virtualGatewayName: string>>
# operationId: DescribeGatewayRoute
export def "describe-gateway-route" [
  mesh_name: string
  virtual_gateway_name: string
  gateway_route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualGatewayName, var: virtual_gateway_name}, {name: gatewayRouteName, var: gateway_route_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_gateway_name: $virtual_gateway_name, gateway_route_name: $gateway_route_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing gateway route that is associated to a specified virtual gateway in a service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}
# Returns: record<gatewayRoute: record<gatewayRouteName: string, meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int>, status: record<status: string>, virtualGatewayName: string>>
# operationId: UpdateGatewayRoute
export def "update-gateway-route" [
  mesh_name: string
  virtual_gateway_name: string
  gateway_route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents a gateway route specification. Specify one gateway route type. — shape: {grpcRoute?: record, http2Route?: record, httpRoute?: record, priority?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualGatewayName, var: virtual_gateway_name}, {name: gatewayRouteName, var: gateway_route_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_gateway_name: $virtual_gateway_name, gateway_route_name: $gateway_route_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing service mesh. You must delete all resources (virtual services, routes, virtual routers, and virtual nodes) in the service mesh before you can delete the mesh itself.
#
# DELETE /v20190125/meshes/{meshName}
# Returns: record<mesh: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: string>>>
# operationId: DeleteMesh
export def "delete-mesh" [
  mesh_name: string
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
    path: "/v20190125/meshes/{meshName}"
    path_params: [{name: meshName, var: mesh_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing service mesh.
#
# GET /v20190125/meshes/{meshName}
# Returns: record<mesh: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: string>>>
# operationId: DescribeMesh
export def "describe-mesh" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}"
    path_params: [{name: meshName, var: mesh_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing service mesh.
#
# PUT /v20190125/meshes/{meshName}
# Returns: record<mesh: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: string>>>
# operationId: UpdateMesh
export def "update-mesh" [
  mesh_name: string
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
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  --spec: record # An object that represents the specification of a service mesh. — shape: {egressFilter?: record, serviceDiscovery?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}"
    path_params: [{name: meshName, var: mesh_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing route.
#
# DELETE /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}
# Returns: record<route: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, routeName: string, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int, tcpRoute: record>, status: record<status: string>, virtualRouterName: string>>
# operationId: DeleteRoute
export def "delete-route" [
  mesh_name: string
  virtual_router_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualRouterName, var: virtual_router_name}, {name: routeName, var: route_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_router_name: $virtual_router_name, route_name: $route_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing route.
#
# GET /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}
# Returns: record<route: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, routeName: string, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int, tcpRoute: record>, status: record<status: string>, virtualRouterName: string>>
# operationId: DescribeRoute
export def "describe-route" [
  mesh_name: string
  virtual_router_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualRouterName, var: virtual_router_name}, {name: routeName, var: route_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_router_name: $virtual_router_name, route_name: $route_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing route for a specified service mesh and virtual router.
#
# PUT /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}
# Returns: record<route: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, routeName: string, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: int, tcpRoute: record>, status: record<status: string>, virtualRouterName: string>>
# operationId: UpdateRoute
export def "update-route" [
  mesh_name: string
  virtual_router_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents a route specification. Specify one route type. — shape: {grpcRoute?: record, http2Route?: record, httpRoute?: record, priority?: int, tcpRoute?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualRouterName, var: virtual_router_name}, {name: routeName, var: route_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_router_name: $virtual_router_name, route_name: $route_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing virtual gateway. You cannot delete a virtual gateway if any gateway routes are associated to it.
#
# DELETE /v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}
# Returns: record<virtualGateway: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, listeners: list, logging: record>, status: record<status: string>, virtualGatewayName: string>>
# operationId: DeleteVirtualGateway
export def "delete-virtual-gateway" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualGatewayName, var: virtual_gateway_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_gateway_name: $virtual_gateway_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing virtual gateway.
#
# GET /v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}
# Returns: record<virtualGateway: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, listeners: list, logging: record>, status: record<status: string>, virtualGatewayName: string>>
# operationId: DescribeVirtualGateway
export def "describe-virtual-gateway" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualGatewayName, var: virtual_gateway_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_gateway_name: $virtual_gateway_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing virtual gateway in a specified service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}
# Returns: record<virtualGateway: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, listeners: list, logging: record>, status: record<status: string>, virtualGatewayName: string>>
# operationId: UpdateVirtualGateway
export def "update-virtual-gateway" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a service mesh resource. — shape: {backendDefaults?: record, listeners?: list, logging?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualGatewayName, var: virtual_gateway_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_gateway_name: $virtual_gateway_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing virtual node. You must delete any virtual services that list a virtual node as a service provider before you can delete the virtual node itself.
#
# DELETE /v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}
# Returns: record<virtualNode: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, backends: list, listeners: list, logging: record, serviceDiscovery: record>, status: record<status: string>, virtualNodeName: string>>
# operationId: DeleteVirtualNode
export def "delete-virtual-node" [
  mesh_name: string
  virtual_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualNodeName, var: virtual_node_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_node_name: $virtual_node_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing virtual node.
#
# GET /v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}
# Returns: record<virtualNode: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, backends: list, listeners: list, logging: record, serviceDiscovery: record>, status: record<status: string>, virtualNodeName: string>>
# operationId: DescribeVirtualNode
export def "describe-virtual-node" [
  mesh_name: string
  virtual_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualNodeName, var: virtual_node_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_node_name: $virtual_node_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing virtual node in a specified service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}
# Returns: record<virtualNode: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<backendDefaults: record, backends: list, listeners: list, logging: record, serviceDiscovery: record>, status: record<status: string>, virtualNodeName: string>>
# operationId: UpdateVirtualNode
export def "update-virtual-node" [
  mesh_name: string
  virtual_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual node. — shape: {backendDefaults?: record, backends?: list, listeners?: list, logging?: record, serviceDiscovery?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualNodeName, var: virtual_node_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_node_name: $virtual_node_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing virtual router. You must delete any routes associated with the virtual router before you can delete the router itself.
#
# DELETE /v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}
# Returns: record<virtualRouter: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<listeners: list>, status: record<status: string>, virtualRouterName: string>>
# operationId: DeleteVirtualRouter
export def "delete-virtual-router" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualRouterName, var: virtual_router_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_router_name: $virtual_router_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing virtual router.
#
# GET /v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}
# Returns: record<virtualRouter: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<listeners: list>, status: record<status: string>, virtualRouterName: string>>
# operationId: DescribeVirtualRouter
export def "describe-virtual-router" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualRouterName, var: virtual_router_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_router_name: $virtual_router_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing virtual router in a specified service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}
# Returns: record<virtualRouter: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<listeners: list>, status: record<status: string>, virtualRouterName: string>>
# operationId: UpdateVirtualRouter
export def "update-virtual-router" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual router. — shape: {listeners?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualRouterName, var: virtual_router_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_router_name: $virtual_router_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing virtual service.
#
# DELETE /v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}
# Returns: record<virtualService: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<provider: record>, status: record<status: string>, virtualServiceName: string>>
# operationId: DeleteVirtualService
export def "delete-virtual-service" [
  mesh_name: string
  virtual_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualServiceName, var: virtual_service_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_service_name: $virtual_service_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing virtual service.
#
# GET /v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}
# Returns: record<virtualService: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<provider: record>, status: record<status: string>, virtualServiceName: string>>
# operationId: DescribeVirtualService
export def "describe-virtual-service" [
  mesh_name: string
  virtual_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
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
    path: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualServiceName, var: virtual_service_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_service_name: $virtual_service_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing virtual service in a specified service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}
# Returns: record<virtualService: record<meshName: string, metadata: record<arn: string, createdAt: string, lastUpdatedAt: string, meshOwner: string, resourceOwner: string, uid: string, version: int>, spec: record<provider: record>, status: record<status: string>, virtualServiceName: string>>
# operationId: UpdateVirtualService
export def "update-virtual-service" [
  mesh_name: string
  virtual_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual service. — shape: {provider?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}"
    path_params: [{name: meshName, var: mesh_name}, {name: virtualServiceName, var: virtual_service_name}]
    query: [{name: meshOwner, var: mesh_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: spec, var: spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mesh_name: $mesh_name, virtual_service_name: $virtual_service_name, mesh_owner: $mesh_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the tags for an App Mesh resource.
#
# GET /v20190125/tags
# Returns: record<nextToken: string, tags: table<key: string, value: string>>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of tag results returned by ListTagsForResource in paginated output. When this parameter is used, ListTagsForResource returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListTagsForResource request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListTagsForResource returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListTagsForResource request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --resource-arn: string # The Amazon Resource Name (ARN) that identifies the resource to list the tags for. (required)
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
    path: "/v20190125/tags"
    query: [{name: limit, var: limit}, {name: nextToken, var: next_token}, {name: resourceArn, var: resource_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, next_token: $next_token, resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource aren't specified in the request parameters, they aren't changed. When a resource is deleted, the tags associated with that resource are also deleted.
#
# PUT /v20190125/tag
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource to add tags to. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # The tags to add to the resource. A tag is an array of key-value pairs. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/tag"
    query: [{name: resourceArn, var: resource_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes specified tags from a resource.
#
# PUT /v20190125/untag
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource to delete tags from. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tag_keys: list<string> # The keys of the tags to be removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v20190125/untag"
    query: [{name: resourceArn, var: resource_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
