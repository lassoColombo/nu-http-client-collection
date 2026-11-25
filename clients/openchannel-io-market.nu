# Auto-generated client for OpenChannel Market API v2.0.24
# Source: https://api.apis.guru/v2/specs/openchannel.io/market/2.0.24/openapi.json
# Auth: --token flag or $env.OPENCHANNEL_MARKET_API_TOKEN

const CLIENT = {
  base_url: "https://market.openchannel.io/v2"
  token_env_var: "OPENCHANNEL_MARKET_API_TOKEN"
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

def base-url-completer [] { ["https://market.openchannel.io/v2"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["approved" "inReview" "rejected" "suspended"] }
def modified-by-completer [] { ["administrator" "developer"] }
def period-completer [] { ["day" "month"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-apps: "record<count: int, list: table<access: list, allow: record, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: list, name: string, ownership: record, randomize: int, rating: int, restrict: record, reviewCount: int, safeName: list, statistics: record, status: record, submittedDate: int, type: string, version: int>, pageNumber: int, pages: int>"
    post-apps: "record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, parent: record<status: record<profanity: list, reason: string, value: string>>, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, status: record<profanity: list<record>, reason: string, value: string>, type: string, version: int>"
    get-apps-by-safe-name-safe-name: "record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, ownership: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, randomize: int, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, statistics: record, status: record<profanity: list<record>, reason: string, value: string>, submittedDate: int, type: string, version: int>"
    get-apps-text-search: "record<count: int, list: table<access: list, allow: record, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: list, name: string, ownership: record, randomize: int, rating: int, restrict: record, reviewCount: int, safeName: list, statistics: record, status: record, submittedDate: int, type: string, version: int>, pageNumber: int, pages: int>"
    get-apps-versions: "record<count: int, list: table<access: list, allow: record, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: list, name: string, parent: record, rating: int, restrict: record, reviewCount: int, safeName: list, status: record, type: string, version: int>, pageNumber: int, pages: int>"
    get-apps-app-id: "record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, ownership: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, randomize: int, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, statistics: record, status: record<profanity: list<record>, reason: string, value: string>, submittedDate: int, type: string, version: int>"
    get-apps-app-id-versions-version: "record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, parent: record<status: record<profanity: list, reason: string, value: string>>, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, status: record<profanity: list<record>, reason: string, value: string>, type: string, version: int>"
    patch-apps-app-id-versions-version: "record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, parent: record<status: record<profanity: list, reason: string, value: string>>, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, status: record<profanity: list<record>, reason: string, value: string>, type: string, version: int>"
    post-apps-app-id-versions-version: "record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, parent: record<status: record<profanity: list, reason: string, value: string>>, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, status: record<profanity: list<record>, reason: string, value: string>, type: string, version: int>"
    post-custom-gateway-payment-ownership-id: "record<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>"
    post-custom-gateway-refund-ownership-id: "record<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>"
    get-developer-accounts: "record<count: int, list: table<customData: record, developerAccountId: string, developerId: string, email: string, name: string>, pageNumber: int, pages: int>"
    get-developer-accounts-developer-account-id: "record<customData: record, developerAccountId: string, developerId: string, email: string, name: string>"
    patch-developer-accounts-developer-account-id: "record<customData: record, developerAccountId: string, developerId: string, email: string, name: string>"
    post-developer-accounts-developer-account-id: "record<customData: record, developerAccountId: string, developerId: string, email: string, name: string>"
    get-developers: "record<count: int, list: table<created: int, customData: record, developerId: string, email: string, name: string, type: string>, pageNumber: int, pages: int>"
    get-developers-developer-id: "record<created: int, customData: record, developerId: string, email: string, name: string, type: string>"
    patch-developers-developer-id: "record<created: int, customData: record, developerId: string, email: string, name: string, type: string>"
    post-developers-developer-id: "record<created: int, customData: record, developerId: string, email: string, name: string, type: string>"
    get-events-event-id: "record<app: record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: list<record>, name: string, ownership: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, randomize: int, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, statistics: record, status: record<profanity: list, reason: string, value: string>, submittedDate: int, type: string, version: int>, createdDate: int, description: string, developer: record<created: int, customData: record, developerId: string, email: string, name: string, type: string>, eventId: string, eventType: string, marketplaceId: string, ownership: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, review: record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>, transaction: record<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>>"
    get-files: "record<contentType: string, fileId: string, fileUrl: string, hash: record<MD5: string, SHA-1: string, SHA-256: string>, mimeCheck: string, name: string, size: int, uploadDate: int, virusScan: record<finished: int, foundViruses: list<record>, started: int, status: string>>"
    post-files: "record<contentType: string, fileId: string, fileUrl: string, hash: record<MD5: string, SHA-1: string, SHA-256: string>, mimeCheck: string, name: string, size: int, uploadDate: int, virusScan: record<finished: int, foundViruses: list<record>, started: int, status: string>>"
    get-files-by-id-or-url: "record<contentType: string, fileId: string, fileUrl: string, hash: record<MD5: string, SHA-1: string, SHA-256: string>, mimeCheck: string, name: string, size: int, uploadDate: int, virusScan: record<finished: int, foundViruses: list<record>, started: int, status: string>>"
    get-files-download: "record<url: string>"
    post-files-url: "record<contentType: string, fileId: string, fileUrl: string, hash: record<MD5: string, SHA-1: string, SHA-256: string>, mimeCheck: string, name: string, size: int, uploadDate: int, virusScan: record<finished: int, foundViruses: list<record>, started: int, status: string>>"
    get-markets-this: "record<attributes: table<name: string, type: string, values: string>, categoryGroups: table<categories: list, name: string>, marketplaceId: string, previewAppUrl: string, viewAppUrl: string>"
    get-ownership: "record<count: int, list: table<appId: string, customData: record, date: int, developerId: string, expires: int, model: record, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, pageNumber: int, pages: int>"
    post-ownership-install: "record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>"
    post-ownership-uninstall-ownership-id: "record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>"
    get-ownership-ownership-id: "record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>"
    patch-ownership-ownership-id: "record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>"
    post-ownership-ownership-id: "record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>"
    get-permission-apps-app-id: "record<access: list<string>, appId: string, date: int, ip: string, isValid: bool, userId: string>"
    post-permission-apps-app-id: "record<access: list<string>, appId: string, date: int, ip: string, isValid: bool, userId: string>"
    get-reviews: "record<count: int, list: table<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record, type: string, user: record, userAccount: record, userAccountId: string, userId: string>, pageNumber: int, pages: int>"
    post-reviews: "record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list<record>, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>"
    get-reviews-review-id: "record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list<record>, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>"
    patch-reviews-review-id: "record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list<record>, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>"
    post-reviews-review-id: "record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list<record>, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>"
    get-stats-series-period-fields: "list<list<record>>"
    get-stats-total: "record<apps: record<\"$appId\": record<\"$field\": int>>, end: int, start: int, totals: record<\"$field\": int>>"
    get-stripe-gateway-developer-developer-id-accounts: "record<accounts: table<accountName: string, country: string, defaultCurrency: string, stripeId: string>, developerId: string>"
    post-stripe-gateway-developer-developer-id-accounts: "record<developerId: string, expires: int, targetUrl: string>"
    delete-stripe-gateway-developer-developer-id-accounts-stripe-id: "record<accounts: table<accountName: string, country: string, defaultCurrency: string, stripeId: string>, developerId: string>"
    get-stripe-gateway-user-user-id-cards: "record<cards: table<address_city: string, address_country: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, brand: string, cardId: string, exp_month: int, exp_year: int, isDefault: bool, last4: string, name: string>, userId: string>"
    post-stripe-gateway-user-user-id-cards: "record<cards: table<address_city: string, address_country: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, brand: string, cardId: string, exp_month: int, exp_year: int, isDefault: bool, last4: string, name: string>, userId: string>"
    delete-stripe-gateway-user-user-id-cards-card-id: "record<cards: table<address_city: string, address_country: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, brand: string, cardId: string, exp_month: int, exp_year: int, isDefault: bool, last4: string, name: string>, userId: string>"
    post-stripe-gateway-user-user-id-cards-card-id: "record<cards: table<address_city: string, address_country: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, brand: string, cardId: string, exp_month: int, exp_year: int, isDefault: bool, last4: string, name: string>, userId: string>"
    get-transactions: "record<count: int, list: table<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>, pageNumber: int, pages: int>"
    post-transactions-transaction-id: "record<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>"
    get-user-accounts: "record<count: int, list: table<customData: record, email: string, name: string, userAccountId: string, userId: string>, pageNumber: int, pages: int>"
    get-user-accounts-user-account-id: "record<customData: record, email: string, name: string, userAccountId: string, userId: string>"
    patch-user-accounts-user-account-id: "record<customData: record, email: string, name: string, userAccountId: string, userId: string>"
    post-user-accounts-user-account-id: "record<customData: record, email: string, name: string, userAccountId: string, userId: string>"
    get-users: "record<count: int, list: table<created: int, customData: record, email: string, name: string, type: string, userId: string>, pageNumber: int, pages: int>"
    get-users-user-id: "record<created: int, customData: record, email: string, name: string, type: string, userId: string>"
    patch-users-user-id: "record<created: int, customData: record, email: string, name: string, type: string, userId: string>"
    post-users-user-id: "record<created: int, customData: record, email: string, name: string, type: string, userId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-apps" "post-apps" "get-apps-by-safe-name-safe-name" "get-apps-text-search" "get-apps-versions" "delete-apps-app-id" "get-apps-app-id" "post-apps-app-id-live" "post-apps-app-id-publish" "delete-apps-app-id-versions-version" "get-apps-app-id-versions-version" "patch-apps-app-id-versions-version" "post-apps-app-id-versions-version" "post-apps-app-id-versions-version-status" "post-custom-gateway-payment-ownership-id" "post-custom-gateway-refund-ownership-id" "get-developer-accounts" "delete-developer-accounts-developer-account-id" "get-developer-accounts-developer-account-id" "patch-developer-accounts-developer-account-id" "post-developer-accounts-developer-account-id" "get-developers" "delete-developers-developer-id" "get-developers-developer-id" "patch-developers-developer-id" "post-developers-developer-id" "get-events-event-id" "get-files" "post-files" "get-files-by-id-or-url" "get-files-download" "post-files-url" "get-markets-this" "get-ownership" "post-ownership-install" "post-ownership-uninstall-ownership-id" "get-ownership-ownership-id" "patch-ownership-ownership-id" "post-ownership-ownership-id" "delete-permission-apps-app-id" "get-permission-apps-app-id" "post-permission-apps-app-id" "get-reviews" "post-reviews" "delete-reviews-review-id" "get-reviews-review-id" "patch-reviews-review-id" "post-reviews-review-id" "post-stats-increment-field" "get-stats-series-period-fields" "get-stats-total" "get-stripe-gateway-developer-developer-id-accounts" "post-stripe-gateway-developer-developer-id-accounts" "delete-stripe-gateway-developer-developer-id-accounts-stripe-id" "get-stripe-gateway-user-user-id-cards" "post-stripe-gateway-user-user-id-cards" "delete-stripe-gateway-user-user-id-cards-card-id" "post-stripe-gateway-user-user-id-cards-card-id" "get-transactions" "delete-transactions-transaction-id" "get-transactions-transaction-id" "post-transactions-transaction-id" "get-user-accounts" "delete-user-accounts-user-account-id" "get-user-accounts-user-account-id" "patch-user-accounts-user-account-id" "post-user-accounts-user-account-id" "get-users" "delete-users-user-id" "get-users-user-id" "patch-users-user-id" "post-users-user-id" "commands"] | sort) } | get name | first)
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

# Returns a paginated list of APPROVED or SUSPENDED apps
#
# GET /apps
# Returns: record<count: int, list: table<access: list, allow: record, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: list, name: string, ownership: record, randomize: int, rating: int, restrict: record, reviewCount: int, safeName: list, statistics: record, status: record, submittedDate: int, type: string, version: int>, pageNumber: int, pages: int>
export def "get-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'MyApp'} matches all the apps that have the name 'MyApp'
  --sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
  --user-id: string # The unique id of the user requesting this resource
  --is-owner: oneof<nothing, bool> # Whether this result should only contain apps that are owned by this user
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}, {name: userId, var: user_id}, {name: isOwner, var: is_owner}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit, user_id: $user_id, is_owner: $is_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new app for this developer
#
# POST /apps
# Returns: record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, parent: record<status: record<profanity: list, reason: string, value: string>>, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, status: record<profanity: list<record>, reason: string, value: string>, type: string, version: int>
export def "post-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is adding this app (required)
  --name: string # The name of the app (required)
  --type: string # The type for this app
  --model: string # A JSON object representing the pricing model type for this app
  --custom-data: string # A custom JSON object that you can create and attach to this record
  --attributes: string # A custom set of app attributes defined by the administrator and attached to this app
  --restrict: string # JSON object to restrict users from owning or viewing this app. Example: {'view':{'country':['Canada','Mexico']},'own':{'country':['Canada','Mexico']}} restricts users from canada and mexico from viewing or owning this app
  --allow: string # JSON object to restrict users from owning or viewing this app. Example: {'view':{'country':['Canada','Mexico']},'own':{'country':['Canada','Mexico']}} restricts users from canada and mexico from viewing or owning this app
  --access: string # JSON array of data access requirements
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps"
    query: [{name: developerId, var: developer_id, required: true}, {name: name, var: name, required: true}, {name: type, var: type}, {name: model, var: model}, {name: customData, var: custom_data}, {name: attributes, var: attributes}, {name: restrict, var: restrict}, {name: allow, var: allow}, {name: access, var: access}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_id: $developer_id, name: $name, type: $type, model: $model, custom_data: $custom_data, attributes: $attributes, restrict: $restrict, allow: $allow, access: $access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single APPROVED or SUSPENDED app
#
# GET /apps/bySafeName/{safeName}
# Returns: record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, ownership: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, randomize: int, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, statistics: record, status: record<profanity: list<record>, reason: string, value: string>, submittedDate: int, type: string, version: int>
export def "get-apps-by-safe-name-safe-name" [
  safe_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The unique id of the user that is requesting this resource
  --track-views: oneof<nothing, bool> # Whether this call should be tracked as a 'view' for this app. Default is false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/bySafeName/{safeName}"
    path_params: [{name: safeName, var: safe_name}]
    query: [{name: userId, var: user_id}, {name: trackViews, var: track_views}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    safe_name: $safe_name, user_id: $user_id, track_views: $track_views
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches through the text of fields to find APPROVED or SUSPENDED apps
#
# GET /apps/textSearch
# Returns: record<count: int, list: table<access: list, allow: record, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: list, name: string, ownership: record, randomize: int, rating: int, restrict: record, reviewCount: int, safeName: list, statistics: record, status: record, submittedDate: int, type: string, version: int>, pageNumber: int, pages: int>
export def "get-apps-text-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'MyApp'} matches all the documents that have the name 'MyApp'
  --text: string # The text to search for. (required)
  --fields: string # A JSON array containing all the fields to be searched through. Example: ['name', 'customData.description'] (required)
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
  --user-id: string # The unique id of the user requesting this resource
  --is-owned: oneof<nothing, bool> # Whether this result should only contain apps that are owned by this user
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/textSearch"
    query: [{name: query, var: query}, {name: text, var: text, required: true}, {name: fields, var: fields, required: true}, {name: pageNumber, var: page_number}, {name: limit, var: limit}, {name: userId, var: user_id}, {name: isOwned, var: is_owned}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, text: $text, fields: $fields, page_number: $page_number, limit: $limit, user_id: $user_id, is_owned: $is_owned
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of AppVersions
#
# GET /apps/versions
# Returns: record<count: int, list: table<access: list, allow: record, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: list, name: string, parent: record, rating: int, restrict: record, reviewCount: int, safeName: list, status: record, type: string, version: int>, pageNumber: int, pages: int>
export def "get-apps-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'MyApp'} matches all the apps that have the name 'MyApp'
  --sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
  --developer-id: string # The unique id of the developer requesting this resource
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/versions"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}, {name: developerId, var: developer_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit, developer_id: $developer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes app and all versions
#
# DELETE /apps/{appId}
export def "delete-apps-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is removing this app (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: developerId, var: developer_id, required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, developer_id: $developer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single APPROVED or SUSPENDED app
#
# GET /apps/{appId}
# Returns: record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, ownership: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, randomize: int, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, statistics: record, status: record<profanity: list<record>, reason: string, value: string>, submittedDate: int, type: string, version: int>
export def "get-apps-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The unique id of the user that is requesting this resource
  --track-views: oneof<nothing, bool> # Whether this call should be tracked as a 'view' for this app. Default is false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: userId, var: user_id}, {name: trackViews, var: track_views}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, user_id: $user_id, track_views: $track_views
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the live app to another, previously approved version
#
# POST /apps/{appId}/live
export def "post-apps-app-id-live" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is changing this AppVersion (required)
  --version: string # The new version of the live App (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/live"
    path_params: [{name: appId, var: app_id}]
    query: [{name: developerId, var: developer_id, required: true}, {name: version, var: version, required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, developer_id: $developer_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publishes the current working version of the app to the marketplace
#
# POST /apps/{appId}/publish
export def "post-apps-app-id-publish" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is modifying this app (required)
  --version: int # The version of the app to be published (required)
  --auto-approve: oneof<nothing, bool> # If true, this AppVersion is automatically approved and becomes immediately available to end users
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/publish"
    path_params: [{name: appId, var: app_id}]
    query: [{name: developerId, var: developer_id, required: true}, {name: version, var: version, required: true}, {name: autoApprove, var: auto_approve}]
    accept: ["application/json"]
    ok: [202]
    auth: basic
  } {
    app_id: $app_id, developer_id: $developer_id, version: $version, auto_approve: $auto_approve
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes AppVersion
#
# DELETE /apps/{appId}/versions/{version}
export def "delete-apps-app-id-versions-version" [
  app_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is removing this app (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/versions/{version}"
    path_params: [{name: appId, var: app_id}, {name: version, var: version}]
    query: [{name: developerId, var: developer_id, required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, version: $version, developer_id: $developer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single AppVersion
#
# GET /apps/{appId}/versions/{version}
# Returns: record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, parent: record<status: record<profanity: list, reason: string, value: string>>, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, status: record<profanity: list<record>, reason: string, value: string>, type: string, version: int>
export def "get-apps-app-id-versions-version" [
  app_id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is requesting this resource
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{version}"
    path_params: [{name: appId, var: app_id}, {name: version, var: version}]
    query: [{name: developerId, var: developer_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, version: $version, developer_id: $developer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the app fields or creates a new version
#
# PATCH /apps/{appId}/versions/{version}
# Returns: record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, parent: record<status: record<profanity: list, reason: string, value: string>>, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, status: record<profanity: list<record>, reason: string, value: string>, type: string, version: int>
export def "patch-apps-app-id-versions-version" [
  app_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is updating this app (required)
  --name: string # The name of the app
  --type: string # The type for this app
  --model: string # A JSON object representing the pricing model type for this app
  --custom-data: string # A custom JSON object that you can create and attach to this record
  --attributes: string # A custom set of app attributes defined by the administrator and attached to this app
  --restrict: string # JSON object to restrict users from purchasing or viewing this app. Example: {'view':{'country':['Canada','Mexico']},'purchase':{'country':['Canada','Mexico']}} restricts users from canada and mexico from viewing or purchasing this app
  --allow: string # JSON object to allow users to purchase or view this app. Example: {'purchase':{'country':['Canada','Mexico']}} allows only users from canada and mexico to purchase this app
  --access: string # JSON array of data access requirements
  --approval-required: string # False if updates should skip the approval process and be available immediately. Default is True
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/apps/{appId}/versions/{version}"
    path_params: [{name: appId, var: app_id}, {name: version, var: version}]
    query: [{name: developerId, var: developer_id, required: true}, {name: name, var: name}, {name: type, var: type}, {name: model, var: model}, {name: customData, var: custom_data}, {name: attributes, var: attributes}, {name: restrict, var: restrict}, {name: allow, var: allow}, {name: access, var: access}, {name: approvalRequired, var: approval_required}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, version: $version, developer_id: $developer_id, name: $name, type: $type, model: $model, custom_data: $custom_data, attributes: $attributes, restrict: $restrict, allow: $allow, access: $access, approval_required: $approval_required
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the app or creates a new version
#
# POST /apps/{appId}/versions/{version}
# Returns: record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLatestVersion: bool, isLive: bool, lastUpdated: int, model: table<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, name: string, parent: record<status: record<profanity: list, reason: string, value: string>>, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, status: record<profanity: list<record>, reason: string, value: string>, type: string, version: int>
export def "post-apps-app-id-versions-version" [
  app_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is updating this app (required)
  --name: string # The name of the app
  --type: string # The type for this app
  --model: string # A JSON object representing the pricing model type for this app
  --custom-data: string # A custom JSON object that you can create and attach to this record
  --attributes: string # A custom set of app attributes defined by the administrator and attached to this app
  --restrict: string # JSON object to restrict users from purchasing or viewing this app. Example: {'view':{'country':['Canada','Mexico']},'purchase':{'country':['Canada','Mexico']}} restricts users from canada and mexico from viewing or purchasing this app
  --allow: string # JSON object to allow users to purchase or view this app. Example: {'purchase':{'country':['Canada','Mexico']}} allows only users from canada and mexico to purchase this app
  --access: string # JSON array of data access requirements
  --approval-required: string # False if updates should skip the approval process and be available immediately. Default is True
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/versions/{version}"
    path_params: [{name: appId, var: app_id}, {name: version, var: version}]
    query: [{name: developerId, var: developer_id, required: true}, {name: name, var: name}, {name: type, var: type}, {name: model, var: model}, {name: customData, var: custom_data}, {name: attributes, var: attributes}, {name: restrict, var: restrict}, {name: allow, var: allow}, {name: access, var: access}, {name: approvalRequired, var: approval_required}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, version: $version, developer_id: $developer_id, name: $name, type: $type, model: $model, custom_data: $custom_data, attributes: $attributes, restrict: $restrict, allow: $allow, access: $access, approval_required: $approval_required
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows a developer or administrator to change the status of apps
#
# POST /apps/{appId}/versions/{version}/status
export def "post-apps-app-id-versions-version-status" [
  app_id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is modifying this app
  --status: string@status-completer # The new status for this app. Can be either 'inReview', 'approved', 'suspended' or 'rejected'
  --modified-by: string@modified-by-completer # The role initiating this status change. Can be either 'developer' or 'administrator' (default) (default: administrator)
  --reason: string # The reason for this status change
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/versions/{version}/status"
    path_params: [{name: appId, var: app_id}, {name: version, var: version}]
    query: [{name: developerId, var: developer_id}, {name: status, var: status}, {name: modifiedBy, var: modified_by}, {name: reason, var: reason}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, version: $version, developer_id: $developer_id, status: $status, modified_by: $modified_by, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a payment for an app on behalf of a user
#
# POST /custom-gateway/payment/{ownershipId}
# Returns: record<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>
export def "post-custom-gateway-payment-ownership-id" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # The total amount paid in cents (required)
  --date: int # The date (in milliseconds) of when this payment was made (format: int64)
  --fee-amount: int # The fee (in cents) paid to a payment processors or third parties to process this payment. Default is 0.
  --marketplace-amount: int # The amount (in cents) paid to the marketplace owner as a commission for the purchase of this app. Defaults based on the commission amount configured for this marketplace.
  --developer-amount: int # The amount (in cents) paid to the owner of the app. Defaults based on the commission amount configured for this marketplace.
  --custom-data: string # A custom JSON object to attach to this transaction
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/custom-gateway/payment/{ownershipId}"
    path_params: [{name: ownershipId, var: ownership_id}]
    query: [{name: amount, var: amount, required: true}, {name: date, var: date}, {name: feeAmount, var: fee_amount}, {name: marketplaceAmount, var: marketplace_amount}, {name: developerAmount, var: developer_amount}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    ownership_id: $ownership_id, amount: $amount, date: $date, fee_amount: $fee_amount, marketplace_amount: $marketplace_amount, developer_amount: $developer_amount, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fully or partially refund payment for an app on behalf of a user
#
# POST /custom-gateway/refund/{ownershipId}
# Returns: record<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>
export def "post-custom-gateway-refund-ownership-id" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # The total amount refunded in cents (required)
  --date: int # The date (in milliseconds) of when this refund was made (format: int64)
  --fee-amount: int # The fee (in cents) recovered from a payment processor or third party to process this payment. The default value is 0
  --marketplace-amount: int # The amount (in cents) recovered from the marketplace owner as a commission refund for the purchase of this app
  --developer-amount: int # The amount (in cents) recovered from the owner of the app
  --custom-data: string # A custom JSON object to attach to this transaction
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/custom-gateway/refund/{ownershipId}"
    path_params: [{name: ownershipId, var: ownership_id}]
    query: [{name: amount, var: amount, required: true}, {name: date, var: date}, {name: feeAmount, var: fee_amount}, {name: marketplaceAmount, var: marketplace_amount}, {name: developerAmount, var: developer_amount}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    ownership_id: $ownership_id, amount: $amount, date: $date, fee_amount: $fee_amount, marketplace_amount: $marketplace_amount, developer_amount: $developer_amount, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of developerAccounts
#
# GET /developerAccounts
# Returns: record<count: int, list: table<customData: record, developerAccountId: string, developerId: string, email: string, name: string>, pageNumber: int, pages: int>
export def "get-developer-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'NASA'} matches all the developerAccounts that have the name 'NASA'
  --sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/developerAccounts"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the developer account
#
# DELETE /developerAccounts/{developerAccountId}
export def "delete-developer-accounts-developer-account-id" [
  developer_account_id: string
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
    path: "/developerAccounts/{developerAccountId}"
    path_params: [{name: developerAccountId, var: developer_account_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    developer_account_id: $developer_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single developer account
#
# GET /developerAccounts/{developerAccountId}
# Returns: record<customData: record, developerAccountId: string, developerId: string, email: string, name: string>
export def "get-developer-accounts-developer-account-id" [
  developer_account_id: string
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
    path: "/developerAccounts/{developerAccountId}"
    path_params: [{name: developerAccountId, var: developer_account_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_account_id: $developer_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the developer account fields
#
# PATCH /developerAccounts/{developerAccountId}
# Returns: record<customData: record, developerAccountId: string, developerId: string, email: string, name: string>
export def "patch-developer-accounts-developer-account-id" [
  developer_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The id of the developer that this account belongs to (required)
  --email: string # The contact email address
  --name: string # The name for the account
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/developerAccounts/{developerAccountId}"
    path_params: [{name: developerAccountId, var: developer_account_id}]
    query: [{name: developerId, var: developer_id, required: true}, {name: email, var: email}, {name: name, var: name}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_account_id: $developer_account_id, developer_id: $developer_id, email: $email, name: $name, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the developer account or adds the developer account if it doesn't exist
#
# POST /developerAccounts/{developerAccountId}
# Returns: record<customData: record, developerAccountId: string, developerId: string, email: string, name: string>
export def "post-developer-accounts-developer-account-id" [
  developer_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The id of the developer that this account belongs to (required)
  --email: string # The contact email address
  --name: string # The name for the account
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/developerAccounts/{developerAccountId}"
    path_params: [{name: developerAccountId, var: developer_account_id}]
    query: [{name: developerId, var: developer_id, required: true}, {name: email, var: email}, {name: name, var: name}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_account_id: $developer_account_id, developer_id: $developer_id, email: $email, name: $name, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of developers
#
# GET /developers
# Returns: record<count: int, list: table<created: int, customData: record, developerId: string, email: string, name: string, type: string>, pageNumber: int, pages: int>
export def "get-developers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'John'} matches all the developers that have the name 'John'
  --sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/developers"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a single developer
#
# DELETE /developers/{developerId}
export def "delete-developers-developer-id" [
  developer_id: string
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
    path: "/developers/{developerId}"
    path_params: [{name: developerId, var: developer_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    developer_id: $developer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single developer
#
# GET /developers/{developerId}
# Returns: record<created: int, customData: record, developerId: string, email: string, name: string, type: string>
export def "get-developers-developer-id" [
  developer_id: string
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
    path: "/developers/{developerId}"
    path_params: [{name: developerId, var: developer_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_id: $developer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the developer fields
#
# PATCH /developers/{developerId}
# Returns: record<created: int, customData: record, developerId: string, email: string, name: string, type: string>
export def "patch-developers-developer-id" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type for this developer
  --email: string # The developer's email
  --username: string # The developer's username
  --name: string # The developer's name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/developers/{developerId}"
    path_params: [{name: developerId, var: developer_id}]
    query: [{name: type, var: type}, {name: email, var: email}, {name: username, var: username}, {name: name, var: name}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_id: $developer_id, type: $type, email: $email, username: $username, name: $name, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the developer record or adds the developer if it doesn't exist
#
# POST /developers/{developerId}
# Returns: record<created: int, customData: record, developerId: string, email: string, name: string, type: string>
export def "post-developers-developer-id" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type for this developer
  --email: string # The developer's email
  --username: string # The developer's username
  --name: string # The developer's name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/developers/{developerId}"
    path_params: [{name: developerId, var: developer_id}]
    query: [{name: type, var: type}, {name: email, var: email}, {name: username, var: username}, {name: name, var: name}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_id: $developer_id, type: $type, email: $email, username: $username, name: $name, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an event
#
# GET /events/{eventId}
# Returns: record<app: record<access: list<string>, allow: record<own: record, view: record>, appId: string, attributes: record, created: int, customData: record, developerId: string, isLive: bool, lastUpdated: int, model: list<record>, name: string, ownership: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, randomize: int, rating: int, restrict: record<own: record, view: record>, reviewCount: int, safeName: list<string>, statistics: record, status: record<profanity: list, reason: string, value: string>, submittedDate: int, type: string, version: int>, createdDate: int, description: string, developer: record<created: int, customData: record, developerId: string, email: string, name: string, type: string>, eventId: string, eventType: string, marketplaceId: string, ownership: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, review: record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>, transaction: record<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>>
export def "get-events-event-id" [
  event_id: string
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
    path: "/events/{eventId}"
    path_params: [{name: eventId, var: event_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of files
#
# GET /files
# Returns: record<contentType: string, fileId: string, fileUrl: string, hash: record<MD5: string, SHA-1: string, SHA-256: string>, mimeCheck: string, name: string, size: int, uploadDate: int, virusScan: record<finished: int, foundViruses: list<record>, started: int, status: string>>
export def "get-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'file.txt'} matches all the files that have the name 'file.txt'
  --sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a file.
#
# POST /files
# Returns: record<contentType: string, fileId: string, fileUrl: string, hash: record<MD5: string, SHA-1: string, SHA-256: string>, mimeCheck: string, name: string, size: int, uploadDate: int, virusScan: record<finished: int, foundViruses: list<record>, started: int, status: string>>
export def "post-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-private: oneof<nothing, bool> # If true, this file will be protected as a private file and require the generation of a signed URL in order to download using the Download File API. The default is false.
  --hash: string # A comma separated list of hashes to return in order to verify file integrity.
  file: string # The file to be uploaded (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files"
    query: [{name: isPrivate, var: is_private}, {name: hash, var: hash}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    is_private: $is_private, hash: $hash, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details for a file.
#
# GET /files/byIdOrUrl
# Returns: record<contentType: string, fileId: string, fileUrl: string, hash: record<MD5: string, SHA-1: string, SHA-256: string>, mimeCheck: string, name: string, size: int, uploadDate: int, virusScan: record<finished: int, foundViruses: list<record>, started: int, status: string>>
export def "get-files-by-id-or-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id-or-url: string # The fileId or fileUrl of the file to be returned (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/byIdOrUrl"
    query: [{name: fileIdOrUrl, var: file_id_or_url, required: true}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    file_id_or_url: $file_id_or_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A signed URL for downloading a private file can be returned by providing the fileId.
#
# GET /files/download
# Returns: record<url: string>
export def "get-files-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: string # The URL of the file to be uploaded (required)
  --valid-seconds: int # The number of seconds that this signed URL should be valid for. The default is 60.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/download"
    query: [{name: fileId, var: file_id, required: true}, {name: validSeconds, var: valid_seconds}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    file_id: $file_id, valid_seconds: $valid_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a file from a URL
#
# POST /files/url
# Returns: record<contentType: string, fileId: string, fileUrl: string, hash: record<MD5: string, SHA-1: string, SHA-256: string>, mimeCheck: string, name: string, size: int, uploadDate: int, virusScan: record<finished: int, foundViruses: list<record>, started: int, status: string>>
export def "post-files-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # The URL of the file to be uploaded (required)
  --is-private: oneof<nothing, bool> # If true, this file will be protected as a private file and require the generation of a signed URL in order to download using the Download File API. The default is false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/files/url"
    query: [{name: url, var: url, required: true}, {name: isPrivate, var: is_private}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    url: $url, is_private: $is_private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current marketplace
#
# GET /markets/this
# Returns: record<attributes: table<name: string, type: string, values: string>, categoryGroups: table<categories: list, name: string>, marketplaceId: string, previewAppUrl: string, viewAppUrl: string>
export def "get-markets-this" [
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
    path: "/markets/this"
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of app licenses
#
# GET /ownership
# Returns: record<count: int, list: table<appId: string, customData: record, date: int, developerId: string, expires: int, model: record, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>, pageNumber: int, pages: int>
export def "get-ownership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'userId':'12'} matches all the ownership records that have the userId '12'.
  --sort: string # A sort document. Example: {'date':1} sorts the results by date in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ownership"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aquires an app license for a user (installs app)
#
# POST /ownership/install
# Returns: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>
export def "post-ownership-install" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # The id of the App being owned (required)
  --user-id: string # The id of the User requesting to own the App (required)
  --model-id: string # The id of the model associated with this ownership request
  --model: string # A custom model that will override the app's default model for this install
  --custom-data: string # A custom JSON object to attach to this ownership record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/ownership/install"
    query: [{name: appId, var: app_id, required: true}, {name: userId, var: user_id, required: true}, {name: modelId, var: model_id}, {name: model, var: model}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, user_id: $user_id, model_id: $model_id, model: $model, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uninstalls a license for a particular user and app (uninstalls app)
#
# POST /ownership/uninstall/{ownershipId}
# Returns: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>
export def "post-ownership-uninstall-ownership-id" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the User requesting to uninstall the App (required)
  --cancel-ownership: oneof<nothing, bool> # True if this app will require payment to be re-installed. Default is false
  --custom-data: string # A custom JSON object to attach to this ownership record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/ownership/uninstall/{ownershipId}"
    path_params: [{name: ownershipId, var: ownership_id}]
    query: [{name: userId, var: user_id, required: true}, {name: cancelOwnership, var: cancel_ownership}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    ownership_id: $ownership_id, user_id: $user_id, cancel_ownership: $cancel_ownership, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an ownership record
#
# GET /ownership/{ownershipId}
# Returns: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>
export def "get-ownership-ownership-id" [
  ownership_id: string
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
    path: "/ownership/{ownershipId}"
    path_params: [{name: ownershipId, var: ownership_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    ownership_id: $ownership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates ownership fields
#
# PATCH /ownership/{ownershipId}
# Returns: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>
export def "patch-ownership-ownership-id" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-data: string # Custom JSON object that will be attached to this ownership record
  --expires: int # The date (in millis) of when this app ownership expires (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/ownership/{ownershipId}"
    path_params: [{name: ownershipId, var: ownership_id}]
    query: [{name: customData, var: custom_data}, {name: expires, var: expires}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    ownership_id: $ownership_id, custom_data: $custom_data, expires: $expires
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an ownership record
#
# POST /ownership/{ownershipId}
# Returns: record<appId: string, customData: record, date: int, developerId: string, expires: int, model: record<billingPeriod: string, billingPeriodUnit: int, commission: int, currency: string, customData: record, feePayer: string, license: string, modelId: string, price: int, subtype: string, trial: int, type: string>, ownershipId: string, ownershipStatus: string, ownershipType: string, uninstallDate: int, userId: string>
export def "post-ownership-ownership-id" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-data: string # Custom JSON object that will be attached to this ownership record
  --expires: int # The date (in millis) of when this app ownership expires (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/ownership/{ownershipId}"
    path_params: [{name: ownershipId, var: ownership_id}]
    query: [{name: customData, var: custom_data}, {name: expires, var: expires}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    ownership_id: $ownership_id, custom_data: $custom_data, expires: $expires
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes permission that allows the app to access this user's data
#
# DELETE /permission/apps/{appId}
export def "delete-permission-apps-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the user (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/permission/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: userId, var: user_id, required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns permission that allows the app to access this user's data
#
# GET /permission/apps/{appId}
# Returns: record<access: list<string>, appId: string, date: int, ip: string, isValid: bool, userId: string>
export def "get-permission-apps-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the user (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/permission/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: userId, var: user_id, required: true}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds permission to allow the app to access this user's data
#
# POST /permission/apps/{appId}
# Returns: record<access: list<string>, appId: string, date: int, ip: string, isValid: bool, userId: string>
export def "post-permission-apps-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the user (required)
  --date: int # The time (in milliseconds) of when the user agreed to the access request (format: int64)
  --ip: string # The ip address of the user agreeing to the access request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/permission/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: userId, var: user_id, required: true}, {name: date, var: date}, {name: ip, var: ip}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, user_id: $user_id, date: $date, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find reviews for a particular App and marketplace. Results are automatically paginated when limit is set
#
# GET /reviews
# Returns: record<count: int, list: table<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record, type: string, user: record, userAccount: record, userAccountId: string, userId: string>, pageNumber: int, pages: int>
export def "get-reviews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'rating': 500} matches all the reviews that have a rating of 500.
  --sort: string # A sort document. Example: {'rating':1} sorts the results by rating in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reviews"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post a review from a User and returns the new post
#
# POST /reviews
# Returns: record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list<record>, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>
export def "post-reviews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # The id of the App that will own this review (required)
  --user-id: string # The id of the User that is posting this review (required)
  --user-account-id: string # The id of the User account that is posting this review
  --headline: string # The review's headline. Limited to 50 characters. (required)
  --rating: int # The rating given within this review. The rating is represented as an integer between 0 and 500 (0 - 5 stars) (required)
  --description: string # The review's description. Limited to 2000 characters. (required)
  --type: string # The type for this review
  --must-own-app: oneof<nothing, bool> # True if a review can be created only by a user that has owned the app. The default is True.
  --auto-approve: oneof<nothing, bool> # True if the review should be automatically approved. The default is False.
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/reviews"
    query: [{name: appId, var: app_id, required: true}, {name: userId, var: user_id, required: true}, {name: userAccountId, var: user_account_id}, {name: headline, var: headline, required: true}, {name: rating, var: rating, required: true}, {name: description, var: description, required: true}, {name: type, var: type}, {name: mustOwnApp, var: must_own_app}, {name: autoApprove, var: auto_approve}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    app_id: $app_id, user_id: $user_id, user_account_id: $user_account_id, headline: $headline, rating: $rating, description: $description, type: $type, must_own_app: $must_own_app, auto_approve: $auto_approve, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a review
#
# DELETE /reviews/{reviewId}
export def "delete-reviews-review-id" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the User that is removing this review (required)
  --user-account-id: string # The id of the User account that is emoving this review
]: nothing -> any {
  http-request {
    method: delete
    path: "/reviews/{reviewId}"
    path_params: [{name: reviewId, var: review_id}]
    query: [{name: userId, var: user_id, required: true}, {name: userAccountId, var: user_account_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    review_id: $review_id, user_id: $user_id, user_account_id: $user_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a Review within a particular App and marketplace
#
# GET /reviews/{reviewId}
# Returns: record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list<record>, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>
export def "get-reviews-review-id" [
  review_id: string
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
    path: "/reviews/{reviewId}"
    path_params: [{name: reviewId, var: review_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    review_id: $review_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a review fields
#
# PATCH /reviews/{reviewId}
# Returns: record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list<record>, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>
export def "patch-reviews-review-id" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the User that is updating this review (required)
  --user-account-id: string # The id of the User account that is posting this review
  --headline: string # The review's headline. Limited to 50 characters.
  --rating: int # The rating given within this review. The rating is represented as an integer between 0 and 500 (0 - 5 stars)
  --description: string # The review's description. Limited to 2000 characters.
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/reviews/{reviewId}"
    path_params: [{name: reviewId, var: review_id}]
    query: [{name: userId, var: user_id, required: true}, {name: userAccountId, var: user_account_id}, {name: headline, var: headline}, {name: rating, var: rating}, {name: description, var: description}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    review_id: $review_id, user_id: $user_id, user_account_id: $user_account_id, headline: $headline, rating: $rating, description: $description, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a review from a User and returns the new post
#
# POST /reviews/{reviewId}
# Returns: record<appId: string, customData: string, description: string, headline: string, rating: int, reportDate: int, reviewId: string, status: record<profanity: list<record>, reason: string, value: string>, type: string, user: record<created: int, customData: record, email: string, name: string, type: string, userId: string>, userAccount: record<customData: record, email: string, name: string, userAccountId: string, userId: string>, userAccountId: string, userId: string>
export def "post-reviews-review-id" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the User that is updating this review (required)
  --user-account-id: string # The id of the User account that is posting this review (required)
  --headline: string # The review's headline. Limited to 50 characters. (required)
  --rating: int # The rating given within this review. The rating is represented as an integer between 0 and 500 (0 - 5 stars) (required)
  --description: string # The review's description. Limited to 2000 characters. (required)
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/reviews/{reviewId}"
    path_params: [{name: reviewId, var: review_id}]
    query: [{name: userId, var: user_id, required: true}, {name: userAccountId, var: user_account_id, required: true}, {name: headline, var: headline, required: true}, {name: rating, var: rating, required: true}, {name: description, var: description, required: true}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    review_id: $review_id, user_id: $user_id, user_account_id: $user_account_id, headline: $headline, rating: $rating, description: $description, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Increments a statistics field
#
# POST /stats/increment/{field}
export def "post-stats-increment-field" [
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # The id of the app associated with this statistic value (required)
  --user-id: string # The id of the user that is performing the action
  --value: int # The increment amount. Default is 1 if no value is provided.
  --date: int # The date (in millis) for when this increment occurred. The default is the current date if no value is provided. (format: int64)
]: nothing -> any {
  http-request {
    method: post
    path: "/stats/increment/{field}"
    path_params: [{name: field, var: field}]
    query: [{name: appId, var: app_id, required: true}, {name: userId, var: user_id}, {name: value, var: value}, {name: date, var: date}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    field: $field, app_id: $app_id, user_id: $user_id, value: $value, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a timeseries for a particular field
#
# GET /stats/series/{period}/{fields}
# Returns: list<list<record>>
export def "get-stats-series-period-fields" [
  period: string@period-completer
  fields: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # The start date for this series (in millis) (format: int64)
  --end: int # The end date for this series (in millis) (format: int64)
  --query: string # A query document. Example: {'developerId': '112'} matches all the apps that have the developer with id 112
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/stats/series/{period}/{fields}"
    path_params: [{name: period, var: period}, {name: fields, var: fields}]
    query: [{name: start, var: start}, {name: end, var: end}, {name: query, var: query}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    period: $period, fields: $fields, start: $start, end: $end, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the total number of events for a particular field.
#
# GET /stats/total
# Returns: record<apps: record<"$appId": record<"$field": int>>, end: int, start: int, totals: record<"$field": int>>
export def "get-stats-total" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # A comma seperated list of all the fields to be returned in the total (available by default: dislikes, likes, reviews, totalSales, developerSales, marketplaceSales, downloads, ownerships, views) (required)
  --query: string # A query document. Example: {'developerId': '112'} matches all the apps that have the developer with id 112
  --start: int # The start date for this total (in millis) (format: int64)
  --end: int # The end date for this total (in millis) (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/total"
    query: [{name: fields, var: fields, required: true}, {name: query, var: query}, {name: start, var: start}, {name: end, var: end}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    fields: $fields, query: $query, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a developers connected Stripe accounts
#
# GET /stripe-gateway/developer/{developerId}/accounts
# Returns: record<accounts: table<accountName: string, country: string, defaultCurrency: string, stripeId: string>, developerId: string>
export def "get-stripe-gateway-developer-developer-id-accounts" [
  developer_id: string
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
    path: "/stripe-gateway/developer/{developerId}/accounts"
    path_params: [{name: developerId, var: developer_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_id: $developer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a temporary URL to allow a developer to connect their Stripe account
#
# POST /stripe-gateway/developer/{developerId}/accounts
# Returns: record<developerId: string, expires: int, targetUrl: string>
export def "post-stripe-gateway-developer-developer-id-accounts" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect-url: string # The URL to redirect this developer after they have connected their Stripe account (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/stripe-gateway/developer/{developerId}/accounts"
    path_params: [{name: developerId, var: developer_id}]
    query: [{name: redirectUrl, var: redirect_url, required: true}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_id: $developer_id, redirect_url: $redirect_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disconnects a developer's Stripe account
#
# DELETE /stripe-gateway/developer/{developerId}/accounts/{stripeId}
# Returns: record<accounts: table<accountName: string, country: string, defaultCurrency: string, stripeId: string>, developerId: string>
export def "delete-stripe-gateway-developer-developer-id-accounts-stripe-id" [
  developer_id: string
  stripe_id: string
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
    method: delete
    path: "/stripe-gateway/developer/{developerId}/accounts/{stripeId}"
    path_params: [{name: developerId, var: developer_id}, {name: stripeId, var: stripe_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    developer_id: $developer_id, stripe_id: $stripe_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns credit cards for this user
#
# GET /stripe-gateway/user/{userId}/cards
# Returns: record<cards: table<address_city: string, address_country: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, brand: string, cardId: string, exp_month: int, exp_year: int, isDefault: bool, last4: string, name: string>, userId: string>
export def "get-stripe-gateway-user-user-id-cards" [
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
    path: "/stripe-gateway/user/{userId}/cards"
    path_params: [{name: userId, var: user_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds credit card for this user
#
# POST /stripe-gateway/user/{userId}/cards
# Returns: record<cards: table<address_city: string, address_country: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, brand: string, cardId: string, exp_month: int, exp_year: int, isDefault: bool, last4: string, name: string>, userId: string>
export def "post-stripe-gateway-user-user-id-cards" [
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
  --qp-token: string # The Stripe token returned by the Stripe.js Stripe.card.createToken call (required) (spec name: token)
  --is-default: oneof<nothing, bool> # Set to true if this should be set to be the default credit card
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/stripe-gateway/user/{userId}/cards"
    path_params: [{name: userId, var: user_id}]
    query: [{name: token, var: qp_token, required: true}, {name: isDefault, var: is_default}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_id: $user_id, qp_token: $qp_token, is_default: $is_default
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a credit card for a user
#
# DELETE /stripe-gateway/user/{userId}/cards/{cardId}
# Returns: record<cards: table<address_city: string, address_country: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, brand: string, cardId: string, exp_month: int, exp_year: int, isDefault: bool, last4: string, name: string>, userId: string>
export def "delete-stripe-gateway-user-user-id-cards-card-id" [
  user_id: string
  card_id: string
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
    method: delete
    path: "/stripe-gateway/user/{userId}/cards/{cardId}"
    path_params: [{name: userId, var: user_id}, {name: cardId, var: card_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_id: $user_id, card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a credit card for this user
#
# POST /stripe-gateway/user/{userId}/cards/{cardId}
# Returns: record<cards: table<address_city: string, address_country: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, brand: string, cardId: string, exp_month: int, exp_year: int, isDefault: bool, last4: string, name: string>, userId: string>
export def "post-stripe-gateway-user-user-id-cards-card-id" [
  user_id: string
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-default: oneof<nothing, bool> # Set to true if this should be set to be the default credit card
  --address-city: string # The card holder's city
  --address-country: string # The card holder's country
  --address-line1: string # The card holder's street address
  --address-line2: string # The card holder's street address
  --address-state: string # The card holder's city state/province
  --address-zip: string # The card holder's zip/postal code
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/stripe-gateway/user/{userId}/cards/{cardId}"
    path_params: [{name: userId, var: user_id}, {name: cardId, var: card_id}]
    query: [{name: isDefault, var: is_default}, {name: address_city, var: address_city}, {name: address_country, var: address_country}, {name: address_line1, var: address_line1}, {name: address_line2, var: address_line2}, {name: address_state, var: address_state}, {name: address_zip, var: address_zip}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_id: $user_id, card_id: $card_id, is_default: $is_default, address_city: $address_city, address_country: $address_country, address_line1: $address_line1, address_line2: $address_line2, address_state: $address_state, address_zip: $address_zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of transactions
#
# GET /transactions
# Returns: record<count: int, list: table<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>, pageNumber: int, pages: int>
export def "get-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'userId':'1'} matches all the transactions that have the userId '1'.
  --sort: string # A sort document. Example: {'date':1} sorts the results by total in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transactions"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deleted a transaction
#
# DELETE /transactions/{transactionId}
export def "delete-transactions-transaction-id" [
  transaction_id: string
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
    path: "/transactions/{transactionId}"
    path_params: [{name: transactionId, var: transaction_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a transaction
#
# GET /transactions/{transactionId}
export def "get-transactions-transaction-id" [
  transaction_id: string
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
    path: "/transactions/{transactionId}"
    path_params: [{name: transactionId, var: transaction_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a transaction
#
# POST /transactions/{transactionId}
# Returns: record<amount: int, appId: string, customData: record, date: int, developerAmount: int, developerId: string, feeAmount: int, marketplaceAmount: int, ownershipId: string, transactionId: string, type: string, userId: string>
export def "post-transactions-transaction-id" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/transactions/{transactionId}"
    path_params: [{name: transactionId, var: transaction_id}]
    query: [{name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    transaction_id: $transaction_id, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of userAccounts
#
# GET /userAccounts
# Returns: record<count: int, list: table<customData: record, email: string, name: string, userAccountId: string, userId: string>, pageNumber: int, pages: int>
export def "get-user-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'NASA'} matches all the userAccounts that have the name 'NASA'
  --sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/userAccounts"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the user account
#
# DELETE /userAccounts/{userAccountId}
export def "delete-user-accounts-user-account-id" [
  user_account_id: string
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
    path: "/userAccounts/{userAccountId}"
    path_params: [{name: userAccountId, var: user_account_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    user_account_id: $user_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single user account
#
# GET /userAccounts/{userAccountId}
# Returns: record<customData: record, email: string, name: string, userAccountId: string, userId: string>
export def "get-user-accounts-user-account-id" [
  user_account_id: string
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
    path: "/userAccounts/{userAccountId}"
    path_params: [{name: userAccountId, var: user_account_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_account_id: $user_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the user account fields
#
# PATCH /userAccounts/{userAccountId}
# Returns: record<customData: record, email: string, name: string, userAccountId: string, userId: string>
export def "patch-user-accounts-user-account-id" [
  user_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The Id of the user that this account belongs to (required)
  --email: string # The contact email address
  --name: string # The user account name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/userAccounts/{userAccountId}"
    path_params: [{name: userAccountId, var: user_account_id}]
    query: [{name: userId, var: user_id, required: true}, {name: email, var: email}, {name: name, var: name}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_account_id: $user_account_id, user_id: $user_id, email: $email, name: $name, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the user account or adds the user account if it doesn't exist
#
# POST /userAccounts/{userAccountId}
# Returns: record<customData: record, email: string, name: string, userAccountId: string, userId: string>
export def "post-user-accounts-user-account-id" [
  user_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The Id of the user that this account belongs to (required)
  --email: string # The contact email address
  --name: string # The user account name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/userAccounts/{userAccountId}"
    path_params: [{name: userAccountId, var: user_account_id}]
    query: [{name: userId, var: user_id, required: true}, {name: email, var: email}, {name: name, var: name}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_account_id: $user_account_id, user_id: $user_id, email: $email, name: $name, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of users
#
# GET /users
# Returns: record<count: int, list: table<created: int, customData: record, email: string, name: string, type: string, userId: string>, pageNumber: int, pages: int>
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'John'} matches all the users that have the name 'John'
  --sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: query, var: query}, {name: sort, var: sort}, {name: pageNumber, var: page_number}, {name: limit, var: limit}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    query: $query, sort: $sort, page_number: $page_number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a single user
#
# DELETE /users/{userId}
export def "delete-users-user-id" [
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
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a single user
#
# GET /users/{userId}
# Returns: record<created: int, customData: record, email: string, name: string, type: string, userId: string>
export def "get-users-user-id" [
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
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates user fields
#
# PATCH /users/{userId}
# Returns: record<created: int, customData: record, email: string, name: string, type: string, userId: string>
export def "patch-users-user-id" [
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
  --type: string # The type for this user
  --email: string # The user's email
  --username: string # The user's username
  --name: string # The user's name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    query: [{name: type, var: type}, {name: email, var: email}, {name: username, var: username}, {name: name, var: name}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_id: $user_id, type: $type, email: $email, username: $username, name: $name, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a single user or adds the user if they don't exist
#
# POST /users/{userId}
# Returns: record<created: int, customData: record, email: string, name: string, type: string, userId: string>
export def "post-users-user-id" [
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
  --type: string # The type for this user
  --email: string # The user's email
  --username: string # The user's username
  --name: string # The user's name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    query: [{name: type, var: type}, {name: email, var: email}, {name: username, var: username}, {name: name, var: name}, {name: customData, var: custom_data}]
    accept: ["*/*"]
    ok: []
    auth: basic
  } {
    user_id: $user_id, type: $type, email: $email, username: $username, name: $name, custom_data: $custom_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
