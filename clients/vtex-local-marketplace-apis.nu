# Auto-generated client for Marketplace API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Marketplace-APIs/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.MARKETPLACE_API_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.MARKETPLACE_API_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "MARKETPLACE_API_TOKEN"
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br/api"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let return_types = {
    getofferslist: "table<BrandId: int, CategoryId: int, LastModified: string, ProductId: string, ProductName: string, Skus: list<record>>"
    retrieve-mapping: "table<marketplaceSalesChannel: string, sellerChannel: string>"
    upsert-mapping: "table<marketplaceSalesChannel: string, sellerChannel: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["inventory-notification" "price-notification" "getofferslist" "get-productoffers" "get-sk-uoffers" "list-seller-leads" "create-seller-lead" "remove-seller-lead" "retrieve-seller-lead" "accept-seller-lead" "create-seller-from-seller-lead" "resend-seller-lead-request" "get-list-sellers" "upsert-seller-request" "get-retrieve-seller" "update-seller" "list-seller-commissions" "bulk-upsert-seller-commissions" "remove-seller-commissions" "retrieve-seller-commissions" "upsert-seller-commissions" "retrieve-mapping" "upsert-mapping" "commands"] | sort) } | get name | first)
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

# Notify marketplace of inventory update
#
# POST /notificator/{sellerId}/changenotification/{skuId}/inventory
# operationId: InventoryNotification
export def "inventory-notification" [
  seller_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. The notification will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: post
    path: "/notificator/{sellerId}/changenotification/{skuId}/inventory"
    path_params: [{name: sellerId, var: seller_id}, {name: skuId, var: sku_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [202]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, sku_id: $sku_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notify marketplace of price update
#
# POST /notificator/{sellerId}/changenotification/{skuId}/price
# operationId: PriceNotification
export def "price-notification" [
  seller_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. The notification will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: post
    path: "/notificator/{sellerId}/changenotification/{skuId}/price"
    path_params: [{name: sellerId, var: seller_id}, {name: skuId, var: sku_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [202]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, sku_id: $sku_id, account_name: $account_name, environment: $environment, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Matched Offers List
#
# GET /offer-manager/pvt/offers
# Returns: table<BrandId: int, CategoryId: int, LastModified: string, ProductId: string, ProductName: string, Skus: list<record>>
# operationId: Getofferslist
export def "getofferslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # Criteria used to sort the list of offers. For sorting values in ascending order, use `asc`, while for descending order, use `desc`. To fill in the field, insert the sorting criteria, followed by 'asc', or 'desc', separated by a comma. You can sort by the following criteria: - **price:** sorts offers by price. *Ascending* goes from lowest to highest price, while *Descending* goes from highest to lowest price. - **name:** sorts offers by *productName*, in alphabetical order. *Ascending* goes from *A* to *Z*, while *Descending* goes from *Z* to *A*. - **availability:** availability in the sales channel (sc). The default value is 1. Ex. sort=availability,desc Ex. sort=name,asc Ex. price,desc (e.g. availability,desc)
  --rows: int # Number of rows included in the response. Each row corresponds to a single offer. The default amount of rows in the response is 1, and the maximum amount is 50. To have more than one offer listed in the response, please add the `rows` parameter with a number greater than 1. (default: 20)
  --start: int # Number corresponding to the row from which the offer list will begin, used for pagination. Filters the list of offers by retrieving the offers starting from the row defined. The default value is 0, if the param is not included in the call. (default: 21)
  --fq: string # This filter query can be used to filter offers by the criteria described below. It should be filled in by following the format: `fq={{criteriaName}}:{{criteriaValue}}`. - **productId:** integer of the product ID - **productName:** string of the product's name - **skuId:** integer of the SKU ID - **eanId:** string of the EAN ID - **refId:** string of the Ref ID - **categoryId:** integer of the category ID - **brandId:** integer of the brand ID - **sellerId:** string of the seller ID - **sc:** integer of the sales channel's ID (trade policy in VTEX) Ex: skuId:172 Ex: categoryId:13 Ex. productName:Product example-123 (e.g. skuId:172)
  --account-name: string # Name of the VTEX account. Used as part of the URL (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/offer-manager/pvt/offers"
    query: [{name: sort, var: sort}, {name: rows, var: rows}, {name: start, var: start}, {name: fq, var: fq}, {name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    sort: $sort, rows: $rows, start: $start, fq: $fq, account_name: $account_name, environment: $environment, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Matched Offer's Data by Product ID
#
# GET /offer-manager/pvt/product/{productId}
# operationId: GetProductoffers
export def "get-productoffers" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/offer-manager/pvt/product/{productId}"
    path_params: [{name: productId, var: product_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, account_name: $account_name, environment: $environment, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Matched Offer's Data by SKU ID
#
# GET /offer-manager/pvt/product/{productId}/sku/{skuId}
# operationId: GetSKUoffers
export def "get-sk-uoffers" [
  product_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/offer-manager/pvt/product/{productId}/sku/{skuId}"
    path_params: [{name: productId, var: product_id}, {name: skuId, var: sku_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    product_id: $product_id, sku_id: $sku_id, account_name: $account_name, environment: $environment, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Seller Leads
#
# GET /seller-register/pvt/seller-leads
# operationId: ListSellerLeads
export def "list-seller-leads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --offset: int # This field determines the limit used to retrieve the list of sellers. The response includes objects starting `from` the value inputted here. (required, format: int32, default: 0)
  --limit: int # This field determines the limit used to retrieve the list of sellers. The response includes objects until the value inputted here. (required, format: int32, default: 15)
  --is-connected: string # Query param that enables results to be filter by whether the seller lead is already connected to the marketplace or not. (required, default: "")
  --search: string # Custom search field, that filters sellers invited by specific marketplace operator's email. (required, default: user email)
  --status: string # Seller Lead's status. Includes `accepted`, `connected` or `invited`. (required, default: invited)
  --order-by: string # Query param determining how data will be ordered in the response, ordering by name or ID in descending our ascending order. Includes the following values: `namesort` = desc/asc `idsort` = desc/asc (required)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/seller-register/pvt/seller-leads"
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}, {name: offset, var: offset, required: true, default: 0}, {name: limit, var: limit, required: true, default: 15}, {name: isConnected, var: is_connected, required: true, default: ""}, {name: search, var: search, required: true, default: "user email"}, {name: status, var: status, required: true, default: invited}, {name: orderBy, var: order_by, required: true}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    account_name: $account_name, environment: $environment, offset: $offset, limit: $limit, is_connected: $is_connected, search: $search, status: $status, order_by: $order_by, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite Seller Lead
#
# POST /seller-register/pvt/seller-leads
# operationId: CreateSellerLead
export def "create-seller-lead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (required, default: apiexample)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  account_id: string # Marketplace's account ID (default: 5fb38ace-d95e-45ad-970d-ee97cce9fbcd)
  accountable: record # shape: {email: string, name: string, phone: string}
  address: record # shape: {city: string, complement: string, neighborhood: string, number: string, postalcode: string, state: string, street: string}
  document: string # Company's legal document code. (default: 12345671000)
  email: string # default: email@email.com
  --has-accepted-legal-terms: oneof<nothing, bool> # Indicates if the seller has accepted the platform's legal terms and conditions. (default: true)
  sales_channel: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/como-funciona-uma-politica-comercial--6Xef8PZiFm40kg2STrMkMV#master-data)) associated to the seller account created. (default: 1)
  seller_account_name: string # Name of the seller's account, part of the url of their VTEX Admin. (default: seller123)
  seller_email: string # Seller's contact email; (default: selleremail@email.com)
  seller_name: string # Seller's store's name. (default: Seller Name)
  seller_type: int # Type of seller, including: `1`: regular seller `2`: whitelabel seller (format: int32, default: 1)
]: any -> any {
  $in | http-request {
    method: post
    path: "/seller-register/pvt/seller-leads"
    query: [{name: accountName, var: account_name, required: true, default: apiexample}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: accountable, var: accountable}, {name: address, var: address}, {name: document, var: document}, {name: email, var: email}, {name: hasAcceptedLegalTerms, var: has_accepted_legal_terms, required: true}, {name: salesChannel, var: sales_channel}, {name: sellerAccountName, var: seller_account_name}, {name: sellerEmail, var: seller_email}, {name: sellerName, var: seller_name}, {name: sellerType, var: seller_type}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type, account_id: $account_id, accountable: $accountable, address: $address, document: $document, email: $email, has_accepted_legal_terms: $has_accepted_legal_terms, sales_channel: $sales_channel, seller_account_name: $seller_account_name, seller_email: $seller_email, seller_name: $seller_name, seller_type: $seller_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Seller Lead
#
# DELETE /seller-register/pvt/seller-leads/{sellerLeadId}
# operationId: RemoveSellerLead
export def "remove-seller-lead" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: delete
    path: "/seller-register/pvt/seller-leads/{sellerLeadId}"
    path_params: [{name: sellerLeadId, var: seller_lead_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_lead_id: $seller_lead_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Seller Lead's Data by Id
#
# GET /seller-register/pvt/seller-leads/{sellerLeadId}
# operationId: RetrieveSellerLead
export def "retrieve-seller-lead" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/seller-register/pvt/seller-leads/{sellerLeadId}"
    path_params: [{name: sellerLeadId, var: seller_lead_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_lead_id: $seller_lead_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept Seller Lead
#
# PUT /seller-register/pvt/seller-leads/{sellerLeadId}
# operationId: AcceptSellerLead
export def "accept-seller-lead" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  account_id: string # Marketplace's account ID (default: 5fb38ace-d95e-45ad-970d-ee97cce9fbcd)
  accountable: record # shape: {email: string, name: string, phone: string}
  address: record # shape: {city: string, complement: string, neighborhood: string, number: string, postalcode: string, state: string, street: string}
  document: string # Company's legal document code. (default: 12345671000)
  email: string # email of the admin responsible for the seller. (default: seller@email.com)
  --has-accepted-legal-terms: oneof<nothing, bool> # Indicates if the seller has accepted the platform's legal terms and conditions. (default: true)
  sales_channel: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/como-funciona-uma-politica-comercial--6Xef8PZiFm40kg2STrMkMV#master-data)) associated to the seller account created. (default: 1)
  seller_account_name: string # Name of the seller's account, part of the url of their VTEX Admin. (default: seller123)
  seller_email: string # Seller's contact email. (default: selleremail@email.com)
  seller_name: string # Seller's store's name. (default: Seller Name)
  seller_type: int # Type of seller, including: `1`: regular seller `2`: whitelabel seller (format: int32, default: 1)
]: any -> any {
  $in | http-request {
    method: put
    path: "/seller-register/pvt/seller-leads/{sellerLeadId}"
    path_params: [{name: sellerLeadId, var: seller_lead_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: accountable, var: accountable}, {name: address, var: address}, {name: document, var: document}, {name: email, var: email}, {name: hasAcceptedLegalTerms, var: has_accepted_legal_terms, required: true}, {name: salesChannel, var: sales_channel}, {name: sellerAccountName, var: seller_account_name}, {name: sellerEmail, var: seller_email}, {name: sellerName, var: seller_name}, {name: sellerType, var: seller_type}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_lead_id: $seller_lead_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type, account_id: $account_id, accountable: $accountable, address: $address, document: $document, email: $email, has_accepted_legal_terms: $has_accepted_legal_terms, sales_channel: $sales_channel, seller_account_name: $seller_account_name, seller_email: $seller_email, seller_name: $seller_name, seller_type: $seller_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Seller From Lead
#
# PUT /seller-register/pvt/seller-leads/{sellerLeadId}/seller
# operationId: CreateSellerFromSellerLead
export def "create-seller-from-seller-lead" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Marketplace's account name, the same one inputted on the endpoint's path. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --is-active: oneof<nothing, bool> # Whether the Seller Lead is `active` or not in Seller Portal. This request only supports the value `false` in this field. If that´s not the case, the request will respond with an internal error. (required, default: false)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: put
    path: "/seller-register/pvt/seller-leads/{sellerLeadId}/seller"
    path_params: [{name: sellerLeadId, var: seller_lead_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}, {name: isActive, var: is_active, required: true, default: false}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_lead_id: $seller_lead_id, account_name: $account_name, environment: $environment, is_active: $is_active, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Seller Lead Invite
#
# PUT /seller-register/pvt/seller-leads/{sellerLeadId}/status
# operationId: ResendSellerLeadRequest
export def "resend-seller-lead-request" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  status: string # Seller Lead's status. Includes `accepted`, `connected` or `invited`. (default: accepted)
]: any -> any {
  $in | http-request {
    method: put
    path: "/seller-register/pvt/seller-leads/{sellerLeadId}/status"
    path_params: [{name: sellerLeadId, var: seller_lead_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_lead_id: $seller_lead_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type, status: $status
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Sellers
#
# GET /seller-register/pvt/sellers
# operationId: GetListSellers
export def "get-list-sellers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --from: float # The start number of pagination, being `0` the default value. (default: 0)
  --to: float # The end number of pagination, being `100` the default value. (default: 100)
  --keyword: string # Search sellers by a keyword in `sellerId` or `sellerName`. (default: keyword)
  --integration: string # Filters sellers by the name of who made the integration, if VTEX or an external hub. The possible values for VTEX integrations are: `vtex-sellerportal`, `vtex-seller` and `vtex-franchise`. (default: vtex-seller)
  --group: string # Groups are defined by keywords that group sellers into categories defined by the marketplace. (default: Group)
  --is-active: oneof<nothing, bool> # Enables to filter sellers that are active (`true`) or unactive (`false`) in the marketplace. (default: false)
  --is-better-scope: oneof<nothing, bool> # The flag `isBetterScope` is used by the VTEX Checkout to simulate shopping carts, products, and shipping only in sellers with the field set as `true`, avoiding performance issues. When used as a query param, `isBetterScope` filters sellers that have the flag set as `true` or `false`. (default: false)
  --is-vtex: oneof<nothing, bool> # When set as `true`, the list returned will be of sellers who have a VTEX store configured. When set as `false`, the list will be of sellers who do not have a VTEX store configured. (default: false)
  --sc: string # Filters sellers available for the marketplace's sales channel (or [trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) indicated in this field. (default: 1)
  --seller-type: int # Filters sellers by their type, which can be regular seller (`1`) or whitelabel seller (`2`). (default: 1)
  --sort: string # Narrow the search filtering by the fields: `id`, `name` or `pendingoffers`. The list retrieved can be organized in an ascending (`asc`) or descending (`desc`) order. The standardized format is `{field}:{order}`, and the default value is `id:asc`. (default: id:asc)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/seller-register/pvt/sellers"
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}, {name: from, var: from}, {name: to, var: to}, {name: keyword, var: keyword}, {name: integration, var: integration}, {name: "group ", var: group}, {name: isActive, var: is_active}, {name: isBetterScope, var: is_better_scope}, {name: isVtex, var: is_vtex}, {name: sc, var: sc}, {name: sellerType, var: seller_type}, {name: sort, var: sort}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    account_name: $account_name, environment: $environment, from: $from, to: $to, keyword: $keyword, integration: $integration, group: $group, is_active: $is_active, is_better_scope: $is_better_scope, is_vtex: $is_vtex, sc: $sc, seller_type: $seller_type, sort: $sort, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure Seller Account
#
# POST /seller-register/pvt/sellers
# operationId: UpsertSellerRequest
export def "upsert-seller-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Marketplace's account name, the same one inputted on the endpoint's path. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  csc_identification: string # SKU Seller Identification (default: cscidentification 123)
  account: string # Seller's account name (default: partner01)
  --allow-hybrid-payments: oneof<nothing, bool> # Flag that allows customers to use gift cards from the seller to buy their products on the marketplace. It identifies purchases made with a gift card so that only the final price (with discounts applied) is paid to the seller. (default: false)
  available_sales_channels: list # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/como-funciona-uma-politica-comercial--6Xef8PZiFm40kg2STrMkMV#master-data)) available. (default: []) — item shape: {id: int, isSelected: bool, name: string}
  catalog_system_endpoint: string # URL of the endpoint of the seller's catalog. This field will only be displayed if the seller type is VTEX Store. The field format will be as follows: `https://{sellerName}.vtexcommercestable.com.br/api/catalog_system/.` (default: https://pedrostore.vtexcommercestable.com.br/api/catalog_system/)
  channel: string # Channel's name. (default: channel name)
  delivery_policy: string # Text describing the delivery policy previously agreed between the marketplace and the seller. (default: Describe delivery policy)
  description: string # String describing the seller (default: Seller A, from the B industry.)
  email: string # email of the admin responsible for the seller. (default: seller@email.com)
  exchange_return_policy: string # Text describing the exchange and return policy previously agreed between the marketplace and the seller. (default: Describe exchange and returns policy)
  fulfillment_endpoint: string # URL of the endpoint for fulfillment of seller's orders, which the marketplace will use to communicate with the seller. For **external sellers**, please include the URL of the seller's endpoint. External sellers have different endpoint standards. The seller must inform this endpoint to the marketplace so that the marketplace can complete the configuration process. For **VTEX Stores**, the field format will be as follows: `https://{SellerName}.vtexcommercestable.com.br/api/fulfillment?&sc={TradePolicyID}`. The value `SellerName` corresponds to the store name if the seller is a VTEX store. The value `TradePolicyID` corresponds to the [trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV#master-data) created by the seller in their own VTEX environment. The seller must inform this ID to the marketplace so that the marketplace can complete the configuration process. The value `AffiliateID` corresponds to the 3-digit affiliate identification code created by the seller. The seller must inform this ID to the marketplace so that the marketplace can complete the configuration process. To configure the [Multilevel Omnichannel Inventory](https://developers.vtex.com/vtex-rest-api/docs/multilevel-omnichannel-inventory) feature, fill in this field with the checkout endpoint following this example: `https://{{sellerAccount}}.vtexcommercestable.com.br/api/checkout?affiliateid={{affiliateId}}&sc={{salesChannel` (default: http://{SellerName}.vtexcommercestable.com.br/api/fulfillment?&sc={TradePolicyID})
  fulfillment_seller_id: string # Identification code of the seller responsible for fulfilling the order. This is an optional field used when a seller sells SKUs from another seller. If the seller sells their own SKUs, it must be nulled. (default: seller1)
  --groups: list # Array of groups attached to the seller. Groups are defined by key-words that group sellers into categories defined by the marketplace when adding a new seller through the [Configure Seller Account](https://developers.vtex.com/vtex-rest-api/reference/sellers#putupsertseller) endpoint. It is possible to filter sellers by group in the Seller Management page in your VTEX Admin. Know more about groups through our [Seller Management](https://help.vtex.com/en/tutorial/gerenciamento-de-sellers-beta--6eEiOISwxuAWJ8w6MtK7iv#groups) documentation. — item shape: {id?: string, name?: string}
  id: string # Seller ID assigned by the marketplace. We recommend filling it in with the seller's account name. (default: seller123)
  --is-active: oneof<nothing, bool> # Whether the seller is active on the marketplace or not. (default: true)
  --is-better-scope: oneof<nothing, bool> # Flag used by the VTEX Checkout to simmulate shopping carts, products and shipping only in sellers with the boolean set as `true`, avoiding performance issues. (default: true)
  --is-vtex: oneof<nothing, bool> # Flag determining whether the seller configured is a VTEX store or not. (default: true)
  name: string # Name of the seller's store, configured in the seller's environment. (default: Seller Name)
  --password: string # User password, if you are using a hub to integrate with the external seller. (nullable, default: integrationHubPassword)
  sales_channel: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) associated to the seller account created. If no value is specified, the system will automatically use the sales channel configured in the seller's [affiliate](https://help.vtex.com/en/tutorial/configuring-affiliates--tutorials_187) ID. (default: 1)
  score: float # Score attributed to this seller. (default: 0)
  --security-privacy-policy: string # Text describing the security policy previously agreed between the marketplace and the seller. (nullable, default: Describe privacy and security policy)
  seller_commission_configuration: record
  seller_type: int # Type of seller, including: `1`: regular seller `2`: whitelabel seller (format: int32, default: 1)
  tax_code: string # This code is the Identity Number for the legal entity and is linked to information in its base country. (default: 34444)
  trust_policy: string # the marketplace must first allow VTEX to share clients’ email addresses with the seller. To do so, it is necessary to set 'AllowEmailSharing' as the value for the TrustPolicy field (default: AllowEmailSharing)
  --user: string # Username, if you are using a hub to integrate with the external seller. (nullable, default: integrationHubUserName)
]: any -> any {
  $in | http-request {
    method: post
    path: "/seller-register/pvt/sellers"
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CSCIdentification, var: csc_identification}, {name: account, var: account}, {name: allowHybridPayments, var: allow_hybrid_payments, required: true}, {name: availableSalesChannels, var: available_sales_channels}, {name: catalogSystemEndpoint, var: catalog_system_endpoint}, {name: channel, var: channel}, {name: deliveryPolicy, var: delivery_policy}, {name: description, var: description}, {name: email, var: email}, {name: exchangeReturnPolicy, var: exchange_return_policy}, {name: fulfillmentEndpoint, var: fulfillment_endpoint}, {name: fulfillmentSellerId, var: fulfillment_seller_id}, {name: groups, var: groups}, {name: id, var: id}, {name: isActive, var: is_active, required: true}, {name: isBetterScope, var: is_better_scope, required: true}, {name: isVtex, var: is_vtex, required: true}, {name: name, var: name}, {name: password, var: password}, {name: salesChannel, var: sales_channel}, {name: score, var: score}, {name: securityPrivacyPolicy, var: security_privacy_policy}, {name: sellerCommissionConfiguration, var: seller_commission_configuration}, {name: sellerType, var: seller_type}, {name: taxCode, var: tax_code}, {name: trustPolicy, var: trust_policy}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type, csc_identification: $csc_identification, account: $account, allow_hybrid_payments: $allow_hybrid_payments, available_sales_channels: $available_sales_channels, catalog_system_endpoint: $catalog_system_endpoint, channel: $channel, delivery_policy: $delivery_policy, description: $description, email: $email, exchange_return_policy: $exchange_return_policy, fulfillment_endpoint: $fulfillment_endpoint, fulfillment_seller_id: $fulfillment_seller_id, groups: $groups, id: $id, is_active: $is_active, is_better_scope: $is_better_scope, is_vtex: $is_vtex, name: $name, password: $password, sales_channel: $sales_channel, score: $score, security_privacy_policy: $security_privacy_policy, seller_commission_configuration: $seller_commission_configuration, seller_type: $seller_type, tax_code: $tax_code, trust_policy: $trust_policy, user: $user
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Seller data by ID
#
# GET /seller-register/pvt/sellers/{sellerId}
# operationId: GetRetrieveSeller
export def "get-retrieve-seller" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --sc: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) associated to the seller account created. (default: 1)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/seller-register/pvt/sellers/{sellerId}"
    path_params: [{name: sellerId, var: seller_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}, {name: sc, var: sc}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, account_name: $account_name, environment: $environment, sc: $sc, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Seller by Seller ID
#
# PATCH /seller-register/pvt/sellers/{sellerId}
# operationId: UpdateSeller
export def "update-seller" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --body: list
]: any -> any {
  $in | http-request {
    method: patch
    path: "/seller-register/pvt/sellers/{sellerId}"
    path_params: [{name: sellerId, var: seller_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Seller Commissions by seller ID
#
# GET /seller-register/pvt/sellers/{sellerId}/commissions
# operationId: ListSellerCommissions
export def "list-seller-commissions" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/seller-register/pvt/sellers/{sellerId}/commissions"
    path_params: [{name: sellerId, var: seller_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert Seller Commissions in Bulk
#
# PUT /seller-register/pvt/sellers/{sellerId}/commissions/categories
# operationId: BulkUpsertSellerCommissions
export def "bulk-upsert-seller-commissions" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/seller-register/pvt/sellers/{sellerId}/commissions/categories"
    path_params: [{name: sellerId, var: seller_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Seller Commissions by Category ID
#
# DELETE /seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}
# operationId: RemoveSellerCommissions
export def "remove-seller-commissions" [
  seller_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: delete
    path: "/seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}"
    path_params: [{name: sellerId, var: seller_id}, {name: categoryId, var: category_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, category_id: $category_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Seller Commissions by Category ID
#
# GET /seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}
# operationId: RetrieveSellerCommissions
export def "retrieve-seller-commissions" [
  seller_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}"
    path_params: [{name: sellerId, var: seller_id}, {name: categoryId, var: category_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, category_id: $category_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert Seller Commissions by Category ID
#
# PUT /seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}
# operationId: UpsertSellerCommissions
export def "upsert-seller-commissions" [
  seller_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --category-full-path: string # Full path to the SKU's category. It should be written as {department}/{category}. For example: if the department is **Appliances** and the category is **Oven**, the full path should be 'Appliances/Oven'. (nullable, default: Appliances/Oven)
  --body-category-id: string # Marketplace's Category ID that the product belongs to, configured in the Catalog. (default: 6) (spec name: categoryId)
  freight_commission_percentage: float # Percentage of the comission applied to the freight in decimals. (default: 2.43)
  product_commission_percentage: float # Percentage of the comission applied to the product in decimals. (default: 9.85)
]: any -> any {
  $in | http-request {
    method: put
    path: "/seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}"
    path_params: [{name: sellerId, var: seller_id}, {name: categoryId, var: category_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: categoryFullPath, var: category_full_path}, {name: categoryId, var: body_category_id, required: true}, {name: freightCommissionPercentage, var: freight_commission_percentage}, {name: productCommissionPercentage, var: product_commission_percentage}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, category_id: $category_id, account_name: $account_name, environment: $environment, hdr_accept: $hdr_accept, content_type: $content_type, category_full_path: $category_full_path, body_category_id: $body_category_id, freight_commission_percentage: $freight_commission_percentage, product_commission_percentage: $product_commission_percentage
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Sales Channel Mapping Data
#
# GET /seller-register/pvt/sellers/{sellerId}/sales-channel/mapping
# Returns: table<marketplaceSalesChannel: string, sellerChannel: string>
# operationId: RetrieveMapping
export def "retrieve-mapping" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. Used as part of the URL (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --an: string # Marketplace's account name, the same one inputted on the endpoint's path. (required, default: apiexamples)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/seller-register/pvt/sellers/{sellerId}/sales-channel/mapping"
    path_params: [{name: sellerId, var: seller_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}, {name: an, var: an, required: true, default: apiexamples}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, account_name: $account_name, environment: $environment, an: $an, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert Sales Channel Mapping
#
# PUT /seller-register/pvt/sellers/{sellerId}/sales-channel/mapping
# Returns: table<marketplaceSalesChannel: string, sellerChannel: string>
# operationId: UpsertMapping
export def "upsert-mapping" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. Used as part of the URL. (required, default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (required, default: vtexcommercestable)
  --an: string # Marketplace's account name, the same one inputted on the endpoint's path. (required, default: apiexamples)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/seller-register/pvt/sellers/{sellerId}/sales-channel/mapping"
    path_params: [{name: sellerId, var: seller_id}]
    query: [{name: accountName, var: account_name, required: true, default: apiexamples}, {name: environment, var: environment, required: true, default: vtexcommercestable}, {name: an, var: an, required: true, default: apiexamples}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_API_APPTOKEN_TOKEN}]
  } {
    seller_id: $seller_id, account_name: $account_name, environment: $environment, an: $an, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
