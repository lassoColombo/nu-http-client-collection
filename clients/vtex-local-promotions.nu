# Auto-generated client for Promotions & Taxes API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Promotions-/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.PROMOTIONS_TAXES_API_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.PROMOTIONS_TAXES_API_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "PROMOTIONS_TAXES_API_TOKEN"
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br" "http://example.com/.exampleParameterValue.com.br/api/rnb" "https://rnb.vtexcommercestable.com.br/api/pricing/pvt" "https://rnb.exampleParameterValue.com.br/api/pricing/pvt" "http://example.com/.vtexcommercestable.com.br/api/rnb"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }

# Completers for enum parameters
def accept-completer [] { ["Promotion" "Tax"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let return_types = {
    get-archived-promotions: "record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>>"
    getarchivedbycouponcode: "record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>"
    archivebycouponcode: "string"
    get-archived-taxes: "record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>>"
    get-all-benefits: "record<archivedItems: list<string>, disabledItems: list<any>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>, limitConfigurationMaxPrice: record<activesCount: int, limit: int>>"
    create-or-update-calculator-configuration: "record<absoluteShippingDiscountValue: float, accumulateWithManualPrice: bool, activateGiftsMultiplier: bool, activeDaysOfWeek: list<string>, affiliates: table<id: string, name: string>, applyToAllShippings: bool, areSalesChannelIdsExclusive: bool, beginDateUtc: string, brands: table<id: string, name: string>, brandsAreInclusive: bool, campaigns: list<any>, cardIssuers: list<any>, categories: table<id: string, name: string>, categoriesAreInclusive: bool, clusterExpressions: list<string>, collections: table<id: string, name: string>, collections1BuyTogether: list<string>, collections2BuyTogether: list<any>, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, conditionsIds: list<string>, coupon: list<any>, cumulative: bool, daysAgoOfPurchases: int, description: string, disableDeal: bool, discountType: string, enableBuyTogetherPerSku: bool, endDateUtc: string, firstBuyIsProfileOptimistic: bool, giftListTypes: list<string>, idCalculatorConfiguration: string, idSeller: string, idSellerIsInclusive: bool, idsSalesChannel: list<string>, installment: int, isActive: bool, isArchived: bool, isDifferentListPriceAndPrice: bool, isFeatured: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, lastModified: string, listSku1BuyTogether: list<any>, listSku2BuyTogether: list<any>, marketingTags: list<string>, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxNumberOfAffectedItems: int, maxNumberOfAffectedItemsGroupKey: string, maxPricesPerItems: list<any>, maxUsage: int, maxUsagePerClient: int, maximumUnitPriceDiscount: float, merchants: list<any>, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, newOffset: float, nominalDiscountValue: float, nominalRewardValue: float, nominalShippingDiscountValue: float, nominalTax: float, offset: int, orderStatusRewardValue: string, origin: string, paymentsMethods: table<id: string, name: string>, paymentsRules: list<any>, percentualDiscountValue: float, percentualDiscountValueList: list<float>, percentualDiscountValueList1: float, percentualDiscountValueList2: float, percentualRewardValue: float, percentualShippingDiscountValue: float, percentualTax: float, products: table<id: string, name: string>, productsAreInclusive: bool, productsSpecifications: list<any>, quantityToAffectBuyTogether: int, rebatePercentualDiscountValue: float, restrictionsBins: list<string>, shippingPercentualTax: float, shouldDistributeDiscountAmongMatchedItems: bool, skus: table<id: string, name: string>, skusAreInclusive: bool, skusGift: record<gifts: int, quantitySelectable: int>, slasIds: list<string>, stores: list<any>, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, type: string, useNewProgressiveAlgorithm: bool, utmCampaign: string, utmSource: string, zipCodeRanges: list<any>>"
    get-calculator-configuration-by-id: "record<absoluteShippingDiscountValue: float, accumulateWithManualPrice: bool, activateGiftsMultiplier: bool, activeDaysOfWeek: list<string>, affiliates: table<id: string, name: string>, applyToAllShippings: bool, areSalesChannelIdsExclusive: bool, beginDateUtc: string, brands: table<id: string, name: string>, brandsAreInclusive: bool, campaigns: list<any>, cardIssuers: list<any>, categories: table<id: string, name: string>, categoriesAreInclusive: bool, clusterExpressions: list<string>, collections: table<id: string, name: string>, collections1BuyTogether: list<string>, collections2BuyTogether: list<any>, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, conditionsIds: list<string>, coupon: list<any>, cumulative: bool, daysAgoOfPurchases: int, description: string, disableDeal: bool, discountType: string, enableBuyTogetherPerSku: bool, endDateUtc: string, firstBuyIsProfileOptimistic: bool, giftListTypes: list<string>, idCalculatorConfiguration: string, idSeller: string, idSellerIsInclusive: bool, idsSalesChannel: list<string>, installment: int, isActive: bool, isArchived: bool, isDifferentListPriceAndPrice: bool, isFeatured: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, lastModified: string, listSku1BuyTogether: list<any>, listSku2BuyTogether: list<any>, marketingTags: list<string>, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxNumberOfAffectedItems: int, maxNumberOfAffectedItemsGroupKey: string, maxPricesPerItems: list<any>, maxUsage: int, maxUsagePerClient: int, maximumUnitPriceDiscount: float, merchants: list<any>, minInstallment: int, minimumQuantityBuyTogether: int, multipleSkusCause: record, multipleUsePerClient: bool, name: string, newOffset: float, nominalDiscountValue: float, nominalRewardValue: float, nominalShippingDiscountValue: float, nominalTax: float, offset: int, orderStatusRewardValue: string, origin: string, paymentsMethods: table<id: string, name: string>, paymentsRules: list<any>, percentualDiscountValue: float, percentualDiscountValueList: list<float>, percentualDiscountValueList1: float, percentualDiscountValueList2: float, percentualRewardValue: float, percentualShippingDiscountValue: float, percentualTax: float, products: table<id: string, name: string>, productsAreInclusive: bool, productsSpecifications: list<any>, quantityToAffectBuyTogether: int, rebatePercentualDiscountValue: float, restrictionsBins: list<string>, shippingPercentualTax: float, shouldDistributeDiscountAmongMatchedItems: bool, skus: table<id: string, name: string>, skusAreInclusive: bool, skusGift: record<gifts: int, quantitySelectable: int>, slasIds: list<string>, stores: list<any>, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, type: string, useNewProgressiveAlgorithm: bool, utmCampaign: string, utmSource: string, zipCodeRanges: table<inclusive: bool, zipCodeFrom: string, zipCodeTo: string>>"
    getcampaignaudiences: "table<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: list<record>>"
    setcampaignconfiguration: "record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, clusterOperator: string, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>>"
    getcampaignconfiguration: "record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>>"
    getall: "table<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>"
    post-api-rnb-pvt-coupon: "record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>"
    post-api-rnb-pvt-coupon-1: "record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>"
    getusage: "record<couponCode: string, hostName: string, profileUsages: record<profileId: record<orderUsage: list>>>"
    getbycouponcode: "record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>"
    massive-generation: "list<string>"
    post-api-rnb-pvt-multiple-coupons: "list<string>"
    get-all-taxes: "record<archivedItems: list<string>, disabledItems: list<string>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>>"
    unarchivebycouponcode: "string"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["usagenotification" "get-archived-promotions" "archive-promotion" "getarchivedbycouponcode" "archivebycouponcode" "get-archived-taxes" "get-all-benefits" "create-or-update-calculator-configuration" "get-calculator-configuration-by-id" "getcampaignaudiences" "setcampaignconfiguration" "getcampaignconfiguration" "getall" "post-api-rnb-pvt-coupon" "post-api-rnb-pvt-coupon-1" "getusage" "getbycouponcode" "massive-generation" "post-api-rnb-pvt-import-calculator-configuration" "put-api-rnb-pvt-import-calculator-configuration-promotion-id" "post-api-rnb-pvt-multiple-coupons" "get-all-taxes" "unarchive-promotion" "unarchivebycouponcode" "saveprice" "getallpaged" "pricebycontext" "deletebysku-id" "pricebysku-id" "pricebysku-idandtrade-policy" "calculatediscountsandtaxes-bundles" "commands"] | sort) } | get name | first)
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

# Usage notification
#
# POST /api/rnb/pub/notifications
# operationId: Usagenotification
export def "usagenotification" [
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
  account_id: string
  calculator_ids: list<string>
  coupon: string
  items_count: int # format: int32
  order_id: string
  profile_id: string
  --used: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rnb/pub/notifications"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: calculatorIds, var: calculator_ids}, {name: coupon, var: coupon}, {name: itemsCount, var: items_count}, {name: orderId, var: order_id}, {name: profileId, var: profile_id}, {name: used, var: used, required: true}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "http://example.com/.exampleParameterValue.com.br/api/rnb"
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, account_id: $account_id, calculator_ids: $calculator_ids, coupon: $coupon, items_count: $items_count, order_id: $order_id, profile_id: $profile_id, used: $used
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Archived Promotions
#
# GET /api/rnb/pvt/archive/benefits/calculatorConfiguration
# Returns: record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>>
# operationId: GetArchivedPromotions
export def "get-archived-promotions" [
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
    path: "/api/rnb/pvt/archive/benefits/calculatorConfiguration"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive Promotion or Tax
#
# POST /api/rnb/pvt/archive/calculatorConfiguration/{idCalculatorConfiguration}
# operationId: ArchivePromotion
export def "archive-promotion" [
  id_calculator_configuration: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/rnb/pvt/archive/calculatorConfiguration/{idCalculatorConfiguration}"
    path_params: [{name: idCalculatorConfiguration, var: id_calculator_configuration}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    id_calculator_configuration: $id_calculator_configuration, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get archived coupon by coupon code
#
# GET /api/rnb/pvt/archive/coupon/{couponCode}
# Returns: record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>
# operationId: Getarchivedbycouponcode
export def "getarchivedbycouponcode" [
  coupon_code: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rnb/pvt/archive/coupon/{couponCode}"
    path_params: [{name: couponCode, var: coupon_code}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    coupon_code: $coupon_code, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive coupon by coupon code
#
# POST /api/rnb/pvt/archive/coupon/{couponCode}
# Returns: string
# operationId: Archivebycouponcode
export def "archivebycouponcode" [
  coupon_code: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/rnb/pvt/archive/coupon/{couponCode}"
    path_params: [{name: couponCode, var: coupon_code}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    coupon_code: $coupon_code, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Archived Taxes
#
# GET /api/rnb/pvt/archive/taxes/calculatorConfiguration
# Returns: record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>>
# operationId: GetArchivedTaxes
export def "get-archived-taxes" [
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
    path: "/api/rnb/pvt/archive/taxes/calculatorConfiguration"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Promotions
#
# GET /api/rnb/pvt/benefits/calculatorconfiguration
# Returns: record<archivedItems: list<string>, disabledItems: list<any>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>, limitConfigurationMaxPrice: record<activesCount: int, limit: int>>
# operationId: GetAllBenefits
export def "get-all-benefits" [
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
    path: "/api/rnb/pvt/benefits/calculatorconfiguration"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or Update Promotion or Tax
#
# POST /api/rnb/pvt/calculatorconfiguration
# Returns: record<absoluteShippingDiscountValue: float, accumulateWithManualPrice: bool, activateGiftsMultiplier: bool, activeDaysOfWeek: list<string>, affiliates: table<id: string, name: string>, applyToAllShippings: bool, areSalesChannelIdsExclusive: bool, beginDateUtc: string, brands: table<id: string, name: string>, brandsAreInclusive: bool, campaigns: list<any>, cardIssuers: list<any>, categories: table<id: string, name: string>, categoriesAreInclusive: bool, clusterExpressions: list<string>, collections: table<id: string, name: string>, collections1BuyTogether: list<string>, collections2BuyTogether: list<any>, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, conditionsIds: list<string>, coupon: list<any>, cumulative: bool, daysAgoOfPurchases: int, description: string, disableDeal: bool, discountType: string, enableBuyTogetherPerSku: bool, endDateUtc: string, firstBuyIsProfileOptimistic: bool, giftListTypes: list<string>, idCalculatorConfiguration: string, idSeller: string, idSellerIsInclusive: bool, idsSalesChannel: list<string>, installment: int, isActive: bool, isArchived: bool, isDifferentListPriceAndPrice: bool, isFeatured: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, lastModified: string, listSku1BuyTogether: list<any>, listSku2BuyTogether: list<any>, marketingTags: list<string>, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxNumberOfAffectedItems: int, maxNumberOfAffectedItemsGroupKey: string, maxPricesPerItems: list<any>, maxUsage: int, maxUsagePerClient: int, maximumUnitPriceDiscount: float, merchants: list<any>, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, newOffset: float, nominalDiscountValue: float, nominalRewardValue: float, nominalShippingDiscountValue: float, nominalTax: float, offset: int, orderStatusRewardValue: string, origin: string, paymentsMethods: table<id: string, name: string>, paymentsRules: list<any>, percentualDiscountValue: float, percentualDiscountValueList: list<float>, percentualDiscountValueList1: float, percentualDiscountValueList2: float, percentualRewardValue: float, percentualShippingDiscountValue: float, percentualTax: float, products: table<id: string, name: string>, productsAreInclusive: bool, productsSpecifications: list<any>, quantityToAffectBuyTogether: int, rebatePercentualDiscountValue: float, restrictionsBins: list<string>, shippingPercentualTax: float, shouldDistributeDiscountAmongMatchedItems: bool, skus: table<id: string, name: string>, skusAreInclusive: bool, skusGift: record<gifts: int, quantitySelectable: int>, slasIds: list<string>, stores: list<any>, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, type: string, useNewProgressiveAlgorithm: bool, utmCampaign: string, utmSource: string, zipCodeRanges: list<any>>
# operationId: CreateOrUpdateCalculatorConfiguration
@deprecated --flag card-issuers
@deprecated --flag collections2-buy-together
@deprecated --flag coupon
@deprecated --flag disable-deal
@deprecated --flag installment
@deprecated --flag max-prices-per-items
@deprecated --flag merchants
@deprecated --flag payments-rules
@deprecated --flag products-specifications
@deprecated --flag stores
@deprecated --flag stores-are-inclusive
@deprecated --flag total-value-include-all-items
export def "create-or-update-calculator-configuration" [
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
  --absolute-shipping-discount-value: float # Maximum shipping value. (e.g. 0)
  --accumulate-with-manual-price: oneof<nothing, bool> # Allows the promotion to apply to products whose prices have been manually added by a call-center operator. (e.g. false)
  --activate-gifts-multiplier: oneof<nothing, bool> # If set as `true`, it activates gifts Multiplier. (e.g. false)
  --active-days-of-week: list<string> # Defines which days of the week the Promotion or Tax will applied.
  --affiliates: list # Marketplace order identifier. The discount will apply to selected affiliates. — item shape: {id?: string, name?: string}
  --apply-to-all-shippings: oneof<nothing, bool> # Promotion or Tax will be applied to all kind of shipping. (e.g. false)
  --are-sales-channel-ids-exclusive: oneof<nothing, bool> # If set to `false`, this Promotion or Tax will be applied to any trade policies present on the `idsSalesChannel` field. If set to `true`, trade policies present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --begin-date-utc: string # Promotion or Tax Begin Date (UTC). (e.g. 2020-05-01T18:47:15.89Z)
  --brands: list # Object composed by the brands that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --brands-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any brand present on the `brands` field. If set to `false`, brands present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --campaigns: list # Campaign Audiences that activate this Promotion or Tax. (e.g. [Campaign Audience test])
  --card-issuers: list # DEPRECATED
  --categories: list # Object composed by the categories that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --categories-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any category present on the `categories` field. If set to `false`, categories present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --cluster-expressions: list<string> # An expression to use with clusters.
  --collections: list # Object composed by the collections that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --collections1-buy-together: list<string> # Collections that will generate the Promotion, type **Buy Together**, **More for less**, **Progressive Discount**, **Buy One Get One**.
  --collections2-buy-together: list # DEPRECATED
  --collections-is-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any collection present on the `collections` field. If set to `false`, collections present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --compare-list-price-and-price: oneof<nothing, bool> # If the **List Price** and **Price** are the same. (e.g. false)
  --conditions-ids: list<string> # Array with conditions IDs.
  --coupon: list # DEPRECATED
  --cumulative: oneof<nothing, bool> # Defines if a Promotion or Tax can accumulate with another one. (`true`) or not (`false`). (e.g. false)
  --days-ago-of-purchases: int # Number of days that are considered to add the purchase history. (e.g. 0)
  --description: string # Internal description of the Promotion or Tax. (e.g. Description of the promotion.)
  --disable-deal: oneof<nothing, bool> # DEPRECATED
  --discount-type: string # The type of discount that will apply to the promotion. (e.g. percentual)
  --enable-buy-together-per-sku: oneof<nothing, bool> # Enable **Buy Together** per SKU. (e.g. false)
  --end-date-utc: string # Promotion or Tax End Date (UTC). (e.g. 2020-05-01T18:47:15.89Z)
  --first-buy-is-profile-optimistic: oneof<nothing, bool> # Applies the discount even if the user is not logged. (e.g. false)
  --gift-list-types: list<string> # Gifts List Type.
  --id-calculator-configuration: string # Promotion ID or Tax ID. (e.g. ba087fa9-8587-44b3-8ef1-ade8d053e9e9)
  --id-seller: string # Seller Name. (e.g. 1)
  --id-seller-is-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any seller present on the `idSeller` field. If set to `false`, sellers present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --ids-sales-channel: list<string> # List of Trade Policies that activate this Promotion or Tax.
  --installment: int # DEPRECATED
  --is-active: oneof<nothing, bool> # If set as `true` the Promotion or Tax is activated. If set as `false` the Promotion or Tax is deactivated. (e.g. true)
  --is-archived: oneof<nothing, bool> # If set as `true` the Promotion or Tax is archived. If set as `false` the Promotion or Tax is not archived. (e.g. false)
  --is-different-list-price-and-price: oneof<nothing, bool> # Applies the Promotion or Tax only if the list price and price is different. (e.g. false)
  --is-featured: oneof<nothing, bool> # Insert a flag with the promotion name used in the product's window display and page. (e.g. true)
  --is-first-buy: oneof<nothing, bool> # Applies the discount only if it's a first buy. (e.g. false)
  --is-min-max-installments: oneof<nothing, bool> # Set if the Promotion or Tax will be applied considering a minimum and maximum values for installments. (e.g. false)
  --is-sla-selected: oneof<nothing, bool> # Applies selected discount only when one of the defined shipping method is selected by the customer. (e.g. false)
  --item-max-price: float # Maximum price of the item. (e.g. 0)
  --item-min-price: float # Minimum price of the item. (e.g. 0)
  --last-modified: string # Date when the Promotion or Tax was last modified. (e.g. 2021-02-23T20:58:38.7963862Z)
  --list-sku1-buy-together: list # SKU first list for the promotion **Buy Together**. (e.g. [SKU])
  --list-sku2-buy-together: list # SKU second list for the promotion **Buy Together**. (e.g. [SKU])
  --marketing-tags: list<string> # Promotion or Tax Marketing tags.
  --marketing-tags-are-not-inclusive: oneof<nothing, bool> # If set to `false`, this Promotion or Tax will be applied to any marketing tag present on the `marketingTags` field. If set to `true`, marketing tags present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --max-installment: int # Maximum value for installment. (e.g. 0)
  --max-number-of-affected-items: int # The maximum number of affected items for a promotion. (e.g. 0)
  --max-number-of-affected-items-group-key: string # The maximum number of affected items by group key for a promotion. (e.g. perCart)
  --max-prices-per-items: list # DEPRECATED
  --max-usage: int # Defines how many times the Promotion or Tax can be used. (e.g. 0)
  --max-usage-per-client: int # Defines if the promotion can be used multiple times per client. (e.g. 0)
  --maximum-unit-price-discount: float # The maximum price for each item of the purchase will be the price set up. (e.g. 0)
  --merchants: list # DEPRECATED
  --min-installment: int # Minimum value for installment. (e.g. 0)
  --minimum-quantity-buy-together: int # Minimum quantity for **Buy Together** promotion. (e.g. 0)
  --multiple-use-per-client: oneof<nothing, bool> # Defines if the promotion can be used multiple times per client. (e.g. false)
  --name: string # Promotion name or Tax name. (e.g. Promoção Social Seller)
  --new-offset: float # New time offset from UTC in seconds. (e.g. -3)
  --nominal-discount-value: float # Exact discount to be applied for the total purchase value. (e.g. 0)
  --nominal-reward-value: float # Nominal value for rewards program. (e.g. 0)
  --nominal-shipping-discount-value: float # Exact discount to be applied for the shipping value. (e.g. 0)
  --nominal-tax: float # Nominal Tax. (e.g. 0)
  --offset: int # Time offset from UTC in seconds. (e.g. -3)
  --order-status-reward-value: string # Order status reward value. (e.g. invoiced)
  --origin: string # Origin of the Promotion or Tax, `marketplace` or `Fulfillment`. Read [Difference between orders with marketplace and fulfillment sources](https://help.vtex.com/en/tutorial/what-are-orders-with-marketplace-source-and-orders-with-fulfillment-source--6eVYrmUAwMOeKICU2KuG06) for more information. (e.g. marketplace)
  --payments-methods: list # Array composed by all the Payments Methods that activate this Promotion or Tax. — item shape: {id?: string, name?: string}
  --payments-rules: list # DEPRECATED
  --percentual-discount-value: float # Percentage discount to be applied for total purchase value. (e.g. 10)
  --percentual-discount-value-list: list<float> # Percentual discount value list.
  --percentual-discount-value-list1: float # Valid discounts for the SKUs in `listSku1BuyTogether`, discount list used for Buy Together Promotions. (e.g. 0)
  --percentual-discount-value-list2: float # Equivalent to `percentualDiscountValueList1`. (e.g. 0)
  --percentual-reward-value: float # Percentage value for rewards program. (e.g. 0)
  --percentual-shipping-discount-value: float # Percentage discount to be applied for shipping value. (e.g. 0)
  --percentual-tax: float # Percentual Tax over purchase total value. (e.g. 0)
  --products: list # Object composed by the products that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --products-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any product present on the `products` field. If set to `false`, products present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --products-specifications: list # DEPRECATED
  --quantity-to-affect-buy-together: int # Quantity to affect **Buy Together** promotion. (e.g. 0)
  --rebate-percentual-discount-value: float # Percentual Shipping Discount Value. (e.g. 0)
  --restrictions-bins: list<string> # The discount will be granted if the card's BIN is given.
  --shipping-percentual-tax: float # Shipping Percentual Tax over purchase total value. (e.g. 0)
  --should-distribute-discount-among-matched-items: oneof<nothing, bool> # Should distribute discount among matched items. (e.g. false)
  --skus: list # Object composed by the SKUs that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --skus-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any SKU present on the `skus` field. If set to `false`, SKUs present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --skus-gift: record # SKU Gift Object. Total discount on the product value set as a gift. — shape: {gifts?: list, quantitySelectable?: int}
  --slas-ids: list<string> # The discount will be granted if the shipping method is the same as the one given.
  --stores: list # DEPRECATED
  --stores-are-inclusive: oneof<nothing, bool> # DEPRECATED
  --total-value-celing: float # Maximum chart value to activate the Promotion or Tax. (e.g. 0)
  --total-value-floor: float # Minimum chart value to activate the Promotion or Tax. (e.g. 0)
  --total-value-include-all-items: oneof<nothing, bool> # DEPRECATED
  --total-value-mode: string # Defines if products that already are receiving a promotion will be considered on the chart total value. There are three options available: `IncludeMatchedItems`, `ExcludeMatchedItems`, `AllItems`. (e.g. IncludeMatchedItems)
  --total-value-purchase: float # Total value a client must have in past orders to activate the Promotion or Tax. (e.g. 0)
  --type: string # Defines what is the type of the promotion or indicates if it is a tax. Possible values: `regular` ([Regular Promotion](https://help.vtex.com/tutorial/regular-promotion--tutorials_327)), `combo` ([Buy Together](https://help.vtex.com/en/tutorial/buy-together--tutorials_323)), `forThePriceOf` ([More for Less](https://help.vtex.com/en/tutorial/creating-a-more-for-less-promotion--tutorials_325)), `progressive` ([Progressive Discount](https://help.vtex.com/en/tutorial/progressive-discount--tutorials_324)), `buyAndWin` ([Buy One Get One](https://help.vtex.com/en/tutorial/buy-one-get-one--tutorials_322)), `maxPricePerItem` (Deprecated), `campaign` ([Campaign Promotion](https://help.vtex.com/en/tutorial/campaign-promotion--1ChYXhK2AQGuS6wAqS8Ume)), `tax` (Tax), `multipleEffects` (Multiple Effects). (e.g. regular)
  --use-new-progressive-algorithm: oneof<nothing, bool> # Use new progressive algorithm. (e.g. false)
  --utm-campaign: string # Coupon utmCampaign code. (e.g. testSource)
  --utm-source: string # Coupon utmSource code. (e.g. testSource)
  --zip-code-ranges: list # Range of the zip code that applies the promotion. — item shape: {inclusive?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rnb/pvt/calculatorconfiguration"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: absoluteShippingDiscountValue, var: absolute_shipping_discount_value}, {name: accumulateWithManualPrice, var: accumulate_with_manual_price}, {name: activateGiftsMultiplier, var: activate_gifts_multiplier}, {name: activeDaysOfWeek, var: active_days_of_week}, {name: affiliates, var: affiliates}, {name: applyToAllShippings, var: apply_to_all_shippings}, {name: areSalesChannelIdsExclusive, var: are_sales_channel_ids_exclusive}, {name: beginDateUtc, var: begin_date_utc}, {name: brands, var: brands}, {name: brandsAreInclusive, var: brands_are_inclusive}, {name: campaigns, var: campaigns}, {name: cardIssuers, var: card_issuers}, {name: categories, var: categories}, {name: categoriesAreInclusive, var: categories_are_inclusive}, {name: clusterExpressions, var: cluster_expressions}, {name: collections, var: collections}, {name: collections1BuyTogether, var: collections1_buy_together}, {name: collections2BuyTogether, var: collections2_buy_together}, {name: collectionsIsInclusive, var: collections_is_inclusive}, {name: compareListPriceAndPrice, var: compare_list_price_and_price}, {name: conditionsIds, var: conditions_ids}, {name: coupon, var: coupon}, {name: cumulative, var: cumulative}, {name: daysAgoOfPurchases, var: days_ago_of_purchases}, {name: description, var: description}, {name: disableDeal, var: disable_deal}, {name: discountType, var: discount_type}, {name: enableBuyTogetherPerSku, var: enable_buy_together_per_sku}, {name: endDateUtc, var: end_date_utc}, {name: firstBuyIsProfileOptimistic, var: first_buy_is_profile_optimistic}, {name: giftListTypes, var: gift_list_types}, {name: idCalculatorConfiguration, var: id_calculator_configuration}, {name: idSeller, var: id_seller}, {name: idSellerIsInclusive, var: id_seller_is_inclusive}, {name: idsSalesChannel, var: ids_sales_channel}, {name: installment, var: installment}, {name: isActive, var: is_active}, {name: isArchived, var: is_archived}, {name: isDifferentListPriceAndPrice, var: is_different_list_price_and_price}, {name: isFeatured, var: is_featured}, {name: isFirstBuy, var: is_first_buy}, {name: isMinMaxInstallments, var: is_min_max_installments}, {name: isSlaSelected, var: is_sla_selected}, {name: itemMaxPrice, var: item_max_price}, {name: itemMinPrice, var: item_min_price}, {name: lastModified, var: last_modified}, {name: listSku1BuyTogether, var: list_sku1_buy_together}, {name: listSku2BuyTogether, var: list_sku2_buy_together}, {name: marketingTags, var: marketing_tags}, {name: marketingTagsAreNotInclusive, var: marketing_tags_are_not_inclusive}, {name: maxInstallment, var: max_installment}, {name: maxNumberOfAffectedItems, var: max_number_of_affected_items}, {name: maxNumberOfAffectedItemsGroupKey, var: max_number_of_affected_items_group_key}, {name: maxPricesPerItems, var: max_prices_per_items}, {name: maxUsage, var: max_usage}, {name: maxUsagePerClient, var: max_usage_per_client}, {name: maximumUnitPriceDiscount, var: maximum_unit_price_discount}, {name: merchants, var: merchants}, {name: minInstallment, var: min_installment}, {name: minimumQuantityBuyTogether, var: minimum_quantity_buy_together}, {name: multipleUsePerClient, var: multiple_use_per_client}, {name: name, var: name}, {name: newOffset, var: new_offset}, {name: nominalDiscountValue, var: nominal_discount_value}, {name: nominalRewardValue, var: nominal_reward_value}, {name: nominalShippingDiscountValue, var: nominal_shipping_discount_value}, {name: nominalTax, var: nominal_tax}, {name: offset, var: offset}, {name: orderStatusRewardValue, var: order_status_reward_value}, {name: origin, var: origin}, {name: paymentsMethods, var: payments_methods}, {name: paymentsRules, var: payments_rules}, {name: percentualDiscountValue, var: percentual_discount_value}, {name: percentualDiscountValueList, var: percentual_discount_value_list}, {name: percentualDiscountValueList1, var: percentual_discount_value_list1}, {name: percentualDiscountValueList2, var: percentual_discount_value_list2}, {name: percentualRewardValue, var: percentual_reward_value}, {name: percentualShippingDiscountValue, var: percentual_shipping_discount_value}, {name: percentualTax, var: percentual_tax}, {name: products, var: products}, {name: productsAreInclusive, var: products_are_inclusive}, {name: productsSpecifications, var: products_specifications}, {name: quantityToAffectBuyTogether, var: quantity_to_affect_buy_together}, {name: rebatePercentualDiscountValue, var: rebate_percentual_discount_value}, {name: restrictionsBins, var: restrictions_bins}, {name: shippingPercentualTax, var: shipping_percentual_tax}, {name: shouldDistributeDiscountAmongMatchedItems, var: should_distribute_discount_among_matched_items}, {name: skus, var: skus}, {name: skusAreInclusive, var: skus_are_inclusive}, {name: skusGift, var: skus_gift}, {name: slasIds, var: slas_ids}, {name: stores, var: stores}, {name: storesAreInclusive, var: stores_are_inclusive}, {name: totalValueCeling, var: total_value_celing}, {name: totalValueFloor, var: total_value_floor}, {name: totalValueIncludeAllItems, var: total_value_include_all_items}, {name: totalValueMode, var: total_value_mode}, {name: totalValuePurchase, var: total_value_purchase}, {name: type, var: type}, {name: useNewProgressiveAlgorithm, var: use_new_progressive_algorithm}, {name: utmCampaign, var: utm_campaign}, {name: utmSource, var: utm_source}, {name: zipCodeRanges, var: zip_code_ranges}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, absolute_shipping_discount_value: $absolute_shipping_discount_value, accumulate_with_manual_price: $accumulate_with_manual_price, activate_gifts_multiplier: $activate_gifts_multiplier, active_days_of_week: $active_days_of_week, affiliates: $affiliates, apply_to_all_shippings: $apply_to_all_shippings, are_sales_channel_ids_exclusive: $are_sales_channel_ids_exclusive, begin_date_utc: $begin_date_utc, brands: $brands, brands_are_inclusive: $brands_are_inclusive, campaigns: $campaigns, card_issuers: $card_issuers, categories: $categories, categories_are_inclusive: $categories_are_inclusive, cluster_expressions: $cluster_expressions, collections: $collections, collections1_buy_together: $collections1_buy_together, collections2_buy_together: $collections2_buy_together, collections_is_inclusive: $collections_is_inclusive, compare_list_price_and_price: $compare_list_price_and_price, conditions_ids: $conditions_ids, coupon: $coupon, cumulative: $cumulative, days_ago_of_purchases: $days_ago_of_purchases, description: $description, disable_deal: $disable_deal, discount_type: $discount_type, enable_buy_together_per_sku: $enable_buy_together_per_sku, end_date_utc: $end_date_utc, first_buy_is_profile_optimistic: $first_buy_is_profile_optimistic, gift_list_types: $gift_list_types, id_calculator_configuration: $id_calculator_configuration, id_seller: $id_seller, id_seller_is_inclusive: $id_seller_is_inclusive, ids_sales_channel: $ids_sales_channel, installment: $installment, is_active: $is_active, is_archived: $is_archived, is_different_list_price_and_price: $is_different_list_price_and_price, is_featured: $is_featured, is_first_buy: $is_first_buy, is_min_max_installments: $is_min_max_installments, is_sla_selected: $is_sla_selected, item_max_price: $item_max_price, item_min_price: $item_min_price, last_modified: $last_modified, list_sku1_buy_together: $list_sku1_buy_together, list_sku2_buy_together: $list_sku2_buy_together, marketing_tags: $marketing_tags, marketing_tags_are_not_inclusive: $marketing_tags_are_not_inclusive, max_installment: $max_installment, max_number_of_affected_items: $max_number_of_affected_items, max_number_of_affected_items_group_key: $max_number_of_affected_items_group_key, max_prices_per_items: $max_prices_per_items, max_usage: $max_usage, max_usage_per_client: $max_usage_per_client, maximum_unit_price_discount: $maximum_unit_price_discount, merchants: $merchants, min_installment: $min_installment, minimum_quantity_buy_together: $minimum_quantity_buy_together, multiple_use_per_client: $multiple_use_per_client, name: $name, new_offset: $new_offset, nominal_discount_value: $nominal_discount_value, nominal_reward_value: $nominal_reward_value, nominal_shipping_discount_value: $nominal_shipping_discount_value, nominal_tax: $nominal_tax, offset: $offset, order_status_reward_value: $order_status_reward_value, origin: $origin, payments_methods: $payments_methods, payments_rules: $payments_rules, percentual_discount_value: $percentual_discount_value, percentual_discount_value_list: $percentual_discount_value_list, percentual_discount_value_list1: $percentual_discount_value_list1, percentual_discount_value_list2: $percentual_discount_value_list2, percentual_reward_value: $percentual_reward_value, percentual_shipping_discount_value: $percentual_shipping_discount_value, percentual_tax: $percentual_tax, products: $products, products_are_inclusive: $products_are_inclusive, products_specifications: $products_specifications, quantity_to_affect_buy_together: $quantity_to_affect_buy_together, rebate_percentual_discount_value: $rebate_percentual_discount_value, restrictions_bins: $restrictions_bins, shipping_percentual_tax: $shipping_percentual_tax, should_distribute_discount_among_matched_items: $should_distribute_discount_among_matched_items, skus: $skus, skus_are_inclusive: $skus_are_inclusive, skus_gift: $skus_gift, slas_ids: $slas_ids, stores: $stores, stores_are_inclusive: $stores_are_inclusive, total_value_celing: $total_value_celing, total_value_floor: $total_value_floor, total_value_include_all_items: $total_value_include_all_items, total_value_mode: $total_value_mode, total_value_purchase: $total_value_purchase, type: $type, use_new_progressive_algorithm: $use_new_progressive_algorithm, utm_campaign: $utm_campaign, utm_source: $utm_source, zip_code_ranges: $zip_code_ranges
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Promotion or Tax by ID
#
# GET /api/rnb/pvt/calculatorconfiguration/{idCalculatorConfiguration}
# Returns: record<absoluteShippingDiscountValue: float, accumulateWithManualPrice: bool, activateGiftsMultiplier: bool, activeDaysOfWeek: list<string>, affiliates: table<id: string, name: string>, applyToAllShippings: bool, areSalesChannelIdsExclusive: bool, beginDateUtc: string, brands: table<id: string, name: string>, brandsAreInclusive: bool, campaigns: list<any>, cardIssuers: list<any>, categories: table<id: string, name: string>, categoriesAreInclusive: bool, clusterExpressions: list<string>, collections: table<id: string, name: string>, collections1BuyTogether: list<string>, collections2BuyTogether: list<any>, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, conditionsIds: list<string>, coupon: list<any>, cumulative: bool, daysAgoOfPurchases: int, description: string, disableDeal: bool, discountType: string, enableBuyTogetherPerSku: bool, endDateUtc: string, firstBuyIsProfileOptimistic: bool, giftListTypes: list<string>, idCalculatorConfiguration: string, idSeller: string, idSellerIsInclusive: bool, idsSalesChannel: list<string>, installment: int, isActive: bool, isArchived: bool, isDifferentListPriceAndPrice: bool, isFeatured: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, lastModified: string, listSku1BuyTogether: list<any>, listSku2BuyTogether: list<any>, marketingTags: list<string>, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxNumberOfAffectedItems: int, maxNumberOfAffectedItemsGroupKey: string, maxPricesPerItems: list<any>, maxUsage: int, maxUsagePerClient: int, maximumUnitPriceDiscount: float, merchants: list<any>, minInstallment: int, minimumQuantityBuyTogether: int, multipleSkusCause: record, multipleUsePerClient: bool, name: string, newOffset: float, nominalDiscountValue: float, nominalRewardValue: float, nominalShippingDiscountValue: float, nominalTax: float, offset: int, orderStatusRewardValue: string, origin: string, paymentsMethods: table<id: string, name: string>, paymentsRules: list<any>, percentualDiscountValue: float, percentualDiscountValueList: list<float>, percentualDiscountValueList1: float, percentualDiscountValueList2: float, percentualRewardValue: float, percentualShippingDiscountValue: float, percentualTax: float, products: table<id: string, name: string>, productsAreInclusive: bool, productsSpecifications: list<any>, quantityToAffectBuyTogether: int, rebatePercentualDiscountValue: float, restrictionsBins: list<string>, shippingPercentualTax: float, shouldDistributeDiscountAmongMatchedItems: bool, skus: table<id: string, name: string>, skusAreInclusive: bool, skusGift: record<gifts: int, quantitySelectable: int>, slasIds: list<string>, stores: list<any>, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, type: string, useNewProgressiveAlgorithm: bool, utmCampaign: string, utmSource: string, zipCodeRanges: table<inclusive: bool, zipCodeFrom: string, zipCodeTo: string>>
# operationId: GetCalculatorConfigurationById
export def "get-calculator-configuration-by-id" [
  id_calculator_configuration: string
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
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rnb/pvt/calculatorconfiguration/{idCalculatorConfiguration}"
    path_params: [{name: idCalculatorConfiguration, var: id_calculator_configuration}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: [Promotion, Tax]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    id_calculator_configuration: $id_calculator_configuration, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all campaign audiences
#
# GET /api/rnb/pvt/campaignConfiguration
# Returns: table<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: list<record>>
# operationId: Getcampaignaudiences
export def "getcampaignaudiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/rnb/pvt/campaignConfiguration"
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create campaign audience
#
# POST /api/rnb/pvt/campaignConfiguration
# Returns: record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, clusterOperator: string, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>>
# operationId: Setcampaignconfiguration
export def "setcampaignconfiguration" [
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
  --begin-date-utc: string # Start date of the campaign audience in UTC format. (e.g. 2020-05-01T21:30:00Z)
  --end-date-utc: string # End date of the campaign audience in UTC format. (e.g. 2020-05-02T01:30:00Z)
  --id: string # Campaign audience ID. (e.g. dd270d06-1ed1-47fc-b04e-a2431121b5a4)
  --is-active: oneof<nothing, bool> # Defines if the campaign audience is active (`true`) or not (`false`). (e.g. true)
  --is-and-operator: oneof<nothing, bool> # When `true`, determines that all the `targetConfigurations` need to be valid for the campaign audience to be active. When `false`, determines that if at least one of the `targetConfigurations` is valid, the campaign audience will be active. (e.g. true)
  --is-archived: oneof<nothing, bool> # Defines if the campaign audience is archived (`true`) or not (`false`). (e.g. false)
  --last-modified: record # Object with information about the last update of the campaign audience. — shape: {dateUtc?: string, user?: string}
  --name: string # Campaign audience name. (e.g. Interna)
  --target-configurations: list # Array that contains all target audience that the campaign audience will be valid. — item shape: {affiliates?: list, areSalesChannelIdsExclusive?: bool, brands?: list, brandsAreInclusive?: bool, campaigns?: list, cardIssuers?: list, categories?: list, categoriesAreInclusive?: bool, clusterExpressions?: list<string>, clusterOperator?: string, collections?: list, collections1BuyTogether?: list<string>, collections2BuyTogether?: list, collectionsIsInclusive?: bool, compareListPriceAndPrice?: bool, coupon?: list, daysAgoOfPurchases?: int, enableBuyTogetherPerSku?: bool, featured?: bool, ... (48 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rnb/pvt/campaignConfiguration"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: beginDateUtc, var: begin_date_utc}, {name: endDateUtc, var: end_date_utc}, {name: id, var: id}, {name: isActive, var: is_active}, {name: isAndOperator, var: is_and_operator}, {name: isArchived, var: is_archived}, {name: lastModified, var: last_modified}, {name: name, var: name}, {name: targetConfigurations, var: target_configurations}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, begin_date_utc: $begin_date_utc, end_date_utc: $end_date_utc, id: $id, is_active: $is_active, is_and_operator: $is_and_operator, is_archived: $is_archived, last_modified: $last_modified, name: $name, target_configurations: $target_configurations
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get campaign audience configuration
#
# GET /api/rnb/pvt/campaignConfiguration/{campaignId}
# Returns: record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>>
# operationId: Getcampaignconfiguration
export def "getcampaignconfiguration" [
  campaign_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rnb/pvt/campaignConfiguration/{campaignId}"
    path_params: [{name: campaignId, var: campaign_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    campaign_id: $campaign_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all coupons
#
# GET /api/rnb/pvt/coupon
# Returns: table<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>
# operationId: Getall
export def "getall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required, default: application/json
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (required, default: application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/rnb/pvt/coupon"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update coupon
#
# POST /api/rnb/pvt/coupon
# Returns: record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>
# operationId: Update
export def "post-api-rnb-pvt-coupon" [
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
  coupon_code: string # Coupon code. (e.g. test)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  --is-archived: oneof<nothing, bool> # Defines if the coupon is archived (`true`) or not (`false`). (e.g. false)
  max_items_per_client: int # Maximum items per client that the coupon can be applied. (e.g. 10)
  utm_campaign: string # UTM campaign code. (e.g. coupon3)
  utm_source: string # UTM source code. (e.g. coupon3)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rnb/pvt/coupon"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: couponCode, var: coupon_code}, {name: expirationIntervalPerUse, var: expiration_interval_per_use}, {name: isArchived, var: is_archived, required: true}, {name: maxItemsPerClient, var: max_items_per_client}, {name: utmCampaign, var: utm_campaign}, {name: utmSource, var: utm_source}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, coupon_code: $coupon_code, expiration_interval_per_use: $expiration_interval_per_use, is_archived: $is_archived, max_items_per_client: $max_items_per_client, utm_campaign: $utm_campaign, utm_source: $utm_source
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create coupon
#
# POST /api/rnb/pvt/coupon/
# Returns: record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>
export def "post-api-rnb-pvt-coupon-1" [
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
  coupon_code: string # Coupon code. (e.g. summersale10)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  max_items_per_client: int # Maximum items per client that the coupon can be applied. (e.g. 10)
  --utm-campaign: string # UTM campaign code. (e.g. summer)
  utm_source: string # UTM source code. (e.g. email)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rnb/pvt/coupon/"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: couponCode, var: coupon_code}, {name: expirationIntervalPerUse, var: expiration_interval_per_use}, {name: maxItemsPerClient, var: max_items_per_client}, {name: utmCampaign, var: utm_campaign}, {name: utmSource, var: utm_source}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, coupon_code: $coupon_code, expiration_interval_per_use: $expiration_interval_per_use, max_items_per_client: $max_items_per_client, utm_campaign: $utm_campaign, utm_source: $utm_source
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get coupon usage
#
# GET /api/rnb/pvt/coupon/usage/{couponCode}
# Returns: record<couponCode: string, hostName: string, profileUsages: record<profileId: record<orderUsage: list>>>
# operationId: Getusage
export def "getusage" [
  coupon_code: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rnb/pvt/coupon/usage/{couponCode}"
    path_params: [{name: couponCode, var: coupon_code}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    coupon_code: $coupon_code, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get coupon by coupon code
#
# GET /api/rnb/pvt/coupon/{couponCode}
# Returns: record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string>
# operationId: Getbycouponcode
export def "getbycouponcode" [
  coupon_code: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rnb/pvt/coupon/{couponCode}"
    path_params: [{name: couponCode, var: coupon_code}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    coupon_code: $coupon_code, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Coupon Massive Generation
#
# POST /api/rnb/pvt/coupons
# Returns: list<string>
# operationId: MassiveGeneration
export def "massive-generation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quantity: int # Quantity of coupons to generate (required, e.g. 10)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  coupon_code: string # Coupon code. (e.g. ctest)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  max_items_per_client: int # Defines if the coupon is archived (`true`) or not (`false`). (e.g. 1)
  utm_campaign: string # UTM campaign code. (e.g. cupom3)
  utm_source: string # UTM source code. (e.g. cupom3)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rnb/pvt/coupons"
    query: [{name: quantity, var: quantity, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: couponCode, var: coupon_code}, {name: expirationIntervalPerUse, var: expiration_interval_per_use}, {name: maxItemsPerClient, var: max_items_per_client}, {name: utmCampaign, var: utm_campaign}, {name: utmSource, var: utm_source}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    quantity: $quantity, content_type: $content_type, hdr_accept: $hdr_accept, coupon_code: $coupon_code, expiration_interval_per_use: $expiration_interval_per_use, max_items_per_client: $max_items_per_client, utm_campaign: $utm_campaign, utm_source: $utm_source
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Multiple SKU Promotion
#
# POST /api/rnb/pvt/import/calculatorConfiguration
export def "post-api-rnb-pvt-import-calculator-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, e.g. text/csv)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --x-vtex-calculator-name: string # Promotion Name. (required, e.g. Test)
  --x-vtex-cumulative: oneof<nothing, bool> # Defines if the Promotion is cumulative with other promotions. (e.g. false)
  --x-vtex-cluster-operator: string # This header allows implementing the Promotion in multiples client clusters. You can set the value as `all` - the Promotion will be valid to all the clusters - or `any` - the Promotion will be valid to any of the clusters. (e.g. any)
  --x-vtex-cluster-expression: string # Cluster that will be included in the Promotion. To add multiple clusters, create a header for each one of them. (e.g. cluster_name=true)
  --x-vtex-start-date: string # Promotion start date. (required, e.g. 2020-08-18T16:00:00+3:00)
  --x-vtex-end-date: string # Promotion end date. (required, e.g. 2020-08-18T16:30:00+3:00)
  --x-vtex-accumulate-with-manual-prices: oneof<nothing, bool> # Condition that will accumulate the Promotion with manual prices or not. (required, e.g. false)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rnb/pvt/import/calculatorConfiguration"
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: X-VTEX-calculator-name, var: x_vtex_calculator_name, required: true}, {name: X-VTEX-cumulative, var: x_vtex_cumulative}, {name: X-VTEX-cluster-operator, var: x_vtex_cluster_operator}, {name: X-VTEX-cluster-expression, var: x_vtex_cluster_expression}, {name: X-VTEX-start-date, var: x_vtex_start_date, required: true}, {name: X-VTEX-end-date, var: x_vtex_end_date, required: true}, {name: X-VTEX-accumulate-with-manual-prices, var: x_vtex_accumulate_with_manual_prices, required: true}]
    body: {content_type: "text/csv", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, x_vtex_calculator_name: $x_vtex_calculator_name, x_vtex_cumulative: $x_vtex_cumulative, x_vtex_cluster_operator: $x_vtex_cluster_operator, x_vtex_cluster_expression: $x_vtex_cluster_expression, x_vtex_start_date: $x_vtex_start_date, x_vtex_end_date: $x_vtex_end_date, x_vtex_accumulate_with_manual_prices: $x_vtex_accumulate_with_manual_prices, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Multiple SKU Promotion
#
# PUT /api/rnb/pvt/import/calculatorConfiguration/{promotionId}
export def "put-api-rnb-pvt-import-calculator-configuration-promotion-id" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, e.g. text/csv)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --x-vtex-calculator-name: string # Promotion Name. (required, e.g. Test)
  --x-vtex-cumulative: oneof<nothing, bool> # Defines if the Promotion is cumulative with other promotions. (e.g. false)
  --x-vtex-cluster-operator: string # This header allows implementing the Promotion in multiples client clusters. You can set the value as `all` - the Promotion will be valid to all the clusters - or `any` - the Promotion will be valid to any of the clusters. (e.g. any)
  --x-vtex-cluster-expression: string # Cluster that will be included in the Promotion. To add multiple clusters, create a header for each one of them. (e.g. cluster_name=true)
  --x-vtex-start-date: string # Promotion start date. (required, e.g. 2020-08-18T16:00:00+3:00)
  --x-vtex-end-date: string # Promotion end date. (required, e.g. 2020-08-18T16:30:00+3:00)
  --x-vtex-accumulate-with-manual-prices: oneof<nothing, bool> # Condition that will accumulate the Promotion with manual prices or not. (required, e.g. false)
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/rnb/pvt/import/calculatorConfiguration/{promotionId}"
    path_params: [{name: promotionId, var: promotion_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: X-VTEX-calculator-name, var: x_vtex_calculator_name, required: true}, {name: X-VTEX-cumulative, var: x_vtex_cumulative}, {name: X-VTEX-cluster-operator, var: x_vtex_cluster_operator}, {name: X-VTEX-cluster-expression, var: x_vtex_cluster_expression}, {name: X-VTEX-start-date, var: x_vtex_start_date, required: true}, {name: X-VTEX-end-date, var: x_vtex_end_date, required: true}, {name: X-VTEX-accumulate-with-manual-prices, var: x_vtex_accumulate_with_manual_prices, required: true}]
    body: {content_type: "text/csv", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    promotion_id: $promotion_id, content_type: $content_type, hdr_accept: $hdr_accept, x_vtex_calculator_name: $x_vtex_calculator_name, x_vtex_cumulative: $x_vtex_cumulative, x_vtex_cluster_operator: $x_vtex_cluster_operator, x_vtex_cluster_expression: $x_vtex_cluster_expression, x_vtex_start_date: $x_vtex_start_date, x_vtex_end_date: $x_vtex_end_date, x_vtex_accumulate_with_manual_prices: $x_vtex_accumulate_with_manual_prices, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create multiple coupons
#
# POST /api/rnb/pvt/multiple-coupons
# Returns: list<string>
export def "post-api-rnb-pvt-multiple-coupons" [
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rnb/pvt/multiple-coupons"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Taxes
#
# GET /api/rnb/pvt/taxes/calculatorconfiguration
# Returns: record<archivedItems: list<string>, disabledItems: list<string>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>>
# operationId: GetAllTaxes
export def "get-all-taxes" [
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
    path: "/api/rnb/pvt/taxes/calculatorconfiguration"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive Promotion or Tax
#
# POST /api/rnb/pvt/unarchive/calculatorConfiguration/{idCalculatorConfiguration}
# operationId: UnarchivePromotion
export def "unarchive-promotion" [
  id_calculator_configuration: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/rnb/pvt/unarchive/calculatorConfiguration/{idCalculatorConfiguration}"
    path_params: [{name: idCalculatorConfiguration, var: id_calculator_configuration}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    id_calculator_configuration: $id_calculator_configuration, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive coupon by coupon code
#
# POST /api/rnb/pvt/unarchive/coupon/{couponCode}
# Returns: string
# operationId: Unarchivebycouponcode
export def "unarchivebycouponcode" [
  coupon_code: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/rnb/pvt/unarchive/coupon/{couponCode}"
    path_params: [{name: couponCode, var: coupon_code}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    coupon_code: $coupon_code, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save Price
#
# POST /price-sheet
# operationId: Saveprice
export def "saveprice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # required, e.g. {{accountName}}
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/price-sheet"
    query: [{name: an, var: an, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://rnb.vtexcommercestable.com.br/api/pricing/pvt"
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    an: $an, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all paged prices
#
# GET /price-sheet/all/{page}/{pageSize}
# operationId: Getallpaged
export def "getallpaged" [
  page: string
  page_size: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # required, e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/price-sheet/all/{page}/{pageSize}"
    path_params: [{name: page, var: page}, {name: pageSize, var: page_size}]
    query: [{name: an, var: an, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://rnb.vtexcommercestable.com.br/api/pricing/pvt"
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    page: $page, page_size: $page_size, an: $an, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Price by context
#
# POST /price-sheet/context
# operationId: Pricebycontext
export def "pricebycontext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # required, e.g. {{accountName}}
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  id: int # format: int32
  item_id: int # format: int32
  sales_channel: int # format: int32
  seller_id: string
  valid_from: string
  valid_to: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/price-sheet/context"
    query: [{name: an, var: an, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: itemId, var: item_id}, {name: salesChannel, var: sales_channel}, {name: sellerId, var: seller_id}, {name: validFrom, var: valid_from}, {name: validTo, var: valid_to}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://rnb.vtexcommercestable.com.br/api/pricing/pvt"
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    an: $an, content_type: $content_type, hdr_accept: $hdr_accept, id: $id, item_id: $item_id, sales_channel: $sales_channel, seller_id: $seller_id, valid_from: $valid_from, valid_to: $valid_to
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Price by SKU Id
#
# DELETE /price-sheet/{skuId}
# operationId: DeletebyskuId
export def "deletebysku-id" [
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
  --an: string # required, e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/price-sheet/{skuId}"
    path_params: [{name: skuId, var: sku_id}]
    query: [{name: an, var: an, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://rnb.exampleParameterValue.com.br/api/pricing/pvt"
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, an: $an, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Price by SKU ID
#
# GET /price-sheet/{skuId}
# operationId: PricebyskuId
export def "pricebysku-id" [
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
  --an: string # required, e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/price-sheet/{skuId}"
    path_params: [{name: skuId, var: sku_id}]
    query: [{name: an, var: an, required: true}]
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://rnb.vtexcommercestable.com.br/api/pricing/pvt"
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, an: $an, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Price by SKU ID and Trade Policy
#
# GET /price-sheet/{skuId}/{tradePolicy}
# operationId: PricebyskuIdandtradePolicy
export def "pricebysku-idandtrade-policy" [
  sku_id: string
  trade_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # required, e.g. {{accountName}}
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (required, default: application/json) (spec name: Accept)
  --content-type: string # Describes the type of the content being sent. (required, default: application/json)
]: nothing -> any {
  http-request {
    method: get
    path: "/price-sheet/{skuId}/{tradePolicy}"
    path_params: [{name: skuId, var: sku_id}, {name: tradePolicy, var: trade_policy}]
    query: [{name: an, var: an, required: true}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: Content-Type, var: content_type, required: true, default: "application/json"}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://rnb.vtexcommercestable.com.br/api/pricing/pvt"
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    sku_id: $sku_id, trade_policy: $trade_policy, an: $an, hdr_accept: $hdr_accept, content_type: $content_type
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate discounts and taxes (Bundles)
#
# POST /pub/bundles
# operationId: Calculatediscountsandtaxes(Bundles)
export def "calculatediscountsandtaxes-bundles" [
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
  --is-shopping-cart: oneof<nothing, bool>
  items: list # item shape: {id: string, index: int, isGift: bool, logisticsInfos: list<string>, measurementUnit: string, params: list, priceSheet: list<string>, priceTags: list<string>, productSpecifications: list<string>, quantity: int, sellerId: string, unitMultiplier: int}
  origin: string
  params: list # item shape: {name: string, value: string}
  profile_id: string
  sales_channel: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/pub/bundles"
    header: [{name: Content-Type, var: content_type, required: true, default: "application/json"}, {name: Accept, var: hdr_accept, required: true, default: "application/json"}]
    body: {content_type: "application/json", kind: json, fields: [{name: isShoppingCart, var: is_shopping_cart, required: true}, {name: items, var: items}, {name: origin, var: origin}, {name: params, var: params}, {name: profileId, var: profile_id}, {name: salesChannel, var: sales_channel}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "http://example.com/.vtexcommercestable.com.br/api/rnb"
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROMOTIONS_TAXES_API_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROMOTIONS_TAXES_API_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, is_shopping_cart: $is_shopping_cart, items: $items, origin: $origin, params: $params, profile_id: $profile_id, sales_channel: $sales_channel
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
