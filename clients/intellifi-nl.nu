# Auto-generated client for Brain Web API v2.23.2+0.gfbc3926.dirty
# Source: https://api.apis.guru/v2/specs/intellifi.nl/2.23.2+0.gfbc3926.dirty/openapi.json
# Auth: --token flag or $env.BRAIN_WEB_API_TOKEN

const CLIENT = {
  base_url: "https://brain.intellifi.cloud/api"
  token_env_var: "BRAIN_WEB_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: "cookie-brain.sid", in: cookie, header_name: "brain.sid", prefix: ""}
    {name: x-api-key, in: header, header_name: X-Api-Key, prefix: ""}
    {name: query-key, in: query, header_name: key, prefix: ""}
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

def base-url-completer [] { ["https://brain.intellifi.cloud/api" "http://brain.intellifi.cloud/api" "https://brain.intellifi.nl/api"] }
def auth-scheme-completer [] { ["cookie-brain.sid" "x-api-key" "query-key"] }

# Completers for enum parameters
def topic-resource-type-completer [] { ["blobs" "items" "keys" "kvpairs" "locations" "presences" "services" "spots" "subscriptions" "users"] }
def topic-action-completer [] { ["connection-rssi-changed" "created" "deleted" "disappeared" "updated"] }
def protocol-completer [] { ["altbeacon" "eddystone" "epcgen2" "generic" "ibeacon" "nanoble" "nfc" "uniwear"] }
def technology-completer [] { ["bluetooth" "optical" "rfid"] }
def type-completer [] { ["barcode" "bluetitan" "gbtag" "relay" "smarttag" "tag"] }
def type-completer-1 [] { ["allow" "debounce" "disallow" "disappeared"] }
def proximity-completer [] { ["far" "immediate" "near"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-authinfo: "record<api_key_id: string, auth_method: string, authenticated: bool, permissions: record<mutate: bool>, url: string, user_id: string>"
    get-blobs: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<blob_key: string, content_type: string, download_url: string, filename: string, hash: string, id: string, time_created: string, time_last_accessed: string, time_updated: string, upload_url: string, url: string>>"
    add-blob: "record<resource: record<id: string, url: string>, status: int>"
    delete-blob: "record<resource: record<id: string, url: string>, status: int>"
    get-blob-metadata-by-id: "record<blob_key: string, content_type: string, download_url: string, filename: string, hash: string, id: string, time_created: string, time_last_accessed: string, time_updated: string, upload_url: string, url: string>"
    get-blob-by-id: "binary"
    get-events: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record, url: string>>"
    get-event-by-id: "record<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record<action: string, arguments: any, resource_id: string, resource_type: string, resource_url: string>, url: string>"
    get-items: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record, id: string, is_present: bool, move_count: int, protocol: string, sets: list, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string>>"
    add-item: "record<resource: record<id: string, url: string>, status: int>"
    delete-item: "record<resource: record<id: string, url: string>, status: int>"
    get-item-by-id: "record<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_present: bool, move_count: int, protocol: string, sets: list<string>, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string>"
    update-item: "record<resource: record<id: string, url: string>, status: int>"
    get-keys: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, is_read_only: bool, label: string, secret: string, time_created: string, time_updated: string, url: string>>"
    add-key: "record<resource: record<id: string, url: string>, status: int>"
    delete-key: "record<resource: record<id: string, url: string>, status: int>"
    get-key-by-id: "record<id: string, is_read_only: bool, label: string, secret: string, time_created: string, time_updated: string, url: string>"
    update-key: "record<resource: record<id: string, url: string>, status: int>"
    get-kv-pairs: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<kv_value: any, id: string, kv_key: string, time_created: string, time_updated: string, url: string>>"
    add-kv-pairs: "record<resource: record<id: string, url: string>, status: int>"
    delete-kv-pair: "record<resource: record<id: string, url: string>, status: int>"
    get-kv-pairs-by-id: "record<kv_value: any, id: string, kv_key: string, time_created: string, time_updated: string, url: string>"
    update-kv-pair: "record<resource: record<id: string, url: string>, status: int>"
    get-location-rules: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<conditions: any, enabled: bool, id: string, label: string, parameters: record, time_created: string, time_updated: string, type: string, url: string>>"
    add-location-rule: "record<resource: record<id: string, url: string>, status: int>"
    delete-location-rule: "record<resource: record<id: string, url: string>, status: int>"
    get-location-rule-by-id: "record<conditions: any, enabled: bool, id: string, label: string, parameters: record, time_created: string, time_updated: string, type: string, url: string>"
    update-location-rule: "record<resource: record<id: string, url: string>, status: int>"
    get-locations: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string>>"
    add-location: "record<resource: record<id: string, url: string>, status: int>"
    delete-location: "record<resource: record<id: string, url: string>, status: int>"
    get-location-by-id: "record<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string>"
    update-location: "record<resource: record<id: string, url: string>, status: int>"
    get-presences: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, item: record, item_id: string, item_url: string, location: record, location_id: string, location_url: string, proximity: string, technology: string, time_created: string, time_updated: string, url: string>>"
    get-presence-by-id: "record<id: string, item: record<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_present: bool, move_count: int, protocol: string, sets: list<string>, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string>, item_id: string, item_url: string, location: record<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string>, location_id: string, location_url: string, proximity: string, technology: string, time_created: string, time_updated: string, url: string>"
    get-services: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<boot_count: int, config: record, config_request: record, id: string, name: string, restart_request: bool, time_created: string, time_updated: string, url: string, version: string>>"
    get-service-by-id: "record<boot_count: int, config: record, config_request: record, id: string, name: string, restart_request: bool, time_created: string, time_updated: string, url: string, version: string>"
    update-service: "record<resource: record<id: string, url: string>, status: int>"
    get-item-lists: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, list: string, metadata: record, sha1: string, time_created: string, time_updated: string, total: int>>"
    add-item-list: "record<resource: record<id: string, url: string>, status: int>"
    delete-item-set: "record<resource: record<id: string, url: string>, status: int>"
    get-item-list-by-id: "record<custom: any, id: string, label: string, list: string, metadata: record, sha1: string, time_created: string, time_updated: string, total: int>"
    update-item-list: "record<resource: record<id: string, url: string>, status: int>"
    get-item-list-ids-by-id: "list<string>"
    add-item-ids-list: "record<status: int, total: int>"
    delete-item-id-from-item-list: "record<status: int, total: int>"
    get-spot-lists: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, list: string, metadata: record, time_created: string, time_updated: string, total: int>>"
    add-spot-list: "record<resource: record<id: string, url: string>, status: int>"
    delete-spot-list: "record<resource: record<id: string, url: string>, status: int>"
    get-spot-list-by-id: "record<custom: any, id: string, label: string, list: string, metadata: record, time_created: string, time_updated: string, total: int>"
    update-spot-list: "record<resource: record<id: string, url: string>, status: int>"
    get-spot-list-ids-by-id: "list<string>"
    add-item-ids-spot-list: "record<status: int, total: int>"
    delete-item-id-from-spot-list: "record<status: int, total: int>"
    get-spots: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<antenna_report_locations: list, config: record, config_request: record, geo_coords: record, id: string, is_online: bool, request_counter: int, senses: record, senses_request: record, serial_number: int, status: any, time_created: string, time_updated: string, url: string>>"
    get-spot-by-id: "record<antenna_report_locations: table<antenna_number: int, report_location: record, report_location_id: string, report_location_url: string>, config: record, config_request: record, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_online: bool, request_counter: int, senses: record, senses_request: record, serial_number: int, status: any, time_created: string, time_updated: string, url: string>"
    update-spot: "record<resource: record<id: string, url: string>, status: int>"
    get-spot-sets-by-id: "record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string>"
    add-spot-set: "record<resource: record<id: string, url: string>, status: int>"
    get-spot-set-by-id: "record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string>"
    update-spot-set: "record<resource: record<id: string, url: string>, status: int>"
    get-spotsets: "record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string>"
    post-spotsets: "record<resource: record<id: string, url: string>, status: int>"
    get-spotsets-id: "record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string>"
    put-spotsets-id: "record<resource: record<id: string, url: string>, status: int>"
    get-subscriptions: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, database_hold_time_h: int, description: string, events_url: string, id: string, populate_events: bool, target_delivery_last_failure: record, target_delivery_status: record, target_retry: bool, target_url: string, time_created: string, time_updated: string, topic_filter: string, url: string, verify_target_certificate: bool>>"
    add-subscription: "record<resource: record<id: string, url: string>, status: int>"
    delete-subscription: "record<resource: record<id: string, url: string>, status: int>"
    get-subscription-by-id: "record<custom: any, database_hold_time_h: int, description: string, events_url: string, id: string, populate_events: bool, target_delivery_last_failure: record, target_delivery_status: record, target_retry: bool, target_url: string, time_created: string, time_updated: string, topic_filter: string, url: string, verify_target_certificate: bool>"
    update-subscription: "record<resource: record<id: string, url: string>, status: int>"
    get-events-for-subscription-by-id: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record, url: string>>"
    get-users: "record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<email: string, first_name: string, id: string, is_admin: bool, is_locked: bool, last_name: string, password: string, time_created: string, time_updated: string, url: string>>"
    add-user: "record<resource: record<id: string, url: string>, status: int>"
    delete-user: "record<resource: record<id: string, url: string>, status: int>"
    get-user-by-id: "record<email: string, first_name: string, id: string, is_admin: bool, is_locked: bool, last_name: string, password: string, time_created: string, time_updated: string, url: string>"
    update-user: "record<resource: record<id: string, url: string>, status: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-authinfo" "get-blobs" "add-blob" "delete-blob" "get-blob-metadata-by-id" "get-blob-by-id" "upload-blob-by-id" "get-events" "get-event-by-id" "get-items" "add-item" "delete-item" "get-item-by-id" "update-item" "get-keys" "add-key" "delete-key" "get-key-by-id" "update-key" "get-kv-pairs" "add-kv-pairs" "delete-kv-pair" "get-kv-pairs-by-id" "update-kv-pair" "get-location-rules" "add-location-rule" "delete-location-rule" "get-location-rule-by-id" "update-location-rule" "get-locations" "add-location" "delete-location" "get-location-by-id" "update-location" "get-presences" "get-presence-by-id" "get-services" "get-service-by-id" "update-service" "get-item-lists" "add-item-list" "delete-item-set" "get-item-list-by-id" "update-item-list" "get-item-list-ids-by-id" "add-item-ids-list" "delete-item-id-from-item-list" "get-spot-lists" "add-spot-list" "delete-spot-list" "get-spot-list-by-id" "update-spot-list" "get-spot-list-ids-by-id" "add-item-ids-spot-list" "delete-item-id-from-spot-list" "get-spots" "get-spot-by-id" "update-spot" "get-spot-sets-by-id" "add-spot-set" "get-spot-set-by-id" "update-spot-set" "get-spotsets" "post-spotsets" "get-spotsets-id" "put-spotsets-id" "get-subscriptions" "add-subscription" "delete-subscription" "get-subscription-by-id" "update-subscription" "get-events-for-subscription-by-id" "get-users" "add-user" "delete-user" "get-user-by-id" "update-user" "commands"] | sort) } | get name | first)
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

# Authentication information
#
# GET /authinfo
# Returns: record<api_key_id: string, auth_method: string, authenticated: bool, permissions: record<mutate: bool>, url: string, user_id: string>
# operationId: getAuthinfo
export def "get-authinfo" [
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
    path: "/authinfo"
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all binary large objects (blob)
#
# GET /blobs
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<blob_key: string, content_type: string, download_url: string, filename: string, hash: string, id: string, time_created: string, time_last_accessed: string, time_updated: string, upload_url: string, url: string>>
# operationId: getBlobs
export def "get-blobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --hash: string # Filter based on the hash of the blob.
  --blob-key: string # Filter based on the unique blob_key
  --content-type: string # Filter based on the content type of the blob.
  --filename: string # Filter based on the filename of the blob.
  --time-last-accessed: string # Filter based on the last time the blob was accessed
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/blobs"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: hash, var: hash}, {name: blob_key, var: blob_key}, {name: content_type, var: content_type}, {name: filename, var: filename}, {name: time_last_accessed, var: time_last_accessed}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, hash: $hash, blob_key: $blob_key, content_type: $content_type, filename: $filename, time_last_accessed: $time_last_accessed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create binary large object (blob) metadata
#
# POST /blobs
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addBlob
export def "add-blob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --blob-key: string # Unique key to the blob (e.g. foobar)
  --content-type: string # Media type of the resource. Automatically detected when not given in a POST. (e.g. image/png)
  --filename: string # Filename of the blob (e.g. Foo bar)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/blobs"
    body: {content_type: "application/json", kind: json, fields: [{name: blob_key, var: blob_key}, {name: content_type, var: content_type}, {name: filename, var: filename}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    blob_key: $blob_key, content_type: $content_type, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete binary large object (blob)
#
# DELETE /blobs/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteBlob
export def "delete-blob" [
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
    path: "/blobs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get binary large object (blob)
#
# GET /blobs/{id}
# Returns: record<blob_key: string, content_type: string, download_url: string, filename: string, hash: string, id: string, time_created: string, time_last_accessed: string, time_updated: string, upload_url: string, url: string>
# operationId: getBlobMetadataById
export def "get-blob-metadata-by-id" [
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
    path: "/blobs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a binary large object (blob)
#
# GET /blobs/{id}/download/{filename}
# Returns: binary
# operationId: getBlobById
export def "get-blob-by-id" [
  id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/blobs/{id}/download/{filename}"
    path_params: [{name: id, var: id}, {name: filename, var: filename}]
    accept: ["image/*"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create binary large object (blob)
#
# POST /blobs/{id}/upload
# operationId: uploadBlobById
export def "upload-blob-by-id" [
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
  --file: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/blobs/{id}/upload"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all events
#
# GET /events
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record, url: string>>
# operationId: getEvents
export def "get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --topic-resource-type: string@topic-resource-type-completer # Filter on the topic resource type (e.g. items)
  --topic-action: string@topic-action-completer # Filter on the topic action (e.g. created)
  --topic-resource: string # Filter on the topic resource id (e.g. 5b7d6cbd7503c445552a1664)
  --time-event: string # Filter on the time the event was generated on the device. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-expire: string # Filter on the time the event will expire. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: "topic.resource_type", var: topic_resource_type}, {name: "topic.action", var: topic_action}, {name: "topic.resource", var: topic_resource}, {name: time_event, var: time_event}, {name: time_expire, var: time_expire}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, topic_resource_type: $topic_resource_type, topic_action: $topic_action, topic_resource: $topic_resource, time_event: $time_event, time_expire: $time_expire
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get event
#
# GET /events/{id}
# Returns: record<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record<action: string, arguments: any, resource_id: string, resource_type: string, resource_url: string>, url: string>
# operationId: getEventById
export def "get-event-by-id" [
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
    path: "/events/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all items
#
# GET /items
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record, id: string, is_present: bool, move_count: int, protocol: string, sets: list, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string>>
# operationId: getItems
export def "get-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --after-code: string # Limits directly on `code_hex`. Marks the start of a range, optionally use `before_code` to set the end. Result output excludes the given `code_hex` value. (e.g. e20000000000000000000000)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before-code: string # Limits directly on `code_hex`. Marks the end of a range, optionally use `after_code` to set the start. Result output excludes the given `code_hex` value. (e.g. e20000000000000000001fff)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from-code: string # Limits on `code_hex`. Marks the start of a range, optionally use `until_code` to set the end. Result output includes the given `code_hex` value. (e.g. e20000000000000000000000)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --until-code: string # Limits on `code_hex`. Marks the end of a range, optionally use `from_code` to set the start. Result output includes the given `code_hex` value. (e.g. e20000000000000000001ffff)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --code-hex: string # Filter based on the hexadecimal string representation of the item. Supports wildcards: `*`. (e.g. deadbeef)
  --is-present: oneof<nothing, bool> # Only show items which are present of not. (e.g. true)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --location: string # Filter based on the location (e.g. 5b7d6cbd7503c445552a1664)
  --metadata: string # Filter based on metadata. Does a partial match on any value in the metadata object. It is also possible to do an exact/wildcard match on specific properties, e.g. `metadata.foo=bar`
  --move-count: int # Filter based on move count (e.g. 4523)
  --protocol: string@protocol-completer # Filter based on the detected protocol of an item. (e.g. epcgen2)
  --sets: string # Filter based on the set the resource is in. (e.g. 5b7d6cbd7503c445552a1664)
  --technology: string@technology-completer # Filter based on the detected technology of an item. (e.g. rfid)
  --text: string # Filter based on a full text search. Searched properties depend on the resource type. Matches on any of the given words. Supports quote (exact words) and minus (exclude) operators. (e.g. penguin)
  --time-last-present: string # Filter based on the time last present (e.g. 2018-09-03T10:23:46.596Z)
  --time-moved: string # Filter based on time last moved (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --type: string@type-completer # Filter based on the type of an item. (e.g. tag)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/items"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: after_code, var: after_code}, {name: before, var: before}, {name: before_id, var: before_id}, {name: before_code, var: before_code}, {name: from, var: from}, {name: from_id, var: from_id}, {name: from_code, var: from_code}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: until_code, var: until_code}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: code_hex, var: code_hex}, {name: is_present, var: is_present}, {name: label, var: label}, {name: location, var: location}, {name: metadata, var: metadata}, {name: move_count, var: move_count}, {name: protocol, var: protocol}, {name: sets, var: sets}, {name: technology, var: technology}, {name: text, var: text}, {name: time_last_present, var: time_last_present}, {name: time_moved, var: time_moved}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, after_code: $after_code, before: $before, before_id: $before_id, before_code: $before_code, from: $from, from_id: $from_id, from_code: $from_code, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, until_code: $until_code, id: $id, time_created: $time_created, time_updated: $time_updated, code_hex: $code_hex, is_present: $is_present, label: $label, location: $location, metadata: $metadata, move_count: $move_count, protocol: $protocol, sets: $sets, technology: $technology, text: $text, time_last_present: $time_last_present, time_moved: $time_moved, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create item
#
# POST /items
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addItem
export def "add-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-request: record # Object containing the new configuration. This will be applied automatically when the values are valid. (e.g. {foo: bar})
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --location-request: string # Instruction for the location engine to forcibly localize the item at the specified location id as soon as possible. Cleared automatically. (e.g. 5b7d6cbd7503c445552a1664)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
  --code-hex: string # String representation of the unique code that this item transmits. By default this is a hexadecimal representation. This number could be so long (> 40 bytes!) that a decimal representation would be useless to generate. (e.g. deadbeef)
  --protocol: string@protocol-completer # Type of protocol that was used to decode this item. (e.g. epcgen2)
  --technology: string@technology-completer # Type of technology that was used to detect this item. (e.g. rfid)
  --type: string@type-completer # Type of item. (e.g. tag)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/items"
    body: {content_type: "application/json", kind: json, fields: [{name: config_request, var: config_request}, {name: custom, var: custom}, {name: label, var: label}, {name: location_request, var: location_request}, {name: metadata, var: metadata}, {name: code_hex, var: code_hex}, {name: protocol, var: protocol}, {name: technology, var: technology}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    config_request: $config_request, custom: $custom, label: $label, location_request: $location_request, metadata: $metadata, code_hex: $code_hex, protocol: $protocol, technology: $technology, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete item
#
# DELETE /items/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteItem
export def "delete-item" [
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
    path: "/items/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item
#
# GET /items/{id}
# Returns: record<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_present: bool, move_count: int, protocol: string, sets: list<string>, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string>
# operationId: getItemById
export def "get-item-by-id" [
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
    path: "/items/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing item
#
# PUT /items/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateItem
export def "update-item" [
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
  --config-request: record # Object containing the new configuration. This will be applied automatically when the values are valid. (e.g. {foo: bar})
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --location-request: string # Instruction for the location engine to forcibly localize the item at the specified location id as soon as possible. Cleared automatically. (e.g. 5b7d6cbd7503c445552a1664)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/items/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_request, var: config_request}, {name: custom, var: custom}, {name: label, var: label}, {name: location_request, var: location_request}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, config_request: $config_request, custom: $custom, label: $label, location_request: $location_request, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all keys
#
# GET /keys
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, is_read_only: bool, label: string, secret: string, time_created: string, time_updated: string, url: string>>
# operationId: getKeys
export def "get-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --secret: string # Filter on the secret token.
  --label: string # Filter on the label.
  --is-read-only: oneof<nothing, bool> # Filter on read only status.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keys"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: secret, var: secret}, {name: label, var: label}, {name: is_read_only, var: is_read_only}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, secret: $secret, label: $label, is_read_only: $is_read_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create key
#
# POST /keys
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addKey
export def "add-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-read-only: oneof<nothing, bool> # Whether or not this key can only read and not write.
  --label: string # Custom label for this API key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys"
    body: {content_type: "application/json", kind: json, fields: [{name: is_read_only, var: is_read_only}, {name: label, var: label}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    is_read_only: $is_read_only, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete key
#
# DELETE /keys/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteKey
export def "delete-key" [
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
    path: "/keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get key
#
# GET /keys/{id}
# Returns: record<id: string, is_read_only: bool, label: string, secret: string, time_created: string, time_updated: string, url: string>
# operationId: getKeyById
export def "get-key-by-id" [
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
    path: "/keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing key
#
# PUT /keys/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateKey
export def "update-key" [
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
  --is-read-only: oneof<nothing, bool> # Whether or not this key can only read and not write.
  --label: string # Custom label for this API key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/keys/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_read_only, var: is_read_only}, {name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, is_read_only: $is_read_only, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all key-value pairs
#
# GET /kvpairs
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<kv_value: any, id: string, kv_key: string, time_created: string, time_updated: string, url: string>>
# operationId: getKvPairs
export def "get-kv-pairs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --kv-key: string # Filter on the key-value pair key value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/kvpairs"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: kv_key, var: kv_key}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, kv_key: $kv_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create key-value pair
#
# POST /kvpairs
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addKvPairs
export def "add-kv-pairs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kv-value: any # The value of the key value pair. (nullable, e.g. all the bars)
  --kv-key: string # Unique identifier for the value. (e.g. foo)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/kvpairs"
    body: {content_type: "application/json", kind: json, fields: [{name: kv_value, var: kv_value}, {name: kv_key, var: kv_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    kv_value: $kv_value, kv_key: $kv_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete key-value pair
#
# DELETE /kvpairs/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteKvPair
export def "delete-kv-pair" [
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
    path: "/kvpairs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get key-value pair
#
# GET /kvpairs/{id}
# Returns: record<kv_value: any, id: string, kv_key: string, time_created: string, time_updated: string, url: string>
# operationId: getKvPairsById
export def "get-kv-pairs-by-id" [
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
    path: "/kvpairs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing Key-value pair
#
# PUT /kvpairs/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateKvPair
export def "update-kv-pair" [
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
  --kv-value: any # The value of the key value pair. (nullable, e.g. all the bars)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/kvpairs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: kv_value, var: kv_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, kv_value: $kv_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all location rules
#
# GET /locationrules
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<conditions: any, enabled: bool, id: string, label: string, parameters: record, time_created: string, time_updated: string, type: string, url: string>>
# operationId: getLocationRules
export def "get-location-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --type: string@type-completer-1 # Filter based on the type of location rule.
  --enabled: oneof<nothing, bool> # Filter based on the `enabled` property. (e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locationrules"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: label, var: label}, {name: type, var: type}, {name: enabled, var: enabled}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, label: $label, type: $type, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create location rule
#
# POST /locationrules
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addLocationRule
export def "add-location-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conditions: record # Scope of this rule, e.g. moves at or away from a specific location or towards a specific location. The `from_location` is mandatory. The `to_location` is either mandatory, optional or not allowed depending on rule type. — shape: {from_location?: string, to_location?: string}
  --enabled: oneof<nothing, bool> # Whether this rule should be in effect (`true`) or on hold (`false`). (e.g. true)
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --parameters: record # Parameters for this rule; depends on the rule type. Refer to the rule type specification for details.
  --type: string@type-completer-1 # The type of location rule to be applied. Allow: items at `conditions.from_location` can only move to `conditions.to_location` and locations allowed in other `allow` rules (destination whitelist). Disallow: items at `conditions.from_location` cannot be moved to `conditions.to_location` and locations disallowed in other `disallow` rules (destination blacklist). Disappeared: items disappearing at `conditions.from_location` will be moved to `parameters.location` after `parameters.time_s` seconds. Debounce: items moves from `conditions.from_location` (and optionally to `conditions.to_location`) will be debounced with a period of `parameters.time_s` seconds, for a maximum of `parameters.max_periods` periods.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/locationrules"
    body: {content_type: "application/json", kind: json, fields: [{name: conditions, var: conditions}, {name: enabled, var: enabled}, {name: label, var: label}, {name: parameters, var: parameters}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    conditions: $conditions, enabled: $enabled, label: $label, parameters: $parameters, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete location rule
#
# DELETE /locationrules/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteLocationRule
export def "delete-location-rule" [
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
    path: "/locationrules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get location rule
#
# GET /locationrules/{id}
# Returns: record<conditions: any, enabled: bool, id: string, label: string, parameters: record, time_created: string, time_updated: string, type: string, url: string>
# operationId: getLocationRuleById
export def "get-location-rule-by-id" [
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
    path: "/locationrules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing location rule
#
# PUT /locationrules/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateLocationRule
export def "update-location-rule" [
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
  --conditions: record # Scope of this rule, e.g. moves at or away from a specific location or towards a specific location. The `from_location` is mandatory. The `to_location` is either mandatory, optional or not allowed depending on rule type. — shape: {from_location?: string, to_location?: string}
  --enabled: oneof<nothing, bool> # Whether this rule should be in effect (`true`) or on hold (`false`). (e.g. true)
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --parameters: record # Parameters for this rule; depends on the rule type. Refer to the rule type specification for details.
  --type: string@type-completer-1 # The type of location rule to be applied. Allow: items at `conditions.from_location` can only move to `conditions.to_location` and locations allowed in other `allow` rules (destination whitelist). Disallow: items at `conditions.from_location` cannot be moved to `conditions.to_location` and locations disallowed in other `disallow` rules (destination blacklist). Disappeared: items disappearing at `conditions.from_location` will be moved to `parameters.location` after `parameters.time_s` seconds. Debounce: items moves from `conditions.from_location` (and optionally to `conditions.to_location`) will be debounced with a period of `parameters.time_s` seconds, for a maximum of `parameters.max_periods` periods.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/locationrules/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: conditions, var: conditions}, {name: enabled, var: enabled}, {name: label, var: label}, {name: parameters, var: parameters}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, conditions: $conditions, enabled: $enabled, label: $label, parameters: $parameters, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all locations
#
# GET /locations
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string>>
# operationId: getLocations
export def "get-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --metadata: string # Filter based on metadata. Does a partial match on any value in the metadata object. It is also possible to do an exact/wildcard match on specific properties, e.g. `metadata.foo=bar`
  --text: string # Filter based on a full text search. Searched properties depend on the resource type. Matches on any of the given words. Supports quote (exact words) and minus (exclude) operators. (e.g. penguin)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locations"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: label, var: label}, {name: metadata, var: metadata}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, label: $label, metadata: $metadata, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create location
#
# POST /locations
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addLocation
export def "add-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/locations"
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: label, var: label}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    custom: $custom, label: $label, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete location
#
# DELETE /locations/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteLocation
export def "delete-location" [
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
    path: "/locations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get location
#
# GET /locations/{id}
# Returns: record<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string>
# operationId: getLocationById
export def "get-location-by-id" [
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
    path: "/locations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing location
#
# PUT /locations/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateLocation
export def "update-location" [
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
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/locations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: label, var: label}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, custom: $custom, label: $label, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all presences
#
# GET /presences
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, item: record, item_id: string, item_url: string, location: record, location_id: string, location_url: string, proximity: string, technology: string, time_created: string, time_updated: string, url: string>>
# operationId: getPresences
export def "get-presences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --item: string # Filter based on the item (e.g. 5b7d6cbd7503c445552a1664)
  --location: string # Filter based on the location (e.g. 5b7d6cbd7503c445552a1664)
  --proximity: string@proximity-completer # Filter based on the proximity. (e.g. immediate)
  --technology: string@technology-completer # Filter based on the detected technology of an item. (e.g. rfid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/presences"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: item, var: item}, {name: location, var: location}, {name: proximity, var: proximity}, {name: technology, var: technology}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, item: $item, location: $location, proximity: $proximity, technology: $technology
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get presence
#
# GET /presences/{id}
# Returns: record<id: string, item: record<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_present: bool, move_count: int, protocol: string, sets: list<string>, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string>, item_id: string, item_url: string, location: record<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string>, location_id: string, location_url: string, proximity: string, technology: string, time_created: string, time_updated: string, url: string>
# operationId: getPresenceById
export def "get-presence-by-id" [
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
    path: "/presences/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all services
#
# GET /services
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<boot_count: int, config: record, config_request: record, id: string, name: string, restart_request: bool, time_created: string, time_updated: string, url: string, version: string>>
# operationId: getServices
export def "get-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --name: string # Filter based on the name of the resource. Supports wildcards: `*` (e.g. Foo Bar)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/services"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get service
#
# GET /services/{id}
# Returns: record<boot_count: int, config: record, config_request: record, id: string, name: string, restart_request: bool, time_created: string, time_updated: string, url: string, version: string>
# operationId: getServiceById
export def "get-service-by-id" [
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
    path: "/services/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing service
#
# PUT /services/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateService
export def "update-service" [
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
  --config-request: record # Object containing the new configuration. This will be applied automatically when the values are valid. (e.g. {foo: bar})
  --restart-request: oneof<nothing, bool> # Set this to `true` to send a reset request for the specific resource. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/services/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config_request, var: config_request}, {name: restart_request, var: restart_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, config_request: $config_request, restart_request: $restart_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all item lists
#
# GET /sets/itemlists
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, list: string, metadata: record, sha1: string, time_created: string, time_updated: string, total: int>>
# operationId: getItemLists
export def "get-item-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --metadata: string # Filter based on metadata. Does a partial match on any value in the metadata object. It is also possible to do an exact/wildcard match on specific properties, e.g. `metadata.foo=bar`
  --text: string # Filter based on a full text search. Searched properties depend on the resource type. Matches on any of the given words. Supports quote (exact words) and minus (exclude) operators. (e.g. penguin)
  --total: int # Filter based on the total amount of items in the list (e.g. 2)
  --sha1: string # The sha1 checksum of the list. This will change when the list is mutated. (e.g. 92cfceb39d57d914ed8b14d0e37643de0797ae56)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sets/itemlists"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: label, var: label}, {name: metadata, var: metadata}, {name: text, var: text}, {name: total, var: total}, {name: sha1, var: sha1}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, label: $label, metadata: $metadata, text: $text, total: $total, sha1: $sha1
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create item list
#
# POST /sets/itemlists
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addItemList
export def "add-item-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sets/itemlists"
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: label, var: label}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    custom: $custom, label: $label, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete item list
#
# DELETE /sets/itemlists/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteItemSet
export def "delete-item-set" [
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
    path: "/sets/itemlists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item list
#
# GET /sets/itemlists/{id}
# Returns: record<custom: any, id: string, label: string, list: string, metadata: record, sha1: string, time_created: string, time_updated: string, total: int>
# operationId: getItemListById
export def "get-item-list-by-id" [
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
    path: "/sets/itemlists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing item list
#
# PUT /sets/itemlists/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateItemList
export def "update-item-list" [
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
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sets/itemlists/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: label, var: label}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, custom: $custom, label: $label, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item ids for this list
#
# GET /sets/itemlists/{id}/ids
# Returns: list<string>
# operationId: getItemListIdsById
export def "get-item-list-ids-by-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sets/itemlists/{id}/ids"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add items to an existing list
#
# POST /sets/itemlists/{id}/ids
# Returns: record<status: int, total: int>
# operationId: addItemIdsList
export def "add-item-ids-list" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sets/itemlists/{id}/ids"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete item from list
#
# DELETE /sets/itemlists/{id}/ids/{itemId}
# Returns: record<status: int, total: int>
# operationId: deleteItemIdFromItemList
export def "delete-item-id-from-item-list" [
  id: string
  item_id: string
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
    path: "/sets/itemlists/{id}/ids/{itemId}"
    path_params: [{name: id, var: id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all spot lists
#
# GET /sets/spotlists
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, list: string, metadata: record, time_created: string, time_updated: string, total: int>>
# operationId: getSpotLists
export def "get-spot-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --metadata: string # Filter based on metadata. Does a partial match on any value in the metadata object. It is also possible to do an exact/wildcard match on specific properties, e.g. `metadata.foo=bar`
  --text: string # Filter based on a full text search. Searched properties depend on the resource type. Matches on any of the given words. Supports quote (exact words) and minus (exclude) operators. (e.g. penguin)
  --total: int # Filter based on the total amount of spots in the list (e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sets/spotlists"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: label, var: label}, {name: metadata, var: metadata}, {name: text, var: text}, {name: total, var: total}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, label: $label, metadata: $metadata, text: $text, total: $total
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create spot list
#
# POST /sets/spotlists
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addSpotList
export def "add-spot-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sets/spotlists"
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: label, var: label}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    custom: $custom, label: $label, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete spot list
#
# DELETE /sets/spotlists/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteSpotList
export def "delete-spot-list" [
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
    path: "/sets/spotlists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Info for a specific spot list
#
# GET /sets/spotlists/{id}
# Returns: record<custom: any, id: string, label: string, list: string, metadata: record, time_created: string, time_updated: string, total: int>
# operationId: getSpotListById
export def "get-spot-list-by-id" [
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
    path: "/sets/spotlists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing spot list
#
# PUT /sets/spotlists/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateSpotList
export def "update-spot-list" [
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
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sets/spotlists/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: label, var: label}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, custom: $custom, label: $label, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spot ids for this list
#
# GET /sets/spotlists/{id}/ids
# Returns: list<string>
# operationId: getSpotListIdsById
export def "get-spot-list-ids-by-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sets/spotlists/{id}/ids"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add spots to an existing list
#
# POST /sets/spotlists/{id}/ids
# Returns: record<status: int, total: int>
# operationId: addItemIdsSpotList
export def "add-item-ids-spot-list" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sets/spotlists/{id}/ids"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete spot from list
#
# DELETE /sets/spotlists/{id}/ids/{itemId}
# Returns: record<status: int, total: int>
# operationId: deleteItemIdFromSpotList
export def "delete-item-id-from-spot-list" [
  id: string
  item_id: string
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
    path: "/sets/spotlists/{id}/ids/{itemId}"
    path_params: [{name: id, var: id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all spots
#
# GET /spots
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<antenna_report_locations: list, config: record, config_request: record, geo_coords: record, id: string, is_online: bool, request_counter: int, senses: record, senses_request: record, serial_number: int, status: any, time_created: string, time_updated: string, url: string>>
# operationId: getSpots
export def "get-spots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --is-online: oneof<nothing, bool> # Filter based on the online status. (e.g. true)
  --request-counter: int # Filter based on the amount of request made (e.g. 73807)
  --serial-number: int # Filter based on the serial number. (e.g. 1337)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spots"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: is_online, var: is_online}, {name: request_counter, var: request_counter}, {name: serial_number, var: serial_number}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, is_online: $is_online, request_counter: $request_counter, serial_number: $serial_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spot
#
# GET /spots/{id}
# Returns: record<antenna_report_locations: table<antenna_number: int, report_location: record, report_location_id: string, report_location_url: string>, config: record, config_request: record, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_online: bool, request_counter: int, senses: record, senses_request: record, serial_number: int, status: any, time_created: string, time_updated: string, url: string>
# operationId: getSpotById
export def "get-spot-by-id" [
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
    path: "/spots/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing spot
#
# PUT /spots/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateSpot
export def "update-spot" [
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
  --antenna-report-locations: list # You may configure this field to an object which couples individual antenna ports to locations. — item shape: {antenna_number?: int}
  --config-request: record # Object containing the new configuration. This will be applied automatically when the values are valid. (e.g. {foo: bar})
  --geo-coords: record # Last known geolocation estimate of this object. Not guaranteed to be included in response. — shape: {lat?: float, lng?: float}
  --senses-request: record # Object containing the new senses configuration. See [Sense & Control](https://intellifi.zendesk.com/hc/en-us/sections/360001568254) documentation for more information. (e.g. {foo: bar})
  --report-location: string # Unique identifier for resource. (e.g. 5b7d6cbd7503c445552a1664)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/spots/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: antenna_report_locations, var: antenna_report_locations}, {name: config_request, var: config_request}, {name: geo_coords, var: geo_coords}, {name: senses_request, var: senses_request}, {name: report_location, var: report_location}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, antenna_report_locations: $antenna_report_locations, config_request: $config_request, geo_coords: $geo_coords, senses_request: $senses_request, report_location: $report_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spotsets
#
# GET /spots/{id}/sets
# Returns: record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string>
# operationId: getSpotSetsById
export def "get-spot-sets-by-id" [
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
    path: "/spots/{id}/sets"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create spotset
#
# POST /spots/{id}/sets
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addSpotSet
export def "add-spot-set" [
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
  --setid: int # Spot set unique identifier. Must be unique within a single device
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spots/{id}/sets"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: setid, var: setid}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    id: $id, setid: $setid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spotset
#
# GET /spots/{id}/sets/{setId}
# Returns: record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string>
# operationId: getSpotSetById
export def "get-spot-set-by-id" [
  id: string
  set_id: string
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
    path: "/spots/{id}/sets/{setId}"
    path_params: [{name: id, var: id}, {name: setId, var: set_id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, set_id: $set_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing spotset
#
# PUT /spots/{id}/sets/{setId}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateSpotSet
export def "update-spot-set" [
  id: string
  set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # Request to delete a set. Remove request needs to be synchronized to the device, so it may take some time before the resource is being removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/spots/{id}/sets/{setId}"
    path_params: [{name: id, var: id}, {name: setId, var: set_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, set_id: $set_id, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spotsets
#
# GET /spotsets
# Returns: record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string>
export def "get-spotsets" [
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
    path: "/spotsets"
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create spotset
#
# POST /spotsets
# Returns: record<resource: record<id: string, url: string>, status: int>
export def "post-spotsets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --setid: int # Spot set unique identifier. Must be unique within a single device
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spotsets"
    body: {content_type: "application/json", kind: json, fields: [{name: setid, var: setid}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    setid: $setid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spotset
#
# GET /spotsets/{id}
# Returns: record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string>
export def "get-spotsets-id" [
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
    path: "/spotsets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing spotset
#
# PUT /spotsets/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
export def "put-spotsets-id" [
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
  --delete: oneof<nothing, bool> # Request to delete a set. Remove request needs to be synchronized to the device, so it may take some time before the resource is being removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/spotsets/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all subscriptions
#
# GET /subscriptions
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, database_hold_time_h: int, description: string, events_url: string, id: string, populate_events: bool, target_delivery_last_failure: record, target_delivery_status: record, target_retry: bool, target_url: string, time_created: string, time_updated: string, topic_filter: string, url: string, verify_target_certificate: bool>>
# operationId: getSubscriptions
export def "get-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --topic-filter: string # Filter on the topic filter. Make sure to use [percent-encoding](https://en.wikipedia.org/wiki/Percent-encoding) in the query parameter.
  --description: string # Filter based on the description.
  --database-hold-time-h: int # Filter based on the number of hours events are retained in the database.
  --populate-events: oneof<nothing, bool> # Filter based on subscriptions that populate the events
  --verify-target-certificate: oneof<nothing, bool> # Filter on the verification of the target certificate.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: topic_filter, var: topic_filter}, {name: description, var: description}, {name: database_hold_time_h, var: database_hold_time_h}, {name: populate_events, var: populate_events}, {name: verify_target_certificate, var: verify_target_certificate}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, topic_filter: $topic_filter, description: $description, database_hold_time_h: $database_hold_time_h, populate_events: $populate_events, verify_target_certificate: $verify_target_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create subscription
#
# POST /subscriptions
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: addSubscription
export def "add-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --database-hold-time-h: int # The number of hours this event is retained in the database. *Only use larger numbers if you know what you are doing.* A couple of hours is enough for most use cases. (e.g. 2)
  --description: string # Additional field to add some notes about this subscription. (nullable, e.g. Item events)
  --populate-events: oneof<nothing, bool> # If set to `true`, resource references in an event (e.g. the location an item moved to) are resolved and populated with data instead of giving just an ID.
  --target-retry: oneof<nothing, bool> # Set to `true` if you want our server to retry if `target_url` is not giving back a `2xx` success code.
  --target-url: string # Url to an external service that all applicable events are pushed to (webhook). Configure to `null` if you don't wish to use this (default).
  --topic-filter: string # MQTT filter that is applied to all events. Allows you to select and filter events. See [Event filtering](https://intellifi.zendesk.com/hc/en-us/articles/360008791494) for more information (e.g. items/#)
  --verify-target-certificate: oneof<nothing, bool> # Whether or not the `target_url` endpoint TLS certificate is verified to be valid.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions"
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: database_hold_time_h, var: database_hold_time_h}, {name: description, var: description}, {name: populate_events, var: populate_events}, {name: target_retry, var: target_retry}, {name: target_url, var: target_url}, {name: topic_filter, var: topic_filter}, {name: verify_target_certificate, var: verify_target_certificate}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    custom: $custom, database_hold_time_h: $database_hold_time_h, description: $description, populate_events: $populate_events, target_retry: $target_retry, target_url: $target_url, topic_filter: $topic_filter, verify_target_certificate: $verify_target_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete subscription
#
# DELETE /subscriptions/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteSubscription
export def "delete-subscription" [
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
    path: "/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subscription
#
# GET /subscriptions/{id}
# Returns: record<custom: any, database_hold_time_h: int, description: string, events_url: string, id: string, populate_events: bool, target_delivery_last_failure: record, target_delivery_status: record, target_retry: bool, target_url: string, time_created: string, time_updated: string, topic_filter: string, url: string, verify_target_certificate: bool>
# operationId: getSubscriptionById
export def "get-subscription-by-id" [
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
    path: "/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing subscription
#
# PUT /subscriptions/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateSubscription
export def "update-subscription" [
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
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --database-hold-time-h: int # The number of hours this event is retained in the database. *Only use larger numbers if you know what you are doing.* A couple of hours is enough for most use cases. (e.g. 2)
  --description: string # Additional field to add some notes about this subscription. (nullable, e.g. Item events)
  --populate-events: oneof<nothing, bool> # If set to `true`, resource references in an event (e.g. the location an item moved to) are resolved and populated with data instead of giving just an ID.
  --target-retry: oneof<nothing, bool> # Set to `true` if you want our server to retry if `target_url` is not giving back a `2xx` success code.
  --target-url: string # Url to an external service that all applicable events are pushed to (webhook). Configure to `null` if you don't wish to use this (default).
  --topic-filter: string # MQTT filter that is applied to all events. Allows you to select and filter events. See [Event filtering](https://intellifi.zendesk.com/hc/en-us/articles/360008791494) for more information (e.g. items/#)
  --verify-target-certificate: oneof<nothing, bool> # Whether or not the `target_url` endpoint TLS certificate is verified to be valid.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: database_hold_time_h, var: database_hold_time_h}, {name: description, var: description}, {name: populate_events, var: populate_events}, {name: target_retry, var: target_retry}, {name: target_url, var: target_url}, {name: topic_filter, var: topic_filter}, {name: verify_target_certificate, var: verify_target_certificate}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, custom: $custom, database_hold_time_h: $database_hold_time_h, description: $description, populate_events: $populate_events, target_retry: $target_retry, target_url: $target_url, topic_filter: $topic_filter, verify_target_certificate: $verify_target_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subscription events
#
# GET /subscriptions/{id}/events
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record, url: string>>
# operationId: getEventsForSubscriptionById
export def "get-events-for-subscription-by-id" [
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
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --qp-id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664) (spec name: id)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --topic-resource-type: string@topic-resource-type-completer # Filter on the topic resource type (e.g. items)
  --topic-action: string@topic-action-completer # Filter on the topic action (e.g. created)
  --topic-resource: string # Filter on the topic resource id (e.g. 5b7d6cbd7503c445552a1664)
  --time-event: string # Filter on the time the event was generated on the device. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-expire: string # Filter on the time the event will expire. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{id}/events"
    path_params: [{name: id, var: id}]
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: qp_id}, {name: time_created, var: time_created}, {name: "topic.resource_type", var: topic_resource_type}, {name: "topic.action", var: topic_action}, {name: "topic.resource", var: topic_resource}, {name: time_event, var: time_event}, {name: time_expire, var: time_expire}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, qp_id: $qp_id, time_created: $time_created, topic_resource_type: $topic_resource_type, topic_action: $topic_action, topic_resource: $topic_resource, time_event: $time_event, time_expire: $time_expire
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users
#
# GET /users
# Returns: record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<email: string, first_name: string, id: string, is_admin: bool, is_locked: bool, last_name: string, password: string, time_created: string, time_updated: string, url: string>>
# operationId: getUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --email: string # Filter on the email address.
  --first-name: string # Filter on the first name.
  --last-name: string # Filter on the last name.
  --is-admin: oneof<nothing, bool> # Filter on the administrator status.
  --is-locked: oneof<nothing, bool> # Filter on the locked status.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: after, var: after}, {name: after_id, var: after_id}, {name: before, var: before}, {name: before_id, var: before_id}, {name: from, var: from}, {name: from_id, var: from_id}, {name: id_only, var: id_only}, {name: limit, var: limit}, {name: populate, var: populate}, {name: results_only, var: results_only}, {name: select, var: select}, {name: sort, var: sort}, {name: until, var: until}, {name: until_id, var: until_id}, {name: timeout_s, var: timeout_s}, {name: id, var: id}, {name: time_created, var: time_created}, {name: time_updated, var: time_updated}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: is_admin, var: is_admin}, {name: is_locked, var: is_locked}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    after: $after, after_id: $after_id, before: $before, before_id: $before_id, from: $from, from_id: $from_id, id_only: $id_only, limit: $limit, populate: $populate, results_only: $results_only, select: $select, sort: $sort, until: $until, until_id: $until_id, timeout_s: $timeout_s, id: $id, time_created: $time_created, time_updated: $time_updated, email: $email, first_name: $first_name, last_name: $last_name, is_admin: $is_admin, is_locked: $is_locked
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user
#
# POST /users
# Returns: record<resource: record<id: string, url: string>, status: int>
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
  --email: string # Email address (e.g. user@intellifi.nl)
  --first-name: string # First name (e.g. Foo)
  --is-admin: oneof<nothing, bool> # Whether or not this is an administrator.
  --is-locked: oneof<nothing, bool> # Whether or not this user is locked and can't change the password.
  --last-name: string # Last name (e.g. Bar)
  --password: string # Password of the user (e.g. password1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: is_admin, var: is_admin}, {name: is_locked, var: is_locked}, {name: last_name, var: last_name}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [201]
    auth: "cookie-brain.sid"
  } {
    email: $email, first_name: $first_name, is_admin: $is_admin, is_locked: $is_locked, last_name: $last_name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user
#
# DELETE /users/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: deleteUser
export def "delete-user" [
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
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user
#
# GET /users/{id}
# Returns: record<email: string, first_name: string, id: string, is_admin: bool, is_locked: bool, last_name: string, password: string, time_created: string, time_updated: string, url: string>
# operationId: getUserById
export def "get-user-by-id" [
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
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing user
#
# PUT /users/{id}
# Returns: record<resource: record<id: string, url: string>, status: int>
# operationId: updateUser
export def "update-user" [
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
  --email: string # Email address (e.g. user@intellifi.nl)
  --first-name: string # First name (e.g. Foo)
  --is-admin: oneof<nothing, bool> # Whether or not this is an administrator.
  --is-locked: oneof<nothing, bool> # Whether or not this user is locked and can't change the password.
  --last-name: string # Last name (e.g. Bar)
  --password: string # Password of the user (e.g. password1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: is_admin, var: is_admin}, {name: is_locked, var: is_locked}, {name: last_name, var: last_name}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: "cookie-brain.sid"
  } {
    id: $id, email: $email, first_name: $first_name, is_admin: $is_admin, is_locked: $is_locked, last_name: $last_name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
