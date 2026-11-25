# Auto-generated client for Subscriptions API (v3) v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Subscriptions-API-(v3)/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.SUBSCRIPTIONS_API_V3_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "SUBSCRIPTIONS_API_V3_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-vtex-api-appkey, in: header, header_name: X-VTEX-API-AppKey, prefix: ""}
    {name: x-vtex-api-apptoken, in: header, header_name: X-VTEX-API-AppToken, prefix: ""}
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let return_types = {
    get-api-rns-pub-cycles: "table<context: record<addressId: string, addressType: string, items: list, paymentAccountId: string, paymentSystem: string, paymentSystemGroup: string, paymentSystemName: string>, customerEmail: string, cycleCount: int, date: string, id: string, isInRetry: bool, lastUpdate: string, message: string, orderInfo: record<orderGroup: string, orderId: string, paymentURL: string, value: int>, simulationItems: list<record>, status: string, subscriptionId: string>"
    get-api-rns-pub-cycles-cycle-id: "record<context: record<addressId: string, addressType: string, items: list<record>, paymentAccountId: string, paymentSystem: string, paymentSystemGroup: string, paymentSystemName: string>, customerEmail: string, cycleCount: int, date: string, id: string, isInRetry: bool, lastUpdate: string, message: string, orderInfo: record<orderGroup: string, orderId: string, paymentURL: string, value: int>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, status: string, subscriptionId: string>"
    get-api-rns-pub-subscriptions: "table<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: list<record>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record, id: string, purchaseDay: int, validity: record>, purchaseSettings: record<currencyCode: string, paymentMethod: record>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>"
    post-api-rns-pub-subscriptions: "record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>"
    post-api-rns-pub-subscriptions-simulate: "record<shippingEstimate: record<allItemsMatched: bool, estimate: string, estimateDeliveryDate: string, name: string, nextPurchaseDate: string>, simulateResponse: record<country: string, items: list<record>, logisticsInfo: list<record>, messages: list<record>, paymentData: record<payments: list, transactions: list>, postalCode: string, selectableGiftsResponse: list<record>, simulationItems: list<record>, totals: list<record>>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, totals: table<id: string, value: float>>"
    get-api-rns-pub-subscriptions-id: "record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>"
    patch-api-rns-pub-subscriptions-id: "record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>"
    post-api-rns-pub-subscriptions-id-items: "record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>"
    patch-api-rns-pub-subscriptions-id-items-item-id: "record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>"
    post-api-rns-pub-subscriptions-id-simulate: "record<shippingEstimate: record<allItemsMatched: bool, estimate: string, estimateDeliveryDate: string, name: string, nextPurchaseDate: string>, simulateResponse: record<country: string, items: list<record>, logisticsInfo: list<record>, messages: list<record>, paymentData: record<payments: list, transactions: list>, postalCode: string, selectableGiftsResponse: list<record>, simulationItems: list<record>, totals: list<record>>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, totals: table<id: string, value: float>>"
    get-api-rns-pub-subscriptions-subscription-id-conversation-message: "table<attachmentNames: list<string>, body: string, date: string, firstWords: string, from: record<aliasMaskType: string, conversationRelatedTo: string, conversationSubject: string, email: string, emailAlias: string, name: string, role: string>, hasAttachment: bool, id: string, subject: string, to: list<record>>"
    get-api-rns-pvt-plans: "table<frequencies: list<record>, id: string>"
    get-api-rns-pvt-plans-id: "record<frequencies: table<interval: int, periodicity: int, periodicityAsString: string>, id: string>"
    get-api-rns-pvt-reports: "table<account: string, description: string, entity: string, key: string, name: string, params: list<record>, query: string, requesterEmail: string, schema: string>"
    post-api-rns-pvt-reports-report-name-documents: "record<canceled: bool, completedDate: string, email: string, enqueueDate: string, errorCount: int, finished: bool, id: string, lastErrorMessage: string, lastUpdateTime: string, linkToDownload: string, outputType: string, percentageProcessed: int, recordsProcessed: int, recordsSum: int, startDate: string, statusMessage: string, zipped: bool>"
    get-api-rns-pvt-reports-report-name-documents-document-id: "record<canceled: bool, completedDate: string, email: string, enqueueDate: string, errorCount: int, finished: bool, id: string, lastErrorMessage: string, lastUpdateTime: string, linkToDownload: string, outputType: string, percentageProcessed: int, recordsProcessed: int, recordsSum: int, startDate: string, statusMessage: string, zipped: bool>"
    get-settings: "record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string>"
    edit-settings: "record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-rns-pub-cycles" "get-api-rns-pub-cycles-cycle-id" "post-api-rns-pub-cycles-cycle-id-retry" "get-api-rns-pub-subscriptions" "post-api-rns-pub-subscriptions" "post-api-rns-pub-subscriptions-simulate" "get-api-rns-pub-subscriptions-id" "patch-api-rns-pub-subscriptions-id" "post-api-rns-pub-subscriptions-id-items" "delete-api-rns-pub-subscriptions-id-items-item-id" "patch-api-rns-pub-subscriptions-id-items-item-id" "post-api-rns-pub-subscriptions-id-simulate" "get-api-rns-pub-subscriptions-subscription-id-conversation-message" "get-api-rns-pvt-plans" "get-api-rns-pvt-plans-id" "get-api-rns-pvt-reports" "post-api-rns-pvt-reports-report-name-documents" "get-api-rns-pvt-reports-report-name-documents-document-id" "get-settings" "edit-settings" "commands"] | sort) } | get name | first)
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

# List cycles
#
# GET /api/rns/pub/cycles
# Returns: table<context: record<addressId: string, addressType: string, items: list, paymentAccountId: string, paymentSystem: string, paymentSystemGroup: string, paymentSystemName: string>, customerEmail: string, cycleCount: int, date: string, id: string, isInRetry: bool, lastUpdate: string, message: string, orderInfo: record<orderGroup: string, orderId: string, paymentURL: string, value: int>, simulationItems: list<record>, status: string, subscriptionId: string>
export def "get-api-rns-pub-cycles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --begin-date: string # Lower limit for the date of creation of the cycle (nullable)
  --end-date: string # Upper limit for the date of creation of the cycle (nullable)
  --subscription-id: string # Id from the subscription that generated the cycle (nullable)
  --customer-email: string # Customer that owns the subscription. Defaults to the current logged user (nullable)
  --status: string # Current cycle status (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pub/cycles"
    query: [{name: beginDate, var: begin_date}, {name: endDate, var: end_date}, {name: subscriptionId, var: subscription_id}, {name: customerEmail, var: customer_email}, {name: status, var: status}, {name: page, var: page}, {name: size, var: size}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    begin_date: $begin_date, end_date: $end_date, subscription_id: $subscription_id, customer_email: $customer_email, status: $status, page: $page, size: $size, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get cycle details
#
# GET /api/rns/pub/cycles/{cycleId}
# Returns: record<context: record<addressId: string, addressType: string, items: list<record>, paymentAccountId: string, paymentSystem: string, paymentSystemGroup: string, paymentSystemName: string>, customerEmail: string, cycleCount: int, date: string, id: string, isInRetry: bool, lastUpdate: string, message: string, orderInfo: record<orderGroup: string, orderId: string, paymentURL: string, value: int>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, status: string, subscriptionId: string>
export def "get-api-rns-pub-cycles-cycle-id" [
  cycle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pub/cycles/{cycleId}"
    path_params: [{name: cycleId, var: cycle_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    cycle_id: $cycle_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retry cycle
#
# POST /api/rns/pub/cycles/{cycleId}/retry
export def "post-api-rns-pub-cycles-cycle-id-retry" [
  cycle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/rns/pub/cycles/{cycleId}/retry"
    path_params: [{name: cycleId, var: cycle_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    cycle_id: $cycle_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List subscriptions
#
# GET /api/rns/pub/subscriptions
# Returns: table<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: list<record>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record, id: string, purchaseDay: int, validity: record>, purchaseSettings: record<currencyCode: string, paymentMethod: record>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>
export def "get-api-rns-pub-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --customer-email: string # Customer that owns the subscription. Defaults to the current logged user. (nullable)
  --status: string # Current subscription status (nullable)
  --address-id: string # Id from the address used as shipping address (nullable)
  --payment-id: string # Id from the payment used as payment method (nullable)
  --plan-id: string # Id from the plan that the subscription belongs to (nullable)
  --next-purchase-date: string # Date for the next cycle (nullable)
  --original-order-id: string # Id from the order that generated the subscription (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pub/subscriptions"
    query: [{name: customerEmail, var: customer_email}, {name: status, var: status}, {name: addressId, var: address_id}, {name: paymentId, var: payment_id}, {name: planId, var: plan_id}, {name: nextPurchaseDate, var: next_purchase_date}, {name: originalOrderId, var: original_order_id}, {name: page, var: page}, {name: size, var: size}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    customer_email: $customer_email, status: $status, address_id: $address_id, payment_id: $payment_id, plan_id: $plan_id, next_purchase_date: $next_purchase_date, original_order_id: $original_order_id, page: $page, size: $size, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create subscription
#
# POST /api/rns/pub/subscriptions
# Returns: record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>
export def "post-api-rns-pub-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --catalog-attachment: string # nullable
  --customer-email: string # nullable
  --items: list # nullable — item shape: {manualPrice?: int, quantity?: int, skuId?: string}
  --next-purchase-date: string # nullable, format: date-time
  plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  purchase_settings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  shipping_address: record # shape: {addressId: string, addressType: string}
  --status: string # nullable
  --title: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rns/pub/subscriptions"
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: catalogAttachment, var: catalog_attachment}, {name: customerEmail, var: customer_email}, {name: items, var: items}, {name: nextPurchaseDate, var: next_purchase_date}, {name: plan, var: plan}, {name: purchaseSettings, var: purchase_settings}, {name: shippingAddress, var: shipping_address}, {name: status, var: status}, {name: title, var: title}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [201]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, catalog_attachment: $catalog_attachment, customer_email: $customer_email, items: $items, next_purchase_date: $next_purchase_date, plan: $plan, purchase_settings: $purchase_settings, shipping_address: $shipping_address, status: $status, title: $title
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Calculate the current prices for the provided subscription template
#
# POST /api/rns/pub/subscriptions/simulate
# Returns: record<shippingEstimate: record<allItemsMatched: bool, estimate: string, estimateDeliveryDate: string, name: string, nextPurchaseDate: string>, simulateResponse: record<country: string, items: list<record>, logisticsInfo: list<record>, messages: list<record>, paymentData: record<payments: list, transactions: list>, postalCode: string, selectableGiftsResponse: list<record>, simulationItems: list<record>, totals: list<record>>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, totals: table<id: string, value: float>>
export def "post-api-rns-pub-subscriptions-simulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --catalog-attachment: string # nullable
  --customer-email: string # nullable
  --items: list # nullable — item shape: {manualPrice?: int, quantity?: int, skuId?: string}
  --next-purchase-date: string # nullable, format: date-time
  plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  purchase_settings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  shipping_address: record # shape: {addressId: string, addressType: string}
  --status: string # nullable
  --title: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rns/pub/subscriptions/simulate"
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: catalogAttachment, var: catalog_attachment}, {name: customerEmail, var: customer_email}, {name: items, var: items}, {name: nextPurchaseDate, var: next_purchase_date}, {name: plan, var: plan}, {name: purchaseSettings, var: purchase_settings}, {name: shippingAddress, var: shipping_address}, {name: status, var: status}, {name: title, var: title}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, catalog_attachment: $catalog_attachment, customer_email: $customer_email, items: $items, next_purchase_date: $next_purchase_date, plan: $plan, purchase_settings: $purchase_settings, shipping_address: $shipping_address, status: $status, title: $title
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get subscription details
#
# GET /api/rns/pub/subscriptions/{id}
# Returns: record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>
export def "get-api-rns-pub-subscriptions-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pub/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update subscription
#
# PATCH /api/rns/pub/subscriptions/{id}
# Returns: record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>
export def "patch-api-rns-pub-subscriptions-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --is-skipped: oneof<nothing, bool> # When set as `true`, it means the shopper asked to skip the next subscription order, and when set as `false`, no subscription order is going to be skipped. (nullable, e.g. false)
  --plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  --purchase-settings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  --shipping-address: record # shape: {addressId: string, addressType: string}
  --status: string # Status to which you wish to update the subscription. The accepted values are: - `ACTIVE` - `PAUSED` - `CANCELLED` - `EXPIRED` - `MISSING` (nullable, e.g. ACTIVE)
  --title: string # Name of the subscription. (nullable, e.g. catFood)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rns/pub/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: isSkipped, var: is_skipped}, {name: plan, var: plan}, {name: purchaseSettings, var: purchase_settings}, {name: shippingAddress, var: shipping_address}, {name: status, var: status}, {name: title, var: title}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept, is_skipped: $is_skipped, plan: $plan, purchase_settings: $purchase_settings, shipping_address: $shipping_address, status: $status, title: $title
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add item to subscription
#
# POST /api/rns/pub/subscriptions/{id}/items
# Returns: record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>
export def "post-api-rns-pub-subscriptions-id-items" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --manual-price: int # Manual price. (nullable, format: int32, e.g. 40)
  --quantity: int # Amount of units in the cart. (format: int32, e.g. 5)
  --sku-id: string # SKU ID. (nullable, e.g. 12)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rns/pub/subscriptions/{id}/items"
    path_params: [{name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: manualPrice, var: manual_price}, {name: quantity, var: quantity}, {name: skuId, var: sku_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept, manual_price: $manual_price, quantity: $quantity, sku_id: $sku_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove items from a subscription.
#
# DELETE /api/rns/pub/subscriptions/{id}/items/{itemId}
export def "delete-api-rns-pub-subscriptions-id-items-item-id" [
  id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/rns/pub/subscriptions/{id}/items/{itemId}"
    path_params: [{name: id, var: id}, {name: itemId, var: item_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    id: $id, item_id: $item_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit items on a subscription.
#
# PATCH /api/rns/pub/subscriptions/{id}/items/{itemId}
# Returns: record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string>
export def "patch-api-rns-pub-subscriptions-id-items-item-id" [
  id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --is-skipped: oneof<nothing, bool> # nullable
  --manual-price: int # Manual price. (nullable, format: int32, e.g. 40)
  --quantity: int # Amount of units in the cart. (format: int32, e.g. 5)
  --status: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rns/pub/subscriptions/{id}/items/{itemId}"
    path_params: [{name: id, var: id}, {name: itemId, var: item_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: isSkipped, var: is_skipped}, {name: manualPrice, var: manual_price}, {name: quantity, var: quantity}, {name: status, var: status}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    id: $id, item_id: $item_id, content_type: $content_type, hdr_accept: $hdr_accept, is_skipped: $is_skipped, manual_price: $manual_price, quantity: $quantity, status: $status
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Calculate the current prices for a specific subscription
#
# POST /api/rns/pub/subscriptions/{id}/simulate
# Returns: record<shippingEstimate: record<allItemsMatched: bool, estimate: string, estimateDeliveryDate: string, name: string, nextPurchaseDate: string>, simulateResponse: record<country: string, items: list<record>, logisticsInfo: list<record>, messages: list<record>, paymentData: record<payments: list, transactions: list>, postalCode: string, selectableGiftsResponse: list<record>, simulationItems: list<record>, totals: list<record>>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, totals: table<id: string, value: float>>
export def "post-api-rns-pub-subscriptions-id-simulate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/rns/pub/subscriptions/{id}/simulate"
    path_params: [{name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get conversation messages
#
# GET /api/rns/pub/subscriptions/{subscriptionId}/conversation-message
# Returns: table<attachmentNames: list<string>, body: string, date: string, firstWords: string, from: record<aliasMaskType: string, conversationRelatedTo: string, conversationSubject: string, email: string, emailAlias: string, name: string, role: string>, hasAttachment: bool, id: string, subject: string, to: list<record>>
export def "get-api-rns-pub-subscriptions-subscription-id-conversation-message" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pub/subscriptions/{subscriptionId}/conversation-message"
    path_params: [{name: subscriptionId, var: subscription_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    subscription_id: $subscription_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List plans
#
# GET /api/rns/pvt/plans
# Returns: table<frequencies: list<record>, id: string>
export def "get-api-rns-pvt-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --periodicity: string # Filter plans by available periodicity (nullable)
  --interval: string # Filter plans by available interval (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pvt/plans"
    query: [{name: periodicity, var: periodicity}, {name: interval, var: interval}, {name: page, var: page}, {name: size, var: size}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    periodicity: $periodicity, interval: $interval, page: $page, size: $size, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get plan details
#
# GET /api/rns/pvt/plans/{id}
# Returns: record<frequencies: table<interval: int, periodicity: int, periodicityAsString: string>, id: string>
export def "get-api-rns-pvt-plans-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pvt/plans/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List report templates
#
# GET /api/rns/pvt/reports
# Returns: table<account: string, description: string, entity: string, key: string, name: string, params: list<record>, query: string, requesterEmail: string, schema: string>
export def "get-api-rns-pvt-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pvt/reports"
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generate report
#
# POST /api/rns/pvt/reports/{reportName}/documents
# Returns: record<canceled: bool, completedDate: string, email: string, enqueueDate: string, errorCount: int, finished: bool, id: string, lastErrorMessage: string, lastUpdateTime: string, linkToDownload: string, outputType: string, percentageProcessed: int, recordsProcessed: int, recordsSum: int, startDate: string, statusMessage: string, zipped: bool>
export def "post-api-rns-pvt-reports-report-name-documents" [
  report_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The report is sent to the email in this field. (default: receiver@email.com)
  --begin-date: string # Start date of the report with the format `yyyy-mm-dd`. This field is required for any type of report. (default: 2022-09-01)
  --end-date: string # End date of the report with the format `yyyy-mm-dd`. This field is required for any type of report. (default: 2022-10-01)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/rns/pvt/reports/{reportName}/documents"
    path_params: [{name: reportName, var: report_name}]
    query: [{name: email, var: email}, {name: beginDate, var: begin_date}, {name: endDate, var: end_date}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    report_name: $report_name, email: $email, begin_date: $begin_date, end_date: $end_date, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get report document details
#
# GET /api/rns/pvt/reports/{reportName}/documents/{documentId}
# Returns: record<canceled: bool, completedDate: string, email: string, enqueueDate: string, errorCount: int, finished: bool, id: string, lastErrorMessage: string, lastUpdateTime: string, linkToDownload: string, outputType: string, percentageProcessed: int, recordsProcessed: int, recordsSum: int, startDate: string, statusMessage: string, zipped: bool>
export def "get-api-rns-pvt-reports-report-name-documents-document-id" [
  report_name: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/pvt/reports/{reportName}/documents/{documentId}"
    path_params: [{name: reportName, var: report_name}, {name: documentId, var: document_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    report_name: $report_name, document_id: $document_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Subscription Settings
#
# GET /api/rns/settings
# Returns: record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string>
# operationId: GetSettings
export def "get-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rns/settings"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit Subscriptions settings
#
# POST /api/rns/settings
# Returns: record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string>
# operationId: EditSettings
export def "edit-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --default-sla: string # Default delivery method. (nullable)
  delivery_channels: list<string> # Array containing delivery channels. (default: [], e.g. delivery)
  execution_hour_in_utc: int # Indicates the time future subscription orders will be generated. (default: 0, e.g. 9)
  --is-multiple-installments-enabled-on-creation: oneof<nothing, bool> # Defines whether or not multiple installments are enabled when a subscription is created. (default: false, e.g. false)
  --is-multiple-installments-enabled-on-update: oneof<nothing, bool> # Defines whether or not multiple installments are enabled when a subscription is updated. (default: false, e.g. false)
  --is-using-v3: oneof<nothing, bool> # Indicates whether or not Subscriptions V3 is enabled. (default: false, e.g. true)
  --manual-price-allowed: oneof<nothing, bool> # When set to `true`, this property enables manual price configuration in subscription items. This is valid for all existing subscriptions, provided that there is a manual price configured and that `isUsingV3` is `true`. (default: false, e.g. false)
  --on-migration-process: oneof<nothing, bool> # Indicates whether or not the account is in the migration process to Subscriptions V3. (default: false, e.g. false)
  order_custom_data_app_id: string # When filled, this field passes along the `customData` infomration in the order to the future recurrent subscription orders.
  --postpone-expiration: oneof<nothing, bool> # Defines whether or not the expiration of subscriptions can be postponed. (default: false, e.g. false)
  --random-id-generation: oneof<nothing, bool> # Defines whether or not the subscription order IDs will be randomly generated. (default: false, e.g. false)
  sla_option: string # Delivery method. (default: "", e.g. NONE)
  --use-item-price-from-original-order: oneof<nothing, bool> # When set to `true`, this property enables using the manual price for each item from the original subscription order. This is only valid for new subscriptions, created from the moment this configuration is enabled. For this to work, it is mandatory that the `manualPriceAllowed` property is set to `true` and that `isUsingV3` is `true`. (default: false, e.g. false)
  workflow_version: string # Workflow version. (default: "", e.g. 1.1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rns/settings"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultSla, var: default_sla}, {name: deliveryChannels, var: delivery_channels}, {name: executionHourInUtc, var: execution_hour_in_utc}, {name: isMultipleInstallmentsEnabledOnCreation, var: is_multiple_installments_enabled_on_creation, required: true}, {name: isMultipleInstallmentsEnabledOnUpdate, var: is_multiple_installments_enabled_on_update, required: true}, {name: isUsingV3, var: is_using_v3, required: true}, {name: manualPriceAllowed, var: manual_price_allowed, required: true}, {name: onMigrationProcess, var: on_migration_process, required: true}, {name: orderCustomDataAppId, var: order_custom_data_app_id}, {name: postponeExpiration, var: postpone_expiration, required: true}, {name: randomIdGeneration, var: random_id_generation, required: true}, {name: slaOption, var: sla_option}, {name: useItemPriceFromOriginalOrder, var: use_item_price_from_original_order, required: true}, {name: workflowVersion, var: workflow_version}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: SUBSCRIPTIONS_API_V3_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, default_sla: $default_sla, delivery_channels: $delivery_channels, execution_hour_in_utc: $execution_hour_in_utc, is_multiple_installments_enabled_on_creation: $is_multiple_installments_enabled_on_creation, is_multiple_installments_enabled_on_update: $is_multiple_installments_enabled_on_update, is_using_v3: $is_using_v3, manual_price_allowed: $manual_price_allowed, on_migration_process: $on_migration_process, order_custom_data_app_id: $order_custom_data_app_id, postpone_expiration: $postpone_expiration, random_id_generation: $random_id_generation, sla_option: $sla_option, use_item_price_from_original_order: $use_item_price_from_original_order, workflow_version: $workflow_version
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
