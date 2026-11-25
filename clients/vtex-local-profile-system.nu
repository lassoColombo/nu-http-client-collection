# Auto-generated client for Profile System v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Profile-System/1.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.PROFILE_SYSTEM_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.PROFILE_SYSTEM_APPTOKEN_TOKEN

const CLIENT = {
  base_url: "https://vtex.local"
  token_env_var: "PROFILE_SYSTEM_TOKEN"
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
    create-client-profile: "record"
    create-or-update-profile-schema: "record"
    get-profile: "list<any>"
    update-client-profile: "record"
    get-client-addresses: "list<any>"
    create-client-address: "record"
    get-unmasked-client-addresses: "list<record>"
    get-address: "record"
    update-client-address: "record"
    get-unmasked-address: "record"
    get-address-by-version: "record"
    get-unmasked-address-by-version: "record"
    get-purchase-information: "list<any>"
    update-purchase-information: "record"
    create-purchase-information: "record"
    get-unmasked-purchase-information: "list<record>"
    get-unmasked-profile: "list<any>"
    get-profile-by-version: "list<any>"
    get-unmasked-profile-by-version: "list<any>"
    create-prospect: "record"
    get-prospect: "list<any>"
    update-prospect: "record"
    get-unmasked-prospect: "list<any>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-client-profile" "create-or-update-profile-schema" "delete-client-profile" "get-profile" "update-client-profile" "get-client-addresses" "create-client-address" "get-unmasked-client-addresses" "delete-address" "get-address" "update-client-address" "get-unmasked-address" "get-address-by-version" "get-unmasked-address-by-version" "delete-purchase-information" "get-purchase-information" "update-purchase-information" "create-purchase-information" "get-unmasked-purchase-information" "get-unmasked-profile" "get-profile-by-version" "get-unmasked-profile-by-version" "create-prospect" "delete-prospect" "get-prospect" "update-prospect" "get-unmasked-prospect" "commands"] | sort) } | get name | first)
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

# Create client profile
#
# POST /api/storage/profile-system/profiles
# Returns: record
# operationId: CreateClientProfile
export def "create-client-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # This parameter sets the the Time To Live (TTL), in days, of the specific document being created or updated with this request. After this period of time from the moment of the request, the document is deleted. By sending this parameter you override the TTL set for the schema. > Currently, the available default document schemas have no TTL. This means that documents are stored indefinitely, unless a TTL is sent when creating or updating. (e.g. 365)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --birth-date: string # Client's birth date in ISO 8601 format. (e.g. 1925-11-17)
  document: string # Client's document. (e.g. 12345678900)
  document_type: string # Type of document informed in `document`. (e.g. CPF)
  email: string # Client's email address. (e.g. john.doe@example.com)
  first_name: string # Client's first name. (e.g. John)
  last_name: string # Client's last name. (e.g. Doe)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/storage/profile-system/profiles"
    query: [{name: ttl, var: ttl}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: birthDate, var: birth_date}, {name: document, var: document}, {name: documentType, var: document_type}, {name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    ttl: $ttl, content_type: $content_type, hdr_accept: $hdr_accept, birth_date: $birth_date, document: $document, document_type: $document_type, email: $email, first_name: $first_name, last_name: $last_name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update profile schema
#
# PUT /api/storage/profile-system/profiles/schema
# Returns: record
# operationId: CreateOrUpdateProfileSchema
export def "create-or-update-profile-schema" [
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
  description: string # Schema's human readable description. (e.g. This schema describes a b2c customer profile.)
  --document-ttl: int # Document time to live, in days. After this many days from its creation or update, any document cerated from this schema will be deleted. (e.g. 1825)
  properties: record # Object describing each field in your desired schema. In this object, each property is a new object, describing the field according to: `type` (string); `sensitive` (boolean); `pii` (boolean) and; `items.type` (if field is array). — shape: {{fieldName}?: record}
  required: list<string> # Schema required fields. (e.g. [firstName, lastName, email, document, documentType])
  title: string # Schema title. (e.g. Client profile schema)
  type: string # Schema type. (e.g. object)
  --v-indexed: list # e.g. [email, document]
  --v-unique: list # e.g. [email, document]
  --version: int # Schema version. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/storage/profile-system/profiles/schema"
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: documentTTL, var: document_ttl}, {name: properties, var: properties}, {name: required, var: required}, {name: title, var: title}, {name: type, var: type}, {name: v-indexed, var: v_indexed}, {name: v-unique, var: v_unique}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, description: $description, document_ttl: $document_ttl, properties: $properties, required: $required, title: $title, type: $type, v_indexed: $v_indexed, v_unique: $v_unique, version: $version
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete client profile
#
# DELETE /api/storage/profile-system/profiles/{profileId}
# operationId: DeleteClientProfile
export def "delete-client-profile" [
  profile_id: string
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
    path: "/api/storage/profile-system/profiles/{profileId}"
    path_params: [{name: profileId, var: profile_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get profile
#
# GET /api/storage/profile-system/profiles/{profileId}
# Returns: list<any>
# operationId: GetProfile
export def "get-profile" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates client profile
#
# PATCH /api/storage/profile-system/profiles/{profileId}
# Returns: record
# operationId: UpdateClientProfile
export def "update-client-profile" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --ttl: int # This parameter sets the the Time To Live (TTL), in days, of the specific document being created or updated with this request. After this period of time from the moment of the request, the document is deleted. By sending this parameter you override the TTL set for the schema. > Currently, the available default document schemas have no TTL. This means that documents are stored indefinitely, unless a TTL is sent when creating or updating. (e.g. 365)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --birth-date: string # Client's birth date in ISO 8601 format. (e.g. 1925-11-17)
  --document: string # Client's document. (e.g. 12345678900)
  --document-type: string # Type of document informed in `document`. (e.g. CPF)
  --email: string # Client's email address. (e.g. john.doe@example.com)
  --first-name: string # Client's first name. (e.g. John)
  --last-name: string # Client's last name. (e.g. Doe)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/storage/profile-system/profiles/{profileId}"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}, {name: ttl, var: ttl}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: birthDate, var: birth_date}, {name: document, var: document}, {name: documentType, var: document_type}, {name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, ttl: $ttl, content_type: $content_type, hdr_accept: $hdr_accept, birth_date: $birth_date, document: $document, document_type: $document_type, email: $email, first_name: $first_name, last_name: $last_name
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get client addresses
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses
# Returns: list<any>
# operationId: GetClientAddresses
export def "get-client-addresses" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/addresses"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create client address
#
# POST /api/storage/profile-system/profiles/{profileId}/addresses
# Returns: record
# operationId: CreateClientAddress
export def "create-client-address" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  administrative_area_level1: string # Name of administrative area, such as the state or province. (e.g. RJ)
  --country-code: string # Two letter country code. (e.g. BR)
  country_name: string # Name of the address country. (e.g. Brasil)
  locality: string # Name of address locality, such as the city. (e.g. Locality)
  locality_area_level1: string # Name of the address locality area, such as the neighborhood or district. (e.g. Locality area)
  postal_code: string # Address postal code. (e.g. 20200-000)
  route: string # Address route or street name. (e.g. 51)
  street_number: string # Address street number. (e.g. 999)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/storage/profile-system/profiles/{profileId}/addresses"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: administrativeAreaLevel1, var: administrative_area_level1}, {name: countryCode, var: country_code}, {name: countryName, var: country_name}, {name: locality, var: locality}, {name: localityAreaLevel1, var: locality_area_level1}, {name: postalCode, var: postal_code}, {name: route, var: route}, {name: streetNumber, var: street_number}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept, administrative_area_level1: $administrative_area_level1, country_code: $country_code, country_name: $country_name, locality: $locality, locality_area_level1: $locality_area_level1, postal_code: $postal_code, route: $route, street_number: $street_number
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unmasked client addresses
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/unmask
# Returns: list<record>
# operationId: GetUnmaskedClientAddresses
export def "get-unmasked-client-addresses" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/addresses/unmask"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete address
#
# DELETE /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# operationId: DeleteAddress
export def "delete-address" [
  profile_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/storage/profile-system/profiles/{profileId}/addresses/{addressId}"
    path_params: [{name: profileId, var: profile_id}, {name: addressId, var: address_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, address_id: $address_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get address
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# Returns: record
# operationId: GetAddress
export def "get-address" [
  profile_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/addresses/{addressId}"
    path_params: [{name: profileId, var: profile_id}, {name: addressId, var: address_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, address_id: $address_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update client address
#
# PATCH /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# Returns: record
# operationId: UpdateClientAddress
export def "update-client-address" [
  profile_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --administrative-area-level1: string # Name of administrative area, such as the state or province. (e.g. RJ)
  --country-code: string # Two letter country code. (e.g. BR)
  --country-name: string # Name of the address country. (e.g. Brasil)
  --locality: string # Name of address locality, such as the city. (e.g. Locality)
  --locality-area-level1: string # Name of the address locality area, such as the neighborhood or district. (e.g. Locality area)
  --postal-code: string # Address postal code. (e.g. 20200-000)
  --route: string # Name of the address country. (e.g. Brasil)
  --street-number: string # Name of the address country. (e.g. Brasil)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/storage/profile-system/profiles/{profileId}/addresses/{addressId}"
    path_params: [{name: profileId, var: profile_id}, {name: addressId, var: address_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: administrativeAreaLevel1, var: administrative_area_level1}, {name: countryCode, var: country_code}, {name: countryName, var: country_name}, {name: locality, var: locality}, {name: localityAreaLevel1, var: locality_area_level1}, {name: postalCode, var: postal_code}, {name: route, var: route}, {name: streetNumber, var: street_number}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, address_id: $address_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept, administrative_area_level1: $administrative_area_level1, country_code: $country_code, country_name: $country_name, locality: $locality, locality_area_level1: $locality_area_level1, postal_code: $postal_code, route: $route, street_number: $street_number
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unmasked address
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/unmask
# Returns: record
# operationId: GetUnmaskedAddress
export def "get-unmasked-address" [
  profile_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (required, e.g. data-validation)
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/unmask"
    path_params: [{name: profileId, var: profile_id}, {name: addressId, var: address_id}]
    query: [{name: reason, var: reason, required: true}, {name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, address_id: $address_id, reason: $reason, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get address by version
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/versions/{addressVersionId}
# Returns: record
# operationId: GetAddressByVersion
export def "get-address-by-version" [
  profile_id: string
  address_id: string
  address_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (required, e.g. data-validation)
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/versions/{addressVersionId}"
    path_params: [{name: profileId, var: profile_id}, {name: addressId, var: address_id}, {name: addressVersionId, var: address_version_id}]
    query: [{name: reason, var: reason, required: true}, {name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, address_id: $address_id, address_version_id: $address_version_id, reason: $reason, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unmasked address by version
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/versions/{addressVersionId}/unmask
# Returns: record
# operationId: GetUnmaskedAddressByVersion
export def "get-unmasked-address-by-version" [
  profile_id: string
  address_id: string
  address_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (required, e.g. data-validation)
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/versions/{addressVersionId}/unmask"
    path_params: [{name: profileId, var: profile_id}, {name: addressId, var: address_id}, {name: addressVersionId, var: address_version_id}]
    query: [{name: reason, var: reason, required: true}, {name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, address_id: $address_id, address_version_id: $address_version_id, reason: $reason, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete purchase information
#
# DELETE /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: DeletePurchaseInformation
export def "delete-purchase-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/storage/profile-system/profiles/{profileId}/purchase-info"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get purchase information
#
# GET /api/storage/profile-system/profiles/{profileId}/purchase-info
# Returns: list<any>
# operationId: GetPurchaseInformation
export def "get-purchase-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/purchase-info"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update purchase information
#
# PATCH /api/storage/profile-system/profiles/{profileId}/purchase-info
# Returns: record
# operationId: UpdatePurchaseInformation
export def "update-purchase-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/storage/profile-system/profiles/{profileId}/purchase-info"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create purchase information
#
# POST /api/storage/profile-system/profiles/{profileId}/purchase-info
# Returns: record
# operationId: CreatePurchaseInformation
export def "create-purchase-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/storage/profile-system/profiles/{profileId}/purchase-info"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unmasked purchase information
#
# GET /api/storage/profile-system/profiles/{profileId}/purchase-info/unmask
# Returns: list<record>
# operationId: GetUnmaskedPurchaseInformation
export def "get-unmasked-purchase-information" [
  profile_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/purchase-info/unmask"
    path_params: [{name: profileId, var: profile_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unmasked profile
#
# GET /api/storage/profile-system/profiles/{profileId}/unmask
# Returns: list<any>
# operationId: GetUnmaskedProfile
export def "get-unmasked-profile" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (required, e.g. data-validation)
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/unmask"
    path_params: [{name: profileId, var: profile_id}]
    query: [{name: reason, var: reason, required: true}, {name: alternativeKey, var: alternative_key}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, reason: $reason, alternative_key: $alternative_key, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get profile by version
#
# GET /api/storage/profile-system/profiles/{profileId}/versions/{profileVersionId}
# Returns: list<any>
# operationId: GetProfileByVersion
export def "get-profile-by-version" [
  profile_id: string
  profile_version_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/versions/{profileVersionId}"
    path_params: [{name: profileId, var: profile_id}, {name: profileVersionId, var: profile_version_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, profile_version_id: $profile_version_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unmasked profile by version
#
# GET /api/storage/profile-system/profiles/{profileId}/versions/{profileVersionId}/unmask
# Returns: list<any>
# operationId: GetUnmaskedProfileByVersion
export def "get-unmasked-profile-by-version" [
  profile_id: string
  profile_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (required, e.g. data-validation)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/profiles/{profileId}/versions/{profileVersionId}/unmask"
    path_params: [{name: profileId, var: profile_id}, {name: profileVersionId, var: profile_version_id}]
    query: [{name: reason, var: reason, required: true}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    profile_id: $profile_id, profile_version_id: $profile_version_id, reason: $reason, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create prospect
#
# POST /api/storage/profile-system/prospects
# Returns: record
# operationId: CreateProspect
export def "create-prospect" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/storage/profile-system/prospects"
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete prospect
#
# DELETE /api/storage/profile-system/prospects/{prospectId}
# operationId: DeleteProspect
export def "delete-prospect" [
  prospect_id: string
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
    path: "/api/storage/profile-system/prospects/{prospectId}"
    path_params: [{name: prospectId, var: prospect_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    prospect_id: $prospect_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get prospect
#
# GET /api/storage/profile-system/prospects/{prospectId}
# Returns: list<any>
# operationId: GetProspect
export def "get-prospect" [
  prospect_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/prospects/{prospectId}"
    path_params: [{name: prospectId, var: prospect_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    prospect_id: $prospect_id, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update prospect
#
# PATCH /api/storage/profile-system/prospects/{prospectId}
# Returns: record
# operationId: UpdateProspect
export def "update-prospect" [
  prospect_id: string
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/storage/profile-system/prospects/{prospectId}"
    path_params: [{name: prospectId, var: prospect_id}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    prospect_id: $prospect_id, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get unmasked prospect
#
# GET /api/storage/profile-system/prospects/{prospectId}/unmask
# Returns: list<any>
# operationId: GetUnmaskedProspect
export def "get-unmasked-prospect" [
  prospect_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (required, e.g. data-validation)
  --content-type: string # Type of the content being sent. (required, e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, e.g. application/json) (spec name: Accept)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/storage/profile-system/prospects/{prospectId}/unmask"
    path_params: [{name: prospectId, var: prospect_id}]
    query: [{name: reason, var: reason, required: true}]
    header: [{name: Content-Type, var: content_type, required: true}, {name: Accept, var: hdr_accept, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-vtex-api-appkey, var: token_appkey, env: PROFILE_SYSTEM_APPKEY_TOKEN}, {scheme: x-vtex-api-apptoken, var: token_apptoken, env: PROFILE_SYSTEM_APPTOKEN_TOKEN}]
  } {
    prospect_id: $prospect_id, reason: $reason, content_type: $content_type, hdr_accept: $hdr_accept
    base_url: $base_url, token_appkey: $token_appkey, token_apptoken: $token_apptoken, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
