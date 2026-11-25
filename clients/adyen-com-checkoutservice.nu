# Auto-generated client for Adyen Checkout API v70
# Source: https://api.apis.guru/v2/specs/adyen.com/CheckoutService/70/openapi.json
# Auth: --token flag or $env.ADYEN_CHECKOUT_API_TOKEN

const CLIENT = {
  base_url: "https://checkout-test.adyen.com/v70"
  token_env_var: "ADYEN_CHECKOUT_API_TOKEN"
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

def base-url-completer [] { ["https://checkout-test.adyen.com/v70"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def channel-completer [] { ["Android" "Web" "iOS"] }
def entity-type-completer [] { ["CompanyName" "NaturalPerson"] }
def industry-usage-completer [] { ["delayedCharge" "installment" "noShow"] }
def recurring-processing-model-completer [] { ["CardOnFile" "Subscription" "UnscheduledCardOnFile"] }
def shopper-interaction-completer [] { ["ContAuth" "Ecommerce" "Moto" "POS"] }
def store-payment-method-mode-completer [] { ["askForConsent" "disabled" "enabled"] }
def status-completer [] { ["expired"] }
def merchant-refund-reason-completer [] { ["CUSTOMER REQUEST" "DUPLICATE" "FRAUD" "OTHER" "RETURN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-apple-pay-sessions: "record<data: string>"
    post-cancels: "record<merchantAccount: string, paymentReference: string, pspReference: string, reference: string, status: string>"
    post-card-details: "record<brands: table<supported: bool, type: string>>"
    post-donations: "record<amount: record<currency: string, value: int>, donationAccount: string, id: string, merchantAccount: string, payment: record<action: any, additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list>, merchantReference: string, order: record<amount: record, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record>, paymentMethod: record<brand: string, type: string>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string>, reference: string, status: string>"
    post-orders: "record<additionalData: record, amount: record<currency: string, value: int>, expiresAt: string, fraudResult: record<accountScore: int, results: list<record>>, orderData: string, pspReference: string, reference: string, refusalReason: string, remainingAmount: record<currency: string, value: int>, resultCode: string>"
    post-orders-cancel: "record<pspReference: string, resultCode: string>"
    post-origin-keys: "record<originKeys: record>"
    post-payment-links: "record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, updatedAt: string, url: string>"
    get-payment-links-link-id: "record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, updatedAt: string, url: string>"
    patch-payment-links-link-id: "record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, updatedAt: string, url: string>"
    post-payment-methods: "record<paymentMethods: table<brand: string, brands: list, configuration: record, fundingSource: string, group: record, inputDetails: list, issuers: list, name: string, type: string>, storedPaymentMethods: table<brand: string, expiryMonth: string, expiryYear: string, holderName: string, iban: string, id: string, lastFour: string, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, supportedRecurringProcessingModels: list, supportedShopperInteractions: list, type: string>>"
    post-payment-methods-balance: "record<additionalData: record, balance: record<currency: string, value: int>, fraudResult: record<accountScore: int, results: list<record>>, pspReference: string, refusalReason: string, resultCode: string, transactionLimit: record<currency: string, value: int>>"
    post-payment-session: "record<paymentSession: string, recurringDetails: table<brand: string, brands: list, configuration: record, fundingSource: string, group: record, inputDetails: list, issuers: list, name: string, recurringDetailReference: string, storedDetails: record, type: string>>"
    post-payments: "record<action: any, additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list<record>>, merchantReference: string, order: record<amount: record<currency: string, value: int>, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record<currency: string, value: int>>, paymentMethod: record<brand: string, type: string>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string>"
    post-payments-details: "record<additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list<record>>, merchantReference: string, order: record<amount: record<currency: string, value: int>, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record<currency: string, value: int>>, paymentMethod: record<brand: string, type: string>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, shopperLocale: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string>"
    post-payments-result: "record<additionalData: record, fraudResult: record<accountScore: int, results: list<record>>, merchantReference: string, order: record<amount: record<currency: string, value: int>, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record<currency: string, value: int>>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, serviceError: record<errorCode: string, errorType: string, message: string, pspReference: string>, shopperLocale: string>"
    post-payments-payment-psp-reference-amount-updates: "record<amount: record<currency: string, value: int>, industryUsage: string, merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string>"
    post-payments-payment-psp-reference-cancels: "record<merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, status: string>"
    post-payments-payment-psp-reference-captures: "record<amount: record<currency: string, value: int>, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string>"
    post-payments-payment-psp-reference-refunds: "record<amount: record<currency: string, value: int>, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, merchantAccount: string, merchantRefundReason: string, paymentPspReference: string, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string>"
    post-payments-payment-psp-reference-reversals: "record<merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, status: string>"
    post-sessions: "record<accountInfo: record<accountAgeIndicator: string, accountChangeDate: string, accountChangeIndicator: string, accountCreationDate: string, accountType: string, addCardAttemptsDay: int, deliveryAddressUsageDate: string, deliveryAddressUsageIndicator: string, homePhone: string, mobilePhone: string, passwordChangeDate: string, passwordChangeIndicator: string, pastTransactionsDay: int, pastTransactionsYear: int, paymentAccountAge: string, paymentAccountIndicator: string, purchasesLast6Months: int, suspiciousActivity: bool, workPhone: string>, additionalAmount: record<currency: string, value: int>, additionalData: record, allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, authenticationData: record<attemptAuthentication: string, authenticationOnly: bool, threeDSRequestData: record<challengeWindowSize: string, dataOnly: string, nativeThreeDS: string, threeDSVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, channel: string, company: record<homepage: string, name: string, registrationNumber: string, registryLocation: string, taxId: string, type: string>, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, enableOneClick: bool, enablePayOut: bool, enableRecurring: bool, expiresAt: string, fundOrigin: record<billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, shopperName: record<firstName: string, lastName: string>>, fundRecipient: record<billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, paymentMethod: record<brand: string, checkoutAttemptId: string, \"cupsecureplus.smscode\": string, cvc: string, encryptedCardNumber: string, encryptedExpiryMonth: string, encryptedExpiryYear: string, encryptedSecurityCode: string, expiryMonth: string, expiryYear: string, fundingSource: string, holderName: string, networkPaymentReference: string, number: string, recurringDetailReference: string, shopperNotificationReference: string, storedPaymentMethodId: string, threeDS2SdkVersion: string, type: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, storedPaymentMethodId: string, subMerchant: record<city: string, country: string, mcc: string, name: string, taxId: string>, telephoneNumber: string, walletIdentifier: string, walletOwnerTaxId: string>, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, mandate: record<amount: string, amountRule: string, billingAttemptsRule: string, billingDay: string, endsAt: string, frequency: string, remarks: string, startsAt: string>, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, mode: string, mpiData: record<authenticationResponse: string, cavv: string, cavvAlgorithm: string, challengeCancel: string, directoryResponse: string, dsTransID: string, eci: string, riskScore: string, threeDSVersion: string, tokenAuthenticationVerificationValue: string, transStatusReason: string, xid: string>, recurringExpiry: string, recurringFrequency: string, recurringProcessingModel: string, redirectFromIssuerMethod: string, redirectToIssuerMethod: string, reference: string, returnUrl: string, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, sessionData: string, shopperEmail: string, shopperIP: string, shopperInteraction: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, store: string, storePaymentMethod: bool, storePaymentMethodMode: string, telephoneNumber: string, threeDSAuthenticationOnly: bool, trustedShopper: bool>"
    get-stored-payment-methods: "record<merchantAccount: string, shopperReference: string, storedPaymentMethods: table<brand: string, expiryMonth: string, expiryYear: string, externalResponseCode: string, externalTokenReference: string, holderName: string, iban: string, id: string, issuerName: string, lastFour: string, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, shopperReference: string, supportedRecurringProcessingModels: list, type: string>>"
    delete-stored-payment-methods-recurring-id: "record<brand: string, expiryMonth: string, expiryYear: string, externalResponseCode: string, externalTokenReference: string, holderName: string, iban: string, id: string, issuerName: string, lastFour: string, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, shopperReference: string, supportedRecurringProcessingModels: list<string>, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-apple-pay-sessions" "post-cancels" "post-card-details" "post-donations" "post-orders" "post-orders-cancel" "post-origin-keys" "post-payment-links" "get-payment-links-link-id" "patch-payment-links-link-id" "post-payment-methods" "post-payment-methods-balance" "post-payment-session" "post-payments" "post-payments-details" "post-payments-result" "post-payments-payment-psp-reference-amount-updates" "post-payments-payment-psp-reference-cancels" "post-payments-payment-psp-reference-captures" "post-payments-payment-psp-reference-refunds" "post-payments-payment-psp-reference-reversals" "post-sessions" "get-stored-payment-methods" "delete-stored-payment-methods-recurring-id" "commands"] | sort) } | get name | first)
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

# Get an Apple Pay session
#
# POST /applePay/sessions
# Returns: record<data: string>
# operationId: post-applePay-sessions
export def "post-apple-pay-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  display_name: string # This is the name that your shoppers will see in the Apple Pay interface. The value returned as `configuration.merchantName` field from the [`/paymentMethods`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/paymentMethods) response.
  domain_name: string # The domain name you provided when you added Apple Pay in your Customer Area. This must match the `window.location.hostname` of the web shop.
  merchant_identifier: string # Your merchant identifier registered with Apple Pay. Use the value of the `configuration.merchantId` field from the [`/paymentMethods`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/paymentMethods) response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/applePay/sessions"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: domainName, var: domain_name}, {name: merchantIdentifier, var: merchant_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, display_name: $display_name, domain_name: $domain_name, merchant_identifier: $merchant_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an authorised payment
#
# POST /cancels
# Returns: record<merchantAccount: string, paymentReference: string, pspReference: string, reference: string, status: string>
# operationId: post-cancels
export def "post-cancels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  merchant_account: string # The merchant account that is used to process the payment.
  payment_reference: string # The [`reference`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/payments__reqParam_reference) of the payment that you want to cancel.
  --reference: string # Your reference for the cancel request. Maximum length: 80 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cancels"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: merchantAccount, var: merchant_account}, {name: paymentReference, var: payment_reference}, {name: reference, var: reference}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    idempotency_key: $idempotency_key, merchant_account: $merchant_account, payment_reference: $payment_reference, reference: $reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of brands on the card
#
# POST /cardDetails
# Returns: record<brands: table<supported: bool, type: string>>
# operationId: post-cardDetails
export def "post-card-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  card_number: string # A minimum of the first 8 digits of the card number and a maximum of the full card number. 11 digits gives the best result. You must be [fully PCI compliant](https://docs.adyen.com/development-resources/pci-dss-compliance-guide) to collect raw card data.
  --country-code: string # The shopper country. Format: [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) Example: NL or DE
  --encrypted-card-number: string # The encrypted card number.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --supported-brands: list<string> # The card brands you support. This is the [`brands`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/paymentMethods__resParam_paymentMethods-brands) array from your [`/paymentMethods`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/paymentMethods) response. If not included, our API uses the ones configured for your merchant account and, if provided, the country code.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cardDetails"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: cardNumber, var: card_number}, {name: countryCode, var: country_code}, {name: encryptedCardNumber, var: encrypted_card_number}, {name: merchantAccount, var: merchant_account}, {name: supportedBrands, var: supported_brands}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, card_number: $card_number, country_code: $country_code, encrypted_card_number: $encrypted_card_number, merchant_account: $merchant_account, supported_brands: $supported_brands
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a transaction for donations
#
# POST /donations
# Returns: record<amount: record<currency: string, value: int>, donationAccount: string, id: string, merchantAccount: string, payment: record<action: any, additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list>, merchantReference: string, order: record<amount: record, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record>, paymentMethod: record<brand: string, type: string>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string>, reference: string, status: string>
# operationId: post-donations
@deprecated --flag conversion-id
@deprecated --flag three-ds-authentication-only
export def "post-donations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --authentication-data: record # shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browser-info: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field is optional for filtering out payment methods that are only available on specific platforms. If this value is not set, then we will try to infer it from the `sdkVersion` or `token`. Possible values: * iOS * Android * Web
  --checkout-attempt-id: string # Checkout attempt ID that corresponds to the Id generated by the client SDK for tracking user payment journey.
  --company: record # shape: {homepage?: string, name?: string, registrationNumber?: string, registryLocation?: string, taxId?: string, type?: string}
  --conversion-id: string # Conversion ID that corresponds to the Id generated by the client SDK for tracking user payment journey. (DEPRECATED)
  --country-code: string # The shopper country. Format: [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) Example: NL or DE
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --device-fingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  donation_account: string # Donation account to which the transaction is credited.
  --donation-original-psp-reference: string # PSP reference of the transaction from which the donation token is generated. Required when `donationToken` is provided.
  --donation-token: string # Donation token received in the `/payments` call.
  --enable-one-click: oneof<nothing, bool> # When true and `shopperReference` is provided, the shopper will be asked if the payment details should be stored for future one-click payments.
  --enable-pay-out: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for payouts.
  --enable-recurring: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for recurring payments.
  --entity-type: string@entity-type-completer # The type of the entity the payment is processed for.
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --industry-usage: string@industry-usage-completer # The reason for the amount update. Possible values: * **delayedCharge** * **noShow** * **installment**
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --line-items: list # Price and product information of the refunded items, required for [partial refunds](https://docs.adyen.com/online-payments/refund#refund-a-payment). > This field is required for partial refunds with 3x 4x Oney, Affirm, Afterpay, Atome, Clearpay, Klarna, Ratepay, Walley, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --order: record # shape: {orderData: string, pspReference: string}
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --origin: string # Required for the 3D Secure 2 `channel` **Web** integration. Set this parameter to the origin URL of the page that you are loading the 3D Secure Component from.
  payment_method: any # The type and required details of a payment method to use.
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurring-expiry: string # Date after which no further authorisations shall be performed. Only for 3D Secure 2.
  --recurring-frequency: string # Minimum number of days between authorisations. Only for 3D Secure 2.
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --redirect-from-issuer-method: string # Specifies the redirect method (GET or POST) when redirecting back from the issuer.
  --redirect-to-issuer-method: string # Specifies the redirect method (GET or POST) when redirecting to the issuer.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  return_url: string # The URL to return to in case of a redirection. The format depends on the channel. This URL can have a maximum of 1024 characters. * For web, include the protocol `http://` or `https://`. You can also include your own additional query parameters, for example, shopper ID or order reference number. Example: `https://your-company.com/checkout?shopperOrder=12xy` * For iOS, use the custom URL for your app. To know more about setting custom URL schemes, refer to the [Apple Developer documentation](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app). Example: `my-app://` * For Android, use a custom URL handled by an Activity on your app. You can configure it with an [intent filter](https://developer.android.com/guide/components/intents-filters). Example: `my-app://your.package.name`
  --risk-data: record # shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
  --session-validity: string # The date and time until when the session remains valid, in [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format. For example: 2020-07-18T15:42:40.428+01:00
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
  --store-payment-method: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be stored.
  --telephone-number: string # The shopper's telephone number.
  --three-ds2-request-data: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (DEPRECATED, default: false)
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/donations"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountInfo, var: account_info}, {name: additionalAmount, var: additional_amount}, {name: additionalData, var: additional_data}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: authenticationData, var: authentication_data}, {name: billingAddress, var: billing_address}, {name: browserInfo, var: browser_info}, {name: captureDelayHours, var: capture_delay_hours}, {name: channel, var: channel}, {name: checkoutAttemptId, var: checkout_attempt_id}, {name: company, var: company}, {name: conversionId, var: conversion_id}, {name: countryCode, var: country_code}, {name: dateOfBirth, var: date_of_birth}, {name: dccQuote, var: dcc_quote}, {name: deliveryAddress, var: delivery_address}, {name: deliveryDate, var: delivery_date}, {name: deviceFingerprint, var: device_fingerprint}, {name: donationAccount, var: donation_account}, {name: donationOriginalPspReference, var: donation_original_psp_reference}, {name: donationToken, var: donation_token}, {name: enableOneClick, var: enable_one_click}, {name: enablePayOut, var: enable_pay_out}, {name: enableRecurring, var: enable_recurring}, {name: entityType, var: entity_type}, {name: fraudOffset, var: fraud_offset}, {name: industryUsage, var: industry_usage}, {name: installments, var: installments}, {name: lineItems, var: line_items}, {name: localizedShopperStatement, var: localized_shopper_statement}, {name: mandate, var: mandate}, {name: mcc, var: mcc}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: merchantRiskIndicator, var: merchant_risk_indicator}, {name: metadata, var: metadata}, {name: mpiData, var: mpi_data}, {name: order, var: order}, {name: orderReference, var: order_reference}, {name: origin, var: origin}, {name: paymentMethod, var: payment_method}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: recurringExpiry, var: recurring_expiry}, {name: recurringFrequency, var: recurring_frequency}, {name: recurringProcessingModel, var: recurring_processing_model}, {name: redirectFromIssuerMethod, var: redirect_from_issuer_method}, {name: redirectToIssuerMethod, var: redirect_to_issuer_method}, {name: reference, var: reference}, {name: returnUrl, var: return_url}, {name: riskData, var: risk_data}, {name: sessionValidity, var: session_validity}, {name: shopperEmail, var: shopper_email}, {name: shopperIP, var: shopper_ip}, {name: shopperInteraction, var: shopper_interaction}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: socialSecurityNumber, var: social_security_number}, {name: splits, var: splits}, {name: store, var: store}, {name: storePaymentMethod, var: store_payment_method}, {name: telephoneNumber, var: telephone_number}, {name: threeDS2RequestData, var: three_ds2_request_data}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}, {name: trustedShopper, var: trusted_shopper}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, account_info: $account_info, additional_amount: $additional_amount, additional_data: $additional_data, amount: $amount, application_info: $application_info, authentication_data: $authentication_data, billing_address: $billing_address, browser_info: $browser_info, capture_delay_hours: $capture_delay_hours, channel: $channel, checkout_attempt_id: $checkout_attempt_id, company: $company, conversion_id: $conversion_id, country_code: $country_code, date_of_birth: $date_of_birth, dcc_quote: $dcc_quote, delivery_address: $delivery_address, delivery_date: $delivery_date, device_fingerprint: $device_fingerprint, donation_account: $donation_account, donation_original_psp_reference: $donation_original_psp_reference, donation_token: $donation_token, enable_one_click: $enable_one_click, enable_pay_out: $enable_pay_out, enable_recurring: $enable_recurring, entity_type: $entity_type, fraud_offset: $fraud_offset, industry_usage: $industry_usage, installments: $installments, line_items: $line_items, localized_shopper_statement: $localized_shopper_statement, mandate: $mandate, mcc: $mcc, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, merchant_risk_indicator: $merchant_risk_indicator, metadata: $metadata, mpi_data: $mpi_data, order: $order, order_reference: $order_reference, origin: $origin, payment_method: $payment_method, platform_chargeback_logic: $platform_chargeback_logic, recurring_expiry: $recurring_expiry, recurring_frequency: $recurring_frequency, recurring_processing_model: $recurring_processing_model, redirect_from_issuer_method: $redirect_from_issuer_method, redirect_to_issuer_method: $redirect_to_issuer_method, reference: $reference, return_url: $return_url, risk_data: $risk_data, session_validity: $session_validity, shopper_email: $shopper_email, shopper_ip: $shopper_ip, shopper_interaction: $shopper_interaction, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, social_security_number: $social_security_number, splits: $splits, store: $store, store_payment_method: $store_payment_method, telephone_number: $telephone_number, three_ds2_request_data: $three_ds2_request_data, three_ds_authentication_only: $three_ds_authentication_only, trusted_shopper: $trusted_shopper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an order
#
# POST /orders
# Returns: record<additionalData: record, amount: record<currency: string, value: int>, expiresAt: string, fraudResult: record<accountScore: int, results: list<record>>, orderData: string, pspReference: string, reference: string, refusalReason: string, remainingAmount: record<currency: string, value: int>, resultCode: string>
# operationId: post-orders
export def "post-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  amount: record # shape: {currency: string, value: int}
  --expires-at: string # The date that order expires; e.g. 2019-03-23T12:25:28Z. If not provided, the default expiry duration is 1 day.
  merchant_account: string # The merchant account identifier, with which you want to process the order.
  reference: string # A custom reference identifying the order.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: expiresAt, var: expires_at}, {name: merchantAccount, var: merchant_account}, {name: reference, var: reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, amount: $amount, expires_at: $expires_at, merchant_account: $merchant_account, reference: $reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an order
#
# POST /orders/cancel
# Returns: record<pspReference: string, resultCode: string>
# operationId: post-orders-cancel
export def "post-orders-cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  merchant_account: string # The merchant account identifier that orderData belongs to.
  order: record # shape: {orderData: string, pspReference: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/cancel"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: merchantAccount, var: merchant_account}, {name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, merchant_account: $merchant_account, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create originKey values for domains
#
# POST /originKeys
# DEPRECATED
# Returns: record<originKeys: record>
# operationId: post-originKeys
@deprecated
export def "post-origin-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  origin_domains: list<string> # The list of origin domains, for which origin keys are requested.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/originKeys"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: originDomains, var: origin_domains}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, origin_domains: $origin_domains
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a payment link
#
# POST /paymentLinks
# Returns: record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, updatedAt: string, url: string>
# operationId: post-paymentLinks
export def "post-payment-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --allowed-payment-methods: list<string> # List of payment methods to be presented to the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types). Example: `"allowedPaymentMethods":["ideal","giropay"]`
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --blocked-payment-methods: list<string> # List of payment methods to be hidden from the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types). Example: `"blockedPaymentMethods":["ideal","giropay"]`
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --country-code: string # The shopper's two-letter country code.
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --deliver-at: string # The date and time when the purchased goods should be delivered. [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format: YYYY-MM-DDThh:mm:ss+TZD, for example, **2020-12-18T10:15:30+01:00**. (format: date-time)
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --description: string # A short description visible on the payment page. Maximum length: 280 characters.
  --expires-at: string # The date when the payment link expires. [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format: YYYY-MM-DDThh:mm:ss+TZD, for example, **2020-12-18T10:15:30+01:00**. The maximum expiry date is 70 days after the payment link is created. If not provided, the payment link expires 24 hours after it was created.
  --installment-options: record # A set of key-value pairs that specifies the installment options available per payment method. The key must be a payment method name in lowercase. For example, **card** to specify installment options for all cards, or **visa** or **mc**. The value must be an object containing the installment options.
  --line-items: list # Price and product information about the purchased items, to be included on the invoice sent to the shopper. This parameter is required for open invoice (_buy now, pay later_) payment methods such Afterpay, Clearpay, Klarna, RatePay, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  --manual-capture: oneof<nothing, bool> # Indicates if the payment must be [captured manually](https://docs.adyen.com/online-payments/capture).
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier for which the payment link is created.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (for example, order auth-rate). The reference should be unique per billing cycle.
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limitations: * Maximum 20 key-value pairs per request. Otherwise, error "177" occurs: "Metadata size exceeds limit" * Maximum 20 characters per key. Otherwise, error "178" occurs: "Metadata key size exceeds limit" * A key cannot have the name `checkout.linkId`. Any value that you provide with this key is going to be replaced by the real payment link ID.
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details. Possible values: * **Subscription** – A transaction for a fixed or variable amount, which follows a fixed schedule. * **CardOnFile** – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * **UnscheduledCardOnFile** – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or has variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  reference: string # A reference that is used to uniquely identify the payment in future communications about the payment status.
  --required-shopper-fields: list<string> # List of fields that the shopper has to provide on the payment page before completing the payment. For more information, refer to [Provide shopper information](https://docs.adyen.com/unified-commerce/pay-by-link/payment-links/api#shopper-information). Possible values: * **billingAddress** – The address where to send the invoice. * **deliveryAddress** – The address where the purchased goods should be delivered. * **shopperEmail** – The shopper's email address. * **shopperName** – The shopper's full name. * **telephoneNumber** – The shopper's phone number.
  --return-url: string # Website URL used for redirection after payment is completed. If provided, a **Continue** button will be shown on the payment page. If shoppers select the button, they are redirected to the specified URL.
  --reusable: oneof<nothing, bool> # Indicates whether the payment link can be reused for multiple payments. If not provided, this defaults to **false** which means the link can be used for one successful payment only.
  --risk-data: record # shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
  --shopper-email: string # The shopper's email address.
  --shopper-locale: string # The language to be used in the payment page, specified by a combination of a language and country code. For example, `en-US`. For a list of shopper locales that Pay by Link supports, refer to [Language and localization](https://docs.adyen.com/unified-commerce/pay-by-link/payment-links/api#language).
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopper-statement: string # The text to be shown on the shopper's bank statement. We recommend sending a maximum of 22 characters, otherwise banks might truncate the string. Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --show-remove-payment-method-button: oneof<nothing, bool> # Set to **false** to hide the button that lets the shopper remove a stored payment method. (default: true)
  --social-security-number: string # The shopper's social security number.
  --split-card-funding-sources: oneof<nothing, bool> # Boolean value indicating whether the card payment method should be split into separate debit and credit options. (default: false)
  --splits: list # An array of objects specifying how the payment should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --store: string # The physical store, for which this payment is processed.
  --store-payment-method-mode: string@store-payment-method-mode-completer # Indicates if the details of the payment method will be stored for the shopper. Possible values: * **disabled** – No details will be stored (default). * **askForConsent** – If the `shopperReference` is provided, the UI lets the shopper choose if they want their payment details to be stored. * **enabled** – If the `shopperReference` is provided, the details will be stored without asking the shopper for consent.
  --telephone-number: string # The shopper's telephone number.
  --theme-id: string # A [theme](https://docs.adyen.com/unified-commerce/pay-by-link/payment-links/api#themes) to customize the appearance of the payment page. If not specified, the payment page is rendered according to the theme set as default in your Customer Area.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paymentLinks"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowedPaymentMethods, var: allowed_payment_methods}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: billingAddress, var: billing_address}, {name: blockedPaymentMethods, var: blocked_payment_methods}, {name: captureDelayHours, var: capture_delay_hours}, {name: countryCode, var: country_code}, {name: dateOfBirth, var: date_of_birth}, {name: deliverAt, var: deliver_at}, {name: deliveryAddress, var: delivery_address}, {name: description, var: description}, {name: expiresAt, var: expires_at}, {name: installmentOptions, var: installment_options}, {name: lineItems, var: line_items}, {name: manualCapture, var: manual_capture}, {name: mcc, var: mcc}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: metadata, var: metadata}, {name: recurringProcessingModel, var: recurring_processing_model}, {name: reference, var: reference}, {name: requiredShopperFields, var: required_shopper_fields}, {name: returnUrl, var: return_url}, {name: reusable, var: reusable}, {name: riskData, var: risk_data}, {name: shopperEmail, var: shopper_email}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: showRemovePaymentMethodButton, var: show_remove_payment_method_button}, {name: socialSecurityNumber, var: social_security_number}, {name: splitCardFundingSources, var: split_card_funding_sources}, {name: splits, var: splits}, {name: store, var: store}, {name: storePaymentMethodMode, var: store_payment_method_mode}, {name: telephoneNumber, var: telephone_number}, {name: themeId, var: theme_id}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    idempotency_key: $idempotency_key, allowed_payment_methods: $allowed_payment_methods, amount: $amount, application_info: $application_info, billing_address: $billing_address, blocked_payment_methods: $blocked_payment_methods, capture_delay_hours: $capture_delay_hours, country_code: $country_code, date_of_birth: $date_of_birth, deliver_at: $deliver_at, delivery_address: $delivery_address, description: $description, expires_at: $expires_at, installment_options: $installment_options, line_items: $line_items, manual_capture: $manual_capture, mcc: $mcc, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, metadata: $metadata, recurring_processing_model: $recurring_processing_model, reference: $reference, required_shopper_fields: $required_shopper_fields, return_url: $return_url, reusable: $reusable, risk_data: $risk_data, shopper_email: $shopper_email, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, show_remove_payment_method_button: $show_remove_payment_method_button, social_security_number: $social_security_number, split_card_funding_sources: $split_card_funding_sources, splits: $splits, store: $store, store_payment_method_mode: $store_payment_method_mode, telephone_number: $telephone_number, theme_id: $theme_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a payment link
#
# GET /paymentLinks/{linkId}
# Returns: record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, updatedAt: string, url: string>
# operationId: get-paymentLinks-linkId
export def "get-payment-links-link-id" [
  link_id: string
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
    path: "/paymentLinks/{linkId}"
    path_params: [{name: linkId, var: link_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the status of a payment link
#
# PATCH /paymentLinks/{linkId}
# Returns: record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, updatedAt: string, url: string>
# operationId: patch-paymentLinks-linkId
export def "patch-payment-links-link-id" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer # Status of the payment link. Possible values: * **expired**
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/paymentLinks/{linkId}"
    path_params: [{name: linkId, var: link_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    link_id: $link_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of available payment methods
#
# POST /paymentMethods
# Returns: record<paymentMethods: table<brand: string, brands: list, configuration: record, fundingSource: string, group: record, inputDetails: list, issuers: list, name: string, type: string>, storedPaymentMethods: table<brand: string, expiryMonth: string, expiryYear: string, holderName: string, iban: string, id: string, lastFour: string, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, supportedRecurringProcessingModels: list, supportedShopperInteractions: list, type: string>>
# operationId: post-paymentMethods
export def "post-payment-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  --allowed-payment-methods: list<string> # List of payment methods to be presented to the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types). Example: `"allowedPaymentMethods":["ideal","giropay"]`
  --amount: record # shape: {currency: string, value: int}
  --blocked-payment-methods: list<string> # List of payment methods to be hidden from the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types). Example: `"blockedPaymentMethods":["ideal","giropay"]`
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field can be used for filtering out payment methods that are only available on specific platforms. Possible values: * iOS * Android * Web
  --country-code: string # The shopper's country code.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --order: record # shape: {orderData: string, pspReference: string}
  --shopper-locale: string # The combination of a language code and a country code to specify the language to be used in the payment.
  --shopper-reference: string # Required for recurring payments. Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --split-card-funding-sources: oneof<nothing, bool> # Boolean value indicating whether the card payment method should be split into separate debit and credit options. (default: false)
  --store: string # The ecommerce or point-of-sale store that is processing the payment. Used in [partner model integrations](https://docs.adyen.com/marketplaces-and-platforms/classic/platforms-for-partners#route-payments) for Adyen for Platforms.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paymentMethods"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalData, var: additional_data}, {name: allowedPaymentMethods, var: allowed_payment_methods}, {name: amount, var: amount}, {name: blockedPaymentMethods, var: blocked_payment_methods}, {name: channel, var: channel}, {name: countryCode, var: country_code}, {name: merchantAccount, var: merchant_account}, {name: order, var: order}, {name: shopperLocale, var: shopper_locale}, {name: shopperReference, var: shopper_reference}, {name: splitCardFundingSources, var: split_card_funding_sources}, {name: store, var: store}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, additional_data: $additional_data, allowed_payment_methods: $allowed_payment_methods, amount: $amount, blocked_payment_methods: $blocked_payment_methods, channel: $channel, country_code: $country_code, merchant_account: $merchant_account, order: $order, shopper_locale: $shopper_locale, shopper_reference: $shopper_reference, split_card_funding_sources: $split_card_funding_sources, store: $store
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the balance of a gift card
#
# POST /paymentMethods/balance
# Returns: record<additionalData: record, balance: record<currency: string, value: int>, fraudResult: record<accountScore: int, results: list<record>>, pspReference: string, refusalReason: string, resultCode: string, transactionLimit: record<currency: string, value: int>>
# operationId: post-paymentMethods-balance
@deprecated --flag three-ds-authentication-only
export def "post-payment-methods-balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
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
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  payment_method: record # The collection that contains the type of the payment method and its specific information.
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
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (DEPRECATED, default: false)
  --totals-group: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paymentMethods/balance"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountInfo, var: account_info}, {name: additionalAmount, var: additional_amount}, {name: additionalData, var: additional_data}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: billingAddress, var: billing_address}, {name: browserInfo, var: browser_info}, {name: captureDelayHours, var: capture_delay_hours}, {name: dateOfBirth, var: date_of_birth}, {name: dccQuote, var: dcc_quote}, {name: deliveryAddress, var: delivery_address}, {name: deliveryDate, var: delivery_date}, {name: deviceFingerprint, var: device_fingerprint}, {name: fraudOffset, var: fraud_offset}, {name: installments, var: installments}, {name: localizedShopperStatement, var: localized_shopper_statement}, {name: mcc, var: mcc}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: merchantRiskIndicator, var: merchant_risk_indicator}, {name: metadata, var: metadata}, {name: orderReference, var: order_reference}, {name: paymentMethod, var: payment_method}, {name: recurring, var: recurring}, {name: recurringProcessingModel, var: recurring_processing_model}, {name: reference, var: reference}, {name: selectedBrand, var: selected_brand}, {name: selectedRecurringDetailReference, var: selected_recurring_detail_reference}, {name: sessionId, var: session_id}, {name: shopperEmail, var: shopper_email}, {name: shopperIP, var: shopper_ip}, {name: shopperInteraction, var: shopper_interaction}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: socialSecurityNumber, var: social_security_number}, {name: splits, var: splits}, {name: store, var: store}, {name: telephoneNumber, var: telephone_number}, {name: threeDS2RequestData, var: three_ds2_request_data}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}, {name: totalsGroup, var: totals_group}, {name: trustedShopper, var: trusted_shopper}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, account_info: $account_info, additional_amount: $additional_amount, additional_data: $additional_data, amount: $amount, application_info: $application_info, billing_address: $billing_address, browser_info: $browser_info, capture_delay_hours: $capture_delay_hours, date_of_birth: $date_of_birth, dcc_quote: $dcc_quote, delivery_address: $delivery_address, delivery_date: $delivery_date, device_fingerprint: $device_fingerprint, fraud_offset: $fraud_offset, installments: $installments, localized_shopper_statement: $localized_shopper_statement, mcc: $mcc, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, merchant_risk_indicator: $merchant_risk_indicator, metadata: $metadata, order_reference: $order_reference, payment_method: $payment_method, recurring: $recurring, recurring_processing_model: $recurring_processing_model, reference: $reference, selected_brand: $selected_brand, selected_recurring_detail_reference: $selected_recurring_detail_reference, session_id: $session_id, shopper_email: $shopper_email, shopper_ip: $shopper_ip, shopper_interaction: $shopper_interaction, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, social_security_number: $social_security_number, splits: $splits, store: $store, telephone_number: $telephone_number, three_ds2_request_data: $three_ds2_request_data, three_ds_authentication_only: $three_ds_authentication_only, totals_group: $totals_group, trusted_shopper: $trusted_shopper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a payment session
#
# POST /paymentSession
# DEPRECATED
# Returns: record<paymentSession: string, recurringDetails: table<brand: string, brands: list, configuration: record, fundingSource: string, group: record, inputDetails: list, issuers: list, name: string, recurringDetailReference: string, storedDetails: record, type: string>>
# operationId: post-paymentSession
@deprecated
@deprecated --flag conversion-id
@deprecated --flag three-ds-authentication-only
export def "post-payment-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  --allowed-payment-methods: list<string> # List of payment methods to be presented to the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types). Example: `"allowedPaymentMethods":["ideal","giropay"]`
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --blocked-payment-methods: list<string> # List of payment methods to be hidden from the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types). Example: `"blockedPaymentMethods":["ideal","giropay"]`
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field is optional for filtering out payment methods that are only available on specific platforms. If this value is not set, then we will try to infer it from the `sdkVersion` or `token`. Possible values: * iOS * Android * Web
  --checkout-attempt-id: string # Checkout attempt ID that corresponds to the Id generated by the client SDK for tracking user payment journey.
  --company: record # shape: {homepage?: string, name?: string, registrationNumber?: string, registryLocation?: string, taxId?: string, type?: string}
  --configuration: record # shape: {avs?: record, cardHolderName?: "NONE"|"OPTIONAL"|"REQUIRED", installments?: record, shopperInput?: record}
  --conversion-id: string # Conversion ID that corresponds to the Id generated by the client SDK for tracking user payment journey. (DEPRECATED)
  country_code: string # The shopper country. Format: [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) Example: NL or DE
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --enable-one-click: oneof<nothing, bool> # When true and `shopperReference` is provided, the shopper will be asked if the payment details should be stored for future one-click payments.
  --enable-pay-out: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for payouts.
  --enable-recurring: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for recurring payments.
  --entity-type: string@entity-type-completer # The type of the entity the payment is processed for.
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --line-items: list # Price and product information of the refunded items, required for [partial refunds](https://docs.adyen.com/online-payments/refund#refund-a-payment). > This field is required for partial refunds with 3x 4x Oney, Affirm, Afterpay, Atome, Clearpay, Klarna, Ratepay, Walley, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --origin: string # Required for the Web integration. Set this parameter to the origin URL of the page that you are loading the SDK from.
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurring-expiry: string # Date after which no further authorisations shall be performed. Only for 3D Secure 2.
  --recurring-frequency: string # Minimum number of days between authorisations. Only for 3D Secure 2.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  return_url: string # The URL to return to in case of a redirection. The format depends on the channel. This URL can have a maximum of 1024 characters. * For web, include the protocol `http://` or `https://`. You can also include your own additional query parameters, for example, shopper ID or order reference number. Example: `https://your-company.com/checkout?shopperOrder=12xy` * For iOS, use the custom URL for your app. To know more about setting custom URL schemes, refer to the [Apple Developer documentation](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app). Example: `my-app://` * For Android, use a custom URL handled by an Activity on your app. You can configure it with an [intent filter](https://developer.android.com/guide/components/intents-filters). Example: `my-app://your.package.name`
  --risk-data: record # shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
  --sdk-version: string # The version of the SDK you are using (for Web SDK integrations only).
  --session-validity: string # The date and time until when the session remains valid, in [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format. For example: 2020-07-18T15:42:40.428+01:00
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
  --store-payment-method: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be stored.
  --telephone-number: string # The shopper's telephone number.
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (DEPRECATED, default: false)
  --body-token: string # The token obtained when initializing the SDK. > This parameter is required for iOS and Android; not required for Web. (spec name: token)
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paymentSession"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalAmount, var: additional_amount}, {name: additionalData, var: additional_data}, {name: allowedPaymentMethods, var: allowed_payment_methods}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: billingAddress, var: billing_address}, {name: blockedPaymentMethods, var: blocked_payment_methods}, {name: captureDelayHours, var: capture_delay_hours}, {name: channel, var: channel}, {name: checkoutAttemptId, var: checkout_attempt_id}, {name: company, var: company}, {name: configuration, var: configuration}, {name: conversionId, var: conversion_id}, {name: countryCode, var: country_code}, {name: dateOfBirth, var: date_of_birth}, {name: dccQuote, var: dcc_quote}, {name: deliveryAddress, var: delivery_address}, {name: deliveryDate, var: delivery_date}, {name: enableOneClick, var: enable_one_click}, {name: enablePayOut, var: enable_pay_out}, {name: enableRecurring, var: enable_recurring}, {name: entityType, var: entity_type}, {name: fraudOffset, var: fraud_offset}, {name: installments, var: installments}, {name: lineItems, var: line_items}, {name: localizedShopperStatement, var: localized_shopper_statement}, {name: mandate, var: mandate}, {name: mcc, var: mcc}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: metadata, var: metadata}, {name: orderReference, var: order_reference}, {name: origin, var: origin}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: recurringExpiry, var: recurring_expiry}, {name: recurringFrequency, var: recurring_frequency}, {name: reference, var: reference}, {name: returnUrl, var: return_url}, {name: riskData, var: risk_data}, {name: sdkVersion, var: sdk_version}, {name: sessionValidity, var: session_validity}, {name: shopperEmail, var: shopper_email}, {name: shopperIP, var: shopper_ip}, {name: shopperInteraction, var: shopper_interaction}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: socialSecurityNumber, var: social_security_number}, {name: splits, var: splits}, {name: store, var: store}, {name: storePaymentMethod, var: store_payment_method}, {name: telephoneNumber, var: telephone_number}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}, {name: token, var: body_token}, {name: trustedShopper, var: trusted_shopper}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, additional_amount: $additional_amount, additional_data: $additional_data, allowed_payment_methods: $allowed_payment_methods, amount: $amount, application_info: $application_info, billing_address: $billing_address, blocked_payment_methods: $blocked_payment_methods, capture_delay_hours: $capture_delay_hours, channel: $channel, checkout_attempt_id: $checkout_attempt_id, company: $company, configuration: $configuration, conversion_id: $conversion_id, country_code: $country_code, date_of_birth: $date_of_birth, dcc_quote: $dcc_quote, delivery_address: $delivery_address, delivery_date: $delivery_date, enable_one_click: $enable_one_click, enable_pay_out: $enable_pay_out, enable_recurring: $enable_recurring, entity_type: $entity_type, fraud_offset: $fraud_offset, installments: $installments, line_items: $line_items, localized_shopper_statement: $localized_shopper_statement, mandate: $mandate, mcc: $mcc, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, metadata: $metadata, order_reference: $order_reference, origin: $origin, platform_chargeback_logic: $platform_chargeback_logic, recurring_expiry: $recurring_expiry, recurring_frequency: $recurring_frequency, reference: $reference, return_url: $return_url, risk_data: $risk_data, sdk_version: $sdk_version, session_validity: $session_validity, shopper_email: $shopper_email, shopper_ip: $shopper_ip, shopper_interaction: $shopper_interaction, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, social_security_number: $social_security_number, splits: $splits, store: $store, store_payment_method: $store_payment_method, telephone_number: $telephone_number, three_ds_authentication_only: $three_ds_authentication_only, body_token: $body_token, trusted_shopper: $trusted_shopper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a transaction
#
# POST /payments
# Returns: record<action: any, additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list<record>>, merchantReference: string, order: record<amount: record<currency: string, value: int>, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record<currency: string, value: int>>, paymentMethod: record<brand: string, type: string>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string>
# operationId: post-payments
@deprecated --flag conversion-id
@deprecated --flag three-ds-authentication-only
export def "post-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --authentication-data: record # shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browser-info: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field is optional for filtering out payment methods that are only available on specific platforms. If this value is not set, then we will try to infer it from the `sdkVersion` or `token`. Possible values: * iOS * Android * Web
  --checkout-attempt-id: string # Checkout attempt ID that corresponds to the Id generated by the client SDK for tracking user payment journey.
  --company: record # shape: {homepage?: string, name?: string, registrationNumber?: string, registryLocation?: string, taxId?: string, type?: string}
  --conversion-id: string # Conversion ID that corresponds to the Id generated by the client SDK for tracking user payment journey. (DEPRECATED)
  --country-code: string # The shopper country. Format: [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) Example: NL or DE
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --device-fingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --enable-one-click: oneof<nothing, bool> # When true and `shopperReference` is provided, the shopper will be asked if the payment details should be stored for future one-click payments.
  --enable-pay-out: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for payouts.
  --enable-recurring: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for recurring payments.
  --entity-type: string@entity-type-completer # The type of the entity the payment is processed for.
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --industry-usage: string@industry-usage-completer # The reason for the amount update. Possible values: * **delayedCharge** * **noShow** * **installment**
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --line-items: list # Price and product information of the refunded items, required for [partial refunds](https://docs.adyen.com/online-payments/refund#refund-a-payment). > This field is required for partial refunds with 3x 4x Oney, Affirm, Afterpay, Atome, Clearpay, Klarna, Ratepay, Walley, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --order: record # shape: {orderData: string, pspReference: string}
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --origin: string # Required for the 3D Secure 2 `channel` **Web** integration. Set this parameter to the origin URL of the page that you are loading the 3D Secure Component from.
  payment_method: any # The type and required details of a payment method to use.
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurring-expiry: string # Date after which no further authorisations shall be performed. Only for 3D Secure 2.
  --recurring-frequency: string # Minimum number of days between authorisations. Only for 3D Secure 2.
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --redirect-from-issuer-method: string # Specifies the redirect method (GET or POST) when redirecting back from the issuer.
  --redirect-to-issuer-method: string # Specifies the redirect method (GET or POST) when redirecting to the issuer.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  return_url: string # The URL to return to in case of a redirection. The format depends on the channel. This URL can have a maximum of 1024 characters. * For web, include the protocol `http://` or `https://`. You can also include your own additional query parameters, for example, shopper ID or order reference number. Example: `https://your-company.com/checkout?shopperOrder=12xy` * For iOS, use the custom URL for your app. To know more about setting custom URL schemes, refer to the [Apple Developer documentation](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app). Example: `my-app://` * For Android, use a custom URL handled by an Activity on your app. You can configure it with an [intent filter](https://developer.android.com/guide/components/intents-filters). Example: `my-app://your.package.name`
  --risk-data: record # shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
  --session-validity: string # The date and time until when the session remains valid, in [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format. For example: 2020-07-18T15:42:40.428+01:00
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
  --store-payment-method: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be stored.
  --telephone-number: string # The shopper's telephone number.
  --three-ds2-request-data: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (DEPRECATED, default: false)
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payments"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountInfo, var: account_info}, {name: additionalAmount, var: additional_amount}, {name: additionalData, var: additional_data}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: authenticationData, var: authentication_data}, {name: billingAddress, var: billing_address}, {name: browserInfo, var: browser_info}, {name: captureDelayHours, var: capture_delay_hours}, {name: channel, var: channel}, {name: checkoutAttemptId, var: checkout_attempt_id}, {name: company, var: company}, {name: conversionId, var: conversion_id}, {name: countryCode, var: country_code}, {name: dateOfBirth, var: date_of_birth}, {name: dccQuote, var: dcc_quote}, {name: deliveryAddress, var: delivery_address}, {name: deliveryDate, var: delivery_date}, {name: deviceFingerprint, var: device_fingerprint}, {name: enableOneClick, var: enable_one_click}, {name: enablePayOut, var: enable_pay_out}, {name: enableRecurring, var: enable_recurring}, {name: entityType, var: entity_type}, {name: fraudOffset, var: fraud_offset}, {name: industryUsage, var: industry_usage}, {name: installments, var: installments}, {name: lineItems, var: line_items}, {name: localizedShopperStatement, var: localized_shopper_statement}, {name: mandate, var: mandate}, {name: mcc, var: mcc}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: merchantRiskIndicator, var: merchant_risk_indicator}, {name: metadata, var: metadata}, {name: mpiData, var: mpi_data}, {name: order, var: order}, {name: orderReference, var: order_reference}, {name: origin, var: origin}, {name: paymentMethod, var: payment_method}, {name: platformChargebackLogic, var: platform_chargeback_logic}, {name: recurringExpiry, var: recurring_expiry}, {name: recurringFrequency, var: recurring_frequency}, {name: recurringProcessingModel, var: recurring_processing_model}, {name: redirectFromIssuerMethod, var: redirect_from_issuer_method}, {name: redirectToIssuerMethod, var: redirect_to_issuer_method}, {name: reference, var: reference}, {name: returnUrl, var: return_url}, {name: riskData, var: risk_data}, {name: sessionValidity, var: session_validity}, {name: shopperEmail, var: shopper_email}, {name: shopperIP, var: shopper_ip}, {name: shopperInteraction, var: shopper_interaction}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: socialSecurityNumber, var: social_security_number}, {name: splits, var: splits}, {name: store, var: store}, {name: storePaymentMethod, var: store_payment_method}, {name: telephoneNumber, var: telephone_number}, {name: threeDS2RequestData, var: three_ds2_request_data}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}, {name: trustedShopper, var: trusted_shopper}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, account_info: $account_info, additional_amount: $additional_amount, additional_data: $additional_data, amount: $amount, application_info: $application_info, authentication_data: $authentication_data, billing_address: $billing_address, browser_info: $browser_info, capture_delay_hours: $capture_delay_hours, channel: $channel, checkout_attempt_id: $checkout_attempt_id, company: $company, conversion_id: $conversion_id, country_code: $country_code, date_of_birth: $date_of_birth, dcc_quote: $dcc_quote, delivery_address: $delivery_address, delivery_date: $delivery_date, device_fingerprint: $device_fingerprint, enable_one_click: $enable_one_click, enable_pay_out: $enable_pay_out, enable_recurring: $enable_recurring, entity_type: $entity_type, fraud_offset: $fraud_offset, industry_usage: $industry_usage, installments: $installments, line_items: $line_items, localized_shopper_statement: $localized_shopper_statement, mandate: $mandate, mcc: $mcc, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, merchant_risk_indicator: $merchant_risk_indicator, metadata: $metadata, mpi_data: $mpi_data, order: $order, order_reference: $order_reference, origin: $origin, payment_method: $payment_method, platform_chargeback_logic: $platform_chargeback_logic, recurring_expiry: $recurring_expiry, recurring_frequency: $recurring_frequency, recurring_processing_model: $recurring_processing_model, redirect_from_issuer_method: $redirect_from_issuer_method, redirect_to_issuer_method: $redirect_to_issuer_method, reference: $reference, return_url: $return_url, risk_data: $risk_data, session_validity: $session_validity, shopper_email: $shopper_email, shopper_ip: $shopper_ip, shopper_interaction: $shopper_interaction, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, social_security_number: $social_security_number, splits: $splits, store: $store, store_payment_method: $store_payment_method, telephone_number: $telephone_number, three_ds2_request_data: $three_ds2_request_data, three_ds_authentication_only: $three_ds_authentication_only, trusted_shopper: $trusted_shopper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit details for a payment
#
# POST /payments/details
# Returns: record<additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list<record>>, merchantReference: string, order: record<amount: record<currency: string, value: int>, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record<currency: string, value: int>>, paymentMethod: record<brand: string, type: string>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, shopperLocale: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string>
# operationId: post-payments-details
@deprecated --flag three-ds-authentication-only
export def "post-payments-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --authentication-data: record # shape: {authenticationOnly?: bool}
  details: record # shape: {MD?: string, PaReq?: string, PaRes?: string, billingToken?: string, cupsecureplus.smscode?: string, facilitatorAccessToken?: string, oneTimePasscode?: string, orderID?: string, payerID?: string, payload?: string, paymentID?: string, paymentStatus?: string, redirectResult?: string, resultCode?: string, threeDSResult?: string, threeds2.challengeResult?: string, threeds2.fingerprint?: string}
  --payment-data: string # The `paymentData` value from the `/payments` response. Required if the `/payments` response returns this value.
  --three-ds-authentication-only: oneof<nothing, bool> # Change the `authenticationOnly` indicator originally set in the `/payments` request. Only needs to be set if you want to modify the value set previously. (DEPRECATED)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payments/details"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: authenticationData, var: authentication_data}, {name: details, var: details}, {name: paymentData, var: payment_data}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, authentication_data: $authentication_data, details: $details, payment_data: $payment_data, three_ds_authentication_only: $three_ds_authentication_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify a payment result
#
# POST /payments/result
# DEPRECATED
# Returns: record<additionalData: record, fraudResult: record<accountScore: int, results: list<record>>, merchantReference: string, order: record<amount: record<currency: string, value: int>, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record<currency: string, value: int>>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, serviceError: record<errorCode: string, errorType: string, message: string, pspReference: string>, shopperLocale: string>
# operationId: post-payments-result
@deprecated
export def "post-payments-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  payload: string # Encrypted and signed payment result data. You should receive this value from the Checkout SDK after the shopper completes the payment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payments/result"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: payload, var: payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    idempotency_key: $idempotency_key, payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an authorised amount
#
# POST /payments/{paymentPspReference}/amountUpdates
# Returns: record<amount: record<currency: string, value: int>, industryUsage: string, merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string>
# operationId: post-payments-paymentPspReference-amountUpdates
export def "post-payments-payment-psp-reference-amount-updates" [
  payment_psp_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  amount: record # shape: {currency: string, value: int}
  --industry-usage: string@industry-usage-completer # The reason for the amount update. Possible values: * **delayedCharge** * **noShow** * **installment**
  merchant_account: string # The merchant account that is used to process the payment.
  --reference: string # Your reference for the amount update request. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payments/{paymentPspReference}/amountUpdates"
    path_params: [{name: paymentPspReference, var: payment_psp_reference}]
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: industryUsage, var: industry_usage}, {name: merchantAccount, var: merchant_account}, {name: reference, var: reference}, {name: splits, var: splits}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    payment_psp_reference: $payment_psp_reference, idempotency_key: $idempotency_key, amount: $amount, industry_usage: $industry_usage, merchant_account: $merchant_account, reference: $reference, splits: $splits
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an authorised payment
#
# POST /payments/{paymentPspReference}/cancels
# Returns: record<merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, status: string>
# operationId: post-payments-paymentPspReference-cancels
export def "post-payments-payment-psp-reference-cancels" [
  payment_psp_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  merchant_account: string # The merchant account that is used to process the payment.
  --reference: string # Your reference for the cancel request. Maximum length: 80 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payments/{paymentPspReference}/cancels"
    path_params: [{name: paymentPspReference, var: payment_psp_reference}]
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: merchantAccount, var: merchant_account}, {name: reference, var: reference}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    payment_psp_reference: $payment_psp_reference, idempotency_key: $idempotency_key, merchant_account: $merchant_account, reference: $reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Capture an authorised payment
#
# POST /payments/{paymentPspReference}/captures
# Returns: record<amount: record<currency: string, value: int>, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string>
# operationId: post-payments-paymentPspReference-captures
export def "post-payments-payment-psp-reference-captures" [
  payment_psp_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  amount: record # shape: {currency: string, value: int}
  --line-items: list # Price and product information of the refunded items, required for [partial refunds](https://docs.adyen.com/online-payments/refund#refund-a-payment). > This field is required for partial refunds with 3x 4x Oney, Affirm, Afterpay, Atome, Clearpay, Klarna, Ratepay, Walley, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  merchant_account: string # The merchant account that is used to process the payment.
  --reference: string # Your reference for the capture request. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payments/{paymentPspReference}/captures"
    path_params: [{name: paymentPspReference, var: payment_psp_reference}]
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: lineItems, var: line_items}, {name: merchantAccount, var: merchant_account}, {name: reference, var: reference}, {name: splits, var: splits}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    payment_psp_reference: $payment_psp_reference, idempotency_key: $idempotency_key, amount: $amount, line_items: $line_items, merchant_account: $merchant_account, reference: $reference, splits: $splits
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refund a captured payment
#
# POST /payments/{paymentPspReference}/refunds
# Returns: record<amount: record<currency: string, value: int>, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, merchantAccount: string, merchantRefundReason: string, paymentPspReference: string, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string>
# operationId: post-payments-paymentPspReference-refunds
export def "post-payments-payment-psp-reference-refunds" [
  payment_psp_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  amount: record # shape: {currency: string, value: int}
  --line-items: list # Price and product information of the refunded items, required for [partial refunds](https://docs.adyen.com/online-payments/refund#refund-a-payment). > This field is required for partial refunds with 3x 4x Oney, Affirm, Afterpay, Atome, Clearpay, Klarna, Ratepay, Walley, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  merchant_account: string # The merchant account that is used to process the payment.
  --merchant-refund-reason: string@merchant-refund-reason-completer # Your reason for the refund request
  --reference: string # Your reference for the refund request. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payments/{paymentPspReference}/refunds"
    path_params: [{name: paymentPspReference, var: payment_psp_reference}]
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: lineItems, var: line_items}, {name: merchantAccount, var: merchant_account}, {name: merchantRefundReason, var: merchant_refund_reason}, {name: reference, var: reference}, {name: splits, var: splits}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    payment_psp_reference: $payment_psp_reference, idempotency_key: $idempotency_key, amount: $amount, line_items: $line_items, merchant_account: $merchant_account, merchant_refund_reason: $merchant_refund_reason, reference: $reference, splits: $splits
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refund or cancel a payment
#
# POST /payments/{paymentPspReference}/reversals
# Returns: record<merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, status: string>
# operationId: post-payments-paymentPspReference-reversals
export def "post-payments-payment-psp-reference-reversals" [
  payment_psp_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  merchant_account: string # The merchant account that is used to process the payment.
  --reference: string # Your reference for the reversal request. Maximum length: 80 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payments/{paymentPspReference}/reversals"
    path_params: [{name: paymentPspReference, var: payment_psp_reference}]
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: merchantAccount, var: merchant_account}, {name: reference, var: reference}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    payment_psp_reference: $payment_psp_reference, idempotency_key: $idempotency_key, merchant_account: $merchant_account, reference: $reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a payment session
#
# POST /sessions
# Returns: record<accountInfo: record<accountAgeIndicator: string, accountChangeDate: string, accountChangeIndicator: string, accountCreationDate: string, accountType: string, addCardAttemptsDay: int, deliveryAddressUsageDate: string, deliveryAddressUsageIndicator: string, homePhone: string, mobilePhone: string, passwordChangeDate: string, passwordChangeIndicator: string, pastTransactionsDay: int, pastTransactionsYear: int, paymentAccountAge: string, paymentAccountIndicator: string, purchasesLast6Months: int, suspiciousActivity: bool, workPhone: string>, additionalAmount: record<currency: string, value: int>, additionalData: record, allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, authenticationData: record<attemptAuthentication: string, authenticationOnly: bool, threeDSRequestData: record<challengeWindowSize: string, dataOnly: string, nativeThreeDS: string, threeDSVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, channel: string, company: record<homepage: string, name: string, registrationNumber: string, registryLocation: string, taxId: string, type: string>, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, enableOneClick: bool, enablePayOut: bool, enableRecurring: bool, expiresAt: string, fundOrigin: record<billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, shopperName: record<firstName: string, lastName: string>>, fundRecipient: record<billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, paymentMethod: record<brand: string, checkoutAttemptId: string, "cupsecureplus.smscode": string, cvc: string, encryptedCardNumber: string, encryptedExpiryMonth: string, encryptedExpiryYear: string, encryptedSecurityCode: string, expiryMonth: string, expiryYear: string, fundingSource: string, holderName: string, networkPaymentReference: string, number: string, recurringDetailReference: string, shopperNotificationReference: string, storedPaymentMethodId: string, threeDS2SdkVersion: string, type: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, storedPaymentMethodId: string, subMerchant: record<city: string, country: string, mcc: string, name: string, taxId: string>, telephoneNumber: string, walletIdentifier: string, walletOwnerTaxId: string>, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, mandate: record<amount: string, amountRule: string, billingAttemptsRule: string, billingDay: string, endsAt: string, frequency: string, remarks: string, startsAt: string>, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, mode: string, mpiData: record<authenticationResponse: string, cavv: string, cavvAlgorithm: string, challengeCancel: string, directoryResponse: string, dsTransID: string, eci: string, riskScore: string, threeDSVersion: string, tokenAuthenticationVerificationValue: string, transStatusReason: string, xid: string>, recurringExpiry: string, recurringFrequency: string, recurringProcessingModel: string, redirectFromIssuerMethod: string, redirectToIssuerMethod: string, reference: string, returnUrl: string, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, sessionData: string, shopperEmail: string, shopperIP: string, shopperInteraction: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, store: string, storePaymentMethod: bool, storePaymentMethodMode: string, telephoneNumber: string, threeDSAuthenticationOnly: bool, trustedShopper: bool>
# operationId: post-sessions
@deprecated --flag three-ds-authentication-only
export def "post-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  --allowed-payment-methods: list<string> # List of payment methods to be presented to the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types). Example: `"allowedPaymentMethods":["ideal","giropay"]`
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --authentication-data: record # shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --blocked-payment-methods: list<string> # List of payment methods to be hidden from the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types). Example: `"blockedPaymentMethods":["ideal","giropay"]`
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field is optional for filtering out payment methods that are only available on specific platforms. If this value is not set, then we will try to infer it from the `sdkVersion` or `token`. Possible values: * **iOS** * **Android** * **Web**
  --company: record # shape: {homepage?: string, name?: string, registrationNumber?: string, registryLocation?: string, taxId?: string, type?: string}
  --country-code: string # The shopper's two-letter country code.
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --deliver-at: string # The date and time when the purchased goods should be delivered. [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format: YYYY-MM-DDThh:mm:ss+TZD, for example, **2020-12-18T10:15:30+01:00**. (format: date-time)
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --enable-one-click: oneof<nothing, bool> # When true and `shopperReference` is provided, the shopper will be asked if the payment details should be stored for future one-click payments.
  --enable-pay-out: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for payouts.
  --enable-recurring: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for recurring payments.
  --expires-at: string # The date the session expires in [ISO8601](https://www.iso.org/iso-8601-date-and-time-format.html) format. When not specified, the expiry date is set to 1 hour after session creation. You cannot set the session expiry to more than 24 hours after session creation. (format: date-time)
  --fund-origin: record # shape: {billingAddress?: record, shopperName?: record}
  --fund-recipient: record # shape: {billingAddress?: record, paymentMethod?: record, shopperEmail?: string, shopperName?: record, shopperReference?: string, storedPaymentMethodId?: string, subMerchant?: record, telephoneNumber?: string, walletIdentifier?: string, walletOwnerTaxId?: string}
  --installment-options: record # A set of key-value pairs that specifies the installment options available per payment method. The key must be a payment method name in lowercase. For example, **card** to specify installment options for all cards, or **visa** or **mc**. The value must be an object containing the installment options.
  --line-items: list # Price and product information about the purchased items, to be included on the invoice sent to the shopper. > This field is required for 3x 4x Oney, Affirm, Afterpay, Clearpay, Klarna, Ratepay, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. * Maximum 20 characters per key. * Maximum 80 characters per value.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --recurring-expiry: string # Date after which no further authorisations shall be performed. Only for 3D Secure 2.
  --recurring-frequency: string # Minimum number of days between authorisations. Only for 3D Secure 2.
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --redirect-from-issuer-method: string # Specifies the redirect method (GET or POST) when redirecting back from the issuer.
  --redirect-to-issuer-method: string # Specifies the redirect method (GET or POST) when redirecting to the issuer.
  reference: string # The reference to uniquely identify a payment.
  return_url: string # The URL to return to when a redirect payment is completed.
  --risk-data: record # shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
  --shopper-email: string # The shopper's email address.
  --shopper-ip: string # The shopper's IP address. In general, we recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > For 3D Secure 2 transactions, schemes require `shopperIP` for all browser-based implementations. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopper-interaction: string@shopper-interaction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default. This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopper-locale: string # The combination of a language code and a country code to specify the language to be used in the payment.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopper-statement: string # The text to be shown on the shopper's bank statement. We recommend sending a maximum of 22 characters, otherwise banks might truncate the string. Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --social-security-number: string # The shopper's social security number.
  --split-card-funding-sources: oneof<nothing, bool> # Boolean value indicating whether the card payment method should be split into separate debit and credit options. (default: false)
  --splits: list # An array of objects specifying how the payment should be split when using [Adyen for Platforms](https://docs.adyen.com/platforms/processing-payments#providing-split-information) or [Issuing](https://docs.adyen.com/issuing/manage-funds#split). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --store: string # The ecommerce or point-of-sale store that is processing the payment.
  --store-payment-method: oneof<nothing, bool> # When this is set to **true** and the `shopperReference` is provided, the payment details will be stored.
  --store-payment-method-mode: string@store-payment-method-mode-completer # Indicates if the details of the payment method will be stored for the shopper. Possible values: * **disabled** – No details will be stored (default). * **askForConsent** – If the `shopperReference` is provided, the UI lets the shopper choose if they want their payment details to be stored. * **enabled** – If the `shopperReference` is provided, the details will be stored without asking the shopper for consent.
  --telephone-number: string # The shopper's telephone number.
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (DEPRECATED, default: false)
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sessions"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountInfo, var: account_info}, {name: additionalAmount, var: additional_amount}, {name: additionalData, var: additional_data}, {name: allowedPaymentMethods, var: allowed_payment_methods}, {name: amount, var: amount}, {name: applicationInfo, var: application_info}, {name: authenticationData, var: authentication_data}, {name: billingAddress, var: billing_address}, {name: blockedPaymentMethods, var: blocked_payment_methods}, {name: captureDelayHours, var: capture_delay_hours}, {name: channel, var: channel}, {name: company, var: company}, {name: countryCode, var: country_code}, {name: dateOfBirth, var: date_of_birth}, {name: deliverAt, var: deliver_at}, {name: deliveryAddress, var: delivery_address}, {name: enableOneClick, var: enable_one_click}, {name: enablePayOut, var: enable_pay_out}, {name: enableRecurring, var: enable_recurring}, {name: expiresAt, var: expires_at}, {name: fundOrigin, var: fund_origin}, {name: fundRecipient, var: fund_recipient}, {name: installmentOptions, var: installment_options}, {name: lineItems, var: line_items}, {name: mandate, var: mandate}, {name: mcc, var: mcc}, {name: merchantAccount, var: merchant_account}, {name: merchantOrderReference, var: merchant_order_reference}, {name: metadata, var: metadata}, {name: mpiData, var: mpi_data}, {name: recurringExpiry, var: recurring_expiry}, {name: recurringFrequency, var: recurring_frequency}, {name: recurringProcessingModel, var: recurring_processing_model}, {name: redirectFromIssuerMethod, var: redirect_from_issuer_method}, {name: redirectToIssuerMethod, var: redirect_to_issuer_method}, {name: reference, var: reference}, {name: returnUrl, var: return_url}, {name: riskData, var: risk_data}, {name: shopperEmail, var: shopper_email}, {name: shopperIP, var: shopper_ip}, {name: shopperInteraction, var: shopper_interaction}, {name: shopperLocale, var: shopper_locale}, {name: shopperName, var: shopper_name}, {name: shopperReference, var: shopper_reference}, {name: shopperStatement, var: shopper_statement}, {name: socialSecurityNumber, var: social_security_number}, {name: splitCardFundingSources, var: split_card_funding_sources}, {name: splits, var: splits}, {name: store, var: store}, {name: storePaymentMethod, var: store_payment_method}, {name: storePaymentMethodMode, var: store_payment_method_mode}, {name: telephoneNumber, var: telephone_number}, {name: threeDSAuthenticationOnly, var: three_ds_authentication_only}, {name: trustedShopper, var: trusted_shopper}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    idempotency_key: $idempotency_key, account_info: $account_info, additional_amount: $additional_amount, additional_data: $additional_data, allowed_payment_methods: $allowed_payment_methods, amount: $amount, application_info: $application_info, authentication_data: $authentication_data, billing_address: $billing_address, blocked_payment_methods: $blocked_payment_methods, capture_delay_hours: $capture_delay_hours, channel: $channel, company: $company, country_code: $country_code, date_of_birth: $date_of_birth, deliver_at: $deliver_at, delivery_address: $delivery_address, enable_one_click: $enable_one_click, enable_pay_out: $enable_pay_out, enable_recurring: $enable_recurring, expires_at: $expires_at, fund_origin: $fund_origin, fund_recipient: $fund_recipient, installment_options: $installment_options, line_items: $line_items, mandate: $mandate, mcc: $mcc, merchant_account: $merchant_account, merchant_order_reference: $merchant_order_reference, metadata: $metadata, mpi_data: $mpi_data, recurring_expiry: $recurring_expiry, recurring_frequency: $recurring_frequency, recurring_processing_model: $recurring_processing_model, redirect_from_issuer_method: $redirect_from_issuer_method, redirect_to_issuer_method: $redirect_to_issuer_method, reference: $reference, return_url: $return_url, risk_data: $risk_data, shopper_email: $shopper_email, shopper_ip: $shopper_ip, shopper_interaction: $shopper_interaction, shopper_locale: $shopper_locale, shopper_name: $shopper_name, shopper_reference: $shopper_reference, shopper_statement: $shopper_statement, social_security_number: $social_security_number, split_card_funding_sources: $split_card_funding_sources, splits: $splits, store: $store, store_payment_method: $store_payment_method, store_payment_method_mode: $store_payment_method_mode, telephone_number: $telephone_number, three_ds_authentication_only: $three_ds_authentication_only, trusted_shopper: $trusted_shopper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tokens for stored payment details
#
# GET /storedPaymentMethods
# Returns: record<merchantAccount: string, shopperReference: string, storedPaymentMethods: table<brand: string, expiryMonth: string, expiryYear: string, externalResponseCode: string, externalTokenReference: string, holderName: string, iban: string, id: string, issuerName: string, lastFour: string, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, shopperReference: string, supportedRecurringProcessingModels: list, type: string>>
# operationId: get-storedPaymentMethods
export def "get-stored-payment-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shopper-reference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --merchant-account: string # Your merchant account.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/storedPaymentMethods"
    query: [{name: shopperReference, var: shopper_reference}, {name: merchantAccount, var: merchant_account}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    shopper_reference: $shopper_reference, merchant_account: $merchant_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a token for stored payment details
#
# DELETE /storedPaymentMethods/{recurringId}
# Returns: record<brand: string, expiryMonth: string, expiryYear: string, externalResponseCode: string, externalTokenReference: string, holderName: string, iban: string, id: string, issuerName: string, lastFour: string, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, shopperReference: string, supportedRecurringProcessingModels: list<string>, type: string>
# operationId: delete-storedPaymentMethods-recurringId
export def "delete-stored-payment-methods-recurring-id" [
  recurring_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shopper-reference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address. (required)
  --merchant-account: string # Your merchant account. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/storedPaymentMethods/{recurringId}"
    path_params: [{name: recurringId, var: recurring_id}]
    query: [{name: shopperReference, var: shopper_reference, required: true}, {name: merchantAccount, var: merchant_account, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    recurring_id: $recurring_id, shopper_reference: $shopper_reference, merchant_account: $merchant_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
