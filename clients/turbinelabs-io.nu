# Auto-generated client for Turbine Labs API v1.0
# Source: https://api.apis.guru/v2/specs/turbinelabs.io/1.0/swagger.json
# Auth: --token flag or $env.TURBINE_LABS_API_TOKEN

const CLIENT = {
  base_url: "https://api.turbinelabs.io/v1.0"
  token_env_var: "TURBINE_LABS_API_TOKEN"
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

def base-url-completer [] { ["https://api.turbinelabs.io/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["after" "before"] }
def protocol-completer [] { ["http" "http2" "http_auto" "tcp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-admin-user-self: "record<checksum: string, deleted_at: string, login_email: string, user_key: string>"
    get-admin-user-self-access-tokens: "record<result: table<access_token_key: string, checksum: string, created_at: string, description: string, signed_token: string, user_key: string>>"
    post-admin-user-self-access-tokens: "record<access_token_key: string, checksum: string, created_at: string, description: string, signed_token: string, user_key: string>"
    get-changelog-adhoc: "record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>"
    get-changelog-cluster-graph-cluster-key: "record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>"
    get-changelog-domain-graph-domain-key: "record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>"
    get-changelog-route-graph-route-key: "record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>"
    get-changelog-shared-rules-graph-shared-rules-key: "record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>"
    get-changelog-zone-zone-key: "record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>"
    get-cluster: "record<result: table<circuit_breakers: record, health_checks: list, instances: list, name: string, outlier_detection: record, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>>"
    post-cluster: "record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>>"
    delete-cluster-cluster-key: "record"
    get-cluster-cluster-key: "record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>>"
    put-cluster-cluster-key: "record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>>"
    post-cluster-cluster-key-instances: "record<result: record<host: string, metadata: list<record>, port: int>>"
    delete-cluster-cluster-key-instances-instance-identifier: "record"
    get-domain: "record<result: table<aliases: list, checksum: string, cors_config: record, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list, ssl_config: record, zone_key: string>>"
    post-domain: "record<result: record<aliases: list<string>, checksum: string, cors_config: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, exposed_headers: list, max_age: int>, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list<record>, ssl_config: record<cert_key_pairs: list, cipher_filter: string, protocols: list>, zone_key: string>>"
    delete-domain-domain-key: "record"
    get-domain-domain-key: "record<result: record<aliases: list<string>, checksum: string, cors_config: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, exposed_headers: list, max_age: int>, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list<record>, ssl_config: record<cert_key_pairs: list, cipher_filter: string, protocols: list>, zone_key: string>>"
    get-listener: "record<result: table<domain_keys: list, ip: string, name: string, port: int, protocol: string, tracing_config: record, zone_key: string, checksum: string, listener_key: string>>"
    post-listener: "record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>>"
    delete-listener-listener-key: "record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list<string>>, zone_key: string, checksum: string, listener_key: string>"
    get-listener-listener-key: "record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>>"
    put-listener-listener-key: "record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>>"
    get-proxy: "record<result: table<domain_keys: list, listener_keys: list, name: string, zone_key: string, checksum: string, proxy_key: string>>"
    post-proxy: "record<result: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>>"
    delete-proxy-proxy-key: "record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>"
    get-proxy-proxy-key: "record<result: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>>"
    get-route: "record<result: table<checksum: string, cohort_seed: record, domain_key: string, path: string, response_data: record, retry_policy: record, route_key: string, rules: list, shared_rules_key: string, zone_key: string>>"
    post-route: "record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>>"
    delete-route-route-key: "record"
    get-route-route-key: "record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>>"
    put-route-route-key: "record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>>"
    get-shared-rules: "record<result: table<checksum: string, cohort_seed: record, default: record, properties: list, response_data: record, retry_policy: record, rules: list, shared_rules_key: string, zone_key: string>>"
    post-shared-rules: "record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>>"
    delete-shared-rules-shared-rules-key: "record"
    get-shared-rules-shared-rules-key: "record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>>"
    put-shared-rules-shared-rules-key: "record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>>"
    get-zone: "record<result: table<checksum: string, name: string, zone_key: string>>"
    post-zone: "record<result: record<checksum: string, name: string, zone_key: string>>"
    delete-zone-zone-key: "record"
    get-zone-zone-key: "record<result: record<checksum: string, name: string, zone_key: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-admin-user-self" "delete-admin-user-self-access-token-access-token-key" "get-admin-user-self-access-tokens" "post-admin-user-self-access-tokens" "get-changelog-adhoc" "get-changelog-cluster-graph-cluster-key" "get-changelog-domain-graph-domain-key" "get-changelog-route-graph-route-key" "get-changelog-shared-rules-graph-shared-rules-key" "get-changelog-zone-zone-key" "get-cluster" "post-cluster" "delete-cluster-cluster-key" "get-cluster-cluster-key" "put-cluster-cluster-key" "post-cluster-cluster-key-instances" "delete-cluster-cluster-key-instances-instance-identifier" "get-domain" "post-domain" "delete-domain-domain-key" "get-domain-domain-key" "get-listener" "post-listener" "delete-listener-listener-key" "get-listener-listener-key" "put-listener-listener-key" "get-proxy" "post-proxy" "delete-proxy-proxy-key" "get-proxy-proxy-key" "get-route" "post-route" "delete-route-route-key" "get-route-route-key" "put-route-route-key" "get-shared-rules" "post-shared-rules" "delete-shared-rules-shared-rules-key" "get-shared-rules-shared-rules-key" "put-shared-rules-shared-rules-key" "get-zone" "post-zone" "delete-zone-zone-key" "get-zone-zone-key" "commands"] | sort) } | get name | first)
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

# Returns the user object for the account authorized and making this request.
#
# GET /admin/user/self
# Returns: record<checksum: string, deleted_at: string, login_email: string, user_key: string>
export def "get-admin-user-self" [
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
    path: "/admin/user/self"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the specified access token.
#
# DELETE /admin/user/self/access_token/{access-token-key}
export def "delete-admin-user-self-access-token-access-token-key" [
  access_token_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the user to be modified (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/user/self/access_token/{access-token-key}"
    path_params: [{name: access-token-key, var: access_token_key}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_token_key: $access_token_key, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Access Tokens that are configured for the authenticated user.
#
# GET /admin/user/self/access_tokens
# Returns: record<result: table<access_token_key: string, checksum: string, created_at: string, description: string, signed_token: string, user_key: string>>
export def "get-admin-user-self-access-tokens" [
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
    path: "/admin/user/self/access_tokens"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Access Token and associates it with the authenticated user.
#
# POST /admin/user/self/access_tokens
# Returns: record<access_token_key: string, checksum: string, created_at: string, description: string, signed_token: string, user_key: string>
export def "post-admin-user-self-access-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/user/self/access_tokens"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows an arbitrary filter to be specified and applied to the org\'s change log.
#
# GET /changelog/adhoc
# Returns: record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>
export def "get-changelog-adhoc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Encoded FilterSums representing the query you would like to execute. See object definition for details.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changelog/adhoc"
    query: [{name: filter, var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get changes related to the indicated cluster
#
# GET /changelog/cluster-graph/{clusterKey}
# Returns: record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>
export def "get-changelog-cluster-graph-cluster-key" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changelog/cluster-graph/{clusterKey}"
    path_params: [{name: clusterKey, var: cluster_key}]
    query: [{name: start, var: start}, {name: end, var: end}, {name: max_results, var: max_results}, {name: ref_id, var: ref_id}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_key: $cluster_key, start: $start, end: $end, max_results: $max_results, ref_id: $ref_id, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get changes related to the indicated domain
#
# GET /changelog/domain-graph/{domainKey}
# Returns: record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>
export def "get-changelog-domain-graph-domain-key" [
  domain_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changelog/domain-graph/{domainKey}"
    path_params: [{name: domainKey, var: domain_key}]
    query: [{name: start, var: start}, {name: end, var: end}, {name: max_results, var: max_results}, {name: ref_id, var: ref_id}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_key: $domain_key, start: $start, end: $end, max_results: $max_results, ref_id: $ref_id, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get changes related to the indicated route
#
# GET /changelog/route-graph/{routeKey}
# Returns: record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>
export def "get-changelog-route-graph-route-key" [
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changelog/route-graph/{routeKey}"
    path_params: [{name: routeKey, var: route_key}]
    query: [{name: start, var: start}, {name: end, var: end}, {name: max_results, var: max_results}, {name: ref_id, var: ref_id}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    route_key: $route_key, start: $start, end: $end, max_results: $max_results, ref_id: $ref_id, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get changes related to the indicated SharedRules
#
# GET /changelog/shared-rules-graph/{sharedRulesKey}
# Returns: record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>
export def "get-changelog-shared-rules-graph-shared-rules-key" [
  shared_rules_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changelog/shared-rules-graph/{sharedRulesKey}"
    path_params: [{name: sharedRulesKey, var: shared_rules_key}]
    query: [{name: start, var: start}, {name: end, var: end}, {name: max_results, var: max_results}, {name: ref_id, var: ref_id}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shared_rules_key: $shared_rules_key, start: $start, end: $end, max_results: $max_results, ref_id: $ref_id, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get changes in a specified zone
#
# GET /changelog/zone/{zoneKey}
# Returns: record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>>
export def "get-changelog-zone-zone-key" [
  zone_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changelog/zone/{zoneKey}"
    path_params: [{name: zoneKey, var: zone_key}]
    query: [{name: start, var: start}, {name: end, var: end}, {name: max_results, var: max_results}, {name: ref_id, var: ref_id}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    zone_key: $zone_key, start: $start, end: $end, max_results: $max_results, ref_id: $ref_id, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get clusters
#
# GET /cluster
# Returns: record<result: table<circuit_breakers: record, health_checks: list, instances: list, name: string, outlier_detection: record, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>>
export def "get-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ClusterFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ClusterFilter will be included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cluster"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create cluster
#
# POST /cluster
# Returns: record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>>
export def "post-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --circuit-breakers: record # Provides limits on various parameters to protect clusters against sudden surges in traffic. — shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
  --health-checks: list # item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
  --instances: list # item shape: {host?: string, metadata?: list, port?: int}
  name: string
  --outlier-detection: record # A form of passive health checking that dynamically determines whether instances in a cluster are performing unlike others and preemptively removes them from a load balancing set. — shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
  --require-tls: oneof<nothing, bool> # If set, requests to this collection of hosts will be made via HTTPS. At this time neither certificate validation and certificate pinning are supported for proxy clients of this cluster.
  zone_key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cluster"
    body: {content_type: "application/json", kind: json, fields: [{name: circuit_breakers, var: circuit_breakers}, {name: health_checks, var: health_checks}, {name: instances, var: instances}, {name: name, var: name}, {name: outlier_detection, var: outlier_detection}, {name: require_tls, var: require_tls}, {name: zone_key, var: zone_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    circuit_breakers: $circuit_breakers, health_checks: $health_checks, instances: $instances, name: $name, outlier_detection: $outlier_detection, require_tls: $require_tls, zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete cluster
#
# DELETE /cluster/{clusterKey}
# Returns: record
export def "delete-cluster-cluster-key" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the cluster to be deleted (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/cluster/{clusterKey}"
    path_params: [{name: clusterKey, var: cluster_key}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_key: $cluster_key, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get cluster
#
# GET /cluster/{clusterKey}
# Returns: record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>>
export def "get-cluster-cluster-key" [
  cluster_key: string
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
    path: "/cluster/{clusterKey}"
    path_params: [{name: clusterKey, var: cluster_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_key: $cluster_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify cluster
#
# PUT /cluster/{clusterKey}
# Returns: record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>>
export def "put-cluster-cluster-key" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --circuit-breakers: record # Provides limits on various parameters to protect clusters against sudden surges in traffic. — shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
  --health-checks: list # item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
  --instances: list # item shape: {host?: string, metadata?: list, port?: int}
  name: string
  --outlier-detection: record # A form of passive health checking that dynamically determines whether instances in a cluster are performing unlike others and preemptively removes them from a load balancing set. — shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
  --require-tls: oneof<nothing, bool> # If set, requests to this collection of hosts will be made via HTTPS. At this time neither certificate validation and certificate pinning are supported for proxy clients of this cluster.
  zone_key: string
  checksum: string
  --body-cluster-key: string # (spec name: cluster_key)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/cluster/{clusterKey}"
    path_params: [{name: clusterKey, var: cluster_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: circuit_breakers, var: circuit_breakers}, {name: health_checks, var: health_checks}, {name: instances, var: instances}, {name: name, var: name}, {name: outlier_detection, var: outlier_detection}, {name: require_tls, var: require_tls}, {name: zone_key, var: zone_key}, {name: checksum, var: checksum}, {name: cluster_key, var: body_cluster_key, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_key: $cluster_key, circuit_breakers: $circuit_breakers, health_checks: $health_checks, instances: $instances, name: $name, outlier_detection: $outlier_detection, require_tls: $require_tls, zone_key: $zone_key, checksum: $checksum, body_cluster_key: $body_cluster_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# add instance
#
# POST /cluster/{clusterKey}/instances
# Returns: record<result: record<host: string, metadata: list<record>, port: int>>
export def "post-cluster-cluster-key-instances" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string
  --metadata: list # item shape: {key?: string, value?: string}
  --port: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cluster/{clusterKey}/instances"
    path_params: [{name: clusterKey, var: cluster_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: host, var: host}, {name: metadata, var: metadata}, {name: port, var: port}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_key: $cluster_key, host: $host, metadata: $metadata, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# remove instance
#
# DELETE /cluster/{clusterKey}/instances/{instanceIdentifier}
# Returns: record
export def "delete-cluster-cluster-key-instances-instance-identifier" [
  cluster_key: string
  instance_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the instance to be deleted (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/cluster/{clusterKey}/instances/{instanceIdentifier}"
    path_params: [{name: clusterKey, var: cluster_key}, {name: instanceIdentifier, var: instance_identifier}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cluster_key: $cluster_key, instance_identifier: $instance_identifier, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get domains
#
# GET /domain
# Returns: record<result: table<aliases: list, checksum: string, cors_config: record, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list, ssl_config: record, zone_key: string>>
export def "get-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of DomainFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any DomainFilter will be included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domain"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create domain
#
# POST /domain
# Returns: record<result: record<aliases: list<string>, checksum: string, cors_config: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, exposed_headers: list, max_age: int>, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list<record>, ssl_config: record<cert_key_pairs: list, cipher_filter: string, protocols: list>, zone_key: string>>
export def "post-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: list<string> # A set of alternate names that this Domain may be referenced by. May start ('*.') or end ('.*') with a wildcard.
  --checksum: string
  --cors-config: record # Experimental: Controls simple CORS responses for the associated domain. The configurable properties map closely to the CORS specification which should be referenced for a full discussion on their meaning: https://www.w3.org/TR/cors/ or https://developer.mozilla.org/docs/Web/HTTP/Access_control_CORS. — shape: {allow_credentials?: bool, allowed_headers?: list<string>, allowed_methods: list<string>, allowed_origins: list<string>, exposed_headers?: list<string>, max_age?: int}
  --domain-key: string
  --force-https: oneof<nothing, bool> # If set to true, requests must use TLS. If a request is not using TLS, (as determined by the scheme or the presence of X-Forwarded-Proto header), a 301 redirect will be sent telling the client to use HTTPS.
  --gzip-enabled: oneof<nothing, bool> # Experimental: if set to true will enable gzip compression on data that passes trough this domain
  name: string
  port: int
  --redirects: list # item shape: {from: string, header_constraints?: list, name: string, redirect_type: "permanent"|"temporary", to: string}
  --ssl-config: record # Experimental: Specifies whether a domain should support SSL/TLS connections from clients. If not set the proxy will expect unencrypted HTTP traffic. — shape: {cert_key_pairs: list, cipher_filter?: string, protocols?: list<string>}
  zone_key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domain"
    body: {content_type: "application/json", kind: json, fields: [{name: aliases, var: aliases}, {name: checksum, var: checksum}, {name: cors_config, var: cors_config}, {name: domain_key, var: domain_key}, {name: force_https, var: force_https}, {name: gzip_enabled, var: gzip_enabled}, {name: name, var: name}, {name: port, var: port}, {name: redirects, var: redirects}, {name: ssl_config, var: ssl_config}, {name: zone_key, var: zone_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aliases: $aliases, checksum: $checksum, cors_config: $cors_config, domain_key: $domain_key, force_https: $force_https, gzip_enabled: $gzip_enabled, name: $name, port: $port, redirects: $redirects, ssl_config: $ssl_config, zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete domain
#
# DELETE /domain/{domainKey}
# Returns: record
export def "delete-domain-domain-key" [
  domain_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the domain to be deleted (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/domain/{domainKey}"
    path_params: [{name: domainKey, var: domain_key}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_key: $domain_key, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get domain
#
# GET /domain/{domainKey}
# Returns: record<result: record<aliases: list<string>, checksum: string, cors_config: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, exposed_headers: list, max_age: int>, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list<record>, ssl_config: record<cert_key_pairs: list, cipher_filter: string, protocols: list>, zone_key: string>>
export def "get-domain-domain-key" [
  domain_key: string
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
    path: "/domain/{domainKey}"
    path_params: [{name: domainKey, var: domain_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_key: $domain_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list listeners
#
# GET /listener
# Returns: record<result: table<domain_keys: list, ip: string, name: string, port: int, protocol: string, tracing_config: record, zone_key: string, checksum: string, listener_key: string>>
export def "get-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ListenerFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ListenerFilter will be included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listener"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create listener
#
# POST /listener
# Returns: record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>>
export def "post-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list<string>
  --ip: string # the interface this listener should bind to.
  name: string
  port: int # the port this listener should bind to.
  protocol: string@protocol-completer # the protocol this listener will handle. http and http2 configure the listener to only process requests of that type. http_auto will adapt to HTTP/1.1 and HTTP/2 as needed. tcp configures the listener to be a tcp proxy
  --tracing-config: record # Configures tracing operations to be performed on the given listener — shape: {ingress?: bool, request_headers_for_tags?: list<string>}
  --zone-key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listener"
    body: {content_type: "application/json", kind: json, fields: [{name: domain_keys, var: domain_keys}, {name: ip, var: ip}, {name: name, var: name}, {name: port, var: port}, {name: protocol, var: protocol}, {name: tracing_config, var: tracing_config}, {name: zone_key, var: zone_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_keys: $domain_keys, ip: $ip, name: $name, port: $port, protocol: $protocol, tracing_config: $tracing_config, zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete listener
#
# DELETE /listener/{listenerKey}
# Returns: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list<string>>, zone_key: string, checksum: string, listener_key: string>
export def "delete-listener-listener-key" [
  listener_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the listener to be deleted (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/listener/{listenerKey}"
    path_params: [{name: listenerKey, var: listener_key}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    listener_key: $listener_key, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get listener
#
# GET /listener/{listenerKey}
# Returns: record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>>
export def "get-listener-listener-key" [
  listener_key: string
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
    path: "/listener/{listenerKey}"
    path_params: [{name: listenerKey, var: listener_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    listener_key: $listener_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify listener
#
# PUT /listener/{listenerKey}
# Returns: record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>>
export def "put-listener-listener-key" [
  listener_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list<string>
  --ip: string # the interface this listener should bind to.
  name: string
  port: int # the port this listener should bind to.
  protocol: string@protocol-completer # the protocol this listener will handle. http and http2 configure the listener to only process requests of that type. http_auto will adapt to HTTP/1.1 and HTTP/2 as needed. tcp configures the listener to be a tcp proxy
  --tracing-config: record # Configures tracing operations to be performed on the given listener — shape: {ingress?: bool, request_headers_for_tags?: list<string>}
  zone_key: string
  checksum: string
  --body-listener-key: string # (spec name: listener_key)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/listener/{listenerKey}"
    path_params: [{name: listenerKey, var: listener_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain_keys, var: domain_keys}, {name: ip, var: ip}, {name: name, var: name}, {name: port, var: port}, {name: protocol, var: protocol}, {name: tracing_config, var: tracing_config}, {name: zone_key, var: zone_key}, {name: checksum, var: checksum}, {name: listener_key, var: body_listener_key, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    listener_key: $listener_key, domain_keys: $domain_keys, ip: $ip, name: $name, port: $port, protocol: $protocol, tracing_config: $tracing_config, zone_key: $zone_key, checksum: $checksum, body_listener_key: $body_listener_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list proxies
#
# GET /proxy
# Returns: record<result: table<domain_keys: list, listener_keys: list, name: string, zone_key: string, checksum: string, proxy_key: string>>
export def "get-proxy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ProxyFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ProxyFilter will be included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/proxy"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create proxy
#
# POST /proxy
# Returns: record<result: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>>
export def "post-proxy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list<string>
  --listener-keys: list<string>
  name: string
  zone_key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/proxy"
    body: {content_type: "application/json", kind: json, fields: [{name: domain_keys, var: domain_keys}, {name: listener_keys, var: listener_keys}, {name: name, var: name}, {name: zone_key, var: zone_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_keys: $domain_keys, listener_keys: $listener_keys, name: $name, zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete proxy
#
# DELETE /proxy/{proxyKey}
# Returns: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>
export def "delete-proxy-proxy-key" [
  proxy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the proxy to be deleted (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/proxy/{proxyKey}"
    path_params: [{name: proxyKey, var: proxy_key}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proxy_key: $proxy_key, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get proxy
#
# GET /proxy/{proxyKey}
# Returns: record<result: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>>
export def "get-proxy-proxy-key" [
  proxy_key: string
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
    path: "/proxy/{proxyKey}"
    path_params: [{name: proxyKey, var: proxy_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proxy_key: $proxy_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get routes
#
# GET /route
# Returns: record<result: table<checksum: string, cohort_seed: record, domain_key: string, path: string, response_data: record, retry_policy: record, route_key: string, rules: list, shared_rules_key: string, zone_key: string>>
export def "get-route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of RouteFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any RouteFilter will be included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/route"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create route
#
# POST /route
# Returns: record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>>
export def "post-route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  domain_key: string
  path: string
  --response-data: record # When a request is served by this Route annotate the response with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from Route take precedence over those from a SharedRules object. — shape: {cookies?: list, headers?: list}
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --route-key: string
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
  shared_rules_key: string
  zone_key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/route"
    body: {content_type: "application/json", kind: json, fields: [{name: checksum, var: checksum}, {name: cohort_seed, var: cohort_seed}, {name: domain_key, var: domain_key}, {name: path, var: path}, {name: response_data, var: response_data}, {name: retry_policy, var: retry_policy}, {name: route_key, var: route_key}, {name: rules, var: rules}, {name: shared_rules_key, var: shared_rules_key}, {name: zone_key, var: zone_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    checksum: $checksum, cohort_seed: $cohort_seed, domain_key: $domain_key, path: $path, response_data: $response_data, retry_policy: $retry_policy, route_key: $route_key, rules: $rules, shared_rules_key: $shared_rules_key, zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete route
#
# DELETE /route/{routeKey}
# Returns: record
export def "delete-route-route-key" [
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the route to be deleted (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/route/{routeKey}"
    path_params: [{name: routeKey, var: route_key}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    route_key: $route_key, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get route
#
# GET /route/{routeKey}
# Returns: record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>>
export def "get-route-route-key" [
  route_key: string
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
    path: "/route/{routeKey}"
    path_params: [{name: routeKey, var: route_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    route_key: $route_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify route
#
# PUT /route/{routeKey}
# Returns: record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>>
export def "put-route-route-key" [
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  domain_key: string
  path: string
  --response-data: record # When a request is served by this Route annotate the response with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from Route take precedence over those from a SharedRules object. — shape: {cookies?: list, headers?: list}
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --body-route-key: string # (spec name: route_key)
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
  shared_rules_key: string
  zone_key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/route/{routeKey}"
    path_params: [{name: routeKey, var: route_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: checksum, var: checksum}, {name: cohort_seed, var: cohort_seed}, {name: domain_key, var: domain_key}, {name: path, var: path}, {name: response_data, var: response_data}, {name: retry_policy, var: retry_policy}, {name: route_key, var: body_route_key, required: true}, {name: rules, var: rules}, {name: shared_rules_key, var: shared_rules_key}, {name: zone_key, var: zone_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    route_key: $route_key, checksum: $checksum, cohort_seed: $cohort_seed, domain_key: $domain_key, path: $path, response_data: $response_data, retry_policy: $retry_policy, body_route_key: $body_route_key, rules: $rules, shared_rules_key: $shared_rules_key, zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get shared_rules
#
# GET /shared_rules
# Returns: record<result: table<checksum: string, cohort_seed: record, default: record, properties: list, response_data: record, retry_policy: record, rules: list, shared_rules_key: string, zone_key: string>>
export def "get-shared-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of SharedRulesFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any SharedRulesFilter will be included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shared_rules"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create shared_rules
#
# POST /shared_rules
# Returns: record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>>
export def "post-shared-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  default: record # shape: {dark?: list, light: list, tap?: list}
  --properties: list # item shape: {key?: string, value?: string}
  --response-data: record # When a request is served by a Route that is part of this SharedRules group the response is annotated with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from the applicable Route and ClusterConstarint takes precedence over those specified here. — shape: {cookies?: list, headers?: list}
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
  --shared-rules-key: string
  zone_key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shared_rules"
    body: {content_type: "application/json", kind: json, fields: [{name: checksum, var: checksum}, {name: cohort_seed, var: cohort_seed}, {name: default, var: default}, {name: properties, var: properties}, {name: response_data, var: response_data}, {name: retry_policy, var: retry_policy}, {name: rules, var: rules}, {name: shared_rules_key, var: shared_rules_key}, {name: zone_key, var: zone_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    checksum: $checksum, cohort_seed: $cohort_seed, default: $default, properties: $properties, response_data: $response_data, retry_policy: $retry_policy, rules: $rules, shared_rules_key: $shared_rules_key, zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete shared_rules object
#
# DELETE /shared_rules/{sharedRulesKey}
# Returns: record
export def "delete-shared-rules-shared-rules-key" [
  shared_rules_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the shared_rules to be deleted (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/shared_rules/{sharedRulesKey}"
    path_params: [{name: sharedRulesKey, var: shared_rules_key}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shared_rules_key: $shared_rules_key, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get shared_rules object
#
# GET /shared_rules/{sharedRulesKey}
# Returns: record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>>
export def "get-shared-rules-shared-rules-key" [
  shared_rules_key: string
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
    path: "/shared_rules/{sharedRulesKey}"
    path_params: [{name: sharedRulesKey, var: shared_rules_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shared_rules_key: $shared_rules_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify shared_rules object
#
# PUT /shared_rules/{sharedRulesKey}
# Returns: record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>>
export def "put-shared-rules-shared-rules-key" [
  shared_rules_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  default: record # shape: {dark?: list, light: list, tap?: list}
  --properties: list # item shape: {key?: string, value?: string}
  --response-data: record # When a request is served by a Route that is part of this SharedRules group the response is annotated with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from the applicable Route and ClusterConstarint takes precedence over those specified here. — shape: {cookies?: list, headers?: list}
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
  --body-shared-rules-key: string # (spec name: shared_rules_key)
  zone_key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/shared_rules/{sharedRulesKey}"
    path_params: [{name: sharedRulesKey, var: shared_rules_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: checksum, var: checksum}, {name: cohort_seed, var: cohort_seed}, {name: default, var: default}, {name: properties, var: properties}, {name: response_data, var: response_data}, {name: retry_policy, var: retry_policy}, {name: rules, var: rules}, {name: shared_rules_key, var: body_shared_rules_key, required: true}, {name: zone_key, var: zone_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shared_rules_key: $shared_rules_key, checksum: $checksum, cohort_seed: $cohort_seed, default: $default, properties: $properties, response_data: $response_data, retry_policy: $retry_policy, rules: $rules, body_shared_rules_key: $body_shared_rules_key, zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get a list of zones
#
# GET /zone
# Returns: record<result: table<checksum: string, name: string, zone_key: string>>
export def "get-zone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ZoneFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ZoneFilter will be included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/zone"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create zone
#
# POST /zone
# Returns: record<result: record<checksum: string, name: string, zone_key: string>>
export def "post-zone" [
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/zone"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete zone
#
# DELETE /zone/{zoneKey}
# Returns: record
export def "delete-zone-zone-key" [
  zone_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the zone to be deleted (required, e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/zone/{zoneKey}"
    path_params: [{name: zoneKey, var: zone_key}]
    query: [{name: checksum, var: checksum, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    zone_key: $zone_key, checksum: $checksum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get zone
#
# GET /zone/{zoneKey}
# Returns: record<result: record<checksum: string, name: string, zone_key: string>>
export def "get-zone-zone-key" [
  zone_key: string
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
    path: "/zone/{zoneKey}"
    path_params: [{name: zoneKey, var: zone_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    zone_key: $zone_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
