# Auto-generated client for Portfolio Optimizer v1.0.9
# Source: https://api.apis.guru/v2/specs/portfoliooptimizer.io/1.0.9/openapi.json
# Auth: --token flag or $env.PORTFOLIO_OPTIMIZER_TOKEN

const CLIENT = {
  base_url: "https://api.portfoliooptimizer.io/v1"
  token_env_var: "PORTFOLIO_OPTIMIZER_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: X-API-Key, prefix: ""}
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

def base-url-completer [] { ["https://api.portfoliooptimizer.io/v1" "https://eu-west-1.api.portfoliooptimizer.io/v1"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def denoising-method-completer [] { ["eigenvaluesClipping"] }
def distance-metric-completer [] { ["bures" "correlationMatrix" "euclidean"] }
def target-equicorrelation-matrix-completer [] { ["maximumEquicorrelationMatrix" "minimumEquicorrelationMatrix" "zeroEquicorrelationMatrix"] }
def clustering-method-completer [] { ["averageLinkage" "completeLinkage" "singleLinkage" "wardLinkage"] }
def bootstrap-method-completer [] { ["circularBlock" "iid" "stationaryBlock"] }
def factors-extraction-method-completer [] { ["approximateMinimumLinearTorsion" "exactMinimumLinearTorsion" "principalComponentAnalysis"] }
def confidence-interval-type-completer [] { ["lowerOneSided" "twoSided" "upperOneSided"] }
def clustering-ordering-completer [] { ["optimal" "r-hclust"] }
def across-cluster-allocation-method-completer [] { ["equalWeighting" "inverseVariance" "inverseVolatility"] }
def within-cluster-allocation-method-completer [] { ["equalWeighting" "inverseVariance" "inverseVolatility"] }
def subset-portfolios-aggregation-method-completer [] { ["average" "median"] }
def subset-portfolios-enumeration-method-completer [] { ["complete" "randomSampling"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-assets-analysis-absorption-ratio: "record<assetsAbsorptionRatio: float>"
    post-assets-analysis-turbulence-index: "record<assetsTurbulenceIndex: float>"
    post-assets-correlation-matrix: "record<assetsCorrelationMatrix: list<list<float>>>"
    post-assets-correlation-matrix-bounds: "record<assetsCorrelationMatrixLowerBounds: list<list<float>>, assetsCorrelationMatrixUpperBounds: list<list<float>>>"
    post-assets-correlation-matrix-denoised: "record<assetsCorrelationMatrix: list<list<float>>>"
    post-assets-correlation-matrix-distance: "record<assetsCorrelationMatrixDistance: float>"
    post-assets-correlation-matrix-effective-rank: "record<assetsCorrelationMatrixEffectiveRank: list<list<float>>>"
    post-assets-correlation-matrix-informativeness: "record<assetsCorrelationMatrixInformativeness: float>"
    post-assets-correlation-matrix-nearest: "record<assetsCorrelationMatrix: list<list<float>>>"
    post-assets-correlation-matrix-random: "record<assetsCorrelationMatrix: list<list<float>>>"
    post-assets-correlation-matrix-shrinkage: "record<assetsCorrelationMatrix: list<list<float>>>"
    post-assets-correlation-matrix-theory-implied: "record<assetsCorrelationMatrix: list<list<float>>>"
    post-assets-correlation-matrix-validation: "record<message: string>"
    post-assets-covariance-matrix: "record<assetsCovarianceMatrix: list<list<float>>>"
    post-assets-covariance-matrix-effective-rank: "record<assetsCovarianceMatrixEffectiveRank: list<list<float>>>"
    post-assets-covariance-matrix-exponentially-weighted: "record<assetsCovarianceMatrix: list<list<float>>>"
    post-assets-covariance-matrix-validation: "record<message: string>"
    post-assets-kurtosis: "record<assets: table<assetKurtosis: float>>"
    post-assets-prices-adjusted: "record<assets: table<assetAdjustedPrices: list>>"
    post-assets-prices-adjusted-forward: "record<assets: table<assetAdjustedPrices: list>>"
    post-assets-returns: "record<assets: table<assetReturns: list>>"
    post-assets-returns-average: "record<assets: table<assetAverageReturn: float>>"
    post-assets-returns-simulation-bootstrap: "record<simulations: table<assets: list>>"
    post-assets-skewness: "record<assets: table<assetSkewness: float>>"
    post-assets-variance: "record<assets: table<assetVariance: float>>"
    post-assets-volatility: "record<assets: table<assetVolatility: float>>"
    post-factors-residualization: "record<residualizedFactorReturns: list<float>>"
    post-portfolio-analysis-alpha: "record<portfolios: table<portfolioAlpha: float>>"
    post-portfolio-analysis-beta: "record<portfolios: table<portfolioBeta: float>>"
    post-portfolio-analysis-conditional-value-at-risk: "record<portfolios: table<portfolioConditionalValueAtRisk: float>>"
    post-portfolio-analysis-contributions-return: "record<portfolios: table<assetsGroupsReturnContributions: list, assetsReturnContributions: list>>"
    post-portfolio-analysis-contributions-risk: "record<portfolios: table<assetsGroupsRiskContributions: list, assetsRiskContributions: list>>"
    post-portfolio-analysis-correlation-spectrum: "record<portfolios: table<portfolioCorrelationSpectrum: list>>"
    post-portfolio-analysis-diversification-ratio: "record<portfolios: table<portfolioDiversificationRatio: float>>"
    post-portfolio-analysis-drawdowns: "record<portfolios: table<portfolioDrawdowns: list, portfolioWorstDrawdowns: list>>"
    post-portfolio-analysis-effective-number-of-bets: "record<portfolios: table<portfolioEffectiveNumberOfBets: float>>"
    post-portfolio-analysis-factors-exposures: "record<portfolios: table<portfolioAlpha: float, portfolioBetas: list, portfolioRSquared: float>>"
    post-portfolio-analysis-mean-variance-efficient-frontier: "record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>>"
    post-portfolio-analysis-mean-variance-minimum-variance-frontier: "record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>>"
    post-portfolio-analysis-return: "record<portfolios: table<portfolioReturn: float>>"
    post-portfolio-analysis-returns-average: "record<portfolios: table<portfolioAverageReturn: float>>"
    post-portfolio-analysis-sharpe-ratio: "record<portfolios: table<portfolioSharpeRatio: float>>"
    post-portfolio-analysis-sharpe-ratio-bias-adjusted: "record<portfolios: table<portfolioBiasAdjustedSharpeRatio: float>>"
    post-portfolio-analysis-sharpe-ratio-confidence-interval: "record<portfolios: table<portfolioSharpeRatioConfidenceInterval: list>>"
    post-portfolio-analysis-sharpe-ratio-probabilistic: "record<portfolios: table<portfolioProbabilisticSharpeRatio: float>>"
    post-portfolio-analysis-sharpe-ratio-probabilistic-minimum-track-record-length: "record<portfolios: table<portfolioSharpeRatioMinimumTrackRecordLength: float>>"
    post-portfolio-analysis-tracking-error: "record<portfolios: table<portfolioTrackingError: float>>"
    post-portfolio-analysis-ulcer-index: "record<portfolios: table<portfolioUlcerIndex: float>>"
    post-portfolio-analysis-ulcer-performance-index: "record<portfolios: table<portfolioUlcerPerformanceIndex: float>>"
    post-portfolio-analysis-value-at-risk: "record<portfolios: table<portfolioValueAtRisk: float>>"
    post-portfolio-analysis-volatility: "record<portfolios: table<portfolioVolatility: float>>"
    post-portfolio-construction-investable: "record<assetsPositions: list<float>, assetsWeights: list<float>>"
    post-portfolio-construction-mimicking: "record<assetsWeights: list<float>>"
    post-portfolio-construction-random: "record<portfolios: table<assetsWeights: list>>"
    post-portfolio-optimization-equal-risk-contributions: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-equal-sharpe-ratio-contributions: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-equal-volatility-weighted: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-equal-weighted: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-hierarchical-risk-parity: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-hierarchical-risk-parity-clustering-based: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-inverse-variance-weighted: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-inverse-volatility-weighted: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-market-capitalization-weighted: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-maximum-decorrelation: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-maximum-return: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-maximum-return-diversified: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-maximum-return-subset-resampling-based: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-maximum-sharpe-ratio: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-maximum-sharpe-ratio-diversified: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-maximum-sharpe-ratio-subset-resampling-based: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-maximum-ulcer-performance-index: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-mean-variance-efficient: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-mean-variance-efficient-diversified: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-mean-variance-efficient-subset-resampling-based: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-minimum-correlation: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-minimum-ulcer-index: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-minimum-variance: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-minimum-variance-diversified: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-minimum-variance-subset-resampling-based: "record<assetsWeights: list<float>>"
    post-portfolio-optimization-most-diversified: "record<assetsWeights: list<float>>"
    post-portfolio-simulation-rebalancing-drift-weight: "record<portfolios: table<portfolioValues: list>>"
    post-portfolio-simulation-rebalancing-fixed-weight: "record<portfolios: table<portfolioValues: list>>"
    post-portfolio-simulation-rebalancing-random-weight: "record<portfolios: table<portfolioValues: list>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-assets-analysis-absorption-ratio" "post-assets-analysis-turbulence-index" "post-assets-correlation-matrix" "post-assets-correlation-matrix-bounds" "post-assets-correlation-matrix-denoised" "post-assets-correlation-matrix-distance" "post-assets-correlation-matrix-effective-rank" "post-assets-correlation-matrix-informativeness" "post-assets-correlation-matrix-nearest" "post-assets-correlation-matrix-random" "post-assets-correlation-matrix-shrinkage" "post-assets-correlation-matrix-theory-implied" "post-assets-correlation-matrix-validation" "post-assets-covariance-matrix" "post-assets-covariance-matrix-effective-rank" "post-assets-covariance-matrix-exponentially-weighted" "post-assets-covariance-matrix-validation" "post-assets-kurtosis" "post-assets-prices-adjusted" "post-assets-prices-adjusted-forward" "post-assets-returns" "post-assets-returns-average" "post-assets-returns-simulation-bootstrap" "post-assets-skewness" "post-assets-variance" "post-assets-volatility" "post-factors-residualization" "post-portfolio-analysis-alpha" "post-portfolio-analysis-beta" "post-portfolio-analysis-conditional-value-at-risk" "post-portfolio-analysis-contributions-return" "post-portfolio-analysis-contributions-risk" "post-portfolio-analysis-correlation-spectrum" "post-portfolio-analysis-diversification-ratio" "post-portfolio-analysis-drawdowns" "post-portfolio-analysis-effective-number-of-bets" "post-portfolio-analysis-factors-exposures" "post-portfolio-analysis-mean-variance-efficient-frontier" "post-portfolio-analysis-mean-variance-minimum-variance-frontier" "post-portfolio-analysis-return" "post-portfolio-analysis-returns-average" "post-portfolio-analysis-sharpe-ratio" "post-portfolio-analysis-sharpe-ratio-bias-adjusted" "post-portfolio-analysis-sharpe-ratio-confidence-interval" "post-portfolio-analysis-sharpe-ratio-probabilistic" "post-portfolio-analysis-sharpe-ratio-probabilistic-minimum-track-record-length" "post-portfolio-analysis-tracking-error" "post-portfolio-analysis-ulcer-index" "post-portfolio-analysis-ulcer-performance-index" "post-portfolio-analysis-value-at-risk" "post-portfolio-analysis-volatility" "post-portfolio-construction-investable" "post-portfolio-construction-mimicking" "post-portfolio-construction-random" "post-portfolio-optimization-equal-risk-contributions" "post-portfolio-optimization-equal-sharpe-ratio-contributions" "post-portfolio-optimization-equal-volatility-weighted" "post-portfolio-optimization-equal-weighted" "post-portfolio-optimization-hierarchical-risk-parity" "post-portfolio-optimization-hierarchical-risk-parity-clustering-based" "post-portfolio-optimization-inverse-variance-weighted" "post-portfolio-optimization-inverse-volatility-weighted" "post-portfolio-optimization-market-capitalization-weighted" "post-portfolio-optimization-maximum-decorrelation" "post-portfolio-optimization-maximum-return" "post-portfolio-optimization-maximum-return-diversified" "post-portfolio-optimization-maximum-return-subset-resampling-based" "post-portfolio-optimization-maximum-sharpe-ratio" "post-portfolio-optimization-maximum-sharpe-ratio-diversified" "post-portfolio-optimization-maximum-sharpe-ratio-subset-resampling-based" "post-portfolio-optimization-maximum-ulcer-performance-index" "post-portfolio-optimization-mean-variance-efficient" "post-portfolio-optimization-mean-variance-efficient-diversified" "post-portfolio-optimization-mean-variance-efficient-subset-resampling-based" "post-portfolio-optimization-minimum-correlation" "post-portfolio-optimization-minimum-ulcer-index" "post-portfolio-optimization-minimum-variance" "post-portfolio-optimization-minimum-variance-diversified" "post-portfolio-optimization-minimum-variance-subset-resampling-based" "post-portfolio-optimization-most-diversified" "post-portfolio-simulation-rebalancing-drift-weight" "post-portfolio-simulation-rebalancing-fixed-weight" "post-portfolio-simulation-rebalancing-random-weight" "commands"] | sort) } | get name | first)
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

# Absorption Ratio
#
# POST /assets/analysis/absorption-ratio
# Returns: record<assetsAbsorptionRatio: float>
export def "post-assets-analysis-absorption-ratio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-covariance-matrix-eigenvectors: record # shape: {eigenvectorsRetained?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/analysis/absorption-ratio"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsCovarianceMatrixEigenvectors, var: assets_covariance_matrix_eigenvectors}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_covariance_matrix_eigenvectors: $assets_covariance_matrix_eigenvectors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Turbulence Index
#
# POST /assets/analysis/turbulence-index
# Returns: record<assetsTurbulenceIndex: float>
export def "post-assets-analysis-turbulence-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_average_returns: list<float> # assetsAverageReturns[i] is the average return of asset i over an historical reference period
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j over an historical reference period
  assets_returns: list<float> # assetsReturns[i] is the return of asset i over a period different from the historical reference period
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/analysis/turbulence-index"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsAverageReturns, var: assets_average_returns}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_average_returns: $assets_average_returns, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Correlation Matrix
#
# POST /assets/correlation/matrix
# Returns: record<assetsCorrelationMatrix: list<list<float>>>
export def "post-assets-correlation-matrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Correlation Matrix Bounds
#
# POST /assets/correlation/matrix/bounds
# Returns: record<assetsCorrelationMatrixLowerBounds: list<list<float>>, assetsCorrelationMatrixUpperBounds: list<list<float>>>
export def "post-assets-correlation-matrix-bounds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  assets_group: list<int> # assetsGroup[k] is the indexes of the assets belonging to the assets group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/bounds"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: assetsGroup, var: assets_group}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, assets_group: $assets_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Denoised Correlation Matrix
#
# POST /assets/correlation/matrix/denoised
# Returns: record<assetsCorrelationMatrix: list<list<float>>>
export def "post-assets-correlation-matrix-denoised" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  assets_correlation_matrix_aspect_ratio: float # The aspect ratio of the asset correlation matrix, defined as the number of assets divided by the number of asset returns per asset used to compute the asset correlation matrix
  --denoising-method: string@denoising-method-completer # The method used to denoise the asset correlation matrix (default: eigenvaluesClipping)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/denoised"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: assetsCorrelationMatrixAspectRatio, var: assets_correlation_matrix_aspect_ratio}, {name: denoisingMethod, var: denoising_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, assets_correlation_matrix_aspect_ratio: $assets_correlation_matrix_aspect_ratio, denoising_method: $denoising_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Correlation Matrix Distance
#
# POST /assets/correlation/matrix/distance
# Returns: record<assetsCorrelationMatrixDistance: float>
export def "post-assets-correlation-matrix-distance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --distance-metric: string@distance-metric-completer # The distance metric to use to compute the distance between the asset correlation matrix and the reference correlation matrix (default: euclidean)
  reference_correlation_matrix: list # referenceCorrelationMatrix[i][j] is the reference correlation between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/distance"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: distanceMetric, var: distance_metric}, {name: referenceCorrelationMatrix, var: reference_correlation_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, distance_metric: $distance_metric, reference_correlation_matrix: $reference_correlation_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Correlation Matrix Effective Rank
#
# POST /assets/correlation/matrix/effective-rank
# Returns: record<assetsCorrelationMatrixEffectiveRank: list<list<float>>>
export def "post-assets-correlation-matrix-effective-rank" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/effective-rank"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Correlation Matrix Informativeness
#
# POST /assets/correlation/matrix/informativeness
# Returns: record<assetsCorrelationMatrixInformativeness: float>
export def "post-assets-correlation-matrix-informativeness" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --distance-metric: string@distance-metric-completer # The distance metric to use to compute the informativeness of the asset correlation matrix (default: euclidean)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/informativeness"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: distanceMetric, var: distance_metric}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, distance_metric: $distance_metric
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Nearest Correlation Matrix
#
# POST /assets/correlation/matrix/nearest
# Returns: record<assetsCorrelationMatrix: list<list<float>>>
export def "post-assets-correlation-matrix-nearest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_approximate_correlation_matrix: list # assetsApproximateCorrelationMatrix[i][i] is the approximate correlation between the asset i and the asset j
  --assets-fixed-correlations: list # assetsFixedCorrelations[k] is the couple of indices (i,j) of the assets i and j for which to keep the approximate correlation assetsApproximateCorrelationMatrix[i][j] fixed
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/nearest"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsApproximateCorrelationMatrix, var: assets_approximate_correlation_matrix}, {name: assetsFixedCorrelations, var: assets_fixed_correlations}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_approximate_correlation_matrix: $assets_approximate_correlation_matrix, assets_fixed_correlations: $assets_fixed_correlations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Random Correlation Matrix
#
# POST /assets/correlation/matrix/random
# Returns: record<assetsCorrelationMatrix: list<list<float>>>
export def "post-assets-correlation-matrix-random" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/random"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Correlation Matrix Shrinkage
#
# POST /assets/correlation/matrix/shrinkage
# Returns: record<assetsCorrelationMatrix: list<list<float>>>
export def "post-assets-correlation-matrix-shrinkage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  shrinkage_factor: float # The shrinkage factor
  --target-equicorrelation-matrix: string@target-equicorrelation-matrix-completer # The shrinkage target correlation matrix
  --target-correlation-matrix: list # targetCorrelationMatrix[i][j] is the target correlation between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/shrinkage"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: shrinkageFactor, var: shrinkage_factor}, {name: targetEquicorrelationMatrix, var: target_equicorrelation_matrix}, {name: targetCorrelationMatrix, var: target_correlation_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, shrinkage_factor: $shrinkage_factor, target_equicorrelation_matrix: $target_equicorrelation_matrix, target_correlation_matrix: $target_correlation_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Theory-Implied Correlation Matrix
#
# POST /assets/correlation/matrix/theory-implied
# Returns: record<assetsCorrelationMatrix: list<list<float>>>
export def "post-assets-correlation-matrix-theory-implied" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetHierarchicalClassification: list}
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: averageLinkage)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/theory-implied"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: clusteringMethod, var: clustering_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, clustering_method: $clustering_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Correlation Matrix Validation
#
# POST /assets/correlation/matrix/validation
# Returns: record<message: string>
export def "post-assets-correlation-matrix-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/correlation/matrix/validation"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Covariance Matrix
#
# POST /assets/covariance/matrix
# Returns: record<assetsCovarianceMatrix: list<list<float>>>
export def "post-assets-covariance-matrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  --assets-correlation-matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --assets-variances: list<float> # assetsVariances[i] is the variance of the asset i
  --assets-volatilities: list<float> # assetsVolatilities[i] is the volatility of the asset i
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/covariance/matrix"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: assetsVariances, var: assets_variances}, {name: assetsVolatilities, var: assets_volatilities}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, assets_variances: $assets_variances, assets_volatilities: $assets_volatilities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Covariance Matrix Effective Rank
#
# POST /assets/covariance/matrix/effective-rank
# Returns: record<assetsCovarianceMatrixEffectiveRank: list<list<float>>>
export def "post-assets-covariance-matrix-effective-rank" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/covariance/matrix/effective-rank"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exponentially Weighted Covariance Matrix
#
# POST /assets/covariance/matrix/exponentially-weighted
# Returns: record<assetsCovarianceMatrix: list<list<float>>>
export def "post-assets-covariance-matrix-exponentially-weighted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  --decay-factor: float # The exponential decay factor (default: 0.94)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/covariance/matrix/exponentially-weighted"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: decayFactor, var: decay_factor}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, decay_factor: $decay_factor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Covariance Matrix Validation
#
# POST /assets/covariance/matrix/validation
# Returns: record<message: string>
export def "post-assets-covariance-matrix-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/covariance/matrix/validation"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kurtosis
#
# POST /assets/kurtosis
# Returns: record<assets: table<assetKurtosis: float>>
export def "post-assets-kurtosis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/kurtosis"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adjusted Prices
#
# POST /assets/prices/adjusted
# Returns: record<assets: table<assetAdjustedPrices: list>>
export def "post-assets-prices-adjusted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/prices/adjusted"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forward-Adjusted Prices
#
# POST /assets/prices/adjusted/forward
# Returns: record<assets: table<assetAdjustedPrices: list>>
export def "post-assets-prices-adjusted-forward" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/prices/adjusted/forward"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Arithmetic Returns
#
# POST /assets/returns
# Returns: record<assets: table<assetReturns: list>>
export def "post-assets-returns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/returns"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Arithmetic Average Return
#
# POST /assets/returns/average
# Returns: record<assets: table<assetAverageReturn: float>>
export def "post-assets-returns-average" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/returns/average"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bootstrap
#
# POST /assets/returns/simulation/bootstrap
# Returns: record<simulations: table<assets: list>>
export def "post-assets-returns-simulation-bootstrap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  --bootstrap-average-block-length: float # The average length of the blocks to use in case the bootstrap method is 'stationaryBlock', in time periods; if not provided, defaults to the inverse of 3.15 * the common length of the assetReturns arrays^1/3
  --bootstrap-block-length: int # The length of the blocks to use in case the bootstrap method is 'circularBlock', in time periods; if not provided, defaults to [3.15 * the common length of the assetReturns arrays^1/3]
  --bootstrap-method: string@bootstrap-method-completer # The bootstrap method to use (default: stationaryBlock)
  --simulations: int # The number of simulations to perform (default: 25)
  --simulations-length: int # The number of time period(s) to simulate per simulation; if not provided, defaults to the common length of the assetReturns arrays
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/returns/simulation/bootstrap"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: bootstrapAverageBlockLength, var: bootstrap_average_block_length}, {name: bootstrapBlockLength, var: bootstrap_block_length}, {name: bootstrapMethod, var: bootstrap_method}, {name: simulations, var: simulations}, {name: simulationsLength, var: simulations_length}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, bootstrap_average_block_length: $bootstrap_average_block_length, bootstrap_block_length: $bootstrap_block_length, bootstrap_method: $bootstrap_method, simulations: $simulations, simulations_length: $simulations_length
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Skewness
#
# POST /assets/skewness
# Returns: record<assets: table<assetSkewness: float>>
export def "post-assets-skewness" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/skewness"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Variance
#
# POST /assets/variance
# Returns: record<assets: table<assetVariance: float>>
export def "post-assets-variance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/variance"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volatility
#
# POST /assets/volatility
# Returns: record<assets: table<assetVolatility: float>>
export def "post-assets-volatility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets/volatility"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Residualization
#
# POST /factors/residualization
# Returns: record<residualizedFactorReturns: list<float>>
export def "post-factors-residualization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  factors: list # item shape: {factorReturns: list<float>}
  residualized_factor: int # The index of the factor to residualize
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/factors/residualization"
    body: {content_type: "application/json", kind: json, fields: [{name: factors, var: factors}, {name: residualizedFactor, var: residualized_factor}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    factors: $factors, residualized_factor: $residualized_factor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Alpha
#
# POST /portfolio/analysis/alpha
# Returns: record<portfolios: table<portfolioAlpha: float>>
export def "post-portfolio-analysis-alpha" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  benchmark_returns: list<float> # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  portfolios: list # item shape: {portfolioReturns: list<float>}
  --risk-free-rate: float # The risk free rate, assumed to be constant for any time t
  --risk-free-returns: list<float> # riskFreeReturns[t] is the risk free return at the time t; the riskFreeReturns array must have the same length as all the portfolioReturns arrays
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/alpha"
    body: {content_type: "application/json", kind: json, fields: [{name: benchmarkReturns, var: benchmark_returns}, {name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}, {name: riskFreeReturns, var: risk_free_returns}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    benchmark_returns: $benchmark_returns, portfolios: $portfolios, risk_free_rate: $risk_free_rate, risk_free_returns: $risk_free_returns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Beta
#
# POST /portfolio/analysis/beta
# Returns: record<portfolios: table<portfolioBeta: float>>
export def "post-portfolio-analysis-beta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  benchmark_returns: list<float> # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  portfolios: list # item shape: {portfolioReturns: list<float>}
  --risk-free-rate: float # The risk free rate, assumed to be constant for any time t
  --risk-free-returns: list<float> # riskFreeReturns[t] is the risk free return at the time t; the riskFreeReturns array must have the same length as all the portfolioReturns arrays
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/beta"
    body: {content_type: "application/json", kind: json, fields: [{name: benchmarkReturns, var: benchmark_returns}, {name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}, {name: riskFreeReturns, var: risk_free_returns}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    benchmark_returns: $benchmark_returns, portfolios: $portfolios, risk_free_rate: $risk_free_rate, risk_free_returns: $risk_free_returns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Conditional Value At Risk
#
# POST /portfolio/analysis/conditional-value-at-risk
# Returns: record<portfolios: table<portfolioConditionalValueAtRisk: float>>
export def "post-portfolio-analysis-conditional-value-at-risk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alpha: float # The conditional value at risk level
  portfolios: list # item shape: {portfolioValues: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/conditional-value-at-risk"
    body: {content_type: "application/json", kind: json, fields: [{name: alpha, var: alpha}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    alpha: $alpha, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return Contributions
#
# POST /portfolio/analysis/contributions/return
# Returns: record<portfolios: table<assetsGroupsReturnContributions: list, assetsReturnContributions: list>>
export def "post-portfolio-analysis-contributions-return" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-groups: list
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/contributions/return"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsGroups, var: assets_groups}, {name: assetsReturns, var: assets_returns}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_groups: $assets_groups, assets_returns: $assets_returns, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Risk Contributions
#
# POST /portfolio/analysis/contributions/risk
# Returns: record<portfolios: table<assetsGroupsRiskContributions: list, assetsRiskContributions: list>>
export def "post-portfolio-analysis-contributions-risk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-groups: list
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/contributions/risk"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsGroups, var: assets_groups}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_groups: $assets_groups, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Correlation Spectrum
#
# POST /portfolio/analysis/correlation-spectrum
# Returns: record<portfolios: table<portfolioCorrelationSpectrum: list>>
export def "post-portfolio-analysis-correlation-spectrum" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/correlation-spectrum"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Diversification Ratio
#
# POST /portfolio/analysis/diversification-ratio
# Returns: record<portfolios: table<portfolioDiversificationRatio: float>>
export def "post-portfolio-analysis-diversification-ratio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/diversification-ratio"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Drawdowns
#
# POST /portfolio/analysis/drawdowns
# Returns: record<portfolios: table<portfolioDrawdowns: list, portfolioWorstDrawdowns: list>>
export def "post-portfolio-analysis-drawdowns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/drawdowns"
    body: {content_type: "application/json", kind: json, fields: [{name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Effective Number of Bets
#
# POST /portfolio/analysis/effective-number-of-bets
# Returns: record<portfolios: table<portfolioEffectiveNumberOfBets: float>>
export def "post-portfolio-analysis-effective-number-of-bets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --factors-extraction-method: string@factors-extraction-method-completer # The method used to extract the uncorrelated risk factors from the asset covariance matrix (default: exactMinimumLinearTorsion)
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/effective-number-of-bets"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: factorsExtractionMethod, var: factors_extraction_method}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, factors_extraction_method: $factors_extraction_method, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Factor Exposures
#
# POST /portfolio/analysis/factors/exposures
# Returns: record<portfolios: table<portfolioAlpha: float, portfolioBetas: list, portfolioRSquared: float>>
export def "post-portfolio-analysis-factors-exposures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --factors: list # item shape: {factorReturns: list<float>}
  portfolios: list # item shape: {portfolioReturns: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/factors/exposures"
    body: {content_type: "application/json", kind: json, fields: [{name: factors, var: factors}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    factors: $factors, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mean-Variance Efficient Frontier
#
# POST /portfolio/analysis/mean-variance/efficient-frontier
# Returns: record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>>
export def "post-portfolio-analysis-mean-variance-efficient-frontier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to compute on the mean-variance efficient frontier (default: 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/mean-variance/efficient-frontier"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mean-Variance Minimum Variance Frontier
#
# POST /portfolio/analysis/mean-variance/minimum-variance-frontier
# Returns: record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>>
export def "post-portfolio-analysis-mean-variance-minimum-variance-frontier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to compute on the mean-variance minimum variance frontier (default: 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/mean-variance/minimum-variance-frontier"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Arithmetic Return
#
# POST /portfolio/analysis/return
# Returns: record<portfolios: table<portfolioReturn: float>>
export def "post-portfolio-analysis-return" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/return"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsReturns, var: assets_returns}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_returns: $assets_returns, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Arithmetic Average Return
#
# POST /portfolio/analysis/returns/average
# Returns: record<portfolios: table<portfolioAverageReturn: float>>
export def "post-portfolio-analysis-returns-average" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/returns/average"
    body: {content_type: "application/json", kind: json, fields: [{name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio
# Returns: record<portfolios: table<portfolioSharpeRatio: float>>
export def "post-portfolio-analysis-sharpe-ratio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  portfolios: list # item shape: {assetsWeights: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/sharpe-ratio"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, portfolios: $portfolios, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bias-Adjusted Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio/bias-adjusted
# Returns: record<portfolios: table<portfolioBiasAdjustedSharpeRatio: float>>
export def "post-portfolio-analysis-sharpe-ratio-bias-adjusted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/sharpe-ratio/bias-adjusted"
    body: {content_type: "application/json", kind: json, fields: [{name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    portfolios: $portfolios, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sharpe Ratio Confidence Interval
#
# POST /portfolio/analysis/sharpe-ratio/confidence-interval
# Returns: record<portfolios: table<portfolioSharpeRatioConfidenceInterval: list>>
export def "post-portfolio-analysis-sharpe-ratio-confidence-interval" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confidence-interval-type: string@confidence-interval-type-completer # The type of confidence interval to build (default: twoSided)
  --confidence-level: float # The confidence level of the confidence interval to build, in percentage (default: 0.95)
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/sharpe-ratio/confidence-interval"
    body: {content_type: "application/json", kind: json, fields: [{name: confidenceIntervalType, var: confidence_interval_type}, {name: confidenceLevel, var: confidence_level}, {name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    confidence_interval_type: $confidence_interval_type, confidence_level: $confidence_level, portfolios: $portfolios, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Probabilistic Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio/probabilistic
# Returns: record<portfolios: table<portfolioProbabilisticSharpeRatio: float>>
export def "post-portfolio-analysis-sharpe-ratio-probabilistic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-sharpe-ratio: float # The Sharpe ratio of the benchmark, in the same sampling frequency as the sampling frequency of the portfolio values
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
  --benchmark-values: list<float> # benchmarkValues[t] is the value of the benchmark at the time t; the benchmarkValues array must have the same length as all the portfolioValues arrays
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/sharpe-ratio/probabilistic"
    body: {content_type: "application/json", kind: json, fields: [{name: benchmarkSharpeRatio, var: benchmark_sharpe_ratio}, {name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}, {name: benchmarkValues, var: benchmark_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    benchmark_sharpe_ratio: $benchmark_sharpe_ratio, portfolios: $portfolios, risk_free_rate: $risk_free_rate, benchmark_values: $benchmark_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Minimum Track Record Length
#
# POST /portfolio/analysis/sharpe-ratio/probabilistic/minimum-track-record-length
# Returns: record<portfolios: table<portfolioSharpeRatioMinimumTrackRecordLength: float>>
export def "post-portfolio-analysis-sharpe-ratio-probabilistic-minimum-track-record-length" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  benchmark_sharpe_ratio: float # The Sharpe ratio of the benchmark, in the same sampling frequency as the sampling frequency of the portfolio values
  --confidence-level: float # The confidence level of the minimum track record length, in percentage (default: 0.95)
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
  --benchmark-values: list<float> # benchmarkValues[t] is the value of the benchmark at the time t; the benchmarkValues array must have the same length as all the portfolioValues arrays
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/sharpe-ratio/probabilistic/minimum-track-record-length"
    body: {content_type: "application/json", kind: json, fields: [{name: benchmarkSharpeRatio, var: benchmark_sharpe_ratio}, {name: confidenceLevel, var: confidence_level}, {name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}, {name: benchmarkValues, var: benchmark_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    benchmark_sharpe_ratio: $benchmark_sharpe_ratio, confidence_level: $confidence_level, portfolios: $portfolios, risk_free_rate: $risk_free_rate, benchmark_values: $benchmark_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tracking Error
#
# POST /portfolio/analysis/tracking-error
# Returns: record<portfolios: table<portfolioTrackingError: float>>
export def "post-portfolio-analysis-tracking-error" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  benchmark_returns: list<float> # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  portfolios: list # item shape: {portfolioReturns: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/tracking-error"
    body: {content_type: "application/json", kind: json, fields: [{name: benchmarkReturns, var: benchmark_returns}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    benchmark_returns: $benchmark_returns, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ulcer Index
#
# POST /portfolio/analysis/ulcer-index
# Returns: record<portfolios: table<portfolioUlcerIndex: float>>
export def "post-portfolio-analysis-ulcer-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/ulcer-index"
    body: {content_type: "application/json", kind: json, fields: [{name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    portfolios: $portfolios, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ulcer Performance Index
#
# POST /portfolio/analysis/ulcer-performance-index
# Returns: record<portfolios: table<portfolioUlcerPerformanceIndex: float>>
export def "post-portfolio-analysis-ulcer-performance-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/ulcer-performance-index"
    body: {content_type: "application/json", kind: json, fields: [{name: portfolios, var: portfolios}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    portfolios: $portfolios, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Value At Risk
#
# POST /portfolio/analysis/value-at-risk
# Returns: record<portfolios: table<portfolioValueAtRisk: float>>
export def "post-portfolio-analysis-value-at-risk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alpha: float # The value at risk level
  portfolios: list # item shape: {portfolioValues: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/value-at-risk"
    body: {content_type: "application/json", kind: json, fields: [{name: alpha, var: alpha}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    alpha: $alpha, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Volatility
#
# POST /portfolio/analysis/volatility
# Returns: record<portfolios: table<portfolioVolatility: float>>
export def "post-portfolio-analysis-volatility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/analysis/volatility"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Investable Portfolio
#
# POST /portfolio/construction/investable
# Returns: record<assetsPositions: list<float>, assetsWeights: list<float>>
export def "post-portfolio-construction-investable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-groups: list
  --assets-groups-weights: list<float> # assetsGroupsWeights[i] is the desired weight of the assets group k in the portfolio, in percentage (can be null to indicate no specific desire); requires assetsGroups to be present
  --assets-minimum-notional-values: list<float> # assetsMinimumNotionalValues[i] is the minimum monetary value that the position in the asset i is required to represent when the asset i is included in the portfolio
  --assets-minimum-positions: list<float> # assetsMinimumPositions[i] is the minimum number of shares of the asset i that is required to purchase when the asset i is included in the portfolio (usual values are the same as for assetsSizeLots)
  assets_prices: list<float> # assetsPrices[i] is the price of the asset i
  --assets-size-lots: list<float> # assetsSizeLots[i] is the number of shares by which it is required to purchase the asset i (usual values are 1 if the asset needs to be purchased share by share, 100 if the asset needs to be purchased by an integer multiple of 100 shares, and 1/1000000 - e.g. for Robinhood broker - if the asset can be purchased by fractional shares)
  --assets-weights: list<float> # assetsWeights[i] is the desired weight of the asset i in the portfolio, in percentage (can be null to indicate no specific desire)
  --maximum-assets-groups-weights: list<float> # maximumAssetsGroupsWeights[k] is the maximum desired weight of the assets group k in the portfolio, in percentage (can be null to indicate no specific desire); requires assetsGroups to be present
  portfolio_value: float # The monetary value of the portfolio
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/construction/investable"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsGroups, var: assets_groups}, {name: assetsGroupsWeights, var: assets_groups_weights}, {name: assetsMinimumNotionalValues, var: assets_minimum_notional_values}, {name: assetsMinimumPositions, var: assets_minimum_positions}, {name: assetsPrices, var: assets_prices}, {name: assetsSizeLots, var: assets_size_lots}, {name: assetsWeights, var: assets_weights}, {name: maximumAssetsGroupsWeights, var: maximum_assets_groups_weights}, {name: portfolioValue, var: portfolio_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_groups: $assets_groups, assets_groups_weights: $assets_groups_weights, assets_minimum_notional_values: $assets_minimum_notional_values, assets_minimum_positions: $assets_minimum_positions, assets_prices: $assets_prices, assets_size_lots: $assets_size_lots, assets_weights: $assets_weights, maximum_assets_groups_weights: $maximum_assets_groups_weights, portfolio_value: $portfolio_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mimicking Portfolio
#
# POST /portfolio/construction/mimicking
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-construction-mimicking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  benchmark_returns: list<float> # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the assetReturns arrays
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/construction/mimicking"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: benchmarkReturns, var: benchmark_returns}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, benchmark_returns: $benchmark_returns, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Random Portfolio
#
# POST /portfolio/construction/random
# Returns: record<portfolios: table<assetsWeights: list>>
export def "post-portfolio-construction-random" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --constraints: record # shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to construct (default: 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/construction/random"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: constraints, var: constraints}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, constraints: $constraints, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equal Risk Contributions Portfolio
#
# POST /portfolio/optimization/equal-risk-contributions
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-equal-risk-contributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --constraints: record # shape: {maximumAssetsWeights?: list<float>, minimumAssetsWeights?: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/equal-risk-contributions"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equal Sharpe Ratio Contributions Portfolio
#
# POST /portfolio/optimization/equal-sharpe-ratio-contributions
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-equal-sharpe-ratio-contributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/equal-sharpe-ratio-contributions"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equal Volatility Weighted Portfolio
#
# POST /portfolio/optimization/equal-volatility-weighted
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-equal-volatility-weighted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_volatilities: list<float> # assetsVolatilities[i] is the volatility of the asset i
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/equal-volatility-weighted"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsVolatilities, var: assets_volatilities}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_volatilities: $assets_volatilities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equal Weighted Portfolio
#
# POST /portfolio/optimization/equal-weighted
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-equal-weighted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/equal-weighted"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hierarchical Risk Parity Portfolio
#
# POST /portfolio/optimization/hierarchical-risk-parity
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-hierarchical-risk-parity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: singleLinkage)
  --clustering-ordering: string@clustering-ordering-completer # The order to impose on the hierarchical clustering tree leaves (default: r-hclust)
  --constraints: record # shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/hierarchical-risk-parity"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: clusteringMethod, var: clustering_method}, {name: clusteringOrdering, var: clustering_ordering}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, clustering_method: $clustering_method, clustering_ordering: $clustering_ordering, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hierarchical Clustering-Based Risk Parity Portfolio
#
# POST /portfolio/optimization/hierarchical-risk-parity/clustering-based
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-hierarchical-risk-parity-clustering-based" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --across-cluster-allocation-method: string@across-cluster-allocation-method-completer # The allocation method to use across clusters (default: equalWeighting)
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: wardLinkage)
  --clustering-ordering: string@clustering-ordering-completer # The order to impose on the hierarchical clustering tree leaves (default: r-hclust)
  --clusters: int # The number of clusters to use in the hierarchical clustering tree; if not provided, the number of clusters to use is computed using the gap statistic method, as described in the first reference
  --constraints: record # shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --within-cluster-allocation-method: string@within-cluster-allocation-method-completer # The allocation method to use within clusters (default: equalWeighting)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/hierarchical-risk-parity/clustering-based"
    body: {content_type: "application/json", kind: json, fields: [{name: acrossClusterAllocationMethod, var: across_cluster_allocation_method}, {name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: clusteringMethod, var: clustering_method}, {name: clusteringOrdering, var: clustering_ordering}, {name: clusters, var: clusters}, {name: constraints, var: constraints}, {name: withinClusterAllocationMethod, var: within_cluster_allocation_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    across_cluster_allocation_method: $across_cluster_allocation_method, assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, clustering_method: $clustering_method, clustering_ordering: $clustering_ordering, clusters: $clusters, constraints: $constraints, within_cluster_allocation_method: $within_cluster_allocation_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inverse Variance Weighted Portfolio
#
# POST /portfolio/optimization/inverse-variance-weighted
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-inverse-variance-weighted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_variances: list<float> # assetsVariances[i] is the variance of the asset i
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/inverse-variance-weighted"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsVariances, var: assets_variances}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_variances: $assets_variances
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inverse Volatility Weighted Portfolio
#
# POST /portfolio/optimization/inverse-volatility-weighted
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-inverse-volatility-weighted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_volatilities: list<float> # assetsVolatilities[i] is the volatility of the asset i
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/inverse-volatility-weighted"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsVolatilities, var: assets_volatilities}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_volatilities: $assets_volatilities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Market Capitalization Weighted Portfolio
#
# POST /portfolio/optimization/market-capitalization-weighted
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-market-capitalization-weighted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_market_capitalizations: list<float> # assetsMarketCapitalizations[i] is the market capitalization of the asset i
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/market-capitalization-weighted"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsMarketCapitalizations, var: assets_market_capitalizations}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_market_capitalizations: $assets_market_capitalizations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maximum Decorrelation Portfolio
#
# POST /portfolio/optimization/maximum-decorrelation
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-maximum-decorrelation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/maximum-decorrelation"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, assets_returns: $assets_returns, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-maximum-return" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/maximum-return"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Diversified Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return/diversified
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-maximum-return-diversified" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/maximum-return/diversified"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subset Resampling-Based Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return/subset-resampling-based
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-maximum-return-subset-resampling-based" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/maximum-return/subset-resampling-based"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}, {name: subsetPortfolios, var: subset_portfolios}, {name: subsetPortfoliosAggregationMethod, var: subset_portfolios_aggregation_method}, {name: subsetPortfoliosEnumerationMethod, var: subset_portfolios_enumeration_method}, {name: subsetSize, var: subset_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints, subset_portfolios: $subset_portfolios, subset_portfolios_aggregation_method: $subset_portfolios_aggregation_method, subset_portfolios_enumeration_method: $subset_portfolios_enumeration_method, subset_size: $subset_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-maximum-sharpe-ratio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/maximum-sharpe-ratio"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Diversified Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio/diversified
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-maximum-sharpe-ratio-diversified" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/maximum-sharpe-ratio/diversified"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subset Resampling-Based Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio/subset-resampling-based
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-maximum-sharpe-ratio-subset-resampling-based" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/maximum-sharpe-ratio/subset-resampling-based"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}, {name: riskFreeRate, var: risk_free_rate}, {name: subsetPortfolios, var: subset_portfolios}, {name: subsetPortfoliosAggregationMethod, var: subset_portfolios_aggregation_method}, {name: subsetPortfoliosEnumerationMethod, var: subset_portfolios_enumeration_method}, {name: subsetSize, var: subset_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints, risk_free_rate: $risk_free_rate, subset_portfolios: $subset_portfolios, subset_portfolios_aggregation_method: $subset_portfolios_aggregation_method, subset_portfolios_enumeration_method: $subset_portfolios_enumeration_method, subset_size: $subset_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maximum Ulcer Performance Index Portfolio
#
# POST /portfolio/optimization/maximum-ulcer-performance-index
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-maximum-ulcer-performance-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/maximum-ulcer-performance-index"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: constraints, var: constraints}, {name: riskFreeRate, var: risk_free_rate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, constraints: $constraints, risk_free_rate: $risk_free_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-mean-variance-efficient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/mean-variance-efficient"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Diversified Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient/diversified
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-mean-variance-efficient-diversified" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/mean-variance-efficient/diversified"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subset Resampling-Based Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient/subset-resampling-based
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-mean-variance-efficient-subset-resampling-based" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/mean-variance-efficient/subset-resampling-based"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}, {name: subsetPortfolios, var: subset_portfolios}, {name: subsetPortfoliosAggregationMethod, var: subset_portfolios_aggregation_method}, {name: subsetPortfoliosEnumerationMethod, var: subset_portfolios_enumeration_method}, {name: subsetSize, var: subset_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints, subset_portfolios: $subset_portfolios, subset_portfolios_aggregation_method: $subset_portfolios_aggregation_method, subset_portfolios_enumeration_method: $subset_portfolios_enumeration_method, subset_size: $subset_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Minimum Correlation Portfolio
#
# POST /portfolio/optimization/minimum-correlation
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-minimum-correlation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j; required if assetsReturns is not provided
  assets_volatilities: list<float> # assetsVariances[i] is the volatility of the asset i; required if assetsCorrelationMatrix is provided and assetsVariances is not provided
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/minimum-correlation"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCorrelationMatrix, var: assets_correlation_matrix}, {name: assetsVolatilities, var: assets_volatilities}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_correlation_matrix: $assets_correlation_matrix, assets_volatilities: $assets_volatilities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Minimum Ulcer Index Portfolio
#
# POST /portfolio/optimization/minimum-ulcer-index
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-minimum-ulcer-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/minimum-ulcer-index"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-minimum-variance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/minimum-variance"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Diversified Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance/diversified
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-minimum-variance-diversified" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/minimum-variance/diversified"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subset Resampling-Based Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance/subset-resampling-based
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-minimum-variance-subset-resampling-based" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/minimum-variance/subset-resampling-based"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: assetsReturns, var: assets_returns}, {name: constraints, var: constraints}, {name: subsetPortfolios, var: subset_portfolios}, {name: subsetPortfoliosAggregationMethod, var: subset_portfolios_aggregation_method}, {name: subsetPortfoliosEnumerationMethod, var: subset_portfolios_enumeration_method}, {name: subsetSize, var: subset_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, assets_returns: $assets_returns, constraints: $constraints, subset_portfolios: $subset_portfolios, subset_portfolios_aggregation_method: $subset_portfolios_aggregation_method, subset_portfolios_enumeration_method: $subset_portfolios_enumeration_method, subset_size: $subset_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Most Diversified Portfolio
#
# POST /portfolio/optimization/most-diversified
# Returns: record<assetsWeights: list<float>>
export def "post-portfolio-optimization-most-diversified" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/optimization/most-diversified"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: assetsCovarianceMatrix, var: assets_covariance_matrix}, {name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, assets_covariance_matrix: $assets_covariance_matrix, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Drift-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/drift-weight
# Returns: record<portfolios: table<portfolioValues: list>>
export def "post-portfolio-simulation-rebalancing-drift-weight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/simulation/rebalancing/drift-weight"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fixed-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/fixed-weight
# Returns: record<portfolios: table<portfolioValues: list>>
export def "post-portfolio-simulation-rebalancing-fixed-weight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/simulation/rebalancing/fixed-weight"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Random-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/random-weight
# Returns: record<portfolios: table<portfolioValues: list>>
export def "post-portfolio-simulation-rebalancing-random-weight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  --portfolios: int # The number of portfolios to simulate (default: 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/simulation/rebalancing/random-weight"
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: portfolios, var: portfolios}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    assets: $assets, portfolios: $portfolios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
