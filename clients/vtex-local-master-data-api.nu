# Auto-generated client for Master Data API - v2 v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Master-Data-API-/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.MASTER_DATA_API_V2_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.MASTER_DATA_API_V2_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "MASTER_DATA_API_V2_TOKEN"
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let return_types = {
    create-new-customer-address: "record<Href: string, Id: string>"
    delete-customer-address: "record<Href: string, Id: string>"
    update-customer-address: "record<Href: string, Id: string>"
    create-new-customer-profilev2: "record<Href: string, Id: string>"
    delete-customer-profile: "record<Href: string, Id: string>"
    update-customer-profile: "record<Href: string, Id: string>"
    createorupdatepartialdocument: "record<Href: string, Id: string>"
    createnewdocument: "record<Href: string, Id: string>"
    getdocument: "record<accountId: string, accountName: string, dataEntityId: string, id: string>"
    updatepartialdocument: "record<Href: string, Id: string>"
    updateentiredocument: "record<Href: string, Id: string>"
    listversions: "table<date: string, document: record, id: string>"
    getversion: "record<author: string, document: record<accountId: string, accountName: string, carttag: string, checkouttag: string, dataEntityId: string, departmentVisitedTag: record<DisplayValue: string, Scores: record>, email: string, followers: list<string>, id: string, rclastsession: string, rclastsessiondate: string>, id: string>"
    putversion: "record<Href: string, Id: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-new-customer-address" "delete-customer-address" "update-customer-address" "create-new-customer-profilev2" "delete-customer-profile" "update-customer-profile" "createorupdatepartialdocument" "createnewdocument" "deletedocument" "getdocument" "updatepartialdocument" "updateentiredocument" "validatedocumentbyclusters" "listversions" "getversion" "putversion" "getindices" "putindices" "deleteindexbyname" "getindexbyname" "getschemas" "deleteschemabyname" "getschemabyname" "saveschemabyname" "scrolldocuments" "searchdocuments" "commands"] | sort) } | get name | first)
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

# Create new customer address
#
# POST /api/dataentities/Address/documents
# Returns: record<Href: string, Id: string>
# operationId: CreateNewCustomerAddress
export def "create-new-customer-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --address-name: string # Address name. (nullable, e.g. My house)
  --address-type: string # Type of address. For example, `Residential` or `Pickup`, among others. (nullable, e.g. residential)
  --city: string # City of the shipping address. (nullable, e.g. Rio de Janeiro)
  --complement: string # Complement to the shipping address in case it applies. (nullable, e.g. 3rd floor)
  --country: string # Three letter ISO code of the country of the shipping address. (nullable, e.g. BRA)
  --neighborhood: string # Neighborhood of the address. (nullable, e.g. Botafogo)
  --number: string # Number of the building, house or apartment in the shipping address. (nullable, e.g. 300)
  --postal-code: string # Postal Code. (nullable, e.g. 12345-000)
  --receiver-name: string # Name of the person who is going to receive the order. (nullable, e.g. Clark Kent.)
  --reference: string # Complement that might help locate the shipping address more precisely in case of delivery. (nullable, e.g. Grey building)
  --state: string # State of the shipping address. (nullable, e.g. Rio de Janeiro)
  --street: string # Street of the address. (nullable, e.g. Praia de Botafogo)
  --user-id: string # ID of the customer to whom the address belongs. (nullable, e.g. 7e03m794-a33a-11e9-84rt6-0adfa64s5a8e)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/dataentities/Address/documents"
    query: [{name: _schema, var: schema}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addressName, var: address_name}, {name: addressType, var: address_type}, {name: city, var: city}, {name: complement, var: complement}, {name: country, var: country}, {name: neighborhood, var: neighborhood}, {name: number, var: number}, {name: postalCode, var: postal_code}, {name: receiverName, var: receiver_name}, {name: reference, var: reference}, {name: state, var: state}, {name: street, var: street}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    schema: $schema, content_type: $content_type, hdr_accept: $hdr_accept, address_name: $address_name, address_type: $address_type, city: $city, complement: $complement, country: $country, neighborhood: $neighborhood, number: $number, postal_code: $postal_code, receiver_name: $receiver_name, reference: $reference, state: $state, street: $street, user_id: $user_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete customer address
#
# DELETE /api/dataentities/Address/documents/{id}
# Returns: record<Href: string, Id: string>
# operationId: DeleteCustomerAddress
export def "delete-customer-address" [
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
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/dataentities/Address/documents/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update customer address
#
# PATCH /api/dataentities/Address/documents/{id}
# Returns: record<Href: string, Id: string>
# operationId: UpdateCustomerAddress
export def "update-customer-address" [
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
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --address-name: string # Address name. (nullable, e.g. My house)
  --address-type: string # Type of address. For example, `Residential` or `Pickup`, among others. (nullable, e.g. residential)
  --city: string # City of the shipping address. (nullable, e.g. Rio de Janeiro)
  --complement: string # Complement to the shipping address in case it applies. (nullable, e.g. 3rd floor)
  --country: string # Three letter ISO code of the country of the shipping address. (nullable, e.g. BRA)
  --neighborhood: string # Neighborhood of the address. (nullable, e.g. Botafogo)
  --number: string # Number of the building, house or apartment in the shipping address. (nullable, e.g. 300)
  --postal-code: string # Postal Code. (nullable, e.g. 12345-000)
  --receiver-name: string # Name of the person who is going to receive the order. (nullable, e.g. Clark Kent.)
  --reference: string # Complement that might help locate the shipping address more precisely in case of delivery. (nullable, e.g. Grey building)
  --state: string # State of the shipping address. (nullable, e.g. Rio de Janeiro)
  --street: string # Street of the address. (nullable, e.g. Praia de Botafogo)
  --user-id: string # ID of the customer to whom the address belongs. (nullable, e.g. 7e03m794-a33a-11e9-84rt6-0adfa64s5a8e)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/dataentities/Address/documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: _schema, var: schema}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addressName, var: address_name}, {name: addressType, var: address_type}, {name: city, var: city}, {name: complement, var: complement}, {name: country, var: country}, {name: neighborhood, var: neighborhood}, {name: number, var: number}, {name: postalCode, var: postal_code}, {name: receiverName, var: receiver_name}, {name: reference, var: reference}, {name: state, var: state}, {name: street, var: street}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    id: $id, schema: $schema, content_type: $content_type, hdr_accept: $hdr_accept, address_name: $address_name, address_type: $address_type, city: $city, complement: $complement, country: $country, neighborhood: $neighborhood, number: $number, postal_code: $postal_code, receiver_name: $receiver_name, reference: $reference, state: $state, street: $street, user_id: $user_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new customer profile
#
# POST /api/dataentities/Client/documents
# Returns: record<Href: string, Id: string>
# operationId: CreateNewCustomerProfilev2
export def "create-new-customer-profilev2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --document: string # Client document. (nullable, e.g. 12345678900)
  --document-type: string # Client document type. (nullable, e.g. CPF)
  --email: string # Client email address. (nullable, e.g. clark.kent@examplemail.com)
  --first-name: string # Client first name. (nullable, e.g. Clark)
  --is-corporate: oneof<nothing, bool> # Indicates whether client is corporate. (nullable, e.g. false)
  --is-newsletter-opt-in: oneof<nothing, bool> # Indicates whether client otped to receive the store newsletter. (nullable, e.g. false)
  --last-name: string # Client last name. (nullable, e.g. Kent)
  --locale-default: string # Default locale, used to set store language and currency, for example. (nullable, e.g. en-US)
  --phone: string # Client telephone number. (nullable, e.g. +12025550195)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/dataentities/Client/documents"
    query: [{name: _schema, var: schema}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: documentType, var: document_type}, {name: email, var: email}, {name: firstName, var: first_name}, {name: isCorporate, var: is_corporate}, {name: isNewsletterOptIn, var: is_newsletter_opt_in}, {name: lastName, var: last_name}, {name: localeDefault, var: locale_default}, {name: phone, var: phone}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    schema: $schema, content_type: $content_type, hdr_accept: $hdr_accept, document: $document, document_type: $document_type, email: $email, first_name: $first_name, is_corporate: $is_corporate, is_newsletter_opt_in: $is_newsletter_opt_in, last_name: $last_name, locale_default: $locale_default, phone: $phone
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete customer profile
#
# DELETE /api/dataentities/Client/documents/{id}
# Returns: record<Href: string, Id: string>
# operationId: DeleteCustomerProfile
export def "delete-customer-profile" [
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
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/dataentities/Client/documents/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update customer profile
#
# PATCH /api/dataentities/Client/documents/{id}
# Returns: record<Href: string, Id: string>
# operationId: UpdateCustomerProfile
export def "update-customer-profile" [
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
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --document: string # Client document. (nullable, e.g. 12345678900)
  --document-type: string # Client document type. (nullable, e.g. CPF)
  --email: string # Client email address. (nullable, e.g. clark.kent@examplemail.com)
  --first-name: string # Client first name. (nullable, e.g. Clark)
  --is-corporate: oneof<nothing, bool> # Indicates whether client is corporate. (nullable, e.g. false)
  --is-newsletter-opt-in: oneof<nothing, bool> # Indicates whether client otped to receive the store newsletter. (nullable, e.g. false)
  --last-name: string # Client last name. (nullable, e.g. Kent)
  --locale-default: string # Default locale, used to set store language and currency, for example. (nullable, e.g. en-US)
  --phone: string # Client telephone number. (nullable, e.g. +12025550195)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/dataentities/Client/documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: _schema, var: schema}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: documentType, var: document_type}, {name: email, var: email}, {name: firstName, var: first_name}, {name: isCorporate, var: is_corporate}, {name: isNewsletterOptIn, var: is_newsletter_opt_in}, {name: lastName, var: last_name}, {name: localeDefault, var: locale_default}, {name: phone, var: phone}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    id: $id, schema: $schema, content_type: $content_type, hdr_accept: $hdr_accept, document: $document, document_type: $document_type, email: $email, first_name: $first_name, is_corporate: $is_corporate, is_newsletter_opt_in: $is_newsletter_opt_in, last_name: $last_name, locale_default: $locale_default, phone: $phone
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create partial document
#
# PATCH /api/dataentities/{dataEntityName}/documents
# Returns: record<Href: string, Id: string>
# operationId: Createorupdatepartialdocument
export def "createorupdatepartialdocument" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/dataentities/{dataEntityName}/documents"
    path_params: [{name: dataEntityName, var: data_entity_name}]
    query: [{name: _schema, var: schema}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, schema: $schema, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new document
#
# POST /api/dataentities/{dataEntityName}/documents
# Returns: record<Href: string, Id: string>
# operationId: Createnewdocument
export def "createnewdocument" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/dataentities/{dataEntityName}/documents"
    path_params: [{name: dataEntityName, var: data_entity_name}]
    query: [{name: _schema, var: schema}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, schema: $schema, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete document
#
# DELETE /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Deletedocument
export def "deletedocument" [
  data_entity_name: string
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
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/dataentities/{dataEntityName}/documents/{id}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get document
#
# GET /api/dataentities/{dataEntityName}/documents/{id}
# Returns: record<accountId: string, accountName: string, dataEntityId: string, id: string>
# operationId: Getdocument
export def "getdocument" [
  data_entity_name: string
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
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/documents/{id}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, id: $id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update partial document
#
# PATCH /api/dataentities/{dataEntityName}/documents/{id}
# Returns: record<Href: string, Id: string>
# operationId: Updatepartialdocument
export def "updatepartialdocument" [
  data_entity_name: string
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
  --where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/dataentities/{dataEntityName}/documents/{id}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: id, var: id}]
    query: [{name: _where, var: where}, {name: _schema, var: schema}]
    header: [{name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, id: $id, where: $where, schema: $schema, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update entire document
#
# PUT /api/dataentities/{dataEntityName}/documents/{id}
# Returns: record<Href: string, Id: string>
# operationId: Updateentiredocument
export def "updateentiredocument" [
  data_entity_name: string
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
  --where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/dataentities/{dataEntityName}/documents/{id}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: id, var: id}]
    query: [{name: _where, var: where}, {name: _schema, var: schema}]
    header: [{name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, id: $id, where: $where, schema: $schema, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate document by clusters
#
# POST /api/dataentities/{dataEntityName}/documents/{id}/clusters
# operationId: Validatedocumentbyclusters
export def "validatedocumentbyclusters" [
  data_entity_name: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/dataentities/{dataEntityName}/documents/{id}/clusters"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: id, var: id}]
    header: [{name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, id: $id, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List versions
#
# GET /api/dataentities/{dataEntityName}/documents/{id}/versions
# Returns: table<date: string, document: record, id: string>
# operationId: Listversions
export def "listversions" [
  data_entity_name: string
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
  --load: oneof<nothing, bool> # If true, return all the fields in each version of the document (default: true)
  --fields: string # If `load` is true, the response will return only these specific fields (default: id,dataEntityId,isNewsletterOptIn,createdBy)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/documents/{id}/versions"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: id, var: id}]
    query: [{name: load, var: load}, {name: fields, var: fields}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, id: $id, load: $load, fields: $fields, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get version
#
# GET /api/dataentities/{dataEntityName}/documents/{id}/versions/{versionId}
# Returns: record<author: string, document: record<accountId: string, accountName: string, carttag: string, checkouttag: string, dataEntityId: string, departmentVisitedTag: record<DisplayValue: string, Scores: record>, email: string, followers: list<string>, id: string, rclastsession: string, rclastsessiondate: string>, id: string>
# operationId: Getversion
export def "getversion" [
  data_entity_name: string
  id: string
  version_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/documents/{id}/versions/{versionId}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: id, var: id}, {name: versionId, var: version_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, id: $id, version_id: $version_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Put version
#
# PUT /api/dataentities/{dataEntityName}/documents/{id}/versions/{versionId}
# Returns: record<Href: string, Id: string>
# operationId: Putversion
export def "putversion" [
  data_entity_name: string
  id: string
  version_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/api/dataentities/{dataEntityName}/documents/{id}/versions/{versionId}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: id, var: id}, {name: versionId, var: version_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, id: $id, version_id: $version_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get indices
#
# GET /api/dataentities/{dataEntityName}/indices
# operationId: Getindices
export def "getindices" [
  data_entity_name: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/indices"
    path_params: [{name: dataEntityName, var: data_entity_name}]
    header: [{name: Content-Type, var: content_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Put indices
#
# PUT /api/dataentities/{dataEntityName}/indices
# operationId: Putindices
export def "putindices" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fields: string # Comma-separted fields of the index
  --multiple: oneof<nothing, bool> # Determines whether the values need to be unique. If false, values must be unique.
  name: string # Name to identify the index
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/dataentities/{dataEntityName}/indices"
    path_params: [{name: dataEntityName, var: data_entity_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: fields, var: fields}, {name: multiple, var: multiple, required: true}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, fields: $fields, multiple: $multiple, name: $name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete index by name
#
# DELETE /api/dataentities/{dataEntityName}/indices/{index_name}
# operationId: Deleteindexbyname
export def "deleteindexbyname" [
  data_entity_name: string
  index_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/dataentities/{dataEntityName}/indices/{index_name}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: index_name, var: index_name}]
    header: [{name: Content-Type, var: content_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, index_name: $index_name, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get index by name
#
# GET /api/dataentities/{dataEntityName}/indices/{index_name}
# operationId: Getindexbyname
export def "getindexbyname" [
  data_entity_name: string
  index_name: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/indices/{index_name}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: index_name, var: index_name}]
    header: [{name: Content-Type, var: content_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, index_name: $index_name, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get schemas
#
# GET /api/dataentities/{dataEntityName}/schemas
# operationId: Getschemas
export def "getschemas" [
  data_entity_name: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/schemas"
    path_params: [{name: dataEntityName, var: data_entity_name}]
    header: [{name: Content-Type, var: content_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete schema by name
#
# DELETE /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Deleteschemabyname
export def "deleteschemabyname" [
  data_entity_name: string
  schema_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/dataentities/{dataEntityName}/schemas/{schemaName}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: schemaName, var: schema_name}]
    header: [{name: Content-Type, var: content_type, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, schema_name: $schema_name, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get schema by name
#
# GET /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Getschemabyname
export def "getschemabyname" [
  data_entity_name: string
  schema_name: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/schemas/{schemaName}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: schemaName, var: schema_name}]
    header: [{name: Content-Type, var: content_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, schema_name: $schema_name, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save schema by name
#
# PUT /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Saveschemabyname
export def "saveschemabyname" [
  data_entity_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  properties: record # e.g. {name: {type: string}} — shape: {name: record}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/dataentities/{dataEntityName}/schemas/{schemaName}"
    path_params: [{name: dataEntityName, var: data_entity_name}, {name: schemaName, var: schema_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, schema_name: $schema_name, properties: $properties
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scroll documents
#
# GET /api/dataentities/{dataEntityName}/scroll
# operationId: Scrolldocuments
export def "scrolldocuments" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Value of the header `X-VTEX-MD-TOKEN` returned in your first request. Send its value in this query string in the subsequent requests. The token has a timeout of 10 minutes, which refreshes after each new request. (default: {tokenValueExample}) (spec name: _token)
  --fields: string # Fields that should be returned by document. Separate fields' names with commas. For example `_fields=email,firstName,document`. You can also use `_all` to fetch all fields. (default: email,firstName,document)
  --where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --keyword: string # String to search. Use quotes for a partial query. For example, `_keyword=Maria` or `_keyword="Maria"`. (e.g. String to search)
  --sort: string # Sets sorting mode in two parts. The first part is the name of the field you want to sort by. In the second part, use `ASC` for ascending or `DESC` for descending. (default: firstName ASC)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --rest-range: string # Defines the collection of documents to be returned. A range within the collection limited by 100 documents per query. (required, e.g. resources=0-10)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/scroll"
    path_params: [{name: dataEntityName, var: data_entity_name}]
    query: [{name: _token, var: qp_token}, {name: _fields, var: fields}, {name: _where, var: where}, {name: _schema, var: schema}, {name: _keyword, var: keyword}, {name: _sort, var: sort}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: REST-Range, var: rest_range, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, qp_token: $qp_token, fields: $fields, where: $where, schema: $schema, keyword: $keyword, sort: $sort, content_type: $content_type, hdr_accept: $hdr_accept, rest_range: $rest_range
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search documents
#
# GET /api/dataentities/{dataEntityName}/search
# operationId: Searchdocuments
export def "searchdocuments" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Fields that should be returned by document. Separate fields' names with commas. For example `_fields=email,firstName,document`. You can also use `_all` to fetch all fields. (default: email,firstName,document)
  --where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --keyword: string # String to search. Use quotes for a partial query. For example, `_keyword=Maria` or `_keyword="Maria"`. (e.g. String to search)
  --sort: string # Sets sorting mode in two parts. The first part is the name of the field you want to sort by. In the second part, use `ASC` for ascending or `DESC` for descending. (default: firstName ASC)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --rest-range: string # Defines the collection of documents to be returned. A range within the collection limited by 100 documents per query. (required, e.g. resources=0-10)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/dataentities/{dataEntityName}/search"
    path_params: [{name: dataEntityName, var: data_entity_name}]
    query: [{name: _fields, var: fields}, {name: _where, var: where}, {name: _schema, var: schema}, {name: _keyword, var: keyword}, {name: _sort, var: sort}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}, {name: REST-Range, var: rest_range, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MASTER_DATA_API_V2_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MASTER_DATA_API_V2_APPTOKEN_TOKEN}]
  } {
    data_entity_name: $data_entity_name, fields: $fields, where: $where, schema: $schema, keyword: $keyword, sort: $sort, content_type: $content_type, hdr_accept: $hdr_accept, rest_range: $rest_range
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
