# Auto-generated client for Product Library API v1.0.0
# Source: https://api.apis.guru/v2/specs/izettle.com/products/1.0.0/openapi.json
# Auth: --token flag or $env.PRODUCT_LIBRARY_API_TOKEN

const CLIENT = {
  base_url: "https://products.izettle.com"
  token_env_var: "PRODUCT_LIBRARY_API_TOKEN"
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

def base-url-completer [] { ["https://products.izettle.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def taxation-mode-completer [] { ["EXCLUSIVE" "INCLUSIVE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-product-types: "record<categories: table<name: string, uuid: string>>"
    get-all-discounts: "table<amount: record<amount: int, currencyId: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, name: string, percentage: float, updated: string, updatedBy: string, uuid: string>"
    get-discount: "record<amount: record<amount: int, currencyId: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, name: string, percentage: float, updated: string, updatedBy: string, uuid: string>"
    get-all-image-urls: "record<imageUrls: list<string>>"
    get-latest-import-status: "record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string>"
    get-status-by-uuid: "record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string>"
    import-library-v2: "record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string>"
    get-library: "record<deletedDiscounts: list<string>, deletedProducts: list<string>, discounts: table<amount: record, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list, name: string, percentage: float, updated: string, updatedBy: string, uuid: string>, fromEventLogUuid: string, products: table<categories: list, category: record, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list, metadata: record, name: string, online: record, presentation: record, taxCode: string, taxExempt: bool, taxRates: list, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record, variants: list, vatPercentage: float>, untilEventLogUuid: string>"
    get-all-products-in-pos: "table<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record>, name: string, online: record<description: string, presentation: record, seo: record, shipping: record, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list>, variants: list<record>, vatPercentage: float>"
    create-product: "record<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record<external: bool, name: string>>, name: string, online: record<description: string, presentation: record<additionalImageUrls: list, displayImageUrl: string, mediaUrls: list>, seo: record<metaDescription: string, slug: string, title: string>, shipping: record<shippingPricingModel: string, weight: record, weightInGrams: int>, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list<record>>, variants: table<barcode: string, costPrice: record, description: string, name: string, options: list, presentation: record, price: record, sku: string, uuid: string, vatPercentage: float>, vatPercentage: float>"
    create-product-slug: "record<productName: string, slug: string>"
    get-all-options: "table<options: list<record>>"
    get-all-products-v2: "table<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record>, name: string, online: record<description: string, presentation: record, seo: record, shipping: record, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list>, variants: list<record>, vatPercentage: float>"
    count-all-products: "table<productCount: int>"
    get-product: "record<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record<external: bool, name: string>>, name: string, online: record<description: string, presentation: record<additionalImageUrls: list, displayImageUrl: string, mediaUrls: list>, seo: record<metaDescription: string, slug: string, title: string>, shipping: record<shippingPricingModel: string, weight: record, weightInGrams: int>, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list<record>>, variants: table<barcode: string, costPrice: record, description: string, name: string, options: list, presentation: record, price: record, sku: string, uuid: string, vatPercentage: float>, vatPercentage: float>"
    get-tax-rates: "table<taxRates: list<record>>"
    create-tax-rates: "record<taxRates: table<default: bool, label: string, percentage: float, uuid: string>>"
    get-product-count-for-all-taxes: "record<counts: table<count: int, taxRateUuid: string>>"
    get-tax-settings: "record<organizationUuid: string, taxationMode: string, taxationType: string>"
    set-taxation-mode: "record<organizationUuid: string, taxationMode: string, taxationType: string>"
    get-tax-rate: "record<default: bool, label: string, percentage: float, uuid: string>"
    update-tax-rate: "record<default: bool, label: string, percentage: float, uuid: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-product-types" "create-categories" "delete-category" "rename-category" "get-all-discounts" "create-discount" "delete-discount" "get-discount" "update-discount" "get-all-image-urls" "get-latest-import-status" "get-status-by-uuid" "import-library-v2" "get-library" "delete-products" "get-all-products-in-pos" "create-product" "create-product-slug" "get-all-options" "get-all-products-v2" "count-all-products" "update-product" "delete-product" "get-product" "get-tax-rates" "create-tax-rates" "get-product-count-for-all-taxes" "get-tax-settings" "set-taxation-mode" "delete-tax-rate" "get-tax-rate" "update-tax-rate" "commands"] | sort) } | get name | first)
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

# Retrieve all categories
#
# GET /organizations/{organizationUuid}/categories/v2
# Returns: record<categories: table<name: string, uuid: string>>
# operationId: getProductTypes
export def "get-product-types" [
  organization_uuid: string
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
    path: "/organizations/{organizationUuid}/categories/v2"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new category
#
# POST /organizations/{organizationUuid}/categories/v2
# operationId: createCategories
export def "create-categories" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list # item shape: {name: string, uuid: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/organizations/{organizationUuid}/categories/v2"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, categories: $categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a category
#
# DELETE /organizations/{organizationUuid}/categories/v2/{categoryUuid}
# operationId: deleteCategory
export def "delete-category" [
  organization_uuid: string
  category_uuid: string
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
    path: "/organizations/{organizationUuid}/categories/v2/{categoryUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: categoryUuid, var: category_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, category_uuid: $category_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a category
#
# PATCH /organizations/{organizationUuid}/categories/v2/{categoryUuid}
# operationId: renameCategory
export def "rename-category" [
  organization_uuid: string
  category_uuid: string
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
]: any -> any {
  $in | http-request {
    method: patch
    path: "/organizations/{organizationUuid}/categories/v2/{categoryUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: categoryUuid, var: category_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, category_uuid: $category_uuid, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all discounts
#
# GET /organizations/{organizationUuid}/discounts
# Returns: table<amount: record<amount: int, currencyId: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, name: string, percentage: float, updated: string, updatedBy: string, uuid: string>
# operationId: getAllDiscounts
export def "get-all-discounts" [
  organization_uuid: string
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
    path: "/organizations/{organizationUuid}/discounts"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a discount
#
# POST /organizations/{organizationUuid}/discounts
# operationId: createDiscount
export def "create-discount" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: record # shape: {amount: int, ... (1 more fields)}
  --description: string
  --external-reference: string
  --image-lookup-keys: list<string>
  --name: string
  --percentage: float
  uuid: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/organizations/{organizationUuid}/discounts"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: description, var: description}, {name: externalReference, var: external_reference}, {name: imageLookupKeys, var: image_lookup_keys}, {name: name, var: name}, {name: percentage, var: percentage}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, amount: $amount, description: $description, external_reference: $external_reference, image_lookup_keys: $image_lookup_keys, name: $name, percentage: $percentage, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a single discount
#
# DELETE /organizations/{organizationUuid}/discounts/{discountUuid}
# operationId: deleteDiscount
export def "delete-discount" [
  organization_uuid: string
  discount_uuid: string
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
    path: "/organizations/{organizationUuid}/discounts/{discountUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: discountUuid, var: discount_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, discount_uuid: $discount_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single discount
#
# GET /organizations/{organizationUuid}/discounts/{discountUuid}
# Returns: record<amount: record<amount: int, currencyId: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, name: string, percentage: float, updated: string, updatedBy: string, uuid: string>
# operationId: getDiscount
export def "get-discount" [
  organization_uuid: string
  discount_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationUuid}/discounts/{discountUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: discountUuid, var: discount_uuid}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, discount_uuid: $discount_uuid, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a single discount
#
# PUT /organizations/{organizationUuid}/discounts/{discountUuid}
# operationId: updateDiscount
export def "update-discount" [
  organization_uuid: string
  discount_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string
  --amount: record # shape: {amount: int, ... (1 more fields)}
  --description: string
  --external-reference: string
  --image-lookup-keys: list<string>
  --name: string
  --percentage: float
  uuid: string # format: uuid
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{organizationUuid}/discounts/{discountUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: discountUuid, var: discount_uuid}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: description, var: description}, {name: externalReference, var: external_reference}, {name: imageLookupKeys, var: image_lookup_keys}, {name: name, var: name}, {name: percentage, var: percentage}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, discount_uuid: $discount_uuid, if_match: $if_match, amount: $amount, description: $description, external_reference: $external_reference, image_lookup_keys: $image_lookup_keys, name: $name, percentage: $percentage, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all library item images
#
# GET /organizations/{organizationUuid}/images
# Returns: record<imageUrls: list<string>>
# operationId: getAllImageUrls
export def "get-all-image-urls" [
  organization_uuid: string
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
    path: "/organizations/{organizationUuid}/images"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status for latest import
#
# GET /organizations/{organizationUuid}/import/status
# Returns: record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string>
# operationId: getLatestImportStatus
export def "get-latest-import-status" [
  organization_uuid: string
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
    path: "/organizations/{organizationUuid}/import/status"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status for an import
#
# GET /organizations/{organizationUuid}/import/status/{importUuid}
# Returns: record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string>
# operationId: getStatusByUuid
export def "get-status-by-uuid" [
  organization_uuid: string
  import_uuid: string
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
    path: "/organizations/{organizationUuid}/import/status/{importUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: importUuid, var: import_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, import_uuid: $import_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import library items
#
# POST /organizations/{organizationUuid}/import/v2
# Returns: record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string>
# operationId: importLibraryV2
export def "import-library-v2" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  products: list # item shape: {categories?: list<string>, category?: record, description?: string, externalReference?: string, imageLookupKeys?: list<string>, metadata?: record, name: string, online?: record, presentation?: record, taxCode?: string, taxExempt?: bool, taxRates?: list<string>, unitName?: string, uuid: string, variantOptionDefinitions?: record, variants?: list, vatPercentage?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationUuid}/import/v2"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: products, var: products}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, products: $products
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the entire library
#
# GET /organizations/{organizationUuid}/library
# Returns: record<deletedDiscounts: list<string>, deletedProducts: list<string>, discounts: table<amount: record, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list, name: string, percentage: float, updated: string, updatedBy: string, uuid: string>, fromEventLogUuid: string, products: table<categories: list, category: record, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list, metadata: record, name: string, online: record, presentation: record, taxCode: string, taxExempt: bool, taxRates: list, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record, variants: list, vatPercentage: float>, untilEventLogUuid: string>
# operationId: getLibrary
export def "get-library" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-log-uuid: string # format: uuid
  --limit: int # format: int32, default: 500
  --offset: string
  --all: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationUuid}/library"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    query: [{name: eventLogUuid, var: event_log_uuid}, {name: limit, var: limit}, {name: offset, var: offset}, {name: all, var: all}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, event_log_uuid: $event_log_uuid, limit: $limit, offset: $offset, all: $all
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a list of products
#
# DELETE /organizations/{organizationUuid}/products
# operationId: deleteProducts
export def "delete-products" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uuid: list<string> # List of product UUIDs to be deleted (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizations/{organizationUuid}/products"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    query: [{name: uuid, var: uuid, style: multi, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all products visible in POS
#
# GET /organizations/{organizationUuid}/products
# Returns: table<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record>, name: string, online: record<description: string, presentation: record, seo: record, shipping: record, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list>, variants: list<record>, vatPercentage: float>
# operationId: getAllProductsInPos
export def "get-all-products-in-pos" [
  organization_uuid: string
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
    path: "/organizations/{organizationUuid}/products"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new product
#
# POST /organizations/{organizationUuid}/products
# Returns: record<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record<external: bool, name: string>>, name: string, online: record<description: string, presentation: record<additionalImageUrls: list, displayImageUrl: string, mediaUrls: list>, seo: record<metaDescription: string, slug: string, title: string>, shipping: record<shippingPricingModel: string, weight: record, weightInGrams: int>, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list<record>>, variants: table<barcode: string, costPrice: record, description: string, name: string, options: list, presentation: record, price: record, sku: string, uuid: string, vatPercentage: float>, vatPercentage: float>
# operationId: createProduct
export def "create-product" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-entity: oneof<nothing, bool> # default: false
  --categories: list<string>
  --category: record # shape: {name: string, uuid: string}
  --create-with-default-tax: oneof<nothing, bool>
  --description: string
  --external-reference: string
  --image-lookup-keys: list<string>
  --metadata: record # shape: {inPos: bool, source?: record}
  name: string
  --online: record # shape: {description?: string, presentation?: record, seo?: record, shipping?: record, status: "ACTIVE"|"HIDDEN", title?: string}
  --presentation: record # shape: {backgroundColor?: string, imageUrl?: string, textColor?: string}
  --tax-code: string
  --tax-exempt: oneof<nothing, bool>
  --tax-rates: list<string>
  --unit-name: string
  uuid: string # format: uuid
  --variant-option-definitions: record # shape: {definitions: list}
  --variants: list # item shape: {barcode?: string, costPrice?: record, description?: string, name?: string, options?: list, presentation?: record, price?: record, sku?: string, uuid: string, vatPercentage?: float}
  --vat-percentage: float
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationUuid}/products"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    query: [{name: returnEntity, var: return_entity}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: category, var: category}, {name: createWithDefaultTax, var: create_with_default_tax}, {name: description, var: description}, {name: externalReference, var: external_reference}, {name: imageLookupKeys, var: image_lookup_keys}, {name: metadata, var: metadata}, {name: name, var: name}, {name: online, var: online}, {name: presentation, var: presentation}, {name: taxCode, var: tax_code}, {name: taxExempt, var: tax_exempt}, {name: taxRates, var: tax_rates}, {name: unitName, var: unit_name}, {name: uuid, var: uuid}, {name: variantOptionDefinitions, var: variant_option_definitions}, {name: variants, var: variants}, {name: vatPercentage, var: vat_percentage}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, return_entity: $return_entity, categories: $categories, category: $category, create_with_default_tax: $create_with_default_tax, description: $description, external_reference: $external_reference, image_lookup_keys: $image_lookup_keys, metadata: $metadata, name: $name, online: $online, presentation: $presentation, tax_code: $tax_code, tax_exempt: $tax_exempt, tax_rates: $tax_rates, unit_name: $unit_name, uuid: $uuid, variant_option_definitions: $variant_option_definitions, variants: $variants, vat_percentage: $vat_percentage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a product identifier
#
# POST /organizations/{organizationUuid}/products/online/slug
# Returns: record<productName: string, slug: string>
# operationId: createProductSlug
export def "create-product-slug" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  product_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationUuid}/products/online/slug"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: productName, var: product_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, product_name: $product_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an aggregate of active Options in the library
#
# GET /organizations/{organizationUuid}/products/options
# Returns: table<options: list<record>>
# operationId: getAllOptions
export def "get-all-options" [
  organization_uuid: string
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
    path: "/organizations/{organizationUuid}/products/options"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all products visible in POS – v2
#
# GET /organizations/{organizationUuid}/products/v2
# Returns: table<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record>, name: string, online: record<description: string, presentation: record, seo: record, shipping: record, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list>, variants: list<record>, vatPercentage: float>
# operationId: getAllProductsV2
export def "get-all-products-v2" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: oneof<nothing, bool> # If true, sorts response by created date
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationUuid}/products/v2"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    query: [{name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the count of existing products
#
# GET /organizations/{organizationUuid}/products/v2/count
# Returns: table<productCount: int>
# operationId: countAllProducts
export def "count-all-products" [
  organization_uuid: string
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
    path: "/organizations/{organizationUuid}/products/v2/count"
    path_params: [{name: organizationUuid, var: organization_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_uuid: $organization_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a single product
#
# PUT /organizations/{organizationUuid}/products/v2/{productUuid}
# operationId: updateProduct
export def "update-product" [
  organization_uuid: string
  product_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string
  --categories: list<string>
  --category: record # shape: {name: string, uuid: string}
  --description: string
  --external-reference: string
  --image-lookup-keys: list<string>
  --metadata: record # shape: {inPos: bool, source?: record}
  name: string
  --online: record # shape: {description?: string, presentation?: record, seo?: record, shipping?: record, status: "ACTIVE"|"HIDDEN", title?: string}
  --presentation: record # shape: {backgroundColor?: string, imageUrl?: string, textColor?: string}
  --tax-code: string
  --tax-exempt: oneof<nothing, bool>
  --tax-rates: list<string>
  --unit-name: string
  uuid: string # format: uuid
  --variant-option-definitions: record # shape: {definitions: list}
  --variants: list # item shape: {barcode?: string, costPrice?: record, description?: string, name?: string, options?: list, presentation?: record, price?: record, sku?: string, uuid: string, vatPercentage?: float}
  --vat-percentage: float
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{organizationUuid}/products/v2/{productUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: productUuid, var: product_uuid}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: category, var: category}, {name: description, var: description}, {name: externalReference, var: external_reference}, {name: imageLookupKeys, var: image_lookup_keys}, {name: metadata, var: metadata}, {name: name, var: name}, {name: online, var: online}, {name: presentation, var: presentation}, {name: taxCode, var: tax_code}, {name: taxExempt, var: tax_exempt}, {name: taxRates, var: tax_rates}, {name: unitName, var: unit_name}, {name: uuid, var: uuid}, {name: variantOptionDefinitions, var: variant_option_definitions}, {name: variants, var: variants}, {name: vatPercentage, var: vat_percentage}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, product_uuid: $product_uuid, if_match: $if_match, categories: $categories, category: $category, description: $description, external_reference: $external_reference, image_lookup_keys: $image_lookup_keys, metadata: $metadata, name: $name, online: $online, presentation: $presentation, tax_code: $tax_code, tax_exempt: $tax_exempt, tax_rates: $tax_rates, unit_name: $unit_name, uuid: $uuid, variant_option_definitions: $variant_option_definitions, variants: $variants, vat_percentage: $vat_percentage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a single product
#
# DELETE /organizations/{organizationUuid}/products/{productUuid}
# operationId: deleteProduct
export def "delete-product" [
  organization_uuid: string
  product_uuid: string
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
    path: "/organizations/{organizationUuid}/products/{productUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: productUuid, var: product_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, product_uuid: $product_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single product
#
# GET /organizations/{organizationUuid}/products/{productUuid}
# Returns: record<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record<external: bool, name: string>>, name: string, online: record<description: string, presentation: record<additionalImageUrls: list, displayImageUrl: string, mediaUrls: list>, seo: record<metaDescription: string, slug: string, title: string>, shipping: record<shippingPricingModel: string, weight: record, weightInGrams: int>, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list<record>>, variants: table<barcode: string, costPrice: record, description: string, name: string, options: list, presentation: record, price: record, sku: string, uuid: string, vatPercentage: float>, vatPercentage: float>
# operationId: getProduct
export def "get-product" [
  organization_uuid: string
  product_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationUuid}/products/{productUuid}"
    path_params: [{name: organizationUuid, var: organization_uuid}, {name: productUuid, var: product_uuid}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    organization_uuid: $organization_uuid, product_uuid: $product_uuid, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all available tax rates
#
# GET /v1/taxes
# Returns: table<taxRates: list<record>>
# operationId: getTaxRates
export def "get-tax-rates" [
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
    path: "/v1/taxes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new tax rates
#
# POST /v1/taxes
# Returns: record<taxRates: table<default: bool, label: string, percentage: float, uuid: string>>
# operationId: createTaxRates
export def "create-tax-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tax_rates: list # item shape: {default?: bool, label: string, percentage?: float, uuid: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/taxes"
    body: {content_type: "application/json", kind: json, fields: [{name: taxRates, var: tax_rates}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tax_rates: $tax_rates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tax rates and a count of products associated with each
#
# GET /v1/taxes/count
# Returns: record<counts: table<count: int, taxRateUuid: string>>
# operationId: getProductCountForAllTaxes
export def "get-product-count-for-all-taxes" [
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
    path: "/v1/taxes/count"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the organization tax settings
#
# GET /v1/taxes/settings
# Returns: record<organizationUuid: string, taxationMode: string, taxationType: string>
# operationId: getTaxSettings
export def "get-tax-settings" [
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
    path: "/v1/taxes/settings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the organization tax settings
#
# PUT /v1/taxes/settings
# Returns: record<organizationUuid: string, taxationMode: string, taxationType: string>
# operationId: setTaxationMode
export def "set-taxation-mode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  taxation_mode: string@taxation-mode-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/taxes/settings"
    body: {content_type: "application/json", kind: json, fields: [{name: taxationMode, var: taxation_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    taxation_mode: $taxation_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a single tax rate
#
# DELETE /v1/taxes/{taxRateUuid}
# operationId: deleteTaxRate
export def "delete-tax-rate" [
  tax_rate_uuid: string
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
    path: "/v1/taxes/{taxRateUuid}"
    path_params: [{name: taxRateUuid, var: tax_rate_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tax_rate_uuid: $tax_rate_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single tax rate
#
# GET /v1/taxes/{taxRateUuid}
# Returns: record<default: bool, label: string, percentage: float, uuid: string>
# operationId: getTaxRate
export def "get-tax-rate" [
  tax_rate_uuid: string
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
    path: "/v1/taxes/{taxRateUuid}"
    path_params: [{name: taxRateUuid, var: tax_rate_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tax_rate_uuid: $tax_rate_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a single tax rate
#
# PUT /v1/taxes/{taxRateUuid}
# Returns: record<default: bool, label: string, percentage: float, uuid: string>
# operationId: updateTaxRate
export def "update-tax-rate" [
  tax_rate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool>
  --label: string
  --percentage: float
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/taxes/{taxRateUuid}"
    path_params: [{name: taxRateUuid, var: tax_rate_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: label, var: label}, {name: percentage, var: percentage}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tax_rate_uuid: $tax_rate_uuid, default: $default, label: $label, percentage: $percentage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
