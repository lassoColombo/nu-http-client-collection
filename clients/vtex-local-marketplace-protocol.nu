# Auto-generated client for Marketplace Protocol v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Marketplace-Protocol/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.MARKETPLACE_PROTOCOL_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "MARKETPLACE_PROTOCOL_TOKEN"
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

def base-url-completer [] { ["https://vtex.local" "https://api.apis.guru"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let return_types = {
    fulfillment-simulation-external-marketplace: "record<country: string, items: table<availability: string, id: string, listPrice: int, measurementUnit: string, offerings: list, parentAssemblyBinding: string, parentItemIndex: int, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, tax: int, unitMultiplier: int>, logisticsInfo: table<addressId: string, deliveryChannels: list, itemIndex: int, itemMetadata: record, messages: list, pickupPoints: list, purchaseConditions: record, quantity: int, selectedDeliveryChannel: string, selectedSla: string, shipsTo: list, slas: list, subscriptionData: record, totals: list>, marketingData: record, paymentData: record<availableAccounts: list<any>, availableAssociations: record, availableTokens: list<any>, giftCardMessages: list<any>, giftCards: list<any>, installmentOptions: list<any>, paymentSystems: list<record>, payments: list<any>>, postalCode: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<any>, teaser: list<any>>, selectableGifts: list<any>>"
    enqueue-new-order: "record<accountName: string, code: string, errors: table<code: string, description: string, source: string>, fields: record<fields: record<franchiseOrderId: string, mainOrderId: string>>, flow: string, marketplaceOrderId: string, message: string, operationId: string, success: bool>"
    update-order-status: "record<accountName: string, code: string, errors: table<code: string, description: string, source: string>, fields: record<fields: record<franchiseOrderId: string, mainOrderId: string>>, flow: string, marketplaceOrderId: string, message: string, operationId: string, success: bool>"
    fulfillment-simulation: "record<country: string, items: table<id: string, listPrice: int, measurementUnit: string, merchantName: string, offerings: list, price: int, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, seller: string, unitMultiplier: int>, logisticsInfo: table<deliveryChannels: list, itemIndex: int, quantity: int, shipsTo: list, slas: list, stockBalance: int>, postalCode: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["fulfillment-simulation-external-marketplace" "send-category-mapping-vtex-mapper" "vtex-mapper-registration" "enqueue-new-order" "update-order-status" "place-fulfillment-order" "authorize-dispatch-for-fulfillment-order" "fulfillment-simulation" "order-placement" "mkp-order-cancellation" "authorize-fulfillment" "cancel-order-in-marketplace" "send-invoice" "send-tracking-information" "update-tracking-status" "commands"] | sort) } | get name | first)
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

# Fulfillment simulation - External Marketplace
#
# POST /api/checkout/pub/orderForms/simulation
# Returns: record<country: string, items: table<availability: string, id: string, listPrice: int, measurementUnit: string, offerings: list, parentAssemblyBinding: string, parentItemIndex: int, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, tax: int, unitMultiplier: int>, logisticsInfo: table<addressId: string, deliveryChannels: list, itemIndex: int, itemMetadata: record, messages: list, pickupPoints: list, purchaseConditions: record, quantity: int, selectedDeliveryChannel: string, selectedSla: string, shipsTo: list, slas: list, subscriptionData: record, totals: list>, marketingData: record, paymentData: record<availableAccounts: list<any>, availableAssociations: record, availableTokens: list<any>, giftCardMessages: list<any>, giftCards: list<any>, installmentOptions: list<any>, paymentSystems: list<record>, payments: list<any>>, postalCode: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<any>, teaser: list<any>>, selectableGifts: list<any>>
# operationId: fulfillment-simulation-external-marketplace
export def "fulfillment-simulation-external-marketplace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --affiliate-id: string # The affiliate ID code created by the seller. (default: MNF)
  --sc: int # Trade Policy (Sales Channel) identification. (e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --client-profile-data: record # Customer's profile information. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, customerClass?: string, document?: string, documentType?: string, email?: string, firstName?: string, isCorporate?: bool, lastName?: string, phone?: string, profileCompleteOnLoading?: bool, profileErrorOnLoading?: bool, stateInscription?: string, tradeName?: string}
  --country: string # Three letter ISO code of the country of the shipping address. This value must be sent along with the `postalCode` or `geoCoordinates` values. (e.g. BRA)
  --geo-coordinates: list<float> # Array containing two floats with geocoordinates, first longitude, then latitude. (default: [-47.924747467041016, -15.832582473754883])
  --is-checked-in: oneof<nothing, bool> # Indicates whether order is checked in. (default: false)
  --items: list # Array containing information about the SKUs inside the cart to be simulated. — item shape: {id?: string, quantity?: int, seller?: string}
  --marketing-data: record # Object containing promotion data such as coupon tracking information and internal or external UTMs. — shape: {coupon?: string, utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  --postal-code: string # Postal code. (e.g. 12345-000)
  --selected-sla: string # SLA selected by the customer. (e.g. Normal)
  --store-id: string # ID of the store. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/checkout/pub/orderForms/simulation"
    query: [{name: affiliateId, var: affiliate_id}, {name: sc, var: sc}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientProfileData, var: client_profile_data}, {name: country, var: country}, {name: geoCoordinates, var: geo_coordinates}, {name: isCheckedIn, var: is_checked_in}, {name: items, var: items}, {name: marketingData, var: marketing_data}, {name: postalCode, var: postal_code}, {name: selectedSla, var: selected_sla}, {name: storeId, var: store_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    affiliate_id: $affiliate_id, sc: $sc, content_type: $content_type, hdr_accept: $hdr_accept, client_profile_data: $client_profile_data, country: $country, geo_coordinates: $geo_coordinates, is_checked_in: $is_checked_in, items: $items, marketing_data: $marketing_data, postal_code: $postal_code, selected_sla: $selected_sla, store_id: $store_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send Category Mapping to VTEX Mapper
#
# POST /portal.vtexcommercestable.com.br/api/mkp-category-mapper/categories/marketplace/{id}
# operationId: send-category-mapping-vtex-mapper
export def "send-category-mapping-vtex-mapper" [
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
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  categories: list # Array with Marketplace parent categories and their information. (default: []) — item shape: {children?: list, id?: string, name?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/portal.vtexcommercestable.com.br/api/mkp-category-mapper/categories/marketplace/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    id: $id, content_type: $content_type, hdr_accept: $hdr_accept, categories: $categories
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# VTEX Mapper Registration
#
# POST /portal.vtexcommercestable.com.br/api/mkp-category-mapper/connector/register
# operationId: vtex-mapper-registration
export def "vtex-mapper-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # Name of the VTEX account. Used as part of the URL. (required, e.g. accountName)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --category-tree-processing-notification-endpoint: string # The `CategoryTreeProcessingNotificationEndpoint` is optional, and should be an endpoint from the external marketplace, that will be notified after the marketplace's category tree is successfully processed or not. (e.g. https://CategoryTreeProcessingNotificationEndpoint.com/api)
  category_tree_end_point: string # Endpoint that returns categories and attributes according to VTEX Mapper specifications. (e.g. http://api.vtexinternal.com.br/api/{{marketplaceName}}/mapper/categories)
  display_name: string # Marketplace Name, that will be displayed in VTEX Mapper. (e.g. Marketplace A)
  mapping_end_point: string # Secure endpoint that will receive the category mapping sent by VTEX Mapper. (e.g. http://api.vtexinternal.com.br/api/{{marketplaceName}}/mapper/mapping)
  properties: record # Refers to the `allowsRemap` property.
]: any -> any {
  $in | http-request {
    method: post
    path: "/portal.vtexcommercestable.com.br/api/mkp-category-mapper/connector/register"
    query: [{name: an, var: an, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryTreeProcessingNotificationEndpoint, var: category_tree_processing_notification_endpoint}, {name: categoryTreeEndPoint, var: category_tree_end_point}, {name: displayName, var: display_name}, {name: mappingEndPoint, var: mapping_end_point}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    an: $an, content_type: $content_type, hdr_accept: $hdr_accept, category_tree_processing_notification_endpoint: $category_tree_processing_notification_endpoint, category_tree_end_point: $category_tree_end_point, display_name: $display_name, mapping_end_point: $mapping_end_point, properties: $properties
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# New Order Integration
#
# POST /{accountName}.vtexcommercestable.com.br/api/order-integration/orders
# Returns: record<accountName: string, code: string, errors: table<code: string, description: string, source: string>, fields: record<fields: record<franchiseOrderId: string, mainOrderId: string>>, flow: string, marketplaceOrderId: string, message: string, operationId: string, success: bool>
# operationId: EnqueueNewOrder
export def "enqueue-new-order" [
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # Parameter should indicate the name of the VTEX account where the order is being integrated or updated, meaning the seller responsible for the order. (e.g. apiexamples)
  --affiliate-id: string # ID identifying the marketplace where the order originates. This ID is configured in the seller's VTEX account, and should be informed to the marketplace. (required, e.g. MKP)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --allow-franchises: oneof<nothing, bool> # Boolean indicating whether franchise accounts linked to the main seller should be considered. That is, if the order delivery pickup/SLA can belong to a [franchise account](https://help.vtex.com/en/tutorial/what-is-a-franchise-account--kWQC6RkFSCUFGgY5gSjdl), for example. This field is optional and defaults to `false`. (e.g. false)
  client_profile_data: record # Structure with the customer's information. An order will be identified as corporate if any of the corporate fields are filled out (`corporateDocument`, `corporatePhone`, `corporateName` or `tradeName`). — shape: {corporateDocument: string, corporateName: string, corporatePhone: string, document: string, email: string, firstName: string, lastName: string, phone: string, stateInscription: string, tradeName: string}
  --connector-endpoint: string # String with the connector's base endpoint that will receive notifications about the orders processing results, as well as status updates from VTEX OMS. This field accepts query strings. You can use the models below: - `https://{{externalconnector}}.com` - `https://{{externalconnector.com}}/api/vtex` if you additionaly want to send a relative URL with the endpoint. This field is optional if the connector uses the [App Template](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template) and authenticates on our request via `VtexIdclientAutCookie`. It is required if the connector is native or does not use the App Template. (e.g. https://{{externalconnector.com}}/api/vtex)
  --connector-name: string # String with the identifier code of the connector responsible for the order. This field is optional if the connector uses the [App Template](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template) and authenticates on our request via `VtexIdclientAutCookie`. It is required if the connector is native or does not use the App Template. (e.g. connectorName)
  --custom-data: record # Structure with the order's customizable fields. To insert custom fields in the order, you must first go through the process of [Creating an app](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template), and then adding the app, as well as the desired fields, within the seller's `orderForm`. More information on [Creating customizable fields in the cart with Checkout API](https://developers.vtex.com/vtex-rest-api/docs/customizable-fields-with-checkout-api). (e.g. {customApps: [{fields: {marketplacePaymentMethod: credit card}, id: marketplace-integration, major: 1}]}) — shape: {customApps: list}
  invoice_data: record # Object with the order's billing data. (e.g. {userPaymentInfo: {paymentMethods: [creditCardPaymentGroup]}}) — shape: {userPaymentInfo: record}
  items: list # item shape: {id: string, price: int, quantity: int}
  marketplace_order_id: string # String that indicates the order's ID in the marketplace. (e.g. 7e62fcd3-827b-400d-be8a-f050a79c4976)
  marketplace_order_status: string # Required field including a string with the order’s status in the marketplace. If you send an order with the status APPROVED to integrate, our service will automatically try to advance it’s status in VTEX after integrating it. This field accepts the following values: - `new` - `approved` (e.g. new)
  marketplace_payment_value: int # Integer that indicates the order’s total value, which the marketplace will pay to the seller. It’s important to note that this value should include interest, if that’s the case. If the value is `USD110.50`, convert it to the format → `11050`. (e.g. 11050)
  --pickup-account-name: string # String that indicates the name of the account responsible for the order’s pickup point. It is only required for pickup-in-point orders from franchise accounts, when franchise accounts `allowFranchises` is `true` and the order in question has a `pickup-in-point` delivery type. It is optional otherwise. (e.g. accountName)
  shipping_data: record # shape: {isFob: bool, isMarketplaceFulfillment: bool, logisticsInfo: list, selectedAddresses: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{accountName}.vtexcommercestable.com.br/api/order-integration/orders"
    path_params: [{name: accountName, var: account_name}]
    query: [{name: an, var: an}, {name: affiliateId, var: affiliate_id, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowFranchises, var: allow_franchises, required: true}, {name: clientProfileData, var: client_profile_data}, {name: connectorEndpoint, var: connector_endpoint}, {name: connectorName, var: connector_name}, {name: customData, var: custom_data}, {name: invoiceData, var: invoice_data}, {name: items, var: items}, {name: marketplaceOrderId, var: marketplace_order_id}, {name: marketplaceOrderStatus, var: marketplace_order_status}, {name: marketplacePaymentValue, var: marketplace_payment_value}, {name: pickupAccountName, var: pickup_account_name}, {name: shippingData, var: shipping_data}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    account_name: $account_name, an: $an, affiliate_id: $affiliate_id, content_type: $content_type, hdr_accept: $hdr_accept, allow_franchises: $allow_franchises, client_profile_data: $client_profile_data, connector_endpoint: $connector_endpoint, connector_name: $connector_name, custom_data: $custom_data, invoice_data: $invoice_data, items: $items, marketplace_order_id: $marketplace_order_id, marketplace_order_status: $marketplace_order_status, marketplace_payment_value: $marketplace_payment_value, pickup_account_name: $pickup_account_name, shipping_data: $shipping_data
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Order Status
#
# PUT /{accountName}.vtexcommercestable.com.br/api/order-integration/orders/status
# Returns: record<accountName: string, code: string, errors: table<code: string, description: string, source: string>, fields: record<fields: record<franchiseOrderId: string, mainOrderId: string>>, flow: string, marketplaceOrderId: string, message: string, operationId: string, success: bool>
# operationId: UpdateOrderStatus
export def "update-order-status" [
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # Parameter should indicate the name of the VTEX account where the order is being integrated or updated, meaning the seller responsible for the order. (e.g. apiexamples)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  connector_endpoint: string # String with the connector's base endpoint that will receive notifications about the orders processing results, as well as status updates from VTEX OMS. This field does not accept query strings. You can use the models below: - `https://{{externalconnector}}.com` - `https://{{externalconnector.com}}/api/vtex` if you additionaly want to send a relative URL with the endpoint. This field is optional if the connector uses the [App Template](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template) and authenticates on our request via `VtexIdclientAutCookie`. It is required if the connector is native or does not use the App Template. (e.g. https://{{externalconnector.com}}/api/vtex)
  connector_name: string # String with the identifier code of the connector responsible for the order. This field is optional if the connector uses the [App Template](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template) and authenticates on our request via `VtexIdclientAutCookie`. It is required if the connector is native or does not use the App Template. (e.g. connectorName)
  marketplace_order_id: string # String that indicates the order's ID in the marketplace. (e.g. 7e62fcd3-827b-400d-be8a-f050a79c4976)
  marketplace_order_status: string # Required field including a string with the order’s status in the marketplace. If you send an order with the status APPROVED to integrate, our service will automatically try to advance its status in VTEX after integrating it. This field accepts the following values: - `new` - `approved`. (e.g. new)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{accountName}.vtexcommercestable.com.br/api/order-integration/orders/status"
    path_params: [{name: accountName, var: account_name}]
    query: [{name: an, var: an}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorEndpoint, var: connector_endpoint}, {name: connectorName, var: connector_name}, {name: marketplaceOrderId, var: marketplace_order_id}, {name: marketplaceOrderStatus, var: marketplace_order_status}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    account_name: $account_name, an: $an, content_type: $content_type, hdr_accept: $hdr_accept, connector_endpoint: $connector_endpoint, connector_name: $connector_name, marketplace_order_id: $marketplace_order_id, marketplace_order_status: $marketplace_order_status
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Place fulfillment order
#
# POST /{accountName}.{environment}.com.br/api/fulfillment/pvt/orders
# operationId: PlaceFulfillmentOrder
export def "place-fulfillment-order" [
  account_name: string
  environment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: string # Sales channel. (e.g. 1)
  --affiliate-id: string # ID identifying the marketplace where the order originates. This ID is configured in the seller's VTEX account, and should be informed to the marketplace. (required, e.g. MKP)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  client_profile_data: record # Customer's profile information. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document: string, documentType: string, email: string, firstName: string, isCorporate?: bool, lastName: string, phone?: string, stateInscription?: string, tradeName?: string}
  --is-created-async: oneof<nothing, bool> # Indicates whether an order is created. It must be `true` if an order is being placed with [Price divergence](https://help.vtex.com/en/tutorial/price-divergence-rule--6RlFLhD1rIRRshl83KnCjW#), otherwise the request will not work. (e.g. false)
  items: list # Array of objects containing information on each of the order's items. — item shape: {attachments?: list<string>, bundleItems?: list, commission?: int, freightCommission?: int, id: string, isGift?: bool, itemAttachment?: record, measurementUnit?: string, price?: int, priceTags?: list, quantity: int, seller: string, unitMultiplier?: int}
  --marketing-data: record # shape: {utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  marketplace_order_id: string # ID of the order in the marketplace. (e.g. 123456789)
  marketplace_payment_value: int # Value of the payment made to the marketplace. (e.g. 100)
  marketplace_services_endpoint: string # Endpoint provided by the marketplace for post purchase communication. Should be an URL, containing protocol, host, path and query string (in case it applies). (e.g. https://exampleseller.marketplaceservices.com)
  --open-text-field: string # Optional field meant to hold additional information about the order. We recommend using this field for text, not data formats such as `JSON` even if escaped. For that purpose, see [Creating customizable fields](https://developers.vtex.com/vtex-rest-api/docs/creating-customizable-fields-in-the-cart-with-checkout-api-1) (e.g. open-text-example)
  --payment-data: record # In other contexts, this field tipically holds an object with payment information. However, since the payment is processed by the marketplace, it will be sent to the seller as `null` in this context. (nullable)
  shipping_data: record # Shipping information. — shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/{accountName}.{environment}.com.br/api/fulfillment/pvt/orders"
    path_params: [{name: accountName, var: account_name}, {name: environment, var: environment}]
    query: [{name: sc, var: sc}, {name: affiliateId, var: affiliate_id, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientProfileData, var: client_profile_data}, {name: isCreatedAsync, var: is_created_async}, {name: items, var: items}, {name: marketingData, var: marketing_data}, {name: marketplaceOrderId, var: marketplace_order_id}, {name: marketplacePaymentValue, var: marketplace_payment_value}, {name: marketplaceServicesEndpoint, var: marketplace_services_endpoint}, {name: openTextField, var: open_text_field}, {name: paymentData, var: payment_data}, {name: shippingData, var: shipping_data}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    account_name: $account_name, environment: $environment, sc: $sc, affiliate_id: $affiliate_id, content_type: $content_type, hdr_accept: $hdr_accept, client_profile_data: $client_profile_data, is_created_async: $is_created_async, items: $items, marketing_data: $marketing_data, marketplace_order_id: $marketplace_order_id, marketplace_payment_value: $marketplace_payment_value, marketplace_services_endpoint: $marketplace_services_endpoint, open_text_field: $open_text_field, payment_data: $payment_data, shipping_data: $shipping_data
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorize dispatch for fulfillment order
#
# POST /{accountName}.{environment}.com.br/api/fulfillment/pvt/orders/{orderId}/fulfill
# operationId: AuthorizeDispatchForFulfillmentOrder
export def "authorize-dispatch-for-fulfillment-order" [
  account_name: string
  environment: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: string # Sales channel. (e.g. 1)
  --affiliate-id: string # ID identifying the marketplace where the order originates. This ID is configured in the seller's VTEX account, and should be informed to the marketplace. (required, e.g. MKP)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --marketplace-order-id: string # ID of the order in the marketplace. It is the same as the `orderId` without the `afilliateId` at the beginning. For instance, if the `orderId` is `"MKP-123"`, the `marketplaceOrderId` is `"123"`. (default: 123)
]: any -> any {
  $in | http-request {
    method: post
    path: "/{accountName}.{environment}.com.br/api/fulfillment/pvt/orders/{orderId}/fulfill"
    path_params: [{name: accountName, var: account_name}, {name: environment, var: environment}, {name: orderId, var: order_id}]
    query: [{name: sc, var: sc}, {name: affiliateId, var: affiliate_id, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: marketplaceOrderId, var: marketplace_order_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    account_name: $account_name, environment: $environment, order_id: $order_id, sc: $sc, affiliate_id: $affiliate_id, content_type: $content_type, hdr_accept: $hdr_accept, marketplace_order_id: $marketplace_order_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fulfillment simulation - External Seller
#
# POST /{fulfillmentEndpoint}/pvt/orderForms/simulation
# Returns: record<country: string, items: table<id: string, listPrice: int, measurementUnit: string, merchantName: string, offerings: list, price: int, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, seller: string, unitMultiplier: int>, logisticsInfo: table<deliveryChannels: list, itemIndex: int, quantity: int, shipsTo: list, slas: list, stockBalance: int>, postalCode: string>
# operationId: fulfillment-simulation
export def "fulfillment-simulation" [
  fulfillment_endpoint: string
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
  --content-type: string # Describes the type of the content being sent. (required, e.g. application/json)
  --country: string # ISO 3-digit code of the country where the delivery address is located. This field is mandatory, for shopping carts simulations, where both Country and Postal Code are required. This field should be sent as `null` for storefront simulations, where the information is not necessary. (e.g. USA)
  --geo-coordinates: list<string> # Geographic coordinates of the delivery address. This may be used instead of the postalCode, in case the marketplace is configured to accept geolocation. Example of value: `[-22.9443504,-43.1825635]`.
  --items: list # Array containing the cart items. — item shape: {id: string, quantity: int, seller: string}
  postal_code: string # Delivery address postal code. This field is mandatory for shopping carts simulations, where both Country and Postal Code are required. This field should be sent as `null` for storefront simulations, where the information is not necessary. (e.g. 12345678)
  --sc: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/como-funciona-uma-politica-comercial--6Xef8PZiFm40kg2STrMkMV#master-data)) associated to the seller account created. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{fulfillmentEndpoint}/pvt/orderForms/simulation"
    path_params: [{name: fulfillmentEndpoint, var: fulfillment_endpoint}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: geoCoordinates, var: geo_coordinates}, {name: items, var: items}, {name: postalCode, var: postal_code}, {name: sc, var: sc}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    fulfillment_endpoint: $fulfillment_endpoint, hdr_accept: $hdr_accept, content_type: $content_type, country: $country, geo_coordinates: $geo_coordinates, items: $items, postal_code: $postal_code, sc: $sc
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order placement
#
# POST /{fulfillmentEndpoint}/pvt/orders
# operationId: order-placement
export def "order-placement" [
  fulfillment_endpoint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-length: string # Length of the request body. (required, e.g. 2183)
  --authorization: string # Indicates authorization. (required, e.g. VTEX key="appKey" token="appToken")
  --x-vtex-api-appkey: string # VTEX API app key. (required, e.g. appKey)
  --x-vtex-api-apptoken: string # VTEX API app token. (required, e.g. appToken)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: accept)
  --accept-enconding: string # Indicates the types of response enconding the client can understand. (required, e.g. gzip, deflate)
  --x-vtex-operation-id: string # VTEX operation ID. (required, e.g. 8032114b-63e9-4e64-b30c-f7afcf676d7a)
  --x-forwarded-proto: string # Determines the protocol used by the client in the request. (required, e.g. https)
  --x-forwarded-for: string # Identifies the originating IP address of the HTTP client. (required, e.g. 179.35.30.186, 130.176.35.67, 172.16.247.49)
  --x-vtex-cache-client-bypass: string # VTEX cache client bypass. (required, e.g. 1)
  --content-type: string # Describes the type of the content being sent. (required, e.g. application/json)
  --traceparent: string # Identifies the incoming request in a tracing system. (required, e.g. 00-083c0ca18bc8d94183f333809a70cd64-bf5e9a641e230540-00)
  --client-profile-data: record # Customer's profile information. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone?: string, stateInscription?: string, tradeName?: string}
  --items: list # Array of objects containing data about each SKU in the cart. — item shape: {attachments?: list, bundleItems?: list, commission?: int, freightCommission?: int, id?: string, isGift?: bool, itemsAttachment?: list, measurementUnit?: string, price?: int, priceTags?: list, quantity?: int, seller?: string, unitMultiplier?: int}
  --marketing-data: record # Marketing tracking data. If the order has no tracking data, the value will be `null`. — shape: {utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  --marketplace-order-id: string # Identifies the order in the marketplace. (e.g. 1138342255777-01)
  --marketplace-payment-value: int # Amount that the marketplace agrees to pay to the seller. The last two digits are the cents. For example, $24.99 is represented 2499. (e.g. 2499)
  --marketplace-services-endpoint: string # Endpoint sent by VTEX to the seller, that will be used to send the invoice and tracking data to the marketplace. This endpoint will also be used in [change order in Multilevel Omnichannel Inventory](https://developers.vtex.com/docs/guides/change-orders-multilevel-omnichannel-inventory-external-marketplaces#implementators) operations in external marketplaces. (e.g. https://marketplaceservicesendpoint.myvtex.com/)
  --open-text-field: string # Optional field meant to hold additional information about the order. We recommend using this field for text, not data formats such as `json` even if escaped. For that purpose, see [Creating customizable fields](https://developers.vtex.com/vtex-rest-api/docs/creating-customizable-fields-in-the-cart-with-checkout-api-1) (e.g. open-text-example)
  --payment-data: record # In other contexts, this field tipically holds an object with payment information. However, since the payment is processed by the marketplace, it will be sent to the seller as `null` in this context. (nullable)
  --shipping-data: record # Shipping information. — shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/{fulfillmentEndpoint}/pvt/orders"
    path_params: [{name: fulfillmentEndpoint, var: fulfillment_endpoint}]
    header: [{name: content-length, var: content_length, required: true}, {name: authorization, var: authorization, required: true}, {name: x-vtex-api-appkey, var: x_vtex_api_appkey, required: true}, {name: x-vtex-api-apptoken, var: x_vtex_api_apptoken, required: true}, {name: accept, var: hdr_accept, required: true}, {name: accept-enconding, var: accept_enconding, required: true}, {name: x-vtex-operation-id, var: x_vtex_operation_id, required: true}, {name: x-forwarded-proto, var: x_forwarded_proto, required: true}, {name: x-forwarded-for, var: x_forwarded_for, required: true}, {name: x-vtex-cache-client-bypass, var: x_vtex_cache_client_bypass, required: true}, {name: content-type, var: content_type, required: true}, {name: traceparent, var: traceparent, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientProfileData, var: client_profile_data}, {name: items, var: items}, {name: marketingData, var: marketing_data}, {name: marketplaceOrderId, var: marketplace_order_id}, {name: marketplacePaymentValue, var: marketplace_payment_value}, {name: marketplaceServicesEndpoint, var: marketplace_services_endpoint}, {name: openTextField, var: open_text_field}, {name: paymentData, var: payment_data}, {name: shippingData, var: shipping_data}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    fulfillment_endpoint: $fulfillment_endpoint, content_length: $content_length, authorization: $authorization, x_vtex_api_appkey: $x_vtex_api_appkey, x_vtex_api_apptoken: $x_vtex_api_apptoken, hdr_accept: $hdr_accept, accept_enconding: $accept_enconding, x_vtex_operation_id: $x_vtex_operation_id, x_forwarded_proto: $x_forwarded_proto, x_forwarded_for: $x_forwarded_for, x_vtex_cache_client_bypass: $x_vtex_cache_client_bypass, content_type: $content_type, traceparent: $traceparent, client_profile_data: $client_profile_data, items: $items, marketing_data: $marketing_data, marketplace_order_id: $marketplace_order_id, marketplace_payment_value: $marketplace_payment_value, marketplace_services_endpoint: $marketplace_services_endpoint, open_text_field: $open_text_field, payment_data: $payment_data, shipping_data: $shipping_data
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marketplace order cancellation
#
# POST /{fulfillmentEndpoint}/pvt/orders/{orderId}/cancel
# operationId: mkp-order-cancellation
export def "mkp-order-cancellation" [
  fulfillment_endpoint: string
  order_id: string
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
  --content-type: string # Describes the type of the content being sent. (required, e.g. application/json)
  marketplace_order_id: string # Identifies the order. The seller should use this ID to trigger the cancellation of the corresponding order. (default: 1138342255777-01)
]: any -> any {
  $in | http-request {
    method: post
    path: "/{fulfillmentEndpoint}/pvt/orders/{orderId}/cancel"
    path_params: [{name: fulfillmentEndpoint, var: fulfillment_endpoint}, {name: orderId, var: order_id}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: marketplaceOrderId, var: marketplace_order_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    fulfillment_endpoint: $fulfillment_endpoint, order_id: $order_id, hdr_accept: $hdr_accept, content_type: $content_type, marketplace_order_id: $marketplace_order_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorize fulfillment
#
# POST /{fulfillmentEndpoint}/pvt/orders/{sellerOrderId}/fulfill
# operationId: authorize-fulfillment
export def "authorize-fulfillment" [
  fulfillment_endpoint: string
  seller_order_id: string
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
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  marketplace_order_id: string # Identifies the order. The seller should use this ID to trigger the fulfillment process of the corresponding order. (e.g. 1138342255777-01)
]: any -> any {
  $in | http-request {
    method: post
    path: "/{fulfillmentEndpoint}/pvt/orders/{sellerOrderId}/fulfill"
    path_params: [{name: fulfillmentEndpoint, var: fulfillment_endpoint}, {name: sellerOrderId, var: seller_order_id}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: marketplaceOrderId, var: marketplace_order_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    fulfillment_endpoint: $fulfillment_endpoint, seller_order_id: $seller_order_id, hdr_accept: $hdr_accept, content_type: $content_type, marketplace_order_id: $marketplace_order_id
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel order in marketplace
#
# POST /{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/cancel
# operationId: cancel-order-in-marketplace
export def "cancel-order-in-marketplace" [
  marketplace_services_endpoint: string
  marketplace_order_id: string
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
  --content-type: string # Describes the type of the content being sent. (required, e.g. application/json)
  reason: string # Insert here the reason for the order's cancellation. (e.g. Product is unavailable)
]: any -> any {
  $in | http-request {
    method: post
    path: "/{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/cancel"
    path_params: [{name: marketplaceServicesEndpoint, var: marketplace_services_endpoint}, {name: marketplaceOrderId, var: marketplace_order_id}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    marketplace_services_endpoint: $marketplace_services_endpoint, marketplace_order_id: $marketplace_order_id, hdr_accept: $hdr_accept, content_type: $content_type, reason: $reason
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send invoice
#
# POST /{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice
# operationId: send-invoice
export def "send-invoice" [
  marketplace_services_endpoint: string
  marketplace_order_id: string
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
  --content-type: string # Describes the type of the content being sent. (required, e.g. application/json)
  --courier: string # Courier, if available on invoice. (e.g. courier-example)
  invoice_number: string # Invoice number (e.g. NFe-00002)
  --invoice-value: int # Invoice value. (e.g. 6000)
  --issuance-date: string # Issuance date. (e.g. 2021-05-21T10:00:00)
  items: list # Array containing the order items. — item shape: {id: string, price: int, quantity: int}
  --tracking-number: string # Tracking number. (e.g. 12345678abc)
  --tracking-url: string # Tracking URL. (e.g. https://courier-example.com/tracking)
  type: string # Indicates the type of the invoice. Use `"Output"` for regular orders and `"Input"` for returns. (e.g. Output)
]: any -> any {
  $in | http-request {
    method: post
    path: "/{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice"
    path_params: [{name: marketplaceServicesEndpoint, var: marketplace_services_endpoint}, {name: marketplaceOrderId, var: marketplace_order_id}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: invoiceNumber, var: invoice_number}, {name: invoiceValue, var: invoice_value}, {name: issuanceDate, var: issuance_date}, {name: items, var: items}, {name: trackingNumber, var: tracking_number}, {name: trackingUrl, var: tracking_url}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    marketplace_services_endpoint: $marketplace_services_endpoint, marketplace_order_id: $marketplace_order_id, hdr_accept: $hdr_accept, content_type: $content_type, courier: $courier, invoice_number: $invoice_number, invoice_value: $invoice_value, issuance_date: $issuance_date, items: $items, tracking_number: $tracking_number, tracking_url: $tracking_url, type: $type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send tracking information
#
# POST /{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice/{invoiceNumber}
# operationId: send-tracking-information
export def "send-tracking-information" [
  marketplace_services_endpoint: string
  marketplace_order_id: string
  invoice_number: string
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
  --content-type: string # Describes the type of the content being sent. (required, e.g. application/json)
  --courier: string # Courier. (e.g. courier-example)
  --dispatched-date: string # Date of order dispatch. (e.g. 2021-06-09)
  --tracking-number: string # Tracking number. (e.g. 12345678abc)
  --tracking-url: string # Tracking URL. (e.g. https://courier-example.com/tracking)
]: any -> any {
  $in | http-request {
    method: post
    path: "/{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice/{invoiceNumber}"
    path_params: [{name: marketplaceServicesEndpoint, var: marketplace_services_endpoint}, {name: marketplaceOrderId, var: marketplace_order_id}, {name: invoiceNumber, var: invoice_number}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: dispatchedDate, var: dispatched_date}, {name: trackingNumber, var: tracking_number}, {name: trackingUrl, var: tracking_url}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    marketplace_services_endpoint: $marketplace_services_endpoint, marketplace_order_id: $marketplace_order_id, invoice_number: $invoice_number, hdr_accept: $hdr_accept, content_type: $content_type, courier: $courier, dispatched_date: $dispatched_date, tracking_number: $tracking_number, tracking_url: $tracking_url
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update tracking status
#
# POST /{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice/{invoiceNumber}/tracking
# operationId: update-tracking-status
export def "update-tracking-status" [
  marketplace_services_endpoint: string
  marketplace_order_id: string
  invoice_number: string
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
  --content-type: string # Describes the type of the content being sent. (required, e.g. application/json)
  --events: list # Array containing information on each tracking event received. — item shape: {city?: string, date?: string, description?: string, state?: string}
  --is-delivered: oneof<nothing, bool> # Indicates if order has been delivered. `false` if it is in transit. (e.g. true)
]: any -> any {
  $in | http-request {
    method: post
    path: "/{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice/{invoiceNumber}/tracking"
    path_params: [{name: marketplaceServicesEndpoint, var: marketplace_services_endpoint}, {name: marketplaceOrderId, var: marketplace_order_id}, {name: invoiceNumber, var: invoice_number}]
    header: [{name: Accept, var: hdr_accept, required: true}, {name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: events, var: events}, {name: isDelivered, var: is_delivered, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: MARKETPLACE_PROTOCOL_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: MARKETPLACE_PROTOCOL_APPTOKEN_TOKEN}]
  } {
    marketplace_services_endpoint: $marketplace_services_endpoint, marketplace_order_id: $marketplace_order_id, invoice_number: $invoice_number, hdr_accept: $hdr_accept, content_type: $content_type, events: $events, is_delivered: $is_delivered
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
