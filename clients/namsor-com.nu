# Auto-generated client for NamSor API v2 v2.0.24
# Source: https://api.apis.guru/v2/specs/namsor.com/2.0.24/openapi.json
# Auth: --token flag or $env.NAMSOR_API_V2_TOKEN

const CLIENT = {
  base_url: "https://v2.namsor.com/NamSorAPIv2"
  token_env_var: "NAMSOR_API_V2_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: X-API-KEY, prefix: ""}
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

def base-url-completer [] { ["https://v2.namsor.com/NamSorAPIv2"] }
def auth-scheme-completer [] { ["x-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    anonymize: "record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool>"
    api-key-info: "record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool>"
    available-services: "record<apiServices: table<costInUnits: int, serviceGroup: string, serviceName: string>>"
    api-status: "record<classifiers: table<classifierName: string, learning: bool, probabilityCalibrated: bool, serving: bool, shuttingDown: bool>, softwareVersion: record<softwareNameAndVersion: string, softwareVersion: list<int>>>"
    api-usage: "record<billingPeriod: record<apiKey: string, billingStatus: string, hardLimit: int, periodEnded: int, periodStarted: int, softLimit: int, stripeCurrentPeriodEnd: int, stripeCurrentPeriodStart: int, subscriptionStarted: int, usage: int>, overageCurrency: string, overageExclTax: float, overageInclTax: float, overageQuantity: int, subscription: record<apiKey: string, currency: string, currencyFactor: float, planBaseFeesKey: string, planEnded: int, planName: string, planQuota: int, planStarted: int, planStatus: string, price: float, priceOverage: float, priceOverageUSD: float, priceUSD: float, priorPlanStarted: int, stripeCustomerId: string, stripeStatus: string, stripeSubscription: string, taxRate: float, userId: string>>"
    api-usage-history: "record<detailedUsage: table<apiKey: record, apiService: string, createdDateTime: int, hostAddress: string, lastFlushedDateTime: int, lastUsedDateTime: int, serviceFeaturesUsage: record, totalUsage: int>>"
    api-usage-history-aggregate: "record<colHeaders: list<string>, data: list<list<int>>, historyTruncated: bool, periodEnd: int, periodStart: int, rowHeaders: list<string>, timeUnit: string, totalUsage: int>"
    castegroup-indian-full: "record<castegroup: string, castegroupAlt: string, castegroupTop: list<string>, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>"
    castegroup-indian-full-batch: "record<personalNames: table<castegroup: string, castegroupAlt: string, castegroupTop: list, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>>"
    chinese-name-candidates: "record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>"
    chinese-name-candidates-batch: "record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>"
    chinese-name-candidates-gender-batch: "record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>"
    chinese-name-gender-candidates: "record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>"
    chinese-name-match: "record<id: string, matchStatus: string, score: float, script: string>"
    chinese-name-match-batch: "record<matchedNames: table<id: string, matchStatus: string, score: float, script: string>>"
    corridor: "record<FirstLastNameDiasporaedOut: record<countryIso2: string, ethnicitiesTop: list<string>, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>, FirstLastNameGenderedOut: record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>, FirstLastNameOriginedOut: record<countriesOriginTop: list<string>, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string>, id: string, script: string>"
    corridor-batch: "record<corridorFromTo: table<FirstLastNameDiasporaedOut: record, FirstLastNameGenderedOut: record, FirstLastNameOriginedOut: record, id: string, script: string>>"
    country: "record<countriesTop: list<string>, country: string, countryAlt: string, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, region: string, score: float, script: string, subRegion: string, topRegion: string>"
    country-batch: "record<personalNames: table<countriesTop: list, country: string, countryAlt: string, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, region: string, score: float, script: string, subRegion: string, topRegion: string>>"
    diaspora: "record<countryIso2: string, ethnicitiesTop: list<string>, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>"
    diaspora-batch: "record<personalNames: table<countryIso2: string, ethnicitiesTop: list, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>>"
    gender: "record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>"
    gender-1: "record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>"
    gender-batch: "record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>>"
    gender-chinese-name: "record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>"
    gender-chinese-name-batch: "record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>>"
    gender-chinese-name-pinyin: "record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>"
    gender-chinese-name-pinyin-batch: "record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>>"
    gender-full: "record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>"
    gender-full-batch: "record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>>"
    gender-full-geo: "record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>"
    gender-full-geo-batch: "record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>>"
    gender-geo: "record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>"
    gender-geo-batch: "record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>>"
    gender-japanese-name-pinyin: "record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>"
    gender-japanese-name-pinyin-batch: "record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>>"
    gender-japanese-name-full: "record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>"
    gender-japanese-name-full-batch: "record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>>"
    japanese-name-gender-kanji-candidates-batch: "record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>"
    japanese-name-kanji-candidates: "record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>"
    japanese-name-kanji-candidates-1: "record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>"
    japanese-name-kanji-candidates-batch: "record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>"
    japanese-name-latin-candidates: "record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>"
    japanese-name-latin-candidates-batch: "record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>"
    japanese-name-match: "record<id: string, matchStatus: string, score: float, script: string>"
    japanese-name-match-batch: "record<matchedNames: table<id: string, matchStatus: string, score: float, script: string>>"
    japanese-name-match-feedback-loop: "record<feedbackCredits: int>"
    learnable: "record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool>"
    name-type: "record<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>"
    name-type-batch: "record<properNouns: table<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>>"
    name-type-geo: "record<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>"
    name-type-geo-batch: "record<properNouns: table<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>>"
    origin: "record<countriesOriginTop: list<string>, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string>"
    origin-batch: "record<personalNames: table<countriesOriginTop: list, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string>>"
    parse-chinese-name: "record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>"
    parse-chinese-name-batch: "record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>"
    parse-japanese-name: "record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>"
    parse-japanese-name-batch: "record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>"
    parse-name: "record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>"
    parse-name-geo: "record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>"
    parse-name-batch: "record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>"
    parse-name-geo-batch: "record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>"
    phone-code: "record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>"
    phone-code-batch: "record<personalNamesWithPhoneNumbers: table<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>>"
    phone-code-geo: "record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>"
    phone-code-geo-batch: "record<personalNamesWithPhoneNumbers: table<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>>"
    phone-code-geo-feedback-loop: "record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>"
    pinyin-chinese-name: "record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>"
    pinyin-chinese-name-batch: "record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>"
    regions: "record<countriesAndRegions: table<countryFIPS: string, countryISO2: string, countryISO3: string, countryName: string, countryNumCode: string, region: string, subregion: string, topregion: string>>"
    religion-full: "record<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list<string>, score: float, script: string>"
    religion-full-batch: "record<personalNames: table<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list, score: float, script: string>>"
    religion: "record<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list<string>, score: float, script: string>"
    religion-indian-full-batch: "record<personalNames: table<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list, score: float, script: string>>"
    software-version: "record<softwareNameAndVersion: string, softwareVersion: list<int>>"
    subclassification: "record<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list<string>>"
    subclassification-batch: "record<personalNames: table<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list>>"
    subclassification-indian: "record<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list<string>>"
    subclassification-indian-batch: "record<personalNames: table<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list>>"
    taxonomy-classes: "record<classifierName: string, classifyingScripts: list<string>, taxonomyClasses: list<string>>"
    us-race-ethnicity: "record<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list<string>, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>"
    us-race-ethnicity-batch: "record<personalNames: table<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>>"
    us-race-ethnicity-zip5: "record<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list<string>, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>"
    us-zip-race-ethnicity-batch: "record<personalNames: table<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["anonymize" "api-key-info" "available-services" "api-status" "api-usage" "api-usage-history" "api-usage-history-aggregate" "castegroup-indian-full" "castegroup-indian-full-batch" "chinese-name-candidates" "chinese-name-candidates-batch" "chinese-name-candidates-gender-batch" "chinese-name-gender-candidates" "chinese-name-match" "chinese-name-match-batch" "corridor" "corridor-batch" "country" "country-batch" "diaspora" "diaspora-batch" "gender" "gender-1" "gender-batch" "gender-chinese-name" "gender-chinese-name-batch" "gender-chinese-name-pinyin" "gender-chinese-name-pinyin-batch" "gender-full" "gender-full-batch" "gender-full-geo" "gender-full-geo-batch" "gender-geo" "gender-geo-batch" "gender-japanese-name-pinyin" "gender-japanese-name-pinyin-batch" "gender-japanese-name-full" "gender-japanese-name-full-batch" "japanese-name-gender-kanji-candidates-batch" "japanese-name-kanji-candidates" "japanese-name-kanji-candidates-1" "japanese-name-kanji-candidates-batch" "japanese-name-latin-candidates" "japanese-name-latin-candidates-batch" "japanese-name-match" "japanese-name-match-batch" "japanese-name-match-feedback-loop" "learnable" "name-type" "name-type-batch" "name-type-geo" "name-type-geo-batch" "origin" "origin-batch" "parse-chinese-name" "parse-chinese-name-batch" "parse-japanese-name" "parse-japanese-name-batch" "parse-name" "parse-name-geo" "parse-name-batch" "parse-name-geo-batch" "phone-code" "phone-code-batch" "phone-code-geo" "phone-code-geo-batch" "phone-code-geo-feedback-loop" "pinyin-chinese-name" "pinyin-chinese-name-batch" "regions" "religion-full" "religion-full-batch" "religion" "religion-indian-full-batch" "software-version" "subclassification" "subclassification-batch" "subclassification-indian" "subclassification-indian-batch" "taxonomy-classes" "us-race-ethnicity" "us-race-ethnicity-batch" "us-race-ethnicity-zip5" "us-zip-race-ethnicity-batch" "commands"] | sort) } | get name | first)
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

# Activate/deactivate anonymization for a source.
#
# GET /api2/json/anonymize/{source}/{anonymized}/{token}
# Returns: record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool>
# operationId: anonymize
export def "anonymize" [
  source: string
  anonymized: bool
  token_arg: string
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
    path: "/api2/json/anonymize/{source}/{anonymized}/{token}"
    path_params: [{name: source, var: source}, {name: anonymized, var: anonymized}, {name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    source: $source, anonymized: $anonymized, token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read API Key info.
#
# GET /api2/json/apiKeyInfo
# Returns: record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool>
# operationId: apiKeyInfo
export def "api-key-info" [
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
    path: "/api2/json/apiKeyInfo"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of classification services and usage cost in Units per classification (default is 1=ONE Unit). Some API endpoints (ex. Corridor) combine multiple classifiers.
#
# GET /api2/json/apiServices
# Returns: record<apiServices: table<costInUnits: int, serviceGroup: string, serviceName: string>>
# operationId: availableServices
export def "available-services" [
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
    path: "/api2/json/apiServices"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Prints the current status of the classifiers. A classifier name in apiStatus corresponds to a service name in apiServices.
#
# GET /api2/json/apiStatus
# Returns: record<classifiers: table<classifierName: string, learning: bool, probabilityCalibrated: bool, serving: bool, shuttingDown: bool>, softwareVersion: record<softwareNameAndVersion: string, softwareVersion: list<int>>>
# operationId: apiStatus
export def "api-status" [
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
    path: "/api2/json/apiStatus"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Print current API usage.
#
# GET /api2/json/apiUsage
# Returns: record<billingPeriod: record<apiKey: string, billingStatus: string, hardLimit: int, periodEnded: int, periodStarted: int, softLimit: int, stripeCurrentPeriodEnd: int, stripeCurrentPeriodStart: int, subscriptionStarted: int, usage: int>, overageCurrency: string, overageExclTax: float, overageInclTax: float, overageQuantity: int, subscription: record<apiKey: string, currency: string, currencyFactor: float, planBaseFeesKey: string, planEnded: int, planName: string, planQuota: int, planStarted: int, planStatus: string, price: float, priceOverage: float, priceOverageUSD: float, priceUSD: float, priorPlanStarted: int, stripeCustomerId: string, stripeStatus: string, stripeSubscription: string, taxRate: float, userId: string>>
# operationId: apiUsage
export def "api-usage" [
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
    path: "/api2/json/apiUsage"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Print historical API usage.
#
# GET /api2/json/apiUsageHistory
# Returns: record<detailedUsage: table<apiKey: record, apiService: string, createdDateTime: int, hostAddress: string, lastFlushedDateTime: int, lastUsedDateTime: int, serviceFeaturesUsage: record, totalUsage: int>>
# operationId: apiUsageHistory
export def "api-usage-history" [
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
    path: "/api2/json/apiUsageHistory"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Print historical API usage (in an aggregated view, by service, by day/hour/min).
#
# GET /api2/json/apiUsageHistoryAggregate
# Returns: record<colHeaders: list<string>, data: list<list<int>>, historyTruncated: bool, periodEnd: int, periodStart: int, rowHeaders: list<string>, timeUnit: string, totalUsage: int>
# operationId: apiUsageHistoryAggregate
export def "api-usage-history-aggregate" [
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
    path: "/api2/json/apiUsageHistoryAggregate"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely Indian name castegroup of a personal full name.
#
# GET /api2/json/castegroupIndianFull/{subDivisionIso31662}/{personalNameFull}
# Returns: record<castegroup: string, castegroupAlt: string, castegroupTop: list<string>, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>
# operationId: castegroupIndianFull
export def "castegroup-indian-full" [
  sub_division_iso31662: string
  personal_name_full: string
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
    path: "/api2/json/castegroupIndianFull/{subDivisionIso31662}/{personalNameFull}"
    path_params: [{name: subDivisionIso31662, var: sub_division_iso31662}, {name: personalNameFull, var: personal_name_full}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    sub_division_iso31662: $sub_division_iso31662, personal_name_full: $personal_name_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely Indian name castegroup of up to 100 personal full names.
#
# POST /api2/json/castegroupIndianFullBatch
# Returns: record<personalNames: table<castegroup: string, castegroupAlt: string, castegroupTop: list, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>>
# operationId: castegroupIndianFullBatch
export def "castegroup-indian-full-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string, subdivisionIso?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/castegroupIndianFullBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify Chinese name candidates, based on the romanized name ex. Wang Xiaoming
#
# GET /api2/json/chineseNameCandidates/{chineseSurnameLatin}/{chineseGivenNameLatin}
# Returns: record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>
# operationId: chineseNameCandidates
export def "chinese-name-candidates" [
  chinese_surname_latin: string
  chinese_given_name_latin: string
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
    path: "/api2/json/chineseNameCandidates/{chineseSurnameLatin}/{chineseGivenNameLatin}"
    path_params: [{name: chineseSurnameLatin, var: chinese_surname_latin}, {name: chineseGivenNameLatin, var: chinese_given_name_latin}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    chinese_surname_latin: $chinese_surname_latin, chinese_given_name_latin: $chinese_given_name_latin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify Chinese name candidates, based on the romanized name (firstName = chineseGivenName; lastName=chineseSurname), ex. Wang Xiaoming
#
# POST /api2/json/chineseNameCandidatesBatch
# Returns: record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>
# operationId: chineseNameCandidatesBatch
export def "chinese-name-candidates-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/chineseNameCandidatesBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify Chinese name candidates, based on the romanized name (firstName = chineseGivenName; lastName=chineseSurname) ex. Wang Xiaoming.
#
# POST /api2/json/chineseNameCandidatesGenderBatch
# Returns: record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>
# operationId: chineseNameCandidatesGenderBatch
export def "chinese-name-candidates-gender-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, gender?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/chineseNameCandidatesGenderBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify Chinese name candidates, based on the romanized name ex. Wang Xiaoming - having a known gender ('male' or 'female')
#
# GET /api2/json/chineseNameGenderCandidates/{chineseSurnameLatin}/{chineseGivenNameLatin}/{knownGender}
# Returns: record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>
# operationId: chineseNameGenderCandidates
export def "chinese-name-gender-candidates" [
  chinese_surname_latin: string
  chinese_given_name_latin: string
  known_gender: string
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
    path: "/api2/json/chineseNameGenderCandidates/{chineseSurnameLatin}/{chineseGivenNameLatin}/{knownGender}"
    path_params: [{name: chineseSurnameLatin, var: chinese_surname_latin}, {name: chineseGivenNameLatin, var: chinese_given_name_latin}, {name: knownGender, var: known_gender}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    chinese_surname_latin: $chinese_surname_latin, chinese_given_name_latin: $chinese_given_name_latin, known_gender: $known_gender
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a score for matching Chinese name ex. 王晓明 with a romanized name ex. Wang Xiaoming
#
# GET /api2/json/chineseNameMatch/{chineseSurnameLatin}/{chineseGivenNameLatin}/{chineseName}
# Returns: record<id: string, matchStatus: string, score: float, script: string>
# operationId: chineseNameMatch
export def "chinese-name-match" [
  chinese_surname_latin: string
  chinese_given_name_latin: string
  chinese_name: string
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
    path: "/api2/json/chineseNameMatch/{chineseSurnameLatin}/{chineseGivenNameLatin}/{chineseName}"
    path_params: [{name: chineseSurnameLatin, var: chinese_surname_latin}, {name: chineseGivenNameLatin, var: chinese_given_name_latin}, {name: chineseName, var: chinese_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    chinese_surname_latin: $chinese_surname_latin, chinese_given_name_latin: $chinese_given_name_latin, chinese_name: $chinese_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify Chinese name candidates, based on the romanized name (firstName = chineseGivenName; lastName=chineseSurname), ex. Wang Xiaoming
#
# POST /api2/json/chineseNameMatchBatch
# Returns: record<matchedNames: table<id: string, matchStatus: string, score: float, script: string>>
# operationId: chineseNameMatchBatch
export def "chinese-name-match-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name1?: record, name2?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/chineseNameMatchBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 20 UNITS PER NAME COUPLE] Infer several classifications for a cross border interaction between names (ex. remit, travel, intl com)
#
# GET /api2/json/corridor/{countryIso2From}/{firstNameFrom}/{lastNameFrom}/{countryIso2To}/{firstNameTo}/{lastNameTo}
# Returns: record<FirstLastNameDiasporaedOut: record<countryIso2: string, ethnicitiesTop: list<string>, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>, FirstLastNameGenderedOut: record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>, FirstLastNameOriginedOut: record<countriesOriginTop: list<string>, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string>, id: string, script: string>
# operationId: corridor
export def "corridor" [
  country_iso2_from: string
  first_name_from: string
  last_name_from: string
  country_iso2_to: string
  first_name_to: string
  last_name_to: string
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
    path: "/api2/json/corridor/{countryIso2From}/{firstNameFrom}/{lastNameFrom}/{countryIso2To}/{firstNameTo}/{lastNameTo}"
    path_params: [{name: countryIso2From, var: country_iso2_from}, {name: firstNameFrom, var: first_name_from}, {name: lastNameFrom, var: last_name_from}, {name: countryIso2To, var: country_iso2_to}, {name: firstNameTo, var: first_name_to}, {name: lastNameTo, var: last_name_to}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    country_iso2_from: $country_iso2_from, first_name_from: $first_name_from, last_name_from: $last_name_from, country_iso2_to: $country_iso2_to, first_name_to: $first_name_to, last_name_to: $last_name_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 20 UNITS PER NAME PAIR] Infer several classifications for up to 100 cross border interaction between names (ex. remit, travel, intl com)
#
# POST /api2/json/corridorBatch
# Returns: record<corridorFromTo: table<FirstLastNameDiasporaedOut: record, FirstLastNameGenderedOut: record, FirstLastNameOriginedOut: record, id: string, script: string>>
# operationId: corridorBatch
export def "corridor-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --corridor-from-to: list # item shape: {firstLastNameGeoFrom?: record, firstLastNameGeoTo?: record, id?: string}
  --facts: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/corridorBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: corridorFromTo, var: corridor_from_to}, {name: facts, var: facts}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    corridor_from_to: $corridor_from_to, facts: $facts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely country of residence of a personal full name, or one surname. Assumes names as they are in the country of residence OR the country of origin.
#
# GET /api2/json/country/{personalNameFull}
# Returns: record<countriesTop: list<string>, country: string, countryAlt: string, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, region: string, score: float, script: string, subRegion: string, topRegion: string>
# operationId: country
export def "country" [
  personal_name_full: string
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
    path: "/api2/json/country/{personalNameFull}"
    path_params: [{name: personalNameFull, var: personal_name_full}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    personal_name_full: $personal_name_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely country of residence of up to 100 personal full names, or surnames. Assumes names as they are in the country of residence OR the country of origin.
#
# POST /api2/json/countryBatch
# Returns: record<personalNames: table<countriesTop: list, country: string, countryAlt: string, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, region: string, score: float, script: string, subRegion: string, topRegion: string>>
# operationId: countryBatch
export def "country-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/countryBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 20 UNITS PER NAME] Infer the likely ethnicity/diaspora of a personal name, given a country of residence ISO2 code (ex. US, CA, AU, NZ etc.)
#
# GET /api2/json/diaspora/{countryIso2}/{firstName}/{lastName}
# Returns: record<countryIso2: string, ethnicitiesTop: list<string>, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>
# operationId: diaspora
export def "diaspora" [
  country_iso2: string
  first_name: string
  last_name: string
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
    path: "/api2/json/diaspora/{countryIso2}/{firstName}/{lastName}"
    path_params: [{name: countryIso2, var: country_iso2}, {name: firstName, var: first_name}, {name: lastName, var: last_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    country_iso2: $country_iso2, first_name: $first_name, last_name: $last_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 20 UNITS PER NAME] Infer the likely ethnicity/diaspora of up to 100 personal names, given a country of residence ISO2 code (ex. US, CA, AU, NZ etc.)
#
# POST /api2/json/diasporaBatch
# Returns: record<personalNames: table<countryIso2: string, ethnicitiesTop: list, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>>
# operationId: diasporaBatch
export def "diaspora-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/diasporaBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a just a fiven name, assuming default 'US' local context. Please use preferably full names and local geographic context for better accuracy.
#
# GET /api2/json/gender/{firstName}
# Returns: record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>
# operationId: gender
export def "gender" [
  first_name: string
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
    path: "/api2/json/gender/{firstName}"
    path_params: [{name: firstName, var: first_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a name.
#
# GET /api2/json/gender/{firstName}/{lastName}
# Returns: record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>
# operationId: gender_1
export def "gender-1" [
  first_name: string
  last_name: string
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
    path: "/api2/json/gender/{firstName}/{lastName}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of up to 100 names, detecting automatically the cultural context.
#
# POST /api2/json/genderBatch
# Returns: record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>>
# operationId: genderBatch
export def "gender-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/genderBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a Chinese full name ex. 王晓明
#
# GET /api2/json/genderChineseName/{chineseName}
# Returns: record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>
# operationId: genderChineseName
export def "gender-chinese-name" [
  chinese_name: string
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
    path: "/api2/json/genderChineseName/{chineseName}"
    path_params: [{name: chineseName, var: chinese_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    chinese_name: $chinese_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of up to 100 full names ex. 王晓明
#
# POST /api2/json/genderChineseNameBatch
# Returns: record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>>
# operationId: genderChineseNameBatch
export def "gender-chinese-name-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/genderChineseNameBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a Chinese name in LATIN (Pinyin).
#
# GET /api2/json/genderChineseNamePinyin/{chineseSurnameLatin}/{chineseGivenNameLatin}
# Returns: record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>
# operationId: genderChineseNamePinyin
export def "gender-chinese-name-pinyin" [
  chinese_surname_latin: string
  chinese_given_name_latin: string
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
    path: "/api2/json/genderChineseNamePinyin/{chineseSurnameLatin}/{chineseGivenNameLatin}"
    path_params: [{name: chineseSurnameLatin, var: chinese_surname_latin}, {name: chineseGivenNameLatin, var: chinese_given_name_latin}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    chinese_surname_latin: $chinese_surname_latin, chinese_given_name_latin: $chinese_given_name_latin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of up to 100 Chinese names in LATIN (Pinyin).
#
# POST /api2/json/genderChineseNamePinyinBatch
# Returns: record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>>
# operationId: genderChineseNamePinyinBatch
export def "gender-chinese-name-pinyin-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/genderChineseNamePinyinBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a full name, ex. John H. Smith
#
# GET /api2/json/genderFull/{fullName}
# Returns: record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>
# operationId: genderFull
export def "gender-full" [
  full_name: string
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
    path: "/api2/json/genderFull/{fullName}"
    path_params: [{name: fullName, var: full_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    full_name: $full_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of up to 100 full names, detecting automatically the cultural context.
#
# POST /api2/json/genderFullBatch
# Returns: record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>>
# operationId: genderFullBatch
export def "gender-full-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/genderFullBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a full name, given a local context (ISO2 country code).
#
# GET /api2/json/genderFullGeo/{fullName}/{countryIso2}
# Returns: record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>
# operationId: genderFullGeo
export def "gender-full-geo" [
  full_name: string
  country_iso2: string
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
    path: "/api2/json/genderFullGeo/{fullName}/{countryIso2}"
    path_params: [{name: fullName, var: full_name}, {name: countryIso2, var: country_iso2}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    full_name: $full_name, country_iso2: $country_iso2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of up to 100 full names, with a given cultural context (country ISO2 code).
#
# POST /api2/json/genderFullGeoBatch
# Returns: record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>>
# operationId: genderFullGeoBatch
export def "gender-full-geo-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/genderFullGeoBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a name, given a local context (ISO2 country code).
#
# GET /api2/json/genderGeo/{firstName}/{lastName}/{countryIso2}
# Returns: record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>
# operationId: genderGeo
export def "gender-geo" [
  first_name: string
  last_name: string
  country_iso2: string
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
    path: "/api2/json/genderGeo/{firstName}/{lastName}/{countryIso2}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: countryIso2, var: country_iso2}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name, country_iso2: $country_iso2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of up to 100 names, each given a local context (ISO2 country code).
#
# POST /api2/json/genderGeoBatch
# Returns: record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>>
# operationId: genderGeoBatch
export def "gender-geo-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/genderGeoBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a Japanese name in LATIN (Pinyin).
#
# GET /api2/json/genderJapaneseName/{japaneseSurname}/{japaneseGivenName}
# Returns: record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>
# operationId: genderJapaneseNamePinyin
export def "gender-japanese-name-pinyin" [
  japanese_surname: string
  japanese_given_name: string
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
    path: "/api2/json/genderJapaneseName/{japaneseSurname}/{japaneseGivenName}"
    path_params: [{name: japaneseSurname, var: japanese_surname}, {name: japaneseGivenName, var: japanese_given_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    japanese_surname: $japanese_surname, japanese_given_name: $japanese_given_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of up to 100 Japanese names in LATIN (Pinyin).
#
# POST /api2/json/genderJapaneseNameBatch
# Returns: record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>>
# operationId: genderJapaneseNamePinyinBatch
export def "gender-japanese-name-pinyin-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/genderJapaneseNameBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of a Japanese full name ex. 王晓明
#
# GET /api2/json/genderJapaneseNameFull/{japaneseName}
# Returns: record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>
# operationId: genderJapaneseNameFull
export def "gender-japanese-name-full" [
  japanese_name: string
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
    path: "/api2/json/genderJapaneseNameFull/{japaneseName}"
    path_params: [{name: japaneseName, var: japanese_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    japanese_name: $japanese_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely gender of up to 100 full names
#
# POST /api2/json/genderJapaneseNameFullBatch
# Returns: record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>>
# operationId: genderJapaneseNameFullBatch
export def "gender-japanese-name-full-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/genderJapaneseNameFullBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify japanese name candidates in KANJI, based on the romanized name (firstName = japaneseGivenName; lastName=japaneseSurname) with KNOWN gender, ex. Yamamoto Sanae
#
# POST /api2/json/japaneseNameGenderKanjiCandidatesBatch
# Returns: record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>
# operationId: japaneseNameGenderKanjiCandidatesBatch
export def "japanese-name-gender-kanji-candidates-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, gender?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/japaneseNameGenderKanjiCandidatesBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify japanese name candidates in KANJI, based on the romanized name ex. Yamamoto Sanae
#
# GET /api2/json/japaneseNameKanjiCandidates/{japaneseSurnameLatin}/{japaneseGivenNameLatin}
# Returns: record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>
# operationId: japaneseNameKanjiCandidates
export def "japanese-name-kanji-candidates" [
  japanese_surname_latin: string
  japanese_given_name_latin: string
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
    path: "/api2/json/japaneseNameKanjiCandidates/{japaneseSurnameLatin}/{japaneseGivenNameLatin}"
    path_params: [{name: japaneseSurnameLatin, var: japanese_surname_latin}, {name: japaneseGivenNameLatin, var: japanese_given_name_latin}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    japanese_surname_latin: $japanese_surname_latin, japanese_given_name_latin: $japanese_given_name_latin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify japanese name candidates in KANJI, based on the romanized name ex. Yamamoto Sanae - and a known gender.
#
# GET /api2/json/japaneseNameKanjiCandidates/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{knownGender}
# Returns: record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>
# operationId: japaneseNameKanjiCandidates_1
export def "japanese-name-kanji-candidates-1" [
  japanese_surname_latin: string
  japanese_given_name_latin: string
  known_gender: string
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
    path: "/api2/json/japaneseNameKanjiCandidates/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{knownGender}"
    path_params: [{name: japaneseSurnameLatin, var: japanese_surname_latin}, {name: japaneseGivenNameLatin, var: japanese_given_name_latin}, {name: knownGender, var: known_gender}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    japanese_surname_latin: $japanese_surname_latin, japanese_given_name_latin: $japanese_given_name_latin, known_gender: $known_gender
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identify japanese name candidates in KANJI, based on the romanized name (firstName = japaneseGivenName; lastName=japaneseSurname), ex. Yamamoto Sanae
#
# POST /api2/json/japaneseNameKanjiCandidatesBatch
# Returns: record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>
# operationId: japaneseNameKanjiCandidatesBatch
export def "japanese-name-kanji-candidates-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/japaneseNameKanjiCandidatesBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Romanize japanese name, based on the name in Kanji.
#
# GET /api2/json/japaneseNameLatinCandidates/{japaneseSurnameKanji}/{japaneseGivenNameKanji}
# Returns: record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string>
# operationId: japaneseNameLatinCandidates
export def "japanese-name-latin-candidates" [
  japanese_surname_kanji: string
  japanese_given_name_kanji: string
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
    path: "/api2/json/japaneseNameLatinCandidates/{japaneseSurnameKanji}/{japaneseGivenNameKanji}"
    path_params: [{name: japaneseSurnameKanji, var: japanese_surname_kanji}, {name: japaneseGivenNameKanji, var: japanese_given_name_kanji}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    japanese_surname_kanji: $japanese_surname_kanji, japanese_given_name_kanji: $japanese_given_name_kanji
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Romanize japanese names, based on the name in KANJI
#
# POST /api2/json/japaneseNameLatinCandidatesBatch
# Returns: record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>>
# operationId: japaneseNameLatinCandidatesBatch
export def "japanese-name-latin-candidates-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/japaneseNameLatinCandidatesBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a score for matching Japanese name in KANJI ex. 山本 早苗 with a romanized name ex. Yamamoto Sanae
#
# GET /api2/json/japaneseNameMatch/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{japaneseName}
# Returns: record<id: string, matchStatus: string, score: float, script: string>
# operationId: japaneseNameMatch
export def "japanese-name-match" [
  japanese_surname_latin: string
  japanese_given_name_latin: string
  japanese_name: string
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
    path: "/api2/json/japaneseNameMatch/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{japaneseName}"
    path_params: [{name: japaneseSurnameLatin, var: japanese_surname_latin}, {name: japaneseGivenNameLatin, var: japanese_given_name_latin}, {name: japaneseName, var: japanese_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    japanese_surname_latin: $japanese_surname_latin, japanese_given_name_latin: $japanese_given_name_latin, japanese_name: $japanese_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a score for matching a list of Japanese names in KANJI ex. 山本 早苗 with romanized names ex. Yamamoto Sanae
#
# POST /api2/json/japaneseNameMatchBatch
# Returns: record<matchedNames: table<id: string, matchStatus: string, score: float, script: string>>
# operationId: japaneseNameMatchBatch
export def "japanese-name-match-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name1?: record, name2?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/japaneseNameMatchBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [CREDITS 1 UNIT] Feedback loop to better perform matching Japanese name in KANJI ex. 山本 早苗 with a romanized name ex. Yamamoto Sanae
#
# GET /api2/json/japaneseNameMatchFeedbackLoop/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{japaneseName}
# Returns: record<feedbackCredits: int>
# operationId: japaneseNameMatchFeedbackLoop
export def "japanese-name-match-feedback-loop" [
  japanese_surname_latin: string
  japanese_given_name_latin: string
  japanese_name: string
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
    path: "/api2/json/japaneseNameMatchFeedbackLoop/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{japaneseName}"
    path_params: [{name: japaneseSurnameLatin, var: japanese_surname_latin}, {name: japaneseGivenNameLatin, var: japanese_given_name_latin}, {name: japaneseName, var: japanese_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    japanese_surname_latin: $japanese_surname_latin, japanese_given_name_latin: $japanese_given_name_latin, japanese_name: $japanese_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate/deactivate learning from a source.
#
# GET /api2/json/learnable/{source}/{learnable}/{token}
# Returns: record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool>
# operationId: learnable
export def "learnable" [
  source: string
  learnable: bool
  token_arg: string
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
    path: "/api2/json/learnable/{source}/{learnable}/{token}"
    path_params: [{name: source, var: source}, {name: learnable, var: learnable}, {name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    source: $source, learnable: $learnable, token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely type of a proper noun (personal name, brand name, place name etc.)
#
# GET /api2/json/nameType/{properNoun}
# Returns: record<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>
# operationId: nameType
export def "name-type" [
  proper_noun: string
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
    path: "/api2/json/nameType/{properNoun}"
    path_params: [{name: properNoun, var: proper_noun}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    proper_noun: $proper_noun
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely common type of up to 100 proper nouns (personal name, brand name, place name etc.)
#
# POST /api2/json/nameTypeBatch
# Returns: record<properNouns: table<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>>
# operationId: nameTypeBatch
export def "name-type-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --proper-nouns: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/nameTypeBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: properNouns, var: proper_nouns}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, proper_nouns: $proper_nouns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely type of a proper noun (personal name, brand name, place name etc.)
#
# GET /api2/json/nameTypeGeo/{properNoun}/{countryIso2}
# Returns: record<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>
# operationId: nameTypeGeo
export def "name-type-geo" [
  proper_noun: string
  country_iso2: string
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
    path: "/api2/json/nameTypeGeo/{properNoun}/{countryIso2}"
    path_params: [{name: properNoun, var: proper_noun}, {name: countryIso2, var: country_iso2}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    proper_noun: $proper_noun, country_iso2: $country_iso2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely common type of up to 100 proper nouns (personal name, brand name, place name etc.)
#
# POST /api2/json/nameTypeGeoBatch
# Returns: record<properNouns: table<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>>
# operationId: nameTypeGeoBatch
export def "name-type-geo-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --proper-nouns: list # item shape: {countryIso2?: string, id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/nameTypeGeoBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: properNouns, var: proper_nouns}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, proper_nouns: $proper_nouns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely country of origin of a personal name. Assumes names as they are in the country of origin. For US, CA, AU, NZ and other melting-pots : use 'diaspora' instead.
#
# GET /api2/json/origin/{firstName}/{lastName}
# Returns: record<countriesOriginTop: list<string>, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string>
# operationId: origin
export def "origin" [
  first_name: string
  last_name: string
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
    path: "/api2/json/origin/{firstName}/{lastName}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely country of origin of up to 100 names, detecting automatically the cultural context.
#
# POST /api2/json/originBatch
# Returns: record<personalNames: table<countriesOriginTop: list, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string>>
# operationId: originBatch
export def "origin-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/originBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely first/last name structure of a name, ex. 王晓明 -> 王(surname) 晓明(given name)
#
# GET /api2/json/parseChineseName/{chineseName}
# Returns: record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>
# operationId: parseChineseName
export def "parse-chinese-name" [
  chinese_name: string
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
    path: "/api2/json/parseChineseName/{chineseName}"
    path_params: [{name: chineseName, var: chinese_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    chinese_name: $chinese_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely first/last name structure of a name, ex. 王晓明 -> 王(surname) 晓明(given name).
#
# POST /api2/json/parseChineseNameBatch
# Returns: record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>
# operationId: parseChineseNameBatch
export def "parse-chinese-name-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/parseChineseNameBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely first/last name structure of a name, ex. 山本 早苗 or Yamamoto Sanae
#
# GET /api2/json/parseJapaneseName/{japaneseName}
# Returns: record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>
# operationId: parseJapaneseName
export def "parse-japanese-name" [
  japanese_name: string
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
    path: "/api2/json/parseJapaneseName/{japaneseName}"
    path_params: [{name: japaneseName, var: japanese_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    japanese_name: $japanese_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely first/last name structure of a name, ex. 山本 早苗 or Yamamoto Sanae
#
# POST /api2/json/parseJapaneseNameBatch
# Returns: record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>
# operationId: parseJapaneseNameBatch
export def "parse-japanese-name-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/parseJapaneseNameBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely first/last name structure of a name, ex. John Smith or SMITH, John or SMITH; John.
#
# GET /api2/json/parseName/{nameFull}
# Returns: record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>
# operationId: parseName
export def "parse-name" [
  name_full: string
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
    path: "/api2/json/parseName/{nameFull}"
    path_params: [{name: nameFull, var: name_full}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    name_full: $name_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely first/last name structure of a name, ex. John Smith or SMITH, John or SMITH; John. For better accuracy, provide a geographic context.
#
# GET /api2/json/parseName/{nameFull}/{countryIso2}
# Returns: record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>
# operationId: parseNameGeo
export def "parse-name-geo" [
  name_full: string
  country_iso2: string
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
    path: "/api2/json/parseName/{nameFull}/{countryIso2}"
    path_params: [{name: nameFull, var: name_full}, {name: countryIso2, var: country_iso2}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    name_full: $name_full, country_iso2: $country_iso2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely first/last name structure of a name, ex. John Smith or SMITH, John or SMITH; John.
#
# POST /api2/json/parseNameBatch
# Returns: record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>
# operationId: parseNameBatch
export def "parse-name-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/parseNameBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Infer the likely first/last name structure of a name, ex. John Smith or SMITH, John or SMITH; John. Giving a local context improves precision.
#
# POST /api2/json/parseNameGeoBatch
# Returns: record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>
# operationId: parseNameGeoBatch
export def "parse-name-geo-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/parseNameGeoBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 11 UNITS PER NAME] Infer the likely country and phone prefix, given a personal name and formatted / unformatted phone number.
#
# GET /api2/json/phoneCode/{firstName}/{lastName}/{phoneNumber}
# Returns: record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>
# operationId: phoneCode
export def "phone-code" [
  first_name: string
  last_name: string
  phone_number: string
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
    path: "/api2/json/phoneCode/{firstName}/{lastName}/{phoneNumber}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: phoneNumber, var: phone_number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name, phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 11 UNITS PER NAME] Infer the likely country and phone prefix, of up to 100 personal names, detecting automatically the local context given a name and formatted / unformatted phone number.
#
# POST /api2/json/phoneCodeBatch
# Returns: record<personalNamesWithPhoneNumbers: table<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>>
# operationId: phoneCodeBatch
export def "phone-code-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names-with-phone-numbers: list # item shape: {firstName?: string, id?: string, lastName?: string, phoneNumber?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/phoneCodeBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNamesWithPhoneNumbers, var: personal_names_with_phone_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names_with_phone_numbers: $personal_names_with_phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 11 UNITS PER NAME] Infer the likely phone prefix, given a personal name and formatted / unformatted phone number, with a local context (ISO2 country of residence).
#
# GET /api2/json/phoneCodeGeo/{firstName}/{lastName}/{phoneNumber}/{countryIso2}
# Returns: record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>
# operationId: phoneCodeGeo
export def "phone-code-geo" [
  first_name: string
  last_name: string
  phone_number: string
  country_iso2: string
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
    path: "/api2/json/phoneCodeGeo/{firstName}/{lastName}/{phoneNumber}/{countryIso2}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: phoneNumber, var: phone_number}, {name: countryIso2, var: country_iso2}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name, phone_number: $phone_number, country_iso2: $country_iso2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 11 UNITS PER NAME] Infer the likely country and phone prefix, of up to 100 personal names, with a local context (ISO2 country of residence).
#
# POST /api2/json/phoneCodeGeoBatch
# Returns: record<personalNamesWithPhoneNumbers: table<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>>
# operationId: phoneCodeGeoBatch
export def "phone-code-geo-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names-with-phone-numbers: list # item shape: {countryIso2?: string, countryIso2Alt?: string, firstName?: string, id?: string, lastName?: string, phoneNumber?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/phoneCodeGeoBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNamesWithPhoneNumbers, var: personal_names_with_phone_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names_with_phone_numbers: $personal_names_with_phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [CREDITS 1 UNIT] Feedback loop to better infer the likely phone prefix, given a personal name and formatted / unformatted phone number, with a local context (ISO2 country of residence).
#
# GET /api2/json/phoneCodeGeoFeedbackLoop/{firstName}/{lastName}/{phoneNumber}/{phoneNumberE164}/{countryIso2}
# Returns: record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>
# operationId: phoneCodeGeoFeedbackLoop
export def "phone-code-geo-feedback-loop" [
  first_name: string
  last_name: string
  phone_number: string
  phone_number_e164: string
  country_iso2: string
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
    path: "/api2/json/phoneCodeGeoFeedbackLoop/{firstName}/{lastName}/{phoneNumber}/{phoneNumberE164}/{countryIso2}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: phoneNumber, var: phone_number}, {name: phoneNumberE164, var: phone_number_e164}, {name: countryIso2, var: country_iso2}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name, phone_number: $phone_number, phone_number_e164: $phone_number_e164, country_iso2: $country_iso2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Romanize the Chinese name to Pinyin, ex. 王晓明 -> Wang (surname) Xiaoming (given name)
#
# GET /api2/json/pinyinChineseName/{chineseName}
# Returns: record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>
# operationId: pinyinChineseName
export def "pinyin-chinese-name" [
  chinese_name: string
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
    path: "/api2/json/pinyinChineseName/{chineseName}"
    path_params: [{name: chineseName, var: chinese_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    chinese_name: $chinese_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Romanize a list of Chinese name to Pinyin, ex. 王晓明 -> Wang (surname) Xiaoming (given name).
#
# POST /api2/json/pinyinChineseNameBatch
# Returns: record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>>
# operationId: pinyinChineseNameBatch
export def "pinyin-chinese-name-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/pinyinChineseNameBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Print basic source statistics.
#
# GET /api2/json/regions
# Returns: record<countriesAndRegions: table<countryFIPS: string, countryISO2: string, countryISO3: string, countryName: string, countryNumCode: string, region: string, subregion: string, topregion: string>>
# operationId: regions
export def "regions" [
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
    path: "/api2/json/regions"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely religion of a personal full name. NB: only for INDIA (as of current version).
#
# GET /api2/json/religionFull/{countryIso2}/{subDivisionIso31662}/{personalNameFull}
# Returns: record<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list<string>, score: float, script: string>
# operationId: religionFull
export def "religion-full" [
  country_iso2: string
  sub_division_iso31662: string
  personal_name_full: string
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
    path: "/api2/json/religionFull/{countryIso2}/{subDivisionIso31662}/{personalNameFull}"
    path_params: [{name: countryIso2, var: country_iso2}, {name: subDivisionIso31662, var: sub_division_iso31662}, {name: personalNameFull, var: personal_name_full}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    country_iso2: $country_iso2, sub_division_iso31662: $sub_division_iso31662, personal_name_full: $personal_name_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely religion of up to 100 personal full names. NB: only for India as of currently.
#
# POST /api2/json/religionFullBatch
# Returns: record<personalNames: table<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list, score: float, script: string>>
# operationId: religionFullBatch
export def "religion-full-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, id?: string, name?: string, subdivisionIso?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/religionFullBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely religion of a personal Indian full name, provided the Indian state or Union territory (NB/ this can be inferred using the subclassification endpoint).
#
# GET /api2/json/religionIndianFull/{subDivisionIso31662}/{personalNameFull}
# Returns: record<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list<string>, score: float, script: string>
# operationId: religion
export def "religion" [
  sub_division_iso31662: string
  personal_name_full: string
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
    path: "/api2/json/religionIndianFull/{subDivisionIso31662}/{personalNameFull}"
    path_params: [{name: subDivisionIso31662, var: sub_division_iso31662}, {name: personalNameFull, var: personal_name_full}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    sub_division_iso31662: $sub_division_iso31662, personal_name_full: $personal_name_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely religion of up to 100 personal full Indian names, provided the subclassification at State or Union territory level (NB/ can be inferred using the subclassification endpoint).
#
# POST /api2/json/religionIndianFullBatch
# Returns: record<personalNames: table<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list, score: float, script: string>>
# operationId: religionIndianFullBatch
export def "religion-indian-full-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string, subdivisionIso?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/religionIndianFullBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the current software version
#
# GET /api2/json/softwareVersion
# Returns: record<softwareNameAndVersion: string, softwareVersion: list<int>>
# operationId: softwareVersion
export def "software-version" [
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
    path: "/api2/json/softwareVersion"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely origin of a name at a country subclassification level (state or regeion). Initially, this is only supported for India (ISO2 code 'IN').
#
# GET /api2/json/subclassification/{countryIso2}/{firstName}/{lastName}
# Returns: record<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list<string>>
# operationId: subclassification
export def "subclassification" [
  country_iso2: string
  first_name: string
  last_name: string
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
    path: "/api2/json/subclassification/{countryIso2}/{firstName}/{lastName}"
    path_params: [{name: countryIso2, var: country_iso2}, {name: firstName, var: first_name}, {name: lastName, var: last_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    country_iso2: $country_iso2, first_name: $first_name, last_name: $last_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely origin of a list of up to 100 names at a country subclassification level (state or regeion). Initially, this is only supported for India (ISO2 code 'IN').
#
# POST /api2/json/subclassificationBatch
# Returns: record<personalNames: table<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list>>
# operationId: subclassificationBatch
export def "subclassification-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/subclassificationBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely Indian state of Union territory according to ISO 3166-2:IN based on the name.
#
# GET /api2/json/subclassificationIndian/{firstName}/{lastName}
# Returns: record<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list<string>>
# operationId: subclassificationIndian
export def "subclassification-indian" [
  first_name: string
  last_name: string
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
    path: "/api2/json/subclassificationIndian/{firstName}/{lastName}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer the likely Indian state of Union territory according to ISO 3166-2:IN based on a list of up to 100 names.
#
# POST /api2/json/subclassificationIndianBatch
# Returns: record<personalNames: table<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list>>
# operationId: subclassificationIndianBatch
export def "subclassification-indian-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/subclassificationIndianBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Print the taxonomy classes valid for the given classifier.
#
# GET /api2/json/taxonomyClasses/{classifierName}
# Returns: record<classifierName: string, classifyingScripts: list<string>, taxonomyClasses: list<string>>
# operationId: taxonomyClasses
export def "taxonomy-classes" [
  classifier_name: string
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
    path: "/api2/json/taxonomyClasses/{classifierName}"
    path_params: [{name: classifierName, var: classifier_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    classifier_name: $classifier_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer a US resident's likely race/ethnicity according to US Census taxonomy W_NL (white, non latino), HL (hispano latino), A (asian, non latino), B_NL (black, non latino). Optionally add header X-OPTION-USRACEETHNICITY-TAXONOMY: USRACEETHNICITY-6CLASSES for two additional classes, AI_AN (American Indian or Alaskan Native) and PI (Pacific Islander).
#
# GET /api2/json/usRaceEthnicity/{firstName}/{lastName}
# Returns: record<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list<string>, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>
# operationId: usRaceEthnicity
export def "us-race-ethnicity" [
  first_name: string
  last_name: string
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
    path: "/api2/json/usRaceEthnicity/{firstName}/{lastName}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer up-to 100 US resident's likely race/ethnicity according to US Census taxonomy. Output is W_NL (white, non latino), HL (hispano latino), A (asian, non latino), B_NL (black, non latino). Optionally add header X-OPTION-USRACEETHNICITY-TAXONOMY: USRACEETHNICITY-6CLASSES for two additional classes, AI_AN (American Indian or Alaskan Native) and PI (Pacific Islander).
#
# POST /api2/json/usRaceEthnicityBatch
# Returns: record<personalNames: table<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>>
# operationId: usRaceEthnicityBatch
export def "us-race-ethnicity-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/usRaceEthnicityBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer a US resident's likely race/ethnicity according to US Census taxonomy, using (optional) ZIP5 code info. Output is W_NL (white, non latino), HL (hispano latino), A (asian, non latino), B_NL (black, non latino). Optionally add header X-OPTION-USRACEETHNICITY-TAXONOMY: USRACEETHNICITY-6CLASSES for two additional classes, AI_AN (American Indian or Alaskan Native) and PI (Pacific Islander).
#
# GET /api2/json/usRaceEthnicityZIP5/{firstName}/{lastName}/{zip5Code}
# Returns: record<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list<string>, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>
# operationId: usRaceEthnicityZIP5
export def "us-race-ethnicity-zip5" [
  first_name: string
  last_name: string
  zip5_code: string
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
    path: "/api2/json/usRaceEthnicityZIP5/{firstName}/{lastName}/{zip5Code}"
    path_params: [{name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: zip5Code, var: zip5_code}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    first_name: $first_name, last_name: $last_name, zip5_code: $zip5_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [USES 10 UNITS PER NAME] Infer up-to 100 US resident's likely race/ethnicity according to US Census taxonomy, with (optional) ZIP code. Output is W_NL (white, non latino), HL (hispano latino), A (asian, non latino), B_NL (black, non latino). Optionally add header X-OPTION-USRACEETHNICITY-TAXONOMY: USRACEETHNICITY-6CLASSES for two additional classes, AI_AN (American Indian or Alaskan Native) and PI (Pacific Islander).
#
# POST /api2/json/usZipRaceEthnicityBatch
# Returns: record<personalNames: table<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>>
# operationId: usZipRaceEthnicityBatch
export def "us-zip-race-ethnicity-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string, zipCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api2/json/usZipRaceEthnicityBatch"
    body: {content_type: "application/json", kind: json, fields: [{name: facts, var: facts}, {name: personalNames, var: personal_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    facts: $facts, personal_names: $personal_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
