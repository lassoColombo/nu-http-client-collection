# Auto-generated client for Health ID Service v1.0
# Source: https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-healthid/1.0/openapi.json
# Auth: --token flag or $env.HEALTH_ID_SERVICE_TOKEN

const CLIENT = {
  base_url: "https://healthidsbx.ndhm.gov.in/api"
  token_env_var: "HEALTH_ID_SERVICE_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: x-hip-id, in: header, header_name: X-HIP-ID, prefix: ""}
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

def base-url-completer [] { ["https://healthidsbx.ndhm.gov.in/api"] }
def auth-scheme-completer [] { ["bearer" "x-hip-id"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "image/png"] }
def auth-type-completer [] { ["FINGERSCAN" "IRIS" "OTP"] }
def auth-method-completer [] { ["AADHAAR_BIO" "AADHAAR_OTP" "DEMOGRAPHICS" "MOBILE_OTP" "PASSWORD"] }
def benefit-doc-type-completer [] { ["ADOPTION_CERTIFICATE" "BIRTH_CERTIFICATE" "CERTIFICATE_IDENTIFY" "DISABILITY_ID_CARD" "DRIVING_LICENSE" "FREEDOM_FIGHTER_PHOTO_CARD" "KISSAN_PHOTO_PASSBOOK" "MARRIAGE_CERTIFICATE" "MNREGA_JOB_CARD" "OTHER_GOVERNMENT_ID" "PAN_CARD" "PENSIONER_PHOTO_CARD" "RATION_CARD" "VOTER_ID_CARD"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    generatere-kyc-aadhar-otp-using-post: "record<txnId: string>"
    verify-aadhar-otp-only-using-post-1: "bool"
    get-benefits-using-get: "record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    change-password-via-aadhar-using-post: "string"
    change-password-via-mobile-using-post: "string"
    generate-aadhar-otp-using-get: "string"
    generate-mobile-otp-using-get: "string"
    change-password-via-using-post: "string"
    generate-card-using-get: "record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    generate-png-card-using-get: "record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    generate-svg-card-using-get: "record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    delete-account-using-delete: "bool"
    get-account-information-using-get: "record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    update-account-information-using-post: "record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    get-qr-code-using-get: "string"
    validate-token-using-post: "bool"
    authenticate-with-password-using-post: "record<token: string>"
    authenticate-user-using-post: "record<txnId: string>"
    auth-with-mobile-token-using-post: "record<token: string>"
    cert-using-get: "string"
    confirm-with-aadhaar-bio-using-post: "record<token: string>"
    confirm-with-aadhaar-otp-using-post: "record<token: string>"
    confirm-with-demographics-using-post: "string"
    confirm-with-mobile-using-post: "record<token: string>"
    auth-account-password-request-using-post: "record<token: string>"
    initiate-auth-using-post: "record<txnId: string>"
    resend-auth-mobile-otp-using-post: "bool"
    retrieval-health-id-by-aadhar-using-post: "record<healthId: string, healthIdNumber: string>"
    generate-aadhar-otp-using-post-1: "record<txnId: string>"
    retrieval-health-id-by-mobile-using-post: "record<healthId: string, healthIdNumber: string>"
    generate-mobile-otp-using-post: "record<txnId: string>"
    get-districts-in-state-using-get: "table<code: string, name: string>"
    get-states-using-get: "table<code: string, districts: list<record>, name: string>"
    delete-tag-using-delete: "table<healthId: string, tags: record>"
    get-tags-using-get: "record"
    add-tag-using-post: "table<healthId: string, tags: record>"
    authenticate-health-facility-using-post: "string"
    change-password-using-post: "string"
    create-aadhaar-account-using-post-1: "record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>"
    generate-password-using-post: "string"
    generate-facility-otp-using-post: "record<txnId: string>"
    generate-svg-card-using-get-1: "string"
    reset-password-using-post: "string"
    generate-aadhar-otp-using-post-2: "record<txnId: string>"
    verify-aadhar-otp-using-post: "record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    verify-bio-using-post: "record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    create-health-id-by-demo-auth-using-post: "record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    delink-hid-benefit-using-post: "record<benefitName: string, healthId: string, status: string>"
    link-hid-benefit-using-post: "record<benefitName: string, healthId: string, status: string>"
    create-health-id-by-mobile-using-post: "record<txnId: string>"
    generate-mobile-otp-using-post-1: "record<txnId: string>"
    notify-benefit-using-post: "record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    find-by-aadhar-using-post: "list<record>"
    find-by-health-id-using-post: "table<benefitId: string, benefitName: string, healthIdNumber: string, stateCode: string>"
    update-mobile-information-using-post: "record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    update-account-information-using-post-1: "record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>"
    update-status-using-post: "bool"
    verify-aadhar-otp-using-post-1: "record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>"
    create-aadhaar-account-using-post: "record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>"
    generate-mobile-otp-for-txn-using-post: "record<txnId: string>"
    generate-aadhar-otp-using-post: "record<txnId: string>"
    resend-aadhar-otp-using-post: "record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>"
    get-health-id-numbers-by-aadhar-using-post: "list<record>"
    verify-aadhar-bio-using-post: "record<txnId: string>"
    verify-mobile-otp-for-txn-using-post: "record<txnId: string>"
    verify-aadhar-otp-only-using-post: "record<txnId: string>"
    verify-user-via-mobile-using-post: "record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>"
    generate-mobile-otp-using-post-1-1: "record<txnId: string>"
    resent-otp-using-post: "bool"
    verify-mobile-otp-using-post: "record<token: string>"
    search-user-by-userid-using-post: "record"
    search-user-by-account-using-post: "record<authMethods: list<string>, healthId: string, healthIdNumber: string, name: string, tags: record>"
    search-user-by-mobile-using-post: "record<authMethods: list<string>, healthId: string, healthIdNumber: string, name: string, tags: record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["generatere-kyc-aadhar-otp-using-post" "verify-aadhar-otp-only-using-post-1" "get-benefits-using-get" "change-password-via-aadhar-using-post" "change-password-via-mobile-using-post" "generate-aadhar-otp-using-get" "generate-mobile-otp-using-get" "change-password-via-using-post" "generate-card-using-get" "generate-png-card-using-get" "generate-svg-card-using-get" "delete-account-using-delete" "get-account-information-using-get" "update-account-information-using-post" "get-qr-code-using-get" "validate-token-using-post" "authenticate-with-password-using-post" "authenticate-user-using-post" "auth-with-mobile-token-using-post" "cert-using-get" "confirm-with-aadhaar-bio-using-post" "confirm-with-aadhaar-otp-using-post" "confirm-with-demographics-using-post" "confirm-with-mobile-using-post" "auth-account-password-request-using-post" "initiate-auth-using-post" "resend-auth-mobile-otp-using-post" "retrieval-health-id-by-aadhar-using-post" "generate-aadhar-otp-using-post-1" "retrieval-health-id-by-mobile-using-post" "generate-mobile-otp-using-post" "get-districts-in-state-using-get" "get-states-using-get" "delete-tag-using-delete" "get-tags-using-get" "add-tag-using-post" "authenticate-health-facility-using-post" "change-password-using-post" "create-aadhaar-account-using-post-1" "generate-password-using-post" "generate-facility-otp-using-post" "generate-svg-card-using-get-1" "reset-password-using-post" "generate-aadhar-otp-using-post-2" "verify-aadhar-otp-using-post" "verify-bio-using-post" "create-health-id-by-demo-auth-using-post" "delink-hid-benefit-using-post" "link-hid-benefit-using-post" "create-health-id-by-mobile-using-post" "generate-mobile-otp-using-post-1" "notify-benefit-using-post" "find-by-aadhar-using-post" "find-by-health-id-using-post" "update-mobile-information-using-post" "update-account-information-using-post-1" "update-status-using-post" "verify-aadhar-otp-using-post-1" "create-aadhaar-account-using-post" "generate-mobile-otp-for-txn-using-post" "generate-aadhar-otp-using-post" "resend-aadhar-otp-using-post" "get-health-id-numbers-by-aadhar-using-post" "verify-aadhar-bio-using-post" "verify-mobile-otp-for-txn-using-post" "verify-aadhar-otp-only-using-post" "verify-user-via-mobile-using-post" "generate-mobile-otp-using-post-1-1" "resent-otp-using-post" "verify-mobile-otp-using-post" "search-user-by-userid-using-post" "search-user-by-account-using-post" "search-user-by-mobile-using-post" "commands"] | sort) } | get name | first)
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

# Generate Aadhaar OTP on registrered for link account with aadhar number
#
# POST /v1/account/aadhaar/generateOTP
# Returns: record<txnId: string>
# operationId: generatereKycAadharOTPUsingPOST
export def "generatere-kyc-aadhar-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/account/aadhaar/generateOTP"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Aadhaar OTP to complete KYC/re-KYC verification.
#
# POST /v1/account/aadhaar/verifyOTP
# Returns: bool
# operationId: verifyAadharOTPOnlyUsingPOST_1
export def "verify-aadhar-otp-only-using-post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
  --otp: string
  --restrictions: string
  --txn-id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/account/aadhaar/verifyOTP"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: otp, var: otp}, {name: restrictions, var: restrictions}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token, otp: $otp, restrictions: $restrictions, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Benefits associated with HealthID.
#
# GET /v1/account/benefits
# Returns: record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: getBenefitsUsingGET
export def "get-benefits-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer XToken)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/account/benefits"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password via Aadhar for heath id.
#
# POST /v1/account/change/passwd/byAadhaar
# Returns: string
# operationId: changePasswordViaAadharUsingPOST
export def "change-password-via-aadhar-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
  --new-password: string
  --otp: string
  --txn-id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/account/change/passwd/byAadhaar"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: newPassword, var: new_password}, {name: otp, var: otp}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token, new_password: $new_password, otp: $otp, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password via mobile for heath id.
#
# POST /v1/account/change/passwd/byMobile
# Returns: string
# operationId: changePasswordViaMobileUsingPOST
export def "change-password-via-mobile-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
  --new-password: string
  --otp: string
  --txn-id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/account/change/passwd/byMobile"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: newPassword, var: new_password}, {name: otp, var: otp}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token, new_password: $new_password, otp: $otp, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Aadhaar OTP on registrered mobile number.
#
# GET /v1/account/change/passwd/generateAadhaarOTP
# Returns: string
# operationId: generateAadharOTPUsingGET
export def "generate-aadhar-otp-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/account/change/passwd/generateAadhaarOTP"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Mobile OTP to start registration.
#
# GET /v1/account/change/passwd/generateMobileOTP
# Returns: string
# operationId: generateMobileOTPUsingGET
export def "generate-mobile-otp-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/account/change/passwd/generateMobileOTP"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password via password for heath id.
#
# POST /v1/account/change/password
# Returns: string
# operationId: changePasswordViaUsingPOST
export def "change-password-via-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
  --new-password: string
  --old-password: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/account/change/password"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: newPassword, var: new_password}, {name: oldPassword, var: old_password}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token, new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Health ID card in PDF format
#
# GET /v1/account/getCard
# Returns: record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: generateCardUsingGET
export def "generate-card-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/account/getCard"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Health ID card PNG
#
# GET /v1/account/getPngCard
# Returns: record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: generatePngCardUsingGET
export def "generate-png-card-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/account/getPngCard"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Health ID card SVG
#
# GET /v1/account/getSvgCard
# Returns: record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: generateSvgCardUsingGET
export def "generate-svg-card-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/account/getSvgCard"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete account
#
# DELETE /v1/account/profile
# Returns: bool
# operationId: deleteAccountUsingDELETE
export def "delete-account-using-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/account/profile"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200, 204]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account information.
#
# GET /v1/account/profile
# Returns: record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: getAccountInformationUsingGET
export def "get-account-information-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer XToken)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/account/profile"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update account information
#
# POST /v1/account/profile
# Returns: record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: updateAccountInformationUsingPOST
export def "update-account-information-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
  --address: string
  --day-of-birth: string
  --district-code: string
  --email: string
  --first-name: string
  --health-id: string
  --last-name: string
  --middle-name: string
  --month-of-birth: string
  --password: string
  --pincode: int # format: int32
  --profile-photo: string
  --state-code: string
  --subdistrict-code: string
  --town-code: string
  --village-code: string
  --ward-code: string
  --year-of-birth: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/account/profile"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: dayOfBirth, var: day_of_birth}, {name: districtCode, var: district_code}, {name: email, var: email}, {name: firstName, var: first_name}, {name: healthId, var: health_id}, {name: lastName, var: last_name}, {name: middleName, var: middle_name}, {name: monthOfBirth, var: month_of_birth}, {name: password, var: password}, {name: pincode, var: pincode}, {name: profilePhoto, var: profile_photo}, {name: stateCode, var: state_code}, {name: subdistrictCode, var: subdistrict_code}, {name: townCode, var: town_code}, {name: villageCode, var: village_code}, {name: wardCode, var: ward_code}, {name: yearOfBirth, var: year_of_birth}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token, address: $address, day_of_birth: $day_of_birth, district_code: $district_code, email: $email, first_name: $first_name, health_id: $health_id, last_name: $last_name, middle_name: $middle_name, month_of_birth: $month_of_birth, password: $password, pincode: $pincode, profile_photo: $profile_photo, state_code: $state_code, subdistrict_code: $subdistrict_code, town_code: $town_code, village_code: $village_code, ward_code: $ward_code, year_of_birth: $year_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Quick Response code in PNG format for this account.
#
# GET /v1/account/qrCode
# Returns: string
# operationId: getQrCodeUsingGET
export def "get-qr-code-using-get" [
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
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer XToken)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/account/qrCode"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*", "image/png"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Validate auth token
#
# POST /v1/account/token
# Returns: bool
# operationId: validateTokenUsingPOST
export def "validate-token-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --auth-token: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/account/token"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: authToken, var: auth_token}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, auth_token: $auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate using Health ID number / Health ID and password
#
# POST /v1/auth/authPassword
# Returns: record<token: string>
# operationId: authenticateWithPasswordUsingPOST
export def "authenticate-with-password-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --health-id: string
  --password: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/auth/authPassword"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: healthId, var: health_id}, {name: password, var: password}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, health_id: $health_id, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate request to generate Mobile OTP using Health ID number / Health ID
#
# POST /v1/auth/authWithMobile
# Returns: record<txnId: string>
# operationId: authenticateUserUsingPOST
export def "authenticate-user-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --healthid: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/auth/authWithMobile"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: healthid, var: healthid}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, healthid: $healthid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate using verified Mobile Number and user data
#
# POST /v1/auth/authWithMobileToken
# Returns: record<token: string>
# operationId: authWithMobileTokenUsingPOST
export def "auth-with-mobile-token-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --gender: string
  --health-id: string
  --name: string
  --body-token: string # (spec name: token)
  txn_id: string
  --year-of-birth: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/auth/authWithMobileToken"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: gender, var: gender}, {name: healthId, var: health_id}, {name: name, var: name}, {name: token, var: body_token}, {name: txnId, var: txn_id}, {name: yearOfBirth, var: year_of_birth}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, gender: $gender, health_id: $health_id, name: $name, body_token: $body_token, txn_id: $txn_id, year_of_birth: $year_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Auth token public key.
#
# GET /v1/auth/cert
# Returns: string
# operationId: certUsingGET
export def "cert-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/auth/cert"
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authentication with Aadhaar Biometric based auth transaction.
#
# POST /v1/auth/confirmWithAadhaarBio
# Returns: record<token: string>
# operationId: confirmWithAadhaarBioUsingPOST
export def "confirm-with-aadhaar-bio-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --auth-type: string@auth-type-completer
  --bio-type: string
  --pid: string
  --txn-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/auth/confirmWithAadhaarBio"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: authType, var: auth_type}, {name: bioType, var: bio_type}, {name: pid, var: pid}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, auth_type: $auth_type, bio_type: $bio_type, pid: $pid, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authentication with Aadhaar OTP based auth transaction.
#
# POST /v1/auth/confirmWithAadhaarOtp
# Returns: record<token: string>
# operationId: confirmWithAadhaarOtpUsingPOST
export def "confirm-with-aadhaar-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  otp: string
  txn_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/auth/confirmWithAadhaarOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: otp, var: otp}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, otp: $otp, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate using demographic data of user.
#
# POST /v1/auth/confirmWithDemographics
# Returns: string
# operationId: confirmWithDemographicsUsingPOST
export def "confirm-with-demographics-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --gender: string
  --name: string
  txn_id: string # format: uuid
  --year-of-birth: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/auth/confirmWithDemographics"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: gender, var: gender}, {name: name, var: name}, {name: txnId, var: txn_id}, {name: yearOfBirth, var: year_of_birth}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, gender: $gender, name: $name, txn_id: $txn_id, year_of_birth: $year_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authentication with Mobile OTP based auth transaction.
#
# POST /v1/auth/confirmWithMobileOTP
# Returns: record<token: string>
# operationId: confirmWithMobileUsingPOST
export def "confirm-with-mobile-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --otp: string
  --txn-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/auth/confirmWithMobileOTP"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: otp, var: otp}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, otp: $otp, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authentication with PASSWORD based auth transaction.
#
# POST /v1/auth/confirmWithPassword
# Returns: record<token: string>
# operationId: authAccountPasswordRequestUsingPOST
export def "auth-account-password-request-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  password: string
  txn_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/auth/confirmWithPassword"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, password: $password, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate authentication process for given Health ID
#
# POST /v1/auth/init
# Returns: record<txnId: string>
# operationId: initiateAuthUsingPOST
export def "initiate-auth-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  auth_method: string@auth-method-completer
  --healthid: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/auth/init"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: authMethod, var: auth_method}, {name: healthid, var: healthid}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, auth_method: $auth_method, healthid: $healthid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Aadhaar/Mobile OTP for Authentication Transaction.
#
# POST /v1/auth/resendAuthOTP
# Returns: bool
# operationId: resendAuthMobileOTPUsingPOST
export def "resend-auth-mobile-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  txn_id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/auth/resendAuthOTP"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify aadhar OTP sent as part of forgetHealth id.
#
# POST /v1/forgot/healthId/aadhaar
# Returns: record<healthId: string, healthIdNumber: string>
# operationId: retrievalHealthIdByAadharUsingPOST
export def "retrieval-health-id-by-aadhar-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  otp: string
  txn_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/forgot/healthId/aadhaar"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: otp, var: otp}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, otp: $otp, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Aadhaar OTP on registrered mobile number
#
# POST /v1/forgot/healthId/aadhaar/generateOtp
# Returns: record<txnId: string>
# operationId: generateAadharOTPUsingPOST_1
export def "generate-aadhar-otp-using-post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhaar: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/forgot/healthId/aadhaar/generateOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadhaar, var: aadhaar}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhaar: $aadhaar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Mobile OTP sent as part of forgetHealth id.
#
# POST /v1/forgot/healthId/mobile
# Returns: record<healthId: string, healthIdNumber: string>
# operationId: retrievalHealthIdByMobileUsingPOST
export def "retrieval-health-id-by-mobile-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --day-of-birth: string
  --first-name: string
  --gender: string
  --last-name: string
  --middle-name: string
  --month-of-birth: string
  --name: string
  --otp: string
  txn_id: string
  --year-of-birth: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/forgot/healthId/mobile"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: dayOfBirth, var: day_of_birth}, {name: firstName, var: first_name}, {name: gender, var: gender}, {name: lastName, var: last_name}, {name: middleName, var: middle_name}, {name: monthOfBirth, var: month_of_birth}, {name: name, var: name}, {name: otp, var: otp}, {name: txnId, var: txn_id}, {name: yearOfBirth, var: year_of_birth}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, day_of_birth: $day_of_birth, first_name: $first_name, gender: $gender, last_name: $last_name, middle_name: $middle_name, month_of_birth: $month_of_birth, name: $name, otp: $otp, txn_id: $txn_id, year_of_birth: $year_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Mobile OTP to start registration
#
# POST /v1/forgot/healthId/mobile/generateOtp
# Returns: record<txnId: string>
# operationId: generateMobileOTPUsingPOST
export def "generate-mobile-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --mobile: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/forgot/healthId/mobile/generateOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: mobile, var: mobile}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, mobile: $mobile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of districts in a given State as per LGD.
#
# GET /v1/ha/lgd/districts
# Returns: table<code: string, name: string>
# operationId: getDistrictsInStateUsingGET
export def "get-districts-in-state-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state-code: string # stateCode (required)
  --accept-language: string # default: en-US
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/ha/lgd/districts"
    query: [{name: stateCode, var: state_code, required: true}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    state_code: $state_code, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of states as per LGD.
#
# GET /v1/ha/lgd/states
# Returns: table<code: string, districts: list<record>, name: string>
# operationId: getStatesUsingGET
export def "get-states-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/ha/lgd/states"
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete tag against HealthId.
#
# DELETE /v1/ha/tags
# Returns: table<healthId: string, tags: record>
# operationId: deleteTagUsingDELETE
export def "delete-tag-using-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --health-id: string
  --tags: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/v1/ha/tags"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: healthId, var: health_id}, {name: tags, var: tags}]}
    accept: ["*/*"]
    ok: [200, 204]
    auth: bearer
  } {
    accept_language: $accept_language, health_id: $health_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of Tags against HealthID.
#
# GET /v1/ha/tags
# Returns: record
# operationId: getTagsUsingGET
export def "get-tags-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/ha/tags"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add tag against HealthId.
#
# POST /v1/ha/tags
# Returns: table<healthId: string, tags: record>
# operationId: addTagUsingPOST
export def "add-tag-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --health-id: string
  --tags: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ha/tags"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: healthId, var: health_id}, {name: tags, var: tags}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, health_id: $health_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate token for heath facility id.
#
# POST /v1/health/facility/authenticate
# Returns: string
# operationId: authenticateHealthFacilityUsingPOST
export def "authenticate-health-facility-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --hfr-uid: string
  --password: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/health/facility/authenticate"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: hfrUid, var: hfr_uid}, {name: password, var: password}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, hfr_uid: $hfr_uid, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password for heath facility id.
#
# POST /v1/health/facility/change/password
# Returns: string
# operationId: changePasswordUsingPOST
export def "change-password-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --hfr-uid: string
  --new-password: string
  --old-password: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/health/facility/change/password"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: hfrUid, var: hfr_uid}, {name: newPassword, var: new_password}, {name: oldPassword, var: old_password}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, hfr_uid: $hfr_uid, new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Health ID card SVG
#
# POST /v1/health/facility/createHealthIdWithPreVerified
# Returns: record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>
# operationId: createAadhaarAccountUsingPOST_1
export def "create-aadhaar-account-using-post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --email: string
  --first-name: string
  --health-id: string
  --last-name: string
  --middle-name: string
  --password: string
  --profile-photo: string
  --txn-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/health/facility/createHealthIdWithPreVerified"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: healthId, var: health_id}, {name: lastName, var: last_name}, {name: middleName, var: middle_name}, {name: password, var: password}, {name: profilePhoto, var: profile_photo}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, email: $email, first_name: $first_name, health_id: $health_id, last_name: $last_name, middle_name: $middle_name, password: $password, profile_photo: $profile_photo, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates password for heath facility id.
#
# POST /v1/health/facility/generate/password
# Returns: string
# operationId: generatePasswordUsingPOST
export def "generate-password-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --hfr-uid: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/health/facility/generate/password"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: hfrUid, var: hfr_uid}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, hfr_uid: $hfr_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate health hacility OTP on registrered mobile number
#
# POST /v1/health/facility/generateOtp
# Returns: record<txnId: string>
# operationId: generateFacilityOTPUsingPOST
export def "generate-facility-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --x-token: string # Auth Token (required, e.g. Bearer XToken)
  --aadhaar: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/health/facility/generateOtp"
    header: [{name: Accept-Language, var: accept_language}, {name: X-Token, var: x_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadhaar, var: aadhaar}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, x_token: $x_token, aadhaar: $aadhaar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# generateSvgCard
#
# GET /v1/health/facility/getSvgCard
# Returns: string
# operationId: generateSvgCardUsingGET_1
export def "generate-svg-card-using-get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --health-id: string # Your health id (required, e.g. demo@ndhm)
  --x-token: string # Auth Token (required, e.g. Bearer X-Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/health/facility/getSvgCard"
    header: [{name: Accept-Language, var: accept_language}, {name: Health-ID, var: health_id, required: true}, {name: X-Token, var: x_token, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    accept_language: $accept_language, health_id: $health_id, x_token: $x_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset password for heath facility id.
#
# POST /v1/health/facility/reset/password
# Returns: string
# operationId: resetPasswordUsingPOST
export def "reset-password-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --hfr-uid: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/health/facility/reset/password"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: hfrUid, var: hfr_uid}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, hfr_uid: $hfr_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Aadhaar OTP on registrered mobile number
#
# POST /v1/hid/benefit/aadhaar/generateOtp
# Returns: record<txnId: string>
# operationId: generateAadharOTPUsingPOST_2
export def "generate-aadhar-otp-using-post-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhaar: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/aadhaar/generateOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadhaar, var: aadhaar}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhaar: $aadhaar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create health id using Aadhaar Number Otp.
#
# POST /v1/hid/benefit/aadhaar/verifyAadharOtp
# Returns: record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: verifyAadharOtpUsingPOST
export def "verify-aadhar-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-id: string
  --benefit-name: string
  --consent-health-id: oneof<nothing, bool>
  --mobile-number: string
  --otp: string
  --txn-id: string
  --validity: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/aadhaar/verifyAadharOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoGeneratedBenefitId, var: auto_generated_benefit_id}, {name: benefitId, var: benefit_id}, {name: benefitName, var: benefit_name}, {name: consentHealthId, var: consent_health_id}, {name: mobileNumber, var: mobile_number}, {name: otp, var: otp}, {name: txnId, var: txn_id}, {name: validity, var: validity}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, auto_generated_benefit_id: $auto_generated_benefit_id, benefit_id: $benefit_id, benefit_name: $benefit_name, consent_health_id: $consent_health_id, mobile_number: $mobile_number, otp: $otp, txn_id: $txn_id, validity: $validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create health id using Biometric Authentication.
#
# POST /v1/hid/benefit/aadhaar/verifyBio
# Returns: record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: verifyBioUsingPOST
export def "verify-bio-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhaar: string
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-id: string
  --benefit-name: string
  --bio-type: string
  --consent-health-id: oneof<nothing, bool>
  --mobile-number: string
  --pid: string
  --validity: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/aadhaar/verifyBio"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadhaar, var: aadhaar}, {name: autoGeneratedBenefitId, var: auto_generated_benefit_id}, {name: benefitId, var: benefit_id}, {name: benefitName, var: benefit_name}, {name: bioType, var: bio_type}, {name: consentHealthId, var: consent_health_id}, {name: mobileNumber, var: mobile_number}, {name: pid, var: pid}, {name: validity, var: validity}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhaar: $aadhaar, auto_generated_benefit_id: $auto_generated_benefit_id, benefit_id: $benefit_id, benefit_name: $benefit_name, bio_type: $bio_type, consent_health_id: $consent_health_id, mobile_number: $mobile_number, pid: $pid, validity: $validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create health id using Aadhaar Demo Auth.
#
# POST /v1/hid/benefit/createHealthId/demo/auth
# Returns: record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: createHealthIdByDemoAuthUsingPOST
export def "create-health-id-by-demo-auth-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhar-number: string
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-id: string
  --benefit-name: string
  --consent-health-id: oneof<nothing, bool>
  --date-of-birth: string
  --gender: string
  --mobile-number: string
  --name: string
  --validity: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/createHealthId/demo/auth"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadharNumber, var: aadhar_number}, {name: autoGeneratedBenefitId, var: auto_generated_benefit_id}, {name: benefitId, var: benefit_id}, {name: benefitName, var: benefit_name}, {name: consentHealthId, var: consent_health_id}, {name: dateOfBirth, var: date_of_birth}, {name: gender, var: gender}, {name: mobileNumber, var: mobile_number}, {name: name, var: name}, {name: validity, var: validity}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhar_number: $aadhar_number, auto_generated_benefit_id: $auto_generated_benefit_id, benefit_id: $benefit_id, benefit_name: $benefit_name, consent_health_id: $consent_health_id, date_of_birth: $date_of_birth, gender: $gender, mobile_number: $mobile_number, name: $name, validity: $validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# De-Linked with hid.
#
# POST /v1/hid/benefit/delink
# Returns: record<benefitName: string, healthId: string, status: string>
# operationId: delinkHidBenefitUsingPOST
export def "delink-hid-benefit-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --benefit-name: string
  --uid-token: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/delink"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: benefitName, var: benefit_name}, {name: uidToken, var: uid_token}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, benefit_name: $benefit_name, uid_token: $uid_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linked with hid.
#
# POST /v1/hid/benefit/link
# Returns: record<benefitName: string, healthId: string, status: string>
# operationId: linkHidBenefitUsingPOST
export def "link-hid-benefit-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --benefit-id: string
  --benefit-name: string
  --state-code: string
  --uid-token: string
  --validity: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/link"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: benefitId, var: benefit_id}, {name: benefitName, var: benefit_name}, {name: stateCode, var: state_code}, {name: uidToken, var: uid_token}, {name: validity, var: validity}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, benefit_id: $benefit_id, benefit_name: $benefit_name, state_code: $state_code, uid_token: $uid_token, validity: $validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create health id using mobile Authentication.
#
# POST /v1/hid/benefit/mobile/createHealthId
# Returns: record<txnId: string>
# operationId: createHealthIdByMobileUsingPOST
export def "create-health-id-by-mobile-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-doc-type: string@benefit-doc-type-completer
  --benefit-id: string
  --benefit-name: string
  --consent-health-id: oneof<nothing, bool>
  --date-of-birth: string
  --doc-number: string
  --file-type: string
  --gender: string
  --name: string
  --otp: string
  --txn-id: string
  --uploaded-doc: string
  --validity: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/mobile/createHealthId"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoGeneratedBenefitId, var: auto_generated_benefit_id}, {name: benefitDocType, var: benefit_doc_type}, {name: benefitId, var: benefit_id}, {name: benefitName, var: benefit_name}, {name: consentHealthId, var: consent_health_id}, {name: dateOfBirth, var: date_of_birth}, {name: docNumber, var: doc_number}, {name: fileType, var: file_type}, {name: gender, var: gender}, {name: name, var: name}, {name: otp, var: otp}, {name: txnId, var: txn_id}, {name: uploadedDoc, var: uploaded_doc}, {name: validity, var: validity}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, auto_generated_benefit_id: $auto_generated_benefit_id, benefit_doc_type: $benefit_doc_type, benefit_id: $benefit_id, benefit_name: $benefit_name, consent_health_id: $consent_health_id, date_of_birth: $date_of_birth, doc_number: $doc_number, file_type: $file_type, gender: $gender, name: $name, otp: $otp, txn_id: $txn_id, uploaded_doc: $uploaded_doc, validity: $validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate mobile OTP on registrered mobile number
#
# POST /v1/hid/benefit/mobile/generateOtp
# Returns: record<txnId: string>
# operationId: generateMobileOtpUsingPOST
export def "generate-mobile-otp-using-post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --mobile: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/mobile/generateOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: mobile, var: mobile}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, mobile: $mobile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create health id using notify Benefit.
#
# POST /v1/hid/benefit/notify/benefit
# Returns: record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: notifyBenefitUsingPOST
export def "notify-benefit-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhar-number-or-uid-token: string
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-id: string
  --benefit-name: string
  --consent-health-id: oneof<nothing, bool>
  --date-of-birth: string
  --gender: string
  --mobile-number: string
  --name: string
  --state-code: string
  --validity: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/notify/benefit"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadharNumberOrUidToken, var: aadhar_number_or_uid_token}, {name: autoGeneratedBenefitId, var: auto_generated_benefit_id}, {name: benefitId, var: benefit_id}, {name: benefitName, var: benefit_name}, {name: consentHealthId, var: consent_health_id}, {name: dateOfBirth, var: date_of_birth}, {name: gender, var: gender}, {name: mobileNumber, var: mobile_number}, {name: name, var: name}, {name: stateCode, var: state_code}, {name: validity, var: validity}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhar_number_or_uid_token: $aadhar_number_or_uid_token, auto_generated_benefit_id: $auto_generated_benefit_id, benefit_id: $benefit_id, benefit_name: $benefit_name, consent_health_id: $consent_health_id, date_of_birth: $date_of_birth, gender: $gender, mobile_number: $mobile_number, name: $name, state_code: $state_code, validity: $validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search health id number using aadhar or aadhar token.
#
# POST /v1/hid/benefit/search/aadhaar
# Returns: list<record>
# operationId: findByAadharUsingPOST
export def "find-by-aadhar-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhaar: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/search/aadhaar"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadhaar, var: aadhaar}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhaar: $aadhaar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search benefit using health id number.
#
# POST /v1/hid/benefit/search/healthIdNumber
# Returns: table<benefitId: string, benefitName: string, healthIdNumber: string, stateCode: string>
# operationId: findByHealthIdUsingPOST
export def "find-by-health-id-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --benefit-id: string
  --health-id: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/search/healthIdNumber"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: benefitId, var: benefit_id}, {name: healthId, var: health_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, benefit_id: $benefit_id, health_id: $health_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update mobile number for account.
#
# POST /v1/hid/benefit/update/mobile
# Returns: record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: updateMobileInformationUsingPOST
export def "update-mobile-information-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --health-id-number: string
  --mobile: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/update/mobile"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: healthIdNumber, var: health_id_number}, {name: mobile, var: mobile}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, health_id_number: $health_id_number, mobile: $mobile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update account information
#
# POST /v1/hid/benefit/update/profile
# Returns: record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string>
# operationId: updateAccountInformationUsingPOST_1
export def "update-account-information-using-post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --address: string
  --day-of-birth: string
  --district-code: string
  --email: string
  --first-name: string
  --health-id: string
  --health-id-number: string
  --last-name: string
  --middle-name: string
  --month-of-birth: string
  --password: string
  --pincode: int # format: int32
  --profile-photo: string
  --state-code: string
  --subdistrict-code: string
  --town-code: string
  --village-code: string
  --ward-code: string
  --year-of-birth: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/update/profile"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: dayOfBirth, var: day_of_birth}, {name: districtCode, var: district_code}, {name: email, var: email}, {name: firstName, var: first_name}, {name: healthId, var: health_id}, {name: healthIdNumber, var: health_id_number}, {name: lastName, var: last_name}, {name: middleName, var: middle_name}, {name: monthOfBirth, var: month_of_birth}, {name: password, var: password}, {name: pincode, var: pincode}, {name: profilePhoto, var: profile_photo}, {name: stateCode, var: state_code}, {name: subdistrictCode, var: subdistrict_code}, {name: townCode, var: town_code}, {name: villageCode, var: village_code}, {name: wardCode, var: ward_code}, {name: yearOfBirth, var: year_of_birth}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, address: $address, day_of_birth: $day_of_birth, district_code: $district_code, email: $email, first_name: $first_name, health_id: $health_id, health_id_number: $health_id_number, last_name: $last_name, middle_name: $middle_name, month_of_birth: $month_of_birth, password: $password, pincode: $pincode, profile_photo: $profile_photo, state_code: $state_code, subdistrict_code: $subdistrict_code, town_code: $town_code, village_code: $village_code, ward_code: $ward_code, year_of_birth: $year_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update health id status .
#
# POST /v1/hid/benefit/update/status
# Returns: bool
# operationId: updateStatusUsingPOST
export def "update-status-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --health-id-number: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/hid/benefit/update/status"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: healthIdNumber, var: health_id_number}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, health_id_number: $health_id_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Aadhaar OTP on registrered mobile number to create Health ID.
#
# POST /v1/registration/aadhaar/createHealthIdWithAadhaarOtp
# Returns: record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>
# operationId: verifyAadharOTPUsingPOST
export def "verify-aadhar-otp-using-post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --email: string
  --first-name: string
  --last-name: string
  --middle-name: string
  --mobile: string
  --otp: string
  --password: string
  --profile-photo: string
  --restrictions: string
  --txn-id: string
  --username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/createHealthIdWithAadhaarOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: middleName, var: middle_name}, {name: mobile, var: mobile}, {name: otp, var: otp}, {name: password, var: password}, {name: profilePhoto, var: profile_photo}, {name: restrictions, var: restrictions}, {name: txnId, var: txn_id}, {name: username, var: username}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, email: $email, first_name: $first_name, last_name: $last_name, middle_name: $middle_name, mobile: $mobile, otp: $otp, password: $password, profile_photo: $profile_photo, restrictions: $restrictions, txn_id: $txn_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Health ID using pre-verified Aadhaar & Mobile.
#
# POST /v1/registration/aadhaar/createHealthIdWithPreVerified
# Returns: record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>
# operationId: createAadhaarAccountUsingPOST
export def "create-aadhaar-account-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --email: string
  --first-name: string
  --health-id: string
  --last-name: string
  --middle-name: string
  --password: string
  --profile-photo: string
  --txn-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/createHealthIdWithPreVerified"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: healthId, var: health_id}, {name: lastName, var: last_name}, {name: middleName, var: middle_name}, {name: password, var: password}, {name: profilePhoto, var: profile_photo}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, email: $email, first_name: $first_name, health_id: $health_id, last_name: $last_name, middle_name: $middle_name, password: $password, profile_photo: $profile_photo, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Mobile OTP for verification.
#
# POST /v1/registration/aadhaar/generateMobileOTP
# Returns: record<txnId: string>
# operationId: generateMobileOTPForTxnUsingPOST
export def "generate-mobile-otp-for-txn-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --mobile: string
  --txn-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/generateMobileOTP"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: mobile, var: mobile}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, mobile: $mobile, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Aadhaar OTP on registrered mobile number
#
# POST /v1/registration/aadhaar/generateOtp
# Returns: record<txnId: string>
# operationId: generateAadharOTPUsingPOST
export def "generate-aadhar-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhaar: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/generateOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadhaar, var: aadhaar}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhaar: $aadhaar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Aadhaar OTP on registrered mobile number to create Health ID.
#
# POST /v1/registration/aadhaar/resendAadhaarOtp
# Returns: record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>
# operationId: resendAadharOTPUsingPOST
export def "resend-aadhar-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  txn_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/resendAadhaarOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search health id number using aadhar.
#
# POST /v1/registration/aadhaar/search/aadhar
# Returns: list<record>
# operationId: getHealthIdNumbersByAadharUsingPOST
export def "get-health-id-numbers-by-aadhar-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhaar: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/search/aadhar"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadhaar, var: aadhaar}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhaar: $aadhaar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Aadhaar using biometrics.
#
# POST /v1/registration/aadhaar/verifyBio
# Returns: record<txnId: string>
# operationId: verifyAadharBioUsingPOST
export def "verify-aadhar-bio-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --aadhaar: string
  --bio-type: string
  --pid: string
  --restrictions: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/verifyBio"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadhaar, var: aadhaar}, {name: bioType, var: bio_type}, {name: pid, var: pid}, {name: restrictions, var: restrictions}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, aadhaar: $aadhaar, bio_type: $bio_type, pid: $pid, restrictions: $restrictions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Mobile OTP in an existing transaction.
#
# POST /v1/registration/aadhaar/verifyMobileOTP
# Returns: record<txnId: string>
# operationId: verifyMobileOTPForTxnUsingPOST
export def "verify-mobile-otp-for-txn-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --otp: string
  --txn-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/verifyMobileOTP"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: otp, var: otp}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, otp: $otp, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Aadhaar OTP and continue for mobile verification.
#
# POST /v1/registration/aadhaar/verifyOTP
# Returns: record<txnId: string>
# operationId: verifyAadharOTPOnlyUsingPOST
export def "verify-aadhar-otp-only-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --otp: string
  --restrictions: string
  --txn-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/aadhaar/verifyOTP"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: otp, var: otp}, {name: restrictions, var: restrictions}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, otp: $otp, restrictions: $restrictions, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Health ID with verified mobile token
#
# POST /v1/registration/mobile/createHealthId
# Returns: record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string>
# operationId: verifyUserViaMobileUsingPOST
export def "verify-user-via-mobile-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --address: string
  --day-of-birth: string
  --district-code: string
  --email: string
  --first-name: string
  --gender: string
  --health-id: string
  --last-name: string
  --middle-name: string
  --month-of-birth: string
  --name: string
  --password: string
  --pincode: int # format: int32
  --profile-photo: string
  --restrictions: string
  --state-code: string
  --subdistrict-code: string
  --body-token: string # (spec name: token)
  --town-code: string
  txn_id: string
  --village-code: string
  --ward-code: string
  --year-of-birth: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/mobile/createHealthId"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: dayOfBirth, var: day_of_birth}, {name: districtCode, var: district_code}, {name: email, var: email}, {name: firstName, var: first_name}, {name: gender, var: gender}, {name: healthId, var: health_id}, {name: lastName, var: last_name}, {name: middleName, var: middle_name}, {name: monthOfBirth, var: month_of_birth}, {name: name, var: name}, {name: password, var: password}, {name: pincode, var: pincode}, {name: profilePhoto, var: profile_photo}, {name: restrictions, var: restrictions}, {name: stateCode, var: state_code}, {name: subdistrictCode, var: subdistrict_code}, {name: token, var: body_token}, {name: townCode, var: town_code}, {name: txnId, var: txn_id}, {name: villageCode, var: village_code}, {name: wardCode, var: ward_code}, {name: yearOfBirth, var: year_of_birth}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, address: $address, day_of_birth: $day_of_birth, district_code: $district_code, email: $email, first_name: $first_name, gender: $gender, health_id: $health_id, last_name: $last_name, middle_name: $middle_name, month_of_birth: $month_of_birth, name: $name, password: $password, pincode: $pincode, profile_photo: $profile_photo, restrictions: $restrictions, state_code: $state_code, subdistrict_code: $subdistrict_code, body_token: $body_token, town_code: $town_code, txn_id: $txn_id, village_code: $village_code, ward_code: $ward_code, year_of_birth: $year_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Mobile OTP to start registration
#
# POST /v1/registration/mobile/generateOtp
# Returns: record<txnId: string>
# operationId: generateMobileOTPUsingPOST_1
export def "generate-mobile-otp-using-post-1-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --mobile: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/mobile/generateOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: mobile, var: mobile}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, mobile: $mobile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Mobile OTP for Health ID registration
#
# POST /v1/registration/mobile/resendOtp
# Returns: bool
# operationId: resentOtpUsingPOST
export def "resent-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  txn_id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/registration/mobile/resendOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Mobile OTP sent as part of registration transaction.
#
# POST /v1/registration/mobile/verifyOtp
# Returns: record<token: string>
# operationId: verifyMobileOTPUsingPOST
export def "verify-mobile-otp-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --otp: string
  --txn-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registration/mobile/verifyOtp"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: otp, var: otp}, {name: txnId, var: txn_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, otp: $otp, txn_id: $txn_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search a user by Health IDs.
#
# POST /v1/search/existsByHealthId
# Returns: record
# operationId: searchUserByUseridUsingPOST
export def "search-user-by-userid-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --health-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/search/existsByHealthId"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: healthId, var: health_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, health_id: $health_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search a user by Health ID Number.
#
# POST /v1/search/searchByHealthId
# Returns: record<authMethods: list<string>, healthId: string, healthIdNumber: string, name: string, tags: record>
# operationId: searchUserByAccountUsingPOST
export def "search-user-by-account-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --health-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/search/searchByHealthId"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: healthId, var: health_id}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, health_id: $health_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search users with a mobile number.
#
# POST /v1/search/searchByMobile
# Returns: record<authMethods: list<string>, healthId: string, healthIdNumber: string, name: string, tags: record>
# operationId: searchUserByMobileUsingPOST
export def "search-user-by-mobile-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # default: en-US
  --gender: string
  --mobile: string
  --name: string
  --year-of-birth: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/search/searchByMobile"
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: gender, var: gender}, {name: mobile, var: mobile}, {name: name, var: name}, {name: yearOfBirth, var: year_of_birth}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    accept_language: $accept_language, gender: $gender, mobile: $mobile, name: $name, year_of_birth: $year_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
