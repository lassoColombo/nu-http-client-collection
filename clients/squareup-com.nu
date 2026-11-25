# Auto-generated client for Square Connect API v2.0
# Source: https://api.apis.guru/v2/specs/squareup.com/2.0/openapi.json
# Auth: --token flag or $env.SQUARE_CONNECT_API_TOKEN

const CLIENT = {
  base_url: "https://connect.squareup.com"
  token_env_var: "SQUARE_CONNECT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
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

def base-url-completer [] { ["https://connect.squareup.com"] }
def auth-scheme-completer [] { ["bearer" "none"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-mobile-authorization-code: "record<authorization_code: string, error: record<category: string, code: string, detail: string, field: string>, expires_at: string>"
    renew-token: "record<access_token: string, expires_at: string, merchant_id: string, plan_id: string, subscription_id: string, token_type: string>"
    revoke-token: "record<success: bool>"
    obtain-token: "record<access_token: string, expires_at: string, id_token: string, merchant_id: string, plan_id: string, refresh_token: string, short_lived: bool, subscription_id: string, token_type: string>"
    list-employees: "table<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string>"
    create-employee: "record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string>"
    retrieve-employee: "record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string>"
    update-employee: "record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string>"
    list-employee-roles: "table<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string>"
    create-employee-role: "record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string>"
    retrieve-employee-role: "record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string>"
    update-employee-role: "record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string>"
    list-orders: "table<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: list<record>, expires_at: string, id: string, order_history: list<record>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record, settled_at: string, tendered_at: string, tendered_money: record, total_money: record, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string>"
    retrieve-order: "record<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: table<category: string, code: string, detail: string, field: string>, expires_at: string, id: string, order_history: table<action: string, created_at: string>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record<amount: int, currency_code: string>, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, settled_at: string, tendered_at: string, tendered_money: record<amount: int, currency_code: string>, total_money: record<amount: int, currency_code: string>, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string>"
    update-order: "record<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: table<category: string, code: string, detail: string, field: string>, expires_at: string, id: string, order_history: table<action: string, created_at: string>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record<amount: int, currency_code: string>, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, settled_at: string, tendered_at: string, tendered_money: record<amount: int, currency_code: string>, total_money: record<amount: int, currency_code: string>, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string>"
    list-payments: "table<additive_tax: list<record>, additive_tax_money: record<amount: int, currency_code: string>, created_at: string, creator_id: string, device: record<id: string, name: string>, discount_money: record<amount: int, currency_code: string>, gross_sales_money: record<amount: int, currency_code: string>, id: string, inclusive_tax: list<record>, inclusive_tax_money: record<amount: int, currency_code: string>, is_partial: bool, itemizations: list<record>, merchant_id: string, net_sales_money: record<amount: int, currency_code: string>, net_total_money: record<amount: int, currency_code: string>, payment_url: string, processing_fee_money: record<amount: int, currency_code: string>, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, refunds: list<record>, surcharge_money: record<amount: int, currency_code: string>, surcharges: list<record>, swedish_rounding_money: record<amount: int, currency_code: string>, tax_money: record<amount: int, currency_code: string>, tender: list<record>, tip_money: record<amount: int, currency_code: string>, total_collected_money: record<amount: int, currency_code: string>>"
    retrieve-payment: "record<additive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, additive_tax_money: record<amount: int, currency_code: string>, created_at: string, creator_id: string, device: record<id: string, name: string>, discount_money: record<amount: int, currency_code: string>, gross_sales_money: record<amount: int, currency_code: string>, id: string, inclusive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, inclusive_tax_money: record<amount: int, currency_code: string>, is_partial: bool, itemizations: table<discount_money: record, discounts: list, gross_sales_money: record, item_detail: record, item_variation_name: string, itemization_type: string, modifiers: list, name: string, net_sales_money: record, notes: string, quantity: float, single_quantity_money: record, taxes: list, total_money: record>, merchant_id: string, net_sales_money: record<amount: int, currency_code: string>, net_total_money: record<amount: int, currency_code: string>, payment_url: string, processing_fee_money: record<amount: int, currency_code: string>, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, refunds: table<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: list, refunded_additive_tax_money: record, refunded_discount_money: record, refunded_inclusive_tax: list, refunded_inclusive_tax_money: record, refunded_money: record, refunded_processing_fee_money: record, refunded_surcharge_money: record, refunded_surcharges: list, refunded_tax_money: record, refunded_tip_money: record, type: string>, surcharge_money: record<amount: int, currency_code: string>, surcharges: table<amount_money: record, applied_money: record, name: string, rate: string, surcharge_id: string, taxable: bool, taxes: list, type: string>, swedish_rounding_money: record<amount: int, currency_code: string>, tax_money: record<amount: int, currency_code: string>, tender: table<card_brand: string, change_back_money: record, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record, settled_at: string, tendered_at: string, tendered_money: record, total_money: record, type: string>, tip_money: record<amount: int, currency_code: string>, total_collected_money: record<amount: int, currency_code: string>>"
    list-refunds: "table<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: list<record>, refunded_additive_tax_money: record<amount: int, currency_code: string>, refunded_discount_money: record<amount: int, currency_code: string>, refunded_inclusive_tax: list<record>, refunded_inclusive_tax_money: record<amount: int, currency_code: string>, refunded_money: record<amount: int, currency_code: string>, refunded_processing_fee_money: record<amount: int, currency_code: string>, refunded_surcharge_money: record<amount: int, currency_code: string>, refunded_surcharges: list<record>, refunded_tax_money: record<amount: int, currency_code: string>, refunded_tip_money: record<amount: int, currency_code: string>, type: string>"
    create-refund: "record<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, refunded_additive_tax_money: record<amount: int, currency_code: string>, refunded_discount_money: record<amount: int, currency_code: string>, refunded_inclusive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, refunded_inclusive_tax_money: record<amount: int, currency_code: string>, refunded_money: record<amount: int, currency_code: string>, refunded_processing_fee_money: record<amount: int, currency_code: string>, refunded_surcharge_money: record<amount: int, currency_code: string>, refunded_surcharges: table<amount_money: record, applied_money: record, name: string, rate: string, surcharge_id: string, taxable: bool, taxes: list, type: string>, refunded_tax_money: record<amount: int, currency_code: string>, refunded_tip_money: record<amount: int, currency_code: string>, type: string>"
    list-settlements: "table<bank_account_id: string, entries: list<record>, id: string, initiated_at: string, status: string, total_money: record<amount: int, currency_code: string>>"
    retrieve-settlement: "record<bank_account_id: string, entries: table<amount_money: record, fee_money: record, payment_id: string, type: string>, id: string, initiated_at: string, status: string, total_money: record<amount: int, currency_code: string>>"
    register-domain: "record<errors: table<category: string, code: string, detail: string, field: string>, status: string>"
    list-bank-accounts: "record<bank_accounts: table<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    get-bank-account-by-v1-id: "record<bank_account: record<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    get-bank-account: "record<bank_account: record<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    create-booking: "record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    search-availability: "record<availabilities: table<appointment_segments: list, location_id: string, start_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-business-booking-profile: "record<business_booking_profile: record<allow_user_cancel: bool, booking_enabled: bool, booking_policy: string, business_appointment_settings: record<alignment_time: string, any_team_member_booking_enabled: bool, cancellation_fee_money: record, cancellation_policy: string, cancellation_policy_text: string, cancellation_window_seconds: int, location_types: list, max_appointments_per_day_limit: int, max_appointments_per_day_limit_type: string, max_booking_lead_time_seconds: int, min_booking_lead_time_seconds: int, multiple_service_booking_enabled: bool, skip_booking_flow_staff_selection: bool>, created_at: string, customer_timezone_choice: string, seller_id: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-team-member-booking-profiles: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_member_booking_profiles: table<description: string, display_name: string, is_bookable: bool, profile_image_url: string, team_member_id: string>>"
    retrieve-team-member-booking-profile: "record<errors: table<category: string, code: string, detail: string, field: string>, team_member_booking_profile: record<description: string, display_name: string, is_bookable: bool, profile_image_url: string, team_member_id: string>>"
    retrieve-booking: "record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    update-booking: "record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    cancel-booking: "record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-cards: "record<cards: table<billing_address: record, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    create-card: "record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-card: "record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    disable-card: "record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-cash-drawer-shifts: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, items: table<closed_at: string, closed_cash_money: record, description: string, ended_at: string, expected_cash_money: record, id: string, opened_at: string, opened_cash_money: record, state: string>>"
    retrieve-cash-drawer-shift: "record<cash_drawer_shift: record<cash_paid_in_money: record<amount: int, currency: string>, cash_paid_out_money: record<amount: int, currency: string>, cash_payment_money: record<amount: int, currency: string>, cash_refunds_money: record<amount: int, currency: string>, closed_at: string, closed_cash_money: record<amount: int, currency: string>, closing_employee_id: string, description: string, device: record<id: string, name: string>, employee_ids: list<string>, ended_at: string, ending_employee_id: string, expected_cash_money: record<amount: int, currency: string>, id: string, opened_at: string, opened_cash_money: record<amount: int, currency: string>, opening_employee_id: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-cash-drawer-shift-events: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, events: table<created_at: string, description: string, employee_id: string, event_money: record, event_type: string, id: string>>"
    batch-delete-catalog-objects: "record<deleted_at: string, deleted_object_ids: list<string>, errors: table<category: string, code: string, detail: string, field: string>>"
    batch-retrieve-catalog-objects: "record<errors: table<category: string, code: string, detail: string, field: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>>"
    batch-upsert-catalog-objects: "record<errors: table<category: string, code: string, detail: string, field: string>, id_mappings: table<client_object_id: string, object_id: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, updated_at: string>"
    catalog-info: "record<errors: table<category: string, code: string, detail: string, field: string>, limits: record<batch_delete_max_object_ids: int, batch_retrieve_max_object_ids: int, batch_upsert_max_objects_per_batch: int, batch_upsert_max_total_objects: int, search_max_page_limit: int, update_item_modifier_lists_max_item_ids: int, update_item_modifier_lists_max_modifier_lists_to_disable: int, update_item_modifier_lists_max_modifier_lists_to_enable: int, update_item_taxes_max_item_ids: int, update_item_taxes_max_taxes_to_disable: int, update_item_taxes_max_taxes_to_enable: int>, standard_unit_description_group: record<language_code: string, standard_unit_descriptions: list<record>>>"
    list-catalog: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>>"
    upsert-catalog-object: "record<catalog_object: record<absent_at_location_ids: list<string>, catalog_v1_ids: list<record>, category_data: record<name: string>, custom_attribute_definition_data: record<allowed_object_types: list, app_visibility: string, custom_attribute_usage_count: int, description: string, key: string, name: string, number_config: record, selection_config: record, seller_visibility: string, source_application: record, string_config: record, type: string>, custom_attribute_values: record, discount_data: record<amount_money: record, discount_type: string, label_color: string, modify_tax_basis: string, name: string, percentage: string, pin_required: bool>, id: string, image_data: record<caption: string, name: string, url: string>, image_id: string, is_deleted: bool, item_data: record<abbreviation: string, available_electronically: bool, available_for_pickup: bool, available_online: bool, category_id: string, description: string, item_options: list, label_color: string, modifier_list_info: list, name: string, product_type: string, skip_modifier_screen: bool, sort_name: string, tax_ids: list, variations: list>, item_option_data: record<description: string, display_name: string, name: string, show_colors: bool, values: list>, item_option_value_data: record<color: string, description: string, item_option_id: string, name: string, ordinal: int>, item_variation_data: record<available_for_booking: bool, inventory_alert_threshold: int, inventory_alert_type: string, item_id: string, item_option_values: list, location_overrides: list, measurement_unit_id: string, name: string, ordinal: int, price_money: record, pricing_type: string, service_duration: int, sku: string, stockable: bool, stockable_conversion: record, team_member_ids: list, track_inventory: bool, upc: string, user_data: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, modifier_data: record<modifier_list_id: string, name: string, ordinal: int, price_money: record>, modifier_list_data: record<modifiers: list, name: string, ordinal: int, selection_type: string>, present_at_all_locations: bool, present_at_location_ids: list<string>, pricing_rule_data: record<apply_products_id: string, customer_group_ids_any: list, discount_id: string, exclude_products_id: string, exclude_strategy: string, match_products_id: string, name: string, time_period_ids: list, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string>, product_set_data: record<all_products: bool, name: string, product_ids_all: list, product_ids_any: list, quantity_exact: int, quantity_max: int, quantity_min: int>, quick_amounts_settings_data: record<amounts: list, eligible_for_auto_amounts: bool, option: string>, subscription_plan_data: record<name: string, phases: list>, tax_data: record<applies_to_custom_amounts: bool, calculation_phase: string, enabled: bool, inclusion_type: string, name: string, percentage: string>, time_period_data: record<event: string>, type: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>, id_mappings: table<client_object_id: string, object_id: string>>"
    delete-catalog-object: "record<deleted_at: string, deleted_object_ids: list<string>, errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-catalog-object: "record<errors: table<category: string, code: string, detail: string, field: string>, object: record<absent_at_location_ids: list<string>, catalog_v1_ids: list<record>, category_data: record<name: string>, custom_attribute_definition_data: record<allowed_object_types: list, app_visibility: string, custom_attribute_usage_count: int, description: string, key: string, name: string, number_config: record, selection_config: record, seller_visibility: string, source_application: record, string_config: record, type: string>, custom_attribute_values: record, discount_data: record<amount_money: record, discount_type: string, label_color: string, modify_tax_basis: string, name: string, percentage: string, pin_required: bool>, id: string, image_data: record<caption: string, name: string, url: string>, image_id: string, is_deleted: bool, item_data: record<abbreviation: string, available_electronically: bool, available_for_pickup: bool, available_online: bool, category_id: string, description: string, item_options: list, label_color: string, modifier_list_info: list, name: string, product_type: string, skip_modifier_screen: bool, sort_name: string, tax_ids: list, variations: list>, item_option_data: record<description: string, display_name: string, name: string, show_colors: bool, values: list>, item_option_value_data: record<color: string, description: string, item_option_id: string, name: string, ordinal: int>, item_variation_data: record<available_for_booking: bool, inventory_alert_threshold: int, inventory_alert_type: string, item_id: string, item_option_values: list, location_overrides: list, measurement_unit_id: string, name: string, ordinal: int, price_money: record, pricing_type: string, service_duration: int, sku: string, stockable: bool, stockable_conversion: record, team_member_ids: list, track_inventory: bool, upc: string, user_data: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, modifier_data: record<modifier_list_id: string, name: string, ordinal: int, price_money: record>, modifier_list_data: record<modifiers: list, name: string, ordinal: int, selection_type: string>, present_at_all_locations: bool, present_at_location_ids: list<string>, pricing_rule_data: record<apply_products_id: string, customer_group_ids_any: list, discount_id: string, exclude_products_id: string, exclude_strategy: string, match_products_id: string, name: string, time_period_ids: list, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string>, product_set_data: record<all_products: bool, name: string, product_ids_all: list, product_ids_any: list, quantity_exact: int, quantity_max: int, quantity_min: int>, quick_amounts_settings_data: record<amounts: list, eligible_for_auto_amounts: bool, option: string>, subscription_plan_data: record<name: string, phases: list>, tax_data: record<applies_to_custom_amounts: bool, calculation_phase: string, enabled: bool, inclusion_type: string, name: string, percentage: string>, time_period_data: record<event: string>, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>>"
    search-catalog-objects: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, latest_time: string, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>>"
    search-catalog-items: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, items: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, matched_variation_ids: list<string>>"
    update-item-modifier-lists: "record<errors: table<category: string, code: string, detail: string, field: string>, updated_at: string>"
    update-item-taxes: "record<errors: table<category: string, code: string, detail: string, field: string>, updated_at: string>"
    list-customers: "record<cursor: string, customers: table<address: record, birthday: string, cards: list, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list, id: string, nickname: string, note: string, phone_number: string, preferences: record, reference_id: string, segment_ids: list, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    create-customer: "record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-customer-groups: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, groups: table<created_at: string, id: string, name: string, updated_at: string>>"
    create-customer-group: "record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>>"
    delete-customer-group: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-customer-group: "record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>>"
    update-customer-group: "record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>>"
    search-customers: "record<cursor: string, customers: table<address: record, birthday: string, cards: list, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list, id: string, nickname: string, note: string, phone_number: string, preferences: record, reference_id: string, segment_ids: list, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-customer-segments: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, segments: table<created_at: string, id: string, name: string, updated_at: string>>"
    retrieve-customer-segment: "record<errors: table<category: string, code: string, detail: string, field: string>, segment: record<created_at: string, id: string, name: string, updated_at: string>>"
    delete-customer: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-customer: "record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    update-customer: "record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    create-customer-card: "record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    delete-customer-card: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    remove-group-from-customer: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    add-group-to-customer: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    list-device-codes: "record<cursor: string, device_codes: table<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    create-device-code: "record<device_code: record<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    get-device-code: "record<device_code: record<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-disputes: "record<cursor: string, disputes: table<amount_money: record, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record, due_at: string, evidence_ids: list, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-dispute: "record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    accept-dispute: "record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-dispute-evidence: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, evidence: table<dispute_id: string, evidence_file: record, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>>"
    create-dispute-evidence-text: "record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>>"
    delete-dispute-evidence: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-dispute-evidence: "record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>>"
    submit-evidence: "record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    get-v2-employees: "record<cursor: string, employees: table<created_at: string, email: string, first_name: string, id: string, is_owner: bool, last_name: string, location_ids: list, phone_number: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    get-v2-employees-id: "record<employee: record<created_at: string, email: string, first_name: string, id: string, is_owner: bool, last_name: string, location_ids: list<string>, phone_number: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-gift-cards: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, gift_cards: table<balance_money: record, created_at: string, customer_ids: list, gan: string, gan_source: any, id: string, state: any, type: any>>"
    create-gift-card: "record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>"
    list-gift-card-activities: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, gift_card_activities: table<activate_activity_details: record, adjust_decrement_activity_details: record, adjust_increment_activity_details: record, block_activity_details: record, clear_balance_activity_details: record, created_at: string, deactivate_activity_details: record, gift_card_balance_money: record, gift_card_gan: string, gift_card_id: string, id: string, import_activity_details: record, import_reversal_activity_details: record, load_activity_details: record, location_id: string, redeem_activity_details: record, refund_activity_details: record, type: any, unblock_activity_details: record, unlinked_activity_refund_activity_details: record>>"
    create-gift-card-activity: "record<errors: table<category: string, code: string, detail: string, field: string>, gift_card_activity: record<activate_activity_details: record<amount_money: record, buyer_payment_instrument_ids: list, line_item_uid: string, order_id: string, reference_id: string>, adjust_decrement_activity_details: record<amount_money: record, reason: any>, adjust_increment_activity_details: record<amount_money: record, reason: any>, block_activity_details: record<reason: any>, clear_balance_activity_details: record<reason: any>, created_at: string, deactivate_activity_details: record<reason: any>, gift_card_balance_money: record<amount: int, currency: string>, gift_card_gan: string, gift_card_id: string, id: string, import_activity_details: record<amount_money: record>, import_reversal_activity_details: record<amount_money: record>, load_activity_details: record<amount_money: record, buyer_payment_instrument_ids: list, line_item_uid: string, order_id: string, reference_id: string>, location_id: string, redeem_activity_details: record<amount_money: record, payment_id: string, reference_id: string>, refund_activity_details: record<amount_money: record, payment_id: string, redeem_activity_id: string, reference_id: string>, type: any, unblock_activity_details: record<reason: any>, unlinked_activity_refund_activity_details: record<amount_money: record, payment_id: string, reference_id: string>>>"
    retrieve-gift-card-from-gan: "record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>"
    retrieve-gift-card-from-nonce: "record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>"
    link-customer-to-gift-card: "record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>"
    unlink-customer-from-gift-card: "record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>"
    retrieve-gift-card: "record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>"
    deprecated-retrieve-inventory-adjustment: "record<adjustment: record<adjustment_group: record<from_state: string, id: string, root_adjustment_id: string, to_state: string>, catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_state: string, goods_receipt_id: string, id: string, location_id: string, occurred_at: string, purchase_order_id: string, quantity: string, reference_id: string, refund_id: string, source: record<application_id: string, name: string, product: string>, to_state: string, total_price_money: record<amount: int, currency: string>, transaction_id: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-inventory-adjustment: "record<adjustment: record<adjustment_group: record<from_state: string, id: string, root_adjustment_id: string, to_state: string>, catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_state: string, goods_receipt_id: string, id: string, location_id: string, occurred_at: string, purchase_order_id: string, quantity: string, reference_id: string, refund_id: string, source: record<application_id: string, name: string, product: string>, to_state: string, total_price_money: record<amount: int, currency: string>, transaction_id: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    deprecated-batch-change-inventory: "record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    deprecated-batch-retrieve-inventory-changes: "record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    deprecated-batch-retrieve-inventory-counts: "record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    batch-change-inventory: "record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    batch-retrieve-inventory-changes: "record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    batch-retrieve-inventory-counts: "record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    deprecated-retrieve-inventory-physical-count: "record<count: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, id: string, location_id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-inventory-physical-count: "record<count: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, id: string, location_id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-inventory-transfer: "record<errors: table<category: string, code: string, detail: string, field: string>, transfer: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_location_id: string, id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string, to_location_id: string>>"
    retrieve-inventory-count: "record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-inventory-changes: "record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    list-invoices: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, invoices: table<accepted_payment_methods: record, created_at: string, custom_fields: list, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record, order_id: string, payment_requests: list, primary_recipient: record, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>"
    create-invoice: "record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>"
    search-invoices: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, invoices: table<accepted_payment_methods: record, created_at: string, custom_fields: list, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record, order_id: string, payment_requests: list, primary_recipient: record, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>"
    delete-invoice: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    get-invoice: "record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>"
    update-invoice: "record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>"
    cancel-invoice: "record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>"
    publish-invoice: "record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>"
    list-break-types: "record<break_types: table<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    create-break-type: "record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    delete-break-type: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    get-break-type: "record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    update-break-type: "record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>"
    list-employee-wages: "record<cursor: string, employee_wages: table<employee_id: string, hourly_rate: record, id: string, title: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    get-employee-wage: "record<employee_wage: record<employee_id: string, hourly_rate: record<amount: int, currency: string>, id: string, title: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    create-shift: "record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>>"
    search-shifts: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, shifts: table<breaks: list, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record>>"
    delete-shift: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    get-shift: "record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>>"
    update-shift: "record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>>"
    list-team-member-wages: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_member_wages: table<hourly_rate: record, id: string, team_member_id: string, title: string>>"
    get-team-member-wage: "record<errors: table<category: string, code: string, detail: string, field: string>, team_member_wage: record<hourly_rate: record<amount: int, currency: string>, id: string, team_member_id: string, title: string>>"
    list-workweek-configs: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, workweek_configs: table<created_at: string, id: string, start_of_day_local_time: string, start_of_week: string, updated_at: string, version: int>>"
    update-workweek-config: "record<errors: table<category: string, code: string, detail: string, field: string>, workweek_config: record<created_at: string, id: string, start_of_day_local_time: string, start_of_week: string, updated_at: string, version: int>>"
    list-locations: "record<errors: table<category: string, code: string, detail: string, field: string>, locations: table<address: record, business_email: string, business_hours: record, business_name: string, capabilities: list, coordinates: record, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record, timezone: string, twitter_username: string, type: string, website_url: string>>"
    create-location: "record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>>"
    retrieve-location: "record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>>"
    update-location: "record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>>"
    create-checkout: "record<checkout: record<additional_recipients: list<record>, ask_for_shipping_address: bool, checkout_page_url: string, created_at: string, id: string, merchant_support_email: string, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>, pre_populate_buyer_email: string, pre_populate_shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, redirect_url: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    get-v2-locations-location-id-refunds: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<additional_recipients: list, amount_money: record, created_at: string, id: string, location_id: string, processing_fee_money: record, reason: string, status: string, tender_id: string, transaction_id: string>>"
    list-transactions: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, transactions: table<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list, shipping_address: record, tenders: list>>"
    charge: "record<errors: table<category: string, code: string, detail: string, field: string>, transaction: record<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list<record>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, tenders: list<record>>>"
    retrieve-transaction: "record<errors: table<category: string, code: string, detail: string, field: string>, transaction: record<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list<record>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, tenders: list<record>>>"
    capture-transaction: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    post-v2-locations-location-id-transactions-transaction-id-refund: "record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<additional_recipients: list<record>, amount_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, processing_fee_money: record<amount: int, currency: string>, reason: string, status: string, tender_id: string, transaction_id: string>>"
    void-transaction: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    create-loyalty-account: "record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_account: record<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list<record>, id: string, lifetime_points: int, mapping: record<created_at: string, id: string, phone_number: string>, program_id: string, updated_at: string>>"
    search-loyalty-accounts: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, loyalty_accounts: table<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list, id: string, lifetime_points: int, mapping: record, program_id: string, updated_at: string>>"
    retrieve-loyalty-account: "record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_account: record<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list<record>, id: string, lifetime_points: int, mapping: record<created_at: string, id: string, phone_number: string>, program_id: string, updated_at: string>>"
    accumulate-loyalty-points: "record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>>"
    adjust-loyalty-points: "record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>>"
    search-loyalty-events: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, events: table<accumulate_points: record, adjust_points: record, create_reward: record, created_at: string, delete_reward: record, expire_points: record, id: string, location_id: string, loyalty_account_id: string, other_event: record, redeem_reward: record, source: string, type: string>>"
    list-loyalty-programs: "record<errors: table<category: string, code: string, detail: string, field: string>, programs: table<accrual_rules: list, created_at: string, expiration_policy: record, id: string, location_ids: list, reward_tiers: list, status: string, terminology: record, updated_at: string>>"
    retrieve-loyalty-program: "record<errors: table<category: string, code: string, detail: string, field: string>, program: record<accrual_rules: list<record>, created_at: string, expiration_policy: record<expiration_duration: string>, id: string, location_ids: list<string>, reward_tiers: list<record>, status: string, terminology: record<one: string, other: string>, updated_at: string>>"
    calculate-loyalty-points: "record<errors: table<category: string, code: string, detail: string, field: string>, points: int>"
    create-loyalty-reward: "record<errors: table<category: string, code: string, detail: string, field: string>, reward: record<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>>"
    search-loyalty-rewards: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, rewards: table<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>>"
    delete-loyalty-reward: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-loyalty-reward: "record<errors: table<category: string, code: string, detail: string, field: string>, reward: record<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>>"
    redeem-loyalty-reward: "record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>>"
    list-merchants: "record<cursor: int, errors: table<category: string, code: string, detail: string, field: string>, merchant: table<business_name: string, country: string, currency: string, id: string, language_code: string, main_location_id: string, status: string>>"
    retrieve-merchant: "record<errors: table<category: string, code: string, detail: string, field: string>, merchant: record<business_name: string, country: string, currency: string, id: string, language_code: string, main_location_id: string, status: string>>"
    create-order: "record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>"
    batch-retrieve-orders: "record<errors: table<category: string, code: string, detail: string, field: string>, orders: table<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>>"
    calculate-order: "record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>"
    search-orders: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, order_entries: table<location_id: string, order_id: string, version: int>, orders: table<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>>"
    get-v2-orders-order-id: "record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>"
    put-v2-orders-order-id: "record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>"
    pay-order: "record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>"
    get-v2-payments: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, payments: table<amount_money: record, app_fee_money: record, approved_money: record, bank_account_details: record, billing_address: record, buyer_email_address: string, capabilities: list, card_details: record, cash_details: record, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record, id: string, location_id: string, note: string, order_id: string, processing_fee: list, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list, refunded_money: record, risk_evaluation: record, shipping_address: record, source_type: string, statement_description_identifier: string, status: string, tip_money: record, total_money: record, updated_at: string, version_token: string, wallet_details: record>>"
    create-payment: "record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>"
    cancel-payment-by-idempotency-key: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    get-payment: "record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>"
    update-payment: "record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>"
    cancel-payment: "record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>"
    complete-payment: "record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>"
    list-payment-refunds: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<amount_money: record, app_fee_money: record, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list, reason: string, status: string, updated_at: string>>"
    refund-payment: "record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list<record>, reason: string, status: string, updated_at: string>>"
    get-payment-refund: "record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list<record>, reason: string, status: string, updated_at: string>>"
    list-sites: "record<errors: table<category: string, code: string, detail: string, field: string>, sites: table<created_at: string, domain: string, id: string, is_published: bool, site_title: string, updated_at: string>>"
    delete-snippet: "record<errors: table<category: string, code: string, detail: string, field: string>>"
    retrieve-snippet: "record<errors: table<category: string, code: string, detail: string, field: string>, snippet: record<content: string, created_at: string, id: string, site_id: string, updated_at: string>>"
    upsert-snippet: "record<errors: table<category: string, code: string, detail: string, field: string>, snippet: record<content: string, created_at: string, id: string, site_id: string, updated_at: string>>"
    create-subscription: "record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>"
    search-subscriptions: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, subscriptions: table<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list, location_id: string, plan_id: string, price_override_money: record, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>"
    retrieve-subscription: "record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>"
    update-subscription: "record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>"
    cancel-subscription: "record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>"
    list-subscription-events: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, subscription_events: table<effective_date: string, id: string, info: any, plan_id: string, subscription_event_type: string>>"
    resume-subscription: "record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>"
    create-team-member: "record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>>"
    bulk-create-team-members: "record<errors: table<category: string, code: string, detail: string, field: string>, team_members: record>"
    bulk-update-team-members: "record<errors: table<category: string, code: string, detail: string, field: string>, team_members: record>"
    search-team-members: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_members: table<assigned_locations: record, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>>"
    retrieve-team-member: "record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>>"
    update-team-member: "record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>>"
    retrieve-wage-setting: "record<errors: table<category: string, code: string, detail: string, field: string>, wage_setting: record<created_at: string, is_overtime_exempt: bool, job_assignments: list<record>, team_member_id: string, updated_at: string, version: int>>"
    update-wage-setting: "record<errors: table<category: string, code: string, detail: string, field: string>, wage_setting: record<created_at: string, is_overtime_exempt: bool, job_assignments: list<record>, team_member_id: string, updated_at: string, version: int>>"
    create-terminal-checkout: "record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    search-terminal-checkouts: "record<checkouts: table<amount_money: record, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record, id: string, location_id: string, note: string, payment_ids: list, payment_type: string, reference_id: string, status: string, updated_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>"
    get-terminal-checkout: "record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    cancel-terminal-checkout: "record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>"
    create-terminal-refund: "record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>>"
    search-terminal-refunds: "record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<amount_money: record, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>>"
    get-terminal-refund: "record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>>"
    cancel-terminal-refund: "record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-mobile-authorization-code" "renew-token" "revoke-token" "obtain-token" "list-employees" "create-employee" "retrieve-employee" "update-employee" "list-employee-roles" "create-employee-role" "retrieve-employee-role" "update-employee-role" "list-orders" "retrieve-order" "update-order" "list-payments" "retrieve-payment" "list-refunds" "create-refund" "list-settlements" "retrieve-settlement" "register-domain" "list-bank-accounts" "get-bank-account-by-v1-id" "get-bank-account" "create-booking" "search-availability" "retrieve-business-booking-profile" "list-team-member-booking-profiles" "retrieve-team-member-booking-profile" "retrieve-booking" "update-booking" "cancel-booking" "list-cards" "create-card" "retrieve-card" "disable-card" "list-cash-drawer-shifts" "retrieve-cash-drawer-shift" "list-cash-drawer-shift-events" "batch-delete-catalog-objects" "batch-retrieve-catalog-objects" "batch-upsert-catalog-objects" "catalog-info" "list-catalog" "upsert-catalog-object" "delete-catalog-object" "retrieve-catalog-object" "search-catalog-objects" "search-catalog-items" "update-item-modifier-lists" "update-item-taxes" "list-customers" "create-customer" "list-customer-groups" "create-customer-group" "delete-customer-group" "retrieve-customer-group" "update-customer-group" "search-customers" "list-customer-segments" "retrieve-customer-segment" "delete-customer" "retrieve-customer" "update-customer" "create-customer-card" "delete-customer-card" "remove-group-from-customer" "add-group-to-customer" "list-device-codes" "create-device-code" "get-device-code" "list-disputes" "retrieve-dispute" "accept-dispute" "list-dispute-evidence" "create-dispute-evidence-text" "delete-dispute-evidence" "retrieve-dispute-evidence" "submit-evidence" "get-v2-employees" "get-v2-employees-id" "list-gift-cards" "create-gift-card" "list-gift-card-activities" "create-gift-card-activity" "retrieve-gift-card-from-gan" "retrieve-gift-card-from-nonce" "link-customer-to-gift-card" "unlink-customer-from-gift-card" "retrieve-gift-card" "deprecated-retrieve-inventory-adjustment" "retrieve-inventory-adjustment" "deprecated-batch-change-inventory" "deprecated-batch-retrieve-inventory-changes" "deprecated-batch-retrieve-inventory-counts" "batch-change-inventory" "batch-retrieve-inventory-changes" "batch-retrieve-inventory-counts" "deprecated-retrieve-inventory-physical-count" "retrieve-inventory-physical-count" "retrieve-inventory-transfer" "retrieve-inventory-count" "retrieve-inventory-changes" "list-invoices" "create-invoice" "search-invoices" "delete-invoice" "get-invoice" "update-invoice" "cancel-invoice" "publish-invoice" "list-break-types" "create-break-type" "delete-break-type" "get-break-type" "update-break-type" "list-employee-wages" "get-employee-wage" "create-shift" "search-shifts" "delete-shift" "get-shift" "update-shift" "list-team-member-wages" "get-team-member-wage" "list-workweek-configs" "update-workweek-config" "list-locations" "create-location" "retrieve-location" "update-location" "create-checkout" "get-v2-locations-location-id-refunds" "list-transactions" "charge" "retrieve-transaction" "capture-transaction" "post-v2-locations-location-id-transactions-transaction-id-refund" "void-transaction" "create-loyalty-account" "search-loyalty-accounts" "retrieve-loyalty-account" "accumulate-loyalty-points" "adjust-loyalty-points" "search-loyalty-events" "list-loyalty-programs" "retrieve-loyalty-program" "calculate-loyalty-points" "create-loyalty-reward" "search-loyalty-rewards" "delete-loyalty-reward" "retrieve-loyalty-reward" "redeem-loyalty-reward" "list-merchants" "retrieve-merchant" "create-order" "batch-retrieve-orders" "calculate-order" "search-orders" "get-v2-orders-order-id" "put-v2-orders-order-id" "pay-order" "get-v2-payments" "create-payment" "cancel-payment-by-idempotency-key" "get-payment" "update-payment" "cancel-payment" "complete-payment" "list-payment-refunds" "refund-payment" "get-payment-refund" "list-sites" "delete-snippet" "retrieve-snippet" "upsert-snippet" "create-subscription" "search-subscriptions" "retrieve-subscription" "update-subscription" "cancel-subscription" "list-subscription-events" "resume-subscription" "create-team-member" "bulk-create-team-members" "bulk-update-team-members" "search-team-members" "retrieve-team-member" "update-team-member" "retrieve-wage-setting" "update-wage-setting" "create-terminal-checkout" "search-terminal-checkouts" "get-terminal-checkout" "cancel-terminal-checkout" "create-terminal-refund" "search-terminal-refunds" "get-terminal-refund" "cancel-terminal-refund" "commands"] | sort) } | get name | first)
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

# CreateMobileAuthorizationCode
#
# POST /mobile/authorization-code
# Returns: record<authorization_code: string, error: record<category: string, code: string, detail: string, field: string>, expires_at: string>
# operationId: CreateMobileAuthorizationCode
export def "create-mobile-authorization-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The Square location ID the authorization code should be tied to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/mobile/authorization-code"
    body: {content_type: "application/json", kind: json, fields: [{name: location_id, var: location_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RenewToken
#
# POST /oauth2/clients/{client_id}/access-token/renew
# Returns: record<access_token: string, expires_at: string, merchant_id: string, plan_id: string, subscription_id: string, token_type: string>
# operationId: RenewToken
export def "renew-token" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The token you want to renew.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/clients/{client_id}/access-token/renew"
    path_params: [{name: client_id, var: client_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_token, var: access_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RevokeToken
#
# POST /oauth2/revoke
# Returns: record<success: bool>
# operationId: RevokeToken
export def "revoke-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The access token of the merchant whose token you want to revoke. Do not provide a value for merchant_id if you provide this parameter.
  --client-id: string # The Square issued ID for your application, available from the [developer dashboard](https://developer.squareup.com/apps).
  --merchant-id: string # The ID of the merchant whose token you want to revoke. Do not provide a value for access_token if you provide this parameter.
  --revoke-only-access-token: oneof<nothing, bool> # If `true`, terminate the given single access token, but do not terminate the entire authorization. Default: `false`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/revoke"
    body: {content_type: "application/json", kind: json, fields: [{name: access_token, var: access_token}, {name: client_id, var: client_id}, {name: merchant_id, var: merchant_id}, {name: revoke_only_access_token, var: revoke_only_access_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, client_id: $client_id, merchant_id: $merchant_id, revoke_only_access_token: $revoke_only_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ObtainToken
#
# POST /oauth2/token
# Returns: record<access_token: string, expires_at: string, id_token: string, merchant_id: string, plan_id: string, refresh_token: string, short_lived: bool, subscription_id: string, token_type: string>
# operationId: ObtainToken
export def "obtain-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # The Square-issued ID of your application, available from the [developer dashboard](https://developer.squareup.com/apps).
  client_secret: string # The Square-issued application secret for your application, available from the [developer dashboard](https://developer.squareup.com/apps).
  --code: string # The authorization code to exchange. This is required if `grant_type` is set to `authorization_code`, to indicate that the application wants to exchange an authorization code for an OAuth access token.
  grant_type: string # Specifies the method to request an OAuth access token. Valid values are: `authorization_code`, `refresh_token`, and `migration_token`
  --migration-token: string # Legacy OAuth access token obtained using a Connect API version prior to 2019-03-13. This parameter is required if `grant_type` is set to `migration_token` to indicate that the application wants to get a replacement OAuth access token. The response also returns a refresh token. For more information, see [Migrate to Using Refresh Tokens](https://developer.squareup.com/docs/oauth-api/migrate-to-refresh-tokens).
  --redirect-uri: string # The redirect URL assigned in the [developer dashboard](https://developer.squareup.com/apps).
  --refresh-token: string # A valid refresh token for generating a new OAuth access token. A valid refresh token is required if `grant_type` is set to `refresh_token` , to indicate the application wants a replacement for an expired OAuth access token.
  --scopes: list<string> # A JSON list of strings representing the permissions the application is requesting. For example: "`["MERCHANT_PROFILE_READ","PAYMENTS_READ","BANK_ACCOUNTS_READ"]`" The access token returned in the response is granted the permissions that comprise the intersection between the requested list of permissions, and those that belong to the provided refresh token.
  --short-lived: oneof<nothing, bool> # A boolean indicating a request for a short-lived access token. The short-lived access token returned in the response will expire in 24 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/token"
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: code, var: code}, {name: grant_type, var: grant_type}, {name: migration_token, var: migration_token}, {name: redirect_uri, var: redirect_uri}, {name: refresh_token, var: refresh_token}, {name: scopes, var: scopes}, {name: short_lived, var: short_lived}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    client_id: $client_id, client_secret: $client_secret, code: $code, grant_type: $grant_type, migration_token: $migration_token, redirect_uri: $redirect_uri, refresh_token: $refresh_token, scopes: $scopes, short_lived: $short_lived
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListEmployees
#
# GET /v1/me/employees
# Returns: table<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string>
# operationId: ListEmployees
export def "list-employees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which employees are listed in the response, based on their created_at field. Default value: ASC
  --begin-updated-at: string # If filtering results by their updated_at field, the beginning of the requested reporting period, in ISO 8601 format
  --end-updated-at: string # If filtering results by there updated_at field, the end of the requested reporting period, in ISO 8601 format.
  --begin-created-at: string # If filtering results by their created_at field, the beginning of the requested reporting period, in ISO 8601 format.
  --end-created-at: string # If filtering results by their created_at field, the end of the requested reporting period, in ISO 8601 format.
  --status: string # If provided, the endpoint returns only employee entities with the specified status (ACTIVE or INACTIVE).
  --external-id: string # If provided, the endpoint returns only employee entities with the specified external_id.
  --limit: int # The maximum integer number of employee entities to return in a single response. Default 100, maximum 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/me/employees"
    query: [{name: order, var: order}, {name: begin_updated_at, var: begin_updated_at}, {name: end_updated_at, var: end_updated_at}, {name: begin_created_at, var: begin_created_at}, {name: end_created_at, var: end_created_at}, {name: status, var: status}, {name: external_id, var: external_id}, {name: limit, var: limit}, {name: batch_token, var: batch_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order: $order, begin_updated_at: $begin_updated_at, end_updated_at: $end_updated_at, begin_created_at: $begin_created_at, end_created_at: $end_created_at, status: $status, external_id: $external_id, limit: $limit, batch_token: $batch_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateEmployee
#
# POST /v1/me/employees
# Returns: record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string>
# operationId: CreateEmployee
export def "create-employee" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-location-ids: list<string> # The IDs of the locations the employee is allowed to clock in at.
  --created-at: string # The time when the employee entity was created, in ISO 8601 format.
  --email: string # The employee's email address.
  --external-id: string # An ID the merchant can set to associate the employee with an entity in another system.
  first_name: string # The employee's first name.
  --id: string # The employee's unique ID.
  last_name: string # The employee's last name.
  --role-ids: list<string> # The ids of the employee's associated roles. Currently, you can specify only one or zero roles per employee.
  --status: string # Whether the employee is ACTIVE or INACTIVE. Inactive employees cannot sign in to Square Register.Merchants update this field from the Square Dashboard.
  --updated-at: string # The time when the employee entity was most recently updated, in ISO 8601 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/me/employees"
    body: {content_type: "application/json", kind: json, fields: [{name: authorized_location_ids, var: authorized_location_ids}, {name: created_at, var: created_at}, {name: email, var: email}, {name: external_id, var: external_id}, {name: first_name, var: first_name}, {name: id, var: id}, {name: last_name, var: last_name}, {name: role_ids, var: role_ids}, {name: status, var: status}, {name: updated_at, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorized_location_ids: $authorized_location_ids, created_at: $created_at, email: $email, external_id: $external_id, first_name: $first_name, id: $id, last_name: $last_name, role_ids: $role_ids, status: $status, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveEmployee
#
# GET /v1/me/employees/{employee_id}
# Returns: record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string>
# operationId: RetrieveEmployee
export def "retrieve-employee" [
  employee_id: string
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
    path: "/v1/me/employees/{employee_id}"
    path_params: [{name: employee_id, var: employee_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employee_id: $employee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateEmployee
#
# PUT /v1/me/employees/{employee_id}
# Returns: record<authorized_location_ids: list<string>, created_at: string, email: string, external_id: string, first_name: string, id: string, last_name: string, role_ids: list<string>, status: string, updated_at: string>
# operationId: UpdateEmployee
export def "update-employee" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-location-ids: list<string> # The IDs of the locations the employee is allowed to clock in at.
  --created-at: string # The time when the employee entity was created, in ISO 8601 format.
  --email: string # The employee's email address.
  --external-id: string # An ID the merchant can set to associate the employee with an entity in another system.
  first_name: string # The employee's first name.
  --id: string # The employee's unique ID.
  last_name: string # The employee's last name.
  --role-ids: list<string> # The ids of the employee's associated roles. Currently, you can specify only one or zero roles per employee.
  --status: string # Whether the employee is ACTIVE or INACTIVE. Inactive employees cannot sign in to Square Register.Merchants update this field from the Square Dashboard.
  --updated-at: string # The time when the employee entity was most recently updated, in ISO 8601 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/me/employees/{employee_id}"
    path_params: [{name: employee_id, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorized_location_ids, var: authorized_location_ids}, {name: created_at, var: created_at}, {name: email, var: email}, {name: external_id, var: external_id}, {name: first_name, var: first_name}, {name: id, var: id}, {name: last_name, var: last_name}, {name: role_ids, var: role_ids}, {name: status, var: status}, {name: updated_at, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employee_id: $employee_id, authorized_location_ids: $authorized_location_ids, created_at: $created_at, email: $email, external_id: $external_id, first_name: $first_name, id: $id, last_name: $last_name, role_ids: $role_ids, status: $status, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListEmployeeRoles
#
# GET /v1/me/roles
# Returns: table<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string>
# operationId: ListEmployeeRoles
export def "list-employee-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which employees are listed in the response, based on their created_at field.Default value: ASC
  --limit: int # The maximum integer number of employee entities to return in a single response. Default 100, maximum 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/me/roles"
    query: [{name: order, var: order}, {name: limit, var: limit}, {name: batch_token, var: batch_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order: $order, limit: $limit, batch_token: $batch_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateEmployeeRole
#
# POST /v1/me/roles
# Returns: record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string>
# operationId: CreateEmployeeRole
export def "create-employee-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # The time when the employee entity was created, in ISO 8601 format. Is set by Square when the Role is created.
  --id: string # The role's unique ID, Can only be set by Square.
  --is-owner: oneof<nothing, bool> # If true, employees with this role have all permissions, regardless of the values indicated in permissions.
  name: string # The role's merchant-defined name.
  permissions: list<string> # The role's permissions.
  --updated-at: string # The time when the employee entity was most recently updated, in ISO 8601 format. Is set by Square when the Role updated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/me/roles"
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: id, var: id}, {name: is_owner, var: is_owner}, {name: name, var: name}, {name: permissions, var: permissions}, {name: updated_at, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    created_at: $created_at, id: $id, is_owner: $is_owner, name: $name, permissions: $permissions, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveEmployeeRole
#
# GET /v1/me/roles/{role_id}
# Returns: record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string>
# operationId: RetrieveEmployeeRole
export def "retrieve-employee-role" [
  role_id: string
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
    path: "/v1/me/roles/{role_id}"
    path_params: [{name: role_id, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateEmployeeRole
#
# PUT /v1/me/roles/{role_id}
# Returns: record<created_at: string, id: string, is_owner: bool, name: string, permissions: list<string>, updated_at: string>
# operationId: UpdateEmployeeRole
export def "update-employee-role" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # The time when the employee entity was created, in ISO 8601 format. Is set by Square when the Role is created.
  --id: string # The role's unique ID, Can only be set by Square.
  --is-owner: oneof<nothing, bool> # If true, employees with this role have all permissions, regardless of the values indicated in permissions.
  name: string # The role's merchant-defined name.
  permissions: list<string> # The role's permissions.
  --updated-at: string # The time when the employee entity was most recently updated, in ISO 8601 format. Is set by Square when the Role updated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/me/roles/{role_id}"
    path_params: [{name: role_id, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: id, var: id}, {name: is_owner, var: is_owner}, {name: name, var: name}, {name: permissions, var: permissions}, {name: updated_at, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id, created_at: $created_at, id: $id, is_owner: $is_owner, name: $name, permissions: $permissions, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListOrders
#
# GET /v1/{location_id}/orders
# Returns: table<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: list<record>, expires_at: string, id: string, order_history: list<record>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record, settled_at: string, tendered_at: string, tendered_money: record, total_money: record, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string>
# operationId: ListOrders
export def "list-orders" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which payments are listed in the response.
  --limit: int # The maximum number of payments to return in a single response. This value cannot exceed 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{location_id}/orders"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: order, var: order}, {name: limit, var: limit}, {name: batch_token, var: batch_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, order: $order, limit: $limit, batch_token: $batch_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveOrder
#
# GET /v1/{location_id}/orders/{order_id}
# Returns: record<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: table<category: string, code: string, detail: string, field: string>, expires_at: string, id: string, order_history: table<action: string, created_at: string>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record<amount: int, currency_code: string>, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, settled_at: string, tendered_at: string, tendered_money: record<amount: int, currency_code: string>, total_money: record<amount: int, currency_code: string>, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string>
# operationId: RetrieveOrder
export def "retrieve-order" [
  location_id: string
  order_id: string
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
    path: "/v1/{location_id}/orders/{order_id}"
    path_params: [{name: location_id, var: location_id}, {name: order_id, var: order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateOrder
#
# PUT /v1/{location_id}/orders/{order_id}
# Returns: record<btc_price_satoshi: float, btc_receive_address: string, buyer_email: string, buyer_note: string, canceled_note: string, completed_note: string, created_at: string, errors: table<category: string, code: string, detail: string, field: string>, expires_at: string, id: string, order_history: table<action: string, created_at: string>, payment_id: string, promo_code: string, recipient_name: string, recipient_phone_number: string, refunded_note: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, state: string, subtotal_money: record<amount: int, currency_code: string>, tender: record<card_brand: string, change_back_money: record<amount: int, currency_code: string>, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, settled_at: string, tendered_at: string, tendered_money: record<amount: int, currency_code: string>, total_money: record<amount: int, currency_code: string>, type: string>, total_discount_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, updated_at: string>
# operationId: UpdateOrder
export def "update-order" [
  location_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # The action to perform on the order (COMPLETE, CANCEL, or REFUND).
  --canceled-note: string # A merchant-specified note about the canceling of the order. Only valid if action is CANCEL.
  --completed-note: string # A merchant-specified note about the completion of the order. Only valid if action is COMPLETE.
  --refunded-note: string # A merchant-specified note about the refunding of the order. Only valid if action is REFUND.
  --shipped-tracking-number: string # The tracking number of the shipment associated with the order. Only valid if action is COMPLETE.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{location_id}/orders/{order_id}"
    path_params: [{name: location_id, var: location_id}, {name: order_id, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: canceled_note, var: canceled_note}, {name: completed_note, var: completed_note}, {name: refunded_note, var: refunded_note}, {name: shipped_tracking_number, var: shipped_tracking_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, order_id: $order_id, action: $action, canceled_note: $canceled_note, completed_note: $completed_note, refunded_note: $refunded_note, shipped_tracking_number: $shipped_tracking_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListPayments
#
# GET /v1/{location_id}/payments
# Returns: table<additive_tax: list<record>, additive_tax_money: record<amount: int, currency_code: string>, created_at: string, creator_id: string, device: record<id: string, name: string>, discount_money: record<amount: int, currency_code: string>, gross_sales_money: record<amount: int, currency_code: string>, id: string, inclusive_tax: list<record>, inclusive_tax_money: record<amount: int, currency_code: string>, is_partial: bool, itemizations: list<record>, merchant_id: string, net_sales_money: record<amount: int, currency_code: string>, net_total_money: record<amount: int, currency_code: string>, payment_url: string, processing_fee_money: record<amount: int, currency_code: string>, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, refunds: list<record>, surcharge_money: record<amount: int, currency_code: string>, surcharges: list<record>, swedish_rounding_money: record<amount: int, currency_code: string>, tax_money: record<amount: int, currency_code: string>, tender: list<record>, tip_money: record<amount: int, currency_code: string>, total_collected_money: record<amount: int, currency_code: string>>
# operationId: ListPayments
export def "list-payments" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which payments are listed in the response.
  --begin-time: string # The beginning of the requested reporting period, in ISO 8601 format. If this value is before January 1, 2013 (2013-01-01T00:00:00Z), this endpoint returns an error. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in ISO 8601 format. If this value is more than one year greater than begin_time, this endpoint returns an error. Default value: The current time.
  --limit: int # The maximum number of payments to return in a single response. This value cannot exceed 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
  --include-partial: oneof<nothing, bool> # Indicates whether or not to include partial payments in the response. Partial payments will have the tenders collected so far, but the itemizations will be empty until the payment is completed.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{location_id}/payments"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: order, var: order}, {name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: batch_token, var: batch_token}, {name: include_partial, var: include_partial}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, order: $order, begin_time: $begin_time, end_time: $end_time, limit: $limit, batch_token: $batch_token, include_partial: $include_partial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrievePayment
#
# GET /v1/{location_id}/payments/{payment_id}
# Returns: record<additive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, additive_tax_money: record<amount: int, currency_code: string>, created_at: string, creator_id: string, device: record<id: string, name: string>, discount_money: record<amount: int, currency_code: string>, gross_sales_money: record<amount: int, currency_code: string>, id: string, inclusive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, inclusive_tax_money: record<amount: int, currency_code: string>, is_partial: bool, itemizations: table<discount_money: record, discounts: list, gross_sales_money: record, item_detail: record, item_variation_name: string, itemization_type: string, modifiers: list, name: string, net_sales_money: record, notes: string, quantity: float, single_quantity_money: record, taxes: list, total_money: record>, merchant_id: string, net_sales_money: record<amount: int, currency_code: string>, net_total_money: record<amount: int, currency_code: string>, payment_url: string, processing_fee_money: record<amount: int, currency_code: string>, receipt_url: string, refunded_money: record<amount: int, currency_code: string>, refunds: table<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: list, refunded_additive_tax_money: record, refunded_discount_money: record, refunded_inclusive_tax: list, refunded_inclusive_tax_money: record, refunded_money: record, refunded_processing_fee_money: record, refunded_surcharge_money: record, refunded_surcharges: list, refunded_tax_money: record, refunded_tip_money: record, type: string>, surcharge_money: record<amount: int, currency_code: string>, surcharges: table<amount_money: record, applied_money: record, name: string, rate: string, surcharge_id: string, taxable: bool, taxes: list, type: string>, swedish_rounding_money: record<amount: int, currency_code: string>, tax_money: record<amount: int, currency_code: string>, tender: table<card_brand: string, change_back_money: record, employee_id: string, entry_method: string, id: string, is_exchange: bool, name: string, pan_suffix: string, payment_note: string, receipt_url: string, refunded_money: record, settled_at: string, tendered_at: string, tendered_money: record, total_money: record, type: string>, tip_money: record<amount: int, currency_code: string>, total_collected_money: record<amount: int, currency_code: string>>
# operationId: RetrievePayment
export def "retrieve-payment" [
  location_id: string
  payment_id: string
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
    path: "/v1/{location_id}/payments/{payment_id}"
    path_params: [{name: location_id, var: location_id}, {name: payment_id, var: payment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListRefunds
#
# GET /v1/{location_id}/refunds
# Returns: table<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: list<record>, refunded_additive_tax_money: record<amount: int, currency_code: string>, refunded_discount_money: record<amount: int, currency_code: string>, refunded_inclusive_tax: list<record>, refunded_inclusive_tax_money: record<amount: int, currency_code: string>, refunded_money: record<amount: int, currency_code: string>, refunded_processing_fee_money: record<amount: int, currency_code: string>, refunded_surcharge_money: record<amount: int, currency_code: string>, refunded_surcharges: list<record>, refunded_tax_money: record<amount: int, currency_code: string>, refunded_tip_money: record<amount: int, currency_code: string>, type: string>
# operationId: ListRefunds
export def "list-refunds" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which payments are listed in the response.
  --begin-time: string # The beginning of the requested reporting period, in ISO 8601 format. If this value is before January 1, 2013 (2013-01-01T00:00:00Z), this endpoint returns an error. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in ISO 8601 format. If this value is more than one year greater than begin_time, this endpoint returns an error. Default value: The current time.
  --limit: int # The approximate number of refunds to return in a single response. Default: 100. Max: 200. Response may contain more results than the prescribed limit when refunds are made simultaneously to multiple tenders in a payment or when refunds are generated in an exchange to account for the value of returned goods.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{location_id}/refunds"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: order, var: order}, {name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: batch_token, var: batch_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, order: $order, begin_time: $begin_time, end_time: $end_time, limit: $limit, batch_token: $batch_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateRefund
#
# POST /v1/{location_id}/refunds
# Returns: record<created_at: string, is_exchange: bool, merchant_id: string, payment_id: string, processed_at: string, reason: string, refunded_additive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, refunded_additive_tax_money: record<amount: int, currency_code: string>, refunded_discount_money: record<amount: int, currency_code: string>, refunded_inclusive_tax: table<applied_money: record, errors: list, fee_id: string, inclusion_type: string, name: string, rate: string>, refunded_inclusive_tax_money: record<amount: int, currency_code: string>, refunded_money: record<amount: int, currency_code: string>, refunded_processing_fee_money: record<amount: int, currency_code: string>, refunded_surcharge_money: record<amount: int, currency_code: string>, refunded_surcharges: table<amount_money: record, applied_money: record, name: string, rate: string, surcharge_id: string, taxable: bool, taxes: list, type: string>, refunded_tax_money: record<amount: int, currency_code: string>, refunded_tip_money: record<amount: int, currency_code: string>, type: string>
# operationId: CreateRefund
export def "create-refund" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payment_id: string # The ID of the payment to refund. If you are creating a `PARTIAL` refund for a split tender payment, instead provide the id of the particular tender you want to refund.
  reason: string # The reason for the refund.
  --refunded-money: record # shape: {amount?: int, currency_code?: string}
  --request-idempotence-key: string # An optional key to ensure idempotence if you issue the same PARTIAL refund request more than once.
  type: string # The type of refund (FULL or PARTIAL).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{location_id}/refunds"
    path_params: [{name: location_id, var: location_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: payment_id, var: payment_id}, {name: reason, var: reason}, {name: refunded_money, var: refunded_money}, {name: request_idempotence_key, var: request_idempotence_key}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, payment_id: $payment_id, reason: $reason, refunded_money: $refunded_money, request_idempotence_key: $request_idempotence_key, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListSettlements
#
# GET /v1/{location_id}/settlements
# Returns: table<bank_account_id: string, entries: list<record>, id: string, initiated_at: string, status: string, total_money: record<amount: int, currency_code: string>>
# operationId: ListSettlements
export def "list-settlements" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # The order in which settlements are listed in the response.
  --begin-time: string # The beginning of the requested reporting period, in ISO 8601 format. If this value is before January 1, 2013 (2013-01-01T00:00:00Z), this endpoint returns an error. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in ISO 8601 format. If this value is more than one year greater than begin_time, this endpoint returns an error. Default value: The current time.
  --limit: int # The maximum number of settlements to return in a single response. This value cannot exceed 200.
  --status: string # Provide this parameter to retrieve only settlements with a particular status (SENT or FAILED).
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{location_id}/settlements"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: order, var: order}, {name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: status, var: status}, {name: batch_token, var: batch_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, order: $order, begin_time: $begin_time, end_time: $end_time, limit: $limit, status: $status, batch_token: $batch_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveSettlement
#
# GET /v1/{location_id}/settlements/{settlement_id}
# Returns: record<bank_account_id: string, entries: table<amount_money: record, fee_money: record, payment_id: string, type: string>, id: string, initiated_at: string, status: string, total_money: record<amount: int, currency_code: string>>
# operationId: RetrieveSettlement
export def "retrieve-settlement" [
  location_id: string
  settlement_id: string
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
    path: "/v1/{location_id}/settlements/{settlement_id}"
    path_params: [{name: location_id, var: location_id}, {name: settlement_id, var: settlement_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, settlement_id: $settlement_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RegisterDomain
#
# POST /v2/apple-pay/domains
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, status: string>
# operationId: RegisterDomain
export def "register-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  domain_name: string # A domain name as described in RFC-1034 that will be registered with ApplePay.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/apple-pay/domains"
    body: {content_type: "application/json", kind: json, fields: [{name: domain_name, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListBankAccounts
#
# GET /v2/bank-accounts
# Returns: record<bank_accounts: table<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: ListBankAccounts
export def "list-bank-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # The pagination cursor returned by a previous call to this endpoint. Use it in the next `ListBankAccounts` request to retrieve the next set of results. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --limit: int # Upper limit on the number of bank accounts to return in the response. Currently, 1000 is the largest supported limit. You can specify a limit of up to 1000 bank accounts. This is also the default limit.
  --location-id: string # Location ID. You can specify this optional filter to retrieve only the linked bank accounts belonging to a specific location.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/bank-accounts"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: location_id, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetBankAccountByV1Id
#
# GET /v2/bank-accounts/by-v1-id/{v1_bank_account_id}
# Returns: record<bank_account: record<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: GetBankAccountByV1Id
export def "get-bank-account-by-v1-id" [
  v1_bank_account_id: string
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
    path: "/v2/bank-accounts/by-v1-id/{v1_bank_account_id}"
    path_params: [{name: v1_bank_account_id, var: v1_bank_account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    v1_bank_account_id: $v1_bank_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetBankAccount
#
# GET /v2/bank-accounts/{bank_account_id}
# Returns: record<bank_account: record<account_number_suffix: string, account_type: string, bank_name: string, country: string, creditable: bool, currency: string, debit_mandate_reference_id: string, debitable: bool, fingerprint: string, holder_name: string, id: string, location_id: string, primary_bank_identification_number: string, reference_id: string, secondary_bank_identification_number: string, status: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: GetBankAccount
export def "get-bank-account" [
  bank_account_id: string
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
    path: "/v2/bank-accounts/{bank_account_id}"
    path_params: [{name: bank_account_id, var: bank_account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_account_id: $bank_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateBooking
#
# POST /v2/bookings
# Returns: record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CreateBooking
export def "create-booking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  booking: record # Represents a booking as a time-bound service contract for a seller's staff member to provide a specified service at a given location to a requesting customer in one or more appointment segments. — shape: {appointment_segments?: list, created_at?: string, customer_id?: string, customer_note?: string, id?: string, location_id?: string, seller_note?: string, start_at?: string, status?: string, updated_at?: string, version?: int}
  --idempotency-key: string # A unique key to make this request an idempotent operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/bookings"
    body: {content_type: "application/json", kind: json, fields: [{name: booking, var: booking}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    booking: $booking, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchAvailability
#
# POST /v2/bookings/availability/search
# Returns: record<availabilities: table<appointment_segments: list, location_id: string, start_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: SearchAvailability
export def "search-availability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  query: record # Query conditions to search for availabilities of bookings. — shape: {filter: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/bookings/availability/search"
    body: {content_type: "application/json", kind: json, fields: [{name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveBusinessBookingProfile
#
# GET /v2/bookings/business-booking-profile
# Returns: record<business_booking_profile: record<allow_user_cancel: bool, booking_enabled: bool, booking_policy: string, business_appointment_settings: record<alignment_time: string, any_team_member_booking_enabled: bool, cancellation_fee_money: record, cancellation_policy: string, cancellation_policy_text: string, cancellation_window_seconds: int, location_types: list, max_appointments_per_day_limit: int, max_appointments_per_day_limit_type: string, max_booking_lead_time_seconds: int, min_booking_lead_time_seconds: int, multiple_service_booking_enabled: bool, skip_booking_flow_staff_selection: bool>, created_at: string, customer_timezone_choice: string, seller_id: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveBusinessBookingProfile
export def "retrieve-business-booking-profile" [
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
    path: "/v2/bookings/business-booking-profile"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListTeamMemberBookingProfiles
#
# GET /v2/bookings/team-member-booking-profiles
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_member_booking_profiles: table<description: string, display_name: string, is_bookable: bool, profile_image_url: string, team_member_id: string>>
# operationId: ListTeamMemberBookingProfiles
export def "list-team-member-booking-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bookable-only: oneof<nothing, bool> # Indicates whether to include only bookable team members in the returned result (`true`) or not (`false`).
  --limit: int # The maximum number of results to return.
  --cursor: string # The cursor for paginating through the results.
  --location-id: string # Indicates whether to include only team members enabled at the given location in the returned result.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/bookings/team-member-booking-profiles"
    query: [{name: bookable_only, var: bookable_only}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: location_id, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bookable_only: $bookable_only, limit: $limit, cursor: $cursor, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveTeamMemberBookingProfile
#
# GET /v2/bookings/team-member-booking-profiles/{team_member_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, team_member_booking_profile: record<description: string, display_name: string, is_bookable: bool, profile_image_url: string, team_member_id: string>>
# operationId: RetrieveTeamMemberBookingProfile
export def "retrieve-team-member-booking-profile" [
  team_member_id: string
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
    path: "/v2/bookings/team-member-booking-profiles/{team_member_id}"
    path_params: [{name: team_member_id, var: team_member_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_member_id: $team_member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveBooking
#
# GET /v2/bookings/{booking_id}
# Returns: record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveBooking
export def "retrieve-booking" [
  booking_id: string
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
    path: "/v2/bookings/{booking_id}"
    path_params: [{name: booking_id, var: booking_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    booking_id: $booking_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateBooking
#
# PUT /v2/bookings/{booking_id}
# Returns: record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: UpdateBooking
export def "update-booking" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  booking: record # Represents a booking as a time-bound service contract for a seller's staff member to provide a specified service at a given location to a requesting customer in one or more appointment segments. — shape: {appointment_segments?: list, created_at?: string, customer_id?: string, customer_note?: string, id?: string, location_id?: string, seller_note?: string, start_at?: string, status?: string, updated_at?: string, version?: int}
  --idempotency-key: string # A unique key to make this request an idempotent operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/bookings/{booking_id}"
    path_params: [{name: booking_id, var: booking_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: booking, var: booking}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    booking_id: $booking_id, booking: $booking, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CancelBooking
#
# POST /v2/bookings/{booking_id}/cancel
# Returns: record<booking: record<appointment_segments: list<record>, created_at: string, customer_id: string, customer_note: string, id: string, location_id: string, seller_note: string, start_at: string, status: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CancelBooking
export def "cancel-booking" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --booking-version: int # The revision number for the booking used for optimistic concurrency.
  --idempotency-key: string # A unique key to make this request an idempotent operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/bookings/{booking_id}/cancel"
    path_params: [{name: booking_id, var: booking_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: booking_version, var: booking_version}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    booking_id: $booking_id, booking_version: $booking_version, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListCards
#
# GET /v2/cards
# Returns: record<cards: table<billing_address: record, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: ListCards
export def "list-cards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. See [Pagination](https://developer.squareup.com/docs/basics/api101/pagination) for more information.
  --customer-id: string # Limit results to cards associated with the customer supplied. By default, all cards owned by the merchant are returned.
  --include-disabled: oneof<nothing, bool> # Includes disabled cards. By default, all enabled cards owned by the merchant are returned.
  --reference-id: string # Limit results to cards associated with the reference_id supplied.
  --sort-order: string # Sorts the returned list by when the card was created with the specified order. This field defaults to ASC.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/cards"
    query: [{name: cursor, var: cursor}, {name: customer_id, var: customer_id}, {name: include_disabled, var: include_disabled}, {name: reference_id, var: reference_id}, {name: sort_order, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, customer_id: $customer_id, include_disabled: $include_disabled, reference_id: $reference_id, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateCard
#
# POST /v2/cards
# Returns: record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CreateCard
export def "create-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card: record # Represents the payment details of a card to be used for payments. These details are determined by the payment token generated by Web Payments SDK. — shape: {billing_address?: record, bin?: string, card_brand?: string, card_type?: string, cardholder_name?: string, customer_id?: string, enabled?: bool, exp_month?: int, exp_year?: int, fingerprint?: string, id?: string, last_4?: string, prepaid_type?: string, reference_id?: string, version?: int}
  idempotency_key: string # A unique string that identifies this CreateCard request. Keys can be any valid string and must be unique for every request. Max: 45 characters See [Idempotency keys](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
  source_id: string # The ID of the source which represents the card information to be stored. This can be a card nonce or a payment id.
  --verification-token: string # An identifying token generated by [Payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity. See the [SCA Overview](https://developer.squareup.com/docs/sca-overview).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/cards"
    body: {content_type: "application/json", kind: json, fields: [{name: card, var: card}, {name: idempotency_key, var: idempotency_key}, {name: source_id, var: source_id}, {name: verification_token, var: verification_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card: $card, idempotency_key: $idempotency_key, source_id: $source_id, verification_token: $verification_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveCard
#
# GET /v2/cards/{card_id}
# Returns: record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveCard
export def "retrieve-card" [
  card_id: string
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
    path: "/v2/cards/{card_id}"
    path_params: [{name: card_id, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DisableCard
#
# POST /v2/cards/{card_id}/disable
# Returns: record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DisableCard
export def "disable-card" [
  card_id: string
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
    path: "/v2/cards/{card_id}/disable"
    path_params: [{name: card_id, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListCashDrawerShifts
#
# GET /v2/cash-drawers/shifts
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, items: table<closed_at: string, closed_cash_money: record, description: string, ended_at: string, expected_cash_money: record, id: string, opened_at: string, opened_cash_money: record, state: string>>
# operationId: ListCashDrawerShifts
export def "list-cash-drawer-shifts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location to query for a list of cash drawer shifts. (required)
  --sort-order: string # The order in which cash drawer shifts are listed in the response, based on their opened_at field. Default value: ASC
  --begin-time: string # The inclusive start time of the query on opened_at, in ISO 8601 format.
  --end-time: string # The exclusive end date of the query on opened_at, in ISO 8601 format.
  --limit: int # Number of cash drawer shift events in a page of results (200 by default, 1000 max).
  --cursor: string # Opaque cursor for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/cash-drawers/shifts"
    query: [{name: location_id, var: location_id, required: true}, {name: sort_order, var: sort_order}, {name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, sort_order: $sort_order, begin_time: $begin_time, end_time: $end_time, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveCashDrawerShift
#
# GET /v2/cash-drawers/shifts/{shift_id}
# Returns: record<cash_drawer_shift: record<cash_paid_in_money: record<amount: int, currency: string>, cash_paid_out_money: record<amount: int, currency: string>, cash_payment_money: record<amount: int, currency: string>, cash_refunds_money: record<amount: int, currency: string>, closed_at: string, closed_cash_money: record<amount: int, currency: string>, closing_employee_id: string, description: string, device: record<id: string, name: string>, employee_ids: list<string>, ended_at: string, ending_employee_id: string, expected_cash_money: record<amount: int, currency: string>, id: string, opened_at: string, opened_cash_money: record<amount: int, currency: string>, opening_employee_id: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveCashDrawerShift
export def "retrieve-cash-drawer-shift" [
  shift_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location to retrieve cash drawer shifts from. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/cash-drawers/shifts/{shift_id}"
    path_params: [{name: shift_id, var: shift_id}]
    query: [{name: location_id, var: location_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shift_id: $shift_id, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListCashDrawerShiftEvents
#
# GET /v2/cash-drawers/shifts/{shift_id}/events
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, events: table<created_at: string, description: string, employee_id: string, event_money: record, event_type: string, id: string>>
# operationId: ListCashDrawerShiftEvents
export def "list-cash-drawer-shift-events" [
  shift_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location to list cash drawer shifts for. (required)
  --limit: int # Number of resources to be returned in a page of results (200 by default, 1000 max).
  --cursor: string # Opaque cursor for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/cash-drawers/shifts/{shift_id}/events"
    path_params: [{name: shift_id, var: shift_id}]
    query: [{name: location_id, var: location_id, required: true}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shift_id: $shift_id, location_id: $location_id, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BatchDeleteCatalogObjects
#
# POST /v2/catalog/batch-delete
# Returns: record<deleted_at: string, deleted_object_ids: list<string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: BatchDeleteCatalogObjects
export def "batch-delete-catalog-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --object-ids: list<string> # The IDs of the CatalogObjects to be deleted. When an object is deleted, other objects in the graph that depend on that object will be deleted as well (for example, deleting a CatalogItem will delete its CatalogItemVariation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/catalog/batch-delete"
    body: {content_type: "application/json", kind: json, fields: [{name: object_ids, var: object_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_ids: $object_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BatchRetrieveCatalogObjects
#
# POST /v2/catalog/batch-retrieve
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>>
# operationId: BatchRetrieveCatalogObjects
export def "batch-retrieve-catalog-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-version: int # The specific version of the catalog objects to be included in the response. This allows you to retrieve historical versions of objects. The specified version value is matched against the [CatalogObject](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogObject)s' `version` attribute. (format: int64)
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested objects, as follows: If the `objects` field of the response contains a CatalogItem, its associated CatalogCategory objects, CatalogTax objects, CatalogImage objects and CatalogModifierLists will be returned in the `related_objects` field of the response. If the `objects` field of the response contains a CatalogItemVariation, its parent CatalogItem will be returned in the `related_objects` field of the response.
  object_ids: list<string> # The IDs of the CatalogObjects to be retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/catalog/batch-retrieve"
    body: {content_type: "application/json", kind: json, fields: [{name: catalog_version, var: catalog_version}, {name: include_related_objects, var: include_related_objects}, {name: object_ids, var: object_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog_version: $catalog_version, include_related_objects: $include_related_objects, object_ids: $object_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BatchUpsertCatalogObjects
#
# POST /v2/catalog/batch-upsert
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, id_mappings: table<client_object_id: string, object_id: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, updated_at: string>
# operationId: BatchUpsertCatalogObjects
export def "batch-upsert-catalog-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  batches: list # A batch of CatalogObjects to be inserted/updated atomically. The objects within a batch will be inserted in an all-or-nothing fashion, i.e., if an error occurs attempting to insert or update an object within a batch, the entire batch will be rejected. However, an error in one batch will not affect other batches within the same request. For each object, its `updated_at` field is ignored and replaced with a current [timestamp](https://developer.squareup.com/docs/build-basics/working-with-dates), and its `is_deleted` field must not be set to `true`. To modify an existing object, supply its ID. To create a new object, use an ID starting with `#`. These IDs may be used to create relationships between an object and attributes of other objects that reference it. For example, you can create a CatalogItem with ID `#ABC` and a CatalogItemVariation with its `item_id` attribute set to `#ABC` in order to associate the CatalogItemVariation with its parent CatalogItem. Any `#`-prefixed IDs are valid only within a single atomic batch, and will be replaced by server-generated IDs. Each batch may contain up to 1,000 objects. The total number of objects across all batches for a single request may not exceed 10,000. If either of these limits is violated, an error will be returned and no objects will be inserted or updated. — item shape: {objects: list}
  idempotency_key: string # A value you specify that uniquely identifies this request among all your requests. A common way to create a valid idempotency key is to use a Universally unique identifier (UUID). If you're unsure whether a particular request was successful, you can reattempt it with the same idempotency key without worrying about creating duplicate objects. See [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/catalog/batch-upsert"
    body: {content_type: "application/json", kind: json, fields: [{name: batches, var: batches}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batches: $batches, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CatalogInfo
#
# GET /v2/catalog/info
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, limits: record<batch_delete_max_object_ids: int, batch_retrieve_max_object_ids: int, batch_upsert_max_objects_per_batch: int, batch_upsert_max_total_objects: int, search_max_page_limit: int, update_item_modifier_lists_max_item_ids: int, update_item_modifier_lists_max_modifier_lists_to_disable: int, update_item_modifier_lists_max_modifier_lists_to_enable: int, update_item_taxes_max_item_ids: int, update_item_taxes_max_taxes_to_disable: int, update_item_taxes_max_taxes_to_enable: int>, standard_unit_description_group: record<language_code: string, standard_unit_descriptions: list<record>>>
# operationId: CatalogInfo
export def "catalog-info" [
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
    path: "/v2/catalog/info"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListCatalog
#
# GET /v2/catalog/list
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>>
# operationId: ListCatalog
export def "list-catalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # The pagination cursor returned in the previous response. Leave unset for an initial request. The page size is currently set to be 100. See [Pagination](https://developer.squareup.com/docs/basics/api101/pagination) for more information.
  --types: string # An optional case-insensitive, comma-separated list of object types to retrieve. The valid values are defined in the [CatalogObjectType](https://developer.squareup.com/reference/square_2021-08-18/enums/CatalogObjectType) enum, including `ITEM`, `ITEM_VARIATION`, `CATEGORY`, `DISCOUNT`, `TAX`, `MODIFIER`, `MODIFIER_LIST`, or `IMAGE`. If this is unspecified, the operation returns objects of all the types at the version of the Square API used to make the request.
  --catalog-version: int # The specific version of the catalog objects to be included in the response. This allows you to retrieve historical versions of objects. The specified version value is matched against the [CatalogObject](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogObject)s' `version` attribute. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/catalog/list"
    query: [{name: cursor, var: cursor}, {name: types, var: types}, {name: catalog_version, var: catalog_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, types: $types, catalog_version: $catalog_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpsertCatalogObject
#
# POST /v2/catalog/object
# Returns: record<catalog_object: record<absent_at_location_ids: list<string>, catalog_v1_ids: list<record>, category_data: record<name: string>, custom_attribute_definition_data: record<allowed_object_types: list, app_visibility: string, custom_attribute_usage_count: int, description: string, key: string, name: string, number_config: record, selection_config: record, seller_visibility: string, source_application: record, string_config: record, type: string>, custom_attribute_values: record, discount_data: record<amount_money: record, discount_type: string, label_color: string, modify_tax_basis: string, name: string, percentage: string, pin_required: bool>, id: string, image_data: record<caption: string, name: string, url: string>, image_id: string, is_deleted: bool, item_data: record<abbreviation: string, available_electronically: bool, available_for_pickup: bool, available_online: bool, category_id: string, description: string, item_options: list, label_color: string, modifier_list_info: list, name: string, product_type: string, skip_modifier_screen: bool, sort_name: string, tax_ids: list, variations: list>, item_option_data: record<description: string, display_name: string, name: string, show_colors: bool, values: list>, item_option_value_data: record<color: string, description: string, item_option_id: string, name: string, ordinal: int>, item_variation_data: record<available_for_booking: bool, inventory_alert_threshold: int, inventory_alert_type: string, item_id: string, item_option_values: list, location_overrides: list, measurement_unit_id: string, name: string, ordinal: int, price_money: record, pricing_type: string, service_duration: int, sku: string, stockable: bool, stockable_conversion: record, team_member_ids: list, track_inventory: bool, upc: string, user_data: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, modifier_data: record<modifier_list_id: string, name: string, ordinal: int, price_money: record>, modifier_list_data: record<modifiers: list, name: string, ordinal: int, selection_type: string>, present_at_all_locations: bool, present_at_location_ids: list<string>, pricing_rule_data: record<apply_products_id: string, customer_group_ids_any: list, discount_id: string, exclude_products_id: string, exclude_strategy: string, match_products_id: string, name: string, time_period_ids: list, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string>, product_set_data: record<all_products: bool, name: string, product_ids_all: list, product_ids_any: list, quantity_exact: int, quantity_max: int, quantity_min: int>, quick_amounts_settings_data: record<amounts: list, eligible_for_auto_amounts: bool, option: string>, subscription_plan_data: record<name: string, phases: list>, tax_data: record<applies_to_custom_amounts: bool, calculation_phase: string, enabled: bool, inclusion_type: string, name: string, percentage: string>, time_period_data: record<event: string>, type: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>, id_mappings: table<client_object_id: string, object_id: string>>
# operationId: UpsertCatalogObject
export def "upsert-catalog-object" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A value you specify that uniquely identifies this request among all your requests. A common way to create a valid idempotency key is to use a Universally unique identifier (UUID). If you're unsure whether a particular request was successful, you can reattempt it with the same idempotency key without worrying about creating duplicate objects. See [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
  object: record # The wrapper object for the Catalog entries of a given object type. The type of a particular `CatalogObject` is determined by the value of the `type` attribute and only the corresponding data attribute can be set on the `CatalogObject` instance. For example, the following list shows some instances of `CatalogObject` of a given `type` and their corresponding data attribute that can be set: - For a `CatalogObject` of the `ITEM` type, set the `item_data` attribute to yield the `CatalogItem` object. - For a `CatalogObject` of the `ITEM_VARIATION` type, set the `item_variation_data` attribute to yield the `CatalogItemVariation` object. - For a `CatalogObject` of the `MODIFIER` type, set the `modifier_data` attribute to yield the `CatalogModifier` object. - For a `CatalogObject` of the `MODIFIER_LIST` type, set the `modifier_list_data` attribute to yield the `CatalogModifierList` object. - For a `CatalogObject` of the `CATEGORY` type, set the `category_data` attribute to yield the `CatalogCategory` object. - For a `CatalogObject` of the `DISCOUNT` type, set the `discount_data` attribute to yield the `CatalogDiscount` object. - For a `CatalogObject` of the `TAX` type, set the `tax_data` attribute to yield the `CatalogTax` object. - For a `CatalogObject` of the `IMAGE` type, set the `image_data` attribute to yield the `CatalogImageData` object. - For a `CatalogObject` of the `QUICK_AMOUNTS_SETTINGS` type, set the `quick_amounts_settings_data` attribute to yield the `CatalogQuickAmountsSettings` object. - For a `CatalogObject` of the `PRICING_RULE` type, set the `pricing_rule_data` attribute to yield the `CatalogPricingRule` object. - For a `CatalogObject` of the `TIME_PERIOD` type, set the `time_period_data` attribute to yield the `CatalogTimePeriod` object. - For a `CatalogObject` of the `PRODUCT_SET` type, set the `product_set_data` attribute to yield the `CatalogProductSet` object. - For a `CatalogObject` of the `SUBSCRIPTION_PLAN` type, set the `subscription_plan_data` attribute to yield the `CatalogSubscriptionPlan` object. For a more detailed discussion of the Catalog data model, please see the [Design a Catalog](https://developer.squareup.com/docs/catalog-api/design-a-catalog) guide. (e.g. {catalog_object: {absent_at_location_ids: [{{ LOCATIONID-1 }}, {{ LOCATIONID-N }}], category_data: {{ CatalogCategory object only if type=CATEGORY }}, connect_v1_ids: {catalog_v1_id: {{ itemID from Catalog v1 }}, location_id: {{ location where v1 ID is used }}}, discount_data: {{ CatalogDiscount object only if type=DISCOUNT }}, id: {{ set by Catalog during object creation }}, is_deleted: {{ [true | false] }}, item_data: {{ CatalogItem object only if type=ITEM }}, item_variation_data: {{ CatalogItemVariation object only if type=ITEM_VARIATION }}, modifier_data: {{ CatalogModifier object only if type=MODIFIER }}, modifier_list_data: {{ CatalogModifierList object only if type=MODIFIER_LIST }}, present_at_all_locations: {{ [true | false] }}, present_at_location_ids: [{{ LOCATIONID-1 }}, {{ LOCATIONID-N }}], tax_data: {{ CatalogTax object only if type=TAX }}, type: {{ [ITEM | ITEM_VARIATION | MODIFIER | MODIFIER_LIST | CATEGORY | DISCOUNT | TAX] }}, updated_at: {{ date & time of most recent update }}, version: {{ version of the CatalogObject }}}}) — shape: {absent_at_location_ids?: list<string>, catalog_v1_ids?: list, category_data?: record, custom_attribute_definition_data?: record, custom_attribute_values?: record, discount_data?: record, id: string, image_data?: record, image_id?: string, is_deleted?: bool, item_data?: record, item_option_data?: record, item_option_value_data?: record, item_variation_data?: record, measurement_unit_data?: record, modifier_data?: record, modifier_list_data?: record, present_at_all_locations?: bool, ... (10 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/catalog/object"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: object, var: object}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteCatalogObject
#
# DELETE /v2/catalog/object/{object_id}
# Returns: record<deleted_at: string, deleted_object_ids: list<string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteCatalogObject
export def "delete-catalog-object" [
  object_id: string
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
    path: "/v2/catalog/object/{object_id}"
    path_params: [{name: object_id, var: object_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_id: $object_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveCatalogObject
#
# GET /v2/catalog/object/{object_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, object: record<absent_at_location_ids: list<string>, catalog_v1_ids: list<record>, category_data: record<name: string>, custom_attribute_definition_data: record<allowed_object_types: list, app_visibility: string, custom_attribute_usage_count: int, description: string, key: string, name: string, number_config: record, selection_config: record, seller_visibility: string, source_application: record, string_config: record, type: string>, custom_attribute_values: record, discount_data: record<amount_money: record, discount_type: string, label_color: string, modify_tax_basis: string, name: string, percentage: string, pin_required: bool>, id: string, image_data: record<caption: string, name: string, url: string>, image_id: string, is_deleted: bool, item_data: record<abbreviation: string, available_electronically: bool, available_for_pickup: bool, available_online: bool, category_id: string, description: string, item_options: list, label_color: string, modifier_list_info: list, name: string, product_type: string, skip_modifier_screen: bool, sort_name: string, tax_ids: list, variations: list>, item_option_data: record<description: string, display_name: string, name: string, show_colors: bool, values: list>, item_option_value_data: record<color: string, description: string, item_option_id: string, name: string, ordinal: int>, item_variation_data: record<available_for_booking: bool, inventory_alert_threshold: int, inventory_alert_type: string, item_id: string, item_option_values: list, location_overrides: list, measurement_unit_id: string, name: string, ordinal: int, price_money: record, pricing_type: string, service_duration: int, sku: string, stockable: bool, stockable_conversion: record, team_member_ids: list, track_inventory: bool, upc: string, user_data: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, modifier_data: record<modifier_list_id: string, name: string, ordinal: int, price_money: record>, modifier_list_data: record<modifiers: list, name: string, ordinal: int, selection_type: string>, present_at_all_locations: bool, present_at_location_ids: list<string>, pricing_rule_data: record<apply_products_id: string, customer_group_ids_any: list, discount_id: string, exclude_products_id: string, exclude_strategy: string, match_products_id: string, name: string, time_period_ids: list, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string>, product_set_data: record<all_products: bool, name: string, product_ids_all: list, product_ids_any: list, quantity_exact: int, quantity_max: int, quantity_min: int>, quick_amounts_settings_data: record<amounts: list, eligible_for_auto_amounts: bool, option: string>, subscription_plan_data: record<name: string, phases: list>, tax_data: record<applies_to_custom_amounts: bool, calculation_phase: string, enabled: bool, inclusion_type: string, name: string, percentage: string>, time_period_data: record<event: string>, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>>
# operationId: RetrieveCatalogObject
export def "retrieve-catalog-object" [
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested object, as follows: If the `object` field of the response contains a `CatalogItem`, its associated `CatalogCategory`, `CatalogTax`, `CatalogImage` and `CatalogModifierList` objects will be returned in the `related_objects` field of the response. If the `object` field of the response contains a `CatalogItemVariation`, its parent `CatalogItem` will be returned in the `related_objects` field of the response. Default value: `false`
  --catalog-version: int # Requests objects as of a specific version of the catalog. This allows you to retrieve historical versions of objects. The value to retrieve a specific version of an object can be found in the version field of [CatalogObject](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogObject)s. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/catalog/object/{object_id}"
    path_params: [{name: object_id, var: object_id}]
    query: [{name: include_related_objects, var: include_related_objects}, {name: catalog_version, var: catalog_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_id: $object_id, include_related_objects: $include_related_objects, catalog_version: $catalog_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchCatalogObjects
#
# POST /v2/catalog/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, latest_time: string, objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, related_objects: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>>
# operationId: SearchCatalogObjects
export def "search-catalog-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # Return objects modified after this [timestamp](https://developer.squareup.com/docs/build-basics/working-with-dates), in RFC 3339 format, e.g., `2016-09-04T23:59:33.123Z`. The timestamp is exclusive - objects with a timestamp equal to `begin_time` will not be included in the response.
  --cursor: string # The pagination cursor returned in the previous response. Leave unset for an initial request. See [Pagination](https://developer.squareup.com/docs/basics/api101/pagination) for more information.
  --include-deleted-objects: oneof<nothing, bool> # If `true`, deleted objects will be included in the results. Deleted objects will have their `is_deleted` field set to `true`.
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested object, as follows: If a CatalogItem is returned in the object field of the response, its associated CatalogCategory, CatalogTax objects, CatalogImage objects and CatalogModifierList objects will be included in the `related_objects` field of the response. If a CatalogItemVariation is returned in the object field of the response, its parent CatalogItem will be included in the `related_objects` field of the response.
  --limit: int # A limit on the number of results to be returned in a single page. The limit is advisory - the implementation may return more or fewer results. If the supplied limit is negative, zero, or is higher than the maximum limit of 1,000, it will be ignored.
  --object-types: list<string> # The desired set of object types to appear in the search results.
  --query: record # A query composed of one or more different types of filters to narrow the scope of targeted objects when calling the `SearchCatalogObjects` endpoint. Although a query can have multiple filters, only certain query types can be combined per call to [SearchCatalogObjects](https://developer.squareup.com/reference/square_2021-08-18/catalog-api/search-catalog-objects). Any combination of the following types may be used together: - [exact_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQueryExact) - [prefix_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQueryPrefix) - [range_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQueryRange) - [sorted_attribute_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQuerySortedAttribute) - [text_query](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogQueryText) All other query types cannot be combined with any others. When a query filter is based on an attribute, the attribute must be searchable. Searchable attributes are listed as follows, along their parent types that can be searched for with applicable query filters. * Searchable attribute and objects queryable by searchable attributes ** - `name`: `CatalogItem`, `CatalogItemVariation`, `CatalogCategory`, `CatalogTax`, `CatalogDiscount`, `CatalogModifier`, 'CatalogModifierList`, `CatalogItemOption`, `CatalogItemOptionValue` - `description`: `CatalogItem`, `CatalogItemOptionValue` - `abbreviation`: `CatalogItem` - `upc`: `CatalogItemVariation` - `sku`: `CatalogItemVariation` - `caption`: `CatalogImage` - `display_name`: `CatalogItemOption` For example, to search for [CatalogItem](https://developer.squareup.com/reference/square_2021-08-18/objects/CatalogItem) objects by searchable attributes, you can use the `"name"`, `"description"`, or `"abbreviation"` attribute in an applicable query filter. — shape: {exact_query?: record, item_variations_for_item_option_values_query?: record, items_for_item_options_query?: record, items_for_modifier_list_query?: record, items_for_tax_query?: record, prefix_query?: record, range_query?: record, set_query?: record, sorted_attribute_query?: record, text_query?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/catalog/search"
    body: {content_type: "application/json", kind: json, fields: [{name: begin_time, var: begin_time}, {name: cursor, var: cursor}, {name: include_deleted_objects, var: include_deleted_objects}, {name: include_related_objects, var: include_related_objects}, {name: limit, var: limit}, {name: object_types, var: object_types}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    begin_time: $begin_time, cursor: $cursor, include_deleted_objects: $include_deleted_objects, include_related_objects: $include_related_objects, limit: $limit, object_types: $object_types, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchCatalogItems
#
# POST /v2/catalog/search-catalog-items
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, items: table<absent_at_location_ids: list, catalog_v1_ids: list, category_data: record, custom_attribute_definition_data: record, custom_attribute_values: record, discount_data: record, id: string, image_data: record, image_id: string, is_deleted: bool, item_data: record, item_option_data: record, item_option_value_data: record, item_variation_data: record, measurement_unit_data: record, modifier_data: record, modifier_list_data: record, present_at_all_locations: bool, present_at_location_ids: list, pricing_rule_data: record, product_set_data: record, quick_amounts_settings_data: record, subscription_plan_data: record, tax_data: record, time_period_data: record, type: string, updated_at: string, version: int>, matched_variation_ids: list<string>>
# operationId: SearchCatalogItems
export def "search-catalog-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-ids: list<string> # The category id query expression to return items containing the specified category IDs.
  --cursor: string # The pagination token, returned in the previous response, used to fetch the next batch of pending results.
  --custom-attribute-filters: list # The customer-attribute filter to return items or item variations matching the specified custom attribute expressions. A maximum number of 10 custom attribute expressions are supported in a single call to the [SearchCatalogItems](https://developer.squareup.com/reference/square_2021-08-18/catalog-api/search-catalog-items) endpoint. — item shape: {bool_filter?: bool, custom_attribute_definition_id?: string, key?: string, number_filter?: record, selection_uids_filter?: list<string>, string_filter?: string}
  --enabled-location-ids: list<string> # The enabled-location query expression to return items and item variations having specified enabled locations.
  --limit: int # The maximum number of results to return per page. The default value is 100.
  --product-types: list<string> # The product types query expression to return items or item variations having the specified product types.
  --sort-order: string # The order to sort the results by item names. The default sort order is ascending (`ASC`).
  --stock-levels: list<string> # The stock-level query expression to return item variations with the specified stock levels.
  --text-filter: string # The text filter expression to return items or item variations containing specified text in the `name`, `description`, or `abbreviation` attribute value of an item, or in the `name`, `sku`, or `upc` attribute value of an item variation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/catalog/search-catalog-items"
    body: {content_type: "application/json", kind: json, fields: [{name: category_ids, var: category_ids}, {name: cursor, var: cursor}, {name: custom_attribute_filters, var: custom_attribute_filters}, {name: enabled_location_ids, var: enabled_location_ids}, {name: limit, var: limit}, {name: product_types, var: product_types}, {name: sort_order, var: sort_order}, {name: stock_levels, var: stock_levels}, {name: text_filter, var: text_filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_ids: $category_ids, cursor: $cursor, custom_attribute_filters: $custom_attribute_filters, enabled_location_ids: $enabled_location_ids, limit: $limit, product_types: $product_types, sort_order: $sort_order, stock_levels: $stock_levels, text_filter: $text_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateItemModifierLists
#
# POST /v2/catalog/update-item-modifier-lists
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, updated_at: string>
# operationId: UpdateItemModifierLists
export def "update-item-modifier-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  item_ids: list<string> # The IDs of the catalog items associated with the CatalogModifierList objects being updated.
  --modifier-lists-to-disable: list<string> # The IDs of the CatalogModifierList objects to disable for the CatalogItem.
  --modifier-lists-to-enable: list<string> # The IDs of the CatalogModifierList objects to enable for the CatalogItem.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/catalog/update-item-modifier-lists"
    body: {content_type: "application/json", kind: json, fields: [{name: item_ids, var: item_ids}, {name: modifier_lists_to_disable, var: modifier_lists_to_disable}, {name: modifier_lists_to_enable, var: modifier_lists_to_enable}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_ids: $item_ids, modifier_lists_to_disable: $modifier_lists_to_disable, modifier_lists_to_enable: $modifier_lists_to_enable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateItemTaxes
#
# POST /v2/catalog/update-item-taxes
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, updated_at: string>
# operationId: UpdateItemTaxes
export def "update-item-taxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  item_ids: list<string> # IDs for the CatalogItems associated with the CatalogTax objects being updated.
  --taxes-to-disable: list<string> # IDs of the CatalogTax objects to disable.
  --taxes-to-enable: list<string> # IDs of the CatalogTax objects to enable.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/catalog/update-item-taxes"
    body: {content_type: "application/json", kind: json, fields: [{name: item_ids, var: item_ids}, {name: taxes_to_disable, var: taxes_to_disable}, {name: taxes_to_enable, var: taxes_to_enable}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_ids: $item_ids, taxes_to_disable: $taxes_to_disable, taxes_to_enable: $taxes_to_enable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListCustomers
#
# GET /v2/customers
# Returns: record<cursor: string, customers: table<address: record, birthday: string, cards: list, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list, id: string, nickname: string, note: string, phone_number: string, preferences: record, reference_id: string, segment_ids: list, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: ListCustomers
export def "list-customers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. The limit is ignored if it is less than 1 or greater than 100. The default value is 100. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --sort-field: string # Indicates how customers should be sorted. The default value is `DEFAULT`.
  --sort-order: string # Indicates whether customers should be sorted in ascending (`ASC`) or descending (`DESC`) order. The default value is `ASC`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: sort_field, var: sort_field}, {name: sort_order, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, sort_field: $sort_field, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateCustomer
#
# POST /v2/customers
# Returns: record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CreateCustomer
export def "create-customer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --birthday: string # The birthday associated with the customer profile, in RFC 3339 format. The year is optional. The timezone and time are not allowed. For example, `0000-09-21T00:00:00-00:00` represents a birthday on September 21 and `1998-09-21T00:00:00-00:00` represents a birthday on September 21, 1998. You can also specify this value in `YYYY-MM-DD` format.
  --company-name: string # A business name associated with the customer profile.
  --email-address: string # The email address associated with the customer profile.
  --family-name: string # The family name (that is, the last name) associated with the customer profile.
  --given-name: string # The given name (that is, the first name) associated with the customer profile.
  --idempotency-key: string # The idempotency key for the request. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --nickname: string # A nickname for the customer profile.
  --note: string # A custom note associated with the customer profile.
  --phone-number: string # The 11-digit phone number associated with the customer profile.
  --reference-id: string # An optional second ID used to associate the customer profile with an entity in another system.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/customers"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: birthday, var: birthday}, {name: company_name, var: company_name}, {name: email_address, var: email_address}, {name: family_name, var: family_name}, {name: given_name, var: given_name}, {name: idempotency_key, var: idempotency_key}, {name: nickname, var: nickname}, {name: note, var: note}, {name: phone_number, var: phone_number}, {name: reference_id, var: reference_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, birthday: $birthday, company_name: $company_name, email_address: $email_address, family_name: $family_name, given_name: $given_name, idempotency_key: $idempotency_key, nickname: $nickname, note: $note, phone_number: $phone_number, reference_id: $reference_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListCustomerGroups
#
# GET /v2/customers/groups
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, groups: table<created_at: string, id: string, name: string, updated_at: string>>
# operationId: ListCustomerGroups
export def "list-customer-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. The limit is ignored if it is less than 1 or greater than 50. The default value is 50. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/groups"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateCustomerGroup
#
# POST /v2/customers/groups
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>>
# operationId: CreateCustomerGroup
export def "create-customer-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  group: record # Represents a group of customer profiles. Customer groups can be created, be modified, and have their membership defined using the Customers API or within the Customer Directory in the Square Seller Dashboard or Point of Sale. — shape: {created_at?: string, id?: string, name: string, updated_at?: string}
  --idempotency-key: string # The idempotency key for the request. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/customers/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: group, var: group}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group: $group, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteCustomerGroup
#
# DELETE /v2/customers/groups/{group_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteCustomerGroup
export def "delete-customer-group" [
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
    path: "/v2/customers/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveCustomerGroup
#
# GET /v2/customers/groups/{group_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>>
# operationId: RetrieveCustomerGroup
export def "retrieve-customer-group" [
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
    path: "/v2/customers/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateCustomerGroup
#
# PUT /v2/customers/groups/{group_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, group: record<created_at: string, id: string, name: string, updated_at: string>>
# operationId: UpdateCustomerGroup
export def "update-customer-group" [
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
  group: record # Represents a group of customer profiles. Customer groups can be created, be modified, and have their membership defined using the Customers API or within the Customer Directory in the Square Seller Dashboard or Point of Sale. — shape: {created_at?: string, id?: string, name: string, updated_at?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/customers/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: group, var: group}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchCustomers
#
# POST /v2/customers/search
# Returns: record<cursor: string, customers: table<address: record, birthday: string, cards: list, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list, id: string, nickname: string, note: string, phone_number: string, preferences: record, reference_id: string, segment_ids: list, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: SearchCustomers
export def "search-customers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Include the pagination cursor in subsequent calls to this endpoint to retrieve the next set of results associated with the original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. The limit is ignored if it is less than the minimum or greater than the maximum value. The default value is 100. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination). (format: int64)
  --query: record # Represents a query (including filtering criteria, sorting criteria, or both) used to search for customer profiles. — shape: {filter?: record, sort?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/customers/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListCustomerSegments
#
# GET /v2/customers/segments
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, segments: table<created_at: string, id: string, name: string, updated_at: string>>
# operationId: ListCustomerSegments
export def "list-customer-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by previous calls to `ListCustomerSegments`. This cursor is used to retrieve the next set of query results. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. The limit is ignored if it is less than 1 or greater than 50. The default value is 50. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/segments"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveCustomerSegment
#
# GET /v2/customers/segments/{segment_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, segment: record<created_at: string, id: string, name: string, updated_at: string>>
# operationId: RetrieveCustomerSegment
export def "retrieve-customer-segment" [
  segment_id: string
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
    path: "/v2/customers/segments/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteCustomer
#
# DELETE /v2/customers/{customer_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteCustomer
export def "delete-customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The current version of the customer profile. As a best practice, you should include this parameter to enable [optimistic concurrency](https://developer.squareup.com/docs/working-with-apis/optimistic-concurrency) control. For more information, see [Delete a customer profile](https://developer.squareup.com/docs/customers-api/use-the-api/keep-records#delete-customer-profile). (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/customers/{customer_id}"
    path_params: [{name: customer_id, var: customer_id}]
    query: [{name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveCustomer
#
# GET /v2/customers/{customer_id}
# Returns: record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveCustomer
export def "retrieve-customer" [
  customer_id: string
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
    path: "/v2/customers/{customer_id}"
    path_params: [{name: customer_id, var: customer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateCustomer
#
# PUT /v2/customers/{customer_id}
# Returns: record<customer: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, birthday: string, cards: list<record>, company_name: string, created_at: string, creation_source: string, email_address: string, family_name: string, given_name: string, group_ids: list<string>, id: string, nickname: string, note: string, phone_number: string, preferences: record<email_unsubscribed: bool>, reference_id: string, segment_ids: list<string>, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: UpdateCustomer
export def "update-customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --birthday: string # The birthday associated with the customer profile, in RFC 3339 format. The year is optional. The timezone and time are not allowed. For example, `0000-09-21T00:00:00-00:00` represents a birthday on September 21 and `1998-09-21T00:00:00-00:00` represents a birthday on September 21, 1998. You can also specify this value in `YYYY-MM-DD` format.
  --company-name: string # A business name associated with the customer profile.
  --email-address: string # The email address associated with the customer profile.
  --family-name: string # The family name (that is, the last name) associated with the customer profile.
  --given-name: string # The given name (that is, the first name) associated with the customer profile.
  --nickname: string # A nickname for the customer profile.
  --note: string # A custom note associated with the customer profile.
  --phone-number: string # The 11-digit phone number associated with the customer profile.
  --reference-id: string # An optional second ID used to associate the customer profile with an entity in another system.
  --version: int # The current version of the customer profile. As a best practice, you should include this field to enable [optimistic concurrency](https://developer.squareup.com/docs/working-with-apis/optimistic-concurrency) control. For more information, see [Update a customer profile](https://developer.squareup.com/docs/customers-api/use-the-api/keep-records#update-a-customer-profile). (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/customers/{customer_id}"
    path_params: [{name: customer_id, var: customer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: birthday, var: birthday}, {name: company_name, var: company_name}, {name: email_address, var: email_address}, {name: family_name, var: family_name}, {name: given_name, var: given_name}, {name: nickname, var: nickname}, {name: note, var: note}, {name: phone_number, var: phone_number}, {name: reference_id, var: reference_id}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, address: $address, birthday: $birthday, company_name: $company_name, email_address: $email_address, family_name: $family_name, given_name: $given_name, nickname: $nickname, note: $note, phone_number: $phone_number, reference_id: $reference_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateCustomerCard
#
# POST /v2/customers/{customer_id}/cards
# Returns: record<card: record<billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, bin: string, card_brand: string, card_type: string, cardholder_name: string, customer_id: string, enabled: bool, exp_month: int, exp_year: int, fingerprint: string, id: string, last_4: string, prepaid_type: string, reference_id: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CreateCustomerCard
export def "create-customer-card" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  card_nonce: string # A card nonce representing the credit card to link to the customer. Card nonces are generated by the Square payment form when customers enter their card information. For more information, see [Walkthrough: Integrate Square Payments in a Website](https://developer.squareup.com/docs/web-payments/take-card-payment). __NOTE:__ Card nonces generated by digital wallets (such as Apple Pay) cannot be used to create a customer card.
  --cardholder-name: string # The full name printed on the credit card.
  --verification-token: string # An identifying token generated by [Payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/customers/{customer_id}/cards"
    path_params: [{name: customer_id, var: customer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing_address, var: billing_address}, {name: card_nonce, var: card_nonce}, {name: cardholder_name, var: cardholder_name}, {name: verification_token, var: verification_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, billing_address: $billing_address, card_nonce: $card_nonce, cardholder_name: $cardholder_name, verification_token: $verification_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteCustomerCard
#
# DELETE /v2/customers/{customer_id}/cards/{card_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteCustomerCard
export def "delete-customer-card" [
  customer_id: string
  card_id: string
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
    path: "/v2/customers/{customer_id}/cards/{card_id}"
    path_params: [{name: customer_id, var: customer_id}, {name: card_id, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RemoveGroupFromCustomer
#
# DELETE /v2/customers/{customer_id}/groups/{group_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RemoveGroupFromCustomer
export def "remove-group-from-customer" [
  customer_id: string
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
    path: "/v2/customers/{customer_id}/groups/{group_id}"
    path_params: [{name: customer_id, var: customer_id}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AddGroupToCustomer
#
# PUT /v2/customers/{customer_id}/groups/{group_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: AddGroupToCustomer
export def "add-group-to-customer" [
  customer_id: string
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
    method: put
    path: "/v2/customers/{customer_id}/groups/{group_id}"
    path_params: [{name: customer_id, var: customer_id}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListDeviceCodes
#
# GET /v2/devices/codes
# Returns: record<cursor: string, device_codes: table<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: ListDeviceCodes
export def "list-device-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. See [Paginating results](https://developer.squareup.com/docs/working-with-apis/pagination) for more information.
  --location-id: string # If specified, only returns DeviceCodes of the specified location. Returns DeviceCodes of all locations if empty.
  --product-type: string # If specified, only returns DeviceCodes targeting the specified product type. Returns DeviceCodes of all product types if empty.
  --status: string # If specified, returns DeviceCodes with the specified statuses. Returns DeviceCodes of status `PAIRED` and `UNPAIRED` if empty.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/devices/codes"
    query: [{name: cursor, var: cursor}, {name: location_id, var: location_id}, {name: product_type, var: product_type}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, location_id: $location_id, product_type: $product_type, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateDeviceCode
#
# POST /v2/devices/codes
# Returns: record<device_code: record<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CreateDeviceCode
export def "create-device-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  device_code: record # shape: {code?: string, created_at?: string, device_id?: string, id?: string, location_id?: string, name?: string, pair_by?: string, paired_at?: string, product_type: string, status?: string, status_changed_at?: string}
  idempotency_key: string # A unique string that identifies this CreateDeviceCode request. Keys can be any valid string but must be unique for every CreateDeviceCode request. See [Idempotency keys](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/devices/codes"
    body: {content_type: "application/json", kind: json, fields: [{name: device_code, var: device_code}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device_code: $device_code, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetDeviceCode
#
# GET /v2/devices/codes/{id}
# Returns: record<device_code: record<code: string, created_at: string, device_id: string, id: string, location_id: string, name: string, pair_by: string, paired_at: string, product_type: string, status: string, status_changed_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: GetDeviceCode
export def "get-device-code" [
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
    path: "/v2/devices/codes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListDisputes
#
# GET /v2/disputes
# Returns: record<cursor: string, disputes: table<amount_money: record, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record, due_at: string, evidence_ids: list, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: ListDisputes
export def "list-disputes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --states: string # The dispute states to filter the result. If not specified, the endpoint returns all open disputes (the dispute status is not `INQUIRY_CLOSED`, `WON`, or `LOST`).
  --location-id: string # The ID of the location for which to return a list of disputes. If not specified, the endpoint returns all open disputes (the dispute status is not `INQUIRY_CLOSED`, `WON`, or `LOST`) associated with all locations.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/disputes"
    query: [{name: cursor, var: cursor}, {name: states, var: states}, {name: location_id, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, states: $states, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveDispute
#
# GET /v2/disputes/{dispute_id}
# Returns: record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveDispute
export def "retrieve-dispute" [
  dispute_id: string
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
    path: "/v2/disputes/{dispute_id}"
    path_params: [{name: dispute_id, var: dispute_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dispute_id: $dispute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AcceptDispute
#
# POST /v2/disputes/{dispute_id}/accept
# Returns: record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: AcceptDispute
export def "accept-dispute" [
  dispute_id: string
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
    path: "/v2/disputes/{dispute_id}/accept"
    path_params: [{name: dispute_id, var: dispute_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dispute_id: $dispute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListDisputeEvidence
#
# GET /v2/disputes/{dispute_id}/evidence
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, evidence: table<dispute_id: string, evidence_file: record, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>>
# operationId: ListDisputeEvidence
export def "list-dispute-evidence" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/disputes/{dispute_id}/evidence"
    path_params: [{name: dispute_id, var: dispute_id}]
    query: [{name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dispute_id: $dispute_id, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateDisputeEvidenceText
#
# POST /v2/disputes/{dispute_id}/evidence-text
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>>
# operationId: CreateDisputeEvidenceText
export def "create-dispute-evidence-text" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  evidence_text: string # The evidence string.
  --evidence-type: string # The type of evidence you are uploading.
  idempotency_key: string # The Unique ID. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/disputes/{dispute_id}/evidence-text"
    path_params: [{name: dispute_id, var: dispute_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: evidence_text, var: evidence_text}, {name: evidence_type, var: evidence_type}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dispute_id: $dispute_id, evidence_text: $evidence_text, evidence_type: $evidence_type, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteDisputeEvidence
#
# DELETE /v2/disputes/{dispute_id}/evidence/{evidence_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteDisputeEvidence
export def "delete-dispute-evidence" [
  dispute_id: string
  evidence_id: string
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
    path: "/v2/disputes/{dispute_id}/evidence/{evidence_id}"
    path_params: [{name: dispute_id, var: dispute_id}, {name: evidence_id, var: evidence_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dispute_id: $dispute_id, evidence_id: $evidence_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveDisputeEvidence
#
# GET /v2/disputes/{dispute_id}/evidence/{evidence_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_id: string, evidence_text: string, evidence_type: string, id: string, uploaded_at: string>>
# operationId: RetrieveDisputeEvidence
export def "retrieve-dispute-evidence" [
  dispute_id: string
  evidence_id: string
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
    path: "/v2/disputes/{dispute_id}/evidence/{evidence_id}"
    path_params: [{name: dispute_id, var: dispute_id}, {name: evidence_id, var: evidence_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dispute_id: $dispute_id, evidence_id: $evidence_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SubmitEvidence
#
# POST /v2/disputes/{dispute_id}/submit-evidence
# Returns: record<dispute: record<amount_money: record<amount: int, currency: string>, brand_dispute_id: string, card_brand: string, created_at: string, dispute_id: string, disputed_payment: record<payment_id: string>, due_at: string, evidence_ids: list<string>, id: string, location_id: string, reason: string, reported_at: string, reported_date: string, state: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: SubmitEvidence
export def "submit-evidence" [
  dispute_id: string
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
    path: "/v2/disputes/{dispute_id}/submit-evidence"
    path_params: [{name: dispute_id, var: dispute_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dispute_id: $dispute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListEmployees
#
# GET /v2/employees
# Returns: record<cursor: string, employees: table<created_at: string, email: string, first_name: string, id: string, is_owner: bool, last_name: string, location_ids: list, phone_number: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
export def "get-v2-employees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string
  --status: string # Specifies the EmployeeStatus to filter the employee by.
  --limit: int # The number of employees to be returned on each page.
  --cursor: string # The token required to retrieve the specified page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/employees"
    query: [{name: location_id, var: location_id}, {name: status, var: status}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, status: $status, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveEmployee
#
# GET /v2/employees/{id}
# Returns: record<employee: record<created_at: string, email: string, first_name: string, id: string, is_owner: bool, last_name: string, location_ids: list<string>, phone_number: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
export def "get-v2-employees-id" [
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
    path: "/v2/employees/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListGiftCards
#
# GET /v2/gift-cards
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, gift_cards: table<balance_money: record, created_at: string, customer_ids: list, gan: string, gan_source: any, id: string, state: any, type: any>>
# operationId: ListGiftCards
export def "list-gift-cards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # If a type is provided, gift cards of this type are returned (see [GiftCardType](https://developer.squareup.com/reference/square_2021-08-18/enums/GiftCardType)). If no type is provided, it returns gift cards of all types.
  --state: string # If the state is provided, it returns the gift cards in the specified state (see [GiftCardStatus](https://developer.squareup.com/reference/square_2021-08-18/enums/GiftCardStatus)). Otherwise, it returns the gift cards of all states.
  --limit: int # If a value is provided, it returns only that number of results per page. The maximum number of results allowed per page is 50. The default value is 30.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. If a cursor is not provided, it returns the first page of the results. For more information, see [Pagination](https://developer.squareup.com/docs/docs/working-with-apis/pagination).
  --customer-id: string # If a value is provided, returns only the gift cards linked to the specified customer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/gift-cards"
    query: [{name: type, var: type}, {name: state, var: state}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: customer_id, var: customer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, state: $state, limit: $limit, cursor: $cursor, customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateGiftCard
#
# POST /v2/gift-cards
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>
# operationId: CreateGiftCard
export def "create-gift-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  gift_card: record # Represents a Square gift card. — shape: {balance_money?: record, created_at?: string, customer_ids?: list<string>, gan?: string, id?: string}
  idempotency_key: string # A unique string that identifies the `CreateGiftCard` request.
  location_id: string # The location ID where the gift card that will be created should be registered.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/gift-cards"
    body: {content_type: "application/json", kind: json, fields: [{name: gift_card, var: gift_card}, {name: idempotency_key, var: idempotency_key}, {name: location_id, var: location_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gift_card: $gift_card, idempotency_key: $idempotency_key, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListGiftCardActivities
#
# GET /v2/gift-cards/activities
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, gift_card_activities: table<activate_activity_details: record, adjust_decrement_activity_details: record, adjust_increment_activity_details: record, block_activity_details: record, clear_balance_activity_details: record, created_at: string, deactivate_activity_details: record, gift_card_balance_money: record, gift_card_gan: string, gift_card_id: string, id: string, import_activity_details: record, import_reversal_activity_details: record, load_activity_details: record, location_id: string, redeem_activity_details: record, refund_activity_details: record, type: any, unblock_activity_details: record, unlinked_activity_refund_activity_details: record>>
# operationId: ListGiftCardActivities
export def "list-gift-card-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --gift-card-id: string # If you provide a gift card ID, the endpoint returns activities that belong to the specified gift card. Otherwise, the endpoint returns all gift card activities for the seller.
  --type: string # If you provide a type, the endpoint returns gift card activities of this type. Otherwise, the endpoint returns all types of gift card activities.
  --location-id: string # If you provide a location ID, the endpoint returns gift card activities for that location. Otherwise, the endpoint returns gift card activities for all locations.
  --begin-time: string # The timestamp for the beginning of the reporting period, in RFC 3339 format. Inclusive. Default: The current time minus one year.
  --end-time: string # The timestamp for the end of the reporting period, in RFC 3339 format. Inclusive. Default: The current time.
  --limit: int # If you provide a limit value, the endpoint returns the specified number of results (or less) per page. A maximum value is 100. The default value is 50.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. If you do not provide the cursor, the call returns the first page of the results.
  --sort-order: string # The order in which the endpoint returns the activities, based on `created_at`. - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/gift-cards/activities"
    query: [{name: gift_card_id, var: gift_card_id}, {name: type, var: type}, {name: location_id, var: location_id}, {name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: sort_order, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gift_card_id: $gift_card_id, type: $type, location_id: $location_id, begin_time: $begin_time, end_time: $end_time, limit: $limit, cursor: $cursor, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateGiftCardActivity
#
# POST /v2/gift-cards/activities
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, gift_card_activity: record<activate_activity_details: record<amount_money: record, buyer_payment_instrument_ids: list, line_item_uid: string, order_id: string, reference_id: string>, adjust_decrement_activity_details: record<amount_money: record, reason: any>, adjust_increment_activity_details: record<amount_money: record, reason: any>, block_activity_details: record<reason: any>, clear_balance_activity_details: record<reason: any>, created_at: string, deactivate_activity_details: record<reason: any>, gift_card_balance_money: record<amount: int, currency: string>, gift_card_gan: string, gift_card_id: string, id: string, import_activity_details: record<amount_money: record>, import_reversal_activity_details: record<amount_money: record>, load_activity_details: record<amount_money: record, buyer_payment_instrument_ids: list, line_item_uid: string, order_id: string, reference_id: string>, location_id: string, redeem_activity_details: record<amount_money: record, payment_id: string, reference_id: string>, refund_activity_details: record<amount_money: record, payment_id: string, redeem_activity_id: string, reference_id: string>, type: any, unblock_activity_details: record<reason: any>, unlinked_activity_refund_activity_details: record<amount_money: record, payment_id: string, reference_id: string>>>
# operationId: CreateGiftCardActivity
export def "create-gift-card-activity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  gift_card_activity: record # Represents an action performed on a gift card that affects its state or balance. — shape: {activate_activity_details?: record, adjust_decrement_activity_details?: record, adjust_increment_activity_details?: record, block_activity_details?: record, clear_balance_activity_details?: record, created_at?: string, deactivate_activity_details?: record, gift_card_balance_money?: record, gift_card_gan?: string, gift_card_id?: string, id?: string, import_activity_details?: record, import_reversal_activity_details?: record, load_activity_details?: record, location_id: string, ... (4 more fields)}
  idempotency_key: string # A unique string that identifies the `CreateGiftCardActivity` request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/gift-cards/activities"
    body: {content_type: "application/json", kind: json, fields: [{name: gift_card_activity, var: gift_card_activity}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gift_card_activity: $gift_card_activity, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveGiftCardFromGAN
#
# POST /v2/gift-cards/from-gan
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>
# operationId: RetrieveGiftCardFromGAN
export def "retrieve-gift-card-from-gan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  gan: string # The gift card account number (GAN) of the gift card to retrieve. The maximum length of a GAN is 255 digits to account for third-party GANs that have been imported. Square-issued gift cards have 16-digit GANs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/gift-cards/from-gan"
    body: {content_type: "application/json", kind: json, fields: [{name: gan, var: gan}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gan: $gan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveGiftCardFromNonce
#
# POST /v2/gift-cards/from-nonce
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>
# operationId: RetrieveGiftCardFromNonce
export def "retrieve-gift-card-from-nonce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  nonce: string # The nonce of the gift card to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/gift-cards/from-nonce"
    body: {content_type: "application/json", kind: json, fields: [{name: nonce, var: nonce}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    nonce: $nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LinkCustomerToGiftCard
#
# POST /v2/gift-cards/{gift_card_id}/link-customer
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>
# operationId: LinkCustomerToGiftCard
export def "link-customer-to-gift-card" [
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # The ID of the customer to be linked.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/gift-cards/{gift_card_id}/link-customer"
    path_params: [{name: gift_card_id, var: gift_card_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customer_id, var: customer_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gift_card_id: $gift_card_id, customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UnlinkCustomerFromGiftCard
#
# POST /v2/gift-cards/{gift_card_id}/unlink-customer
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>
# operationId: UnlinkCustomerFromGiftCard
export def "unlink-customer-from-gift-card" [
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/gift-cards/{gift_card_id}/unlink-customer"
    path_params: [{name: gift_card_id, var: gift_card_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customer_id, var: customer_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gift_card_id: $gift_card_id, customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveGiftCard
#
# GET /v2/gift-cards/{id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<balance_money: record<amount: int, currency: string>, created_at: string, customer_ids: list<string>, gan: string, gan_source: any, id: string, state: any, type: any>>
# operationId: RetrieveGiftCard
export def "retrieve-gift-card" [
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
    path: "/v2/gift-cards/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeprecatedRetrieveInventoryAdjustment
#
# GET /v2/inventory/adjustment/{adjustment_id}
# Returns: record<adjustment: record<adjustment_group: record<from_state: string, id: string, root_adjustment_id: string, to_state: string>, catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_state: string, goods_receipt_id: string, id: string, location_id: string, occurred_at: string, purchase_order_id: string, quantity: string, reference_id: string, refund_id: string, source: record<application_id: string, name: string, product: string>, to_state: string, total_price_money: record<amount: int, currency: string>, transaction_id: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeprecatedRetrieveInventoryAdjustment
export def "deprecated-retrieve-inventory-adjustment" [
  adjustment_id: string
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
    path: "/v2/inventory/adjustment/{adjustment_id}"
    path_params: [{name: adjustment_id, var: adjustment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    adjustment_id: $adjustment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveInventoryAdjustment
#
# GET /v2/inventory/adjustments/{adjustment_id}
# Returns: record<adjustment: record<adjustment_group: record<from_state: string, id: string, root_adjustment_id: string, to_state: string>, catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_state: string, goods_receipt_id: string, id: string, location_id: string, occurred_at: string, purchase_order_id: string, quantity: string, reference_id: string, refund_id: string, source: record<application_id: string, name: string, product: string>, to_state: string, total_price_money: record<amount: int, currency: string>, transaction_id: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveInventoryAdjustment
export def "retrieve-inventory-adjustment" [
  adjustment_id: string
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
    path: "/v2/inventory/adjustments/{adjustment_id}"
    path_params: [{name: adjustment_id, var: adjustment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    adjustment_id: $adjustment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeprecatedBatchChangeInventory
#
# POST /v2/inventory/batch-change
# Returns: record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeprecatedBatchChangeInventory
export def "deprecated-batch-change-inventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --changes: list # The set of physical counts and inventory adjustments to be made. Changes are applied based on the client-supplied timestamp and may be sent out of order. — item shape: {adjustment?: record, measurement_unit?: record, measurement_unit_id?: string, physical_count?: record, transfer?: record, type?: string}
  idempotency_key: string # A client-supplied, universally unique identifier (UUID) for the request. See [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency) in the [API Development 101](https://developer.squareup.com/docs/basics/api101/overview) section for more information.
  --ignore-unchanged-counts: oneof<nothing, bool> # Indicates whether the current physical count should be ignored if the quantity is unchanged since the last physical count. Default: `true`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/inventory/batch-change"
    body: {content_type: "application/json", kind: json, fields: [{name: changes, var: changes}, {name: idempotency_key, var: idempotency_key}, {name: ignore_unchanged_counts, var: ignore_unchanged_counts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    changes: $changes, idempotency_key: $idempotency_key, ignore_unchanged_counts: $ignore_unchanged_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeprecatedBatchRetrieveInventoryChanges
#
# POST /v2/inventory/batch-retrieve-changes
# Returns: record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeprecatedBatchRetrieveInventoryChanges
export def "deprecated-batch-retrieve-inventory-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-object-ids: list<string> # The filter to return results by `CatalogObject` ID. The filter is only applicable when set. The default value is null.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --location-ids: list<string> # The filter to return results by `Location` ID. The filter is only applicable when set. The default value is null.
  --states: list<string> # The filter to return `ADJUSTMENT` query results by `InventoryState`. This filter is only applied when set. The default value is null.
  --types: list<string> # The filter to return results by `InventoryChangeType` values other than `TRANSFER`. The default value is `[PHYSICAL_COUNT, ADJUSTMENT]`.
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
  --updated-before: string # The filter to return results with their `created_at` or `calculated_at` value strictly before the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/inventory/batch-retrieve-changes"
    body: {content_type: "application/json", kind: json, fields: [{name: catalog_object_ids, var: catalog_object_ids}, {name: cursor, var: cursor}, {name: location_ids, var: location_ids}, {name: states, var: states}, {name: types, var: types}, {name: updated_after, var: updated_after}, {name: updated_before, var: updated_before}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog_object_ids: $catalog_object_ids, cursor: $cursor, location_ids: $location_ids, states: $states, types: $types, updated_after: $updated_after, updated_before: $updated_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeprecatedBatchRetrieveInventoryCounts
#
# POST /v2/inventory/batch-retrieve-counts
# Returns: record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeprecatedBatchRetrieveInventoryCounts
export def "deprecated-batch-retrieve-inventory-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-object-ids: list<string> # The filter to return results by `CatalogObject` ID. The filter is applicable only when set. The default is null.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --location-ids: list<string> # The filter to return results by `Location` ID. This filter is applicable only when set. The default is null.
  --states: list<string> # The filter to return results by `InventoryState`. The filter is only applicable when set. Ignored are untracked states of `NONE`, `SOLD`, and `UNLINKED_RETURN`. The default is null.
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/inventory/batch-retrieve-counts"
    body: {content_type: "application/json", kind: json, fields: [{name: catalog_object_ids, var: catalog_object_ids}, {name: cursor, var: cursor}, {name: location_ids, var: location_ids}, {name: states, var: states}, {name: updated_after, var: updated_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog_object_ids: $catalog_object_ids, cursor: $cursor, location_ids: $location_ids, states: $states, updated_after: $updated_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BatchChangeInventory
#
# POST /v2/inventory/changes/batch-create
# Returns: record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: BatchChangeInventory
export def "batch-change-inventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --changes: list # The set of physical counts and inventory adjustments to be made. Changes are applied based on the client-supplied timestamp and may be sent out of order. — item shape: {adjustment?: record, measurement_unit?: record, measurement_unit_id?: string, physical_count?: record, transfer?: record, type?: string}
  idempotency_key: string # A client-supplied, universally unique identifier (UUID) for the request. See [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency) in the [API Development 101](https://developer.squareup.com/docs/basics/api101/overview) section for more information.
  --ignore-unchanged-counts: oneof<nothing, bool> # Indicates whether the current physical count should be ignored if the quantity is unchanged since the last physical count. Default: `true`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/inventory/changes/batch-create"
    body: {content_type: "application/json", kind: json, fields: [{name: changes, var: changes}, {name: idempotency_key, var: idempotency_key}, {name: ignore_unchanged_counts, var: ignore_unchanged_counts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    changes: $changes, idempotency_key: $idempotency_key, ignore_unchanged_counts: $ignore_unchanged_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BatchRetrieveInventoryChanges
#
# POST /v2/inventory/changes/batch-retrieve
# Returns: record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: BatchRetrieveInventoryChanges
export def "batch-retrieve-inventory-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-object-ids: list<string> # The filter to return results by `CatalogObject` ID. The filter is only applicable when set. The default value is null.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --location-ids: list<string> # The filter to return results by `Location` ID. The filter is only applicable when set. The default value is null.
  --states: list<string> # The filter to return `ADJUSTMENT` query results by `InventoryState`. This filter is only applied when set. The default value is null.
  --types: list<string> # The filter to return results by `InventoryChangeType` values other than `TRANSFER`. The default value is `[PHYSICAL_COUNT, ADJUSTMENT]`.
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
  --updated-before: string # The filter to return results with their `created_at` or `calculated_at` value strictly before the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/inventory/changes/batch-retrieve"
    body: {content_type: "application/json", kind: json, fields: [{name: catalog_object_ids, var: catalog_object_ids}, {name: cursor, var: cursor}, {name: location_ids, var: location_ids}, {name: states, var: states}, {name: types, var: types}, {name: updated_after, var: updated_after}, {name: updated_before, var: updated_before}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog_object_ids: $catalog_object_ids, cursor: $cursor, location_ids: $location_ids, states: $states, types: $types, updated_after: $updated_after, updated_before: $updated_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BatchRetrieveInventoryCounts
#
# POST /v2/inventory/counts/batch-retrieve
# Returns: record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: BatchRetrieveInventoryCounts
export def "batch-retrieve-inventory-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-object-ids: list<string> # The filter to return results by `CatalogObject` ID. The filter is applicable only when set. The default is null.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --location-ids: list<string> # The filter to return results by `Location` ID. This filter is applicable only when set. The default is null.
  --states: list<string> # The filter to return results by `InventoryState`. The filter is only applicable when set. Ignored are untracked states of `NONE`, `SOLD`, and `UNLINKED_RETURN`. The default is null.
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/inventory/counts/batch-retrieve"
    body: {content_type: "application/json", kind: json, fields: [{name: catalog_object_ids, var: catalog_object_ids}, {name: cursor, var: cursor}, {name: location_ids, var: location_ids}, {name: states, var: states}, {name: updated_after, var: updated_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog_object_ids: $catalog_object_ids, cursor: $cursor, location_ids: $location_ids, states: $states, updated_after: $updated_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeprecatedRetrieveInventoryPhysicalCount
#
# GET /v2/inventory/physical-count/{physical_count_id}
# Returns: record<count: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, id: string, location_id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeprecatedRetrieveInventoryPhysicalCount
export def "deprecated-retrieve-inventory-physical-count" [
  physical_count_id: string
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
    path: "/v2/inventory/physical-count/{physical_count_id}"
    path_params: [{name: physical_count_id, var: physical_count_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    physical_count_id: $physical_count_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveInventoryPhysicalCount
#
# GET /v2/inventory/physical-counts/{physical_count_id}
# Returns: record<count: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, id: string, location_id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveInventoryPhysicalCount
export def "retrieve-inventory-physical-count" [
  physical_count_id: string
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
    path: "/v2/inventory/physical-counts/{physical_count_id}"
    path_params: [{name: physical_count_id, var: physical_count_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    physical_count_id: $physical_count_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveInventoryTransfer
#
# GET /v2/inventory/transfers/{transfer_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, transfer: record<catalog_object_id: string, catalog_object_type: string, created_at: string, employee_id: string, from_location_id: string, id: string, occurred_at: string, quantity: string, reference_id: string, source: record<application_id: string, name: string, product: string>, state: string, to_location_id: string>>
# operationId: RetrieveInventoryTransfer
export def "retrieve-inventory-transfer" [
  transfer_id: string
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
    path: "/v2/inventory/transfers/{transfer_id}"
    path_params: [{name: transfer_id, var: transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transfer_id: $transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveInventoryCount
#
# GET /v2/inventory/{catalog_object_id}
# Returns: record<counts: table<calculated_at: string, catalog_object_id: string, catalog_object_type: string, is_estimated: bool, location_id: string, quantity: string, state: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveInventoryCount
export def "retrieve-inventory-count" [
  catalog_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-ids: string # The [Location](https://developer.squareup.com/reference/square_2021-08-18/objects/Location) IDs to look up as a comma-separated list. An empty list queries all locations.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/inventory/{catalog_object_id}"
    path_params: [{name: catalog_object_id, var: catalog_object_id}]
    query: [{name: location_ids, var: location_ids}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog_object_id: $catalog_object_id, location_ids: $location_ids, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveInventoryChanges
#
# GET /v2/inventory/{catalog_object_id}/changes
# Returns: record<changes: table<adjustment: record, measurement_unit: record, measurement_unit_id: string, physical_count: record, transfer: record, type: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: RetrieveInventoryChanges
export def "retrieve-inventory-changes" [
  catalog_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-ids: string # The [Location](https://developer.squareup.com/reference/square_2021-08-18/objects/Location) IDs to look up as a comma-separated list. An empty list queries all locations.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/inventory/{catalog_object_id}/changes"
    path_params: [{name: catalog_object_id, var: catalog_object_id}]
    query: [{name: location_ids, var: location_ids}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog_object_id: $catalog_object_id, location_ids: $location_ids, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListInvoices
#
# GET /v2/invoices
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, invoices: table<accepted_payment_methods: record, created_at: string, custom_fields: list, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record, order_id: string, payment_requests: list, primary_recipient: record, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>
# operationId: ListInvoices
export def "list-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location for which to list invoices. (required)
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of invoices to return (200 is the maximum `limit`). If not provided, the server uses a default limit of 100 invoices.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/invoices"
    query: [{name: location_id, var: location_id, required: true}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateInvoice
#
# POST /v2/invoices
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>
# operationId: CreateInvoice
export def "create-invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique string that identifies the `CreateInvoice` request. If you do not provide `idempotency_key` (or provide an empty string as the value), the endpoint treats each request as independent. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  invoice: record # Stores information about an invoice. You use the Invoices API to create and manage invoices. For more information, see [Manage Invoices Using the Invoices API](https://developer.squareup.com/docs/invoices-api/overview). — shape: {accepted_payment_methods?: record, created_at?: string, custom_fields?: list, description?: string, id?: string, invoice_number?: string, location_id?: string, next_payment_amount_money?: record, order_id?: string, payment_requests?: list, primary_recipient?: record, public_url?: string, scheduled_at?: string, status?: string, subscription_id?: string, timezone?: string, title?: string, updated_at?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/invoices"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: invoice, var: invoice}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, invoice: $invoice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchInvoices
#
# POST /v2/invoices/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, invoices: table<accepted_payment_methods: record, created_at: string, custom_fields: list, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record, order_id: string, payment_requests: list, primary_recipient: record, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>
# operationId: SearchInvoices
export def "search-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of invoices to return (200 is the maximum `limit`). If not provided, the server uses a default limit of 100 invoices.
  query: record # Describes query criteria for searching invoices. — shape: {filter: record, sort?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/invoices/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteInvoice
#
# DELETE /v2/invoices/{invoice_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteInvoice
export def "delete-invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version of the [invoice](https://developer.squareup.com/reference/square_2021-08-18/objects/Invoice) to delete. If you do not know the version, you can call [GetInvoice](https://developer.squareup.com/reference/square_2021-08-18/invoices-api/get-invoice) or [ListInvoices](https://developer.squareup.com/reference/square_2021-08-18/invoices-api/list-invoices).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/invoices/{invoice_id}"
    path_params: [{name: invoice_id, var: invoice_id}]
    query: [{name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetInvoice
#
# GET /v2/invoices/{invoice_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>
# operationId: GetInvoice
export def "get-invoice" [
  invoice_id: string
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
    path: "/v2/invoices/{invoice_id}"
    path_params: [{name: invoice_id, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateInvoice
#
# PUT /v2/invoices/{invoice_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>
# operationId: UpdateInvoice
export def "update-invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-to-clear: list<string> # The list of fields to clear. For examples, see [Update an invoice](https://developer.squareup.com/docs/invoices-api/overview#update-an-invoice).
  --idempotency-key: string # A unique string that identifies the `UpdateInvoice` request. If you do not provide `idempotency_key` (or provide an empty string as the value), the endpoint treats each request as independent. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  invoice: record # Stores information about an invoice. You use the Invoices API to create and manage invoices. For more information, see [Manage Invoices Using the Invoices API](https://developer.squareup.com/docs/invoices-api/overview). — shape: {accepted_payment_methods?: record, created_at?: string, custom_fields?: list, description?: string, id?: string, invoice_number?: string, location_id?: string, next_payment_amount_money?: record, order_id?: string, payment_requests?: list, primary_recipient?: record, public_url?: string, scheduled_at?: string, status?: string, subscription_id?: string, timezone?: string, title?: string, updated_at?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/invoices/{invoice_id}"
    path_params: [{name: invoice_id, var: invoice_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fields_to_clear, var: fields_to_clear}, {name: idempotency_key, var: idempotency_key}, {name: invoice, var: invoice}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, fields_to_clear: $fields_to_clear, idempotency_key: $idempotency_key, invoice: $invoice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CancelInvoice
#
# POST /v2/invoices/{invoice_id}/cancel
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>
# operationId: CancelInvoice
export def "cancel-invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  version: int # The version of the [invoice](https://developer.squareup.com/reference/square_2021-08-18/objects/Invoice) to cancel. If you do not know the version, you can call [GetInvoice](https://developer.squareup.com/reference/square_2021-08-18/invoices-api/get-invoice) or [ListInvoices](https://developer.squareup.com/reference/square_2021-08-18/invoices-api/list-invoices).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/invoices/{invoice_id}/cancel"
    path_params: [{name: invoice_id, var: invoice_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PublishInvoice
#
# POST /v2/invoices/{invoice_id}/publish
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, invoice: record<accepted_payment_methods: record<bank_account: bool, card: bool, square_gift_card: bool>, created_at: string, custom_fields: list<record>, delivery_method: any, description: string, id: string, invoice_number: string, location_id: string, next_payment_amount_money: record<amount: int, currency: string>, order_id: string, payment_requests: list<record>, primary_recipient: record<address: record, company_name: string, customer_id: string, email_address: string, family_name: string, given_name: string, phone_number: string>, public_url: string, scheduled_at: string, status: string, subscription_id: string, timezone: string, title: string, updated_at: string, version: int>>
# operationId: PublishInvoice
export def "publish-invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique string that identifies the `PublishInvoice` request. If you do not provide `idempotency_key` (or provide an empty string as the value), the endpoint treats each request as independent. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  version: int # The version of the [invoice](https://developer.squareup.com/reference/square_2021-08-18/objects/Invoice) to publish. This must match the current version of the invoice; otherwise, the request is rejected.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/invoices/{invoice_id}/publish"
    path_params: [{name: invoice_id, var: invoice_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, idempotency_key: $idempotency_key, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListBreakTypes
#
# GET /v2/labor/break-types
# Returns: record<break_types: table<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: ListBreakTypes
export def "list-break-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # Filter the returned `BreakType` results to only those that are associated with the specified location.
  --limit: int # The maximum number of `BreakType` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `BreakType` results to fetch.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/labor/break-types"
    query: [{name: location_id, var: location_id}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateBreakType
#
# POST /v2/labor/break-types
# Returns: record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CreateBreakType
export def "create-break-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  break_type: record # A defined break template that sets an expectation for possible `Break` instances on a `Shift`. — shape: {break_name: string, created_at?: string, expected_duration: string, id?: string, is_paid: bool, location_id: string, updated_at?: string, version?: int}
  --idempotency-key: string # A unique string value to ensure the idempotency of the operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/labor/break-types"
    body: {content_type: "application/json", kind: json, fields: [{name: break_type, var: break_type}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    break_type: $break_type, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteBreakType
#
# DELETE /v2/labor/break-types/{id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteBreakType
export def "delete-break-type" [
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
    method: delete
    path: "/v2/labor/break-types/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetBreakType
#
# GET /v2/labor/break-types/{id}
# Returns: record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: GetBreakType
export def "get-break-type" [
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
    path: "/v2/labor/break-types/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateBreakType
#
# PUT /v2/labor/break-types/{id}
# Returns: record<break_type: record<break_name: string, created_at: string, expected_duration: string, id: string, is_paid: bool, location_id: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: UpdateBreakType
export def "update-break-type" [
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
  break_type: record # A defined break template that sets an expectation for possible `Break` instances on a `Shift`. — shape: {break_name: string, created_at?: string, expected_duration: string, id?: string, is_paid: bool, location_id: string, updated_at?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/labor/break-types/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: break_type, var: break_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, break_type: $break_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListEmployeeWages
#
# GET /v2/labor/employee-wages
# Returns: record<cursor: string, employee_wages: table<employee_id: string, hourly_rate: record, id: string, title: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: ListEmployeeWages
export def "list-employee-wages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employee-id: string # Filter the returned wages to only those that are associated with the specified employee.
  --limit: int # The maximum number of `EmployeeWage` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `EmployeeWage` results to fetch.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/labor/employee-wages"
    query: [{name: employee_id, var: employee_id}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employee_id: $employee_id, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetEmployeeWage
#
# GET /v2/labor/employee-wages/{id}
# Returns: record<employee_wage: record<employee_id: string, hourly_rate: record<amount: int, currency: string>, id: string, title: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: GetEmployeeWage
export def "get-employee-wage" [
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
    path: "/v2/labor/employee-wages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateShift
#
# POST /v2/labor/shifts
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>>
# operationId: CreateShift
export def "create-shift" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique string value to ensure the idempotency of the operation.
  shift: record # A record of the hourly rate, start, and end times for a single work shift for an employee. This might include a record of the start and end times for breaks taken during the shift. — shape: {breaks?: list, created_at?: string, employee_id?: string, end_at?: string, id?: string, location_id?: string, start_at: string, status?: string, team_member_id?: string, timezone?: string, updated_at?: string, version?: int, wage?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/labor/shifts"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: shift, var: shift}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, shift: $shift
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchShifts
#
# POST /v2/labor/shifts/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, shifts: table<breaks: list, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record>>
# operationId: SearchShifts
export def "search-shifts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # An opaque cursor for fetching the next page.
  --limit: int # The number of resources in a page (200 by default).
  --query: record # The parameters of a `Shift` search query, which includes filter and sort options. — shape: {filter?: record, sort?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/labor/shifts/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteShift
#
# DELETE /v2/labor/shifts/{id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteShift
export def "delete-shift" [
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
    method: delete
    path: "/v2/labor/shifts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetShift
#
# GET /v2/labor/shifts/{id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>>
# operationId: GetShift
export def "get-shift" [
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
    path: "/v2/labor/shifts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateShift
#
# PUT /v2/labor/shifts/{id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, shift: record<breaks: list<record>, created_at: string, employee_id: string, end_at: string, id: string, location_id: string, start_at: string, status: string, team_member_id: string, timezone: string, updated_at: string, version: int, wage: record<hourly_rate: record, title: string>>>
# operationId: UpdateShift
export def "update-shift" [
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
  shift: record # A record of the hourly rate, start, and end times for a single work shift for an employee. This might include a record of the start and end times for breaks taken during the shift. — shape: {breaks?: list, created_at?: string, employee_id?: string, end_at?: string, id?: string, location_id?: string, start_at: string, status?: string, team_member_id?: string, timezone?: string, updated_at?: string, version?: int, wage?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/labor/shifts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: shift, var: shift}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, shift: $shift
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListTeamMemberWages
#
# GET /v2/labor/team-member-wages
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_member_wages: table<hourly_rate: record, id: string, team_member_id: string, title: string>>
# operationId: ListTeamMemberWages
export def "list-team-member-wages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-member-id: string # Filter the returned wages to only those that are associated with the specified team member.
  --limit: int # The maximum number of `TeamMemberWage` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `EmployeeWage` results to fetch.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/labor/team-member-wages"
    query: [{name: team_member_id, var: team_member_id}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_member_id: $team_member_id, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetTeamMemberWage
#
# GET /v2/labor/team-member-wages/{id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, team_member_wage: record<hourly_rate: record<amount: int, currency: string>, id: string, team_member_id: string, title: string>>
# operationId: GetTeamMemberWage
export def "get-team-member-wage" [
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
    path: "/v2/labor/team-member-wages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListWorkweekConfigs
#
# GET /v2/labor/workweek-configs
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, workweek_configs: table<created_at: string, id: string, start_of_day_local_time: string, start_of_week: string, updated_at: string, version: int>>
# operationId: ListWorkweekConfigs
export def "list-workweek-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of `WorkweekConfigs` results to return per page.
  --cursor: string # A pointer to the next page of `WorkweekConfig` results to fetch.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/labor/workweek-configs"
    query: [{name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateWorkweekConfig
#
# PUT /v2/labor/workweek-configs/{id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, workweek_config: record<created_at: string, id: string, start_of_day_local_time: string, start_of_week: string, updated_at: string, version: int>>
# operationId: UpdateWorkweekConfig
export def "update-workweek-config" [
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
  workweek_config: record # Sets the day of the week and hour of the day that a business starts a workweek. This is used to calculate overtime pay. — shape: {created_at?: string, id?: string, start_of_day_local_time: string, start_of_week: string, updated_at?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/labor/workweek-configs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: workweek_config, var: workweek_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, workweek_config: $workweek_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListLocations
#
# GET /v2/locations
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, locations: table<address: record, business_email: string, business_hours: record, business_name: string, capabilities: list, coordinates: record, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record, timezone: string, twitter_username: string, type: string, website_url: string>>
# operationId: ListLocations
export def "list-locations" [
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
    path: "/v2/locations"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateLocation
#
# POST /v2/locations
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>>
# operationId: CreateLocation
export def "create-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # shape: {address?: record, business_email?: string, business_hours?: record, business_name?: string, capabilities?: list<string>, coordinates?: record, country?: string, created_at?: string, currency?: string, description?: string, facebook_url?: string, full_format_logo_url?: string, id?: string, instagram_username?: string, language_code?: string, logo_url?: string, mcc?: string, merchant_id?: string, name?: string, phone_number?: string, pos_background_url?: string, status?: string, tax_ids?: record, ... (4 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/locations"
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveLocation
#
# GET /v2/locations/{location_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>>
# operationId: RetrieveLocation
export def "retrieve-location" [
  location_id: string
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
    path: "/v2/locations/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateLocation
#
# PUT /v2/locations/{location_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, location: record<address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, business_email: string, business_hours: record<periods: list>, business_name: string, capabilities: list<string>, coordinates: record<latitude: float, longitude: float>, country: string, created_at: string, currency: string, description: string, facebook_url: string, full_format_logo_url: string, id: string, instagram_username: string, language_code: string, logo_url: string, mcc: string, merchant_id: string, name: string, phone_number: string, pos_background_url: string, status: string, tax_ids: record<eu_vat: string, fr_naf: string, fr_siret: string>, timezone: string, twitter_username: string, type: string, website_url: string>>
# operationId: UpdateLocation
export def "update-location" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # shape: {address?: record, business_email?: string, business_hours?: record, business_name?: string, capabilities?: list<string>, coordinates?: record, country?: string, created_at?: string, currency?: string, description?: string, facebook_url?: string, full_format_logo_url?: string, id?: string, instagram_username?: string, language_code?: string, logo_url?: string, mcc?: string, merchant_id?: string, name?: string, phone_number?: string, pos_background_url?: string, status?: string, tax_ids?: record, ... (4 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/locations/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateCheckout
#
# POST /v2/locations/{location_id}/checkouts
# Returns: record<checkout: record<additional_recipients: list<record>, ask_for_shipping_address: bool, checkout_page_url: string, created_at: string, id: string, merchant_support_email: string, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>, pre_populate_buyer_email: string, pre_populate_shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, redirect_url: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CreateCheckout
export def "create-checkout" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-recipients: list # The basic primitive of a multi-party transaction. The value is optional. The transaction facilitated by you can be split from here. If you provide this value, the `amount_money` value in your `additional_recipients` field cannot be more than 90% of the `total_money` calculated by Square for your order. The `location_id` must be a valid seller location where the checkout is occurring. This field requires `PAYMENTS_WRITE_ADDITIONAL_RECIPIENTS` OAuth permission. This field is currently not supported in the Square Sandbox. — item shape: {amount_money: record, description: string, location_id: string}
  --ask-for-shipping-address: oneof<nothing, bool> # If `true`, Square Checkout collects shipping information on your behalf and stores that information with the transaction information in the Square Seller Dashboard. Default: `false`.
  idempotency_key: string # A unique string that identifies this checkout among others you have created. It can be any valid string but must be unique for every order sent to Square Checkout for a given location ID. The idempotency key is used to avoid processing the same order more than once. If you are unsure whether a particular checkout was created successfully, you can attempt it again with the same idempotency key and all the same other parameters without worrying about creating duplicates. You should use a random number/string generator native to the language you are working in to generate strings for your idempotency keys. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --merchant-support-email: string # The email address to display on the Square Checkout confirmation page and confirmation email that the buyer can use to contact the seller. If this value is not set, the confirmation page and email display the primary email address associated with the seller's Square account. Default: none; only exists if explicitly set.
  --note: string # An optional note to associate with the `checkout` object. This value cannot exceed 60 characters.
  order: record # e.g. {request_body: {idempotency_key: 8193148c-9586-11e6-99f9-28cfe92138cf, order: {discounts: [{name: Labor Day Sale, percentage: 5, scope: ORDER, uid: labor-day-sale}, {catalog_object_id: DB7L55ZH2BGWI4H23ULIWOQ7, scope: ORDER, uid: membership-discount}, {amount_money: {amount: 100, currency: USD}, name: Sale - $1.00 off, scope: LINE_ITEM, uid: one-dollar-off}], line_items: [{base_price_money: {amount: 1599, currency: USD}, name: New York Strip Steak, quantity: 1}, {applied_discounts: [{discount_uid: one-dollar-off}], catalog_object_id: BEMYCSMIJL46OCDV4KYIKXIB, modifiers: [{catalog_object_id: CHQX7Y4KY6N5KINJKZCFURPZ}], quantity: 2}], location_id: 057P5VYJ4A5X1, reference_id: my-order-001, taxes: [{name: State Sales Tax, percentage: 9, scope: ORDER, uid: state-sales-tax}]}}} — shape: {idempotency_key?: string, order?: record}
  --pre-populate-buyer-email: string # If provided, the buyer's email is prepopulated on the checkout page as an editable text field. Default: none; only exists if explicitly set.
  --pre-populate-shipping-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --redirect-url: string # The URL to redirect to after the checkout is completed with `checkoutId`, `transactionId`, and `referenceId` appended as URL parameters. For example, if the provided redirect URL is `http://www.example.com/order-complete`, a successful transaction redirects the customer to: http://www.example.com/order-complete?checkoutId=xxxxxx&referenceId=xxxxxx&transactionId=xxxxxx If you do not provide a redirect URL, Square Checkout displays an order confirmation page on your behalf; however, it is strongly recommended that you provide a redirect URL so you can verify the transaction results and finalize the order through your existing/normal confirmation workflow. Default: none; only exists if explicitly set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/locations/{location_id}/checkouts"
    path_params: [{name: location_id, var: location_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additional_recipients, var: additional_recipients}, {name: ask_for_shipping_address, var: ask_for_shipping_address}, {name: idempotency_key, var: idempotency_key}, {name: merchant_support_email, var: merchant_support_email}, {name: note, var: note}, {name: order, var: order}, {name: pre_populate_buyer_email, var: pre_populate_buyer_email}, {name: pre_populate_shipping_address, var: pre_populate_shipping_address}, {name: redirect_url, var: redirect_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, additional_recipients: $additional_recipients, ask_for_shipping_address: $ask_for_shipping_address, idempotency_key: $idempotency_key, merchant_support_email: $merchant_support_email, note: $note, order: $order, pre_populate_buyer_email: $pre_populate_buyer_email, pre_populate_shipping_address: $pre_populate_shipping_address, redirect_url: $redirect_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListRefunds
#
# GET /v2/locations/{location_id}/refunds
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<additional_recipients: list, amount_money: record, created_at: string, id: string, location_id: string, processing_fee_money: record, reason: string, status: string, tender_id: string, transaction_id: string>>
export def "get-v2-locations-location-id-refunds" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # The beginning of the requested reporting period, in RFC 3339 format. See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in RFC 3339 format. See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity. Default value: The current time.
  --sort-order: string # The order in which results are listed in the response (`ASC` for oldest first, `DESC` for newest first). Default value: `DESC`
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. See [Paginating results](https://developer.squareup.com/docs/working-with-apis/pagination) for more information.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/locations/{location_id}/refunds"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: sort_order, var: sort_order}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, begin_time: $begin_time, end_time: $end_time, sort_order: $sort_order, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListTransactions
#
# GET /v2/locations/{location_id}/transactions
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, transactions: table<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list, shipping_address: record, tenders: list>>
# operationId: ListTransactions
export def "list-transactions" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # The beginning of the requested reporting period, in RFC 3339 format. See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity. Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in RFC 3339 format. See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity. Default value: The current time.
  --sort-order: string # The order in which results are listed in the response (`ASC` for oldest first, `DESC` for newest first). Default value: `DESC`
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. See [Paginating results](https://developer.squareup.com/docs/working-with-apis/pagination) for more information.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/locations/{location_id}/transactions"
    path_params: [{name: location_id, var: location_id}]
    query: [{name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: sort_order, var: sort_order}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, begin_time: $begin_time, end_time: $end_time, sort_order: $sort_order, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charge
#
# POST /v2/locations/{location_id}/transactions
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, transaction: record<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list<record>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, tenders: list<record>>>
# operationId: Charge
export def "charge" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-recipients: list # The basic primitive of multi-party transaction. The value is optional. The transaction facilitated by you can be split from here. If you provide this value, the `amount_money` value in your additional_recipients must not be more than 90% of the `amount_money` value in the charge request. The `location_id` must be the valid location of the app owner merchant. This field requires the `PAYMENTS_WRITE_ADDITIONAL_RECIPIENTS` OAuth permission. This field is currently not supported in sandbox. — item shape: {amount_money: record, description?: string, location_id: string, receivable_id?: string}
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --billing-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --buyer-email-address: string # The buyer's email address, if available. This value is optional, but this transaction is ineligible for chargeback protection if it is not provided.
  --card-nonce: string # A payment token generated from the [Card.tokenize()](https://developer.squareup.com/reference/sdks/web/payments/objects/Card#Card.tokenize) that represents the card to charge. The application that provides a payment token to this endpoint must be the _same application_ that generated the payment token with the Web Payments SDK. Otherwise, the nonce is invalid. Do not provide a value for this field if you provide a value for `customer_card_id`.
  --customer-card-id: string # The ID of the customer card on file to charge. Do not provide a value for this field if you provide a value for `card_nonce`. If you provide this value, you _must_ also provide a value for `customer_id`.
  --customer-id: string # The ID of the customer to associate this transaction with. This field is required if you provide a value for `customer_card_id`, and optional otherwise.
  --delay-capture: oneof<nothing, bool> # If `true`, the request will only perform an Auth on the provided card. You can then later perform either a Capture (with the [CaptureTransaction](https://developer.squareup.com/reference/square_2021-08-18/transactions-api/capture-transaction) endpoint) or a Void (with the [VoidTransaction](https://developer.squareup.com/reference/square_2021-08-18/transactions-api/void-transaction) endpoint). Default value: `false`
  idempotency_key: string # A value you specify that uniquely identifies this transaction among transactions you've created. If you're unsure whether a particular transaction succeeded, you can reattempt it with the same idempotency key without worrying about double-charging the buyer. See [Idempotency keys](https://developer.squareup.com/docs/working-with-apis/idempotency) for more information.
  --note: string # An optional note to associate with the transaction. This value cannot exceed 60 characters.
  --order-id: string # The ID of the order to associate with this transaction. If you provide this value, the `amount_money` value of your request must __exactly match__ the value of the order's `total_money` field.
  --reference-id: string # An optional ID you can associate with the transaction for your own purposes (such as to associate the transaction with an entity ID in your own database). This value cannot exceed 40 characters.
  --shipping-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --verification-token: string # A token generated by SqPaymentForm's verifyBuyer() that represents customer's device info and 3ds challenge result.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/locations/{location_id}/transactions"
    path_params: [{name: location_id, var: location_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additional_recipients, var: additional_recipients}, {name: amount_money, var: amount_money}, {name: billing_address, var: billing_address}, {name: buyer_email_address, var: buyer_email_address}, {name: card_nonce, var: card_nonce}, {name: customer_card_id, var: customer_card_id}, {name: customer_id, var: customer_id}, {name: delay_capture, var: delay_capture}, {name: idempotency_key, var: idempotency_key}, {name: note, var: note}, {name: order_id, var: order_id}, {name: reference_id, var: reference_id}, {name: shipping_address, var: shipping_address}, {name: verification_token, var: verification_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, additional_recipients: $additional_recipients, amount_money: $amount_money, billing_address: $billing_address, buyer_email_address: $buyer_email_address, card_nonce: $card_nonce, customer_card_id: $customer_card_id, customer_id: $customer_id, delay_capture: $delay_capture, idempotency_key: $idempotency_key, note: $note, order_id: $order_id, reference_id: $reference_id, shipping_address: $shipping_address, verification_token: $verification_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveTransaction
#
# GET /v2/locations/{location_id}/transactions/{transaction_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, transaction: record<client_id: string, created_at: string, id: string, location_id: string, order_id: string, product: string, reference_id: string, refunds: list<record>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, tenders: list<record>>>
# operationId: RetrieveTransaction
export def "retrieve-transaction" [
  location_id: string
  transaction_id: string
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
    path: "/v2/locations/{location_id}/transactions/{transaction_id}"
    path_params: [{name: location_id, var: location_id}, {name: transaction_id, var: transaction_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CaptureTransaction
#
# POST /v2/locations/{location_id}/transactions/{transaction_id}/capture
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CaptureTransaction
export def "capture-transaction" [
  location_id: string
  transaction_id: string
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
    path: "/v2/locations/{location_id}/transactions/{transaction_id}/capture"
    path_params: [{name: location_id, var: location_id}, {name: transaction_id, var: transaction_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateRefund
#
# POST /v2/locations/{location_id}/transactions/{transaction_id}/refund
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<additional_recipients: list<record>, amount_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, processing_fee_money: record<amount: int, currency: string>, reason: string, status: string, tender_id: string, transaction_id: string>>
export def "post-v2-locations-location-id-transactions-transaction-id-refund" [
  location_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  idempotency_key: string # A value you specify that uniquely identifies this refund among refunds you've created for the tender. If you're unsure whether a particular refund succeeded, you can reattempt it with the same idempotency key without worrying about duplicating the refund. See [Idempotency keys](https://developer.squareup.com/docs/working-with-apis/idempotency) for more information.
  --reason: string # A description of the reason for the refund. Default value: `Refund via API`
  tender_id: string # The ID of the tender to refund. A [`Transaction`](https://developer.squareup.com/reference/square_2021-08-18/objects/Transaction) has one or more `tenders` (i.e., methods of payment) associated with it, and you refund each tender separately with the Connect API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/locations/{location_id}/transactions/{transaction_id}/refund"
    path_params: [{name: location_id, var: location_id}, {name: transaction_id, var: transaction_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount_money, var: amount_money}, {name: idempotency_key, var: idempotency_key}, {name: reason, var: reason}, {name: tender_id, var: tender_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, transaction_id: $transaction_id, amount_money: $amount_money, idempotency_key: $idempotency_key, reason: $reason, tender_id: $tender_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# VoidTransaction
#
# POST /v2/locations/{location_id}/transactions/{transaction_id}/void
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: VoidTransaction
export def "void-transaction" [
  location_id: string
  transaction_id: string
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
    path: "/v2/locations/{location_id}/transactions/{transaction_id}/void"
    path_params: [{name: location_id, var: location_id}, {name: transaction_id, var: transaction_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateLoyaltyAccount
#
# POST /v2/loyalty/accounts
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_account: record<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list<record>, id: string, lifetime_points: int, mapping: record<created_at: string, id: string, phone_number: string>, program_id: string, updated_at: string>>
# operationId: CreateLoyaltyAccount
export def "create-loyalty-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `CreateLoyaltyAccount` request. Keys can be any valid string, but must be unique for every request.
  loyalty_account: record # Describes a loyalty account. For more information, see [Manage Loyalty Accounts Using the Loyalty API](https://developer.squareup.com/docs/loyalty-api/overview). — shape: {balance?: int, created_at?: string, customer_id?: string, enrolled_at?: string, expiring_point_deadlines?: list, id?: string, lifetime_points?: int, mapping?: record, program_id: string, updated_at?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: loyalty_account, var: loyalty_account}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, loyalty_account: $loyalty_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchLoyaltyAccounts
#
# POST /v2/loyalty/accounts/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, loyalty_accounts: table<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list, id: string, lifetime_points: int, mapping: record, program_id: string, updated_at: string>>
# operationId: SearchLoyaltyAccounts
export def "search-loyalty-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --limit: int # The maximum number of results to include in the response.
  --query: record # The search criteria for the loyalty accounts. — shape: {customer_ids?: list<string>, mappings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/accounts/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveLoyaltyAccount
#
# GET /v2/loyalty/accounts/{account_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_account: record<balance: int, created_at: string, customer_id: string, enrolled_at: string, expiring_point_deadlines: list<record>, id: string, lifetime_points: int, mapping: record<created_at: string, id: string, phone_number: string>, program_id: string, updated_at: string>>
# operationId: RetrieveLoyaltyAccount
export def "retrieve-loyalty-account" [
  account_id: string
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
    path: "/v2/loyalty/accounts/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AccumulateLoyaltyPoints
#
# POST /v2/loyalty/accounts/{account_id}/accumulate
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>>
# operationId: AccumulateLoyaltyPoints
export def "accumulate-loyalty-points" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  accumulate_points: record # Provides metadata when the event `type` is `ACCUMULATE_POINTS`. — shape: {loyalty_program_id?: string, order_id?: string, points?: int}
  idempotency_key: string # A unique string that identifies the `AccumulateLoyaltyPoints` request. Keys can be any valid string but must be unique for every request.
  location_id: string # The [location](https://developer.squareup.com/reference/square_2021-08-18/objects/Location) where the purchase was made.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/accounts/{account_id}/accumulate"
    path_params: [{name: account_id, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accumulate_points, var: accumulate_points}, {name: idempotency_key, var: idempotency_key}, {name: location_id, var: location_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, accumulate_points: $accumulate_points, idempotency_key: $idempotency_key, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AdjustLoyaltyPoints
#
# POST /v2/loyalty/accounts/{account_id}/adjust
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>>
# operationId: AdjustLoyaltyPoints
export def "adjust-loyalty-points" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  adjust_points: record # Provides metadata when the event `type` is `ADJUST_POINTS`. — shape: {loyalty_program_id?: string, points: int, reason?: string}
  idempotency_key: string # A unique string that identifies this `AdjustLoyaltyPoints` request. Keys can be any valid string, but must be unique for every request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/accounts/{account_id}/adjust"
    path_params: [{name: account_id, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: adjust_points, var: adjust_points}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, adjust_points: $adjust_points, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchLoyaltyEvents
#
# POST /v2/loyalty/events/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, events: table<accumulate_points: record, adjust_points: record, create_reward: record, created_at: string, delete_reward: record, expire_points: record, id: string, location_id: string, loyalty_account_id: string, other_event: record, redeem_reward: record, source: string, type: string>>
# operationId: SearchLoyaltyEvents
export def "search-loyalty-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --limit: int # The maximum number of results to include in the response. The last page might contain fewer events. The default is 30 events.
  --query: record # Represents a query used to search for loyalty events. — shape: {filter?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/events/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListLoyaltyPrograms
#
# GET /v2/loyalty/programs
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, programs: table<accrual_rules: list, created_at: string, expiration_policy: record, id: string, location_ids: list, reward_tiers: list, status: string, terminology: record, updated_at: string>>
# operationId: ListLoyaltyPrograms
export def "list-loyalty-programs" [
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
    path: "/v2/loyalty/programs"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveLoyaltyProgram
#
# GET /v2/loyalty/programs/{program_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, program: record<accrual_rules: list<record>, created_at: string, expiration_policy: record<expiration_duration: string>, id: string, location_ids: list<string>, reward_tiers: list<record>, status: string, terminology: record<one: string, other: string>, updated_at: string>>
# operationId: RetrieveLoyaltyProgram
export def "retrieve-loyalty-program" [
  program_id: string
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
    path: "/v2/loyalty/programs/{program_id}"
    path_params: [{name: program_id, var: program_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    program_id: $program_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CalculateLoyaltyPoints
#
# POST /v2/loyalty/programs/{program_id}/calculate
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, points: int>
# operationId: CalculateLoyaltyPoints
export def "calculate-loyalty-points" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # The [order](https://developer.squareup.com/reference/square_2021-08-18/objects/Order) ID for which to calculate the points. Specify this field if your application uses the Orders API to process orders. Otherwise, specify the `transaction_amount_money`.
  --transaction-amount-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/programs/{program_id}/calculate"
    path_params: [{name: program_id, var: program_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: order_id, var: order_id}, {name: transaction_amount_money, var: transaction_amount_money}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    program_id: $program_id, order_id: $order_id, transaction_amount_money: $transaction_amount_money
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateLoyaltyReward
#
# POST /v2/loyalty/rewards
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, reward: record<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>>
# operationId: CreateLoyaltyReward
export def "create-loyalty-reward" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `CreateLoyaltyReward` request. Keys can be any valid string, but must be unique for every request.
  reward: record # Represents a contract to redeem loyalty points for a [reward tier](https://developer.squareup.com/reference/square_2021-08-18/objects/LoyaltyProgramRewardTier) discount. Loyalty rewards can be in an ISSUED, REDEEMED, or DELETED state. For more information, see [Redeem loyalty rewards](https://developer.squareup.com/docs/loyalty-api/overview#redeem-loyalty-rewards). — shape: {created_at?: string, id?: string, loyalty_account_id: string, order_id?: string, points?: int, redeemed_at?: string, reward_tier_id: string, status?: string, updated_at?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/rewards"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: reward, var: reward}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, reward: $reward
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchLoyaltyRewards
#
# POST /v2/loyalty/rewards/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, rewards: table<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>>
# operationId: SearchLoyaltyRewards
export def "search-loyalty-rewards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --limit: int # The maximum number of results to return in the response.
  --query: record # The set of search requirements. — shape: {loyalty_account_id: string, status?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/rewards/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteLoyaltyReward
#
# DELETE /v2/loyalty/rewards/{reward_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteLoyaltyReward
export def "delete-loyalty-reward" [
  reward_id: string
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
    path: "/v2/loyalty/rewards/{reward_id}"
    path_params: [{name: reward_id, var: reward_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reward_id: $reward_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveLoyaltyReward
#
# GET /v2/loyalty/rewards/{reward_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, reward: record<created_at: string, id: string, loyalty_account_id: string, order_id: string, points: int, redeemed_at: string, reward_tier_id: string, status: string, updated_at: string>>
# operationId: RetrieveLoyaltyReward
export def "retrieve-loyalty-reward" [
  reward_id: string
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
    path: "/v2/loyalty/rewards/{reward_id}"
    path_params: [{name: reward_id, var: reward_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reward_id: $reward_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RedeemLoyaltyReward
#
# POST /v2/loyalty/rewards/{reward_id}/redeem
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, event: record<accumulate_points: record<loyalty_program_id: string, order_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, create_reward: record<loyalty_program_id: string, points: int, reward_id: string>, created_at: string, delete_reward: record<loyalty_program_id: string, points: int, reward_id: string>, expire_points: record<loyalty_program_id: string, points: int>, id: string, location_id: string, loyalty_account_id: string, other_event: record<loyalty_program_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, order_id: string, reward_id: string>, source: string, type: string>>
# operationId: RedeemLoyaltyReward
export def "redeem-loyalty-reward" [
  reward_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `RedeemLoyaltyReward` request. Keys can be any valid string, but must be unique for every request.
  location_id: string # The ID of the [location](https://developer.squareup.com/reference/square_2021-08-18/objects/Location) where the reward is redeemed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/loyalty/rewards/{reward_id}/redeem"
    path_params: [{name: reward_id, var: reward_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: location_id, var: location_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reward_id: $reward_id, idempotency_key: $idempotency_key, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListMerchants
#
# GET /v2/merchants
# Returns: record<cursor: int, errors: table<category: string, code: string, detail: string, field: string>, merchant: table<business_name: string, country: string, currency: string, id: string, language_code: string, main_location_id: string, status: string>>
# operationId: ListMerchants
export def "list-merchants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: int # The cursor generated by the previous response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/merchants"
    query: [{name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveMerchant
#
# GET /v2/merchants/{merchant_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, merchant: record<business_name: string, country: string, currency: string, id: string, language_code: string, main_location_id: string, status: string>>
# operationId: RetrieveMerchant
export def "retrieve-merchant" [
  merchant_id: string
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
    path: "/v2/merchants/{merchant_id}"
    path_params: [{name: merchant_id, var: merchant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateOrder
#
# POST /v2/orders
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>
# operationId: CreateOrder
export def "create-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A value you specify that uniquely identifies this order among orders you have created. If you are unsure whether a particular order was created successfully, you can try it again with the same idempotency key without worrying about creating duplicate orders. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency).
  --order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns. All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/orders"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BatchRetrieveOrders
#
# POST /v2/orders/batch-retrieve
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, orders: table<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>>
# operationId: BatchRetrieveOrders
export def "batch-retrieve-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The ID of the location for these orders. This field is optional: omit it to retrieve orders within the scope of the current authorization's merchant ID.
  order_ids: list<string> # The IDs of the orders to retrieve. A maximum of 100 orders can be retrieved per request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/orders/batch-retrieve"
    body: {content_type: "application/json", kind: json, fields: [{name: location_id, var: location_id}, {name: order_ids, var: order_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, order_ids: $order_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CalculateOrder
#
# POST /v2/orders/calculate
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>
# operationId: CalculateOrder
export def "calculate-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns. All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
  --proposed-rewards: list # Identifies one or more loyalty reward tiers to apply during the order calculation. The discounts defined by the reward tiers are added to the order only to preview the effect of applying the specified rewards. The rewards do not correspond to actual redemptions; that is, no `reward`s are created. Therefore, the reward `id`s are random strings used only to reference the reward tier. — item shape: {id: string, reward_tier_id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/orders/calculate"
    body: {content_type: "application/json", kind: json, fields: [{name: order, var: order}, {name: proposed_rewards, var: proposed_rewards}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order: $order, proposed_rewards: $proposed_rewards
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchOrders
#
# POST /v2/orders/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, order_entries: table<location_id: string, order_id: string, version: int>, orders: table<closed_at: string, created_at: string, customer_id: string, discounts: list, fulfillments: list, id: string, line_items: list, location_id: string, metadata: record, net_amounts: record, pricing_options: record, reference_id: string, refunds: list, return_amounts: record, returns: list, rewards: list, rounding_adjustment: record, service_charges: list, source: record, state: string, taxes: list, tenders: list, total_discount_money: record, total_money: record, total_service_charge_money: record, total_tax_money: record, total_tip_money: record, updated_at: string, version: int>>
# operationId: SearchOrders
export def "search-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. Default: `500`
  --location-ids: list<string> # The location IDs for the orders to query. All locations must belong to the same merchant. Min: 1 location ID. Max: 10 location IDs.
  --query: record # Contains query criteria for the search. — shape: {filter?: record, sort?: record}
  --return-entries: oneof<nothing, bool> # A Boolean that controls the format of the search results. If `true`, `SearchOrders` returns [OrderEntry](https://developer.squareup.com/reference/square_2021-08-18/objects/OrderEntry) objects. If `false`, `SearchOrders` returns complete order objects. Default: `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/orders/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: location_ids, var: location_ids}, {name: query, var: query}, {name: return_entries, var: return_entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, location_ids: $location_ids, query: $query, return_entries: $return_entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveOrder
#
# GET /v2/orders/{order_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>
export def "get-v2-orders-order-id" [
  order_id: string
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
    path: "/v2/orders/{order_id}"
    path_params: [{name: order_id, var: order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateOrder
#
# PUT /v2/orders/{order_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>
export def "put-v2-orders-order-id" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-to-clear: list<string> # The [dot notation paths](https://developer.squareup.com/docs/orders-api/manage-orders#on-dot-notation) fields to clear. For example, `line_items[uid].note`. For more information, see [Deleting fields](https://developer.squareup.com/docs/orders-api/manage-orders#delete-fields).
  --idempotency-key: string # A value you specify that uniquely identifies this update request. If you are unsure whether a particular update was applied to an order successfully, you can reattempt it with the same idempotency key without worrying about creating duplicate updates to the order. The latest order version is returned. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency).
  --order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns. All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {closed_at?: string, created_at?: string, customer_id?: string, discounts?: list, fulfillments?: list, id?: string, line_items?: list, location_id: string, metadata?: record, net_amounts?: record, pricing_options?: record, reference_id?: string, refunds?: list, return_amounts?: record, returns?: list, rewards?: list, rounding_adjustment?: record, service_charges?: list, source?: record, state?: string, taxes?: list, tenders?: list, total_discount_money?: record, total_money?: record, ... (5 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/orders/{order_id}"
    path_params: [{name: order_id, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fields_to_clear, var: fields_to_clear}, {name: idempotency_key, var: idempotency_key}, {name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, fields_to_clear: $fields_to_clear, idempotency_key: $idempotency_key, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PayOrder
#
# POST /v2/orders/{order_id}/pay
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, order: record<closed_at: string, created_at: string, customer_id: string, discounts: list<record>, fulfillments: list<record>, id: string, line_items: list<record>, location_id: string, metadata: record, net_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, reference_id: string, refunds: list<record>, return_amounts: record<discount_money: record, service_charge_money: record, tax_money: record, tip_money: record, total_money: record>, returns: list<record>, rewards: list<record>, rounding_adjustment: record<amount_money: record, name: string, uid: string>, service_charges: list<record>, source: record<name: string>, state: string, taxes: list<record>, tenders: list<record>, total_discount_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, updated_at: string, version: int>>
# operationId: PayOrder
export def "pay-order" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A value you specify that uniquely identifies this request among requests you have sent. If you are unsure whether a particular payment request was completed successfully, you can reattempt it with the same idempotency key without worrying about duplicate payments. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --order-version: int # The version of the order being paid. If not supplied, the latest version will be paid.
  --payment-ids: list<string> # The IDs of the [payments](https://developer.squareup.com/reference/square_2021-08-18/objects/Payment) to collect. The payment total must match the order total.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/orders/{order_id}/pay"
    path_params: [{name: order_id, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: order_version, var: order_version}, {name: payment_ids, var: payment_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, idempotency_key: $idempotency_key, order_version: $order_version, payment_ids: $payment_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListPayments
#
# GET /v2/payments
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, payments: table<amount_money: record, app_fee_money: record, approved_money: record, bank_account_details: record, billing_address: record, buyer_email_address: string, capabilities: list, card_details: record, cash_details: record, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record, id: string, location_id: string, note: string, order_id: string, processing_fee: list, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list, refunded_money: record, risk_evaluation: record, shipping_address: record, source_type: string, statement_description_identifier: string, status: string, tip_money: record, total_money: record, updated_at: string, version_token: string, wallet_details: record>>
export def "get-v2-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # The timestamp for the beginning of the reporting period, in RFC 3339 format. Inclusive. Default: The current time minus one year.
  --end-time: string # The timestamp for the end of the reporting period, in RFC 3339 format. Default: The current time.
  --sort-order: string # The order in which results are listed: - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --location-id: string # Limit results to the location supplied. By default, results are returned for the default (main) location associated with the seller.
  --total: int # The exact amount in the `total_money` for a payment. (format: int64)
  --last-4: string # The last four digits of a payment card.
  --card-brand: string # The brand of the payment card (for example, VISA).
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. The default value of 100 is also the maximum allowed value. If the provided value is greater than 100, it is ignored and the default value is used instead. Default: `100`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/payments"
    query: [{name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: sort_order, var: sort_order}, {name: cursor, var: cursor}, {name: location_id, var: location_id}, {name: total, var: total}, {name: last_4, var: last_4}, {name: card_brand, var: card_brand}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    begin_time: $begin_time, end_time: $end_time, sort_order: $sort_order, cursor: $cursor, location_id: $location_id, total: $total, last_4: $last_4, card_brand: $card_brand, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreatePayment
#
# POST /v2/payments
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>
# operationId: CreatePayment
export def "create-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-partial-authorization: oneof<nothing, bool> # If set to `true` and charging a Square Gift Card, a payment might be returned with `amount_money` equal to less than what was requested. For example, a request for $20 when charging a Square Gift Card with a balance of $5 results in an APPROVED payment of $5. You might choose to prompt the buyer for an additional payment to cover the remainder or cancel the Gift Card payment. This field cannot be `true` when `autocomplete = true`. For more information, see [Partial amount with Square Gift Cards](https://developer.squareup.com/docs/payments-api/take-payments#partial-payment-gift-card). Default: false
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --app-fee-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --autocomplete: oneof<nothing, bool> # If set to `true`, this payment will be completed when possible. If set to `false`, this payment is held in an approved state until either explicitly completed (captured) or canceled (voided). For more information, see [Delayed capture](https://developer.squareup.com/docs/payments-api/take-payments/card-payments#delayed-capture-of-a-card-payment). Default: true
  --billing-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  --buyer-email-address: string # The buyer's email address.
  --cash-details: record # Stores details about a cash payment. Contains only non-confidential information. For more information, see [Take Cash Payments](https://developer.squareup.com/docs/payments-api/take-payments/cash-payments). — shape: {buyer_supplied_money: record, change_back_money?: record}
  --customer-id: string # The [Customer](https://developer.squareup.com/reference/square_2021-08-18/objects/Customer) ID of the customer associated with the payment. This is required if the `source_id` refers to a card on file created using the Customers API.
  --delay-duration: string # The duration of time after the payment's creation when Square automatically cancels the payment. This automatic cancellation applies only to payments that do not reach a terminal state (COMPLETED, CANCELED, or FAILED) before the `delay_duration` time period. This parameter should be specified as a time duration, in RFC 3339 format, with a minimum value of 1 minute. Note: This feature is only supported for card payments. This parameter can only be set for a delayed capture payment (`autocomplete=false`). Default: - Card-present payments: "PT36H" (36 hours) from the creation time. - Card-not-present payments: "P7D" (7 days) from the creation time.
  --external-details: record # Stores details about an external payment. Contains only non-confidential information. For more information, see [Take External Payments](https://developer.squareup.com/docs/payments-api/take-payments/external-payments). — shape: {source: string, source_fee_money?: record, source_id?: string, type: string}
  idempotency_key: string # A unique string that identifies this `CreatePayment` request. Keys can be any valid string but must be unique for every `CreatePayment` request. Max: 45 characters Note: The number of allowed characters might be less than the stated maximum, if multi-byte characters are used. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --location-id: string # The location ID to associate with the payment. If not specified, the default location is used.
  --note: string # An optional note to be entered by the developer when creating a payment. Limit 500 characters.
  --order-id: string # Associates a previously created order with this payment.
  --reference-id: string # A user-defined ID to associate with the payment. You can use this field to associate the payment to an entity in an external system (for example, you might specify an order ID that is generated by a third-party shopping cart). Limit 40 characters.
  --shipping-address: record # Represents a postal address in a country. The address format is based on an [open-source library from Google](https://github.com/google/libaddressinput). For more information, see [AddressValidationMetadata](https://github.com/google/libaddressinput/wiki/AddressValidationMetadata). This format has dedicated fields for four address components: postal code, locality (city), administrative district (state, prefecture, or province), and sublocality (town or village). These components have dedicated fields in the `Address` object because software sometimes behaves differently based on them. For example, sales tax software may charge different amounts of sales tax based on the postal code, and some software is only available in certain states due to compliance reasons. For the remaining address components, the `Address` type provides the `address_line_1` and `address_line_2` fields for free-form data entry. These fields are free-form because the remaining address components have too many variations around the world and typical software does not parse these components. These fields enable users to enter anything they want. Note that, in the current implementation, all other `Address` type fields are blank. These include `address_line_3`, `sublocality_2`, `sublocality_3`, `administrative_district_level_2`, `administrative_district_level_3`, `first_name`, `last_name`, and `organization`. When it comes to localization, the seller's language preferences (see [Language preferences](https://developer.squareup.com/docs/locations-api#location-specific-and-seller-level-language-preferences)) are ignored for addresses. Even though Square products (such as Square Point of Sale and the Seller Dashboard) mostly use a seller's language preference in communication, when it comes to addresses, they will use English for a US address, Japanese for an address in Japan, and so on. — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, country?: string, first_name?: string, last_name?: string, locality?: string, organization?: string, postal_code?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string}
  source_id: string # The ID for the source of funds for this payment. This can be a payment token (card nonce) generated by the Square payment form or a card on file made with the Customers API. If recording a payment that the seller received outside of Square, specify either "CASH" or "EXTERNAL". For more information, see [Take Payments](https://developer.squareup.com/docs/payments-api/take-payments).
  --statement-description-identifier: string # Optional additional payment information to include on the customer's card statement as part of the statement description. This can be, for example, an invoice number, ticket number, or short description that uniquely identifies the purchase. Note that the `statement_description_identifier` might get truncated on the statement description to fit the required information including the Square identifier (SQ *) and name of the seller taking the payment.
  --tip-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --verification-token: string # An identifying token generated by [payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity. For more information, see [SCA Overview](https://developer.squareup.com/docs/sca-overview).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/payments"
    body: {content_type: "application/json", kind: json, fields: [{name: accept_partial_authorization, var: accept_partial_authorization}, {name: amount_money, var: amount_money}, {name: app_fee_money, var: app_fee_money}, {name: autocomplete, var: autocomplete}, {name: billing_address, var: billing_address}, {name: buyer_email_address, var: buyer_email_address}, {name: cash_details, var: cash_details}, {name: customer_id, var: customer_id}, {name: delay_duration, var: delay_duration}, {name: external_details, var: external_details}, {name: idempotency_key, var: idempotency_key}, {name: location_id, var: location_id}, {name: note, var: note}, {name: order_id, var: order_id}, {name: reference_id, var: reference_id}, {name: shipping_address, var: shipping_address}, {name: source_id, var: source_id}, {name: statement_description_identifier, var: statement_description_identifier}, {name: tip_money, var: tip_money}, {name: verification_token, var: verification_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accept_partial_authorization: $accept_partial_authorization, amount_money: $amount_money, app_fee_money: $app_fee_money, autocomplete: $autocomplete, billing_address: $billing_address, buyer_email_address: $buyer_email_address, cash_details: $cash_details, customer_id: $customer_id, delay_duration: $delay_duration, external_details: $external_details, idempotency_key: $idempotency_key, location_id: $location_id, note: $note, order_id: $order_id, reference_id: $reference_id, shipping_address: $shipping_address, source_id: $source_id, statement_description_identifier: $statement_description_identifier, tip_money: $tip_money, verification_token: $verification_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CancelPaymentByIdempotencyKey
#
# POST /v2/payments/cancel
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CancelPaymentByIdempotencyKey
export def "cancel-payment-by-idempotency-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # The `idempotency_key` identifying the payment to be canceled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/payments/cancel"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetPayment
#
# GET /v2/payments/{payment_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>
# operationId: GetPayment
export def "get-payment" [
  payment_id: string
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
    path: "/v2/payments/{payment_id}"
    path_params: [{name: payment_id, var: payment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdatePayment
#
# PUT /v2/payments/{payment_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>
# operationId: UpdatePayment
export def "update-payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `UpdatePayment` request. Keys can be any valid string but must be unique for every `UpdatePayment` request. The maximum is 45 characters. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency).
  --payment: record # Represents a payment processed by the Square API. — shape: {amount_money?: record, app_fee_money?: record, approved_money?: record, bank_account_details?: record, billing_address?: record, buyer_email_address?: string, capabilities?: list<string>, card_details?: record, cash_details?: record, created_at?: string, customer_id?: string, delay_action?: string, delay_duration?: string, delayed_until?: string, employee_id?: string, external_details?: record, id?: string, location_id?: string, note?: string, order_id?: string, processing_fee?: list, ... (15 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/payments/{payment_id}"
    path_params: [{name: payment_id, var: payment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: payment, var: payment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id, idempotency_key: $idempotency_key, payment: $payment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CancelPayment
#
# POST /v2/payments/{payment_id}/cancel
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>
# operationId: CancelPayment
export def "cancel-payment" [
  payment_id: string
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
    path: "/v2/payments/{payment_id}/cancel"
    path_params: [{name: payment_id, var: payment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CompletePayment
#
# POST /v2/payments/{payment_id}/complete
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, approved_money: record<amount: int, currency: string>, bank_account_details: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, errors: list, fingerprint: string, statement_description: string, transfer_type: string>, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, buyer_email_address: string, capabilities: list<string>, card_details: record<application_cryptogram: string, application_identifier: string, application_name: string, auth_result_code: string, avs_status: string, card: record, card_payment_timeline: record, cvv_status: string, device_details: record, entry_method: string, errors: list, refund_requires_card_presence: bool, statement_description: string, status: string, verification_method: string, verification_results: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, created_at: string, customer_id: string, delay_action: string, delay_duration: string, delayed_until: string, employee_id: string, external_details: record<source: string, source_fee_money: record, source_id: string, type: string>, id: string, location_id: string, note: string, order_id: string, processing_fee: list<record>, receipt_number: string, receipt_url: string, reference_id: string, refund_ids: list<string>, refunded_money: record<amount: int, currency: string>, risk_evaluation: record<created_at: string, risk_level: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, country: string, first_name: string, last_name: string, locality: string, organization: string, postal_code: string, sublocality: string, sublocality_2: string, sublocality_3: string>, source_type: string, statement_description_identifier: string, status: string, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, updated_at: string, version_token: string, wallet_details: record<status: string>>>
# operationId: CompletePayment
export def "complete-payment" [
  payment_id: string
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
    path: "/v2/payments/{payment_id}/complete"
    path_params: [{name: payment_id, var: payment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListPaymentRefunds
#
# GET /v2/refunds
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<amount_money: record, app_fee_money: record, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list, reason: string, status: string, updated_at: string>>
# operationId: ListPaymentRefunds
export def "list-payment-refunds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin-time: string # The timestamp for the beginning of the requested reporting period, in RFC 3339 format. Default: The current time minus one year.
  --end-time: string # The timestamp for the end of the requested reporting period, in RFC 3339 format. Default: The current time.
  --sort-order: string # The order in which results are listed: - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/basics/api101/pagination).
  --location-id: string # Limit results to the location supplied. By default, results are returned for all locations associated with the seller.
  --status: string # If provided, only refunds with the given status are returned. For a list of refund status values, see [PaymentRefund](https://developer.squareup.com/reference/square_2021-08-18/objects/PaymentRefund). Default: If omitted, refunds are returned regardless of their status.
  --source-type: string # If provided, only refunds with the given source type are returned. - `CARD` - List refunds only for payments where `CARD` was specified as the payment source. Default: If omitted, refunds are returned regardless of the source type.
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. If the supplied value is greater than 100, no more than 100 results are returned. Default: 100
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/refunds"
    query: [{name: begin_time, var: begin_time}, {name: end_time, var: end_time}, {name: sort_order, var: sort_order}, {name: cursor, var: cursor}, {name: location_id, var: location_id}, {name: status, var: status}, {name: source_type, var: source_type}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    begin_time: $begin_time, end_time: $end_time, sort_order: $sort_order, cursor: $cursor, location_id: $location_id, status: $status, source_type: $source_type, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RefundPayment
#
# POST /v2/refunds
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list<record>, reason: string, status: string, updated_at: string>>
# operationId: RefundPayment
export def "refund-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --app-fee-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  idempotency_key: string # A unique string that identifies this `RefundPayment` request. The key can be any valid string but must be unique for every `RefundPayment` request. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  payment_id: string # The unique ID of the payment being refunded.
  --reason: string # A description of the reason for the refund.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/refunds"
    body: {content_type: "application/json", kind: json, fields: [{name: amount_money, var: amount_money}, {name: app_fee_money, var: app_fee_money}, {name: idempotency_key, var: idempotency_key}, {name: payment_id, var: payment_id}, {name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    amount_money: $amount_money, app_fee_money: $app_fee_money, idempotency_key: $idempotency_key, payment_id: $payment_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetPaymentRefund
#
# GET /v2/refunds/{refund_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, created_at: string, id: string, location_id: string, order_id: string, payment_id: string, processing_fee: list<record>, reason: string, status: string, updated_at: string>>
# operationId: GetPaymentRefund
export def "get-payment-refund" [
  refund_id: string
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
    path: "/v2/refunds/{refund_id}"
    path_params: [{name: refund_id, var: refund_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    refund_id: $refund_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListSites
#
# GET /v2/sites
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, sites: table<created_at: string, domain: string, id: string, is_published: bool, site_title: string, updated_at: string>>
# operationId: ListSites
export def "list-sites" [
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
    path: "/v2/sites"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteSnippet
#
# DELETE /v2/sites/{site_id}/snippet
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>>
# operationId: DeleteSnippet
export def "delete-snippet" [
  site_id: string
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
    path: "/v2/sites/{site_id}/snippet"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveSnippet
#
# GET /v2/sites/{site_id}/snippet
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, snippet: record<content: string, created_at: string, id: string, site_id: string, updated_at: string>>
# operationId: RetrieveSnippet
export def "retrieve-snippet" [
  site_id: string
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
    path: "/v2/sites/{site_id}/snippet"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpsertSnippet
#
# POST /v2/sites/{site_id}/snippet
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, snippet: record<content: string, created_at: string, id: string, site_id: string, updated_at: string>>
# operationId: UpsertSnippet
export def "upsert-snippet" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  snippet: record # Represents the snippet that is added to a Square Online site. The snippet code is injected into the `head` element of all pages on the site, except for checkout pages. — shape: {content: string, created_at?: string, id?: string, site_id?: string, updated_at?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/sites/{site_id}/snippet"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateSubscription
#
# POST /v2/subscriptions
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>
# operationId: CreateSubscription
export def "create-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canceled-date: string # The date when the subscription should be canceled, in YYYY-MM-DD format (for example, 2025-02-29). This overrides the plan configuration if it comes before the date the subscription would otherwise end.
  --card-id: string # The ID of the [customer](https://developer.squareup.com/reference/square_2021-08-18/objects/Customer) [card](https://developer.squareup.com/reference/square_2021-08-18/objects/Card) to charge. If not specified, Square sends an invoice via email. For an example to create a customer and add a card on file, see [Subscriptions Walkthrough](https://developer.squareup.com/docs/subscriptions-api/walkthrough).
  customer_id: string # The ID of the [customer](https://developer.squareup.com/reference/square_2021-08-18/objects/Customer) profile.
  --idempotency-key: string # A unique string that identifies this `CreateSubscription` request. If you do not provide a unique string (or provide an empty string as the value), the endpoint treats each request as independent. For more information, see [Idempotency keys](https://developer.squareup.com/docs/working-with-apis/idempotency).
  location_id: string # The ID of the location the subscription is associated with.
  plan_id: string # The ID of the subscription plan created using the Catalog API. For more information, see [Set Up and Manage a Subscription Plan](https://developer.squareup.com/docs/subscriptions-api/setup-plan) and [Subscriptions Walkthrough](https://developer.squareup.com/docs/subscriptions-api/walkthrough).
  --price-override-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: string}
  --start-date: string # The start date of the subscription, in YYYY-MM-DD format. For example, 2013-01-15. If the start date is left empty, the subscription begins immediately.
  --tax-percentage: string # The tax to add when billing the subscription. The percentage is expressed in decimal form, using a `'.'` as the decimal separator and without a `'%'` sign. For example, a value of 7.5 corresponds to 7.5%.
  --timezone: string # The timezone that is used in date calculations for the subscription. If unset, defaults to the location timezone. If a timezone is not configured for the location, defaults to "America/New_York". Format: the IANA Timezone Database identifier for the location timezone. For a list of time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/subscriptions"
    body: {content_type: "application/json", kind: json, fields: [{name: canceled_date, var: canceled_date}, {name: card_id, var: card_id}, {name: customer_id, var: customer_id}, {name: idempotency_key, var: idempotency_key}, {name: location_id, var: location_id}, {name: plan_id, var: plan_id}, {name: price_override_money, var: price_override_money}, {name: start_date, var: start_date}, {name: tax_percentage, var: tax_percentage}, {name: timezone, var: timezone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    canceled_date: $canceled_date, card_id: $card_id, customer_id: $customer_id, idempotency_key: $idempotency_key, location_id: $location_id, plan_id: $plan_id, price_override_money: $price_override_money, start_date: $start_date, tax_percentage: $tax_percentage, timezone: $timezone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchSubscriptions
#
# POST /v2/subscriptions/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, subscriptions: table<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list, location_id: string, plan_id: string, price_override_money: record, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>
# operationId: SearchSubscriptions
export def "search-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The upper limit on the number of subscriptions to return in the response. Default: `200`
  --query: record # Represents a query (including filtering criteria) used to search for subscriptions. — shape: {filter?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/subscriptions/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveSubscription
#
# GET /v2/subscriptions/{subscription_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>
# operationId: RetrieveSubscription
export def "retrieve-subscription" [
  subscription_id: string
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
    path: "/v2/subscriptions/{subscription_id}"
    path_params: [{name: subscription_id, var: subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateSubscription
#
# PUT /v2/subscriptions/{subscription_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>
# operationId: UpdateSubscription
export def "update-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription: record # Represents a customer subscription to a subscription plan. For an overview of the `Subscription` type, see [Subscription object](https://developer.squareup.com/docs/subscriptions-api/overview#subscription-object-overview). — shape: {canceled_date?: string, card_id?: string, charged_through_date?: string, created_at?: string, customer_id?: string, id?: string, invoice_ids?: list<string>, location_id?: string, plan_id?: string, price_override_money?: record, start_date?: string, status?: string, tax_percentage?: string, timezone?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/subscriptions/{subscription_id}"
    path_params: [{name: subscription_id, var: subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: subscription, var: subscription}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, subscription: $subscription
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CancelSubscription
#
# POST /v2/subscriptions/{subscription_id}/cancel
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>
# operationId: CancelSubscription
export def "cancel-subscription" [
  subscription_id: string
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
    path: "/v2/subscriptions/{subscription_id}/cancel"
    path_params: [{name: subscription_id, var: subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListSubscriptionEvents
#
# GET /v2/subscriptions/{subscription_id}/events
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, subscription_events: table<effective_date: string, id: string, info: any, plan_id: string, subscription_event_type: string>>
# operationId: ListSubscriptionEvents
export def "list-subscription-events" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The upper limit on the number of subscription events to return in the response. Default: `200`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/subscriptions/{subscription_id}/events"
    path_params: [{name: subscription_id, var: subscription_id}]
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ResumeSubscription
#
# POST /v2/subscriptions/{subscription_id}/resume
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<canceled_date: string, card_id: string, charged_through_date: string, created_at: string, customer_id: string, id: string, invoice_ids: list<string>, location_id: string, plan_id: string, price_override_money: record<amount: int, currency: string>, start_date: string, status: string, tax_percentage: string, timezone: string, version: int>>
# operationId: ResumeSubscription
export def "resume-subscription" [
  subscription_id: string
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
    path: "/v2/subscriptions/{subscription_id}/resume"
    path_params: [{name: subscription_id, var: subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateTeamMember
#
# POST /v2/team-members
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>>
# operationId: CreateTeamMember
export def "create-team-member" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # A unique string that identifies this `CreateTeamMember` request. Keys can be any valid string, but must be unique for every request. For more information, see [Idempotency](https://developer.squareup.com/docs/basics/api101/idempotency). The minimum length is 1 and the maximum length is 45.
  --team-member: record # A record representing an individual team member for a business. — shape: {assigned_locations?: record, created_at?: string, email_address?: string, family_name?: string, given_name?: string, id?: string, is_owner?: bool, phone_number?: string, reference_id?: string, status?: string, updated_at?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/team-members"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: team_member, var: team_member}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, team_member: $team_member
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BulkCreateTeamMembers
#
# POST /v2/team-members/bulk-create
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, team_members: record>
# operationId: BulkCreateTeamMembers
export def "bulk-create-team-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  team_members: record # The data used to create the `TeamMember` objects. Each key is the `idempotency_key` that maps to the `CreateTeamMemberRequest`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/team-members/bulk-create"
    body: {content_type: "application/json", kind: json, fields: [{name: team_members, var: team_members}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_members: $team_members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BulkUpdateTeamMembers
#
# POST /v2/team-members/bulk-update
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, team_members: record>
# operationId: BulkUpdateTeamMembers
export def "bulk-update-team-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  team_members: record # The data used to update the `TeamMember` objects. Each key is the `team_member_id` that maps to the `UpdateTeamMemberRequest`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/team-members/bulk-update"
    body: {content_type: "application/json", kind: json, fields: [{name: team_members, var: team_members}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_members: $team_members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchTeamMembers
#
# POST /v2/team-members/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, team_members: table<assigned_locations: record, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>>
# operationId: SearchTeamMembers
export def "search-team-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # The opaque cursor for fetching the next page. For more information, see [pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of `TeamMember` objects in a page (100 by default).
  --query: record # Represents the parameters in a search for `TeamMember` objects. — shape: {filter?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/team-members/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveTeamMember
#
# GET /v2/team-members/{team_member_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>>
# operationId: RetrieveTeamMember
export def "retrieve-team-member" [
  team_member_id: string
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
    path: "/v2/team-members/{team_member_id}"
    path_params: [{name: team_member_id, var: team_member_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_member_id: $team_member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateTeamMember
#
# PUT /v2/team-members/{team_member_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, team_member: record<assigned_locations: record<assignment_type: string, location_ids: list>, created_at: string, email_address: string, family_name: string, given_name: string, id: string, is_owner: bool, phone_number: string, reference_id: string, status: string, updated_at: string>>
# operationId: UpdateTeamMember
export def "update-team-member" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-member: record # A record representing an individual team member for a business. — shape: {assigned_locations?: record, created_at?: string, email_address?: string, family_name?: string, given_name?: string, id?: string, is_owner?: bool, phone_number?: string, reference_id?: string, status?: string, updated_at?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/team-members/{team_member_id}"
    path_params: [{name: team_member_id, var: team_member_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: team_member, var: team_member}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_member_id: $team_member_id, team_member: $team_member
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveWageSetting
#
# GET /v2/team-members/{team_member_id}/wage-setting
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, wage_setting: record<created_at: string, is_overtime_exempt: bool, job_assignments: list<record>, team_member_id: string, updated_at: string, version: int>>
# operationId: RetrieveWageSetting
export def "retrieve-wage-setting" [
  team_member_id: string
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
    path: "/v2/team-members/{team_member_id}/wage-setting"
    path_params: [{name: team_member_id, var: team_member_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_member_id: $team_member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateWageSetting
#
# PUT /v2/team-members/{team_member_id}/wage-setting
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, wage_setting: record<created_at: string, is_overtime_exempt: bool, job_assignments: list<record>, team_member_id: string, updated_at: string, version: int>>
# operationId: UpdateWageSetting
export def "update-wage-setting" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  wage_setting: record # An object representing a team member's wage information. — shape: {created_at?: string, is_overtime_exempt?: bool, job_assignments?: list, team_member_id?: string, updated_at?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/team-members/{team_member_id}/wage-setting"
    path_params: [{name: team_member_id, var: team_member_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: wage_setting, var: wage_setting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_member_id: $team_member_id, wage_setting: $wage_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateTerminalCheckout
#
# POST /v2/terminals/checkouts
# Returns: record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CreateTerminalCheckout
export def "create-terminal-checkout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  checkout: record # shape: {amount_money: record, app_id?: string, cancel_reason?: string, created_at?: string, deadline_duration?: string, device_options: record, id?: string, location_id?: string, note?: string, payment_ids?: list<string>, payment_type?: string, reference_id?: string, status?: string, updated_at?: string}
  idempotency_key: string # A unique string that identifies this `CreateCheckout` request. Keys can be any valid string but must be unique for every `CreateCheckout` request. See [Idempotency keys](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/terminals/checkouts"
    body: {content_type: "application/json", kind: json, fields: [{name: checkout, var: checkout}, {name: idempotency_key, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    checkout: $checkout, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchTerminalCheckouts
#
# POST /v2/terminals/checkouts/search
# Returns: record<checkouts: table<amount_money: record, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record, id: string, location_id: string, note: string, payment_ids: list, payment_type: string, reference_id: string, status: string, updated_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: SearchTerminalCheckouts
export def "search-terminal-checkouts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. See [Pagination](https://developer.squareup.com/docs/basics/api101/pagination) for more information.
  --limit: int # Limits the number of results returned for a single request.
  --query: record # shape: {filter?: record, sort?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/terminals/checkouts/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetTerminalCheckout
#
# GET /v2/terminals/checkouts/{checkout_id}
# Returns: record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: GetTerminalCheckout
export def "get-terminal-checkout" [
  checkout_id: string
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
    path: "/v2/terminals/checkouts/{checkout_id}"
    path_params: [{name: checkout_id, var: checkout_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    checkout_id: $checkout_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CancelTerminalCheckout
#
# POST /v2/terminals/checkouts/{checkout_id}/cancel
# Returns: record<checkout: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_options: record<device_id: string, skip_receipt_screen: bool, tip_settings: record>, id: string, location_id: string, note: string, payment_ids: list<string>, payment_type: string, reference_id: string, status: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>>
# operationId: CancelTerminalCheckout
export def "cancel-terminal-checkout" [
  checkout_id: string
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
    path: "/v2/terminals/checkouts/{checkout_id}/cancel"
    path_params: [{name: checkout_id, var: checkout_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    checkout_id: $checkout_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateTerminalRefund
#
# POST /v2/terminals/refunds
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>>
# operationId: CreateTerminalRefund
export def "create-terminal-refund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  idempotency_key: string # A unique string that identifies this `CreateRefund` request. Keys can be any valid string but must be unique for every `CreateRefund` request. See [Idempotency keys](https://developer.squareup.com/docs/basics/api101/idempotency) for more information.
  --refund: record # shape: {amount_money: record, app_id?: string, cancel_reason?: string, created_at?: string, deadline_duration?: string, device_id?: string, id?: string, location_id?: string, order_id?: string, payment_id: string, reason?: string, refund_id?: string, status?: string, updated_at?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/terminals/refunds"
    body: {content_type: "application/json", kind: json, fields: [{name: idempotency_key, var: idempotency_key}, {name: refund, var: refund}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, refund: $refund
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SearchTerminalRefunds
#
# POST /v2/terminals/refunds/search
# Returns: record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, refunds: table<amount_money: record, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>>
# operationId: SearchTerminalRefunds
export def "search-terminal-refunds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query.
  --limit: int # Limits the number of results returned for a single request.
  --query: record # shape: {filter?: record, sort?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/terminals/refunds/search"
    body: {content_type: "application/json", kind: json, fields: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetTerminalRefund
#
# GET /v2/terminals/refunds/{terminal_refund_id}
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>>
# operationId: GetTerminalRefund
export def "get-terminal-refund" [
  terminal_refund_id: string
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
    path: "/v2/terminals/refunds/{terminal_refund_id}"
    path_params: [{name: terminal_refund_id, var: terminal_refund_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    terminal_refund_id: $terminal_refund_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CancelTerminalRefund
#
# POST /v2/terminals/refunds/{terminal_refund_id}/cancel
# Returns: record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<amount_money: record<amount: int, currency: string>, app_id: string, cancel_reason: string, created_at: string, deadline_duration: string, device_id: string, id: string, location_id: string, order_id: string, payment_id: string, reason: string, refund_id: string, status: string, updated_at: string>>
# operationId: CancelTerminalRefund
export def "cancel-terminal-refund" [
  terminal_refund_id: string
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
    path: "/v2/terminals/refunds/{terminal_refund_id}/cancel"
    path_params: [{name: terminal_refund_id, var: terminal_refund_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    terminal_refund_id: $terminal_refund_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
