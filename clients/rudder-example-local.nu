# Auto-generated client for Rudder API v16
# Source: https://api.apis.guru/v2/specs/rudder.example.local/16/openapi.json
# Auth: --token flag or $env.RUDDER_API_TOKEN

const CLIENT = {
  base_url: "https://rudder.example.local/rudder/api/latest"
  token_env_var: "RUDDER_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-token, in: header, header_name: X-API-Token, prefix: ""}
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

def base-url-completer [] { ["https://rudder.example.local/rudder/api/latest"] }
def auth-scheme-completer [] { ["x-api-token"] }

# Completers for enum parameters
def status-completer [] { ["deployed" "pending deployment"] }
def policy-mode-completer [] { ["audit" "enforce"] }
def composition-completer [] { ["and" "or"] }
def status-completer-1 [] { ["accepted" "refused"] }
def mode-completer [] { ["erase" "move"] }
def policy-mode-completer-1 [] { ["audit" "default" "enforce"] }
def state-completer [] { ["empty-policies" "enabled" "ignored" "initializing" "preparing-eol"] }
def archive-kind-completer [] { ["directives" "full" "groups" "parameters" "rules"] }
def archive-restore-kind-completer [] { ["archive ID" "latestArchive" "latestCommit"] }
def is-pre-hahed-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-change-requests: "record<action: string, data: record<rules: list<record>>, result: string>"
    get-archives-export: "binary"
    import: "record<action: string, data: record<archiveImported: bool>, result: string>"
    get-branding-conf: "record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string>"
    update-b-randing-conf: "record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string>"
    reload-branding-conf: "record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string>"
    decline-change-request: "record<action: string, data: record<rules: list<record>>, result: string>"
    change-request-details: "record<action: string, data: record<rules: list<record>>, result: string>"
    update-change-request: "record<action: string, data: record<rules: list<record>>, result: string>"
    accept-change-request: "record<action: string, data: record<rules: list<record>>, result: string>"
    get-global-compliance: "record<action: string, data: record<globalCompliance: record<compliance: float, complianceDetails: record>>, result: string>"
    get-nodes-compliance: "record<action: string, data: record<nodes: list<record>>, result: string>"
    get-node-compliance: "record<action: string, data: record<nodes: list<record>>, result: string>"
    get-rules-compliance: "record<action: string, data: record<rules: list<record>>, result: string>"
    get-rule-compliance: "record<action: string, data: record<rules: list<record>>, result: string>"
    get-all-cve: "record<action: string, data: record<CVEs: list<record>>, result: string>"
    check-cve: "record<action: string, data: record<cveChecks: list<record>>, result: string>"
    get-cve-check-configuration: "record<action: string, data: record<apiKey: string, url: string>, result: string>"
    update-cve-check-configuration: "record<action: string, data: record<apiKey: string, url: string>, result: string>"
    get-last-cve-check: "record<action: string, data: record<CVEChecks: list<record>>, result: string>"
    get-cve-list: "record<action: string, data: record<CVEs: list<record>>, result: string>"
    update-cve: "record<action: string, data: record<CVEs: int>, result: string>"
    read-cv-efrom-fs: "record<action: string, data: record<CVEs: int>, result: string>"
    get-all-data-sources: "record<action: string, data: record<datasources: list<record>>, result: string>"
    create-data-source: "record<action: string, data: record<datasources: list<record>>, result: string>"
    reload-all-datasources-all-nodes: "record<action: string, data: string, result: string>"
    reload-one-datasource-all-nodes: "record<action: string, data: string, result: string>"
    delete-data-source: "record<action: string, data: record<datasources: list<record>>, result: string>"
    get-data-source: "record<action: string, data: record<datasources: list<record>>, result: string>"
    update-data-source: "record<action: string, data: record<datasources: list<record>>, result: string>"
    list-directives: "record<action: string, data: record<directives: list<record>>, result: string>"
    create-directive: "record<action: string, data: record<directives: list<record>>, result: string>"
    delete-directive: "record<action: string, data: record<directives: list<record>>, result: string>"
    directive-details: "record<action: string, data: record<directives: list<record>>, result: string>"
    update-directive: "record<action: string, data: record<directives: list<record>>, result: string>"
    check-directive: "record<action: string, data: record<directives: list<record>>, result: string>"
    list-groups: "record<action: string, data: record<groups: list<record>>, result: string>"
    create-group: "record<action: string, data: record<groups: list<record>>, result: string>"
    create-group-category: "record<action: string, data: record<groupCategories: list<record>>, result: string>"
    delete-group-category: "record<action: string, data: record<groupCategories: list<record>>, result: string>"
    get-group-category-details: "record<action: string, data: record<groupCategories: list<record>>, result: string>"
    update-group-category: "record<action: string, data: record<groupCategories: list<record>>, result: string>"
    get-group-tree: "record<action: string, data: record<groupCategories: record>, result: string>"
    delete-group: "record<action: string, data: record<groups: list<record>>, result: string>"
    group-details: "record<action: string, data: record<groups: list<record>>, result: string>"
    update-group: "record<action: string, data: record<groups: list<record>>, result: string>"
    reload-group: "record<action: string, data: record<groups: list<record>>, result: string>"
    api-general-informations: "record<action: string, data: record<availableVersions: list<record>, documentation: string, endpoints: list<list>>, result: string>"
    api-informations: "record<action: string, data: record<documentation: string, endpointName: string, endpoints: list<record>>, result: string>"
    api-sub-informations: "record<action: string, data: record<availableVersions: list<record>, documentation: string, endpoints: list<list>>, result: string>"
    queue-information: "record<action: string, data: record<queueMaxSize: int, queueSaturated: bool>, result: string>"
    upload-inventory: "record<action: string, data: string, result: string>"
    file-watcher-restart: "record<action: string, data: string, result: string>"
    file-watcher-start: "record<action: string, data: string, result: string>"
    file-watcher-stop: "record<action: string, data: string, result: string>"
    methods: "record<action: string, data: record<methods: record<agents: list, category: string, condition: record, deprecated: record, desc: string, documentation: string, id: string, name: string, parameters: list, version: string>>, result: string>"
    reload-methods: "record<action: string, data: record<methods: record<agents: list, category: string, condition: record, deprecated: record, desc: string, documentation: string, id: string, name: string, parameters: list, version: string>>, result: string>"
    list-accepted-nodes: "record<action: string, data: record<nodes: list<record>>, result: string>"
    create-nodes: "record<action: string, data: record<created: list<string>, failed: list<string>>, result: string>"
    apply-policy-all-nodes: "record<action: string, data: table<hostname: string, id: string, result: string>, result: string>"
    list-pending-nodes: "record<action: string, data: record<nodes: list<record>>, result: string>"
    change-pending-node-status: "record<action: string, data: record<nodes: list<record>>, result: string>"
    get-nodes-status: "record<action: string, data: record<nodes: list<record>>, result: string>"
    delete-node: "record<action: string, data: record<nodes: list<record>>, result: string>"
    node-details: "record<action: string, data: record<nodes: list<record>>, result: string>"
    update-node: "record<action: string, data: record<nodes: list<record>>, result: string>"
    apply-node: "string"
    reload-all-datasources-one-node: "record<action: string, data: string, result: string>"
    reload-one-datasource-one-node: "record<action: string, data: string, result: string>"
    node-inherited-properties: "record<action: string, data: table<id: string, properties: list>, result: string>"
    list-parameters: "record<action: string, data: record<parameters: list<record>>, result: string>"
    create-parameter: "record<action: string, data: record<parameters: list<record>>, id: string, result: string>"
    delete-parameter: "record<action: string, data: record<parameters: list<record>>, id: string, result: string>"
    parameter-details: "record<action: string, data: record<parameters: list<record>>, id: string, result: string>"
    update-parameter: "record<action: string, data: record<parameters: list<record>>, id: string, result: string>"
    list-rules: "record<action: string, data: record<rules: list<record>>, result: string>"
    create-rule: "record<action: string, data: record<rules: list<record>>, result: string>"
    create-rule-category: "record<action: string, data: record<ruleCategories: list<record>>, result: string>"
    delete-rule-category: "record<action: string, data: record<groupCategories: list<record>>, result: string>"
    get-rule-category-details: "record<action: string, data: record<rulesCategories: list<record>>, result: string>"
    update-rule-category: "record<action: string, data: record<ruleCategories: list<record>>, result: string>"
    get-rule-tree: "record<action: string, data: record<ruleCategories: record>, result: string>"
    delete-rule: "record<action: string, data: record<rules: list<record>>, result: string>"
    rule-details: "record<action: string, data: record<rules: list<record>>, result: string>"
    update-rule: "record<action: string, data: record<rules: list<record>>, result: string>"
    demote-to-node: "record<action: string, data: string, result: string>"
    promote-to-relay: "record<action: string, data: string, result: string>"
    get-all-secrets: "record<action: string, data: record<secrets: list<record>>, result: string>"
    update-secret: "record<action: string, data: record<secrets: list<record>>, result: string>"
    add-secret: "record<action: string, data: record<secrets: list<record>>, result: string>"
    delete-secret: "record<action: string, data: record<secrets: list<record>>, result: string>"
    get-secret: "record<action: string, data: record<secrets: list<record>>, result: string>"
    get-all-settings: "record<action: string, data: record<settings: record<allowed_networks: list, change_message_prompt: string, display_recent_changes_graphs: bool, enable_change_message: bool, enable_change_request: bool, enable_javascript_directives: string, enable_self_deployment: bool, enable_self_validation: bool, first_run_hour: int, first_run_minute: int, global_policy_mode: string, global_policy_mode_overridable: bool, heartbeat_frequency: int, mandatory_change_message: bool, modified_file_ttl: int, node_accept_duplicated_hostname: bool, node_onaccept_default_policyMode: string, node_onaccept_default_state: string, output_file_ttl: int, relay_server_synchronization_method: string, relay_server_synchronize_policies: bool, relay_server_synchronize_shared_files: bool, reporting_mode: string, require_time_synchronization: bool, rudder_compute_changes: bool, rudder_compute_dyngroups_max_parallelism: string, rudder_generation_compute_dyngroups: bool, rudder_generation_continue_on_error: bool, rudder_generation_delay: string, rudder_generation_js_timeout: int, rudder_generation_max_parallelism: string, rudder_generation_policy: string, rudder_report_protocol_default: string, rudder_save_db_compliance_details: bool, rudder_save_db_compliance_levels: bool, rudder_verify_certificates: bool, run_frequency: int, send_metrics: string, splay_time: int, unexpected_unbound_var_values: bool>>, result: string>"
    get-allowed-networks: "record<action: string, data: record<settings: record<allowed_networks: list>>, id: string, result: string>"
    set-allowed-networks: "record<action: string, data: record<allowed_networks: list<any>>, id: string, result: string>"
    modify-allowed-networks: "record<action: string, data: record<allowed_networks: list<any>>, result: string>"
    get-setting: "record<action: string, data: record<settingId: string>, id: string, result: string>"
    modify-setting: "record<action: string, data: record<settingId: string>, id: string, result: string>"
    none: "string"
    list-archives: "record<action: string, data: record<full: list<record>>, result: string>"
    create-archive: "record<action: string, data: record<full: record<commiter: string, gitCommit: string, id: string>>, result: string>"
    restore-archive: "record<action: string, data: record<directive: string, full: string, groups: string, parameters: string, rules: string>, result: string>"
    get-zip-archive: "binary"
    get-healthcheck-result: "record<action: string, data: table<msg: string, name: string, status: string>, result: string>"
    get-system-info: "record<action: string, data: record<rudder: record<build-time: string, full-version: string, major-version: string>>, result: string>"
    purge-software: "record<action: string, data: list<string>, result: string>"
    regenerate-policies: "record<action: string, data: record<policies: string>, result: string>"
    reload-all: "record<action: string, data: record<groups: string, techniques: string>, result: string>"
    reload-groups: "record<action: string, data: record<groups: string>, result: string>"
    reload-techniques: "record<action: string, data: record<techniques: string>, result: string>"
    get-status: "record<action: string, data: record<global: string>, result: string>"
    update-policies: "record<action: string, data: record<policies: string>, result: string>"
    list-techniques: "record<action: string, data: record<techniques: list<record>>, result: string>"
    create-technique: "record<action: string, data: record<techniques: record<technique: record>>, result: string>"
    technique-categories: "record<action: string, data: record<techniqueCategories: record<id: string, name: string, path: string, subcategories: list>>, result: string>"
    techniques: "record<action: string, data: record<techniques: list<record>>, result: string>"
    list-techniques-versions: "record<action: string, data: record<techniques: list<record>>, result: string>"
    get-technique-all-version: "record<action: string, data: record<techniques: list<record>>, result: string>"
    list-techniques-directives: "record<action: string, data: record<directives: list<record>>, result: string>"
    delete-technique: "record<action: string, data: record<techniques: record<id: string, version: string>>, result: string>"
    get-technique-all-version-id: "record<action: string, data: record<techniques: list<record>>, result: string>"
    update-technique: "record<action: string, data: record<techniques: record<technique: record>>, result: string>"
    list-technique-version-directives: "record<action: string, data: record<directives: list<record>>, result: string>"
    get-techniques-resources: "record<action: string, data: record<resources: list<record>>, result: string>"
    technique-revisions: "record<action: string, data: record<techniques: list<record>>, result: string>"
    add-user: "record<action: string, data: record<addedUser: record<password: string, role: list, username: string>>, result: string>"
    get-role: "record<action: string, data: table<id: string, rights: list>, result: string>"
    update-user: "record<action: string, data: record<updatedUser: record<password: string, role: list, username: string>>, result: string>"
    get-user-info: "record<action: string, data: record<digest: string, users: list<record>>, result: string>"
    reload-user-conf: "record<action: string, data: record<reload: record<status: string>>, result: string>"
    delete-user: "record<action: string, data: record<deletedUser: record<username: string>>, result: string>"
    list-users: "record<action: string, data: table<isValidated: bool, userExists: bool, username: string>, result: string>"
    save-workflow-user: "record<action: string, data: record<isValidated: bool, userExists: bool, username: string>, result: string>"
    remove-validated-user: "record<action: string, data: string, result: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-change-requests" "get-archives-export" "import" "get-branding-conf" "update-b-randing-conf" "reload-branding-conf" "decline-change-request" "change-request-details" "update-change-request" "accept-change-request" "get-global-compliance" "get-nodes-compliance" "get-node-compliance" "get-rules-compliance" "get-rule-compliance" "get-all-cve" "check-cve" "get-cve-check-configuration" "update-cve-check-configuration" "get-last-cve-check" "get-cve-list" "update-cve" "read-cv-efrom-fs" "get-all-data-sources" "create-data-source" "reload-all-datasources-all-nodes" "reload-one-datasource-all-nodes" "delete-data-source" "get-data-source" "update-data-source" "list-directives" "create-directive" "delete-directive" "directive-details" "update-directive" "check-directive" "list-groups" "create-group" "create-group-category" "delete-group-category" "get-group-category-details" "update-group-category" "get-group-tree" "delete-group" "group-details" "update-group" "reload-group" "api-general-informations" "api-informations" "api-sub-informations" "queue-information" "upload-inventory" "file-watcher-restart" "file-watcher-start" "file-watcher-stop" "methods" "reload-methods" "list-accepted-nodes" "create-nodes" "apply-policy-all-nodes" "list-pending-nodes" "change-pending-node-status" "get-nodes-status" "delete-node" "node-details" "update-node" "apply-node" "reload-all-datasources-one-node" "reload-one-datasource-one-node" "node-inherited-properties" "list-parameters" "create-parameter" "delete-parameter" "parameter-details" "update-parameter" "list-rules" "create-rule" "create-rule-category" "delete-rule-category" "get-rule-category-details" "update-rule-category" "get-rule-tree" "delete-rule" "rule-details" "update-rule" "demote-to-node" "promote-to-relay" "get-all-secrets" "update-secret" "add-secret" "delete-secret" "get-secret" "get-all-settings" "get-allowed-networks" "set-allowed-networks" "modify-allowed-networks" "get-setting" "modify-setting" "none" "list-archives" "create-archive" "restore-archive" "get-zip-archive" "get-healthcheck-result" "get-system-info" "purge-software" "regenerate-policies" "reload-all" "reload-groups" "reload-techniques" "get-status" "update-policies" "list-techniques" "create-technique" "technique-categories" "techniques" "list-techniques-versions" "get-technique-all-version" "list-techniques-directives" "delete-technique" "get-technique-all-version-id" "update-technique" "list-technique-version-directives" "get-techniques-resources" "technique-revisions" "add-user" "get-role" "update-user" "get-user-info" "reload-user-conf" "delete-user" "list-users" "save-workflow-user" "remove-validated-user" "commands"] | sort) } | get name | first)
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

# List all change requests
#
# GET /api/changeRequests
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: listChangeRequests
export def "list-change-requests" [
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
    path: "/api/changeRequests"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a ZIP archive of the requested items and their dependencies
#
# GET /archives/export
# Returns: binary
# operationId: export
export def "get-archives-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # IDs (optionally with revision, '+' need to be escaped as '%2B') of rules to include
  --directives: list # IDs (optionally with revision, '+' need to be escaped as '%2B') of directives to include
  --techniques: list # IDs, ie technique name/technique version (optionally with revision, '+' need to be escaped as '%2B') of techniques to include
  --groups: list # IDs (optionally with revision, '+' need to be escaped as '%2B') of groups to include
  --include: list<string> # Scope of dependencies to include in archive, where rule as directives and groups dependencies, directives have techniques dependencies, and techniques and groups don't have dependencies. 'none' means no dependencies will be include, 'all' means that the whole tree will, 'directives' and 'groups' means to include them specifically, 'techniques' means to include both directives and techniques.
]: nothing -> any {
  http-request {
    method: get
    path: "/archives/export"
    query: [{name: rules, var: rules, style: csv}, {name: directives, var: directives, style: csv}, {name: techniques, var: techniques, style: csv}, {name: groups, var: groups, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: x-api-token
  } {
    rules: $rules, directives: $directives, techniques: $techniques, groups: $groups, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a ZIP archive of policies into Rudder
#
# POST /archives/import
# Returns: record<action: string, data: record<archiveImported: bool>, result: string>
# operationId: import
export def "import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archive: string # The ZIP archive file containing policies in a conventional layout and serialization format (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/archives/import"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: archive, var: archive}], files: [archive]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    archive: $archive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get branding configuration
#
# GET /branding
# Returns: record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string>
# operationId: getBrandingConf
export def "get-branding-conf" [
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
    path: "/branding"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update web interface customization
#
# POST /branding
# Returns: record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string>
# operationId: updateBRandingConf
export def "update-b-randing-conf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bar_color: record # shape: {alpha: float, blue: float, green: float, red: float}
  --display-bar: oneof<nothing, bool> # Whether header bar is displayed or not
  --display-bar-login: oneof<nothing, bool> # Whether header bar is displayed in login page or not
  --display-label: oneof<nothing, bool> # Whether header bar's label is displayed or not
  --display-motd: oneof<nothing, bool> # Whether the message of the day is displayed in login page or not
  label_color: record # shape: {alpha: float, blue: float, green: float, red: float}
  label_text: string # The header bar's label title (e.g. Production)
  motd: string # Message of the day in login page (e.g. Welcome, please sign in:)
  small_logo: record # shape: {enable: bool}
  wide_logo: record # shape: {enable: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/branding"
    body: {content_type: "application/json", kind: json, fields: [{name: barColor, var: bar_color}, {name: displayBar, var: display_bar, required: true}, {name: displayBarLogin, var: display_bar_login, required: true}, {name: displayLabel, var: display_label, required: true}, {name: displayMotd, var: display_motd, required: true}, {name: labelColor, var: label_color}, {name: labelText, var: label_text}, {name: motd, var: motd}, {name: smallLogo, var: small_logo}, {name: wideLogo, var: wide_logo}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    bar_color: $bar_color, display_bar: $display_bar, display_bar_login: $display_bar_login, display_label: $display_label, display_motd: $display_motd, label_color: $label_color, label_text: $label_text, motd: $motd, small_logo: $small_logo, wide_logo: $wide_logo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload branding file
#
# POST /branding/reload
# Returns: record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string>
# operationId: reloadBrandingConf
export def "reload-branding-conf" [
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
    method: post
    path: "/branding/reload"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decline a request details
#
# DELETE /changeRequests/{changeRequestId}
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: declineChangeRequest
export def "decline-change-request" [
  change_request_id: int
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
    path: "/changeRequests/{changeRequestId}"
    path_params: [{name: changeRequestId, var: change_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    change_request_id: $change_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a change request details
#
# GET /changeRequests/{changeRequestId}
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: changeRequestDetails
export def "change-request-details" [
  change_request_id: int
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
    path: "/changeRequests/{changeRequestId}"
    path_params: [{name: changeRequestId, var: change_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    change_request_id: $change_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a request details
#
# POST /changeRequests/{changeRequestId}
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: updateChangeRequest
export def "update-change-request" [
  change_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Change request description
  --name: string # Change request name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/changeRequests/{changeRequestId}"
    path_params: [{name: changeRequestId, var: change_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    change_request_id: $change_request_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept a request details
#
# POST /changeRequests/{changeRequestId}/accept
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: acceptChangeRequest
export def "accept-change-request" [
  change_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # New status of the change request (e.g. deployed)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/changeRequests/{changeRequestId}/accept"
    path_params: [{name: changeRequestId, var: change_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    change_request_id: $change_request_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Global compliance
#
# GET /compliance
# Returns: record<action: string, data: record<globalCompliance: record<compliance: float, complianceDetails: record>>, result: string>
# operationId: getGlobalCompliance
export def "get-global-compliance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/compliance"
    query: [{name: precision, var: precision}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    precision: $precision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compliance details for all nodes
#
# GET /compliance/nodes
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: getNodesCompliance
export def "get-nodes-compliance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: int # Number of depth level of compliance objects to display (1:rules, 2:directives, 3:components, 4:nodes, 5:values, 6:reports) (default: 10, e.g. 4)
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/compliance/nodes"
    query: [{name: level, var: level}, {name: precision, var: precision}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    level: $level, precision: $precision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compliance details by node
#
# GET /compliance/nodes/{nodeId}
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: getNodeCompliance
export def "get-node-compliance" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: int # Number of depth level of compliance objects to display (1:rules, 2:directives, 3:components, 4:nodes, 5:values, 6:reports) (default: 10, e.g. 4)
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/compliance/nodes/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    query: [{name: level, var: level}, {name: precision, var: precision}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id, level: $level, precision: $precision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compliance details for all rules
#
# GET /compliance/rules
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: getRulesCompliance
export def "get-rules-compliance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: int # Number of depth level of compliance objects to display (1:rules, 2:directives, 3:components, 4:nodes, 5:values, 6:reports) (default: 10, e.g. 4)
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/compliance/rules"
    query: [{name: level, var: level}, {name: precision, var: precision}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    level: $level, precision: $precision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compliance details by rule
#
# GET /compliance/rules/{ruleId}
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: getRuleCompliance
export def "get-rule-compliance" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: int # Number of depth level of compliance objects to display (1:rules, 2:directives, 3:components, 4:nodes, 5:values, 6:reports) (default: 10, e.g. 4)
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/compliance/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    query: [{name: level, var: level}, {name: precision, var: precision}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    rule_id: $rule_id, level: $level, precision: $precision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all CVE details
#
# GET /cve
# Returns: record<action: string, data: record<CVEs: list<record>>, result: string>
# operationId: getAllCve
export def "get-all-cve" [
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
    path: "/cve"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a CVE check
#
# POST /cve/check
# Returns: record<action: string, data: record<cveChecks: list<record>>, result: string>
# operationId: checkCVE
export def "check-cve" [
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
    method: post
    path: "/cve/check"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CVE check config
#
# GET /cve/check/config
# Returns: record<action: string, data: record<apiKey: string, url: string>, result: string>
# operationId: getCVECheckConfiguration
export def "get-cve-check-configuration" [
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
    path: "/cve/check/config"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update cve check config
#
# POST /cve/check/config
# Returns: record<action: string, data: record<apiKey: string, url: string>, result: string>
# operationId: updateCVECheckConfiguration
export def "update-cve-check-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # Token used by to contact the API to check CVE
  --url: string # Url used to check CVE (e.g. https://api.rudder.io/cve/v1/)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cve/check/config"
    body: {content_type: "application/json", kind: json, fields: [{name: apiKey, var: api_key}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    api_key: $api_key, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get last CVE check result
#
# GET /cve/check/last
# Returns: record<action: string, data: record<CVEChecks: list<record>>, result: string>
# operationId: getLastCVECheck
export def "get-last-cve-check" [
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
    path: "/cve/check/last"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of CVE details
#
# POST /cve/list
# Returns: record<action: string, data: record<CVEs: list<record>>, result: string>
# operationId: getCVEList
export def "get-cve-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cve-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cve/list"
    body: {content_type: "application/json", kind: json, fields: [{name: cveIds, var: cve_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    cve_ids: $cve_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update CVE database from remote source
#
# POST /cve/update/
# Returns: record<action: string, data: record<CVEs: int>, result: string>
# operationId: updateCVE
export def "update-cve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # Url used to update CVE, will default to one set in config (e.g. https://nvd.nist.gov/feeds/json/cve/1.1)
  --years: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cve/update/"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}, {name: years, var: years}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    url: $url, years: $years
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update CVE database from file system
#
# POST /cve/update/fs
# Returns: record<action: string, data: record<CVEs: int>, result: string>
# operationId: readCVEfromFS
export def "read-cv-efrom-fs" [
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
    method: post
    path: "/cve/update/fs"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all data sources
#
# GET /datasources
# Returns: record<action: string, data: record<datasources: list<record>>, result: string>
# operationId: getAllDataSources
export def "get-all-data-sources" [
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
    path: "/datasources"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a data source
#
# PUT /datasources
# Returns: record<action: string, data: record<datasources: list<record>>, result: string>
# operationId: createDataSource
export def "create-data-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the goal of the data source to create. (e.g. Synchronize example data from the CMDB)
  --enabled: oneof<nothing, bool> # Enable or disable data source. (e.g. true)
  --id: string # Unique identifier of the data source to create. (e.g. test-data-source)
  --name: string # The human readable name of the data source to create. (e.g. Test data source)
  --run-parameters: record # Parameters to configure when the data source is fetched to update node properties. — shape: {onGeneration?: bool, onNewNode?: bool, schedule?: record}
  --type: record # Define and configure data source type. — shape: {name?: "HTTP", parameters?: record}
  --update-timeout: int # Duration in seconds before aborting data source update. The main goal is to prevent never ending requests. If a periodicity if configured, you should set that timeout at a lower value. (e.g. 30)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/datasources"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: enabled, var: enabled}, {name: id, var: id}, {name: name, var: name}, {name: runParameters, var: run_parameters}, {name: type, var: type}, {name: updateTimeout, var: update_timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    description: $description, enabled: $enabled, id: $id, name: $name, run_parameters: $run_parameters, type: $type, update_timeout: $update_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update properties from data sources
#
# POST /datasources/reload
# Returns: record<action: string, data: string, result: string>
# operationId: ReloadAllDatasourcesAllNodes
export def "reload-all-datasources-all-nodes" [
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
    method: post
    path: "/datasources/reload"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update properties from data sources
#
# POST /datasources/reload/{datasourceId}
# Returns: record<action: string, data: string, result: string>
# operationId: ReloadOneDatasourceAllNodes
export def "reload-one-datasource-all-nodes" [
  datasource_id: string
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
    method: post
    path: "/datasources/reload/{datasourceId}"
    path_params: [{name: datasourceId, var: datasource_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    datasource_id: $datasource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a data source
#
# DELETE /datasources/{datasourceId}
# Returns: record<action: string, data: record<datasources: list<record>>, result: string>
# operationId: deleteDataSource
export def "delete-data-source" [
  datasource_id: string
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
    path: "/datasources/{datasourceId}"
    path_params: [{name: datasourceId, var: datasource_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    datasource_id: $datasource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get data source configuration
#
# GET /datasources/{datasourceId}
# Returns: record<action: string, data: record<datasources: list<record>>, result: string>
# operationId: getDataSource
export def "get-data-source" [
  datasource_id: string
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
    path: "/datasources/{datasourceId}"
    path_params: [{name: datasourceId, var: datasource_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    datasource_id: $datasource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a data source configuration
#
# POST /datasources/{datasourceId}
# Returns: record<action: string, data: record<datasources: list<record>>, result: string>
# operationId: updateDataSource
export def "update-data-source" [
  datasource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the goal of the data source to create. (e.g. Synchronize example data from the CMDB)
  --enabled: oneof<nothing, bool> # Enable or disable data source. (e.g. true)
  --id: string # Unique identifier of the data source to create. (e.g. test-data-source)
  --name: string # The human readable name of the data source to create. (e.g. Test data source)
  --run-parameters: record # Parameters to configure when the data source is fetched to update node properties. — shape: {onGeneration?: bool, onNewNode?: bool, schedule?: record}
  --type: record # Define and configure data source type. — shape: {name?: "HTTP", parameters?: record}
  --update-timeout: int # Duration in seconds before aborting data source update. The main goal is to prevent never ending requests. If a periodicity if configured, you should set that timeout at a lower value. (e.g. 30)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datasources/{datasourceId}"
    path_params: [{name: datasourceId, var: datasource_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: enabled, var: enabled}, {name: id, var: id}, {name: name, var: name}, {name: runParameters, var: run_parameters}, {name: type, var: type}, {name: updateTimeout, var: update_timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    datasource_id: $datasource_id, description: $description, enabled: $enabled, id: $id, name: $name, run_parameters: $run_parameters, type: $type, update_timeout: $update_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all directives
#
# GET /directives
# Returns: record<action: string, data: record<directives: list<record>>, result: string>
# operationId: listDirectives
export def "list-directives" [
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
    path: "/directives"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a directive
#
# PUT /directives
# Returns: record<action: string, data: record<directives: list<record>>, result: string>
# operationId: createDirective
export def "create-directive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --long-description: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --short-description: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --source: string # The id of the directive the clone will be based onto. If this parameter if provided, the new directive will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --technique-name: string # Directive id (e.g. userManagement)
  --technique-version: string # Directive id (e.g. 8.0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/directives"
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: enabled, var: enabled}, {name: id, var: id}, {name: longDescription, var: long_description}, {name: parameters, var: parameters}, {name: priority, var: priority}, {name: shortDescription, var: short_description}, {name: source, var: source}, {name: system, var: system}, {name: tags, var: tags}, {name: techniqueName, var: technique_name}, {name: techniqueVersion, var: technique_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    display_name: $display_name, enabled: $enabled, id: $id, long_description: $long_description, parameters: $parameters, priority: $priority, short_description: $short_description, source: $source, system: $system, tags: $tags, technique_name: $technique_name, technique_version: $technique_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a directive
#
# DELETE /directives/{directiveId}
# Returns: record<action: string, data: record<directives: list<record>>, result: string>
# operationId: deleteDirective
export def "delete-directive" [
  directive_id: string
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
    path: "/directives/{directiveId}"
    path_params: [{name: directiveId, var: directive_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    directive_id: $directive_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get directive details
#
# GET /directives/{directiveId}
# Returns: record<action: string, data: record<directives: list<record>>, result: string>
# operationId: directiveDetails
export def "directive-details" [
  directive_id: string
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
    path: "/directives/{directiveId}"
    path_params: [{name: directiveId, var: directive_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    directive_id: $directive_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a directive details
#
# POST /directives/{directiveId}
# Returns: record<action: string, data: record<directives: list<record>>, result: string>
# operationId: updateDirective
export def "update-directive" [
  directive_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --long-description: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --policy-mode: string@policy-mode-completer # Policy mode of the directive (e.g. audit)
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --short-description: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --technique-name: string # Directive id (e.g. userManagement)
  --technique-version: string # Directive id (e.g. 8.0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/directives/{directiveId}"
    path_params: [{name: directiveId, var: directive_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: enabled, var: enabled}, {name: id, var: id}, {name: longDescription, var: long_description}, {name: parameters, var: parameters}, {name: policyMode, var: policy_mode}, {name: priority, var: priority}, {name: shortDescription, var: short_description}, {name: system, var: system}, {name: tags, var: tags}, {name: techniqueName, var: technique_name}, {name: techniqueVersion, var: technique_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    directive_id: $directive_id, display_name: $display_name, enabled: $enabled, id: $id, long_description: $long_description, parameters: $parameters, policy_mode: $policy_mode, priority: $priority, short_description: $short_description, system: $system, tags: $tags, technique_name: $technique_name, technique_version: $technique_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check that update on a directive is valid
#
# POST /directives/{directiveId}/check
# Returns: record<action: string, data: record<directives: list<record>>, result: string>
# operationId: checkDirective
export def "check-directive" [
  directive_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --long-description: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --policy-mode: string@policy-mode-completer # Policy mode of the directive (e.g. audit)
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --short-description: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --technique-name: string # Directive id (e.g. userManagement)
  --technique-version: string # Directive id (e.g. 8.0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/directives/{directiveId}/check"
    path_params: [{name: directiveId, var: directive_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: enabled, var: enabled}, {name: id, var: id}, {name: longDescription, var: long_description}, {name: parameters, var: parameters}, {name: policyMode, var: policy_mode}, {name: priority, var: priority}, {name: shortDescription, var: short_description}, {name: system, var: system}, {name: tags, var: tags}, {name: techniqueName, var: technique_name}, {name: techniqueVersion, var: technique_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    directive_id: $directive_id, display_name: $display_name, enabled: $enabled, id: $id, long_description: $long_description, parameters: $parameters, policy_mode: $policy_mode, priority: $priority, short_description: $short_description, system: $system, tags: $tags, technique_name: $technique_name, technique_version: $technique_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all groups
#
# GET /groups
# Returns: record<action: string, data: record<groups: list<record>>, result: string>
# operationId: listGroups
export def "list-groups" [
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
    path: "/groups"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a group
#
# PUT /groups
# Returns: record<action: string, data: record<groups: list<record>>, result: string>
# operationId: createGroup
export def "create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string # Id of the new group's category (format: uuid, e.g. e17ecf6a-a9f2-44de-a97c-116d24d30ff4)
  --description: string # Group description (e.g. Documentation for the group)
  display_name: string # Name of the group (e.g. Ubuntu 18.04 nodes)
  --dynamic: oneof<nothing, bool> # Should the group be dynamically refreshed (if not, it is a static group) (default: true)
  --enabled: oneof<nothing, bool> # Enable or disable the group (default: true)
  --id: string # Group id, only provide it when needed. (format: uuid, default: {autogenerated}, e.g. 32d013f7-b6d8-46c8-99d3-016307fa66c0)
  --properties: list # Group properties — item shape: {name: string, value: any}
  --query: record # The criteria defining the group. If not provided, the group will be empty. — shape: {composition?: "and"|"or", select?: string, where?: list}
  --source: string # The id of the group the clone will be based onto. If this parameter if provided, the new group will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: description, var: description}, {name: displayName, var: display_name}, {name: dynamic, var: dynamic}, {name: enabled, var: enabled}, {name: id, var: id}, {name: properties, var: properties}, {name: query, var: query}, {name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    category: $category, description: $description, display_name: $display_name, dynamic: $dynamic, enabled: $enabled, id: $id, properties: $properties, query: $query, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a group category
#
# PUT /groups/categories
# Returns: record<action: string, data: record<groupCategories: list<record>>, result: string>
# operationId: CreateGroupCategory
export def "create-group-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Group category description (e.g. Nodes by hardware provider)
  --id: string # Group category id, only provide it when needed. (format: uuid, default: {autogenerated}, e.g. 32d013f7-b6d8-46c8-99d3-016307fa66c0)
  name: string # Name of the group category (e.g. Hardware groups)
  parent: string # The parent category of the groups (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/categories"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    description: $description, id: $id, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete group category
#
# DELETE /groups/categories/{groupCategoryId}
# Returns: record<action: string, data: record<groupCategories: list<record>>, result: string>
# operationId: DeleteGroupCategory
export def "delete-group-category" [
  group_category_id: string
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
    path: "/groups/categories/{groupCategoryId}"
    path_params: [{name: groupCategoryId, var: group_category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    group_category_id: $group_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group category details
#
# GET /groups/categories/{groupCategoryId}
# Returns: record<action: string, data: record<groupCategories: list<record>>, result: string>
# operationId: GetGroupCategoryDetails
export def "get-group-category-details" [
  group_category_id: string
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
    path: "/groups/categories/{groupCategoryId}"
    path_params: [{name: groupCategoryId, var: group_category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    group_category_id: $group_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update group category details
#
# POST /groups/categories/{groupCategoryId}
# Returns: record<action: string, data: record<groupCategories: list<record>>, result: string>
# operationId: UpdateGroupCategory
export def "update-group-category" [
  group_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Group category description (e.g. Nodes by hardware provider)
  name: string # Name of the group category (e.g. Hardware groups)
  parent: string # The parent category of the groups (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/categories/{groupCategoryId}"
    path_params: [{name: groupCategoryId, var: group_category_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    group_category_id: $group_category_id, description: $description, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get groups tree
#
# GET /groups/tree
# Returns: record<action: string, data: record<groupCategories: record>, result: string>
# operationId: GetGroupTree
export def "get-group-tree" [
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
    path: "/groups/tree"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a group
#
# DELETE /groups/{groupId}
# Returns: record<action: string, data: record<groups: list<record>>, result: string>
# operationId: deleteGroup
export def "delete-group" [
  group_id: string
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
    path: "/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group details
#
# GET /groups/{groupId}
# Returns: record<action: string, data: record<groups: list<record>>, result: string>
# operationId: groupDetails
export def "group-details" [
  group_id: string
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
    path: "/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update group details
#
# POST /groups/{groupId}
# Returns: record<action: string, data: record<groups: list<record>>, result: string>
# operationId: updateGroup
export def "update-group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # Id of the new group's category (format: uuid, e.g. e17ecf6a-a9f2-44de-a97c-116d24d30ff4)
  --description: string # Group description (e.g. Documentation for the group)
  --display-name: string # Name of the group (e.g. Ubuntu 18.04 nodes)
  --dynamic: oneof<nothing, bool> # Should the group be dynamically refreshed (if not, it is a static group) (default: true)
  --enabled: oneof<nothing, bool> # Enable or disable the group (default: true)
  --query: record # The criteria defining the group. If not provided, the group will be empty. — shape: {composition?: "and"|"or", select?: string, where?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: description, var: description}, {name: displayName, var: display_name}, {name: dynamic, var: dynamic}, {name: enabled, var: enabled}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    group_id: $group_id, category: $category, description: $description, display_name: $display_name, dynamic: $dynamic, enabled: $enabled, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload a group
#
# POST /groups/{groupId}/reload
# Returns: record<action: string, data: record<groups: list<record>>, result: string>
# operationId: reloadGroup
export def "reload-group" [
  group_id: string
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
    method: post
    path: "/groups/{groupId}/reload"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all endoints
#
# GET /info
# Returns: record<action: string, data: record<availableVersions: list<record>, documentation: string, endpoints: list<list>>, result: string>
# operationId: apiGeneralInformations
export def "api-general-informations" [
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
    path: "/info"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about one API endpoint
#
# GET /info/details/{endpointName}
# Returns: record<action: string, data: record<documentation: string, endpointName: string, endpoints: list<record>>, result: string>
# operationId: apiInformations
export def "api-informations" [
  endpoint_name: string
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
    path: "/info/details/{endpointName}"
    path_params: [{name: endpointName, var: endpoint_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    endpoint_name: $endpoint_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information on endpoint in a section
#
# GET /info/{sectionId}
# Returns: record<action: string, data: record<availableVersions: list<record>, documentation: string, endpoints: list<list>>, result: string>
# operationId: apiSubInformations
export def "api-sub-informations" [
  section_id: string
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
    path: "/info/{sectionId}"
    path_params: [{name: sectionId, var: section_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    section_id: $section_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about inventory processing queue
#
# GET /inventories/info
# Returns: record<action: string, data: record<queueMaxSize: int, queueSaturated: bool>, result: string>
# operationId: queueInformation
export def "queue-information" [
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
    path: "/inventories/info"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload an inventory for processing
#
# POST /inventories/upload
# Returns: record<action: string, data: string, result: string>
# operationId: uploadInventory
export def "upload-inventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # The inventory file. The original file name is used to check extension, that should be .xml[.gz] or .ocs[.gz] (format: binary)
  --signature: string # The signature file. The original file name is used to check extension, that should be ${originalInventoryFileName}.sign[.gz] (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inventories/upload"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: signature, var: signature}], files: [file, signature]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    file: $file, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restart inventory watcher
#
# POST /inventories/watcher/restart
# Returns: record<action: string, data: string, result: string>
# operationId: fileWatcherRestart
export def "file-watcher-restart" [
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
    method: post
    path: "/inventories/watcher/restart"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start inventory watcher
#
# POST /inventories/watcher/start
# Returns: record<action: string, data: string, result: string>
# operationId: fileWatcherStart
export def "file-watcher-start" [
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
    method: post
    path: "/inventories/watcher/start"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop inventory watcher
#
# POST /inventories/watcher/stop
# Returns: record<action: string, data: string, result: string>
# operationId: fileWatcherStop
export def "file-watcher-stop" [
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
    method: post
    path: "/inventories/watcher/stop"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List methods
#
# GET /methods
# Returns: record<action: string, data: record<methods: record<agents: list, category: string, condition: record, deprecated: record, desc: string, documentation: string, id: string, name: string, parameters: list, version: string>>, result: string>
# operationId: methods
export def "methods" [
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
    path: "/methods"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload methods
#
# POST /methods/reload
# Returns: record<action: string, data: record<methods: record<agents: list, category: string, condition: record, deprecated: record, desc: string, documentation: string, id: string, name: string, parameters: list, version: string>>, result: string>
# operationId: reloadMethods
export def "reload-methods" [
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
    method: post
    path: "/methods/reload"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List managed nodes
#
# GET /nodes
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: listAcceptedNodes
export def "list-accepted-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Level of information to include from the node inventory. Some base levels are defined (**minimal**, **default**, **full**). You can add fields you want to a base level by adding them to the list, possible values are keys from json answer. If you don't provide a base level, they will be added to `default` level, so if you only want os details, use `minimal,os` as the value for this parameter. * **minimal** includes: `id`, `hostname` and `status` * **default** includes **minimal** plus `architectureDescription`, `description`, `ipAddresses`, `lastRunDate`, `lastInventoryDate`, `machine`, `os`, `managementTechnology`, `policyServerId`, `properties` (be careful! Only node own properties, if you also need inherited properties, look at the dedicated `/nodes/{id}/inheritedProperties` endpoint), `policyMode `, `ram` and `timezone` * **full** includes: **default** plus `accounts`, `bios`, `controllers`, `environmentVariables`, `fileSystems`, `managementTechnologyDetails`, `memories`, `networkInterfaces`, `ports`, `processes`, `processors`, `slots`, `software`, `sound`, `storage`, `videos` and `virtualMachines` (format: comma-separated list, default: default, e.g. minimal)
  --query: string # The criterion you want to find for your nodes. Replaces the `where`, `composition` and `select` parameters in a single parameter.
  --where: string # The criterion you want to find for your nodes
  --composition: string@composition-completer # Boolean operator to use between each `where` criteria. (default: and, e.g. and)
  --select: string # What kind of data we want to include. Here we can get policy servers/relay by setting `nodeAndPolicyServer`. Only used if `where` is defined. (default: node)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nodes"
    query: [{name: include, var: include}, {name: query, var: query}, {name: where, var: where}, {name: composition, var: composition}, {name: select, var: select}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    include: $include, query: $query, where: $where, composition: $composition, select: $select
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create one or several new nodes
#
# PUT /nodes
# Returns: record<action: string, data: record<created: list<string>, failed: list<string>>, result: string>
# operationId: createNodes
export def "create-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/nodes"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger an agent run on all nodes
#
# POST /nodes/applyPolicy
# Returns: record<action: string, data: table<hostname: string, id: string, result: string>, result: string>
# operationId: applyPolicyAllNodes
export def "apply-policy-all-nodes" [
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
    method: post
    path: "/nodes/applyPolicy"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pending nodes
#
# GET /nodes/pending
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: listPendingNodes
export def "list-pending-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Level of information to include from the node inventory. Some base levels are defined (**minimal**, **default**, **full**). You can add fields you want to a base level by adding them to the list, possible values are keys from json answer. If you don't provide a base level, they will be added to `default` level, so if you only want os details, use `minimal,os` as the value for this parameter. * **minimal** includes: `id`, `hostname` and `status` * **default** includes **minimal** plus `architectureDescription`, `description`, `ipAddresses`, `lastRunDate`, `lastInventoryDate`, `machine`, `os`, `managementTechnology`, `policyServerId`, `properties` (be careful! Only node own properties, if you also need inherited properties, look at the dedicated `/nodes/{id}/inheritedProperties` endpoint), `policyMode `, `ram` and `timezone` * **full** includes: **default** plus `accounts`, `bios`, `controllers`, `environmentVariables`, `fileSystems`, `managementTechnologyDetails`, `memories`, `networkInterfaces`, `ports`, `processes`, `processors`, `slots`, `software`, `sound`, `storage`, `videos` and `virtualMachines` (format: comma-separated list, default: default, e.g. minimal)
  --query: string # The criterion you want to find for your nodes. Replaces the `where`, `composition` and `select` parameters in a single parameter.
  --where: string # The criterion you want to find for your nodes
  --composition: string@composition-completer # Boolean operator to use between each `where` criteria. (default: and, e.g. and)
  --select: string # What kind of data we want to include. Here we can get policy servers/relay by setting `nodeAndPolicyServer`. Only used if `where` is defined. (default: node)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nodes/pending"
    query: [{name: include, var: include}, {name: query, var: query}, {name: where, var: where}, {name: composition, var: composition}, {name: select, var: select}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    include: $include, query: $query, where: $where, composition: $composition, select: $select
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update pending Node status
#
# POST /nodes/pending/{nodeId}
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: changePendingNodeStatus
export def "change-pending-node-status" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # New status of the pending node (e.g. accepted)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/nodes/pending/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get nodes acceptation status
#
# GET /nodes/status
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: getNodesStatus
export def "get-nodes-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Comma separated list of node Ids (required, format: comma-separated list, default: default, e.g. 8403353b-42c4-46f5-a08d-bc77a1a0bad9,root)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nodes/status"
    query: [{name: ids, var: ids, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a node
#
# DELETE /nodes/{nodeId}
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: deleteNode
export def "delete-node" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # Deletion mode to use, either move to trash ('move', default) or erase ('erase') (default: move, e.g. move)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/nodes/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    query: [{name: mode, var: mode}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id, mode: $mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a node
#
# GET /nodes/{nodeId}
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: nodeDetails
export def "node-details" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Level of information to include from the node inventory. Some base levels are defined (**minimal**, **default**, **full**). You can add fields you want to a base level by adding them to the list, possible values are keys from json answer. If you don't provide a base level, they will be added to `default` level, so if you only want os details, use `minimal,os` as the value for this parameter. * **minimal** includes: `id`, `hostname` and `status` * **default** includes **minimal** plus `architectureDescription`, `description`, `ipAddresses`, `lastRunDate`, `lastInventoryDate`, `machine`, `os`, `managementTechnology`, `policyServerId`, `properties` (be careful! Only node own properties, if you also need inherited properties, look at the dedicated `/nodes/{id}/inheritedProperties` endpoint), `policyMode `, `ram` and `timezone` * **full** includes: **default** plus `accounts`, `bios`, `controllers`, `environmentVariables`, `fileSystems`, `managementTechnologyDetails`, `memories`, `networkInterfaces`, `ports`, `processes`, `processors`, `slots`, `software`, `sound`, `storage`, `videos` and `virtualMachines` (format: comma-separated list, default: default, e.g. minimal)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nodes/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    query: [{name: include, var: include}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update node settings and properties
#
# POST /nodes/{nodeId}
# Returns: record<action: string, data: record<nodes: list<record>>, result: string>
# operationId: updateNode
export def "update-node" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-key: record # Information about agent key or certificate — shape: {status?: "certified"|"undefined", value: string}
  --policy-mode: string@policy-mode-completer-1 # In which mode the node will apply its configuration policy. Use `default` to use the global mode. (e.g. audit)
  --properties: list # item shape: {name: string, value: any}
  --state: string@state-completer # The node life cycle state. See [dedicated doc](https://docs.rudder.io/reference/current/usage/advanced_node_management.html#node-lifecycle) for more information. (e.g. enabled)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/nodes/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agentKey, var: agent_key}, {name: policyMode, var: policy_mode}, {name: properties, var: properties}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id, agent_key: $agent_key, policy_mode: $policy_mode, properties: $properties, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger an agent run
#
# POST /nodes/{nodeId}/applyPolicy
# Returns: string
# operationId: applyNode
export def "apply-node" [
  node_id: string
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
    method: post
    path: "/nodes/{nodeId}/applyPolicy"
    path_params: [{name: nodeId, var: node_id}]
    accept: ["text/plain"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update properties for one node from all data sources
#
# POST /nodes/{nodeId}/fetchData
# Returns: record<action: string, data: string, result: string>
# operationId: ReloadAllDatasourcesOneNode
export def "reload-all-datasources-one-node" [
  node_id: string
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
    method: post
    path: "/nodes/{nodeId}/fetchData"
    path_params: [{name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update properties for one node from a data source
#
# POST /nodes/{nodeId}/fetchData/{datasourceId}
# Returns: record<action: string, data: string, result: string>
# operationId: ReloadOneDatasourceOneNode
export def "reload-one-datasource-one-node" [
  node_id: string
  datasource_id: string
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
    method: post
    path: "/nodes/{nodeId}/fetchData/{datasourceId}"
    path_params: [{name: nodeId, var: node_id}, {name: datasourceId, var: datasource_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id, datasource_id: $datasource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get inherited node properties for a node
#
# GET /nodes/{nodeId}/inheritedProperties
# Returns: record<action: string, data: table<id: string, properties: list>, result: string>
# operationId: nodeInheritedProperties
export def "node-inherited-properties" [
  node_id: string
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
    path: "/nodes/{nodeId}/inheritedProperties"
    path_params: [{name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all global parameters
#
# GET /parameters
# Returns: record<action: string, data: record<parameters: list<record>>, result: string>
# operationId: listParameters
export def "list-parameters" [
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
    path: "/parameters"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new parameter
#
# PUT /parameters
# Returns: record<action: string, data: record<parameters: list<record>>, id: string, result: string>
# operationId: createParameter
export def "create-parameter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the parameter (e.g. Default inform message put in footer of managed files by Rudder)
  id: string # Name of the parameter (e.g. rudder_file_edit_footer)
  --overridable: oneof<nothing, bool> # Is the global parameter overridable by node (e.g. false)
  --value: any # Value of the parameter (format: string or JSON, e.g. ### End of file managed by Rudder ###)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/parameters"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: overridable, var: overridable}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    description: $description, id: $id, overridable: $overridable, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a parameter
#
# DELETE /parameters/{parameterId}
# Returns: record<action: string, data: record<parameters: list<record>>, id: string, result: string>
# operationId: deleteParameter
export def "delete-parameter" [
  parameter_id: string
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
    path: "/parameters/{parameterId}"
    path_params: [{name: parameterId, var: parameter_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    parameter_id: $parameter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the value of a parameter
#
# GET /parameters/{parameterId}
# Returns: record<action: string, data: record<parameters: list<record>>, id: string, result: string>
# operationId: parameterDetails
export def "parameter-details" [
  parameter_id: string
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
    path: "/parameters/{parameterId}"
    path_params: [{name: parameterId, var: parameter_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    parameter_id: $parameter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a parameter's value
#
# POST /parameters/{parameterId}
# Returns: record<action: string, data: record<parameters: list<record>>, id: string, result: string>
# operationId: updateParameter
export def "update-parameter" [
  parameter_id: string
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
    method: post
    path: "/parameters/{parameterId}"
    path_params: [{name: parameterId, var: parameter_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    parameter_id: $parameter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all rules
#
# GET /rules
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: listRules
export def "list-rules" [
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
    path: "/rules"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a rule
#
# PUT /rules
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: createRule
export def "create-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # The parent category id. If provided, the new rule will be in this parent category (format: uuid, e.g. 38e0c6ea-917f-47b8-82e0-e6a1d3dd62ca)
  --directives: list<string> # Directives linked to the rule
  --display-name: string # Rule name (e.g. Security policy)
  --enabled: oneof<nothing, bool> # Is the rule enabled (e.g. true)
  --id: string # Rule id (format: uuid, e.g. 0c1713ae-cb9d-4f7b-abda-ca38c5d643ea)
  --long-description: string # Rule documentation (e.g. This rules should be applied to all Linux nodes required basic hardening)
  --short-description: string # One line rule description (e.g. Baseline applying CIS guidelines)
  --source: string # The id of the rule the clone will be based onto. If this parameter if provided, the new rule will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
  --system: oneof<nothing, bool> # If true it is an internal Rudder rule (e.g. false)
  --tags: list # item shape: {name?: string}
  --targets: list # Node and special groups targeted by that rule — item shape: {exclude: record, include: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/rules"
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: directives, var: directives}, {name: displayName, var: display_name}, {name: enabled, var: enabled}, {name: id, var: id}, {name: longDescription, var: long_description}, {name: shortDescription, var: short_description}, {name: source, var: source}, {name: system, var: system}, {name: tags, var: tags}, {name: targets, var: targets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    category: $category, directives: $directives, display_name: $display_name, enabled: $enabled, id: $id, long_description: $long_description, short_description: $short_description, source: $source, system: $system, tags: $tags, targets: $targets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a rule category
#
# PUT /rules/categories
# Returns: record<action: string, data: record<ruleCategories: list<record>>, result: string>
# operationId: CreateRuleCategory
export def "create-rule-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Rules category description (e.g. Baseline applying CIS guidelines)
  --id: string # Rule category id, only provide it when needed. (format: uuid, default: {autogenerated}, e.g. 32d013f7-b6d8-46c8-99d3-016307fa66c0)
  name: string # Name of the rule category (e.g. Security policies)
  parent: string # The parent category of the rules (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/rules/categories"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    description: $description, id: $id, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete group category
#
# DELETE /rules/categories/{ruleCategoryId}
# Returns: record<action: string, data: record<groupCategories: list<record>>, result: string>
# operationId: DeleteRuleCategory
export def "delete-rule-category" [
  rule_category_id: string
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
    path: "/rules/categories/{ruleCategoryId}"
    path_params: [{name: ruleCategoryId, var: rule_category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    rule_category_id: $rule_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get rule category details
#
# GET /rules/categories/{ruleCategoryId}
# Returns: record<action: string, data: record<rulesCategories: list<record>>, result: string>
# operationId: GetRuleCategoryDetails
export def "get-rule-category-details" [
  rule_category_id: string
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
    path: "/rules/categories/{ruleCategoryId}"
    path_params: [{name: ruleCategoryId, var: rule_category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    rule_category_id: $rule_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update rule category details
#
# POST /rules/categories/{ruleCategoryId}
# Returns: record<action: string, data: record<ruleCategories: list<record>>, result: string>
# operationId: UpdateRuleCategory
export def "update-rule-category" [
  rule_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Rules category description (e.g. Baseline applying CIS guidelines)
  name: string # Name of the rule category (e.g. Security policies)
  parent: string # The parent category of the rules (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rules/categories/{ruleCategoryId}"
    path_params: [{name: ruleCategoryId, var: rule_category_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    rule_category_id: $rule_category_id, description: $description, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get rules tree
#
# GET /rules/tree
# Returns: record<action: string, data: record<ruleCategories: record>, result: string>
# operationId: GetRuleTree
export def "get-rule-tree" [
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
    path: "/rules/tree"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a rule
#
# DELETE /rules/{ruleId}
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: deleteRule
export def "delete-rule" [
  rule_id: string
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
    path: "/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a rule details
#
# GET /rules/{ruleId}
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: ruleDetails
export def "rule-details" [
  rule_id: string
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
    path: "/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a rule details
#
# POST /rules/{ruleId}
# Returns: record<action: string, data: record<rules: list<record>>, result: string>
# operationId: updateRule
export def "update-rule" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # The parent category id. (format: uuid, e.g. 38e0c6ea-917f-47b8-82e0-e6a1d3dd62ca)
  --directives: list<string> # Directives linked to the rule
  --display-name: string # Rule name (e.g. Security policy)
  --enabled: oneof<nothing, bool> # Is the rule enabled (e.g. true)
  --id: string # Rule id (format: uuid, e.g. 0c1713ae-cb9d-4f7b-abda-ca38c5d643ea)
  --long-description: string # Rule documentation (e.g. This rules should be applied to all Linux nodes required basic hardening)
  --short-description: string # One line rule description (e.g. Baseline applying CIS guidelines)
  --system: oneof<nothing, bool> # If true it is an internal Rudder rule (e.g. false)
  --tags: list # item shape: {name?: string}
  --targets: list # Node and special groups targeted by that rule — item shape: {exclude: record, include: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: directives, var: directives}, {name: displayName, var: display_name}, {name: enabled, var: enabled}, {name: id, var: id}, {name: longDescription, var: long_description}, {name: shortDescription, var: short_description}, {name: system, var: system}, {name: tags, var: tags}, {name: targets, var: targets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    rule_id: $rule_id, category: $category, directives: $directives, display_name: $display_name, enabled: $enabled, id: $id, long_description: $long_description, short_description: $short_description, system: $system, tags: $tags, targets: $targets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Demote a relay to simple node
#
# POST /scaleoutrelay/demote/{nodeId}
# Returns: record<action: string, data: string, result: string>
# operationId: demoteToNode
export def "demote-to-node" [
  node_id: string
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
    method: post
    path: "/scaleoutrelay/demote/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promote a node to relay
#
# POST /scaleoutrelay/promote/{nodeId}
# Returns: record<action: string, data: string, result: string>
# operationId: promoteToRelay
export def "promote-to-relay" [
  node_id: string
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
    method: post
    path: "/scaleoutrelay/promote/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all secrets
#
# GET /secret/
# Returns: record<action: string, data: record<secrets: list<record>>, result: string>
# operationId: getAllSecrets
export def "get-all-secrets" [
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
    path: "/secret/"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a secret
#
# POST /secret/
# Returns: record<action: string, data: record<secrets: list<record>>, result: string>
# operationId: updateSecret
export def "update-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the secret to identify it more easily (e.g. Password of my super secret user account)
  --name: string # The name of the secret used as a reference on the value (e.g. secret-password)
  --value: string # The value of the secret it will not be exposed in the interface (e.g. nj-k;EO32!kFWewn2Nk,u)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/secret/"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    description: $description, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a secret
#
# PUT /secret/
# Returns: record<action: string, data: record<secrets: list<record>>, result: string>
# operationId: addSecret
export def "add-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the secret to identify it more easily (e.g. Password of my super secret user account)
  --name: string # The name of the secret used as a reference on the value (e.g. secret-password)
  --value: string # The value of the secret it will not be exposed in the interface (e.g. nj-k;EO32!kFWewn2Nk,u)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/secret/"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    description: $description, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a secret
#
# DELETE /secret/{name}
# Returns: record<action: string, data: record<secrets: list<record>>, result: string>
# operationId: deleteSecret
export def "delete-secret" [
  name: string
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
    path: "/secret/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one secret
#
# GET /secret/{name}
# Returns: record<action: string, data: record<secrets: list<record>>, result: string>
# operationId: getSecret
export def "get-secret" [
  name: string
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
    path: "/secret/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all settings
#
# GET /settings
# Returns: record<action: string, data: record<settings: record<allowed_networks: list, change_message_prompt: string, display_recent_changes_graphs: bool, enable_change_message: bool, enable_change_request: bool, enable_javascript_directives: string, enable_self_deployment: bool, enable_self_validation: bool, first_run_hour: int, first_run_minute: int, global_policy_mode: string, global_policy_mode_overridable: bool, heartbeat_frequency: int, mandatory_change_message: bool, modified_file_ttl: int, node_accept_duplicated_hostname: bool, node_onaccept_default_policyMode: string, node_onaccept_default_state: string, output_file_ttl: int, relay_server_synchronization_method: string, relay_server_synchronize_policies: bool, relay_server_synchronize_shared_files: bool, reporting_mode: string, require_time_synchronization: bool, rudder_compute_changes: bool, rudder_compute_dyngroups_max_parallelism: string, rudder_generation_compute_dyngroups: bool, rudder_generation_continue_on_error: bool, rudder_generation_delay: string, rudder_generation_js_timeout: int, rudder_generation_max_parallelism: string, rudder_generation_policy: string, rudder_report_protocol_default: string, rudder_save_db_compliance_details: bool, rudder_save_db_compliance_levels: bool, rudder_verify_certificates: bool, run_frequency: int, send_metrics: string, splay_time: int, unexpected_unbound_var_values: bool>>, result: string>
# operationId: getAllSettings
export def "get-all-settings" [
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
    path: "/settings"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get allowed networks for a policy server
#
# GET /settings/allowed_networks/{nodeId}
# Returns: record<action: string, data: record<settings: record<allowed_networks: list>>, id: string, result: string>
# operationId: getAllowedNetworks
export def "get-allowed-networks" [
  node_id: string
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
    path: "/settings/allowed_networks/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set allowed networks for a policy server
#
# POST /settings/allowed_networks/{nodeId}
# Returns: record<action: string, data: record<allowed_networks: list<any>>, id: string, result: string>
# operationId: setAllowedNetworks
export def "set-allowed-networks" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record # New value of the allowed networks (e.g. enforce)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/settings/allowed_networks/{nodeId}"
    path_params: [{name: nodeId, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify allowed networks for a policy server
#
# POST /settings/allowed_networks/{nodeId}/diff
# Returns: record<action: string, data: record<allowed_networks: list<any>>, result: string>
# operationId: modifyAllowedNetworks
export def "modify-allowed-networks" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-networks: record # shape: {add?: list, delete?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/settings/allowed_networks/{nodeId}/diff"
    path_params: [{name: nodeId, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowed_networks, var: allowed_networks}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    node_id: $node_id, allowed_networks: $allowed_networks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the value of a setting
#
# GET /settings/{settingId}
# Returns: record<action: string, data: record<settingId: string>, id: string, result: string>
# operationId: getSetting
export def "get-setting" [
  setting_id: string
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
    path: "/settings/{settingId}"
    path_params: [{name: settingId, var: setting_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    setting_id: $setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the value of a setting
#
# POST /settings/{settingId}
# Returns: record<action: string, data: record<settingId: string>, id: string, result: string>
# operationId: modifySetting
export def "modify-setting" [
  setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # New value of the setting (e.g. enforce)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/settings/{settingId}"
    path_params: [{name: settingId, var: setting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    setting_id: $setting_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if Rudder is alive
#
# GET /status
# Returns: string
# operationId: none
export def "none" [
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
    path: "/status"
    accept: ["text/plain"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List archives
#
# GET /system/archives/{archiveKind}
# Returns: record<action: string, data: record<full: list<record>>, result: string>
# operationId: listArchives
export def "list-archives" [
  archive_kind: string@archive-kind-completer
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
    path: "/system/archives/{archiveKind}"
    path_params: [{name: archiveKind, var: archive_kind}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    archive_kind: $archive_kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an archive
#
# POST /system/archives/{archiveKind}
# Returns: record<action: string, data: record<full: record<commiter: string, gitCommit: string, id: string>>, result: string>
# operationId: createArchive
export def "create-archive" [
  archive_kind: string@archive-kind-completer
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
    method: post
    path: "/system/archives/{archiveKind}"
    path_params: [{name: archiveKind, var: archive_kind}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    archive_kind: $archive_kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore an archive
#
# POST /system/archives/{archiveKind}/restore/{archiveRestoreKind}
# Returns: record<action: string, data: record<directive: string, full: string, groups: string, parameters: string, rules: string>, result: string>
# operationId: restoreArchive
export def "restore-archive" [
  archive_kind: string@archive-kind-completer
  archive_restore_kind: string@archive-restore-kind-completer
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
    method: post
    path: "/system/archives/{archiveKind}/restore/{archiveRestoreKind}"
    path_params: [{name: archiveKind, var: archive_kind}, {name: archiveRestoreKind, var: archive_restore_kind}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    archive_kind: $archive_kind, archive_restore_kind: $archive_restore_kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an archive as a ZIP
#
# GET /system/archives/{archiveKind}/zip/{commitId}
# Returns: binary
# operationId: getZipArchive
export def "get-zip-archive" [
  archive_kind: string@archive-kind-completer
  commit_id: string
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
    path: "/system/archives/{archiveKind}/zip/{commitId}"
    path_params: [{name: archiveKind, var: archive_kind}, {name: commitId, var: commit_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: x-api-token
  } {
    archive_kind: $archive_kind, commit_id: $commit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get healthcheck
#
# GET /system/healthcheck
# Returns: record<action: string, data: table<msg: string, name: string, status: string>, result: string>
# operationId: getHealthcheckResult
export def "get-healthcheck-result" [
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
    path: "/system/healthcheck"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get server information
#
# GET /system/info
# Returns: record<action: string, data: record<rudder: record<build-time: string, full-version: string, major-version: string>>, result: string>
# operationId: getSystemInfo
export def "get-system-info" [
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
    path: "/system/info"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger batch for cleaning unreferenced software
#
# POST /system/maintenance/purgeSoftware
# Returns: record<action: string, data: list<string>, result: string>
# operationId: purgeSoftware
export def "purge-software" [
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
    method: post
    path: "/system/maintenance/purgeSoftware"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a new policy generation
#
# POST /system/regenerate/policies
# Returns: record<action: string, data: record<policies: string>, result: string>
# operationId: regeneratePolicies
export def "regenerate-policies" [
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
    method: post
    path: "/system/regenerate/policies"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload both techniques and dynamic groups
#
# POST /system/reload
# Returns: record<action: string, data: record<groups: string, techniques: string>, result: string>
# operationId: reloadAll
export def "reload-all" [
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
    method: post
    path: "/system/reload"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload dynamic groups
#
# POST /system/reload/groups
# Returns: record<action: string, data: record<groups: string>, result: string>
# operationId: reloadGroups
export def "reload-groups" [
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
    method: post
    path: "/system/reload/groups"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload techniques
#
# POST /system/reload/techniques
# Returns: record<action: string, data: record<techniques: string>, result: string>
# operationId: reloadTechniques
export def "reload-techniques" [
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
    method: post
    path: "/system/reload/techniques"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get server status
#
# GET /system/status
# Returns: record<action: string, data: record<global: string>, result: string>
# operationId: getStatus
export def "get-status" [
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
    path: "/system/status"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger update of policies
#
# POST /system/update/policies
# Returns: record<action: string, data: record<policies: string>, result: string>
# operationId: updatePolicies
export def "update-policies" [
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
    method: post
    path: "/system/update/policies"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all techniques
#
# GET /techniques
# Returns: record<action: string, data: record<techniques: list<record>>, result: string>
# operationId: listTechniques
export def "list-techniques" [
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
    path: "/techniques"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create technique
#
# PUT /techniques
# Returns: record<action: string, data: record<techniques: record<technique: record>>, result: string>
# operationId: CreateTechnique
export def "create-technique" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/techniques"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List categories
#
# GET /techniques/categories
# Returns: record<action: string, data: record<techniqueCategories: record<id: string, name: string, path: string, subcategories: list>>, result: string>
# operationId: techniqueCategories
export def "technique-categories" [
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
    path: "/techniques/categories"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload techniques
#
# POST /techniques/reload
# Returns: record<action: string, data: record<techniques: list<record>>, result: string>
# operationId: techniques
export def "techniques" [
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
    method: post
    path: "/techniques/reload"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List versions
#
# GET /techniques/versions
# Returns: record<action: string, data: record<techniques: list<record>>, result: string>
# operationId: listTechniquesVersions
export def "list-techniques-versions" [
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
    path: "/techniques/versions"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Technique metadata by ID
#
# GET /techniques/{techniqueId}
# Returns: record<action: string, data: record<techniques: list<record>>, result: string>
# operationId: getTechniqueAllVersion
export def "get-technique-all-version" [
  technique_id: string
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
    path: "/techniques/{techniqueId}"
    path_params: [{name: techniqueId, var: technique_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    technique_id: $technique_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all directives based on a technique
#
# GET /techniques/{techniqueId}/directives
# Returns: record<action: string, data: record<directives: list<record>>, result: string>
# operationId: listTechniquesDirectives
export def "list-techniques-directives" [
  technique_id: string
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
    path: "/techniques/{techniqueId}/directives"
    path_params: [{name: techniqueId, var: technique_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    technique_id: $technique_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete technique
#
# DELETE /techniques/{techniqueId}/{techniqueVersion}
# Returns: record<action: string, data: record<techniques: record<id: string, version: string>>, result: string>
# operationId: deleteTechnique
export def "delete-technique" [
  technique_id: string
  technique_version: string
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
    path: "/techniques/{techniqueId}/{techniqueVersion}"
    path_params: [{name: techniqueId, var: technique_id}, {name: techniqueVersion, var: technique_version}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    technique_id: $technique_id, technique_version: $technique_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Technique metadata by version and ID
#
# GET /techniques/{techniqueId}/{techniqueVersion}
# Returns: record<action: string, data: record<techniques: list<record>>, result: string>
# operationId: getTechniqueAllVersionId
export def "get-technique-all-version-id" [
  technique_id: string
  technique_version: string
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
    path: "/techniques/{techniqueId}/{techniqueVersion}"
    path_params: [{name: techniqueId, var: technique_id}, {name: techniqueVersion, var: technique_version}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    technique_id: $technique_id, technique_version: $technique_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update technique
#
# POST /techniques/{techniqueId}/{techniqueVersion}
# Returns: record<action: string, data: record<techniques: record<technique: record>>, result: string>
# operationId: updateTechnique
export def "update-technique" [
  technique_id: string
  technique_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/techniques/{techniqueId}/{techniqueVersion}"
    path_params: [{name: techniqueId, var: technique_id}, {name: techniqueVersion, var: technique_version}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    technique_id: $technique_id, technique_version: $technique_version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all directives based on a version of a technique
#
# GET /techniques/{techniqueId}/{techniqueVersion}/directives
# Returns: record<action: string, data: record<directives: list<record>>, result: string>
# operationId: listTechniqueVersionDirectives
export def "list-technique-version-directives" [
  technique_id: string
  technique_version: string
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
    path: "/techniques/{techniqueId}/{techniqueVersion}/directives"
    path_params: [{name: techniqueId, var: technique_id}, {name: techniqueVersion, var: technique_version}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    technique_id: $technique_id, technique_version: $technique_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Technique's resources
#
# GET /techniques/{techniqueId}/{techniqueVersion}/resources
# Returns: record<action: string, data: record<resources: list<record>>, result: string>
# operationId: getTechniquesResources
export def "get-techniques-resources" [
  technique_id: string
  technique_version: string
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
    path: "/techniques/{techniqueId}/{techniqueVersion}/resources"
    path_params: [{name: techniqueId, var: technique_id}, {name: techniqueVersion, var: technique_version}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    technique_id: $technique_id, technique_version: $technique_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Technique's revisions
#
# GET /techniques/{techniqueId}/{techniqueVersion}/revisions
# Returns: record<action: string, data: record<techniques: list<record>>, result: string>
# operationId: techniqueRevisions
export def "technique-revisions" [
  technique_id: string
  technique_version: string
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
    path: "/techniques/{techniqueId}/{techniqueVersion}/revisions"
    path_params: [{name: techniqueId, var: technique_id}, {name: techniqueVersion, var: technique_version}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    technique_id: $technique_id, technique_version: $technique_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add user
#
# POST /usermanagement
# Returns: record<action: string, data: record<addedUser: record<password: string, role: list, username: string>>, result: string>
# operationId: addUser
export def "add-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-pre-hahed: oneof<nothing, bool> # If you want to provide hashed password set this property to `true` otherwise we will hash the plain password and store the hash
  --password: string # this password will be hashed for you if the `isPreHashed` is set on false (e.g. passwdWillBeStoredHashed)
  --role: list<string> # Defined user's permissions
  --username: string # e.g. John Doe
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usermanagement"
    body: {content_type: "application/json", kind: json, fields: [{name: isPreHahed, var: is_pre_hahed}, {name: password, var: password}, {name: role, var: role}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    is_pre_hahed: $is_pre_hahed, password: $password, role: $role, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all roles
#
# GET /usermanagement/roles
# Returns: record<action: string, data: table<id: string, rights: list>, result: string>
# operationId: getRole
export def "get-role" [
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
    path: "/usermanagement/roles"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user's infos
#
# POST /usermanagement/update/{username}
# Returns: record<action: string, data: record<updatedUser: record<password: string, role: list, username: string>>, result: string>
# operationId: updateUser
export def "update-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-pre-hahed: oneof<nothing, bool> # If you want to provide hashed password set this property to `true` otherwise we will hash the plain password and store the hash
  --password: string # this password will be hashed for you if the `isPreHashed` is set on false (e.g. passwdWillBeStoredHashed)
  --role: list<string> # Defined user's permissions
  --body-username: string # e.g. John Doe (spec name: username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usermanagement/update/{username}"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: isPreHahed, var: is_pre_hahed}, {name: password, var: password}, {name: role, var: role}, {name: username, var: body_username}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    username: $username, is_pre_hahed: $is_pre_hahed, password: $password, role: $role, body_username: $body_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all users
#
# GET /usermanagement/users
# Returns: record<action: string, data: record<digest: string, users: list<record>>, result: string>
# operationId: getUserInfo
export def "get-user-info" [
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
    path: "/usermanagement/users"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload user
#
# GET /usermanagement/users/reload
# Returns: record<action: string, data: record<reload: record<status: string>>, result: string>
# operationId: reloadUserConf
export def "reload-user-conf" [
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
    path: "/usermanagement/users/reload"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an user
#
# DELETE /usermanagement/{username}
# Returns: record<action: string, data: record<deletedUser: record<username: string>>, result: string>
# operationId: deleteUser
export def "delete-user" [
  username: string
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
    path: "/usermanagement/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user
#
# GET /users
# Returns: record<action: string, data: table<isValidated: bool, userExists: bool, username: string>, result: string>
# operationId: listUsers
export def "list-users" [
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
    path: "/users"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update validated user list
#
# POST /validatedUsers
# Returns: record<action: string, data: record<isValidated: bool, userExists: bool, username: string>, result: string>
# operationId: saveWorkflowUser
export def "save-workflow-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  validated_users: list<string> # list of user to put in validated list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/validatedUsers"
    body: {content_type: "application/json", kind: json, fields: [{name: validatedUsers, var: validated_users}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    validated_users: $validated_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an user from validated user list
#
# DELETE /validatedUsers/{username}
# Returns: record<action: string, data: string, result: string>
# operationId: removeValidatedUser
export def "remove-validated-user" [
  username: string
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
    path: "/validatedUsers/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
