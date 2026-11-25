# Auto-generated client for Adyen Payment API v68
# Source: https://api.apis.guru/v2/specs/adyen.com/PaymentService/68/openapi.json
# Auth: --token flag or $env.ADYEN_PAYMENT_API_TOKEN

const CLIENT = {
  base_url: "https://pal-test.adyen.com/pal/servlet/Payment/v68"
  token_env_var: "ADYEN_PAYMENT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: X-API-Key, prefix: ""}
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

def base-url-completer [] { ["https://pal-test.adyen.com/pal/servlet/Payment/v68"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def entity-type-completer [] { ["CompanyName" "NaturalPerson"] }
def funding-source-completer [] { ["debit"] }
def recurring-processing-model-completer [] { ["CardOnFile" "Subscription" "UnscheduledCardOnFile"] }
def shopper-interaction-completer [] { ["ContAuth" "Ecommerce" "Moto" "POS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-adjust-authorisation: "record<additionalData: record, pspReference: string, response: string>"
    post-authorise: "record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string>"
    post-authorise3d: "record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string>"
    post-authorise3ds2: "record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string>"
    post-cancel: "record<additionalData: record, pspReference: string, response: string>"
    post-cancel-or-refund: "record<additionalData: record, pspReference: string, response: string>"
    post-capture: "record<additionalData: record, pspReference: string, response: string>"
    post-donate: "record<additionalData: record, pspReference: string, response: string>"
    post-get-authentication-result: "record<threeDS1Result: record<cavv: string, cavvAlgorithm: string, eci: string, threeDAuthenticatedResponse: string, threeDOfferedResponse: string, xid: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>>"
    post-refund: "record<additionalData: record, pspReference: string, response: string>"
    post-retrieve3ds2-result: "record<threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>>"
    post-technical-cancel: "record<additionalData: record, pspReference: string, response: string>"
    post-void-pending-refund: "record<additionalData: record, pspReference: string, response: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-adjust-authorisation" "post-authorise" "post-authorise3d" "post-authorise3ds2" "post-cancel" "post-cancel-or-refund" "post-capture" "post-donate" "post-get-authentication-result" "post-refund" "post-retrieve3ds2-result" "post-technical-cancel" "post-void-pending-refund" "commands"] | sort) } | get name | first)
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

# Change the authorised amount
#
# POST /adjustAuthorisation
# Returns: record<additionalData: record, pspReference: string, response: string>
# operationId: post-adjustAuthorisation
export def "post-adjust-authorisation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  modification_amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/adjustAuthorisation"
    body: {content_type: "application/json", kind: json, fields: [{name: additionalData, var: additional_data}, {name: merchantAccount, var: merchant_account}, {name: modificationAmount, var: modification_amount}, {name: mpiData, var: mpi_data}, {name: originalMerchantReference, var: original_merchant_reference}, {name: originalReference, var: original_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: reference, var: reference}, {name: splits, var: splits}, {name: tenderReference, var: tender_reference}, {name: uniqueTerminalId, var: unique_terminal_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    additional_data: $additional_data, merchant_account: $merchant_account, modification_amount: $modification_amount, mpi_data: $mpi_data, original_merchant_reference: $original_merchant_reference, original_reference: $original_reference, platform_chargeback_logic: $platform_chargeback_logic, reference: $reference, splits: $splits, tender_reference: $tender_reference, unique_terminal_id: $unique_terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an authorisation
#
# POST /authorise
# Returns: record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string>
# operationId: post-authorise
export def "post-authorise" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --bank-account: record # shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browser-info: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --card: record # shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --device-fingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --entity-type: string@entity-type-completer # The type of the entity the payment is processed for.
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --fund-destination: record # shape: {additionalData?: record, billingAddress?: record, card?: record, selectedRecurringDetailReference?: string, shopperEmail?: string, shopperName?: record, shopperReference?: string, subMerchant?: record, telephoneNumber?: string}
  --fund-source: record # shape: {additionalData?: record, billingAddress?: record, card?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string}
  --funding-source: string@funding-source-completer # The funding source that should be used when multiple sources are available. For Brazilian combo cards, by default the funding source is credit. To use debit, set this value to **debit**.
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --nationality: string # The two-character country code of the shopper's nationality.
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selected-brand: string # Some payment methods require defining a value for this field to specify how to process the transaction. For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selected-recurring-detail-reference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --session-id: string # A session ID used to identify a payment session.
  --shopper-email: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > For 3D Secure 2 transactions, schemes require `shopperEmail` for all browser-based and mobile implementations.
  --shopper-ip: string # The shopper's IP address. In general, we recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > For 3D Secure 2 transactions, schemes require `shopperIP` for all browser-based implementations. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopper-interaction: string@shopper-interaction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default. This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopper-locale: string # The combination of a language code and a country code to specify the language to be used in the payment.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Required for recurring payments. Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopper-statement: string # The text to be shown on the shopper's bank statement. We recommend sending a maximum of 22 characters, otherwise banks might truncate the string. Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --social-security-number: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using [Adyen for Platforms](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information) or [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --store: string # The ecommerce or point-of-sale store that is processing the payment. Used in [partner model integrations](https://docs.adyen.com/marketplaces-and-platforms/classic/platforms-for-partners#route-payments) for Adyen for Platforms.
  --telephone-number: string # The shopper's telephone number.
  --three-ds2-request-data: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (default: false)
  --totals-group: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorise"
    body: {content_type: "application/json", kind: json, fields: [{name: accountInfo, var: account_info}, {name: additionalAmount, var: additional_amount}, {name: additionalData, var: additional_data}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: bankAccount, var: bank_account}, {name: billingAddress, var: billing_address}, {name: browserInfo, var: browser_info}, {name: captureDelayHours, var: capture_delay_hours}, {name: card, var: card}, {name: dateOfBirth, var: date_of_birth}, {name: dccQuote, var: dcc_quote}, {name: deliveryAddress, var: delivery_address}, {name: deliveryDate, var: delivery_date}, {name: deviceFingerprint, var: device_fingerprint}, {name: entityType, var: entity_type}, {name: fraudOffset, var: fraud_offset}, {name: fundDestination, var: fund_destination}, {name: fundSource, var: fund_source}, {name: fundingSource, var: funding_source}, {name: installments, var: installments}, {name: localizedShopperStatement, var: localized_shopper_statement}, {name: mandate, var: mandate}, {name: mcc, var: mcc}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: merchantRiskIndicator, var: merchant_risk_indicator}, {name: metadata, var: metadata}, {name: mpiData, var: mpi_data}, {name: nationality, var: nationality}, {name: orderReference, var: order_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: recurring, var: recurring}, {name: recurringProcessingModel, var: recurring_processing_model}, {name: reference, var: reference}, {name: selectedBrand, var: selected_brand}, {name: selectedRecurringDetailReference, var: selected_recurring_detail_reference}, {name: sessionId, var: session_id}, {name: shopperEmail, var: shopper_email}, {name: shopperIP, var: shopper_ip}, {name: shopperInteraction, var: shopper_interaction}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: socialSecurityNumber, var: social_security_number}, {name: splits, var: splits}, {name: store, var: store}, {name: telephoneNumber, var: telephone_number}, {name: threeDS2RequestData, var: three_ds2_request_data}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}, {name: totalsGroup, var: totals_group}, {name: trustedShopper, var: trusted_shopper}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_info: $account_info, additional_amount: $additional_amount, additional_data: $additional_data, amount: $amount, application_info: $application_info, bank_account: $bank_account, billing_address: $billing_address, browser_info: $browser_info, capture_delay_hours: $capture_delay_hours, card: $card, date_of_birth: $date_of_birth, dcc_quote: $dcc_quote, delivery_address: $delivery_address, delivery_date: $delivery_date, device_fingerprint: $device_fingerprint, entity_type: $entity_type, fraud_offset: $fraud_offset, fund_destination: $fund_destination, fund_source: $fund_source, funding_source: $funding_source, installments: $installments, localized_shopper_statement: $localized_shopper_statement, mandate: $mandate, mcc: $mcc, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, merchant_risk_indicator: $merchant_risk_indicator, metadata: $metadata, mpi_data: $mpi_data, nationality: $nationality, order_reference: $order_reference, platform_chargeback_logic: $platform_chargeback_logic, recurring: $recurring, recurring_processing_model: $recurring_processing_model, reference: $reference, selected_brand: $selected_brand, selected_recurring_detail_reference: $selected_recurring_detail_reference, session_id: $session_id, shopper_email: $shopper_email, shopper_ip: $shopper_ip, shopper_interaction: $shopper_interaction, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, social_security_number: $social_security_number, splits: $splits, store: $store, telephone_number: $telephone_number, three_ds2_request_data: $three_ds2_request_data, three_ds_authentication_only: $three_ds_authentication_only, totals_group: $totals_group, trusted_shopper: $trusted_shopper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete a 3DS authorisation
#
# POST /authorise3d
# Returns: record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string>
# operationId: post-authorise3d
export def "post-authorise3d" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  --amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browser-info: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --device-fingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  md: string # The payment session identifier returned by the card issuer.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  pa_response: string # Payment authorisation response returned by the card issuer. The `paResponse` field holds the PaRes value received from the card issuer.
  --recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selected-brand: string # Some payment methods require defining a value for this field to specify how to process the transaction. For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selected-recurring-detail-reference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --session-id: string # A session ID used to identify a payment session.
  --shopper-email: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > For 3D Secure 2 transactions, schemes require `shopperEmail` for all browser-based and mobile implementations.
  --shopper-ip: string # The shopper's IP address. In general, we recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > For 3D Secure 2 transactions, schemes require `shopperIP` for all browser-based implementations. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopper-interaction: string@shopper-interaction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default. This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopper-locale: string # The combination of a language code and a country code to specify the language to be used in the payment.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Required for recurring payments. Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopper-statement: string # The text to be shown on the shopper's bank statement. We recommend sending a maximum of 22 characters, otherwise banks might truncate the string. Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --social-security-number: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using [Adyen for Platforms](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information) or [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --store: string # The ecommerce or point-of-sale store that is processing the payment. Used in [partner model integrations](https://docs.adyen.com/marketplaces-and-platforms/classic/platforms-for-partners#route-payments) for Adyen for Platforms.
  --telephone-number: string # The shopper's telephone number.
  --three-ds2-request-data: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (default: false)
  --totals-group: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorise3d"
    body: {content_type: "application/json", kind: json, fields: [{name: accountInfo, var: account_info}, {name: additionalAmount, var: additional_amount}, {name: additionalData, var: additional_data}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: billingAddress, var: billing_address}, {name: browserInfo, var: browser_info}, {name: captureDelayHours, var: capture_delay_hours}, {name: dateOfBirth, var: date_of_birth}, {name: dccQuote, var: dcc_quote}, {name: deliveryAddress, var: delivery_address}, {name: deliveryDate, var: delivery_date}, {name: deviceFingerprint, var: device_fingerprint}, {name: fraudOffset, var: fraud_offset}, {name: installments, var: installments}, {name: localizedShopperStatement, var: localized_shopper_statement}, {name: mcc, var: mcc}, {name: md, var: md}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: merchantRiskIndicator, var: merchant_risk_indicator}, {name: metadata, var: metadata}, {name: orderReference, var: order_reference}, {name: paResponse, var: pa_response}, {name: recurring, var: recurring}, {name: recurringProcessingModel, var: recurring_processing_model}, {name: reference, var: reference}, {name: selectedBrand, var: selected_brand}, {name: selectedRecurringDetailReference, var: selected_recurring_detail_reference}, {name: sessionId, var: session_id}, {name: shopperEmail, var: shopper_email}, {name: shopperIP, var: shopper_ip}, {name: shopperInteraction, var: shopper_interaction}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: socialSecurityNumber, var: social_security_number}, {name: splits, var: splits}, {name: store, var: store}, {name: telephoneNumber, var: telephone_number}, {name: threeDS2RequestData, var: three_ds2_request_data}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}, {name: totalsGroup, var: totals_group}, {name: trustedShopper, var: trusted_shopper}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_info: $account_info, additional_amount: $additional_amount, additional_data: $additional_data, amount: $amount, application_info: $application_info, billing_address: $billing_address, browser_info: $browser_info, capture_delay_hours: $capture_delay_hours, date_of_birth: $date_of_birth, dcc_quote: $dcc_quote, delivery_address: $delivery_address, delivery_date: $delivery_date, device_fingerprint: $device_fingerprint, fraud_offset: $fraud_offset, installments: $installments, localized_shopper_statement: $localized_shopper_statement, mcc: $mcc, md: $md, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, merchant_risk_indicator: $merchant_risk_indicator, metadata: $metadata, order_reference: $order_reference, pa_response: $pa_response, recurring: $recurring, recurring_processing_model: $recurring_processing_model, reference: $reference, selected_brand: $selected_brand, selected_recurring_detail_reference: $selected_recurring_detail_reference, session_id: $session_id, shopper_email: $shopper_email, shopper_ip: $shopper_ip, shopper_interaction: $shopper_interaction, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, social_security_number: $social_security_number, splits: $splits, store: $store, telephone_number: $telephone_number, three_ds2_request_data: $three_ds2_request_data, three_ds_authentication_only: $three_ds_authentication_only, totals_group: $totals_group, trusted_shopper: $trusted_shopper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete a 3DS2 authorisation
#
# POST /authorise3ds2
# Returns: record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string>
# operationId: post-authorise3ds2
export def "post-authorise3ds2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browser-info: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --device-fingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selected-brand: string # Some payment methods require defining a value for this field to specify how to process the transaction. For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selected-recurring-detail-reference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --session-id: string # A session ID used to identify a payment session.
  --shopper-email: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > For 3D Secure 2 transactions, schemes require `shopperEmail` for all browser-based and mobile implementations.
  --shopper-ip: string # The shopper's IP address. In general, we recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > For 3D Secure 2 transactions, schemes require `shopperIP` for all browser-based implementations. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopper-interaction: string@shopper-interaction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default. This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopper-locale: string # The combination of a language code and a country code to specify the language to be used in the payment.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Required for recurring payments. Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopper-statement: string # The text to be shown on the shopper's bank statement. We recommend sending a maximum of 22 characters, otherwise banks might truncate the string. Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --social-security-number: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using [Adyen for Platforms](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information) or [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --store: string # The ecommerce or point-of-sale store that is processing the payment. Used in [partner model integrations](https://docs.adyen.com/marketplaces-and-platforms/classic/platforms-for-partners#route-payments) for Adyen for Platforms.
  --telephone-number: string # The shopper's telephone number.
  --three-ds2-request-data: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
  --three-ds2-result: record # shape: {authenticationValue?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", dsTransID?: string, eci?: string, exemptionIndicator?: "lowValue"|"secureCorporate"|"trustedBeneficiary"|"transactionRiskAnalysis", messageVersion?: string, riskScore?: string, threeDSServerTransID?: string, timestamp?: string, transStatus?: string, transStatusReason?: string, ... (1 more fields)}
  --three-ds2-token: string # The ThreeDS2Token that was returned in the /authorise call.
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (default: false)
  --totals-group: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorise3ds2"
    body: {content_type: "application/json", kind: json, fields: [{name: accountInfo, var: account_info}, {name: additionalAmount, var: additional_amount}, {name: additionalData, var: additional_data}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: billingAddress, var: billing_address}, {name: browserInfo, var: browser_info}, {name: captureDelayHours, var: capture_delay_hours}, {name: dateOfBirth, var: date_of_birth}, {name: dccQuote, var: dcc_quote}, {name: deliveryAddress, var: delivery_address}, {name: deliveryDate, var: delivery_date}, {name: deviceFingerprint, var: device_fingerprint}, {name: fraudOffset, var: fraud_offset}, {name: installments, var: installments}, {name: localizedShopperStatement, var: localized_shopper_statement}, {name: mcc, var: mcc}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: merchantRiskIndicator, var: merchant_risk_indicator}, {name: metadata, var: metadata}, {name: orderReference, var: order_reference}, {name: recurring, var: recurring}, {name: recurringProcessingModel, var: recurring_processing_model}, {name: reference, var: reference}, {name: selectedBrand, var: selected_brand}, {name: selectedRecurringDetailReference, var: selected_recurring_detail_reference}, {name: sessionId, var: session_id}, {name: shopperEmail, var: shopper_email}, {name: shopperIP, var: shopper_ip}, {name: shopperInteraction, var: shopper_interaction}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: socialSecurityNumber, var: social_security_number}, {name: splits, var: splits}, {name: store, var: store}, {name: telephoneNumber, var: telephone_number}, {name: threeDS2RequestData, var: three_ds2_request_data}, {name: threeDS2Result, var: three_ds2_result}, {name: threeDS2Token, var: three_ds2_token}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}, {name: totalsGroup, var: totals_group}, {name: trustedShopper, var: trusted_shopper}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_info: $account_info, additional_amount: $additional_amount, additional_data: $additional_data, amount: $amount, application_info: $application_info, billing_address: $billing_address, browser_info: $browser_info, capture_delay_hours: $capture_delay_hours, date_of_birth: $date_of_birth, dcc_quote: $dcc_quote, delivery_address: $delivery_address, delivery_date: $delivery_date, device_fingerprint: $device_fingerprint, fraud_offset: $fraud_offset, installments: $installments, localized_shopper_statement: $localized_shopper_statement, mcc: $mcc, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, merchant_risk_indicator: $merchant_risk_indicator, metadata: $metadata, order_reference: $order_reference, recurring: $recurring, recurring_processing_model: $recurring_processing_model, reference: $reference, selected_brand: $selected_brand, selected_recurring_detail_reference: $selected_recurring_detail_reference, session_id: $session_id, shopper_email: $shopper_email, shopper_ip: $shopper_ip, shopper_interaction: $shopper_interaction, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, social_security_number: $social_security_number, splits: $splits, store: $store, telephone_number: $telephone_number, three_ds2_request_data: $three_ds2_request_data, three_ds2_result: $three_ds2_result, three_ds2_token: $three_ds2_token, three_ds_authentication_only: $three_ds_authentication_only, totals_group: $totals_group, trusted_shopper: $trusted_shopper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an authorisation
#
# POST /cancel
# Returns: record<additionalData: record, pspReference: string, response: string>
# operationId: post-cancel
export def "post-cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cancel"
    body: {content_type: "application/json", kind: json, fields: [{name: additionalData, var: additional_data}, {name: merchantAccount, var: merchant_account}, {name: mpiData, var: mpi_data}, {name: originalMerchantReference, var: original_merchant_reference}, {name: originalReference, var: original_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: reference, var: reference}, {name: splits, var: splits}, {name: tenderReference, var: tender_reference}, {name: uniqueTerminalId, var: unique_terminal_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    additional_data: $additional_data, merchant_account: $merchant_account, mpi_data: $mpi_data, original_merchant_reference: $original_merchant_reference, original_reference: $original_reference, platform_chargeback_logic: $platform_chargeback_logic, reference: $reference, splits: $splits, tender_reference: $tender_reference, unique_terminal_id: $unique_terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel or refund a payment
#
# POST /cancelOrRefund
# Returns: record<additionalData: record, pspReference: string, response: string>
# operationId: post-cancelOrRefund
export def "post-cancel-or-refund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cancelOrRefund"
    body: {content_type: "application/json", kind: json, fields: [{name: additionalData, var: additional_data}, {name: merchantAccount, var: merchant_account}, {name: mpiData, var: mpi_data}, {name: originalMerchantReference, var: original_merchant_reference}, {name: originalReference, var: original_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: reference, var: reference}, {name: tenderReference, var: tender_reference}, {name: uniqueTerminalId, var: unique_terminal_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    additional_data: $additional_data, merchant_account: $merchant_account, mpi_data: $mpi_data, original_merchant_reference: $original_merchant_reference, original_reference: $original_reference, platform_chargeback_logic: $platform_chargeback_logic, reference: $reference, tender_reference: $tender_reference, unique_terminal_id: $unique_terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Capture an authorisation
#
# POST /capture
# Returns: record<additionalData: record, pspReference: string, response: string>
# operationId: post-capture
export def "post-capture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  modification_amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/capture"
    body: {content_type: "application/json", kind: json, fields: [{name: additionalData, var: additional_data}, {name: merchantAccount, var: merchant_account}, {name: modificationAmount, var: modification_amount}, {name: mpiData, var: mpi_data}, {name: originalMerchantReference, var: original_merchant_reference}, {name: originalReference, var: original_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: reference, var: reference}, {name: splits, var: splits}, {name: tenderReference, var: tender_reference}, {name: uniqueTerminalId, var: unique_terminal_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    additional_data: $additional_data, merchant_account: $merchant_account, modification_amount: $modification_amount, mpi_data: $mpi_data, original_merchant_reference: $original_merchant_reference, original_reference: $original_reference, platform_chargeback_logic: $platform_chargeback_logic, reference: $reference, splits: $splits, tender_reference: $tender_reference, unique_terminal_id: $unique_terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a donation
#
# POST /donate
# Returns: record<additionalData: record, pspReference: string, response: string>
# operationId: post-donate
export def "post-donate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  donation_account: string # The Adyen account name of the charity.
  merchant_account: string # The merchant account that is used to process the payment.
  modification_amount: record # shape: {currency: string, value: int}
  --original-reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/donate"
    body: {content_type: "application/json", kind: json, fields: [{name: donationAccount, var: donation_account}, {name: merchantAccount, var: merchant_account}, {name: modificationAmount, var: modification_amount}, {name: originalReference, var: original_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: reference, var: reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    donation_account: $donation_account, merchant_account: $merchant_account, modification_amount: $modification_amount, original_reference: $original_reference, platform_chargeback_logic: $platform_chargeback_logic, reference: $reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the 3DS authentication result
#
# POST /getAuthenticationResult
# Returns: record<threeDS1Result: record<cavv: string, cavvAlgorithm: string, eci: string, threeDAuthenticatedResponse: string, threeDOfferedResponse: string, xid: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>>
# operationId: post-getAuthenticationResult
export def "post-get-authentication-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  merchant_account: string # The merchant account identifier, with which the authentication was processed.
  psp_reference: string # The pspReference identifier for the transaction.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getAuthenticationResult"
    body: {content_type: "application/json", kind: json, fields: [{name: merchantAccount, var: merchant_account}, {name: pspReference, var: psp_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    merchant_account: $merchant_account, psp_reference: $psp_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refund a captured payment
#
# POST /refund
# Returns: record<additionalData: record, pspReference: string, response: string>
# operationId: post-refund
export def "post-refund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  modification_amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/refund"
    body: {content_type: "application/json", kind: json, fields: [{name: additionalData, var: additional_data}, {name: merchantAccount, var: merchant_account}, {name: modificationAmount, var: modification_amount}, {name: mpiData, var: mpi_data}, {name: originalMerchantReference, var: original_merchant_reference}, {name: originalReference, var: original_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: reference, var: reference}, {name: splits, var: splits}, {name: tenderReference, var: tender_reference}, {name: uniqueTerminalId, var: unique_terminal_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    additional_data: $additional_data, merchant_account: $merchant_account, modification_amount: $modification_amount, mpi_data: $mpi_data, original_merchant_reference: $original_merchant_reference, original_reference: $original_reference, platform_chargeback_logic: $platform_chargeback_logic, reference: $reference, splits: $splits, tender_reference: $tender_reference, unique_terminal_id: $unique_terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the 3DS2 authentication result
#
# POST /retrieve3ds2Result
# Returns: record<threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>>
# operationId: post-retrieve3ds2Result
export def "post-retrieve3ds2-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  psp_reference: string # The pspReference returned in the /authorise call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/retrieve3ds2Result"
    body: {content_type: "application/json", kind: json, fields: [{name: merchantAccount, var: merchant_account}, {name: pspReference, var: psp_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    merchant_account: $merchant_account, psp_reference: $psp_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an authorisation using your reference
#
# POST /technicalCancel
# Returns: record<additionalData: record, pspReference: string, response: string>
# operationId: post-technicalCancel
export def "post-technical-cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  --modification-amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  original_merchant_reference: string # The original merchant reference to cancel.
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/technicalCancel"
    body: {content_type: "application/json", kind: json, fields: [{name: additionalData, var: additional_data}, {name: merchantAccount, var: merchant_account}, {name: modificationAmount, var: modification_amount}, {name: mpiData, var: mpi_data}, {name: originalMerchantReference, var: original_merchant_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: reference, var: reference}, {name: splits, var: splits}, {name: tenderReference, var: tender_reference}, {name: uniqueTerminalId, var: unique_terminal_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    additional_data: $additional_data, merchant_account: $merchant_account, modification_amount: $modification_amount, mpi_data: $mpi_data, original_merchant_reference: $original_merchant_reference, platform_chargeback_logic: $platform_chargeback_logic, reference: $reference, splits: $splits, tender_reference: $tender_reference, unique_terminal_id: $unique_terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an in-person refund
#
# POST /voidPendingRefund
# Returns: record<additionalData: record, pspReference: string, response: string>
# operationId: post-voidPendingRefund
export def "post-void-pending-refund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  --modification-amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  --original-reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/voidPendingRefund"
    body: {content_type: "application/json", kind: json, fields: [{name: additionalData, var: additional_data}, {name: merchantAccount, var: merchant_account}, {name: modificationAmount, var: modification_amount}, {name: mpiData, var: mpi_data}, {name: originalMerchantReference, var: original_merchant_reference}, {name: originalReference, var: original_reference}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: reference, var: reference}, {name: splits, var: splits}, {name: tenderReference, var: tender_reference}, {name: uniqueTerminalId, var: unique_terminal_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    additional_data: $additional_data, merchant_account: $merchant_account, modification_amount: $modification_amount, mpi_data: $mpi_data, original_merchant_reference: $original_merchant_reference, original_reference: $original_reference, platform_chargeback_logic: $platform_chargeback_logic, reference: $reference, splits: $splits, tender_reference: $tender_reference, unique_terminal_id: $unique_terminal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
