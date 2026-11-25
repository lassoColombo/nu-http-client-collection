# Auto-generated client for ShipEngine API v1.1.202303022103
# Source: https://api.apis.guru/v2/specs/shipengine.com/1.1.202303022103/openapi.json
# Auth: --token flag or $env.SHIPENGINE_API_TOKEN

const CLIENT = {
  base_url: "https://api.shipengine.com"
  token_env_var: "SHIPENGINE_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: api-key, in: header, header_name: API-Key, prefix: ""}
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

def base-url-completer [] { ["https://api.shipengine.com"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def status-completer [] { ["archived" "completed" "completed_with_errors" "invalid" "notifying" "open" "processing" "queued"] }
def sort-dir-completer [] { ["asc" "desc"] }
def sort-by-completer [] { ["created_at" "processed_at" "ship_date"] }
def accept-completer [] { ["application/json" "text/plain"] }
def display-scheme-completer [] { ["label" "label_and_qr_code" "qr_code"] }
def label-format-completer [] { ["pdf" "png" "zpl"] }
def label-layout-completer [] { ["4x6" "letter"] }
def carrier-name-completer [] { ["access_worldwide" "amazon_buy_shipping" "amazon_shipping_uk" "apc" "asendia" "australia_post" "canada_post" "dhl_ecommerce" "dhl_express" "dhl_express_au" "dhl_express_ca" "dhl_express_uk" "dpd" "endicia" "fedex" "fedex_uk" "firstmile" "imex" "newgistics" "ontrac" "purolator_canada" "royal_mail" "rr_donnelley" "seko" "sendle" "stamps_com" "ups"] }
def ancillary-endorsement-completer [] { ["address_service_requested" "change_service_requested" "forwarding_service_requested" "leave_if_no_response" "none" "return_service_requested"] }
def carrier-name-completer-1 [] { ["dhl_express" "fedex" "newgistics" "ups"] }
def pickup-type-completer [] { ["business_service_center" "drop_box" "none" "regular_pickup" "request_courier" "station"] }
def smart-post-endorsement-completer [] { ["address_service_requested" "change_service_requested" "forwarding_service_requested" "leave_if_no_response" "none" "return_service_requested"] }
def smart-post-hub-completer [] { ["allentown_pa" "atlanta_ga" "baltimore_md" "charlotte_nc" "chino_ca" "dallas_tx" "denver_co" "detroit_mi" "edison_nj" "grove_city_oh" "groveport_oh" "houston_tx" "indianapolis_in" "kansas_city_ks" "los_angeles_ca" "martinsburg_wv" "memphis_tn" "minneapolis_mn" "new_berlin_wi" "newark_ny" "none" "northborough_ma" "orlando_fl" "phoneix_az" "pittsburgh_pa" "reno_nv" "sacramento_ca" "salt_lake_city_ut" "scranton_pa" "seattle_wa" "south_brunswick_nj" "st_louis_mo" "wheeling_il" "windsor_ct"] }
def mail-innovations-endorsement-completer [] { ["address_service_requested" "change_service_requested" "forwarding_service_requested" "leave_if_no_response" "none" "return_service_requested"] }
def accept-completer-1 [] { ["application/pdf" "application/zpl" "image/png"] }
def event-completer [] { ["batch" "carrier_connected" "order_source_refresh_complete" "rate" "report_complete" "sales_orders_imported" "track"] }
def label-status-completer [] { ["completed" "error" "processing" "voided"] }
def sort-by-completer-1 [] { ["created_at" "modified_at"] }
def charge-event-completer [] { ["carrier_default" "on_carrier_acceptance" "on_creation"] }
def label-download-type-completer [] { ["inline" "url"] }
def validate-address-completer [] { ["no_validation" "validate_and_clean" "validate_only"] }
def address-residential-indicator-completer [] { ["no" "unknown" "yes"] }
def confirmation-completer [] { ["adult_signature" "delivery" "delivery_mailed" "direct_signature" "none" "signature" "verbal_confirmation"] }
def shipment-status-completer [] { ["cancelled" "label_purchased" "pending" "processing"] }
def insurance-provider-completer [] { ["carrier" "none" "shipsurance" "third_party"] }
def order-source-code-completer [] { ["amazon_ca" "amazon_us" "brightpearl" "channel_advisor" "cratejoy" "ebay" "etsy" "groupon_goods" "jane" "magento" "paypal" "seller_active" "shopify" "squarespace" "stitch_labs" "three_dcart" "tophatter" "volusion" "walmart" "woo_commerce"] }
def origin-type-completer [] { ["drop_off" "pickup"] }
def redirect-completer [] { ["shipengine-dashboard"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    parse-address: "record<address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, entities: table<end_index: int, result: record, score: float, start_index: int, text: string, type: string>, score: float>"
    validate-address: "table<matched_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, messages: list<record>, original_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, status: string>"
    list-batches: "record<batches: table<batch_errors_url: record, batch_id: string, batch_labels_url: record, batch_notes: string, batch_number: string, batch_shipments_url: record, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record, forms: int, label_download: record, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, total: int>"
    create-batch: "record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>"
    get-batch-by-external-id: "record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>"
    delete-batch: "string"
    get-batch-by-id: "record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>"
    update-batch: "string"
    add-to-batch: "string"
    list-batch-errors: "record<errors: table<error: string, external_shipment_id: string, shipment_id: string>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>>"
    process-batch: "string"
    remove-from-batch: "string"
    list-carriers: "record<carriers: table<account_number: string, balance: float, carrier_code: string, carrier_id: string, friendly_name: string, has_multi_package_supporting_services: bool, nickname: string, options: list, packages: list, primary: bool, requires_funded_amount: bool, services: list, supports_label_messages: bool>, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>"
    get-carrier-by-id: "record<account_number: string, balance: float, carrier_code: string, carrier_id: string, friendly_name: string, has_multi_package_supporting_services: bool, nickname: string, options: table<default_value: string, description: string, name: string>, packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>, primary: bool, requires_funded_amount: bool, services: table<carrier_code: string, carrier_id: string, domestic: bool, international: bool, is_multi_package_supported: bool, name: string, service_code: string>, supports_label_messages: bool>"
    add-funds-to-carrier: "record<balance: record<amount: float, currency: string>>"
    get-carrier-options: "record<options: table<default_value: string, description: string, name: string>>"
    list-carrier-package-types: "record<packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>>"
    list-carrier-services: "record<services: table<carrier_code: string, carrier_id: string, domestic: bool, international: bool, is_multi_package_supported: bool, name: string, service_code: string>>"
    connect-carrier: "record<carrier_id: string>"
    disconnect-carrier: "string"
    update-carrier-settings: "string"
    disconnect-insurer: "record"
    connect-insurer: "record"
    download-file: "binary"
    list-webhooks: "table<event: string, url: string, webhook_id: string>"
    create-webhook: "record<event: string, url: string, webhook_id: string>"
    delete-webhook: "string"
    get-webhook-by-id: "record<event: string, url: string, webhook_id: string>"
    update-webhook: "string"
    add-funds-to-insurance: "record<amount: float, currency: string>"
    get-insurance-balance: "record<amount: float, currency: string>"
    list-labels: "record<labels: table<alternative_identifiers: list, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record, insurance_claim: record, insurance_cost: record, is_international: bool, is_return_label: bool, label_download: record, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: list, rma_number: string, service_code: string, ship_date: string, shipment: record, shipment_cost: record, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, total: int>"
    create-label: "record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>"
    get-label-by-external-shipment-id: "record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>"
    create-label-from-rate: "record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>"
    create-label-from-shipment: "record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>"
    get-label-by-id: "record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>"
    create-return-label: "record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>"
    get-tracking-log-from-label: "record<actual_delivery_date: string, carrier_code: string, carrier_detail_code: string, carrier_id: string, carrier_status_code: string, carrier_status_description: string, estimated_delivery_date: string, events: table<carrier_detail_code: string, carrier_occurred_at: string, carrier_status_code: string, carrier_status_description: string, city_locality: string, company_name: string, country_code: string, description: string, event_code: string, latitude: float, longitude: float, occurred_at: string, postal_code: string, signer: string, state_province: string, status_code: string, status_description: string>, exception_description: string, ship_date: string, status_code: string, status_description: string, tracking_number: string, tracking_url: string>"
    void-label: "record<approved: bool, message: string>"
    list-manifests: "record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, page: int, pages: int, total: int>"
    create-manifest: "record<manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, manifest_requests: table<manifest_request_id: string, status: string>, carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>"
    get-manifest-request-by-id: "record<manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, manifest_requests: table<manifest_request_id: string, status: string>, carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>"
    get-manifest-by-id: "record<carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>"
    list-package-types: "record<packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>>"
    create-package-type: "record<description: string, dimensions: record<height: float, length: float, unit: string, width: float>, name: string, package_code: string, package_id: string>"
    delete-package-type: "string"
    get-package-type-by-id: "record<description: string, dimensions: record<height: float, length: float, unit: string, width: float>, name: string, package_code: string, package_id: string>"
    update-package-type: "string"
    list-scheduled-pickups: "record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, pickups: table<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record, created_at: string, label_ids: list, pickup_address: record, pickup_id: string, pickup_notes: string, pickup_window: record, pickup_windows: list, warehouse_id: string>, total: int, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>"
    schedule-pickup: "record<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record<email: string, name: string, phone: string>, created_at: string, label_ids: list<string>, pickup_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, pickup_id: string, pickup_notes: string, pickup_window: record<end_at: string, start_at: string>, pickup_windows: table<end_at: string, start_at: string>, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>"
    delete-scheduled-pickup: "record<errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string, pickup_id: string>"
    get-pickup-by-id: "record<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record<email: string, name: string, phone: string>, created_at: string, label_ids: list<string>, pickup_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, pickup_id: string, pickup_notes: string, pickup_window: record<end_at: string, start_at: string>, pickup_windows: table<end_at: string, start_at: string>, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>"
    calculate-rates: "record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string, rate_response: record<created_at: string, errors: list<record>, invalid_rates: list<record>, rate_request_id: string, rates: list<record>, shipment_id: string, status: string>>"
    compare-bulk-rates: "table<created_at: string, errors: list<record>, rate_request_id: string, shipment_id: string, status: string>"
    estimate-rates: "table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record<amount: float, currency: string>, delivery_days: int, error_messages: list<string>, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record<amount: float, currency: string>, negotiated_rate: bool, other_amount: record<amount: float, currency: string>, package_type: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record<amount: float, currency: string>, tax_amount: record<amount: float, currency: string>, trackable: bool, validation_status: string, warning_messages: list<string>, zone: int>"
    get-rate-by-id: "record<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record<amount: float, currency: string>, delivery_days: int, error_messages: list<string>, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record<amount: float, currency: string>, negotiated_rate: bool, other_amount: record<amount: float, currency: string>, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record<amount: float, currency: string>, tax_amount: record<amount: float, currency: string>, trackable: bool, validation_status: string, warning_messages: list<string>, zone: int>"
    service-points-list: "record<errors: table<error_code: string, error_source: string, error_type: string, message: string>, lat: float, long: float, service_points: table<address_line1: string, carrier_code: string, city_locality: string, company_name: string, country_code: string, distance_in_meters: float, features: list, hours_of_operation: record, lat: float, long: float, phone_number: string, postal_code: string, service_codes: list, service_point_id: string, state_province: string>>"
    service-points-get-by-id: "record<service_point: record<address_line1: string, carrier_code: string, city_locality: string, company_name: string, country_code: string, features: list<string>, hours_of_operation: record<friday: list, monday: list, saturday: list, sunday: list, thursday: list, tuesday: list, wednesday: list>, lat: float, long: float, phone_number: string, postal_code: string, service_codes: list<string>, service_point_id: string, state_province: string>>"
    list-shipments: "record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, shipments: table<advanced_options: record, carrier_id: string, confirmation: string, created_at: string, customs: record, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list, modified_at: string, order_source_code: string, origin_type: string, packages: list, return_to: record, service_code: string, ship_date: string, ship_from: record, ship_to: record, shipment_id: string, shipment_number: string, shipment_status: string, tags: list, tax_identifiers: list, total_weight: record, warehouse_id: string>, total: int>"
    create-shipments: "record<has_errors: bool, shipments: table<advanced_options: record, carrier_id: string, confirmation: string, created_at: string, customs: record, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list, modified_at: string, order_source_code: string, origin_type: string, packages: list, return_to: record, service_code: string, ship_date: string, ship_from: record, ship_to: record, shipment_id: string, shipment_number: string, shipment_status: string, tags: list, tax_identifiers: list, total_weight: record, warehouse_id: string, address_validation: record, errors: list>>"
    get-shipment-by-external-id: "record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string>"
    parse-shipment: "record<entities: table<end_index: int, result: record, score: float, start_index: int, text: string, type: string>, score: float, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>>"
    get-shipment-by-id: "record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string>"
    update-shipment: "record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string, address_validation: record<matched_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, messages: list<record>, original_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, status: string>, errors: list<string>>"
    cancel-shipments: "string"
    list-shipment-rates: "record<created_at: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, invalid_rates: table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record, delivery_days: int, error_messages: list, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record, negotiated_rate: bool, other_amount: record, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record, tax_amount: record, trackable: bool, validation_status: string, warning_messages: list, zone: int>, rate_request_id: string, rates: table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record, delivery_days: int, error_messages: list, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record, negotiated_rate: bool, other_amount: record, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record, tax_amount: record, trackable: bool, validation_status: string, warning_messages: list, zone: int>, shipment_id: string, status: string>"
    untag-shipment: "string"
    tag-shipment: "record<shipment_id: string, tag: record<name: string>>"
    list-tags: "record<tags: table<name: string>>"
    delete-tag: "string"
    create-tag: "record<name: string>"
    rename-tag: "string"
    tokens-get-ephemeral-token: "record<redirect_url: string, token: string>"
    get-tracking-log: "record<actual_delivery_date: string, carrier_code: string, carrier_detail_code: string, carrier_id: string, carrier_status_code: string, carrier_status_description: string, estimated_delivery_date: string, events: table<carrier_detail_code: string, carrier_occurred_at: string, carrier_status_code: string, carrier_status_description: string, city_locality: string, company_name: string, country_code: string, description: string, event_code: string, latitude: float, longitude: float, occurred_at: string, postal_code: string, signer: string, state_province: string, status_code: string, status_description: string>, exception_description: string, ship_date: string, status_code: string, status_description: string, tracking_number: string, tracking_url: string>"
    start-tracking: "string"
    stop-tracking: "string"
    list-warehouses: "record<warehouses: table<created_at: string, is_default: bool, name: string, origin_address: record, return_address: record, warehouse_id: string>>"
    create-warehouse: "record<created_at: string, is_default: bool, name: string, origin_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, return_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, warehouse_id: string>"
    delete-warehouse: "string"
    get-warehouse-by-id: "record<created_at: string, is_default: bool, name: string, origin_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, return_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, warehouse_id: string>"
    update-warehouse: "string"
    update-warehouse-settings: "string"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["parse-address" "validate-address" "list-batches" "create-batch" "get-batch-by-external-id" "delete-batch" "get-batch-by-id" "update-batch" "add-to-batch" "list-batch-errors" "process-batch" "remove-from-batch" "list-carriers" "get-carrier-by-id" "add-funds-to-carrier" "get-carrier-options" "list-carrier-package-types" "list-carrier-services" "connect-carrier" "disconnect-carrier" "get-carrier-settings" "update-carrier-settings" "disconnect-insurer" "connect-insurer" "download-file" "list-webhooks" "create-webhook" "delete-webhook" "get-webhook-by-id" "update-webhook" "add-funds-to-insurance" "get-insurance-balance" "list-labels" "create-label" "get-label-by-external-shipment-id" "create-label-from-rate" "create-label-from-shipment" "get-label-by-id" "create-return-label" "get-tracking-log-from-label" "void-label" "list-manifests" "create-manifest" "get-manifest-request-by-id" "get-manifest-by-id" "list-package-types" "create-package-type" "delete-package-type" "get-package-type-by-id" "update-package-type" "list-scheduled-pickups" "schedule-pickup" "delete-scheduled-pickup" "get-pickup-by-id" "calculate-rates" "compare-bulk-rates" "estimate-rates" "get-rate-by-id" "service-points-list" "service-points-get-by-id" "list-shipments" "create-shipments" "get-shipment-by-external-id" "parse-shipment" "get-shipment-by-id" "update-shipment" "cancel-shipments" "list-shipment-rates" "untag-shipment" "tag-shipment" "list-tags" "delete-tag" "create-tag" "rename-tag" "tokens-get-ephemeral-token" "get-tracking-log" "start-tracking" "stop-tracking" "list-warehouses" "create-warehouse" "delete-warehouse" "get-warehouse-by-id" "update-warehouse" "update-warehouse-settings" "commands"] | sort) } | get name | first)
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

# Parse an address
#
# PUT /v1/addresses/recognize
# Returns: record<address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, entities: table<end_index: int, result: record, score: float, start_index: int, text: string, type: string>, score: float>
# operationId: parse_address
export def "parse-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # You can optionally provide any already-known address values. For example, you may already know the recipient's name, city, and country, and only want to parse the street address into separate lines. — shape: {address_line1?: string, address_line2?: string, address_line3?: string, address_residential_indicator?: "unknown"|"yes"|"no", city_locality?: string, company_name?: string, country_code?: string, email?: string, name?: string, phone?: string, postal_code?: string, state_province?: string}
  text: string # The unstructured text that contains address-related entities (e.g. Margie McMiller at 3800 North Lamar suite 200 in austin, tx.  The zip code there is 78652.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/addresses/recognize"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    address: $address, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate An Address
#
# POST /v1/addresses/validate
# Returns: table<matched_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, messages: list<record>, original_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, status: string>
# operationId: validate_address
export def "validate-address" [
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
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/addresses/validate"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Batches
#
# GET /v1/batches
# Returns: record<batches: table<batch_errors_url: record, batch_id: string, batch_labels_url: record, batch_notes: string, batch_number: string, batch_shipments_url: record, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record, forms: int, label_download: record, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, total: int>
# operationId: list_batches
export def "list-batches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sort-dir: string@sort-dir-completer # Controls the sort order of the query. (default: desc)
  --batch-number: string # Batch Number
  --sort-by: string@sort-by-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/batches"
    query: [{name: status, var: status}, {name: page, var: page}, {name: page_size, var: page_size}, {name: sort_dir, var: sort_dir}, {name: batch_number, var: batch_number}, {name: sort_by, var: sort_by}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    status: $status, page: $page, page_size: $page_size, sort_dir: $sort_dir, batch_number: $batch_number, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create A Batch
#
# POST /v1/batches
# Returns: record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>
# operationId: create_batch
export def "create-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --batch-notes: string # Add custom messages for a particular batch (e.g. This is my batch)
  --external-batch-id: string # A string that uniquely identifies the external batch
  --rate-ids: list<string> # Array of rate IDs used in the batch
  --shipment-ids: list<string> # Array of shipment IDs used in the batch
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/batches"
    body: {content_type: "application/json", kind: json, fields: [{name: batch_notes, var: batch_notes}, {name: external_batch_id, var: external_batch_id}, {name: rate_ids, var: rate_ids}, {name: shipment_ids, var: shipment_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    batch_notes: $batch_notes, external_batch_id: $external_batch_id, rate_ids: $rate_ids, shipment_ids: $shipment_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Batch By External ID
#
# GET /v1/batches/external_batch_id/{external_batch_id}
# Returns: record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>
# operationId: get_batch_by_external_id
export def "get-batch-by-external-id" [
  external_batch_id: string
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
    path: "/v1/batches/external_batch_id/{external_batch_id}"
    path_params: [{name: external_batch_id, var: external_batch_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    external_batch_id: $external_batch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Batch By Id
#
# DELETE /v1/batches/{batch_id}
# Returns: string
# operationId: delete_batch
export def "delete-batch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/batches/{batch_id}"
    path_params: [{name: batch_id, var: batch_id}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    batch_id: $batch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Batch By ID
#
# GET /v1/batches/{batch_id}
# Returns: record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>
# operationId: get_batch_by_id
export def "get-batch-by-id" [
  batch_id: string
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
    path: "/v1/batches/{batch_id}"
    path_params: [{name: batch_id, var: batch_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    batch_id: $batch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Batch By Id
#
# PUT /v1/batches/{batch_id}
# Returns: string
# operationId: update_batch
export def "update-batch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: put
    path: "/v1/batches/{batch_id}"
    path_params: [{name: batch_id, var: batch_id}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    batch_id: $batch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add to a Batch
#
# POST /v1/batches/{batch_id}/add
# Returns: string
# operationId: add_to_batch
export def "add-to-batch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --rate-ids: list<string> # Array of Rate IDs to be modifed on the batch
  --shipment-ids: list<string> # The Shipment Ids to be modified on the batch
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/batches/{batch_id}/add"
    path_params: [{name: batch_id, var: batch_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rate_ids, var: rate_ids}, {name: shipment_ids, var: shipment_ids}]}
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    batch_id: $batch_id, rate_ids: $rate_ids, shipment_ids: $shipment_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Batch Errors
#
# GET /v1/batches/{batch_id}/errors
# Returns: record<errors: table<error: string, external_shipment_id: string, shipment_id: string>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>>
# operationId: list_batch_errors
export def "list-batch-errors" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --pagesize: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/batches/{batch_id}/errors"
    path_params: [{name: batch_id, var: batch_id}]
    query: [{name: page, var: page}, {name: pagesize, var: pagesize}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    batch_id: $batch_id, page: $page, pagesize: $pagesize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Process Batch ID Labels
#
# POST /v1/batches/{batch_id}/process/labels
# Returns: string
# operationId: process_batch
export def "process-batch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --label-format: string@label-format-completer # The possible file formats in which shipping labels can be downloaded. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. |Label Format | Supported Carriers |--------------|----------------------------------- |`pdf` | All carriers |`png` | `fedex` `stamps_com` `ups` `usps` |`zpl` | `access_worldwide` `apc` `asendia` `dhl_global_mail` `dhl_express` `dhl_express_australia` `dhl_express_canada` `dhl_express_worldwide` `dhl_express_uk` `dpd` `endicia` `fedex` `fedex_uk` `firstmile` `imex` `newgistics` `ontrac` `rr_donnelley` `stamps_com` `ups` `usps` (default: pdf)
  --label-layout: string@label-layout-completer # The available layouts (sizes) in which shipping labels can be downloaded. The label format determines which sizes are supported. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --ship-date: string # The Ship date the batch is being processed for (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/batches/{batch_id}/process/labels"
    path_params: [{name: batch_id, var: batch_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_scheme, var: display_scheme}, {name: label_format, var: label_format}, {name: label_layout, var: label_layout}, {name: ship_date, var: ship_date}]}
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    batch_id: $batch_id, display_scheme: $display_scheme, label_format: $label_format, label_layout: $label_layout, ship_date: $ship_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove From Batch
#
# POST /v1/batches/{batch_id}/remove
# Returns: string
# operationId: remove_from_batch
export def "remove-from-batch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --rate-ids: list<string> # Array of Rate IDs to be modifed on the batch
  --shipment-ids: list<string> # The Shipment Ids to be modified on the batch
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/batches/{batch_id}/remove"
    path_params: [{name: batch_id, var: batch_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rate_ids, var: rate_ids}, {name: shipment_ids, var: shipment_ids}]}
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    batch_id: $batch_id, rate_ids: $rate_ids, shipment_ids: $shipment_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Carriers
#
# GET /v1/carriers
# Returns: record<carriers: table<account_number: string, balance: float, carrier_code: string, carrier_id: string, friendly_name: string, has_multi_package_supporting_services: bool, nickname: string, options: list, packages: list, primary: bool, requires_funded_amount: bool, services: list, supports_label_messages: bool>, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>
# operationId: list_carriers
export def "list-carriers" [
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
    path: "/v1/carriers"
    accept: ["application/json"]
    ok: [200, 207]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Carrier By ID
#
# GET /v1/carriers/{carrier_id}
# Returns: record<account_number: string, balance: float, carrier_code: string, carrier_id: string, friendly_name: string, has_multi_package_supporting_services: bool, nickname: string, options: table<default_value: string, description: string, name: string>, packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>, primary: bool, requires_funded_amount: bool, services: table<carrier_code: string, carrier_id: string, domestic: bool, international: bool, is_multi_package_supported: bool, name: string, service_code: string>, supports_label_messages: bool>
# operationId: get_carrier_by_id
export def "get-carrier-by-id" [
  carrier_id: string
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
    path: "/v1/carriers/{carrier_id}"
    path_params: [{name: carrier_id, var: carrier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_id: $carrier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Funds To Carrier
#
# PUT /v1/carriers/{carrier_id}/add_funds
# Returns: record<balance: record<amount: float, currency: string>>
# operationId: add_funds_to_carrier
export def "add-funds-to-carrier" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The monetary amount, in the specified currency. (format: double)
  currency: string # The currencies that are supported by ShipEngine are the ones that specified by ISO 4217: https://www.iso.org/iso-4217-currency-codes.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/carriers/{carrier_id}/add_funds"
    path_params: [{name: carrier_id, var: carrier_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: currency, var: currency}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_id: $carrier_id, amount: $amount, currency: $currency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Carrier Options
#
# GET /v1/carriers/{carrier_id}/options
# Returns: record<options: table<default_value: string, description: string, name: string>>
# operationId: get_carrier_options
export def "get-carrier-options" [
  carrier_id: string
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
    path: "/v1/carriers/{carrier_id}/options"
    path_params: [{name: carrier_id, var: carrier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_id: $carrier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Carrier Package Types
#
# GET /v1/carriers/{carrier_id}/packages
# Returns: record<packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>>
# operationId: list_carrier_package_types
export def "list-carrier-package-types" [
  carrier_id: string
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
    path: "/v1/carriers/{carrier_id}/packages"
    path_params: [{name: carrier_id, var: carrier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_id: $carrier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Carrier Services
#
# GET /v1/carriers/{carrier_id}/services
# Returns: record<services: table<carrier_code: string, carrier_id: string, domestic: bool, international: bool, is_multi_package_supported: bool, name: string, service_code: string>>
# operationId: list_carrier_services
export def "list-carrier-services" [
  carrier_id: string
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
    path: "/v1/carriers/{carrier_id}/services"
    path_params: [{name: carrier_id, var: carrier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_id: $carrier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Connect a carrier account
#
# POST /v1/connections/carriers/{carrier_name}
# Returns: record<carrier_id: string>
# operationId: connect_carrier
export def "connect-carrier" [
  carrier_name: string@carrier-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  nickname: string # The nickname associated with the carrier connection (e.g. Stamps.com)
  --password: string # Access Worldwide Password
  --username: string # Access Worldwide Username
  --email: string # An email address. (format: email)
  --merchant-seller-id: string
  --mws-auth-token: string
  --auth-code: string # Amazon UK Shipping auth code.
  --account-number: string # Asendia account number
  --ftp-password: string # FTP password
  --ftp-username: string # FTP username
  --api-key: string # API key
  --api-secret: string # API secret
  --contract-id: string # Canada Post Account Contract ID
  --ancillary-endorsement: string@ancillary-endorsement-completer # [Ancillary service endorsements](https://pe.usps.com/text/qsg300/Q507.htm) are used by mailers to request an addressee's new address and to provide the carrier with instructions on how to handle packages that are undeliverable as addressed. | Ancillary Service Endorsement | Description |--------------------------------|----------------------------------------------------- | `none` | No ancillary service is requested. Depending on the carrier servive, the package may be forwarded, returned, or discarded. | `return_service_requested` | The package is returned to the sender. If possible, notification of the new address is is included with the returned package. | `forwarding_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. | `address_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. This is similar to `forwarding_service_requested`, but different restrictions and charges may apply. | `change_service_requested` | The package is discarded. If possible, notification of the new address is sent to the sender. | `leave_if_no_response` |
  --client-id: string # The client id
  --distribution-center: string # The distribution center
  --pickup-number: string # The pickup number
  --registration-id: string
  --software-name: string
  --sold-to: string # Sold To field
  --country-code: string # A two-letter [ISO 3166-1 country code](https://en.wikipedia.org/wiki/ISO_3166-1)
  --site-id: string # Required if password is provided
  --account: string # Account
  --passphrase: string # Passphrase
  --address1: string # Address
  --address2: string # Address
  --agree-to-eula: oneof<nothing, bool> # Boolean signaling agreement to the Fedex End User License Agreement
  --city: string # The city
  --company: string # The company
  --first-name: string # First name
  --last-name: string # Last name
  --meter-number: string # Meter number
  --phone: string # Phone number
  --postal-code: string # Postal Code
  --state: string # State
  --mailer-id: string # A string that uniquely identifies the mailer
  --profile-name: string # Profile name
  --induction-site: string # Induction site
  --merchant-id: int # Merchant id (format: int32)
  --activation-key: string # Activation key
  --company-name: string # Company name
  --contact-name: string # Contact name
  --oba-email: string # The oba email address (format: email)
  --street-line1: string # Street line1
  --street-line2: string # Street line2
  --street-line3: string # Street line3
  --access-key: string # Seko Account Access Key
  --sendle-id: string # A string that uniquely identifies the sendle
  --account-country-code: string # Account country code
  --account-postal-code: string # Account postal code
  --agree-to-technology-agreement: oneof<nothing, bool> # The Agreement to the [UPS Technology Agreement](https://www.ups.com/assets/resources/media/UTA_with_EUR.pdf)
  --invoice: record # The UPS invoice — shape: {control_id?: string, invoice_amount?: float, invoice_currency_code?: string, invoice_date?: string, invoice_number?: string}
  --invoice-amount: float # The invoice amount (format: double)
  --invoice-currency-code: string # The invoice currency code
  --title: string # Title
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/carriers/{carrier_name}"
    path_params: [{name: carrier_name, var: carrier_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: nickname, var: nickname}, {name: password, var: password}, {name: username, var: username}, {name: email, var: email}, {name: merchant_seller_id, var: merchant_seller_id}, {name: mws_auth_token, var: mws_auth_token}, {name: auth_code, var: auth_code}, {name: account_number, var: account_number}, {name: ftp_password, var: ftp_password}, {name: ftp_username, var: ftp_username}, {name: api_key, var: api_key}, {name: api_secret, var: api_secret}, {name: contract_id, var: contract_id}, {name: ancillary_endorsement, var: ancillary_endorsement}, {name: client_id, var: client_id}, {name: distribution_center, var: distribution_center}, {name: pickup_number, var: pickup_number}, {name: registration_id, var: registration_id}, {name: software_name, var: software_name}, {name: sold_to, var: sold_to}, {name: country_code, var: country_code}, {name: site_id, var: site_id}, {name: account, var: account}, {name: passphrase, var: passphrase}, {name: address1, var: address1}, {name: address2, var: address2}, {name: agree_to_eula, var: agree_to_eula}, {name: city, var: city}, {name: company, var: company}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: meter_number, var: meter_number}, {name: phone, var: phone}, {name: postal_code, var: postal_code}, {name: state, var: state}, {name: mailer_id, var: mailer_id}, {name: profile_name, var: profile_name}, {name: induction_site, var: induction_site}, {name: merchant_id, var: merchant_id}, {name: activation_key, var: activation_key}, {name: company_name, var: company_name}, {name: contact_name, var: contact_name}, {name: oba_email, var: oba_email}, {name: street_line1, var: street_line1}, {name: street_line2, var: street_line2}, {name: street_line3, var: street_line3}, {name: access_key, var: access_key}, {name: sendle_id, var: sendle_id}, {name: account_country_code, var: account_country_code}, {name: account_postal_code, var: account_postal_code}, {name: agree_to_technology_agreement, var: agree_to_technology_agreement}, {name: invoice, var: invoice}, {name: invoice_amount, var: invoice_amount}, {name: invoice_currency_code, var: invoice_currency_code}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_name: $carrier_name, nickname: $nickname, password: $password, username: $username, email: $email, merchant_seller_id: $merchant_seller_id, mws_auth_token: $mws_auth_token, auth_code: $auth_code, account_number: $account_number, ftp_password: $ftp_password, ftp_username: $ftp_username, api_key: $api_key, api_secret: $api_secret, contract_id: $contract_id, ancillary_endorsement: $ancillary_endorsement, client_id: $client_id, distribution_center: $distribution_center, pickup_number: $pickup_number, registration_id: $registration_id, software_name: $software_name, sold_to: $sold_to, country_code: $country_code, site_id: $site_id, account: $account, passphrase: $passphrase, address1: $address1, address2: $address2, agree_to_eula: $agree_to_eula, city: $city, company: $company, first_name: $first_name, last_name: $last_name, meter_number: $meter_number, phone: $phone, postal_code: $postal_code, state: $state, mailer_id: $mailer_id, profile_name: $profile_name, induction_site: $induction_site, merchant_id: $merchant_id, activation_key: $activation_key, company_name: $company_name, contact_name: $contact_name, oba_email: $oba_email, street_line1: $street_line1, street_line2: $street_line2, street_line3: $street_line3, access_key: $access_key, sendle_id: $sendle_id, account_country_code: $account_country_code, account_postal_code: $account_postal_code, agree_to_technology_agreement: $agree_to_technology_agreement, invoice: $invoice, invoice_amount: $invoice_amount, invoice_currency_code: $invoice_currency_code, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disconnect a carrier
#
# DELETE /v1/connections/carriers/{carrier_name}/{carrier_id}
# Returns: string
# operationId: disconnect_carrier
export def "disconnect-carrier" [
  carrier_name: string@carrier-name-completer
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/connections/carriers/{carrier_name}/{carrier_id}"
    path_params: [{name: carrier_name, var: carrier_name}, {name: carrier_id, var: carrier_id}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    carrier_name: $carrier_name, carrier_id: $carrier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get carrier settings
#
# GET /v1/connections/carriers/{carrier_name}/{carrier_id}/settings
# operationId: get_carrier_settings
export def "get-carrier-settings" [
  carrier_name: string@carrier-name-completer-1
  carrier_id: string
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
    path: "/v1/connections/carriers/{carrier_name}/{carrier_id}/settings"
    path_params: [{name: carrier_name, var: carrier_name}, {name: carrier_id, var: carrier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_name: $carrier_name, carrier_id: $carrier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update carrier settings
#
# PUT /v1/connections/carriers/{carrier_name}/{carrier_id}/settings
# Returns: string
# operationId: update_carrier_settings
export def "update-carrier-settings" [
  carrier_name: string@carrier-name-completer-1
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-primary-account: oneof<nothing, bool> # Indicates if this is primary account
  --nickname: string # Account nickname
  --should-hide-account-number-on-archive-doc: oneof<nothing, bool> # Indicates if the account number should be hidden on the archive documentation
  --letterhead-image: string
  --pickup-type: string@pickup-type-completer # Determines how FedEx will pickup your packages |Pickup Type |Description |--------------------------|----------------------------------------- |`none` | Not specified |`regular_pickup` | You already have a daily pickup scheduled with FedEx |`request_courier` | You will call FedEx to request a courier |`drop_box` | You will drop-off packages in a FedEx drop box |`business_service_center` | You will drop-off packages at an authorized FedEx business service center |`station` | You will drop-off the package at a FedEx Station
  --signature-image: string
  --smart-post-endorsement: string@smart-post-endorsement-completer # [Ancillary service endorsements](https://pe.usps.com/text/qsg300/Q507.htm) are used by mailers to request an addressee's new address and to provide the carrier with instructions on how to handle packages that are undeliverable as addressed. | Ancillary Service Endorsement | Description |--------------------------------|----------------------------------------------------- | `none` | No ancillary service is requested. Depending on the carrier servive, the package may be forwarded, returned, or discarded. | `return_service_requested` | The package is returned to the sender. If possible, notification of the new address is is included with the returned package. | `forwarding_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. | `address_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. This is similar to `forwarding_service_requested`, but different restrictions and charges may apply. | `change_service_requested` | The package is discarded. If possible, notification of the new address is sent to the sender. | `leave_if_no_response` |
  --smart-post-hub: string@smart-post-hub-completer # The possible smart post hub values
  --include-barcode-with-order-number: oneof<nothing, bool>
  --receive-email-on-manifest-processing: oneof<nothing, bool>
  --account-postal-code: string # account postal code
  --invoice: record # The invoice — shape: {control_id?: string, invoice_amount?: float, invoice_currency_code?: string, invoice_date?: string, invoice_number?: string}
  --mail-innovations-cost-center: string # mail innovations cost center
  --mail-innovations-endorsement: string@mail-innovations-endorsement-completer # [Ancillary service endorsements](https://pe.usps.com/text/qsg300/Q507.htm) are used by mailers to request an addressee's new address and to provide the carrier with instructions on how to handle packages that are undeliverable as addressed. | Ancillary Service Endorsement | Description |--------------------------------|----------------------------------------------------- | `none` | No ancillary service is requested. Depending on the carrier servive, the package may be forwarded, returned, or discarded. | `return_service_requested` | The package is returned to the sender. If possible, notification of the new address is is included with the returned package. | `forwarding_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. | `address_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. This is similar to `forwarding_service_requested`, but different restrictions and charges may apply. | `change_service_requested` | The package is discarded. If possible, notification of the new address is sent to the sender. | `leave_if_no_response` |
  --use-carbon-neutral-shipping-program: oneof<nothing, bool> # The use carbon neutral shipping program
  --use-consolidation-services: oneof<nothing, bool> # The use consolidation services
  --use-ground-freight-pricing: oneof<nothing, bool> # The use ground freight pricing
  --use-negotiated-rates: oneof<nothing, bool> # The use negotiated rates
  --use-order-number-on-mail-innovations-labels: oneof<nothing, bool> # The use order number on mail innovations labels
  --email: string # Email
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/connections/carriers/{carrier_name}/{carrier_id}/settings"
    path_params: [{name: carrier_name, var: carrier_name}, {name: carrier_id, var: carrier_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_primary_account, var: is_primary_account}, {name: nickname, var: nickname}, {name: should_hide_account_number_on_archive_doc, var: should_hide_account_number_on_archive_doc}, {name: letterhead_image, var: letterhead_image}, {name: pickup_type, var: pickup_type}, {name: signature_image, var: signature_image}, {name: smart_post_endorsement, var: smart_post_endorsement}, {name: smart_post_hub, var: smart_post_hub}, {name: include_barcode_with_order_number, var: include_barcode_with_order_number}, {name: receive_email_on_manifest_processing, var: receive_email_on_manifest_processing}, {name: account_postal_code, var: account_postal_code}, {name: invoice, var: invoice}, {name: mail_innovations_cost_center, var: mail_innovations_cost_center}, {name: mail_innovations_endorsement, var: mail_innovations_endorsement}, {name: use_carbon_neutral_shipping_program, var: use_carbon_neutral_shipping_program}, {name: use_consolidation_services, var: use_consolidation_services}, {name: use_ground_freight_pricing, var: use_ground_freight_pricing}, {name: use_negotiated_rates, var: use_negotiated_rates}, {name: use_order_number_on_mail_innovations_labels, var: use_order_number_on_mail_innovations_labels}, {name: email, var: email}]}
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    carrier_name: $carrier_name, carrier_id: $carrier_id, is_primary_account: $is_primary_account, nickname: $nickname, should_hide_account_number_on_archive_doc: $should_hide_account_number_on_archive_doc, letterhead_image: $letterhead_image, pickup_type: $pickup_type, signature_image: $signature_image, smart_post_endorsement: $smart_post_endorsement, smart_post_hub: $smart_post_hub, include_barcode_with_order_number: $include_barcode_with_order_number, receive_email_on_manifest_processing: $receive_email_on_manifest_processing, account_postal_code: $account_postal_code, invoice: $invoice, mail_innovations_cost_center: $mail_innovations_cost_center, mail_innovations_endorsement: $mail_innovations_endorsement, use_carbon_neutral_shipping_program: $use_carbon_neutral_shipping_program, use_consolidation_services: $use_consolidation_services, use_ground_freight_pricing: $use_ground_freight_pricing, use_negotiated_rates: $use_negotiated_rates, use_order_number_on_mail_innovations_labels: $use_order_number_on_mail_innovations_labels, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Disconnect a Shipsurance Account
#
# DELETE /v1/connections/insurance/shipsurance
# Returns: record
# operationId: disconnect_insurer
export def "disconnect-insurer" [
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
    path: "/v1/connections/insurance/shipsurance"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Connect a Shipsurance Account
#
# POST /v1/connections/insurance/shipsurance
# Returns: record
# operationId: connect_insurer
export def "connect-insurer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # An email address. (format: email)
  policy_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/insurance/shipsurance"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: policy_id, var: policy_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    email: $email, policy_id: $policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download File
#
# GET /v1/downloads/{dir}/{subdir}/{filename}
# Returns: binary
# operationId: download_file
export def "download-file" [
  dir: string
  subdir: string
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --download: string
  --rotation: int # format: int32
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/downloads/{dir}/{subdir}/{filename}"
    path_params: [{name: dir, var: dir}, {name: subdir, var: subdir}, {name: filename, var: filename}]
    query: [{name: download, var: download}, {name: rotation, var: rotation}]
    accept: ["application/pdf", "application/zpl", "image/png"]
    ok: [200]
    auth: api-key
  } {
    dir: $dir, subdir: $subdir, filename: $filename, download: $download, rotation: $rotation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Webhooks
#
# GET /v1/environment/webhooks
# Returns: table<event: string, url: string, webhook_id: string>
# operationId: list_webhooks
export def "list-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/environment/webhooks"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Webhook
#
# POST /v1/environment/webhooks
# Returns: record<event: string, url: string, webhook_id: string>
# operationId: create_webhook
export def "create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: string@event-completer # The possible webook event values
  url: string # The url that the webhook sends the request to (format: url, e.g. https://[YOUR ENDPOINT ID].x.requestbin.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/environment/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    event: $event, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Webhook By ID
#
# DELETE /v1/environment/webhooks/{webhook_id}
# Returns: string
# operationId: delete_webhook
export def "delete-webhook" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/environment/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Webhook By ID
#
# GET /v1/environment/webhooks/{webhook_id}
# Returns: record<event: string, url: string, webhook_id: string>
# operationId: get_webhook_by_id
export def "get-webhook-by-id" [
  webhook_id: string
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
    path: "/v1/environment/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Webhook
#
# PUT /v1/environment/webhooks/{webhook_id}
# Returns: string
# operationId: update_webhook
export def "update-webhook" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: string # The url that the wehbook sends the request (format: url, e.g. https://[YOUR ENDPOINT ID].x.requestbin.com)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/environment/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    webhook_id: $webhook_id, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add Funds To Insurance
#
# PATCH /v1/insurance/shipsurance/add_funds
# Returns: record<amount: float, currency: string>
# operationId: add_funds_to_insurance
export def "add-funds-to-insurance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The monetary amount, in the specified currency. (format: double)
  currency: string # The currencies that are supported by ShipEngine are the ones that specified by ISO 4217: https://www.iso.org/iso-4217-currency-codes.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/insurance/shipsurance/add_funds"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: currency, var: currency}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    amount: $amount, currency: $currency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Insurance Funds Balance
#
# GET /v1/insurance/shipsurance/balance
# Returns: record<amount: float, currency: string>
# operationId: get_insurance_balance
export def "get-insurance-balance" [
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
    path: "/v1/insurance/shipsurance/balance"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List labels
#
# GET /v1/labels
# Returns: record<labels: table<alternative_identifiers: list, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record, insurance_claim: record, insurance_cost: record, is_international: bool, is_return_label: bool, label_download: record, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: list, rma_number: string, service_code: string, ship_date: string, shipment: record, shipment_cost: record, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, total: int>
# operationId: list_labels
export def "list-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-status: string@label-status-completer # Only return labels that are currently in the specified status
  --service-code: string # Only return labels for a specific [carrier service](https://www.shipengine.com/docs/shipping/use-a-carrier-service/) (e.g. usps_first_class_mail)
  --carrier-id: string # Only return labels for a specific [carrier account](https://www.shipengine.com/docs/carriers/setup/) (e.g. se-28529731)
  --tracking-number: string # Only return labels with a specific tracking number (e.g. 9405511899223197428490)
  --batch-id: string # Only return labels that were created in a specific [batch](https://www.shipengine.com/docs/labels/bulk/) (e.g. se-28529731)
  --rate-id: string # Rate ID (e.g. se-28529731)
  --shipment-id: string # Shipment ID (e.g. se-28529731)
  --warehouse-id: string # Only return labels that originate from a specific [warehouse](https://www.shipengine.com/docs/shipping/ship-from-a-warehouse/) (e.g. se-28529731)
  --created-at-start: string # Only return labels that were created on or after a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Only return labels that were created on or before a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sort-dir: string@sort-dir-completer # Controls the sort order of the query. (default: desc)
  --sort-by: string@sort-by-completer-1 # Controls which field the query is sorted by. (default: created_at)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/labels"
    query: [{name: label_status, var: label_status}, {name: service_code, var: service_code}, {name: carrier_id, var: carrier_id}, {name: tracking_number, var: tracking_number}, {name: batch_id, var: batch_id}, {name: rate_id, var: rate_id}, {name: shipment_id, var: shipment_id}, {name: warehouse_id, var: warehouse_id}, {name: created_at_start, var: created_at_start}, {name: created_at_end, var: created_at_end}, {name: page, var: page}, {name: page_size, var: page_size}, {name: sort_dir, var: sort_dir}, {name: sort_by, var: sort_by}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    label_status: $label_status, service_code: $service_code, carrier_id: $carrier_id, tracking_number: $tracking_number, batch_id: $batch_id, rate_id: $rate_id, shipment_id: $shipment_id, warehouse_id: $warehouse_id, created_at_start: $created_at_start, created_at_end: $created_at_end, page: $page, page_size: $page_size, sort_dir: $sort_dir, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase Label
#
# POST /v1/labels
# Returns: record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>
# operationId: create_label
@deprecated --flag test-label
export def "create-label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ship-from-service-point-id: string # A unique identifier for a carrier drop off point where a merchant plans to deliver packages. This will take precedence over a shipment's ship from address. (nullable, e.g. 614940)
  --ship-to-service-point-id: string # A unique identifier for a carrier service point where the shipment will be delivered by the carrier. This will take precedence over a shipment's ship to address. (nullable, e.g. 614940)
  --charge-event: string@charge-event-completer # The label charge event.
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --is-return-label: oneof<nothing, bool> # Indicates whether this is a return label. You may also want to set the `rma_number` so you know what is being returned.
  --label-download-type: string@label-download-type-completer # There are two different ways to [download a label](https://www.shipengine.com/docs/labels/downloading/): |Label Download Type | Description |--------------------|------------------------------ |`url` |You will receive a URL, which you can use to download the label in a separate request. The URL will remain valid for 90 days.This is the default if `label_download_type` is unspecified. |`inline` |You will receive the Base64-encoded label as part of the response. No need for a second request to download the label. (default: url)
  --label-format: string@label-format-completer # The file format that you want the label to be in. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. (default: pdf)
  --label-image-id: string # The label image resource that was used to create a custom label image. (nullable)
  --label-layout: string@label-layout-completer # The layout (size) that you want the label to be in. The `label_format` determines which sizes are allowed. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --outbound-label-id: string # The `label_id` of the original (outgoing) label that the return label is for. This associates the two labels together, which is required by some carriers.
  --rma-number: string # An optional Return Merchandise Authorization number. This field is useful for return labels. You can set it to any string value. (nullable)
  shipment: record # The shipment information used to generate the label — shape: {advanced_options: record, carrier_id: string, confirmation: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs: record, external_order_id?: string, external_shipment_id?: string, insurance_provider: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
  --test-label: oneof<nothing, bool> # Indicate if this label is being used only for testing purposes. If true, then no charge will be added to your account. (DEPRECATED, default: false)
  --validate-address: string@validate-address-completer # The possible validate address values (default: validate_and_clean)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/labels"
    body: {content_type: "application/json", kind: json, fields: [{name: ship_from_service_point_id, var: ship_from_service_point_id}, {name: ship_to_service_point_id, var: ship_to_service_point_id}, {name: charge_event, var: charge_event}, {name: display_scheme, var: display_scheme}, {name: is_return_label, var: is_return_label}, {name: label_download_type, var: label_download_type}, {name: label_format, var: label_format}, {name: label_image_id, var: label_image_id}, {name: label_layout, var: label_layout}, {name: outbound_label_id, var: outbound_label_id}, {name: rma_number, var: rma_number}, {name: shipment, var: shipment}, {name: test_label, var: test_label}, {name: validate_address, var: validate_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    ship_from_service_point_id: $ship_from_service_point_id, ship_to_service_point_id: $ship_to_service_point_id, charge_event: $charge_event, display_scheme: $display_scheme, is_return_label: $is_return_label, label_download_type: $label_download_type, label_format: $label_format, label_image_id: $label_image_id, label_layout: $label_layout, outbound_label_id: $outbound_label_id, rma_number: $rma_number, shipment: $shipment, test_label: $test_label, validate_address: $validate_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Label By External Shipment ID
#
# GET /v1/labels/external_shipment_id/{external_shipment_id}
# Returns: record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>
# operationId: get_label_by_external_shipment_id
export def "get-label-by-external-shipment-id" [
  external_shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-download-type: string@label-download-type-completer # e.g. url
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/labels/external_shipment_id/{external_shipment_id}"
    path_params: [{name: external_shipment_id, var: external_shipment_id}]
    query: [{name: label_download_type, var: label_download_type}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    external_shipment_id: $external_shipment_id, label_download_type: $label_download_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase Label with Rate ID
#
# POST /v1/labels/rates/{rate_id}
# Returns: record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>
# operationId: create_label_from_rate
export def "create-label-from-rate" [
  rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --label-download-type: string@label-download-type-completer # There are two different ways to [download a label](https://www.shipengine.com/docs/labels/downloading/): |Label Download Type | Description |--------------------|------------------------------ |`url` |You will receive a URL, which you can use to download the label in a separate request. The URL will remain valid for 90 days.This is the default if `label_download_type` is unspecified. |`inline` |You will receive the Base64-encoded label as part of the response. No need for a second request to download the label.
  --label-format: string@label-format-completer # The possible file formats in which shipping labels can be downloaded. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. |Label Format | Supported Carriers |--------------|----------------------------------- |`pdf` | All carriers |`png` | `fedex` `stamps_com` `ups` `usps` |`zpl` | `access_worldwide` `apc` `asendia` `dhl_global_mail` `dhl_express` `dhl_express_australia` `dhl_express_canada` `dhl_express_worldwide` `dhl_express_uk` `dpd` `endicia` `fedex` `fedex_uk` `firstmile` `imex` `newgistics` `ontrac` `rr_donnelley` `stamps_com` `ups` `usps` (default: pdf)
  --label-layout: string@label-layout-completer # The available layouts (sizes) in which shipping labels can be downloaded. The label format determines which sizes are supported. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --validate-address: string@validate-address-completer # The possible validate address values
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/labels/rates/{rate_id}"
    path_params: [{name: rate_id, var: rate_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_scheme, var: display_scheme}, {name: label_download_type, var: label_download_type}, {name: label_format, var: label_format}, {name: label_layout, var: label_layout}, {name: validate_address, var: validate_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    rate_id: $rate_id, display_scheme: $display_scheme, label_download_type: $label_download_type, label_format: $label_format, label_layout: $label_layout, validate_address: $validate_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase Label with Shipment ID
#
# POST /v1/labels/shipment/{shipment_id}
# Returns: record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>
# operationId: create_label_from_shipment
export def "create-label-from-shipment" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --label-download-type: string@label-download-type-completer # There are two different ways to [download a label](https://www.shipengine.com/docs/labels/downloading/): |Label Download Type | Description |--------------------|------------------------------ |`url` |You will receive a URL, which you can use to download the label in a separate request. The URL will remain valid for 90 days.This is the default if `label_download_type` is unspecified. |`inline` |You will receive the Base64-encoded label as part of the response. No need for a second request to download the label.
  --label-format: string@label-format-completer # The possible file formats in which shipping labels can be downloaded. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. |Label Format | Supported Carriers |--------------|----------------------------------- |`pdf` | All carriers |`png` | `fedex` `stamps_com` `ups` `usps` |`zpl` | `access_worldwide` `apc` `asendia` `dhl_global_mail` `dhl_express` `dhl_express_australia` `dhl_express_canada` `dhl_express_worldwide` `dhl_express_uk` `dpd` `endicia` `fedex` `fedex_uk` `firstmile` `imex` `newgistics` `ontrac` `rr_donnelley` `stamps_com` `ups` `usps` (default: pdf)
  --label-layout: string@label-layout-completer # The available layouts (sizes) in which shipping labels can be downloaded. The label format determines which sizes are supported. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --validate-address: string@validate-address-completer # The possible validate address values
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/labels/shipment/{shipment_id}"
    path_params: [{name: shipment_id, var: shipment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_scheme, var: display_scheme}, {name: label_download_type, var: label_download_type}, {name: label_format, var: label_format}, {name: label_layout, var: label_layout}, {name: validate_address, var: validate_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    shipment_id: $shipment_id, display_scheme: $display_scheme, label_download_type: $label_download_type, label_format: $label_format, label_layout: $label_layout, validate_address: $validate_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Label By ID
#
# GET /v1/labels/{label_id}
# Returns: record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>
# operationId: get_label_by_id
export def "get-label-by-id" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-download-type: string@label-download-type-completer # e.g. url
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/labels/{label_id}"
    path_params: [{name: label_id, var: label_id}]
    query: [{name: label_download_type, var: label_download_type}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    label_id: $label_id, label_download_type: $label_download_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a return label
#
# POST /v1/labels/{label_id}/return
# Returns: record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>
# operationId: create_return_label
export def "create-return-label" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --charge-event: string@charge-event-completer # The label charge event.
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --label-download-type: string@label-download-type-completer # There are two different ways to [download a label](https://www.shipengine.com/docs/labels/downloading/): |Label Download Type | Description |--------------------|------------------------------ |`url` |You will receive a URL, which you can use to download the label in a separate request. The URL will remain valid for 90 days.This is the default if `label_download_type` is unspecified. |`inline` |You will receive the Base64-encoded label as part of the response. No need for a second request to download the label. (default: url)
  --label-format: string@label-format-completer # The file format that you want the label to be in. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. (default: pdf)
  --label-image-id: string # The label image resource that was used to create a custom label image. (nullable)
  --label-layout: string@label-layout-completer # The layout (size) that you want the label to be in. The `label_format` determines which sizes are allowed. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/labels/{label_id}/return"
    path_params: [{name: label_id, var: label_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: charge_event, var: charge_event}, {name: display_scheme, var: display_scheme}, {name: label_download_type, var: label_download_type}, {name: label_format, var: label_format}, {name: label_image_id, var: label_image_id}, {name: label_layout, var: label_layout}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    label_id: $label_id, charge_event: $charge_event, display_scheme: $display_scheme, label_download_type: $label_download_type, label_format: $label_format, label_image_id: $label_image_id, label_layout: $label_layout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Label Tracking Information
#
# GET /v1/labels/{label_id}/track
# Returns: record<actual_delivery_date: string, carrier_code: string, carrier_detail_code: string, carrier_id: string, carrier_status_code: string, carrier_status_description: string, estimated_delivery_date: string, events: table<carrier_detail_code: string, carrier_occurred_at: string, carrier_status_code: string, carrier_status_description: string, city_locality: string, company_name: string, country_code: string, description: string, event_code: string, latitude: float, longitude: float, occurred_at: string, postal_code: string, signer: string, state_province: string, status_code: string, status_description: string>, exception_description: string, ship_date: string, status_code: string, status_description: string, tracking_number: string, tracking_url: string>
# operationId: get_tracking_log_from_label
export def "get-tracking-log-from-label" [
  label_id: string
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
    path: "/v1/labels/{label_id}/track"
    path_params: [{name: label_id, var: label_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Void a Label By ID
#
# PUT /v1/labels/{label_id}/void
# Returns: record<approved: bool, message: string>
# operationId: void_label
export def "void-label" [
  label_id: string
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
    method: put
    path: "/v1/labels/{label_id}/void"
    path_params: [{name: label_id, var: label_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Manifests
#
# GET /v1/manifests
# Returns: record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, page: int, pages: int, total: int>
# operationId: list_manifests
export def "list-manifests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouse-id: string # Warehouse ID (e.g. se-28529731)
  --ship-date-start: string # ship date start range (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --ship-date-end: string # ship date end range (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Used to create a filter for when a resource was created, (ex. A shipment that was created before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --carrier-id: string # Carrier ID (e.g. se-28529731)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --label-ids: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/manifests"
    query: [{name: warehouse_id, var: warehouse_id}, {name: ship_date_start, var: ship_date_start}, {name: ship_date_end, var: ship_date_end}, {name: created_at_start, var: created_at_start}, {name: created_at_end, var: created_at_end}, {name: carrier_id, var: carrier_id}, {name: page, var: page}, {name: page_size, var: page_size}, {name: label_ids, var: label_ids, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    warehouse_id: $warehouse_id, ship_date_start: $ship_date_start, ship_date_end: $ship_date_end, created_at_start: $created_at_start, created_at_end: $created_at_end, carrier_id: $carrier_id, page: $page, page_size: $page_size, label_ids: $label_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Manifest
#
# POST /v1/manifests
# Returns: record<manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, manifest_requests: table<manifest_request_id: string, status: string>, carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>
# operationId: create_manifest
export def "create-manifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: string # A string that uniquely identifies the carrier
  --excluded-label-ids: list<string> # The list of label ids to exclude from the manifest
  --label-ids: list<string> # The list of label ids to include for the manifest
  --ship-date: string # The ship date that the shipment will be sent out on (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --warehouse-id: string # A string that uniquely identifies the warehouse
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/manifests"
    body: {content_type: "application/json", kind: json, fields: [{name: carrier_id, var: carrier_id}, {name: excluded_label_ids, var: excluded_label_ids}, {name: label_ids, var: label_ids}, {name: ship_date, var: ship_date}, {name: warehouse_id, var: warehouse_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_id: $carrier_id, excluded_label_ids: $excluded_label_ids, label_ids: $label_ids, ship_date: $ship_date, warehouse_id: $warehouse_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Manifest Request By Id
#
# GET /v1/manifests/requests/{manifest_request_id}
# Returns: record<manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, manifest_requests: table<manifest_request_id: string, status: string>, carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>
# operationId: get_manifest_request_by_id
export def "get-manifest-request-by-id" [
  manifest_request_id: string
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
    path: "/v1/manifests/requests/{manifest_request_id}"
    path_params: [{name: manifest_request_id, var: manifest_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    manifest_request_id: $manifest_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Manifest By Id
#
# GET /v1/manifests/{manifest_id}
# Returns: record<carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>
# operationId: get_manifest_by_id
export def "get-manifest-by-id" [
  manifest_id: string
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
    path: "/v1/manifests/{manifest_id}"
    path_params: [{name: manifest_id, var: manifest_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    manifest_id: $manifest_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Custom Package Types
#
# GET /v1/packages
# Returns: record<packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>>
# operationId: list_package_types
export def "list-package-types" [
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
    path: "/v1/packages"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Custom Package Type
#
# POST /v1/packages
# Returns: record<description: string, dimensions: record<height: float, length: float, unit: string, width: float>, name: string, package_code: string, package_id: string>
# operationId: create_package_type
export def "create-package-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Provides a helpful description for the custom package. (nullable, e.g. Packaging for laptops)
  --dimensions: record # The custom dimensions for the package. — shape: {height: float, length: float, unit: "inch"|"centimeter", width: float}
  name: string # e.g. laptop_box
  package_code: string # A [package type](https://www.shipengine.com/docs/reference/list-carrier-packages/), such as `thick_envelope`, `small_flat_rate_box`, `large_package`, etc. Use the code `package` for custom or unknown package types.
  --package-id: string # A string that uniquely identifies the package.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/packages"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: dimensions, var: dimensions}, {name: name, var: name}, {name: package_code, var: package_code}, {name: package_id, var: package_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    description: $description, dimensions: $dimensions, name: $name, package_code: $package_code, package_id: $package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete A Custom Package By ID
#
# DELETE /v1/packages/{package_id}
# Returns: string
# operationId: delete_package_type
export def "delete-package-type" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/packages/{package_id}"
    path_params: [{name: package_id, var: package_id}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    package_id: $package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Custom Package Type By ID
#
# GET /v1/packages/{package_id}
# Returns: record<description: string, dimensions: record<height: float, length: float, unit: string, width: float>, name: string, package_code: string, package_id: string>
# operationId: get_package_type_by_id
export def "get-package-type-by-id" [
  package_id: string
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
    path: "/v1/packages/{package_id}"
    path_params: [{name: package_id, var: package_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    package_id: $package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Custom Package Type By ID
#
# PUT /v1/packages/{package_id}
# Returns: string
# operationId: update_package_type
export def "update-package-type" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Provides a helpful description for the custom package. (nullable, e.g. Packaging for laptops)
  --dimensions: record # The custom dimensions for the package. — shape: {height: float, length: float, unit: "inch"|"centimeter", width: float}
  name: string # e.g. laptop_box
  package_code: string # A [package type](https://www.shipengine.com/docs/reference/list-carrier-packages/), such as `thick_envelope`, `small_flat_rate_box`, `large_package`, etc. Use the code `package` for custom or unknown package types.
  --body-package-id: string # A string that uniquely identifies the package. (spec name: package_id)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/packages/{package_id}"
    path_params: [{name: package_id, var: package_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: dimensions, var: dimensions}, {name: name, var: name}, {name: package_code, var: package_code}, {name: package_id, var: body_package_id}]}
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    package_id: $package_id, description: $description, dimensions: $dimensions, name: $name, package_code: $package_code, body_package_id: $body_package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Scheduled Pickups
#
# GET /v1/pickups
# Returns: record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, pickups: table<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record, created_at: string, label_ids: list, pickup_address: record, pickup_id: string, pickup_notes: string, pickup_window: record, pickup_windows: list, warehouse_id: string>, total: int, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>
# operationId: list_scheduled_pickups
export def "list-scheduled-pickups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: string # Carrier ID (e.g. se-28529731)
  --warehouse-id: string # Warehouse ID (e.g. se-28529731)
  --created-at-start: string # Only return scheduled pickups that were created on or after a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Only return scheduled pickups that were created on or before a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/pickups"
    query: [{name: carrier_id, var: carrier_id}, {name: warehouse_id, var: warehouse_id}, {name: created_at_start, var: created_at_start}, {name: created_at_end, var: created_at_end}, {name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_id: $carrier_id, warehouse_id: $warehouse_id, created_at_start: $created_at_start, created_at_end: $created_at_end, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule a Pickup
#
# POST /v1/pickups
# Returns: record<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record<email: string, name: string, phone: string>, created_at: string, label_ids: list<string>, pickup_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, pickup_id: string, pickup_notes: string, pickup_window: record<end_at: string, start_at: string>, pickup_windows: table<end_at: string, start_at: string>, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>
# operationId: schedule_pickup
export def "schedule-pickup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  contact_details: record # shape: {email: string, name: string, phone: string}
  label_ids: list<string> # Label IDs that will be included in the pickup request
  --pickup-notes: string # Used by some carriers to give special instructions for a package pickup
  pickup_window: record # The desired time range for the package pickup. — shape: {end_at: string, start_at: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/pickups"
    body: {content_type: "application/json", kind: json, fields: [{name: contact_details, var: contact_details}, {name: label_ids, var: label_ids}, {name: pickup_notes, var: pickup_notes}, {name: pickup_window, var: pickup_window}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    contact_details: $contact_details, label_ids: $label_ids, pickup_notes: $pickup_notes, pickup_window: $pickup_window
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Scheduled Pickup
#
# DELETE /v1/pickups/{pickup_id}
# Returns: record<errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string, pickup_id: string>
# operationId: delete_scheduled_pickup
export def "delete-scheduled-pickup" [
  pickup_id: string
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
    path: "/v1/pickups/{pickup_id}"
    path_params: [{name: pickup_id, var: pickup_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    pickup_id: $pickup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Pickup By ID
#
# GET /v1/pickups/{pickup_id}
# Returns: record<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record<email: string, name: string, phone: string>, created_at: string, label_ids: list<string>, pickup_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, pickup_id: string, pickup_notes: string, pickup_window: record<end_at: string, start_at: string>, pickup_windows: table<end_at: string, start_at: string>, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>
# operationId: get_pickup_by_id
export def "get-pickup-by-id" [
  pickup_id: string
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
    path: "/v1/pickups/{pickup_id}"
    path_params: [{name: pickup_id, var: pickup_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    pickup_id: $pickup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Shipping Rates
#
# POST /v1/rates
# Returns: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string, rate_response: record<created_at: string, errors: list<record>, invalid_rates: list<record>, rate_request_id: string, rates: list<record>, shipment_id: string, status: string>>
# operationId: calculate_rates
export def "calculate-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rate-options: record # The rate options — shape: {calculate_tax_amount?: bool, carrier_ids: list<string>, is_return?: bool, package_types?: list<string>, preferred_currency?: string, service_codes?: list<string>}
  shipment_id: string # A string that uniquely identifies the shipment
  shipment: record # The shipment object — shape: {validate_address?: "no_validation"|"validate_only"|"validate_and_clean", advanced_options?: record, carrier_id: string, confirmation?: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs?: record, external_order_id?: string, external_shipment_id?: string, insurance_provider?: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/rates"
    body: {content_type: "application/json", kind: json, fields: [{name: rate_options, var: rate_options}, {name: shipment_id, var: shipment_id}, {name: shipment, var: shipment}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    rate_options: $rate_options, shipment_id: $shipment_id, shipment: $shipment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Bulk Rates
#
# POST /v1/rates/bulk
# Returns: table<created_at: string, errors: list<record>, rate_request_id: string, shipment_id: string, status: string>
# operationId: compare_bulk_rates
export def "compare-bulk-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_options: record # The rate options — shape: {calculate_tax_amount?: bool, carrier_ids: list<string>, is_return?: bool, package_types?: list<string>, preferred_currency?: string, service_codes?: list<string>}
  --shipment-ids: list<string> # The array of shipment IDs
  --shipments: list # The array of shipments to get bulk rate estimates for — item shape: {validate_address?: "no_validation"|"validate_only"|"validate_and_clean", advanced_options?: record, carrier_id: string, confirmation?: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs?: record, external_order_id?: string, external_shipment_id?: string, insurance_provider?: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/rates/bulk"
    body: {content_type: "application/json", kind: json, fields: [{name: rate_options, var: rate_options}, {name: shipment_ids, var: shipment_ids}, {name: shipments, var: shipments}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    rate_options: $rate_options, shipment_ids: $shipment_ids, shipments: $shipments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Estimate Rates
#
# POST /v1/rates/estimate
# Returns: table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record<amount: float, currency: string>, delivery_days: int, error_messages: list<string>, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record<amount: float, currency: string>, negotiated_rate: bool, other_amount: record<amount: float, currency: string>, package_type: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record<amount: float, currency: string>, tax_amount: record<amount: float, currency: string>, trackable: bool, validation_status: string, warning_messages: list<string>, zone: int>
# operationId: estimate_rates
@deprecated --flag carrier-id
export def "estimate-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-residential-indicator: string@address-residential-indicator-completer # Indicates whether an address is residential.
  --confirmation: string@confirmation-completer # The possible delivery confirmation values
  --dimensions: record # The dimensions of the package — shape: {height: float, length: float, unit: "inch"|"centimeter", width: float}
  from_city_locality: string # from postal code (e.g. Austin)
  from_country_code: string # A two-letter [ISO 3166-1 country code](https://en.wikipedia.org/wiki/ISO_3166-1)
  from_postal_code: string # postal code
  from_state_province: string # From state province (e.g. Austin)
  ship_date: string # ship date (format: date-time)
  to_city_locality: string # The city locality the package is being shipped to (e.g. Austin)
  to_country_code: string # A two-letter [ISO 3166-1 country code](https://en.wikipedia.org/wiki/ISO_3166-1)
  to_postal_code: string # postal code
  to_state_province: string # To state province (e.g. Houston)
  weight: record # The weight of the package — shape: {unit: "pound"|"ounce"|"gram"|"kilogram", value: float}
  --carrier-id: string # A string that uniquely identifies the carrier (DEPRECATED)
  --carrier-ids: list<string> # Array of Carrier Ids
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/rates/estimate"
    body: {content_type: "application/json", kind: json, fields: [{name: address_residential_indicator, var: address_residential_indicator}, {name: confirmation, var: confirmation}, {name: dimensions, var: dimensions}, {name: from_city_locality, var: from_city_locality}, {name: from_country_code, var: from_country_code}, {name: from_postal_code, var: from_postal_code}, {name: from_state_province, var: from_state_province}, {name: ship_date, var: ship_date}, {name: to_city_locality, var: to_city_locality}, {name: to_country_code, var: to_country_code}, {name: to_postal_code, var: to_postal_code}, {name: to_state_province, var: to_state_province}, {name: weight, var: weight}, {name: carrier_id, var: carrier_id}, {name: carrier_ids, var: carrier_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    address_residential_indicator: $address_residential_indicator, confirmation: $confirmation, dimensions: $dimensions, from_city_locality: $from_city_locality, from_country_code: $from_country_code, from_postal_code: $from_postal_code, from_state_province: $from_state_province, ship_date: $ship_date, to_city_locality: $to_city_locality, to_country_code: $to_country_code, to_postal_code: $to_postal_code, to_state_province: $to_state_province, weight: $weight, carrier_id: $carrier_id, carrier_ids: $carrier_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Rate By ID
#
# GET /v1/rates/{rate_id}
# Returns: record<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record<amount: float, currency: string>, delivery_days: int, error_messages: list<string>, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record<amount: float, currency: string>, negotiated_rate: bool, other_amount: record<amount: float, currency: string>, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record<amount: float, currency: string>, tax_amount: record<amount: float, currency: string>, trackable: bool, validation_status: string, warning_messages: list<string>, zone: int>
# operationId: get_rate_by_id
export def "get-rate-by-id" [
  rate_id: string
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
    path: "/v1/rates/{rate_id}"
    path_params: [{name: rate_id, var: rate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    rate_id: $rate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Service Points
#
# POST /v1/service_points/list
# Returns: record<errors: table<error_code: string, error_source: string, error_type: string, message: string>, lat: float, long: float, service_points: table<address_line1: string, carrier_code: string, city_locality: string, company_name: string, country_code: string, distance_in_meters: float, features: list, hours_of_operation: record, lat: float, long: float, phone_number: string, postal_code: string, service_codes: list, service_point_id: string, state_province: string>>
# operationId: service_points_list
export def "service-points-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # Structured address to search by. — shape: {address_line1?: string, address_line2?: string, address_line3?: string, city_locality?: string, country_code: string, postal_code?: string, state_province?: string}
  --address-query: string # Unstructured text to search for service points by. (e.g. 177A Bleecker Street New York)
  --lat: float # The latitude of the point. Represented as signed degrees. Required if long is provided. http://www.geomidpoint.com/latlon.html (format: double, e.g. 48.874518928233094)
  --long: float # The longitude of the point. Represented as signed degrees. Required if lat is provided. http://www.geomidpoint.com/latlon.html (format: double, e.g. 2.3591775711639404)
  --max-results: int # The maximum number of service points to return (format: int32, e.g. 25)
  providers: list # An array of shipping service providers and service codes — item shape: {carrier_id?: string, service_code?: list<string>}
  --radius: int # Search radius in kilometers (format: int32, e.g. 500)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/service_points/list"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: address_query, var: address_query}, {name: lat, var: lat}, {name: long, var: long}, {name: max_results, var: max_results}, {name: providers, var: providers}, {name: radius, var: radius}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    address: $address, address_query: $address_query, lat: $lat, long: $long, max_results: $max_results, providers: $providers, radius: $radius
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Service Point By ID
#
# GET /v1/service_points/{carrier_code}/{country_code}/{service_point_id}
# Returns: record<service_point: record<address_line1: string, carrier_code: string, city_locality: string, company_name: string, country_code: string, features: list<string>, hours_of_operation: record<friday: list, monday: list, saturday: list, sunday: list, thursday: list, tuesday: list, wednesday: list>, lat: float, long: float, phone_number: string, postal_code: string, service_codes: list<string>, service_point_id: string, state_province: string>>
# operationId: service_points_get_by_id
export def "service-points-get-by-id" [
  carrier_code: string
  country_code: string
  service_point_id: string
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
    path: "/v1/service_points/{carrier_code}/{country_code}/{service_point_id}"
    path_params: [{name: carrier_code, var: carrier_code}, {name: country_code, var: country_code}, {name: service_point_id, var: service_point_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_code: $carrier_code, country_code: $country_code, service_point_id: $service_point_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Shipments
#
# GET /v1/shipments
# Returns: record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, shipments: table<advanced_options: record, carrier_id: string, confirmation: string, created_at: string, customs: record, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list, modified_at: string, order_source_code: string, origin_type: string, packages: list, return_to: record, service_code: string, ship_date: string, ship_from: record, ship_to: record, shipment_id: string, shipment_number: string, shipment_status: string, tags: list, tax_identifiers: list, total_weight: record, warehouse_id: string>, total: int>
# operationId: list_shipments
export def "list-shipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipment-status: string@shipment-status-completer
  --batch-id: string # Batch ID (e.g. se-28529731)
  --tag: string # Search for shipments based on the custom tag added to the shipment object (e.g. Letters_to_santa)
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Used to create a filter for when a resource was created, (ex. A shipment that was created before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --modified-at-start: string # Used to create a filter for when a resource was modified (ex. A shipment that was modified after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --modified-at-end: string # Used to create a filter for when a resource was modified (ex. A shipment that was modified before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sales-order-id: string # Sales Order ID
  --sort-dir: string@sort-dir-completer # Controls the sort order of the query. (default: desc)
  --sort-by: string@sort-by-completer-1 # e.g. modified_at
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/shipments"
    query: [{name: shipment_status, var: shipment_status}, {name: batch_id, var: batch_id}, {name: tag, var: tag}, {name: created_at_start, var: created_at_start}, {name: created_at_end, var: created_at_end}, {name: modified_at_start, var: modified_at_start}, {name: modified_at_end, var: modified_at_end}, {name: page, var: page}, {name: page_size, var: page_size}, {name: sales_order_id, var: sales_order_id}, {name: sort_dir, var: sort_dir}, {name: sort_by, var: sort_by}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    shipment_status: $shipment_status, batch_id: $batch_id, tag: $tag, created_at_start: $created_at_start, created_at_end: $created_at_end, modified_at_start: $modified_at_start, modified_at_end: $modified_at_end, page: $page, page_size: $page_size, sales_order_id: $sales_order_id, sort_dir: $sort_dir, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Shipments
#
# POST /v1/shipments
# Returns: record<has_errors: bool, shipments: table<advanced_options: record, carrier_id: string, confirmation: string, created_at: string, customs: record, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list, modified_at: string, order_source_code: string, origin_type: string, packages: list, return_to: record, service_code: string, ship_date: string, ship_from: record, ship_to: record, shipment_id: string, shipment_number: string, shipment_status: string, tags: list, tax_identifiers: list, total_weight: record, warehouse_id: string, address_validation: record, errors: list>>
# operationId: create_shipments
export def "create-shipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  shipments: list # An array of shipments to be created. — item shape: {validate_address?: "no_validation"|"validate_only"|"validate_and_clean", advanced_options?: record, carrier_id: string, confirmation?: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs?: record, external_order_id?: string, external_shipment_id?: string, insurance_provider?: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/shipments"
    body: {content_type: "application/json", kind: json, fields: [{name: shipments, var: shipments}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    shipments: $shipments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Shipment By External ID
#
# GET /v1/shipments/external_shipment_id/{external_shipment_id}
# Returns: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string>
# operationId: get_shipment_by_external_id
export def "get-shipment-by-external-id" [
  external_shipment_id: string
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
    path: "/v1/shipments/external_shipment_id/{external_shipment_id}"
    path_params: [{name: external_shipment_id, var: external_shipment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    external_shipment_id: $external_shipment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parse shipping info
#
# PUT /v1/shipments/recognize
# Returns: record<entities: table<end_index: int, result: record, score: float, start_index: int, text: string, type: string>, score: float, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>>
# operationId: parse_shipment
export def "parse-shipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipment: record # You can optionally provide a `shipment` object containing any already-known values. For example, you probably already know the `ship_from` address, and you may also already know what carrier and service you want to use. — shape: {advanced_options?: record, carrier_id?: string, confirmation?: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs?: record, external_order_id?: string, external_shipment_id?: string, insurance_provider?: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
  text: string # The unstructured text that contains shipping-related entities (e.g. I have a 4oz package that's 5x10x14in, and I need to ship it to Margie McMiller at 3800 North Lamar suite 200 in austin, tx 78652. Please send it via USPS first class and require an adult signature. It also needs to be insured for $400. )
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/shipments/recognize"
    body: {content_type: "application/json", kind: json, fields: [{name: shipment, var: shipment}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    shipment: $shipment, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Shipment By ID
#
# GET /v1/shipments/{shipment_id}
# Returns: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string>
# operationId: get_shipment_by_id
export def "get-shipment-by-id" [
  shipment_id: string
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
    path: "/v1/shipments/{shipment_id}"
    path_params: [{name: shipment_id, var: shipment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    shipment_id: $shipment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Shipment By ID
#
# PUT /v1/shipments/{shipment_id}
# Returns: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string, address_validation: record<matched_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, messages: list<record>, original_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, status: string>, errors: list<string>>
# operationId: update_shipment
export def "update-shipment" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advanced-options: record # Advanced shipment options. These are entirely optional. — shape: {bill_to_account?: string, bill_to_country_code?: string, bill_to_party?: "recipient"|"third_party", bill_to_postal_code?: string, collect_on_delivery?: record, contains_alcohol?: bool, custom_field1?: string, custom_field2?: string, custom_field3?: string, delivered_duty_paid?: bool, dry_ice?: bool, dry_ice_weight?: record, fedex_freight?: record, freight_class?: string, non_machinable?: bool, origin_type?: "pickup"|"drop_off", saturday_delivery?: bool, shipper_release?: bool, ... (2 more fields)}
  --carrier-id: string # The carrier account that is billed for the shipping charges
  --confirmation: string@confirmation-completer # The type of delivery confirmation that is required for this shipment. (default: none)
  --customs: record # Customs information. This is usually only needed for international shipments. (nullable) — shape: {contents: "merchandise"|"documents"|"gift"|"returned_goods"|"sample", customs_items?: list, non_delivery: "return_to_sender"|"treat_as_abandoned"}
  --external-order-id: string # ID that the Order Source assigned (nullable)
  --external-shipment-id: string # A unique user-defined key to identify a shipment. This can be used to retrieve the shipment. > **Warning:** The `external_shipment_id` is limited to 50 characters. Any additional characters will be truncated. (nullable)
  --insurance-provider: string@insurance-provider-completer # The insurance provider to use for any insured packages in the shipment. (default: none)
  --items: list # Describe the packages included in this shipment as related to potential metadata that was imported from external order sources (default: []) — item shape: {asin?: string, external_order_id?: string, external_order_item_id?: string, name?: string, order_source_code?: "amazon_ca"|"amazon_us"|"brightpearl"|"channel_advisor"|"cratejoy"|"ebay"|"etsy"|"jane"|"groupon_goods"|"magento"|"paypal"|"seller_active"|"shopify"|"stitch_labs"|"squarespace"|"three_dcart"|"tophatter"|"walmart"|"woo_commerce"|"volusion", quantity?: int, sales_order_id?: string, sales_order_item_id?: string, sku?: string}
  --order-source-code: string@order-source-code-completer # The order sources that are supported by ShipEngine
  --origin-type: string@origin-type-completer # Indicates if the package will be picked up or dropped off by the carrier (nullable)
  --packages: list # The packages in the shipment. > **Note:** Some carriers only allow one package per shipment. If you attempt to create a multi-package shipment for a carrier that doesn't allow it, an error will be returned. — item shape: {content_description?: string, dimensions?: record, external_package_id?: string, insured_value?: record, label_messages?: record, package_code?: string, package_id?: string, weight: record}
  --return-to: record # The return address for this shipment. Defaults to the `ship_from` address. — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string, instructions?: string}
  --service-code: string # The [carrier service](https://www.shipengine.com/docs/shipping/use-a-carrier-service/) used to ship the package, such as `fedex_ground`, `usps_first_class_mail`, `flat_rate_envelope`, etc.
  --ship-date: string # The date that the shipment was (or will be) shippped. ShipEngine will take the day of week into consideration. For example, if the carrier does not operate on Sundays, then a package that would have shipped on Sunday will ship on Monday instead. (format: date-time)
  ship_from: record # The shipment's origin address. If you frequently ship from the same location, consider [creating a warehouse](https://www.shipengine.com/docs/reference/create-warehouse/). Then you can simply specify the `warehouse_id` rather than the complete address each time. — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string, instructions?: string}
  ship_to: record # The recipient's mailing address — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string, instructions?: string}
  --shipment-number: string # A non-unique user-defined number used to identify a shipment. If undefined, this will match the external_shipment_id of the shipment. > **Warning:** The `shipment_number` is limited to 50 characters. Any additional characters will be truncated. (nullable)
  --tax-identifiers: list # nullable — item shape: {identifier_type: "vat"|"eori"|"ssn"|"ein"|"tin"|"ioss"|"pan"|"voec", issuing_authority: string, taxable_entity_type: "shipper"|"recipient", value: string}
  --warehouse-id: string # The [warehouse](https://www.shipengine.com/docs/shipping/ship-from-a-warehouse/) that the shipment is being shipped from. Either `warehouse_id` or `ship_from` must be specified. (nullable)
  --validate-address: string@validate-address-completer # The possible validate address values (default: no_validation)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/shipments/{shipment_id}"
    path_params: [{name: shipment_id, var: shipment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: advanced_options, var: advanced_options}, {name: carrier_id, var: carrier_id}, {name: confirmation, var: confirmation}, {name: customs, var: customs}, {name: external_order_id, var: external_order_id}, {name: external_shipment_id, var: external_shipment_id}, {name: insurance_provider, var: insurance_provider}, {name: items, var: items}, {name: order_source_code, var: order_source_code}, {name: origin_type, var: origin_type}, {name: packages, var: packages}, {name: return_to, var: return_to}, {name: service_code, var: service_code}, {name: ship_date, var: ship_date}, {name: ship_from, var: ship_from}, {name: ship_to, var: ship_to}, {name: shipment_number, var: shipment_number}, {name: tax_identifiers, var: tax_identifiers}, {name: warehouse_id, var: warehouse_id}, {name: validate_address, var: validate_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    shipment_id: $shipment_id, advanced_options: $advanced_options, carrier_id: $carrier_id, confirmation: $confirmation, customs: $customs, external_order_id: $external_order_id, external_shipment_id: $external_shipment_id, insurance_provider: $insurance_provider, items: $items, order_source_code: $order_source_code, origin_type: $origin_type, packages: $packages, return_to: $return_to, service_code: $service_code, ship_date: $ship_date, ship_from: $ship_from, ship_to: $ship_to, shipment_number: $shipment_number, tax_identifiers: $tax_identifiers, warehouse_id: $warehouse_id, validate_address: $validate_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a Shipment
#
# PUT /v1/shipments/{shipment_id}/cancel
# Returns: string
# operationId: cancel_shipments
export def "cancel-shipments" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: put
    path: "/v1/shipments/{shipment_id}/cancel"
    path_params: [{name: shipment_id, var: shipment_id}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    shipment_id: $shipment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Shipment Rates
#
# GET /v1/shipments/{shipment_id}/rates
# Returns: record<created_at: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, invalid_rates: table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record, delivery_days: int, error_messages: list, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record, negotiated_rate: bool, other_amount: record, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record, tax_amount: record, trackable: bool, validation_status: string, warning_messages: list, zone: int>, rate_request_id: string, rates: table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record, delivery_days: int, error_messages: list, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record, negotiated_rate: bool, other_amount: record, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record, tax_amount: record, trackable: bool, validation_status: string, warning_messages: list, zone: int>, shipment_id: string, status: string>
# operationId: list_shipment_rates
export def "list-shipment-rates" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/shipments/{shipment_id}/rates"
    path_params: [{name: shipment_id, var: shipment_id}]
    query: [{name: created_at_start, var: created_at_start}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    shipment_id: $shipment_id, created_at_start: $created_at_start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Tag from Shipment
#
# DELETE /v1/shipments/{shipment_id}/tags/{tag_name}
# Returns: string
# operationId: untag_shipment
export def "untag-shipment" [
  shipment_id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/shipments/{shipment_id}/tags/{tag_name}"
    path_params: [{name: shipment_id, var: shipment_id}, {name: tag_name, var: tag_name}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    shipment_id: $shipment_id, tag_name: $tag_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add Tag to Shipment
#
# POST /v1/shipments/{shipment_id}/tags/{tag_name}
# Returns: record<shipment_id: string, tag: record<name: string>>
# operationId: tag_shipment
export def "tag-shipment" [
  shipment_id: string
  tag_name: string
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
    path: "/v1/shipments/{shipment_id}/tags/{tag_name}"
    path_params: [{name: shipment_id, var: shipment_id}, {name: tag_name, var: tag_name}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    shipment_id: $shipment_id, tag_name: $tag_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tags
#
# GET /v1/tags
# Returns: record<tags: table<name: string>>
# operationId: list_tags
export def "list-tags" [
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
    path: "/v1/tags"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Tag
#
# DELETE /v1/tags/{tag_name}
# Returns: string
# operationId: delete_tag
export def "delete-tag" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/tags/{tag_name}"
    path_params: [{name: tag_name, var: tag_name}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    tag_name: $tag_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a New Tag
#
# POST /v1/tags/{tag_name}
# Returns: record<name: string>
# operationId: create_tag
export def "create-tag" [
  tag_name: string
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
    path: "/v1/tags/{tag_name}"
    path_params: [{name: tag_name, var: tag_name}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    tag_name: $tag_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Tag Name
#
# PUT /v1/tags/{tag_name}/{new_tag_name}
# Returns: string
# operationId: rename_tag
export def "rename-tag" [
  tag_name: string
  new_tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: put
    path: "/v1/tags/{tag_name}/{new_tag_name}"
    path_params: [{name: tag_name, var: tag_name}, {name: new_tag_name, var: new_tag_name}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    tag_name: $tag_name, new_tag_name: $new_tag_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Ephemeral Token
#
# POST /v1/tokens/ephemeral
# Returns: record<redirect_url: string, token: string>
# operationId: tokens_get_ephemeral_token
export def "tokens-get-ephemeral-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect: string@redirect-completer # Include a redirect url to the application formatted with the ephemeral token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/tokens/ephemeral"
    query: [{name: redirect, var: redirect}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    redirect: $redirect
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tracking Information
#
# GET /v1/tracking
# Returns: record<actual_delivery_date: string, carrier_code: string, carrier_detail_code: string, carrier_id: string, carrier_status_code: string, carrier_status_description: string, estimated_delivery_date: string, events: table<carrier_detail_code: string, carrier_occurred_at: string, carrier_status_code: string, carrier_status_description: string, city_locality: string, company_name: string, country_code: string, description: string, event_code: string, latitude: float, longitude: float, occurred_at: string, postal_code: string, signer: string, state_province: string, status_code: string, status_description: string>, exception_description: string, ship_date: string, status_code: string, status_description: string, tracking_number: string, tracking_url: string>
# operationId: get_tracking_log
export def "get-tracking-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-code: string # Carrier code used to retrieve tracking information (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/tracking"
    query: [{name: carrier_code, var: carrier_code}, {name: tracking_number, var: tracking_number}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    carrier_code: $carrier_code, tracking_number: $tracking_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start Tracking a Package
#
# POST /v1/tracking/start
# Returns: string
# operationId: start_tracking
export def "start-tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-code: string # Carrier code used to retrieve tracking information (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/tracking/start"
    query: [{name: carrier_code, var: carrier_code}, {name: tracking_number, var: tracking_number}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    carrier_code: $carrier_code, tracking_number: $tracking_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Stop Tracking a Package
#
# POST /v1/tracking/stop
# Returns: string
# operationId: stop_tracking
export def "stop-tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-code: string # Carrier code used to retrieve tracking information (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/tracking/stop"
    query: [{name: carrier_code, var: carrier_code}, {name: tracking_number, var: tracking_number}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    carrier_code: $carrier_code, tracking_number: $tracking_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Warehouses
#
# GET /v1/warehouses
# Returns: record<warehouses: table<created_at: string, is_default: bool, name: string, origin_address: record, return_address: record, warehouse_id: string>>
# operationId: list_warehouses
export def "list-warehouses" [
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
    path: "/v1/warehouses"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Warehouse
#
# POST /v1/warehouses
# Returns: record<created_at: string, is_default: bool, name: string, origin_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, return_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, warehouse_id: string>
# operationId: create_warehouse
export def "create-warehouse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-default: oneof<nothing, bool> # Designates which single warehouse is the default on the account (nullable, default: false)
  name: string # Name of the warehouse (e.g. Zero Cool HQ)
  origin_address: record # The origin address of the warehouse — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string}
  --return-address: record # The return address associated with the warehouse — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/warehouses"
    body: {content_type: "application/json", kind: json, fields: [{name: is_default, var: is_default}, {name: name, var: name}, {name: origin_address, var: origin_address}, {name: return_address, var: return_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    is_default: $is_default, name: $name, origin_address: $origin_address, return_address: $return_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Warehouse By ID
#
# DELETE /v1/warehouses/{warehouse_id}
# Returns: string
# operationId: delete_warehouse
export def "delete-warehouse" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/warehouses/{warehouse_id}"
    path_params: [{name: warehouse_id, var: warehouse_id}]
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    warehouse_id: $warehouse_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Warehouse By Id
#
# GET /v1/warehouses/{warehouse_id}
# Returns: record<created_at: string, is_default: bool, name: string, origin_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, return_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, warehouse_id: string>
# operationId: get_warehouse_by_id
export def "get-warehouse-by-id" [
  warehouse_id: string
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
    path: "/v1/warehouses/{warehouse_id}"
    path_params: [{name: warehouse_id, var: warehouse_id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    warehouse_id: $warehouse_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Warehouse By Id
#
# PUT /v1/warehouses/{warehouse_id}
# Returns: string
# operationId: update_warehouse
export def "update-warehouse" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-default: oneof<nothing, bool> # Designates which single warehouse is the default on the account (nullable, default: false)
  name: string # Name of the warehouse (e.g. Zero Cool HQ)
  origin_address: record # The origin address of the warehouse — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string}
  --return-address: record # The return address associated with the warehouse — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/warehouses/{warehouse_id}"
    path_params: [{name: warehouse_id, var: warehouse_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_default, var: is_default}, {name: name, var: name}, {name: origin_address, var: origin_address}, {name: return_address, var: return_address}]}
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    warehouse_id: $warehouse_id, is_default: $is_default, name: $name, origin_address: $origin_address, return_address: $return_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Warehouse Settings
#
# PUT /v1/warehouses/{warehouse_id}/settings
# Returns: string
# operationId: update_warehouse_settings
export def "update-warehouse-settings" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-default: oneof<nothing, bool> # The default property on the warehouse. (nullable, e.g. true)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/warehouses/{warehouse_id}/settings"
    path_params: [{name: warehouse_id, var: warehouse_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_default, var: is_default}]}
    accept: ["application/json", "text/plain"]
    ok: [204]
    auth: api-key
  } {
    warehouse_id: $warehouse_id, is_default: $is_default
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
