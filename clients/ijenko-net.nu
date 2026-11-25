# Auto-generated client for IoE² IoT API - to create end-user applications v3.0.0
# Source: https://api.apis.guru/v2/specs/ijenko.net/3.0.0/swagger.json
# Auth: --token flag or $env.IOE_IOT_API_TO_CREATE_END_USER_APPLICATIONS_TOKEN

const CLIENT = {
  base_url: "https://ioe2api.ijenko.net"
  token_env_var: "IOE_IOT_API_TO_CREATE_END_USER_APPLICATIONS_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: access-token, in: header, header_name: Access-Token, prefix: ""}
    {name: query-token, in: query, header_name: token, prefix: ""}
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

def base-url-completer [] { ["https://ioe2api.ijenko.net"] }
def auth-scheme-completer [] { ["access-token" "query-token" "none"] }

# Completers for enum parameters
def span-completer [] { ["D" "H" "M" "Wmo" "Wsu" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    account-places: "table<id: string, name: string>"
    account-new-place: "record<code: int, message: string, resource: record<entity: string, href: string, id: string>>"
    account-tokens: "table<appName: string, id: string, lastUse: string, places: list<record>, refreshTokenExpires: string, self: bool, user: record<canLogin: bool, email: string, id: string, locale: string, metadata: record, name: string, phoneNumber: string>>"
    account-users: "table<canLogin: bool, email: string, id: string, locale: string, metadata: record, name: string, phoneNumber: string>"
    account-new-user: "record<code: int, message: string, resource: record<entity: string, href: string, id: string>>"
    account-get-user: "record<account: string, canLogin: bool, email: string, locale: string, metadata: record, name: string, phoneNumber: string>"
    user-get-metadata: "record"
    user-patch-metadata: "record"
    auth-account-login: "record<accessToken: string, accessTokenExpires: string, refreshToken: string, refreshTokenExpires: string>"
    auth-refresh-token: "record<accessToken: string, accessTokenExpires: string, refreshToken: string, refreshTokenExpires: string>"
    devices-get: "record<address: string, attributes: record, class: string, functionalities: table<class: string, device: string, endpoint: int, id: string, metadata: record, name: string, tags: list>, isOnline: bool, manufacturer: string, metadata: record, model: string, name: string, place: string, protocol: string, tags: list<string>>"
    device-add-functionality: "record<code: int, message: string, resource: record<entity: string, href: string, id: string>>"
    device-get-metadata: "record"
    device-patch-metadata: "record"
    device-run: "table<functionality: string, result: list<any>, status: int>"
    device-get-tags: "list<string>"
    device-patch-tags: "list<string>"
    functionalities-get: "record<actions: list<string>, attributes: list<string>, class: string, device: string, endpoint: int, metadata: record, name: string, tags: list<string>>"
    functionality-values: "record"
    functionality-value: "record<value: any, when: string>"
    functionality-get-metadata: "record"
    functionality-patch-metadata: "record"
    functionality-run: "record<functionality: string, result: list<any>, status: int>"
    functionality-get-tags: "list<string>"
    functionality-patch-tags: "list<string>"
    me-get: "record<email: string, id: string, locale: string, login: string, metadata: record, name: string, phoneNumber: string>"
    notifications-get: "record<data: record, metadata: record, name: string, place: string, routing: string>"
    notification-get-metadata: "record"
    notification-patch-metadata: "record"
    me-places: "table<id: string, name: string>"
    places-get: "record<account: string, country: string, metadata: record, name: string, timeZone: string, zipCode: string>"
    place-buses: "table<functionality: string, id: string, protocol: string>"
    place-pairing: "record<duration: int, enabled: bool>"
    place-open-pairing: "record<duration: int, enabled: bool>"
    place-devices: "table<address: string, class: string, id: string, isOnline: bool, metadata: record, name: string, place: string, tags: list<string>>"
    place-electricity-autonomy: "record<autonomy: float, code: int, from: string, message: string, to: string>"
    place-electricity-get-flows: "record<code: int, flows: record<battery_charge: list<record>, battery_discharge: list<record>, battery_grid: list<record>, elec_drawn: list<record>, elec_feed_in: list<record>, elec_from_household: list<record>, elec_local: list<record>, elec_to_pv: list<record>, elec_total_gen: list<record>, elec_total_usage: list<record>, elec_usage: list<record>>, message: string, missing: record<battery_charge: bool, battery_discharge: bool, battery_grid: bool, elec_drawn: bool, elec_feed_in: bool, elec_from_household: bool, elec_local: bool, elec_to_pv: bool, elec_total_gen: bool, elec_total_usage: bool, elec_usage: bool>>"
    place-electricity-get-flows-setup: "record<battery_charge: table<class: string, id: string>, battery_discharge: table<class: string, id: string>, battery_grid: table<class: string, id: string>, elec_drawn: table<class: string, id: string>, elec_feed_in: table<class: string, id: string>, elec_from_household: table<class: string, id: string>, elec_local: table<class: string, id: string>, elec_to_pv: table<class: string, id: string>, elec_total_gen: table<class: string, id: string>, elec_total_usage: table<class: string, id: string>, elec_usage: table<class: string, id: string>>"
    place-electricity-self-consumption: "record<code: int, from: string, message: string, selfConsumption: float, to: string>"
    place-functionalities: "table<class: string, device: string, endpoint: int, id: string, metadata: record, name: string, tags: list<string>>"
    place-get-metadata: "record"
    place-patch-metadata: "record"
    place-notifications: "table<id: string, metadata: record, name: string>"
    place-new-notification: "record<code: int, message: string, resource: record<entity: string, href: string, id: string>>"
    place-programs: "table<enabled: bool, id: string, metadata: record, name: string>"
    place-new-program: "record<code: int, message: string, resource: record<entity: string, href: string, id: string>>"
    place-run: "table<functionality: string, result: list<any>, status: int>"
    programs-get: "record<code: any, enabled: bool, metadata: record, name: string, place: string>"
    program-log: "table<actions: list<record>, errors: list<string>, notifications: list<string>, when: string>"
    program-get-metadata: "record"
    program-patch-metadata: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["account-change-password" "account-places" "account-new-place" "account-tokens" "account-revoke-token" "account-users" "account-new-user" "account-delete-user" "account-get-user" "account-patch-user" "user-get-metadata" "user-patch-metadata" "auth-account-login" "auth-refresh-token" "auth-reset-password" "auth-revoke-token" "devices-get" "devices-patch" "device-add-functionality" "device-get-metadata" "device-patch-metadata" "device-run" "device-get-tags" "device-patch-tags" "functionalities-get" "functionality-patch" "functionality-values" "functionality-value" "functionality-set" "functionality-get-metadata" "functionality-patch-metadata" "functionality-run" "functionality-get-tags" "functionality-patch-tags" "me-get" "me-patch" "notification-delete" "notifications-get" "notification-patch" "notification-get-metadata" "notification-patch-metadata" "me-places" "places-get" "place-patch" "place-buses" "place-pairing" "place-open-pairing" "place-devices" "place-electricity-autonomy" "place-electricity-get-flows" "place-electricity-get-flows-setup" "place-electricity-self-consumption" "place-functionalities" "place-get-metadata" "place-patch-metadata" "place-notifications" "place-new-notification" "place-programs" "place-new-program" "place-run" "program-delete" "programs-get" "program-patch" "program-log" "program-get-metadata" "program-patch-metadata" "program-run" "commands"] | sort) } | get name | first)
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

# Change the password
#
# POST /account/change-password
# operationId: Account.changePassword
export def "account-change-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string # format: password
  old_password: string # format: password
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/change-password"
    body: {content_type: "application/json", kind: json, fields: [{name: newPassword, var: new_password}, {name: oldPassword, var: old_password}]}
    accept: ["application/json"]
    ok: [204]
    auth: query-token
  } {
    new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Places of the Account
#
# GET /account/places
# Returns: table<id: string, name: string>
# operationId: Account.places
export def "account-places" [
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
    path: "/account/places"
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Place
#
# POST /account/places
# Returns: record<code: int, message: string, resource: record<entity: string, href: string, id: string>>
# operationId: Account.newPlace
export def "account-new-place" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string # Country code (ISO 3166-1 alpha-2) (e.g. FR)
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string # e.g. ⌂ Home
  time_zone: string # A time zone name from the Time Zone Database at https://www.iana.org/time-zones (e.g. Europe/Paris)
  zip_code: string # Postal code
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/places"
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: metadata, var: metadata}, {name: name, var: name}, {name: timeZone, var: time_zone}, {name: zipCode, var: zip_code}]}
    accept: ["application/json"]
    ok: [201]
    auth: query-token
  } {
    country: $country, metadata: $metadata, name: $name, time_zone: $time_zone, zip_code: $zip_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List active Tokens of the Account
#
# GET /account/tokens
# Returns: table<appName: string, id: string, lastUse: string, places: list<record>, refreshTokenExpires: string, self: bool, user: record<canLogin: bool, email: string, id: string, locale: string, metadata: record, name: string, phoneNumber: string>>
# operationId: Account.tokens
export def "account-tokens" [
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
    path: "/account/tokens"
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke a Token
#
# DELETE /account/tokens/{tokenId}
# operationId: Account.revokeToken
export def "account-revoke-token" [
  token_id: string
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
    path: "/account/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    accept: ["application/json"]
    ok: [204]
    auth: query-token
  } {
    token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Users of the Account
#
# GET /account/users
# Returns: table<canLogin: bool, email: string, id: string, locale: string, metadata: record, name: string, phoneNumber: string>
# operationId: Account.users
export def "account-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/users"
    query: [{name: embed-metadata, var: embed_metadata, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    embed_metadata: $embed_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# New User
#
# POST /account/users
# Returns: record<code: int, message: string, resource: record<entity: string, href: string, id: string>>
# operationId: Account.newUser
export def "account-new-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
  locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml . (e.g. fr-FR)
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
  --phone-number: string # Phone number of the *User* in international format, for SMS notifications. (e.g. +33177494646)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: locale, var: locale}, {name: metadata, var: metadata}, {name: name, var: name}, {name: phoneNumber, var: phone_number}]}
    accept: ["application/json"]
    ok: [201]
    auth: query-token
  } {
    email: $email, locale: $locale, metadata: $metadata, name: $name, phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a User
#
# DELETE /account/users/{userId}
# operationId: Account.deleteUser
export def "account-delete-user" [
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
    path: "/account/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: query-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about a User
#
# GET /account/users/{userId}
# Returns: record<account: string, canLogin: bool, email: string, locale: string, metadata: record, name: string, phoneNumber: string>
# operationId: Account.getUser
export def "account-get-user" [
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
    path: "/account/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a User
#
# PATCH /account/users/{userId}
# operationId: Account.patchUser
export def "account-patch-user" [
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
  --email: string # format: email
  --locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml . (e.g. fr-FR)
  --name: string
  --phone-number: string # Phone number of the *User* in international format, for SMS notifications. (e.g. +33177494646)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/account/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: locale, var: locale}, {name: name, var: name}, {name: phoneNumber, var: phone_number}]}
    accept: ["application/json"]
    ok: [204, 304]
    auth: query-token
  } {
    user_id: $user_id, email: $email, locale: $locale, name: $name, phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata
#
# GET /account/users/{userId}/metadata
# Returns: record
# operationId: User.getMetadata
export def "user-get-metadata" [
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
    path: "/account/users/{userId}/metadata"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify metadata
#
# PATCH /account/users/{userId}/metadata
# Returns: record
# operationId: User.patchMetadata
export def "user-patch-metadata" [
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
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account/users/{userId}/metadata"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200, 304]
    auth: query-token
  } {
    user_id: $user_id, add: $add, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a token using login+password
#
# POST /auth/login
# Returns: record<accessToken: string, accessTokenExpires: string, refreshToken: string, refreshTokenExpires: string>
# operationId: AuthAccountLogin
export def "auth-account-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_id: string
  login: string
  password: string # format: password
  --ttl: int # Desired maximum life-time in seconds for the refresh token (e.g. 1800)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/login"
    body: {content_type: "application/json", kind: json, fields: [{name: appId, var: app_id}, {name: login, var: login}, {name: password, var: password}, {name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, login: $login, password: $password, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh a token
#
# POST /auth/refresh
# Returns: record<accessToken: string, accessTokenExpires: string, refreshToken: string, refreshTokenExpires: string>
# operationId: AuthRefreshToken
export def "auth-refresh-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_id: string
  refresh_token: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/refresh"
    body: {content_type: "application/json", kind: json, fields: [{name: appId, var: app_id}, {name: refreshToken, var: refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ask for a new password
#
# POST /auth/reset-password
# operationId: AuthResetPassword
export def "auth-reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_id: string
  --email: string # format: email
  --login: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/auth/reset-password"
    body: {content_type: "application/json", kind: json, fields: [{name: appId, var: app_id}, {name: email, var: email}, {name: login, var: login}]}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    app_id: $app_id, email: $email, login: $login
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke a token
#
# POST /auth/revoke
# operationId: AuthRevokeToken
export def "auth-revoke-token" [
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
    path: "/auth/revoke"
    accept: ["application/json"]
    ok: [204]
    auth: query-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about a Device
#
# GET /devices/{deviceId}
# Returns: record<address: string, attributes: record, class: string, functionalities: table<class: string, device: string, endpoint: int, id: string, metadata: record, name: string, tags: list>, isOnline: bool, manufacturer: string, metadata: record, model: string, name: string, place: string, protocol: string, tags: list<string>>
# operationId: Devices.get
export def "devices-get" [
  device_id: string
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
    path: "/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Device
#
# PATCH /devices/{deviceId}
# operationId: Devices.patch
export def "devices-patch" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the *Device* as defined by the user. Can be used for user interfaces.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [204, 304]
    auth: query-token
  } {
    device_id: $device_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add dynamically a functionality
#
# POST /devices/{deviceId}/functionalities
# Returns: record<code: int, message: string, resource: record<entity: string, href: string, id: string>>
# operationId: Device.addFunctionality
export def "device-add-functionality" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  --name: string # Free functionality name
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/devices/{deviceId}/functionalities"
    path_params: [{name: deviceId, var: device_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: metadata, var: metadata}, {name: name, var: name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: query-token
  } {
    device_id: $device_id, metadata: $metadata, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata
#
# GET /devices/{deviceId}/metadata
# Returns: record
# operationId: Device.getMetadata
export def "device-get-metadata" [
  device_id: string
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
    path: "/devices/{deviceId}/metadata"
    path_params: [{name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify metadata
#
# PATCH /devices/{deviceId}/metadata
# Returns: record
# operationId: Device.patchMetadata
export def "device-patch-metadata" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/devices/{deviceId}/metadata"
    path_params: [{name: deviceId, var: device_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200, 304]
    auth: query-token
  } {
    device_id: $device_id, add: $add, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run actions
#
# POST /devices/{deviceId}/run/{action}
# Returns: table<functionality: string, result: list<any>, status: int>
# operationId: Device.run
export def "device-run" [
  device_id: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --functionalities: string # Functionality selector: Functionality tags or functionality class (optionally, '@' followed by a endpoint in decimal) or '*' for all. Multiple values are separated by '|' and are interpreted as « OR ». (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/devices/{deviceId}/run/{action}"
    path_params: [{name: deviceId, var: device_id}, {name: action, var: action}]
    query: [{name: functionalities, var: functionalities, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    device_id: $device_id, action: $action, functionalities: $functionalities, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tags
#
# GET /devices/{deviceId}/tags
# Returns: list<string>
# operationId: Device.getTags
export def "device-get-tags" [
  device_id: string
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
    path: "/devices/{deviceId}/tags"
    path_params: [{name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify tags
#
# PATCH /devices/{deviceId}/tags
# Returns: list<string>
# operationId: Device.patchTags
export def "device-patch-tags" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: list<string> # list of tags to add
  --remove: list<string> # list of tags to remove
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/devices/{deviceId}/tags"
    path_params: [{name: deviceId, var: device_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200, 304]
    auth: query-token
  } {
    device_id: $device_id, add: $add, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about a Functionality
#
# GET /functionalities/{functionalityId}
# Returns: record<actions: list<string>, attributes: list<string>, class: string, device: string, endpoint: int, metadata: record, name: string, tags: list<string>>
# operationId: Functionalities.get
export def "functionalities-get" [
  functionality_id: string
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
    path: "/functionalities/{functionalityId}"
    path_params: [{name: functionalityId, var: functionality_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    functionality_id: $functionality_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Functionality
#
# PATCH /functionalities/{functionalityId}
# operationId: Functionality.patch
export def "functionality-patch" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Free functionality name
]: any -> any {
  $in | http-request {
    method: patch
    path: "/functionalities/{functionalityId}"
    path_params: [{name: functionalityId, var: functionality_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [204, 304]
    auth: query-token
  } {
    functionality_id: $functionality_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get history of multiple attributes
#
# GET /functionalities/{functionalityId}/attributes
# Returns: record
# operationId: Functionality.values
export def "functionality-values" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --names: list<string> # One or multiple *Attribute* names separated by commas
  --from: string # Beginning of the time interval. (format: date-time)
  --to: string # End of the interval. Default: now. (format: date-time)
  --surround: oneof<nothing, bool> # If true, return also one value before from and one value after to
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/functionalities/{functionalityId}/attributes"
    path_params: [{name: functionalityId, var: functionality_id}]
    query: [{name: names, var: names, style: csv}, {name: from, var: from}, {name: to, var: to}, {name: surround, var: surround}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    functionality_id: $functionality_id, names: $names, from: $from, to: $to, surround: $surround
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Attribute value
#
# GET /functionalities/{functionalityId}/attributes/{attributeName}
# Returns: record<value: any, when: string>
# operationId: Functionality.value
export def "functionality-value" [
  functionality_id: string
  attribute_name: string
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
    path: "/functionalities/{functionalityId}/attributes/{attributeName}"
    path_params: [{name: functionalityId, var: functionality_id}, {name: attributeName, var: attribute_name}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: query-token
  } {
    functionality_id: $functionality_id, attribute_name: $attribute_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an Attribute value
#
# PUT /functionalities/{functionalityId}/attributes/{attributeName}
# operationId: Functionality.set
export def "functionality-set" [
  functionality_id: string
  attribute_name: string
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
    path: "/functionalities/{functionalityId}/attributes/{attributeName}"
    path_params: [{name: functionalityId, var: functionality_id}, {name: attributeName, var: attribute_name}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: query-token
  } {
    functionality_id: $functionality_id, attribute_name: $attribute_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata
#
# GET /functionalities/{functionalityId}/metadata
# Returns: record
# operationId: Functionality.getMetadata
export def "functionality-get-metadata" [
  functionality_id: string
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
    path: "/functionalities/{functionalityId}/metadata"
    path_params: [{name: functionalityId, var: functionality_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    functionality_id: $functionality_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify metadata
#
# PATCH /functionalities/{functionalityId}/metadata
# Returns: record
# operationId: Functionality.patchMetadata
export def "functionality-patch-metadata" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/functionalities/{functionalityId}/metadata"
    path_params: [{name: functionalityId, var: functionality_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200, 304]
    auth: query-token
  } {
    functionality_id: $functionality_id, add: $add, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run an action
#
# POST /functionalities/{functionalityId}/run/{action}
# Returns: record<functionality: string, result: list<any>, status: int>
# operationId: Functionality.run
export def "functionality-run" [
  functionality_id: string
  action: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/functionalities/{functionalityId}/run/{action}"
    path_params: [{name: functionalityId, var: functionality_id}, {name: action, var: action}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    functionality_id: $functionality_id, action: $action, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tags
#
# GET /functionalities/{functionalityId}/tags
# Returns: list<string>
# operationId: Functionality.getTags
export def "functionality-get-tags" [
  functionality_id: string
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
    path: "/functionalities/{functionalityId}/tags"
    path_params: [{name: functionalityId, var: functionality_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    functionality_id: $functionality_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify tags
#
# PATCH /functionalities/{functionalityId}/tags
# Returns: list<string>
# operationId: Functionality.patchTags
export def "functionality-patch-tags" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: list<string> # list of tags to add
  --remove: list<string> # list of tags to remove
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/functionalities/{functionalityId}/tags"
    path_params: [{name: functionalityId, var: functionality_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200, 304]
    auth: query-token
  } {
    functionality_id: $functionality_id, add: $add, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about the User
#
# GET /me
# Returns: record<email: string, id: string, locale: string, login: string, metadata: record, name: string, phoneNumber: string>
# operationId: Me.get
export def "me-get" [
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
    auth: query-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User information
#
# PATCH /me
# operationId: Me.patch
export def "me-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml . (e.g. fr-FR)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/me"
    body: {content_type: "application/json", kind: json, fields: [{name: locale, var: locale}]}
    accept: ["application/json"]
    ok: [204, 304]
    auth: query-token
  } {
    locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Notification
#
# DELETE /notifications/{notificationId}
# operationId: Notification.delete
export def "notification-delete" [
  notification_id: string
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
    path: "/notifications/{notificationId}"
    path_params: [{name: notificationId, var: notification_id}]
    accept: ["application/json"]
    ok: [204]
    auth: query-token
  } {
    notification_id: $notification_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about a Notification
#
# GET /notifications/{notificationId}
# Returns: record<data: record, metadata: record, name: string, place: string, routing: string>
# operationId: Notifications.get
export def "notifications-get" [
  notification_id: string
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
    path: "/notifications/{notificationId}"
    path_params: [{name: notificationId, var: notification_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    notification_id: $notification_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Notification
#
# PATCH /notifications/{notificationId}
# operationId: Notification.patch
export def "notification-patch" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --name: string
  --routing: string # format: uri
]: any -> any {
  $in | http-request {
    method: patch
    path: "/notifications/{notificationId}"
    path_params: [{name: notificationId, var: notification_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: name, var: name}, {name: routing, var: routing}]}
    accept: ["application/json"]
    ok: [204, 304]
    auth: query-token
  } {
    notification_id: $notification_id, data: $data, name: $name, routing: $routing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata
#
# GET /notifications/{notificationId}/metadata
# Returns: record
# operationId: Notification.getMetadata
export def "notification-get-metadata" [
  notification_id: string
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
    path: "/notifications/{notificationId}/metadata"
    path_params: [{name: notificationId, var: notification_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    notification_id: $notification_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify metadata of a Notification
#
# PATCH /notifications/{notificationId}/metadata
# Returns: record
# operationId: Notification.patchMetadata
export def "notification-patch-metadata" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/notifications/{notificationId}/metadata"
    path_params: [{name: notificationId, var: notification_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200, 304]
    auth: query-token
  } {
    notification_id: $notification_id, add: $add, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accessible Places
#
# GET /places
# Returns: table<id: string, name: string>
# operationId: Me.places
export def "me-places" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/places"
    query: [{name: embed-metadata, var: embed_metadata, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    embed_metadata: $embed_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about a Place
#
# GET /places/{placeId}
# Returns: record<account: string, country: string, metadata: record, name: string, timeZone: string, zipCode: string>
# operationId: Places.get
export def "places-get" [
  place_id: string
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
    path: "/places/{placeId}"
    path_params: [{name: placeId, var: place_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Place
#
# PATCH /places/{placeId}
# operationId: Place.patch
export def "place-patch" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country code (ISO 3166-1 alpha-2) (e.g. FR)
  --name: string # e.g. ⌂ Home
  --time-zone: string # A time zone name from the Time Zone Database at https://www.iana.org/time-zones (e.g. Europe/Paris)
  --zip-code: string # Postal code
]: any -> any {
  $in | http-request {
    method: patch
    path: "/places/{placeId}"
    path_params: [{name: placeId, var: place_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: name, var: name}, {name: timeZone, var: time_zone}, {name: zipCode, var: zip_code}]}
    accept: ["application/json"]
    ok: [204, 304]
    auth: query-token
  } {
    place_id: $place_id, country: $country, name: $name, time_zone: $time_zone, zip_code: $zip_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Buses
#
# GET /places/{placeId}/buses
# Returns: table<functionality: string, id: string, protocol: string>
# operationId: Place.buses
export def "place-buses" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-pairing: oneof<nothing, bool> # Filter out buses that have no pairing window (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/places/{placeId}/buses"
    path_params: [{name: placeId, var: place_id}]
    query: [{name: withPairing, var: with_pairing}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, with_pairing: $with_pairing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# State of the pairing window
#
# GET /places/{placeId}/buses/{busId}/pairing
# Returns: record<duration: int, enabled: bool>
# operationId: Place.pairing
export def "place-pairing" [
  place_id: string
  bus_id: string
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
    path: "/places/{placeId}/buses/{busId}/pairing"
    path_params: [{name: placeId, var: place_id}, {name: busId, var: bus_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, bus_id: $bus_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open/Close the pairing window
#
# PUT /places/{placeId}/buses/{busId}/pairing
# Returns: record<duration: int, enabled: bool>
# operationId: Place.openPairing
export def "place-open-pairing" [
  place_id: string
  bus_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --duration: int # Duration of the pairing window.
  --enabled: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/places/{placeId}/buses/{busId}/pairing"
    path_params: [{name: placeId, var: place_id}, {name: busId, var: bus_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: duration, var: duration}, {name: enabled, var: enabled, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, bus_id: $bus_id, duration: $duration, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Devices
#
# GET /places/{placeId}/devices
# Returns: table<address: string, class: string, id: string, isOnline: bool, metadata: record, name: string, place: string, tags: list<string>>
# operationId: Place.devices
export def "place-devices" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: string # Devices selector. Device tags or device classes or device ids or '*' for any. Multiple values are separated by '|' and interpreted as « OR ».
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/places/{placeId}/devices"
    path_params: [{name: placeId, var: place_id}]
    query: [{name: devices, var: devices}, {name: embed-metadata, var: embed_metadata, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, devices: $devices, embed_metadata: $embed_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get autonomy rate of the place
#
# GET /places/{placeId}/electricity/autonomy
# Returns: record<autonomy: float, code: int, from: string, message: string, to: string>
# operationId: Place.Electricity.autonomy
export def "place-electricity-autonomy" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --when: string # A time part of the time span. (required, format: date-time)
  --span: string@span-completer # Timespan: H (hour), D (day), Wmo (week starting on Monday), Wsu (week starting on Sunday), M (month), Y (year) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/places/{placeId}/electricity/autonomy"
    path_params: [{name: placeId, var: place_id}]
    query: [{name: when, var: when, required: true}, {name: span, var: span, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, when: $when, span: $span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get electricity virtual flows
#
# GET /places/{placeId}/electricity/flows
# Returns: record<code: int, flows: record<battery_charge: list<record>, battery_discharge: list<record>, battery_grid: list<record>, elec_drawn: list<record>, elec_feed_in: list<record>, elec_from_household: list<record>, elec_local: list<record>, elec_to_pv: list<record>, elec_total_gen: list<record>, elec_total_usage: list<record>, elec_usage: list<record>>, message: string, missing: record<battery_charge: bool, battery_discharge: bool, battery_grid: bool, elec_drawn: bool, elec_feed_in: bool, elec_from_household: bool, elec_local: bool, elec_to_pv: bool, elec_total_gen: bool, elec_total_usage: bool, elec_usage: bool>>
# operationId: Place.Electricity.getFlows
export def "place-electricity-get-flows" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flows: list<string> # Names of the flows requested (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/places/{placeId}/electricity/flows"
    path_params: [{name: placeId, var: place_id}]
    query: [{name: flows, var: flows, style: csv, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, flows: $flows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get electricity flows setup
#
# GET /places/{placeId}/electricity/flows/setup
# Returns: record<battery_charge: table<class: string, id: string>, battery_discharge: table<class: string, id: string>, battery_grid: table<class: string, id: string>, elec_drawn: table<class: string, id: string>, elec_feed_in: table<class: string, id: string>, elec_from_household: table<class: string, id: string>, elec_local: table<class: string, id: string>, elec_to_pv: table<class: string, id: string>, elec_total_gen: table<class: string, id: string>, elec_total_usage: table<class: string, id: string>, elec_usage: table<class: string, id: string>>
# operationId: Place.Electricity.getFlowsSetup
export def "place-electricity-get-flows-setup" [
  place_id: string
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
    path: "/places/{placeId}/electricity/flows/setup"
    path_params: [{name: placeId, var: place_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get self-consumption rate of the place
#
# GET /places/{placeId}/electricity/self-consumption
# Returns: record<code: int, from: string, message: string, selfConsumption: float, to: string>
# operationId: Place.Electricity.selfConsumption
export def "place-electricity-self-consumption" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --when: string # A time part of the time span. (required, format: date-time)
  --span: string@span-completer # Timespan: H (hour), D (day), Wmo (week starting on Monday), Wsu (week starting on Sunday), M (month), Y (year) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/places/{placeId}/electricity/self-consumption"
    path_params: [{name: placeId, var: place_id}]
    query: [{name: when, var: when, required: true}, {name: span, var: span, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, when: $when, span: $span
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Functionalities
#
# GET /places/{placeId}/functionalities
# Returns: table<class: string, device: string, endpoint: int, id: string, metadata: record, name: string, tags: list<string>>
# operationId: Place.functionalities
export def "place-functionalities" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: string # Devices selector. Device tags or device classes or device ids or '*' for any. Multiple values are separated by '|' and interpreted as « OR ».
  --functionalities: string # Functionality selector: Functionality tags or functionality class (optionally, '@' followed by a endpoint in decimal) or '*' for all. Multiple values are separated by '|' and are interpreted as « OR ».
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/places/{placeId}/functionalities"
    path_params: [{name: placeId, var: place_id}]
    query: [{name: devices, var: devices}, {name: functionalities, var: functionalities}, {name: embed-metadata, var: embed_metadata, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, devices: $devices, functionalities: $functionalities, embed_metadata: $embed_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata
#
# GET /places/{placeId}/metadata
# Returns: record
# operationId: Place.getMetadata
export def "place-get-metadata" [
  place_id: string
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
    path: "/places/{placeId}/metadata"
    path_params: [{name: placeId, var: place_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify metadata
#
# PATCH /places/{placeId}/metadata
# Returns: record
# operationId: Place.patchMetadata
export def "place-patch-metadata" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/places/{placeId}/metadata"
    path_params: [{name: placeId, var: place_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200, 304]
    auth: query-token
  } {
    place_id: $place_id, add: $add, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Notifications
#
# GET /places/{placeId}/notifications
# Returns: table<id: string, metadata: record, name: string>
# operationId: Place.notifications
export def "place-notifications" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/places/{placeId}/notifications"
    path_params: [{name: placeId, var: place_id}]
    query: [{name: embed-metadata, var: embed_metadata, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, embed_metadata: $embed_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Notification
#
# POST /places/{placeId}/notifications
# Returns: record<code: int, message: string, resource: record<entity: string, href: string, id: string>>
# operationId: Place.newNotification
export def "place-new-notification" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
  --routing: string # format: uri
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/places/{placeId}/notifications"
    path_params: [{name: placeId, var: place_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: metadata, var: metadata}, {name: name, var: name}, {name: routing, var: routing}]}
    accept: ["application/json"]
    ok: [201]
    auth: query-token
  } {
    place_id: $place_id, data: $data, metadata: $metadata, name: $name, routing: $routing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Programs
#
# GET /places/{placeId}/programs
# Returns: table<enabled: bool, id: string, metadata: record, name: string>
# operationId: Place.programs
export def "place-programs" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list<string> # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/places/{placeId}/programs"
    path_params: [{name: placeId, var: place_id}]
    query: [{name: embed-metadata, var: embed_metadata, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, embed_metadata: $embed_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Program
#
# POST /places/{placeId}/programs
# Returns: record<code: int, message: string, resource: record<entity: string, href: string, id: string>>
# operationId: Place.newProgram
export def "place-new-program" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: any # null/boolean/integer/number/string/object/array
  --enabled: oneof<nothing, bool> # default: true
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/places/{placeId}/programs"
    path_params: [{name: placeId, var: place_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: enabled, var: enabled}, {name: metadata, var: metadata}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: query-token
  } {
    place_id: $place_id, code: $code, enabled: $enabled, metadata: $metadata, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run actions
#
# POST /places/{placeId}/run/{action}
# Returns: table<functionality: string, result: list<any>, status: int>
# operationId: Place.run
export def "place-run" [
  place_id: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: string # Devices selector. Device tags or device classes or device ids or '*' for any. Multiple values are separated by '|' and interpreted as « OR ». (required)
  --functionalities: string # Functionality selector: Functionality tags or functionality class (optionally, '@' followed by a endpoint in decimal) or '*' for all. Multiple values are separated by '|' and are interpreted as « OR ». (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/places/{placeId}/run/{action}"
    path_params: [{name: placeId, var: place_id}, {name: action, var: action}]
    query: [{name: devices, var: devices, required: true}, {name: functionalities, var: functionalities, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    place_id: $place_id, action: $action, devices: $devices, functionalities: $functionalities, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Program
#
# DELETE /programs/{programId}
# operationId: Program.delete
export def "program-delete" [
  program_id: string
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
    path: "/programs/{programId}"
    path_params: [{name: programId, var: program_id}]
    accept: ["application/json"]
    ok: [204]
    auth: query-token
  } {
    program_id: $program_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about a Program
#
# GET /programs/{programId}
# Returns: record<code: any, enabled: bool, metadata: record, name: string, place: string>
# operationId: Programs.get
export def "programs-get" [
  program_id: string
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
    path: "/programs/{programId}"
    path_params: [{name: programId, var: program_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    program_id: $program_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Program
#
# PATCH /programs/{programId}
# operationId: Program.patch
export def "program-patch" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: any # null/boolean/integer/number/string/object/array
  --enabled: oneof<nothing, bool>
  --name: string
]: any -> any {
  $in | http-request {
    method: patch
    path: "/programs/{programId}"
    path_params: [{name: programId, var: program_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: enabled, var: enabled}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [204, 304]
    auth: query-token
  } {
    program_id: $program_id, code: $code, enabled: $enabled, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# History of executions of a Program
#
# GET /programs/{programId}/log
# Returns: table<actions: list<record>, errors: list<string>, notifications: list<string>, when: string>
# operationId: Program.log
export def "program-log" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # Beginning of the time interval. (required, format: date-time)
  --to: string # End of the interval. Default: now. (format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/programs/{programId}/log"
    path_params: [{name: programId, var: program_id}]
    query: [{name: from, var: from, required: true}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    program_id: $program_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata
#
# GET /programs/{programId}/metadata
# Returns: record
# operationId: Program.getMetadata
export def "program-get-metadata" [
  program_id: string
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
    path: "/programs/{programId}/metadata"
    path_params: [{name: programId, var: program_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-token
  } {
    program_id: $program_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify metadata of a Program
#
# PATCH /programs/{programId}/metadata
# Returns: record
# operationId: Program.patchMetadata
export def "program-patch-metadata" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # list of pairs key/value to add/replace
  --remove: list<string> # list of keys to remove
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/programs/{programId}/metadata"
    path_params: [{name: programId, var: program_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200, 304]
    auth: query-token
  } {
    program_id: $program_id, add: $add, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run the Program
#
# POST /programs/{programId}/run
# operationId: Program.run
export def "program-run" [
  program_id: string
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
    path: "/programs/{programId}/run"
    path_params: [{name: programId, var: program_id}]
    accept: ["application/json"]
    ok: [204]
    auth: query-token
  } {
    program_id: $program_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
