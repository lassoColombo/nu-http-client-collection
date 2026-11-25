# Auto-generated client for Qualpay Payment Gateway API v1.7.0
# Source: https://api.apis.guru/v2/specs/qualpay.com/1.7.0/swagger.json
# Auth: --token flag or $env.QUALPAY_PAYMENT_GATEWAY_API_TOKEN

const CLIENT = {
  base_url: "https://api-test.qualpay.com/pg"
  token_env_var: "QUALPAY_PAYMENT_GATEWAY_API_TOKEN"
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

def base-url-completer [] { ["https://api-test.qualpay.com/pg"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-card-type-information: "record<funding_source: string, ind_comm_level2: string, ind_comm_level3: string, issuer_country: string, pg_id: string, rcode: string, rmsg: string>"
    authorization: "record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>"
    batch-close: "record<batch_info: string, echo_fields: string, pg_id: string, rcode: string, rmsg: string>"
    capture: "record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>"
    credit: "record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>"
    send-receipt: "record<pg_id: string, rcode: string, rmsg: string>"
    expire: "record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>"
    force: "record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>"
    recharge: "record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>"
    refund: "record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>"
    sale: "record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>"
    tokenize: "record<card_id: string, card_number: string, echo_fields: string, pg_id: string, rcode: string, rmsg: string>"
    verify: "record<auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, card_number: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>"
    void: "record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-card-type-information" "authorization" "batch-close" "capture" "credit" "send-receipt" "expire" "force" "recharge" "refund" "sale" "tokenize" "verify" "void" "commands"] | sort) } | get name | first)
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

# Get Card type Information for Visa, Mastercard, and Discover
#
# POST /ardef
# Returns: record<funding_source: string, ind_comm_level2: string, ind_comm_level3: string, issuer_country: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Get Card Type Information 
export def "get-card-type-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number. (e.g. 4111111111111111)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ardef"
    body: {content_type: "application/json", kind: json, fields: [{name: card_number, var: card_number}, {name: merchant_id, var: merchant_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    card_number: $card_number, merchant_id: $merchant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorize Transaction
#
# POST /auth
# Returns: record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Authorization
export def "authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # Format: Variable length, up to 12,2 NDescription: Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.Conditional Requirement: Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # Format: Fixed length, 6 ANDescription: This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.Conditional Requirement: This field is required in force request type. (e.g. 620376)
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 ANDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # Format: Fixed length, 28 ANDescription: Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # Format: Variable lengthDescription: [Deprecated use email_address] Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # Format: Variable length, up to 32 ANDescription: Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. JOECUSTOMER_12)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # Format: Variable length, up to 21 ANDescription: When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # Format: Fixed length, 9 ANDescription: For use by merchants using negative option marketing. This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: END DSCNTEND OFFEREND PROMOEND TRIAL (e.g. END PROMO)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --duplicate-seconds: int # Format: Variable length, up to 5 NDescription: Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # Default: falseDescription: When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # Format: Variable length, up to 36 ANDescription: Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --fbo-id: int # Format: Variable length, up to 16 NDescription: For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # Format: Variable lengthDescription: JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: quantity (7N) description (26AN) unit_of_measure (12AN) product_code (12AN) - cannot be all zeroes debit_credit_ind (1 AN) unit_cost (12,2N) Optional subfields: type_of_supply (2AN) - visa onlycommodity_code - visa only(12AN)Conditional Requirement: This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # Format: Variable length, up to 32 ANDescription: Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # Format: Fixed length, 1 ANDescription: MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --partial-auth: oneof<nothing, bool> # Default: falseDescription: This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request on a different card is needed to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # Format: Fixed length, 32 ANDescription: PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # Format: Variable length, up to 25 ANDescription: Purchase Identifier (also referred to as the invoice number generated by the merchant).Conditional Requirement: This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # Format: Variable length, up to 10 NDescription: Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --tran-currency: int # Format: Fixed length, 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # Format: Fixed length, 28 ANDescription: Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth"
    body: {content_type: "application/json", kind: json, fields: [{name: amt_convenience_fee, var: amt_convenience_fee}, {name: amt_fbo, var: amt_fbo}, {name: amt_tax, var: amt_tax}, {name: amt_tran, var: amt_tran}, {name: amt_tran_fee, var: amt_tran_fee}, {name: auth_code, var: auth_code}, {name: avs_address, var: avs_address}, {name: avs_zip, var: avs_zip}, {name: card_id, var: card_id}, {name: card_number, var: card_number}, {name: card_swipe, var: card_swipe}, {name: cardholder_name, var: cardholder_name}, {name: cavv_3ds, var: cavv_3ds}, {name: client_ip, var: client_ip}, {name: customer, var: customer}, {name: customer_code, var: customer_code}, {name: customer_email, var: customer_email}, {name: customer_id, var: customer_id}, {name: cvv2, var: cvv2}, {name: dba_name, var: dba_name}, {name: dba_suffix, var: dba_suffix}, {name: dda_number, var: dda_number}, {name: developer_id, var: developer_id}, {name: duplicate_seconds, var: duplicate_seconds}, {name: echo_fields, var: echo_fields}, {name: email_address, var: email_address}, {name: email_receipt, var: email_receipt}, {name: emv_tran_id, var: emv_tran_id}, {name: exp_date, var: exp_date}, {name: fbo_id, var: fbo_id}, {name: line_items, var: line_items}, {name: loc_id, var: loc_id}, {name: mc_ucaf_data, var: mc_ucaf_data}, {name: mc_ucaf_ind, var: mc_ucaf_ind}, {name: merch_ref_num, var: merch_ref_num}, {name: merchant_id, var: merchant_id}, {name: moto_ecomm_ind, var: moto_ecomm_ind}, {name: partial_auth, var: partial_auth}, {name: payload_apple_pay, var: payload_apple_pay}, {name: payload_google_pay, var: payload_google_pay}, {name: pg_id, var: pg_id}, {name: profile_id, var: profile_id}, {name: purchase_id, var: purchase_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: subscription_id, var: subscription_id}, {name: tokenize, var: tokenize}, {name: tr_number, var: tr_number}, {name: tran_currency, var: tran_currency}, {name: type_id, var: type_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}, {name: xid_3ds, var: xid_3ds}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    amt_convenience_fee: $amt_convenience_fee, amt_fbo: $amt_fbo, amt_tax: $amt_tax, amt_tran: $amt_tran, amt_tran_fee: $amt_tran_fee, auth_code: $auth_code, avs_address: $avs_address, avs_zip: $avs_zip, card_id: $card_id, card_number: $card_number, card_swipe: $card_swipe, cardholder_name: $cardholder_name, cavv_3ds: $cavv_3ds, client_ip: $client_ip, customer: $customer, customer_code: $customer_code, customer_email: $customer_email, customer_id: $customer_id, cvv2: $cvv2, dba_name: $dba_name, dba_suffix: $dba_suffix, dda_number: $dda_number, developer_id: $developer_id, duplicate_seconds: $duplicate_seconds, echo_fields: $echo_fields, email_address: $email_address, email_receipt: $email_receipt, emv_tran_id: $emv_tran_id, exp_date: $exp_date, fbo_id: $fbo_id, line_items: $line_items, loc_id: $loc_id, mc_ucaf_data: $mc_ucaf_data, mc_ucaf_ind: $mc_ucaf_ind, merch_ref_num: $merch_ref_num, merchant_id: $merchant_id, moto_ecomm_ind: $moto_ecomm_ind, partial_auth: $partial_auth, payload_apple_pay: $payload_apple_pay, payload_google_pay: $payload_google_pay, pg_id: $pg_id, profile_id: $profile_id, purchase_id: $purchase_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, subscription_id: $subscription_id, tokenize: $tokenize, tr_number: $tr_number, tran_currency: $tran_currency, type_id: $type_id, user_id: $user_id, vendor_id: $vendor_id, xid_3ds: $xid_3ds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close Batch
#
# POST /batchClose
# Returns: record<batch_info: string, echo_fields: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Batch Close
export def "batch-close" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --tran-currency: int # Format: Variable length, up to 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/batchClose"
    body: {content_type: "application/json", kind: json, fields: [{name: developer_id, var: developer_id}, {name: echo_fields, var: echo_fields}, {name: loc_id, var: loc_id}, {name: merchant_id, var: merchant_id}, {name: profile_id, var: profile_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: tran_currency, var: tran_currency}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    developer_id: $developer_id, echo_fields: $echo_fields, loc_id: $loc_id, merchant_id: $merchant_id, profile_id: $profile_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, tran_currency: $tran_currency, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Capture an Authorized Transaction
#
# POST /capture/{pgIdOrig}
# Returns: record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Capture
export def "capture" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # Format: Variable length, up to 12,2 NDescription: Total amount to capture. The amount must be less than or equal to the authorized amount. (format: double, e.g. 1193.5)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/capture/{pgIdOrig}"
    path_params: [{name: pgIdOrig, var: pg_id_orig}]
    body: {content_type: "application/json", kind: json, fields: [{name: amt_tran, var: amt_tran}, {name: developer_id, var: developer_id}, {name: echo_fields, var: echo_fields}, {name: loc_id, var: loc_id}, {name: merchant_id, var: merchant_id}, {name: profile_id, var: profile_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    pg_id_orig: $pg_id_orig, amt_tran: $amt_tran, developer_id: $developer_id, echo_fields: $echo_fields, loc_id: $loc_id, merchant_id: $merchant_id, profile_id: $profile_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, user_id: $user_id, vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issue Credit to Cardholder
#
# POST /credit
# Returns: record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Credit
export def "credit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # Format: Variable length, up to 12,2 NDescription: Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.Conditional Requirement: Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # Format: Fixed length, 6 ANDescription: This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.Conditional Requirement: This field is required in force request type. (e.g. 620376)
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 ANDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # Format: Fixed length, 28 ANDescription: Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # Format: Variable lengthDescription: [Deprecated use email_address] Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # Format: Variable length, up to 32 ANDescription: Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. JOECUSTOMER_12)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # Format: Variable length, up to 21 ANDescription: When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # Format: Fixed length, 9 ANDescription: For use by merchants using negative option marketing. This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: END DSCNTEND OFFEREND PROMOEND TRIAL (e.g. END PROMO)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --duplicate-seconds: int # Format: Variable length, up to 5 NDescription: Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # Default: falseDescription: When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # Format: Variable length, up to 36 ANDescription: Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --fbo-id: int # Format: Variable length, up to 16 NDescription: For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # Format: Variable lengthDescription: JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: quantity (7N) description (26AN) unit_of_measure (12AN) product_code (12AN) - cannot be all zeroes debit_credit_ind (1 AN) unit_cost (12,2N) Optional subfields: type_of_supply (2AN) - visa onlycommodity_code - visa only(12AN)Conditional Requirement: This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # Format: Variable length, up to 32 ANDescription: Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # Format: Fixed length, 1 ANDescription: MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --partial-auth: oneof<nothing, bool> # Default: falseDescription: This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request on a different card is needed to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # Format: Fixed length, 32 ANDescription: PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # Format: Variable length, up to 25 ANDescription: Purchase Identifier (also referred to as the invoice number generated by the merchant).Conditional Requirement: This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # Format: Variable length, up to 10 NDescription: Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --tran-currency: int # Format: Fixed length, 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # Format: Fixed length, 28 ANDescription: Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/credit"
    body: {content_type: "application/json", kind: json, fields: [{name: amt_convenience_fee, var: amt_convenience_fee}, {name: amt_fbo, var: amt_fbo}, {name: amt_tax, var: amt_tax}, {name: amt_tran, var: amt_tran}, {name: amt_tran_fee, var: amt_tran_fee}, {name: auth_code, var: auth_code}, {name: avs_address, var: avs_address}, {name: avs_zip, var: avs_zip}, {name: card_id, var: card_id}, {name: card_number, var: card_number}, {name: card_swipe, var: card_swipe}, {name: cardholder_name, var: cardholder_name}, {name: cavv_3ds, var: cavv_3ds}, {name: client_ip, var: client_ip}, {name: customer, var: customer}, {name: customer_code, var: customer_code}, {name: customer_email, var: customer_email}, {name: customer_id, var: customer_id}, {name: cvv2, var: cvv2}, {name: dba_name, var: dba_name}, {name: dba_suffix, var: dba_suffix}, {name: dda_number, var: dda_number}, {name: developer_id, var: developer_id}, {name: duplicate_seconds, var: duplicate_seconds}, {name: echo_fields, var: echo_fields}, {name: email_address, var: email_address}, {name: email_receipt, var: email_receipt}, {name: emv_tran_id, var: emv_tran_id}, {name: exp_date, var: exp_date}, {name: fbo_id, var: fbo_id}, {name: line_items, var: line_items}, {name: loc_id, var: loc_id}, {name: mc_ucaf_data, var: mc_ucaf_data}, {name: mc_ucaf_ind, var: mc_ucaf_ind}, {name: merch_ref_num, var: merch_ref_num}, {name: merchant_id, var: merchant_id}, {name: moto_ecomm_ind, var: moto_ecomm_ind}, {name: partial_auth, var: partial_auth}, {name: payload_apple_pay, var: payload_apple_pay}, {name: payload_google_pay, var: payload_google_pay}, {name: pg_id, var: pg_id}, {name: profile_id, var: profile_id}, {name: purchase_id, var: purchase_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: subscription_id, var: subscription_id}, {name: tokenize, var: tokenize}, {name: tr_number, var: tr_number}, {name: tran_currency, var: tran_currency}, {name: type_id, var: type_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}, {name: xid_3ds, var: xid_3ds}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    amt_convenience_fee: $amt_convenience_fee, amt_fbo: $amt_fbo, amt_tax: $amt_tax, amt_tran: $amt_tran, amt_tran_fee: $amt_tran_fee, auth_code: $auth_code, avs_address: $avs_address, avs_zip: $avs_zip, card_id: $card_id, card_number: $card_number, card_swipe: $card_swipe, cardholder_name: $cardholder_name, cavv_3ds: $cavv_3ds, client_ip: $client_ip, customer: $customer, customer_code: $customer_code, customer_email: $customer_email, customer_id: $customer_id, cvv2: $cvv2, dba_name: $dba_name, dba_suffix: $dba_suffix, dda_number: $dda_number, developer_id: $developer_id, duplicate_seconds: $duplicate_seconds, echo_fields: $echo_fields, email_address: $email_address, email_receipt: $email_receipt, emv_tran_id: $emv_tran_id, exp_date: $exp_date, fbo_id: $fbo_id, line_items: $line_items, loc_id: $loc_id, mc_ucaf_data: $mc_ucaf_data, mc_ucaf_ind: $mc_ucaf_ind, merch_ref_num: $merch_ref_num, merchant_id: $merchant_id, moto_ecomm_ind: $moto_ecomm_ind, partial_auth: $partial_auth, payload_apple_pay: $payload_apple_pay, payload_google_pay: $payload_google_pay, pg_id: $pg_id, profile_id: $profile_id, purchase_id: $purchase_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, subscription_id: $subscription_id, tokenize: $tokenize, tr_number: $tr_number, tran_currency: $tran_currency, type_id: $type_id, user_id: $user_id, vendor_id: $vendor_id, xid_3ds: $xid_3ds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send Transaction Receipt Email
#
# POST /emailReceipt/{pgId}
# Returns: record<pg_id: string, rcode: string, rmsg: string>
# operationId: Send Receipt
export def "send-receipt" [
  pg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  email_address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --logo-url: string # ANDescription: A link to the logo image that will be included in the transaction receipt. (e.g. https://app.qualpay.com/shared/images/qp-icon.png)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this email receipt request applies. (format: int64, e.g. 212100026512)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/emailReceipt/{pgId}"
    path_params: [{name: pgId, var: pg_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: developer_id, var: developer_id}, {name: email_address, var: email_address}, {name: logo_url, var: logo_url}, {name: merchant_id, var: merchant_id}, {name: vendor_id, var: vendor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    pg_id: $pg_id, developer_id: $developer_id, email_address: $email_address, logo_url: $logo_url, merchant_id: $merchant_id, vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Expire Token
#
# POST /expireToken
# Returns: record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Expire
export def "expire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this expire token request applies. (format: int64, e.g. 212100026512)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/expireToken"
    body: {content_type: "application/json", kind: json, fields: [{name: card_id, var: card_id}, {name: developer_id, var: developer_id}, {name: echo_fields, var: echo_fields}, {name: loc_id, var: loc_id}, {name: merchant_id, var: merchant_id}, {name: profile_id, var: profile_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    card_id: $card_id, developer_id: $developer_id, echo_fields: $echo_fields, loc_id: $loc_id, merchant_id: $merchant_id, profile_id: $profile_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, user_id: $user_id, vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Force Transaction Approval
#
# POST /force
# Returns: record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Force
export def "force" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # Format: Variable length, up to 12,2 NDescription: Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.Conditional Requirement: Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # Format: Fixed length, 6 ANDescription: This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.Conditional Requirement: This field is required in force request type. (e.g. 620376)
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 ANDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # Format: Fixed length, 28 ANDescription: Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # Format: Variable lengthDescription: [Deprecated use email_address] Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # Format: Variable length, up to 32 ANDescription: Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. JOECUSTOMER_12)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # Format: Variable length, up to 21 ANDescription: When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # Format: Fixed length, 9 ANDescription: For use by merchants using negative option marketing. This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: END DSCNTEND OFFEREND PROMOEND TRIAL (e.g. END PROMO)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --duplicate-seconds: int # Format: Variable length, up to 5 NDescription: Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # Default: falseDescription: When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # Format: Variable length, up to 36 ANDescription: Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --fbo-id: int # Format: Variable length, up to 16 NDescription: For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # Format: Variable lengthDescription: JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: quantity (7N) description (26AN) unit_of_measure (12AN) product_code (12AN) - cannot be all zeroes debit_credit_ind (1 AN) unit_cost (12,2N) Optional subfields: type_of_supply (2AN) - visa onlycommodity_code - visa only(12AN)Conditional Requirement: This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # Format: Variable length, up to 32 ANDescription: Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # Format: Fixed length, 1 ANDescription: MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --partial-auth: oneof<nothing, bool> # Default: falseDescription: This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request on a different card is needed to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # Format: Fixed length, 32 ANDescription: PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # Format: Variable length, up to 25 ANDescription: Purchase Identifier (also referred to as the invoice number generated by the merchant).Conditional Requirement: This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # Format: Variable length, up to 10 NDescription: Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --tran-currency: int # Format: Fixed length, 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # Format: Fixed length, 28 ANDescription: Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/force"
    body: {content_type: "application/json", kind: json, fields: [{name: amt_convenience_fee, var: amt_convenience_fee}, {name: amt_fbo, var: amt_fbo}, {name: amt_tax, var: amt_tax}, {name: amt_tran, var: amt_tran}, {name: amt_tran_fee, var: amt_tran_fee}, {name: auth_code, var: auth_code}, {name: avs_address, var: avs_address}, {name: avs_zip, var: avs_zip}, {name: card_id, var: card_id}, {name: card_number, var: card_number}, {name: card_swipe, var: card_swipe}, {name: cardholder_name, var: cardholder_name}, {name: cavv_3ds, var: cavv_3ds}, {name: client_ip, var: client_ip}, {name: customer, var: customer}, {name: customer_code, var: customer_code}, {name: customer_email, var: customer_email}, {name: customer_id, var: customer_id}, {name: cvv2, var: cvv2}, {name: dba_name, var: dba_name}, {name: dba_suffix, var: dba_suffix}, {name: dda_number, var: dda_number}, {name: developer_id, var: developer_id}, {name: duplicate_seconds, var: duplicate_seconds}, {name: echo_fields, var: echo_fields}, {name: email_address, var: email_address}, {name: email_receipt, var: email_receipt}, {name: emv_tran_id, var: emv_tran_id}, {name: exp_date, var: exp_date}, {name: fbo_id, var: fbo_id}, {name: line_items, var: line_items}, {name: loc_id, var: loc_id}, {name: mc_ucaf_data, var: mc_ucaf_data}, {name: mc_ucaf_ind, var: mc_ucaf_ind}, {name: merch_ref_num, var: merch_ref_num}, {name: merchant_id, var: merchant_id}, {name: moto_ecomm_ind, var: moto_ecomm_ind}, {name: partial_auth, var: partial_auth}, {name: payload_apple_pay, var: payload_apple_pay}, {name: payload_google_pay, var: payload_google_pay}, {name: pg_id, var: pg_id}, {name: profile_id, var: profile_id}, {name: purchase_id, var: purchase_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: subscription_id, var: subscription_id}, {name: tokenize, var: tokenize}, {name: tr_number, var: tr_number}, {name: tran_currency, var: tran_currency}, {name: type_id, var: type_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}, {name: xid_3ds, var: xid_3ds}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    amt_convenience_fee: $amt_convenience_fee, amt_fbo: $amt_fbo, amt_tax: $amt_tax, amt_tran: $amt_tran, amt_tran_fee: $amt_tran_fee, auth_code: $auth_code, avs_address: $avs_address, avs_zip: $avs_zip, card_id: $card_id, card_number: $card_number, card_swipe: $card_swipe, cardholder_name: $cardholder_name, cavv_3ds: $cavv_3ds, client_ip: $client_ip, customer: $customer, customer_code: $customer_code, customer_email: $customer_email, customer_id: $customer_id, cvv2: $cvv2, dba_name: $dba_name, dba_suffix: $dba_suffix, dda_number: $dda_number, developer_id: $developer_id, duplicate_seconds: $duplicate_seconds, echo_fields: $echo_fields, email_address: $email_address, email_receipt: $email_receipt, emv_tran_id: $emv_tran_id, exp_date: $exp_date, fbo_id: $fbo_id, line_items: $line_items, loc_id: $loc_id, mc_ucaf_data: $mc_ucaf_data, mc_ucaf_ind: $mc_ucaf_ind, merch_ref_num: $merch_ref_num, merchant_id: $merchant_id, moto_ecomm_ind: $moto_ecomm_ind, partial_auth: $partial_auth, payload_apple_pay: $payload_apple_pay, payload_google_pay: $payload_google_pay, pg_id: $pg_id, profile_id: $profile_id, purchase_id: $purchase_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, subscription_id: $subscription_id, tokenize: $tokenize, tr_number: $tr_number, tran_currency: $tran_currency, type_id: $type_id, user_id: $user_id, vendor_id: $vendor_id, xid_3ds: $xid_3ds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recharge Previously Settled Transaction
#
# POST /recharge/{pgIdOrig}
# Returns: record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Recharge
export def "recharge" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # Format: Variable length, up to 12,2 NDescription: Amount to recharge using the payment data from a previous transaction. (format: double, e.g. 1139.5)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recharge/{pgIdOrig}"
    path_params: [{name: pgIdOrig, var: pg_id_orig}]
    body: {content_type: "application/json", kind: json, fields: [{name: amt_tran, var: amt_tran}, {name: developer_id, var: developer_id}, {name: echo_fields, var: echo_fields}, {name: loc_id, var: loc_id}, {name: merchant_id, var: merchant_id}, {name: profile_id, var: profile_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    pg_id_orig: $pg_id_orig, amt_tran: $amt_tran, developer_id: $developer_id, echo_fields: $echo_fields, loc_id: $loc_id, merchant_id: $merchant_id, profile_id: $profile_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refund Previously Captured Transaction
#
# POST /refund/{pgIdOrig}
# Returns: record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Refund
export def "refund" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # Format: Variable length, up to 12,2 NDescription: Total amount to refund. Partial refunds are allowed by providing an amount in this field that is less than the total original transaction amount. (format: double, e.g. 1193.5)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this refund request applies. (format: int64, e.g. 212100026512)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/refund/{pgIdOrig}"
    path_params: [{name: pgIdOrig, var: pg_id_orig}]
    body: {content_type: "application/json", kind: json, fields: [{name: amt_tran, var: amt_tran}, {name: developer_id, var: developer_id}, {name: echo_fields, var: echo_fields}, {name: loc_id, var: loc_id}, {name: merchant_id, var: merchant_id}, {name: profile_id, var: profile_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    pg_id_orig: $pg_id_orig, amt_tran: $amt_tran, developer_id: $developer_id, echo_fields: $echo_fields, loc_id: $loc_id, merchant_id: $merchant_id, profile_id: $profile_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, user_id: $user_id, vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sale (Auth + Capture)
#
# POST /sale
# Returns: record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Sale
export def "sale" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # Format: Variable length, up to 12,2 NDescription: Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.Conditional Requirement: Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # Format: Fixed length, 6 ANDescription: This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.Conditional Requirement: This field is required in force request type. (e.g. 620376)
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 ANDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # Format: Fixed length, 28 ANDescription: Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # Format: Variable lengthDescription: [Deprecated use email_address] Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # Format: Variable length, up to 32 ANDescription: Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. JOECUSTOMER_12)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # Format: Variable length, up to 21 ANDescription: When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # Format: Fixed length, 9 ANDescription: For use by merchants using negative option marketing. This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: END DSCNTEND OFFEREND PROMOEND TRIAL (e.g. END PROMO)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --duplicate-seconds: int # Format: Variable length, up to 5 NDescription: Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # Default: falseDescription: When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # Format: Variable length, up to 36 ANDescription: Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --fbo-id: int # Format: Variable length, up to 16 NDescription: For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # Format: Variable lengthDescription: JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: quantity (7N) description (26AN) unit_of_measure (12AN) product_code (12AN) - cannot be all zeroes debit_credit_ind (1 AN) unit_cost (12,2N) Optional subfields: type_of_supply (2AN) - visa onlycommodity_code - visa only(12AN)Conditional Requirement: This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # Format: Variable length, up to 32 ANDescription: Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # Format: Fixed length, 1 ANDescription: MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --partial-auth: oneof<nothing, bool> # Default: falseDescription: This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request on a different card is needed to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # Format: Fixed length, 32 ANDescription: PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # Format: Variable length, up to 25 ANDescription: Purchase Identifier (also referred to as the invoice number generated by the merchant).Conditional Requirement: This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # Format: Variable length, up to 10 NDescription: Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --tran-currency: int # Format: Fixed length, 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # Format: Fixed length, 28 ANDescription: Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sale"
    body: {content_type: "application/json", kind: json, fields: [{name: amt_convenience_fee, var: amt_convenience_fee}, {name: amt_fbo, var: amt_fbo}, {name: amt_tax, var: amt_tax}, {name: amt_tran, var: amt_tran}, {name: amt_tran_fee, var: amt_tran_fee}, {name: auth_code, var: auth_code}, {name: avs_address, var: avs_address}, {name: avs_zip, var: avs_zip}, {name: card_id, var: card_id}, {name: card_number, var: card_number}, {name: card_swipe, var: card_swipe}, {name: cardholder_name, var: cardholder_name}, {name: cavv_3ds, var: cavv_3ds}, {name: client_ip, var: client_ip}, {name: customer, var: customer}, {name: customer_code, var: customer_code}, {name: customer_email, var: customer_email}, {name: customer_id, var: customer_id}, {name: cvv2, var: cvv2}, {name: dba_name, var: dba_name}, {name: dba_suffix, var: dba_suffix}, {name: dda_number, var: dda_number}, {name: developer_id, var: developer_id}, {name: duplicate_seconds, var: duplicate_seconds}, {name: echo_fields, var: echo_fields}, {name: email_address, var: email_address}, {name: email_receipt, var: email_receipt}, {name: emv_tran_id, var: emv_tran_id}, {name: exp_date, var: exp_date}, {name: fbo_id, var: fbo_id}, {name: line_items, var: line_items}, {name: loc_id, var: loc_id}, {name: mc_ucaf_data, var: mc_ucaf_data}, {name: mc_ucaf_ind, var: mc_ucaf_ind}, {name: merch_ref_num, var: merch_ref_num}, {name: merchant_id, var: merchant_id}, {name: moto_ecomm_ind, var: moto_ecomm_ind}, {name: partial_auth, var: partial_auth}, {name: payload_apple_pay, var: payload_apple_pay}, {name: payload_google_pay, var: payload_google_pay}, {name: pg_id, var: pg_id}, {name: profile_id, var: profile_id}, {name: purchase_id, var: purchase_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: subscription_id, var: subscription_id}, {name: tokenize, var: tokenize}, {name: tr_number, var: tr_number}, {name: tran_currency, var: tran_currency}, {name: type_id, var: type_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}, {name: xid_3ds, var: xid_3ds}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    amt_convenience_fee: $amt_convenience_fee, amt_fbo: $amt_fbo, amt_tax: $amt_tax, amt_tran: $amt_tran, amt_tran_fee: $amt_tran_fee, auth_code: $auth_code, avs_address: $avs_address, avs_zip: $avs_zip, card_id: $card_id, card_number: $card_number, card_swipe: $card_swipe, cardholder_name: $cardholder_name, cavv_3ds: $cavv_3ds, client_ip: $client_ip, customer: $customer, customer_code: $customer_code, customer_email: $customer_email, customer_id: $customer_id, cvv2: $cvv2, dba_name: $dba_name, dba_suffix: $dba_suffix, dda_number: $dda_number, developer_id: $developer_id, duplicate_seconds: $duplicate_seconds, echo_fields: $echo_fields, email_address: $email_address, email_receipt: $email_receipt, emv_tran_id: $emv_tran_id, exp_date: $exp_date, fbo_id: $fbo_id, line_items: $line_items, loc_id: $loc_id, mc_ucaf_data: $mc_ucaf_data, mc_ucaf_ind: $mc_ucaf_ind, merch_ref_num: $merch_ref_num, merchant_id: $merchant_id, moto_ecomm_ind: $moto_ecomm_ind, partial_auth: $partial_auth, payload_apple_pay: $payload_apple_pay, payload_google_pay: $payload_google_pay, pg_id: $pg_id, profile_id: $profile_id, purchase_id: $purchase_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, subscription_id: $subscription_id, tokenize: $tokenize, tr_number: $tr_number, tran_currency: $tran_currency, type_id: $type_id, user_id: $user_id, vendor_id: $vendor_id, xid_3ds: $xid_3ds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tokenize Card
#
# POST /tokenize
# Returns: record<card_id: string, card_number: string, echo_fields: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Tokenize
export def "tokenize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 NDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number in requests requiring cardholder account data.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79Description: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of account holder email addresses. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  exp_date: string # Format: Fixed length, 4 N(MMYY format)Description: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --single-use: oneof<nothing, bool> # Default: falseDescription: In a tokenize request, setting the single_use field to "true" will cause a single-use token to be generated. This token will expire in 10 minutes or when first used. (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this tokenize request applies. (format: int64, e.g. 212100026512)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tokenize"
    body: {content_type: "application/json", kind: json, fields: [{name: avs_address, var: avs_address}, {name: avs_zip, var: avs_zip}, {name: card_id, var: card_id}, {name: card_number, var: card_number}, {name: card_swipe, var: card_swipe}, {name: cardholder_name, var: cardholder_name}, {name: client_ip, var: client_ip}, {name: cvv2, var: cvv2}, {name: dda_number, var: dda_number}, {name: developer_id, var: developer_id}, {name: echo_fields, var: echo_fields}, {name: email_address, var: email_address}, {name: exp_date, var: exp_date}, {name: loc_id, var: loc_id}, {name: merchant_id, var: merchant_id}, {name: payload_apple_pay, var: payload_apple_pay}, {name: payload_google_pay, var: payload_google_pay}, {name: profile_id, var: profile_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: single_use, var: single_use}, {name: tr_number, var: tr_number}, {name: type_id, var: type_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    avs_address: $avs_address, avs_zip: $avs_zip, card_id: $card_id, card_number: $card_number, card_swipe: $card_swipe, cardholder_name: $cardholder_name, client_ip: $client_ip, cvv2: $cvv2, dda_number: $dda_number, developer_id: $developer_id, echo_fields: $echo_fields, email_address: $email_address, exp_date: $exp_date, loc_id: $loc_id, merchant_id: $merchant_id, payload_apple_pay: $payload_apple_pay, payload_google_pay: $payload_google_pay, profile_id: $profile_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, single_use: $single_use, tr_number: $tr_number, type_id: $type_id, user_id: $user_id, vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Card
#
# POST /verify
# Returns: record<auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, card_number: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Verify
export def "verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 NDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Variable length, up to 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  card_number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 data magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of account holder email addresses. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. Required when the field card_number is present. If card_swipe is present in the request, this field must NOT be present. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present. (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verify"
    body: {content_type: "application/json", kind: json, fields: [{name: avs_address, var: avs_address}, {name: avs_zip, var: avs_zip}, {name: card_id, var: card_id}, {name: card_number, var: card_number}, {name: card_swipe, var: card_swipe}, {name: cardholder_name, var: cardholder_name}, {name: client_ip, var: client_ip}, {name: customer, var: customer}, {name: customer_code, var: customer_code}, {name: cvv2, var: cvv2}, {name: dda_number, var: dda_number}, {name: developer_id, var: developer_id}, {name: echo_fields, var: echo_fields}, {name: email_address, var: email_address}, {name: exp_date, var: exp_date}, {name: loc_id, var: loc_id}, {name: merch_ref_num, var: merch_ref_num}, {name: merchant_id, var: merchant_id}, {name: moto_ecomm_ind, var: moto_ecomm_ind}, {name: payload_apple_pay, var: payload_apple_pay}, {name: payload_google_pay, var: payload_google_pay}, {name: profile_id, var: profile_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: tokenize, var: tokenize}, {name: tr_number, var: tr_number}, {name: type_id, var: type_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    avs_address: $avs_address, avs_zip: $avs_zip, card_id: $card_id, card_number: $card_number, card_swipe: $card_swipe, cardholder_name: $cardholder_name, client_ip: $client_ip, customer: $customer, customer_code: $customer_code, cvv2: $cvv2, dda_number: $dda_number, developer_id: $developer_id, echo_fields: $echo_fields, email_address: $email_address, exp_date: $exp_date, loc_id: $loc_id, merch_ref_num: $merch_ref_num, merchant_id: $merchant_id, moto_ecomm_ind: $moto_ecomm_ind, payload_apple_pay: $payload_apple_pay, payload_google_pay: $payload_google_pay, profile_id: $profile_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, tokenize: $tokenize, tr_number: $tr_number, type_id: $type_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Void a Previously Authorized Transaction
#
# POST /void/{pgIdOrig}
# Returns: record<echo_fields: string, pg_id: string, rcode: string, rmsg: string>
# operationId: Void
export def "void" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this void request applies. (format: int64, e.g. 212100026512)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/void/{pgIdOrig}"
    path_params: [{name: pgIdOrig, var: pg_id_orig}]
    body: {content_type: "application/json", kind: json, fields: [{name: developer_id, var: developer_id}, {name: echo_fields, var: echo_fields}, {name: loc_id, var: loc_id}, {name: merchant_id, var: merchant_id}, {name: profile_id, var: profile_id}, {name: report_data, var: report_data}, {name: retry_attempt, var: retry_attempt}, {name: retry_id, var: retry_id}, {name: session_id, var: session_id}, {name: user_id, var: user_id}, {name: vendor_id, var: vendor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    pg_id_orig: $pg_id_orig, developer_id: $developer_id, echo_fields: $echo_fields, loc_id: $loc_id, merchant_id: $merchant_id, profile_id: $profile_id, report_data: $report_data, retry_attempt: $retry_attempt, retry_id: $retry_id, session_id: $session_id, user_id: $user_id, vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
