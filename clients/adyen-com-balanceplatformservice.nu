# Auto-generated client for Configuration API v2
# Source: https://api.apis.guru/v2/specs/adyen.com/BalancePlatformService/2/openapi.json
# Auth: --token flag or $env.CONFIGURATION_API_TOKEN

const CLIENT = {
  base_url: "https://balanceplatform-api-test.adyen.com/bcl/v2"
  token_env_var: "CONFIGURATION_API_TOKEN"
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

def base-url-completer [] { ["https://balanceplatform-api-test.adyen.com/bcl/v2"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["active" "closed" "inactive" "suspended"] }
def category-completer [] { ["bank" "internal" "platformPayment"] }
def status-completer-1 [] { ["active" "inactive"] }
def type-completer [] { ["pull" "push"] }
def status-reason-completer [] { ["accountClosure" "damaged" "endOfLife" "expired" "lost" "other" "stolen" "suspectedFraud"] }
def type-completer-1 [] { ["bankAccount" "card"] }
def outcome-type-completer [] { ["hardBlock" "scoreBased"] }
def request-type-completer [] { ["authentication" "authorization" "tokenization"] }
def type-completer-2 [] { ["allowList" "blockList" "maxUsage" "velocity"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-account-holders: "record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>>"
    get-account-holders-id: "record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>>"
    patch-account-holders-id: "record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>>"
    get-account-holders-id-balance-accounts: "record<balanceAccounts: table<accountHolderId: string, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>, hasNext: bool, hasPrevious: bool>"
    post-balance-accounts: "record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>"
    get-balance-accounts-balance-account-id-sweeps: "record<hasNext: bool, hasPrevious: bool, sweeps: table<category: string, counterparty: record, currency: string, description: string, id: string, priorities: list, reason: string, schedule: any, status: string, sweepAmount: record, targetAmount: record, triggerAmount: record, type: string>>"
    post-balance-accounts-balance-account-id-sweeps: "record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string>"
    get-balance-accounts-balance-account-id-sweeps-sweep-id: "record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string>"
    patch-balance-accounts-balance-account-id-sweeps-sweep-id: "record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string>"
    get-balance-accounts-id: "record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>"
    patch-balance-accounts-id: "record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>"
    get-balance-accounts-id-payment-instruments: "record<hasNext: bool, hasPrevious: bool, paymentInstruments: table<balanceAccountId: string, bankAccount: any, card: record, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string>>"
    get-balance-platforms-id: "record<description: string, id: string, status: string>"
    get-balance-platforms-id-account-holders: "record<accountHolders: table<balancePlatform: string, capabilities: record, contactDetails: record, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: list>, hasNext: bool, hasPrevious: bool>"
    get-grant-accounts-id: "record<balances: table<currency: string, fee: int, principal: int, total: int>, fundingBalanceAccountId: string, id: string, limits: table<amount: record>>"
    get-grant-offers: "record<grantOffers: table<accountHolderId: string, amount: record, contractType: string, expiresAt: record, fee: record, id: string, repayment: record, startsAt: record>>"
    get-grant-offers-grant-offer-id: "record<accountHolderId: string, amount: record<currency: string, value: int>, contractType: string, expiresAt: record, fee: record<amount: record<currency: string, value: int>>, id: string, repayment: record<basisPoints: int, term: record<estimatedDays: int, maximumDays: int>, threshold: record<amount: record>>, startsAt: record>"
    post-payment-instrument-groups: "record<balancePlatform: string, description: string, id: string, properties: record, reference: string, txVariant: string>"
    get-payment-instrument-groups-id: "record<balancePlatform: string, description: string, id: string, properties: record, reference: string, txVariant: string>"
    get-payment-instrument-groups-id-transaction-rules: "record<transactionRules: table<aggregationLevel: string, description: string, endDate: string, entityKey: record, id: string, interval: record, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record, score: int, startDate: string, status: string, type: string>>"
    post-payment-instruments: "record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string>"
    get-payment-instruments-id: "record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string>"
    patch-payment-instruments-id: "record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusComment: string, statusReason: string, type: string>"
    get-payment-instruments-id-reveal: "record<cvc: string, expiration: record<month: string, year: string>, pan: string>"
    get-payment-instruments-id-transaction-rules: "record<transactionRules: table<aggregationLevel: string, description: string, endDate: string, entityKey: record, id: string, interval: record, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record, score: int, startDate: string, status: string, type: string>>"
    post-transaction-rules: "record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string>"
    delete-transaction-rules-transaction-rule-id: "record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string>"
    get-transaction-rules-transaction-rule-id: "record<transactionRule: record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record, brandVariants: record, countries: record, dayOfWeek: record, differentCurrencies: record, entryModes: record, internationalTransaction: record, matchingTransactions: record, mccs: record, merchantNames: record, merchants: record, processingTypes: record, timeOfDay: record, totalAmount: record>, score: int, startDate: string, status: string, type: string>>"
    patch-transaction-rules-transaction-rule-id: "record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string>"
    post-validate-bank-account-identification: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-account-holders" "get-account-holders-id" "patch-account-holders-id" "get-account-holders-id-balance-accounts" "post-balance-accounts" "get-balance-accounts-balance-account-id-sweeps" "post-balance-accounts-balance-account-id-sweeps" "delete-balance-accounts-balance-account-id-sweeps-sweep-id" "get-balance-accounts-balance-account-id-sweeps-sweep-id" "patch-balance-accounts-balance-account-id-sweeps-sweep-id" "get-balance-accounts-id" "patch-balance-accounts-id" "get-balance-accounts-id-payment-instruments" "get-balance-platforms-id" "get-balance-platforms-id-account-holders" "get-grant-accounts-id" "get-grant-offers" "get-grant-offers-grant-offer-id" "post-payment-instrument-groups" "get-payment-instrument-groups-id" "get-payment-instrument-groups-id-transaction-rules" "post-payment-instruments" "get-payment-instruments-id" "patch-payment-instruments-id" "get-payment-instruments-id-reveal" "get-payment-instruments-id-transaction-rules" "post-transaction-rules" "delete-transaction-rules-transaction-rule-id" "get-transaction-rules-transaction-rule-id" "patch-transaction-rules-transaction-rule-id" "post-validate-bank-account-identification" "commands"] | sort) } | get name | first)
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

# Create an account holder
#
# POST /accountHolders
# Returns: record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>>
# operationId: post-accountHolders
export def "post-account-holders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance-platform: string # The unique identifier of the [balance platform](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balancePlatforms/{id}__queryParam_id) to which the account holder belongs. Required in the request if your API credentials can be used for multiple balance platforms.
  --capabilities: record # Contains key-value pairs that specify the actions that an account holder can do in your platform. The key is a capability required for your integration. For example, **issueCard** for Issuing. The value is an object containing the settings for the capability.
  --contact-details: record # shape: {address: record, email: string, phone: record, webAddress?: string}
  --description: string # Your description for the account holder, maximum 300 characters.
  legal_entity_id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) associated with the account holder. Adyen performs a verification process against the legal entity of the account holder.
  --reference: string # Your reference for the account holder, maximum 150 characters.
  --time-zone: string # The [time zone](https://www.iana.org/time-zones) of the account holder. For example, **Europe/Amsterdam**. Defaults to the time zone of the balance platform if no time zone is set. For possible values, see the [list of time zone codes](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accountHolders"
    body: {content_type: "application/json", kind: json, fields: [{name: balancePlatform, var: balance_platform}, {name: capabilities, var: capabilities}, {name: contactDetails, var: contact_details}, {name: description, var: description}, {name: legalEntityId, var: legal_entity_id}, {name: reference, var: reference}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    balance_platform: $balance_platform, capabilities: $capabilities, contact_details: $contact_details, description: $description, legal_entity_id: $legal_entity_id, reference: $reference, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an account holder
#
# GET /accountHolders/{id}
# Returns: record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>>
# operationId: get-accountHolders-id
export def "get-account-holders-id" [
  id: string
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
    path: "/accountHolders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an account holder
#
# PATCH /accountHolders/{id}
# Returns: record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>>
# operationId: patch-accountHolders-id
export def "patch-account-holders-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance-platform: string # The unique identifier of the [balance platform](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balancePlatforms/{id}__queryParam_id) to which the account holder belongs. Required in the request if your API credentials can be used for multiple balance platforms.
  --capabilities: record # Contains key-value pairs that specify the actions that an account holder can do in your platform. The key is a capability required for your integration. For example, **issueCard** for Issuing. The value is an object containing the settings for the capability.
  --contact-details: record # shape: {address: record, email: string, phone: record, webAddress?: string}
  --description: string # Your description for the account holder, maximum 300 characters.
  legal_entity_id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) associated with the account holder. Adyen performs a verification process against the legal entity of the account holder.
  --primary-balance-account: string # The ID of the account holder's primary balance account. By default, this is set to the first balance account that you create for the account holder. To assign a different balance account, send a PATCH request.
  --reference: string # Your reference for the account holder, maximum 150 characters.
  --status: string@status-completer # The status of the account holder. Possible values: * **active**: The account holder is active. This is the default status when creating an account holder. * **inactive (Deprecated)**: The account holder is temporarily inactive due to missing KYC details. You can set the account back to active by providing the missing KYC details. * **suspended**: The account holder is permanently deactivated by Adyen. This action cannot be undone. * **closed**: The account holder is permanently deactivated by you. This action cannot be undone.
  --time-zone: string # The [time zone](https://www.iana.org/time-zones) of the account holder. For example, **Europe/Amsterdam**. Defaults to the time zone of the balance platform if no time zone is set. For possible values, see the [list of time zone codes](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accountHolders/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: balancePlatform, var: balance_platform}, {name: capabilities, var: capabilities}, {name: contactDetails, var: contact_details}, {name: description, var: description}, {name: legalEntityId, var: legal_entity_id}, {name: primaryBalanceAccount, var: primary_balance_account}, {name: reference, var: reference}, {name: status, var: status}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, balance_platform: $balance_platform, capabilities: $capabilities, contact_details: $contact_details, description: $description, legal_entity_id: $legal_entity_id, primary_balance_account: $primary_balance_account, reference: $reference, status: $status, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all balance accounts of an account holder
#
# GET /accountHolders/{id}/balanceAccounts
# Returns: record<balanceAccounts: table<accountHolderId: string, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>, hasNext: bool, hasPrevious: bool>
# operationId: get-accountHolders-id-balanceAccounts
export def "get-account-holders-id-balance-accounts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items that you want to skip. (format: int32)
  --limit: int # The number of items returned per page, maximum 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accountHolders/{id}/balanceAccounts"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a balance account
#
# POST /balanceAccounts
# Returns: record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>
# operationId: post-balanceAccounts
export def "post-balance-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_id: string # The unique identifier of the [account holder](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/accountHolders__resParam_id) associated with the balance account.
  --default-currency-code: string # The default three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes) of the balance account. The default value is **EUR**.
  --description: string # A human-readable description of the balance account, maximum 300 characters. You can use this parameter to distinguish between multiple balance accounts under an account holder.
  --reference: string # Your reference for the balance account, maximum 150 characters.
  --time-zone: string # The [time zone](https://www.iana.org/time-zones) of the balance account. For example, **Europe/Amsterdam**. Defaults to the time zone of the account holder if no time zone is set. For possible values, see the [list of time zone codes](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/balanceAccounts"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderId, var: account_holder_id}, {name: defaultCurrencyCode, var: default_currency_code}, {name: description, var: description}, {name: reference, var: reference}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_holder_id: $account_holder_id, default_currency_code: $default_currency_code, description: $description, reference: $reference, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all sweeps for a balance account
#
# GET /balanceAccounts/{balanceAccountId}/sweeps
# Returns: record<hasNext: bool, hasPrevious: bool, sweeps: table<category: string, counterparty: record, currency: string, description: string, id: string, priorities: list, reason: string, schedule: any, status: string, sweepAmount: record, targetAmount: record, triggerAmount: record, type: string>>
# operationId: get-balanceAccounts-balanceAccountId-sweeps
export def "get-balance-accounts-balance-account-id-sweeps" [
  balance_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items that you want to skip. (format: int32)
  --limit: int # The number of items returned per page, maximum 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/balanceAccounts/{balanceAccountId}/sweeps"
    path_params: [{name: balanceAccountId, var: balance_account_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    balance_account_id: $balance_account_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a sweep
#
# POST /balanceAccounts/{balanceAccountId}/sweeps
# Returns: record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string>
# operationId: post-balanceAccounts-balanceAccountId-sweeps
export def "post-balance-accounts-balance-account-id-sweeps" [
  balance_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The type of transfer that results from the sweep. Possible values: - **bank**: Sweep to a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id). - **internal**: Transfer to another [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/balanceAccounts__resParam_id) within your platform. Required when setting `priorities`.
  counterparty: record # shape: {balanceAccountId?: string, merchantAccount?: string, transferInstrumentId?: string}
  currency: string # The three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes) in uppercase. For example, **EUR**. The sweep currency must match any of the [balances currencies](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balanceAccounts/{id}__resParam_balances).
  --description: string # The message that will be used in the sweep transfer's description body with a maximum length of 140 characters. If the message is longer after replacing placeholders, the message will be cut off at 140 characters.
  --priorities: list<string> # The list of priorities for the bank transfer. This sets the speed at which the transfer is sent and the fees that you have to pay. You can provide multiple priorities. Adyen will try to pay out using the priority listed first, and if that's not possible, it moves on to the next option in the order of provided priorities. Possible values: * **regular**: For normal, low-value transactions. * **fast**: Faster way to transfer funds but has higher fees. Recommended for high-priority, low-value transactions. * **wire**: Fastest way to transfer funds but has the highest fees. Recommended for high-priority, high-value transactions. * **instant**: Instant way to transfer funds in [SEPA countries](https://www.ecb.europa.eu/paym/integration/retail/sepa/html/index.en.html). * **crossBorder**: High-value transfer to a recipient in a different country. * **internal**: Transfer to an Adyen-issued business bank account (by bank account number/IBAN). Set `category` to **bank**. For more details, see [optional priorities setup](https://docs.adyen.com/marketplaces-and-platforms/payout-to-users/scheduled-payouts#optional-priorities-setup).
  schedule: any # The schedule when the `triggerAmount` is evaluated. If the balance meets the threshold, funds are pushed out of or pulled in to the balance account.
  --status: string@status-completer-1 # The status of the sweep. If not provided, by default, this is set to **active**. Possible values: * **active**: the sweep is enabled and funds will be pulled in or pushed out based on the defined configuration. * **inactive**: the sweep is disabled and cannot be triggered.
  --sweep-amount: record # shape: {currency: string, value: int}
  --target-amount: record # shape: {currency: string, value: int}
  --trigger-amount: record # shape: {currency: string, value: int}
  --type: string@type-completer # The direction of sweep, whether pushing out or pulling in funds to the balance account. If not provided, by default, this is set to **push**. Possible values: * **push**: _push out funds_ to a destination balance account or transfer instrument. * **pull**: _pull in funds_ from a source merchant account, transfer instrument, or balance account. (default: push)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/balanceAccounts/{balanceAccountId}/sweeps"
    path_params: [{name: balanceAccountId, var: balance_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: counterparty, var: counterparty}, {name: currency, var: currency}, {name: description, var: description}, {name: priorities, var: priorities}, {name: schedule, var: schedule}, {name: status, var: status}, {name: sweepAmount, var: sweep_amount}, {name: targetAmount, var: target_amount}, {name: triggerAmount, var: trigger_amount}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    balance_account_id: $balance_account_id, category: $category, counterparty: $counterparty, currency: $currency, description: $description, priorities: $priorities, schedule: $schedule, status: $status, sweep_amount: $sweep_amount, target_amount: $target_amount, trigger_amount: $trigger_amount, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a sweep
#
# DELETE /balanceAccounts/{balanceAccountId}/sweeps/{sweepId}
# operationId: delete-balanceAccounts-balanceAccountId-sweeps-sweepId
export def "delete-balance-accounts-balance-account-id-sweeps-sweep-id" [
  balance_account_id: string
  sweep_id: string
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
    path: "/balanceAccounts/{balanceAccountId}/sweeps/{sweepId}"
    path_params: [{name: balanceAccountId, var: balance_account_id}, {name: sweepId, var: sweep_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    balance_account_id: $balance_account_id, sweep_id: $sweep_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a sweep
#
# GET /balanceAccounts/{balanceAccountId}/sweeps/{sweepId}
# Returns: record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string>
# operationId: get-balanceAccounts-balanceAccountId-sweeps-sweepId
export def "get-balance-accounts-balance-account-id-sweeps-sweep-id" [
  balance_account_id: string
  sweep_id: string
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
    path: "/balanceAccounts/{balanceAccountId}/sweeps/{sweepId}"
    path_params: [{name: balanceAccountId, var: balance_account_id}, {name: sweepId, var: sweep_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    balance_account_id: $balance_account_id, sweep_id: $sweep_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a sweep
#
# PATCH /balanceAccounts/{balanceAccountId}/sweeps/{sweepId}
# Returns: record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string>
# operationId: patch-balanceAccounts-balanceAccountId-sweeps-sweepId
export def "patch-balance-accounts-balance-account-id-sweeps-sweep-id" [
  balance_account_id: string
  sweep_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The type of transfer that results from the sweep. Possible values: - **bank**: Sweep to a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id). - **internal**: Transfer to another [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/balanceAccounts__resParam_id) within your platform. Required when setting `priorities`.
  counterparty: record # shape: {balanceAccountId?: string, merchantAccount?: string, transferInstrumentId?: string}
  currency: string # The three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes) in uppercase. For example, **EUR**. The sweep currency must match any of the [balances currencies](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balanceAccounts/{id}__resParam_balances).
  --description: string # The message that will be used in the sweep transfer's description body with a maximum length of 140 characters. If the message is longer after replacing placeholders, the message will be cut off at 140 characters.
  --priorities: list<string> # The list of priorities for the bank transfer. This sets the speed at which the transfer is sent and the fees that you have to pay. You can provide multiple priorities. Adyen will try to pay out using the priority listed first, and if that's not possible, it moves on to the next option in the order of provided priorities. Possible values: * **regular**: For normal, low-value transactions. * **fast**: Faster way to transfer funds but has higher fees. Recommended for high-priority, low-value transactions. * **wire**: Fastest way to transfer funds but has the highest fees. Recommended for high-priority, high-value transactions. * **instant**: Instant way to transfer funds in [SEPA countries](https://www.ecb.europa.eu/paym/integration/retail/sepa/html/index.en.html). * **crossBorder**: High-value transfer to a recipient in a different country. * **internal**: Transfer to an Adyen-issued business bank account (by bank account number/IBAN). Set `category` to **bank**. For more details, see [optional priorities setup](https://docs.adyen.com/marketplaces-and-platforms/payout-to-users/scheduled-payouts#optional-priorities-setup).
  schedule: any # The schedule when the `triggerAmount` is evaluated. If the balance meets the threshold, funds are pushed out of or pulled in to the balance account.
  --status: string@status-completer-1 # The status of the sweep. If not provided, by default, this is set to **active**. Possible values: * **active**: the sweep is enabled and funds will be pulled in or pushed out based on the defined configuration. * **inactive**: the sweep is disabled and cannot be triggered.
  --sweep-amount: record # shape: {currency: string, value: int}
  --target-amount: record # shape: {currency: string, value: int}
  --trigger-amount: record # shape: {currency: string, value: int}
  --type: string@type-completer # The direction of sweep, whether pushing out or pulling in funds to the balance account. If not provided, by default, this is set to **push**. Possible values: * **push**: _push out funds_ to a destination balance account or transfer instrument. * **pull**: _pull in funds_ from a source merchant account, transfer instrument, or balance account. (default: push)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/balanceAccounts/{balanceAccountId}/sweeps/{sweepId}"
    path_params: [{name: balanceAccountId, var: balance_account_id}, {name: sweepId, var: sweep_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: counterparty, var: counterparty}, {name: currency, var: currency}, {name: description, var: description}, {name: priorities, var: priorities}, {name: schedule, var: schedule}, {name: status, var: status}, {name: sweepAmount, var: sweep_amount}, {name: targetAmount, var: target_amount}, {name: triggerAmount, var: trigger_amount}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    balance_account_id: $balance_account_id, sweep_id: $sweep_id, category: $category, counterparty: $counterparty, currency: $currency, description: $description, priorities: $priorities, schedule: $schedule, status: $status, sweep_amount: $sweep_amount, target_amount: $target_amount, trigger_amount: $trigger_amount, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a balance account
#
# GET /balanceAccounts/{id}
# Returns: record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>
# operationId: get-balanceAccounts-id
export def "get-balance-accounts-id" [
  id: string
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
    path: "/balanceAccounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a balance account
#
# PATCH /balanceAccounts/{id}
# Returns: record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>
# operationId: patch-balanceAccounts-id
export def "patch-balance-accounts-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-holder-id: string # The unique identifier of the [account holder](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/accountHolders__resParam_id) associated with the balance account.
  --default-currency-code: string # The default currency code of this balance account, in three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes) format. The default value is **EUR**.
  --description: string # A human-readable description of the balance account, maximum 300 characters. You can use this parameter to distinguish between multiple balance accounts under an account holder.
  --reference: string # Your reference to the balance account, maximum 150 characters.
  --status: string@status-completer # The status of the balance account. Payment instruments linked to the balance account can only be used if the balance account status is **active**. Possible values: **active**, **inactive**, **closed**, **suspended**.
  --time-zone: string # The [time zone](https://www.iana.org/time-zones) of the balance account. For example, **Europe/Amsterdam**. Defaults to the time zone of the account holder if no time zone is set. For possible values, see the [list of time zone codes](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/balanceAccounts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderId, var: account_holder_id}, {name: defaultCurrencyCode, var: default_currency_code}, {name: description, var: description}, {name: reference, var: reference}, {name: status, var: status}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, account_holder_id: $account_holder_id, default_currency_code: $default_currency_code, description: $description, reference: $reference, status: $status, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all payment instruments for a balance account
#
# GET /balanceAccounts/{id}/paymentInstruments
# Returns: record<hasNext: bool, hasPrevious: bool, paymentInstruments: table<balanceAccountId: string, bankAccount: any, card: record, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string>>
# operationId: get-balanceAccounts-id-paymentInstruments
export def "get-balance-accounts-id-payment-instruments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items that you want to skip. (format: int32)
  --limit: int # The number of items returned per page, maximum 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/balanceAccounts/{id}/paymentInstruments"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a balance platform
#
# GET /balancePlatforms/{id}
# Returns: record<description: string, id: string, status: string>
# operationId: get-balancePlatforms-id
export def "get-balance-platforms-id" [
  id: string
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
    path: "/balancePlatforms/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all account holders under a balance platform
#
# GET /balancePlatforms/{id}/accountHolders
# Returns: record<accountHolders: table<balancePlatform: string, capabilities: record, contactDetails: record, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: list>, hasNext: bool, hasPrevious: bool>
# operationId: get-balancePlatforms-id-accountHolders
export def "get-balance-platforms-id-account-holders" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items that you want to skip. (format: int32)
  --limit: int # The number of items returned per page, maximum 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/balancePlatforms/{id}/accountHolders"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a grant account
#
# GET /grantAccounts/{id}
# Returns: record<balances: table<currency: string, fee: int, principal: int, total: int>, fundingBalanceAccountId: string, id: string, limits: table<amount: record>>
# operationId: get-grantAccounts-id
export def "get-grant-accounts-id" [
  id: string
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
    path: "/grantAccounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all available grant offers
#
# GET /grantOffers
# Returns: record<grantOffers: table<accountHolderId: string, amount: record, contractType: string, expiresAt: record, fee: record, id: string, repayment: record, startsAt: record>>
# operationId: get-grantOffers
export def "get-grant-offers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-holder-id: string # The unique identifier of the grant account. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/grantOffers"
    query: [{name: accountHolderId, var: account_holder_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_holder_id: $account_holder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a grant offer
#
# GET /grantOffers/{grantOfferId}
# Returns: record<accountHolderId: string, amount: record<currency: string, value: int>, contractType: string, expiresAt: record, fee: record<amount: record<currency: string, value: int>>, id: string, repayment: record<basisPoints: int, term: record<estimatedDays: int, maximumDays: int>, threshold: record<amount: record>>, startsAt: record>
# operationId: get-grantOffers-grantOfferId
export def "get-grant-offers-grant-offer-id" [
  grant_offer_id: string
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
    path: "/grantOffers/{grantOfferId}"
    path_params: [{name: grantOfferId, var: grant_offer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    grant_offer_id: $grant_offer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a payment instrument group
#
# POST /paymentInstrumentGroups
# Returns: record<balancePlatform: string, description: string, id: string, properties: record, reference: string, txVariant: string>
# operationId: post-paymentInstrumentGroups
export def "post-payment-instrument-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  balance_platform: string # The unique identifier of the [balance platform](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balancePlatforms/{id}__queryParam_id) to which the payment instrument group belongs.
  --description: string # Your description for the payment instrument group, maximum 300 characters.
  --properties: record # Properties of the payment instrument group.
  --reference: string # Your reference for the payment instrument group, maximum 150 characters.
  tx_variant: string # The tx variant of the payment instrument group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paymentInstrumentGroups"
    body: {content_type: "application/json", kind: json, fields: [{name: balancePlatform, var: balance_platform}, {name: description, var: description}, {name: properties, var: properties}, {name: reference, var: reference}, {name: txVariant, var: tx_variant}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    balance_platform: $balance_platform, description: $description, properties: $properties, reference: $reference, tx_variant: $tx_variant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a payment instrument group
#
# GET /paymentInstrumentGroups/{id}
# Returns: record<balancePlatform: string, description: string, id: string, properties: record, reference: string, txVariant: string>
# operationId: get-paymentInstrumentGroups-id
export def "get-payment-instrument-groups-id" [
  id: string
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
    path: "/paymentInstrumentGroups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all transaction rules for a payment instrument group
#
# GET /paymentInstrumentGroups/{id}/transactionRules
# Returns: record<transactionRules: table<aggregationLevel: string, description: string, endDate: string, entityKey: record, id: string, interval: record, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record, score: int, startDate: string, status: string, type: string>>
# operationId: get-paymentInstrumentGroups-id-transactionRules
export def "get-payment-instrument-groups-id-transaction-rules" [
  id: string
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
    path: "/paymentInstrumentGroups/{id}/transactionRules"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a payment instrument
#
# POST /paymentInstruments
# Returns: record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string>
# operationId: post-paymentInstruments
export def "post-payment-instruments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  balance_account_id: string # The unique identifier of the [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/v1/post/balanceAccounts__resParam_id) associated with the payment instrument.
  --card: record # shape: {authentication?: record, brand: string, brandVariant: string, cardholderName: string, configuration?: record, deliveryContact?: record, formFactor: "physical"|"unknown"|"virtual"}
  --description: string # Your description for the payment instrument, maximum 300 characters.
  issuing_country_code: string # The two-character [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code where the payment instrument is issued. For example, **NL** or **US**.
  --payment-instrument-group-id: string # The unique identifier of the [payment instrument group](https://docs.adyen.com/api-explorer/#/balanceplatform/v1/post/paymentInstrumentGroups__resParam_id) to which the payment instrument belongs.
  --reference: string # Your reference for the payment instrument, maximum 150 characters.
  --status: string@status-completer # The status of the payment instrument. If a status is not specified when creating a payment instrument, it is set to **active** by default. However, there can be exceptions for cards based on the `card.formFactor` and the `issuingCountryCode`. For example, when issuing physical cards in the US, the default status is **inactive**. Possible values: * **active**: The payment instrument is active and can be used to make payments. * **inactive**: The payment instrument is inactive and cannot be used to make payments. * **suspended**: The payment instrument is suspended, either because it was stolen or lost. * **closed**: The payment instrument is permanently closed. This action cannot be undone.
  --status-reason: string@status-reason-completer # The reason for updating the status of the payment instrument. Possible values: **lost**, **stolen**, **damaged**, **suspectedFraud**, **expired**, **endOfLife**, **accountClosure**, **other**. If the reason is **other**, you must also send the `statusComment` parameter describing the status change.
  type: string@type-completer-1 # Type of payment instrument. Possible value: **card**, **bankAccount**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paymentInstruments"
    body: {content_type: "application/json", kind: json, fields: [{name: balanceAccountId, var: balance_account_id}, {name: card, var: card}, {name: description, var: description}, {name: issuingCountryCode, var: issuing_country_code}, {name: paymentInstrumentGroupId, var: payment_instrument_group_id}, {name: reference, var: reference}, {name: status, var: status}, {name: statusReason, var: status_reason}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    balance_account_id: $balance_account_id, card: $card, description: $description, issuing_country_code: $issuing_country_code, payment_instrument_group_id: $payment_instrument_group_id, reference: $reference, status: $status, status_reason: $status_reason, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a payment instrument
#
# GET /paymentInstruments/{id}
# Returns: record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string>
# operationId: get-paymentInstruments-id
export def "get-payment-instruments-id" [
  id: string
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
    path: "/paymentInstruments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a payment instrument
#
# PATCH /paymentInstruments/{id}
# Returns: record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusComment: string, statusReason: string, type: string>
# operationId: patch-paymentInstruments-id
export def "patch-payment-instruments-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance-account-id: string # The unique identifier of the balance account associated with this payment instrument. >You can only change the balance account ID if the payment instrument has **inactive** status.
  --card: record # shape: {authentication?: record, brand: string, brandVariant: string, cardholderName: string, configuration?: record, deliveryContact?: record, formFactor: "physical"|"unknown"|"virtual"}
  --status: string@status-completer # The status of the payment instrument. If a status is not specified when creating a payment instrument, it is set to **active** by default. However, there can be exceptions for cards based on the `card.formFactor` and the `issuingCountryCode`. For example, when issuing physical cards in the US, the default status is **inactive**. Possible values: * **active**: The payment instrument is active and can be used to make payments. * **inactive**: The payment instrument is inactive and cannot be used to make payments. * **suspended**: The payment instrument is suspended, either because it was stolen or lost. * **closed**: The payment instrument is permanently closed. This action cannot be undone.
  --status-comment: string # Comment for the status of the payment instrument. Required if `statusReason` is **other**.
  --status-reason: string@status-reason-completer # The reason for updating the status of the payment instrument. Possible values: **lost**, **stolen**, **damaged**, **suspectedFraud**, **expired**, **endOfLife**, **accountClosure**, **other**. If the reason is **other**, you must also send the `statusComment` parameter describing the status change.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/paymentInstruments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: balanceAccountId, var: balance_account_id}, {name: card, var: card}, {name: status, var: status}, {name: statusComment, var: status_comment}, {name: statusReason, var: status_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, balance_account_id: $balance_account_id, card: $card, status: $status, status_comment: $status_comment, status_reason: $status_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the PAN of a payment instrument
#
# GET /paymentInstruments/{id}/reveal
# Returns: record<cvc: string, expiration: record<month: string, year: string>, pan: string>
# operationId: get-paymentInstruments-id-reveal
export def "get-payment-instruments-id-reveal" [
  id: string
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
    path: "/paymentInstruments/{id}/reveal"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all transaction rules for a payment instrument
#
# GET /paymentInstruments/{id}/transactionRules
# Returns: record<transactionRules: table<aggregationLevel: string, description: string, endDate: string, entityKey: record, id: string, interval: record, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record, score: int, startDate: string, status: string, type: string>>
# operationId: get-paymentInstruments-id-transactionRules
export def "get-payment-instruments-id-transaction-rules" [
  id: string
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
    path: "/paymentInstruments/{id}/transactionRules"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transaction rule
#
# POST /transactionRules
# Returns: record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string>
# operationId: post-transactionRules
export def "post-transaction-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aggregation-level: string # The level at which data must be accumulated, used in rules with `type` **velocity** or **maxUsage**. The level must be the [same or lower in hierarchy](https://docs.adyen.com/issuing/transaction-rules#accumulate-data) than the `entityKey`. If not provided, by default, the rule will accumulate data at the **paymentInstrument** level. Possible values: **paymentInstrument**, **paymentInstrumentGroup**, **balanceAccount**, **accountHolder**, **balancePlatform**.
  description: string # Your description for the transaction rule, maximum 300 characters.
  --end-date: string # The date when the rule will stop being evaluated, in ISO 8601 extended offset date-time format. For example, **2020-12-18T10:15:30+01:00**. If not provided, the rule will be evaluated until the rule status is set to **inactive**.
  entity_key: record # shape: {entityReference?: string, entityType?: string}
  interval: record # shape: {dayOfMonth?: int, dayOfWeek?: "friday"|"monday"|"saturday"|"sunday"|"thursday"|"tuesday"|"wednesday", duration?: record, timeOfDay?: string, timeZone?: string, type: "daily"|"lifetime"|"monthly"|"perTransaction"|"rolling"|"sliding"|"weekly"}
  --outcome-type: string@outcome-type-completer # The [outcome](https://docs.adyen.com/issuing/transaction-rules#outcome) that will be applied when a transaction meets the conditions of the rule. If not provided, by default, this is set to **hardBlock**. Possible values: * **hardBlock**: the transaction is declined. * **scoreBased**: the transaction is assigned the `score` you specified. Adyen calculates the total score and if it exceeds 100, the transaction is declined.
  reference: string # Your reference for the transaction rule, maximum 150 characters.
  --request-type: string@request-type-completer # Indicates the type of request to which the rule applies. Possible values: **authorization**, **authentication**, **tokenization**.
  rule_restrictions: record # shape: {activeNetworkTokens?: record, brandVariants?: record, countries?: record, dayOfWeek?: record, differentCurrencies?: record, entryModes?: record, internationalTransaction?: record, matchingTransactions?: record, mccs?: record, merchantNames?: record, merchants?: record, processingTypes?: record, timeOfDay?: record, totalAmount?: record}
  --score: int # A positive or negative score applied to the transaction if it meets the conditions of the rule. Required when `outcomeType` is **scoreBased**. The value must be between **-100** and **100**. (format: int32)
  --start-date: string # The date when the rule will start to be evaluated, in ISO 8601 extended offset date-time format. For example, **2020-12-18T10:15:30+01:00**. If not provided when creating a transaction rule, the `startDate` is set to the date when the rule status is set to **active**.
  --status: string@status-completer-1 # The status of the transaction rule. If you provide a `startDate` in the request, the rule is automatically created with an **active** status. Possible values: **active**, **inactive**.
  type: string@type-completer-2 # The [type of rule](https://docs.adyen.com/issuing/transaction-rules#rule-types), which defines if a rule blocks transactions based on individual characteristics or accumulates data. Possible values: * **blockList**: decline a transaction when the conditions are met. * **maxUsage**: add the amount or number of transactions for the lifetime of a payment instrument, and then decline a transaction when the specified limits are met. * **velocity**: add the amount or number of transactions based on a specified time interval, and then decline a transaction when the specified limits are met.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transactionRules"
    body: {content_type: "application/json", kind: json, fields: [{name: aggregationLevel, var: aggregation_level}, {name: description, var: description}, {name: endDate, var: end_date}, {name: entityKey, var: entity_key}, {name: interval, var: interval}, {name: outcomeType, var: outcome_type}, {name: reference, var: reference}, {name: requestType, var: request_type}, {name: ruleRestrictions, var: rule_restrictions}, {name: score, var: score}, {name: startDate, var: start_date}, {name: status, var: status}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    aggregation_level: $aggregation_level, description: $description, end_date: $end_date, entity_key: $entity_key, interval: $interval, outcome_type: $outcome_type, reference: $reference, request_type: $request_type, rule_restrictions: $rule_restrictions, score: $score, start_date: $start_date, status: $status, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a transaction rule
#
# DELETE /transactionRules/{transactionRuleId}
# Returns: record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string>
# operationId: delete-transactionRules-transactionRuleId
export def "delete-transaction-rules-transaction-rule-id" [
  transaction_rule_id: string
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
    path: "/transactionRules/{transactionRuleId}"
    path_params: [{name: transactionRuleId, var: transaction_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    transaction_rule_id: $transaction_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a transaction rule
#
# GET /transactionRules/{transactionRuleId}
# Returns: record<transactionRule: record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record, brandVariants: record, countries: record, dayOfWeek: record, differentCurrencies: record, entryModes: record, internationalTransaction: record, matchingTransactions: record, mccs: record, merchantNames: record, merchants: record, processingTypes: record, timeOfDay: record, totalAmount: record>, score: int, startDate: string, status: string, type: string>>
# operationId: get-transactionRules-transactionRuleId
export def "get-transaction-rules-transaction-rule-id" [
  transaction_rule_id: string
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
    path: "/transactionRules/{transactionRuleId}"
    path_params: [{name: transactionRuleId, var: transaction_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    transaction_rule_id: $transaction_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a transaction rule
#
# PATCH /transactionRules/{transactionRuleId}
# Returns: record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string>
# operationId: patch-transactionRules-transactionRuleId
export def "patch-transaction-rules-transaction-rule-id" [
  transaction_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aggregation-level: string # The level at which data must be accumulated, used in rules with `type` **velocity** or **maxUsage**. The level must be the [same or lower in hierarchy](https://docs.adyen.com/issuing/transaction-rules#accumulate-data) than the `entityKey`. If not provided, by default, the rule will accumulate data at the **paymentInstrument** level. Possible values: **paymentInstrument**, **paymentInstrumentGroup**, **balanceAccount**, **accountHolder**, **balancePlatform**.
  description: string # Your description for the transaction rule, maximum 300 characters.
  --end-date: string # The date when the rule will stop being evaluated, in ISO 8601 extended offset date-time format. For example, **2020-12-18T10:15:30+01:00**. If not provided, the rule will be evaluated until the rule status is set to **inactive**.
  entity_key: record # shape: {entityReference?: string, entityType?: string}
  interval: record # shape: {dayOfMonth?: int, dayOfWeek?: "friday"|"monday"|"saturday"|"sunday"|"thursday"|"tuesday"|"wednesday", duration?: record, timeOfDay?: string, timeZone?: string, type: "daily"|"lifetime"|"monthly"|"perTransaction"|"rolling"|"sliding"|"weekly"}
  --outcome-type: string@outcome-type-completer # The [outcome](https://docs.adyen.com/issuing/transaction-rules#outcome) that will be applied when a transaction meets the conditions of the rule. If not provided, by default, this is set to **hardBlock**. Possible values: * **hardBlock**: the transaction is declined. * **scoreBased**: the transaction is assigned the `score` you specified. Adyen calculates the total score and if it exceeds 100, the transaction is declined.
  reference: string # Your reference for the transaction rule, maximum 150 characters.
  --request-type: string@request-type-completer # Indicates the type of request to which the rule applies. Possible values: **authorization**, **authentication**, **tokenization**.
  rule_restrictions: record # shape: {activeNetworkTokens?: record, brandVariants?: record, countries?: record, dayOfWeek?: record, differentCurrencies?: record, entryModes?: record, internationalTransaction?: record, matchingTransactions?: record, mccs?: record, merchantNames?: record, merchants?: record, processingTypes?: record, timeOfDay?: record, totalAmount?: record}
  --score: int # A positive or negative score applied to the transaction if it meets the conditions of the rule. Required when `outcomeType` is **scoreBased**. The value must be between **-100** and **100**. (format: int32)
  --start-date: string # The date when the rule will start to be evaluated, in ISO 8601 extended offset date-time format. For example, **2020-12-18T10:15:30+01:00**. If not provided when creating a transaction rule, the `startDate` is set to the date when the rule status is set to **active**.
  --status: string@status-completer-1 # The status of the transaction rule. If you provide a `startDate` in the request, the rule is automatically created with an **active** status. Possible values: **active**, **inactive**.
  type: string@type-completer-2 # The [type of rule](https://docs.adyen.com/issuing/transaction-rules#rule-types), which defines if a rule blocks transactions based on individual characteristics or accumulates data. Possible values: * **blockList**: decline a transaction when the conditions are met. * **maxUsage**: add the amount or number of transactions for the lifetime of a payment instrument, and then decline a transaction when the specified limits are met. * **velocity**: add the amount or number of transactions based on a specified time interval, and then decline a transaction when the specified limits are met.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transactionRules/{transactionRuleId}"
    path_params: [{name: transactionRuleId, var: transaction_rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: aggregationLevel, var: aggregation_level}, {name: description, var: description}, {name: endDate, var: end_date}, {name: entityKey, var: entity_key}, {name: interval, var: interval}, {name: outcomeType, var: outcome_type}, {name: reference, var: reference}, {name: requestType, var: request_type}, {name: ruleRestrictions, var: rule_restrictions}, {name: score, var: score}, {name: startDate, var: start_date}, {name: status, var: status}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    transaction_rule_id: $transaction_rule_id, aggregation_level: $aggregation_level, description: $description, end_date: $end_date, entity_key: $entity_key, interval: $interval, outcome_type: $outcome_type, reference: $reference, request_type: $request_type, rule_restrictions: $rule_restrictions, score: $score, start_date: $start_date, status: $status, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate a bank account
#
# POST /validateBankAccountIdentification
# Returns: record
# operationId: post-validateBankAccountIdentification
export def "post-validate-bank-account-identification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_identification: any # Bank account identification.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/validateBankAccountIdentification"
    body: {content_type: "application/json", kind: json, fields: [{name: accountIdentification, var: account_identification}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_identification: $account_identification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
