# Auto-generated client for Neblio REST API Suite v1.3.0
# Source: https://api.apis.guru/v2/specs/nebl.io/1.3.0/openapi.json
# Auth: --token flag or $env.NEBLIO_REST_API_SUITE_TOKEN

const CLIENT = {
  base_url: "https://ntp1node.nebl.io"
  token_env_var: "NEBLIO_REST_API_SUITE_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
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

def base-url-completer [] { ["https://ntp1node.nebl.io" "http://127.0.0.1:6326" "http://127.0.0.1:16326"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    json-rpc: "record<error: record, id: string, result: record>"
    get-address: "record<addrStr: string, balance: float, balanceSat: float, totalReceived: float, totalReceivedSat: float, totalSent: float, totalSentSat: float, transactions: list<string>, txAppearances: float, unconfirmedBalance: float, unconfirmedBalanceSat: float, unconfirmedTxAppearances: float>"
    get-address-balance: "float"
    get-address-total-received: "float"
    get-address-total-sent: "float"
    get-address-unconfirmed-balance: "float"
    get-address-utxos: "table<address: string, amount: float, confirmations: float, scriptPubKey: string, ts: float, txid: string, vout: float>"
    get-block-index: "record<blockHash: string>"
    get-block: "record<bits: string, confirmations: float, difficulty: float, hash: string, height: float, merkleroot: string, nextblockhash: string, nonce: float, previousblockhash: string, reward: float, size: float, time: float, tx: list<string>, version: float>"
    get-raw-tx: "record<rawtx: string>"
    get-status: "record"
    get-sync: "record<blockChainHeight: float, error: string, height: float, status: string, syncPercentage: float, type: string>"
    send-tx: "record<txid: string>"
    get-tx: "record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: table<n: float, scriptSig: record, sequence: float, txid: string, value: float, valueSat: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, used: bool, usedBlockheight: float, usedTxid: string, value: float>>"
    get-txs: "record<pagesTotal: float, txs: table<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: list, vout: list>>"
    get-address-info: "record<address: string, utxos: table<blockheight: float, blocktime: float, index: float, scriptPubKey: record, tokens: list, txid: string, used: bool, value: float>>"
    broadcast-tx: "record<txid: string>"
    burn-token: "record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string>"
    issue-token: "record<tokenId: string, txHex: string>"
    send-token: "record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string>"
    get-token-holders: "record<aggregationPolicy: string, divibility: float, holders: table<address: string, amount: float>, lockStatus: bool, someUtxo: string, tokenId: string>"
    get-token-id: "record<tokenId: string, tokenName: string>"
    get-token-metadata: "record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float>"
    get-token-metadata-of-utxo: "record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float>"
    get-transaction-info: "record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, hex: string, locktime: float, time: float, totalsent: float, txid: string, version: float, vin: table<previousOutput: record, scriptSig: record, sequence: float, tokens: list, txid: string, value: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, tokens: list, used: bool, usedBlockheight: float, usedTxid: string, value: float>>"
    testnet-get-faucet: "record<data: record<txId: string>, status: string>"
    testnet-get-address: "record<addrStr: string, balance: float, balanceSat: float, totalReceived: float, totalReceivedSat: float, totalSent: float, totalSentSat: float, transactions: list<string>, txAppearances: float, unconfirmedBalance: float, unconfirmedBalanceSat: float, unconfirmedTxAppearances: float>"
    testnet-get-address-balance: "float"
    testnet-get-address-total-received: "float"
    testnet-get-address-total-sent: "float"
    testnet-get-address-unconfirmed-balance: "float"
    testnet-get-address-utxos: "table<address: string, amount: float, confirmations: float, scriptPubKey: string, ts: float, txid: string, vout: float>"
    testnet-get-block-index: "record<blockHash: string>"
    testnet-get-block: "record<bits: string, confirmations: float, difficulty: float, hash: string, height: float, merkleroot: string, nextblockhash: string, nonce: float, previousblockhash: string, reward: float, size: float, time: float, tx: list<string>, version: float>"
    testnet-get-raw-tx: "record<rawtx: string>"
    testnet-get-status: "record"
    testnet-get-sync: "record<blockChainHeight: float, error: string, height: float, status: string, syncPercentage: float, type: string>"
    testnet-send-tx: "record<txid: string>"
    testnet-get-tx: "record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: table<n: float, scriptSig: record, sequence: float, txid: string, value: float, valueSat: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, used: bool, usedBlockheight: float, usedTxid: string, value: float>>"
    testnet-get-txs: "record<pagesTotal: float, txs: table<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: list, vout: list>>"
    testnet-get-address-info: "record<address: string, utxos: table<blockheight: float, blocktime: float, index: float, scriptPubKey: record, tokens: list, txid: string, used: bool, value: float>>"
    testnet-broadcast-tx: "record<txid: string>"
    testnet-burn-token: "record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string>"
    testnet-issue-token: "record<tokenId: string, txHex: string>"
    testnet-send-token: "record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string>"
    testnet-get-token-holders: "record<aggregationPolicy: string, divibility: float, holders: table<address: string, amount: float>, lockStatus: bool, someUtxo: string, tokenId: string>"
    testnet-get-token-id: "record<tokenId: string, tokenName: string>"
    testnet-get-token-metadata: "record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float>"
    testnet-get-token-metadata-of-utxo: "record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float>"
    testnet-get-transaction-info: "record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, hex: string, locktime: float, time: float, totalsent: float, txid: string, version: float, vin: table<previousOutput: record, scriptSig: record, sequence: float, tokens: list, txid: string, value: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, tokens: list, used: bool, usedBlockheight: float, usedTxid: string, value: float>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["json-rpc" "get-address" "get-address-balance" "get-address-total-received" "get-address-total-sent" "get-address-unconfirmed-balance" "get-address-utxos" "get-block-index" "get-block" "get-raw-tx" "get-status" "get-sync" "send-tx" "get-tx" "get-txs" "get-address-info" "broadcast-tx" "burn-token" "issue-token" "send-token" "get-token-holders" "get-token-id" "get-token-metadata" "get-token-metadata-of-utxo" "get-transaction-info" "testnet-get-faucet" "testnet-get-address" "testnet-get-address-balance" "testnet-get-address-total-received" "testnet-get-address-total-sent" "testnet-get-address-unconfirmed-balance" "testnet-get-address-utxos" "testnet-get-block-index" "testnet-get-block" "testnet-get-raw-tx" "testnet-get-status" "testnet-get-sync" "testnet-send-tx" "testnet-get-tx" "testnet-get-txs" "testnet-get-address-info" "testnet-broadcast-tx" "testnet-burn-token" "testnet-issue-token" "testnet-send-token" "testnet-get-token-holders" "testnet-get-token-id" "testnet-get-token-metadata" "testnet-get-token-metadata-of-utxo" "testnet-get-transaction-info" "commands"] | sort) } | get name | first)
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

# Send a JSON-RPC call to a localhost neblio-Qt or nebliod node
#
# POST /
# Returns: record<error: record, id: string, result: record>
# operationId: json_rpc
export def "json-rpc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Identifier of RCP caller (default: neblio-apis, e.g. neblio-apis)
  jsonrpc: string # JSON-RPC version (default: 1.0, e.g. 1.0)
  method: string # Name of the Neblio RPC method to call (e.g. getstakinginfo)
  params: list<string> # Array of string params that should be passed to the RPC method. (e.g. [])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: jsonrpc, var: jsonrpc}, {name: method, var: method}, {name: params, var: params}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "http://127.0.0.1:6326"
    auth: basic
  } {
    id: $id, jsonrpc: $jsonrpc, method: $method, params: $params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns address object
#
# GET /ins/addr/{address}
# Returns: record<addrStr: string, balance: float, balanceSat: float, totalReceived: float, totalReceivedSat: float, totalSent: float, totalSentSat: float, transactions: list<string>, txAppearances: float, unconfirmedBalance: float, unconfirmedBalanceSat: float, unconfirmedTxAppearances: float>
# operationId: getAddress
export def "get-address" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ins/addr/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns address balance in sats
#
# GET /ins/addr/{address}/balance
# Returns: float
# operationId: getAddressBalance
export def "get-address-balance" [
  address: string
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
    path: "/ins/addr/{address}/balance"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns total received by address in sats
#
# GET /ins/addr/{address}/totalReceived
# Returns: float
# operationId: getAddressTotalReceived
export def "get-address-total-received" [
  address: string
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
    path: "/ins/addr/{address}/totalReceived"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns total sent by address in sats
#
# GET /ins/addr/{address}/totalSent
# Returns: float
# operationId: getAddressTotalSent
export def "get-address-total-sent" [
  address: string
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
    path: "/ins/addr/{address}/totalSent"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns address unconfirmed balance in sats
#
# GET /ins/addr/{address}/unconfirmedBalance
# Returns: float
# operationId: getAddressUnconfirmedBalance
export def "get-address-unconfirmed-balance" [
  address: string
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
    path: "/ins/addr/{address}/unconfirmedBalance"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all UTXOs at a given address
#
# GET /ins/addr/{address}/utxo
# Returns: table<address: string, amount: float, confirmations: float, scriptPubKey: string, ts: float, txid: string, vout: float>
# operationId: getAddressUtxos
export def "get-address-utxos" [
  address: string
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
    path: "/ins/addr/{address}/utxo"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns block hash of block
#
# GET /ins/block-index/{blockindex}
# Returns: record<blockHash: string>
# operationId: getBlockIndex
export def "get-block-index" [
  blockindex: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ins/block-index/{blockindex}"
    path_params: [{name: blockindex, var: blockindex}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    blockindex: $blockindex
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information regarding a Neblio block
#
# GET /ins/block/{blockhash}
# Returns: record<bits: string, confirmations: float, difficulty: float, hash: string, height: float, merkleroot: string, nextblockhash: string, nonce: float, previousblockhash: string, reward: float, size: float, time: float, tx: list<string>, version: float>
# operationId: getBlock
export def "get-block" [
  blockhash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ins/block/{blockhash}"
    path_params: [{name: blockhash, var: blockhash}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    blockhash: $blockhash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns raw transaction hex
#
# GET /ins/rawtx/{txid}
# Returns: record<rawtx: string>
# operationId: getRawTx
export def "get-raw-tx" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ins/rawtx/{txid}"
    path_params: [{name: txid, var: txid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    txid: $txid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Utility API for calling several blockchain node functions
#
# GET /ins/status
# Returns: record
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
  --q: string # Function to call, getInfo, getDifficulty, getBestBlockHash, or getLastBlockHash
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ins/status"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get node sync status
#
# GET /ins/sync
# Returns: record<blockChainHeight: float, error: string, height: float, status: string, syncPercentage: float, type: string>
# operationId: getSync
export def "get-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ins/sync"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Broadcasts a signed raw transaction to the network (not NTP1 specific)
#
# POST /ins/tx/send
# Returns: record<txid: string>
# operationId: sendTx
export def "send-tx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rawtx: string # Signed raw tx hex to broadcast
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ins/tx/send"
    body: {content_type: "application/json", kind: json, fields: [{name: rawtx, var: rawtx}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rawtx: $rawtx
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns transaction object
#
# GET /ins/tx/{txid}
# Returns: record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: table<n: float, scriptSig: record, sequence: float, txid: string, value: float, valueSat: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, used: bool, usedBlockheight: float, usedTxid: string, value: float>>
# operationId: getTx
export def "get-tx" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ins/tx/{txid}"
    path_params: [{name: txid, var: txid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    txid: $txid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get transactions by block or address
#
# GET /ins/txs
# Returns: record<pagesTotal: float, txs: table<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: list, vout: list>>
# operationId: getTxs
export def "get-txs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Address
  --block: string # Block Hash
  --page-num: float # Page number to display
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ins/txs"
    query: [{name: address, var: address}, {name: block, var: block}, {name: pageNum, var: page_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address, block: $block, page_num: $page_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information On a Neblio Address
#
# GET /ntp1/addressinfo/{address}
# Returns: record<address: string, utxos: table<blockheight: float, blocktime: float, index: float, scriptPubKey: record, tokens: list, txid: string, used: bool, value: float>>
# operationId: getAddressInfo
export def "get-address-info" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ntp1/addressinfo/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Broadcasts a signed raw transaction to the network
#
# POST /ntp1/broadcast
# Returns: record<txid: string>
# operationId: broadcastTx
export def "broadcast-tx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tx_hex: string # Signed raw tx hex to broadcast
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ntp1/broadcast"
    body: {content_type: "application/json", kind: json, fields: [{name: txHex, var: tx_hex}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tx_hex: $tx_hex
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Builds a transaction that burns an NTP1 Token
#
# POST /ntp1/burntoken
# Returns: record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string>
# operationId: burnToken
export def "burn-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  burn: list # Array of objects representing tokens to be burned — item shape: {amount?: float, tokenId?: string}
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --from: list<string> # Array of addresses to send the token from
  --transfer: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ntp1/burntoken"
    body: {content_type: "application/json", kind: json, fields: [{name: burn, var: burn}, {name: fee, var: fee}, {name: from, var: from}, {name: transfer, var: transfer}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    burn: $burn, fee: $fee, from: $from, transfer: $transfer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Builds a transaction that issues a new NTP1 Token
#
# POST /ntp1/issue
# Returns: record<tokenId: string, txHex: string>
# operationId: issueToken
export def "issue-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Number of tokens to issue
  divisibility: float # Number of decimal places the token should be divisble by (0-7)
  fee: float # Fee in satoshi to include in the issuance transaction min 1000000000 (10 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  issue_address: string # Address issuing the token
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --reissuable: oneof<nothing, bool> # whether the token should be reissuable
  transfer: list # item shape: {address?: string, amount?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ntp1/issue"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: divisibility, var: divisibility}, {name: fee, var: fee}, {name: flags, var: flags}, {name: issueAddress, var: issue_address}, {name: metadata, var: metadata}, {name: reissuable, var: reissuable, required: true}, {name: transfer, var: transfer}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    amount: $amount, divisibility: $divisibility, fee: $fee, flags: $flags, issue_address: $issue_address, metadata: $metadata, reissuable: $reissuable, transfer: $transfer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Builds a transaction that sends an NTP1 Token
#
# POST /ntp1/sendtoken
# Returns: record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string>
# operationId: sendToken
export def "send-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  --from: list<string> # Array of addresses to send the token from
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --sendutxo: list<string> # Array of UTXOs to send the token from
  to: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ntp1/sendtoken"
    body: {content_type: "application/json", kind: json, fields: [{name: fee, var: fee}, {name: flags, var: flags}, {name: from, var: from}, {name: metadata, var: metadata}, {name: sendutxo, var: sendutxo}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fee: $fee, flags: $flags, from: $from, metadata: $metadata, sendutxo: $sendutxo, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Addresses Holding a Token
#
# GET /ntp1/stakeholders/{tokenid}
# Returns: record<aggregationPolicy: string, divibility: float, holders: table<address: string, amount: float>, lockStatus: bool, someUtxo: string, tokenId: string>
# operationId: getTokenHolders
export def "get-token-holders" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ntp1/stakeholders/{tokenid}"
    path_params: [{name: tokenid, var: tokenid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tokenid: $tokenid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the tokenId representing a token
#
# GET /ntp1/tokenid/{tokensymbol}
# Returns: record<tokenId: string, tokenName: string>
# operationId: getTokenId
export def "get-token-id" [
  tokensymbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ntp1/tokenid/{tokensymbol}"
    path_params: [{name: tokensymbol, var: tokensymbol}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tokensymbol: $tokensymbol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Metadata of Token
#
# GET /ntp1/tokenmetadata/{tokenid}
# Returns: record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float>
# operationId: getTokenMetadata
export def "get-token-metadata" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ntp1/tokenmetadata/{tokenid}"
    path_params: [{name: tokenid, var: tokenid}]
    query: [{name: verbosity, var: verbosity}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tokenid: $tokenid, verbosity: $verbosity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get UTXO Metadata of Token
#
# GET /ntp1/tokenmetadata/{tokenid}/{utxo}
# Returns: record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float>
# operationId: getTokenMetadataOfUtxo
export def "get-token-metadata-of-utxo" [
  tokenid: string
  utxo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ntp1/tokenmetadata/{tokenid}/{utxo}"
    path_params: [{name: tokenid, var: tokenid}, {name: utxo, var: utxo}]
    query: [{name: verbosity, var: verbosity}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tokenid: $tokenid, utxo: $utxo, verbosity: $verbosity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information On an NTP1 Transaction
#
# GET /ntp1/transactioninfo/{txid}
# Returns: record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, hex: string, locktime: float, time: float, totalsent: float, txid: string, version: float, vin: table<previousOutput: record, scriptSig: record, sequence: float, tokens: list, txid: string, value: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, tokens: list, used: bool, usedBlockheight: float, usedTxid: string, value: float>>
# operationId: getTransactionInfo
export def "get-transaction-info" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ntp1/transactioninfo/{txid}"
    path_params: [{name: txid, var: txid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    txid: $txid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Withdraws testnet NEBL to the specified address
#
# GET /testnet/faucet
# Returns: record<data: record<txId: string>, status: string>
# operationId: testnet_getFaucet
export def "testnet-get-faucet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Your Neblio Testnet Address (required)
  --amount: float # Amount of NEBL to withdrawal in satoshis
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/testnet/faucet"
    query: [{name: address, var: address, required: true}, {name: amount, var: amount}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address, amount: $amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns address object
#
# GET /testnet/ins/addr/{address}
# Returns: record<addrStr: string, balance: float, balanceSat: float, totalReceived: float, totalReceivedSat: float, totalSent: float, totalSentSat: float, transactions: list<string>, txAppearances: float, unconfirmedBalance: float, unconfirmedBalanceSat: float, unconfirmedTxAppearances: float>
# operationId: testnet_getAddress
export def "testnet-get-address" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ins/addr/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns address balance in sats
#
# GET /testnet/ins/addr/{address}/balance
# Returns: float
# operationId: testnet_getAddressBalance
export def "testnet-get-address-balance" [
  address: string
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
    path: "/testnet/ins/addr/{address}/balance"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns total received by address in sats
#
# GET /testnet/ins/addr/{address}/totalReceived
# Returns: float
# operationId: testnet_getAddressTotalReceived
export def "testnet-get-address-total-received" [
  address: string
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
    path: "/testnet/ins/addr/{address}/totalReceived"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns total sent by address in sats
#
# GET /testnet/ins/addr/{address}/totalSent
# Returns: float
# operationId: testnet_getAddressTotalSent
export def "testnet-get-address-total-sent" [
  address: string
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
    path: "/testnet/ins/addr/{address}/totalSent"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns address unconfirmed balance in sats
#
# GET /testnet/ins/addr/{address}/unconfirmedBalance
# Returns: float
# operationId: testnet_getAddressUnconfirmedBalance
export def "testnet-get-address-unconfirmed-balance" [
  address: string
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
    path: "/testnet/ins/addr/{address}/unconfirmedBalance"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all UTXOs at a given address
#
# GET /testnet/ins/addr/{address}/utxo
# Returns: table<address: string, amount: float, confirmations: float, scriptPubKey: string, ts: float, txid: string, vout: float>
# operationId: testnet_getAddressUtxos
export def "testnet-get-address-utxos" [
  address: string
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
    path: "/testnet/ins/addr/{address}/utxo"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns block hash of block
#
# GET /testnet/ins/block-index/{blockindex}
# Returns: record<blockHash: string>
# operationId: testnet_getBlockIndex
export def "testnet-get-block-index" [
  blockindex: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ins/block-index/{blockindex}"
    path_params: [{name: blockindex, var: blockindex}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    blockindex: $blockindex
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information regarding a Neblio block
#
# GET /testnet/ins/block/{blockhash}
# Returns: record<bits: string, confirmations: float, difficulty: float, hash: string, height: float, merkleroot: string, nextblockhash: string, nonce: float, previousblockhash: string, reward: float, size: float, time: float, tx: list<string>, version: float>
# operationId: testnet_getBlock
export def "testnet-get-block" [
  blockhash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ins/block/{blockhash}"
    path_params: [{name: blockhash, var: blockhash}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    blockhash: $blockhash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns raw transaction hex
#
# GET /testnet/ins/rawtx/{txid}
# Returns: record<rawtx: string>
# operationId: testnet_getRawTx
export def "testnet-get-raw-tx" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ins/rawtx/{txid}"
    path_params: [{name: txid, var: txid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    txid: $txid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Utility API for calling several blockchain node functions
#
# GET /testnet/ins/status
# Returns: record
# operationId: testnet_getStatus
export def "testnet-get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Function to call, getInfo, getDifficulty, getBestBlockHash, or getLastBlockHash
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/testnet/ins/status"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get node sync status
#
# GET /testnet/ins/sync
# Returns: record<blockChainHeight: float, error: string, height: float, status: string, syncPercentage: float, type: string>
# operationId: testnet_getSync
export def "testnet-get-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ins/sync"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Broadcasts a signed raw transaction to the network (not NTP1 specific)
#
# POST /testnet/ins/tx/send
# Returns: record<txid: string>
# operationId: testnet_sendTx
export def "testnet-send-tx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rawtx: string # Signed raw tx hex to broadcast
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/testnet/ins/tx/send"
    body: {content_type: "application/json", kind: json, fields: [{name: rawtx, var: rawtx}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rawtx: $rawtx
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns transaction object
#
# GET /testnet/ins/tx/{txid}
# Returns: record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: table<n: float, scriptSig: record, sequence: float, txid: string, value: float, valueSat: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, used: bool, usedBlockheight: float, usedTxid: string, value: float>>
# operationId: testnet_getTx
export def "testnet-get-tx" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ins/tx/{txid}"
    path_params: [{name: txid, var: txid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    txid: $txid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get transactions by block or address
#
# GET /testnet/ins/txs
# Returns: record<pagesTotal: float, txs: table<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: list, vout: list>>
# operationId: testnet_getTxs
export def "testnet-get-txs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Address
  --block: string # Block Hash
  --page-num: float # Page number to display
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/testnet/ins/txs"
    query: [{name: address, var: address}, {name: block, var: block}, {name: pageNum, var: page_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address, block: $block, page_num: $page_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information On a Neblio Address
#
# GET /testnet/ntp1/addressinfo/{address}
# Returns: record<address: string, utxos: table<blockheight: float, blocktime: float, index: float, scriptPubKey: record, tokens: list, txid: string, used: bool, value: float>>
# operationId: testnet_getAddressInfo
export def "testnet-get-address-info" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ntp1/addressinfo/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Broadcasts a signed raw transaction to the network
#
# POST /testnet/ntp1/broadcast
# Returns: record<txid: string>
# operationId: testnet_broadcastTx
export def "testnet-broadcast-tx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tx_hex: string # Signed raw tx hex to broadcast
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/testnet/ntp1/broadcast"
    body: {content_type: "application/json", kind: json, fields: [{name: txHex, var: tx_hex}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tx_hex: $tx_hex
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Builds a transaction that burns an NTP1 Token
#
# POST /testnet/ntp1/burntoken
# Returns: record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string>
# operationId: testnet_burnToken
export def "testnet-burn-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  burn: list # Array of objects representing tokens to be burned — item shape: {amount?: float, tokenId?: string}
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --from: list<string> # Array of addresses to send the token from
  --transfer: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/testnet/ntp1/burntoken"
    body: {content_type: "application/json", kind: json, fields: [{name: burn, var: burn}, {name: fee, var: fee}, {name: from, var: from}, {name: transfer, var: transfer}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    burn: $burn, fee: $fee, from: $from, transfer: $transfer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Builds a transaction that issues a new NTP1 Token
#
# POST /testnet/ntp1/issue
# Returns: record<tokenId: string, txHex: string>
# operationId: testnet_issueToken
export def "testnet-issue-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Number of tokens to issue
  divisibility: float # Number of decimal places the token should be divisble by (0-7)
  fee: float # Fee in satoshi to include in the issuance transaction min 1000000000 (10 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  issue_address: string # Address issuing the token
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --reissuable: oneof<nothing, bool> # whether the token should be reissuable
  transfer: list # item shape: {address?: string, amount?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/testnet/ntp1/issue"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: divisibility, var: divisibility}, {name: fee, var: fee}, {name: flags, var: flags}, {name: issueAddress, var: issue_address}, {name: metadata, var: metadata}, {name: reissuable, var: reissuable, required: true}, {name: transfer, var: transfer}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    amount: $amount, divisibility: $divisibility, fee: $fee, flags: $flags, issue_address: $issue_address, metadata: $metadata, reissuable: $reissuable, transfer: $transfer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Builds a transaction that sends an NTP1 Token
#
# POST /testnet/ntp1/sendtoken
# Returns: record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string>
# operationId: testnet_sendToken
export def "testnet-send-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  --from: list<string> # Array of addresses to send the token from
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --sendutxo: list<string> # Array of UTXOs to send the token from
  to: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/testnet/ntp1/sendtoken"
    body: {content_type: "application/json", kind: json, fields: [{name: fee, var: fee}, {name: flags, var: flags}, {name: from, var: from}, {name: metadata, var: metadata}, {name: sendutxo, var: sendutxo}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fee: $fee, flags: $flags, from: $from, metadata: $metadata, sendutxo: $sendutxo, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Addresses Holding a Token
#
# GET /testnet/ntp1/stakeholders/{tokenid}
# Returns: record<aggregationPolicy: string, divibility: float, holders: table<address: string, amount: float>, lockStatus: bool, someUtxo: string, tokenId: string>
# operationId: testnet_getTokenHolders
export def "testnet-get-token-holders" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ntp1/stakeholders/{tokenid}"
    path_params: [{name: tokenid, var: tokenid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tokenid: $tokenid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the tokenId representing a token
#
# GET /testnet/ntp1/tokenid/{tokensymbol}
# Returns: record<tokenId: string, tokenName: string>
# operationId: testnet_getTokenId
export def "testnet-get-token-id" [
  tokensymbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ntp1/tokenid/{tokensymbol}"
    path_params: [{name: tokensymbol, var: tokensymbol}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tokensymbol: $tokensymbol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Metadata of Token
#
# GET /testnet/ntp1/tokenmetadata/{tokenid}
# Returns: record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float>
# operationId: testnet_getTokenMetadata
export def "testnet-get-token-metadata" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/testnet/ntp1/tokenmetadata/{tokenid}"
    path_params: [{name: tokenid, var: tokenid}]
    query: [{name: verbosity, var: verbosity}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tokenid: $tokenid, verbosity: $verbosity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get UTXO Metadata of Token
#
# GET /testnet/ntp1/tokenmetadata/{tokenid}/{utxo}
# Returns: record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float>
# operationId: testnet_getTokenMetadataOfUtxo
export def "testnet-get-token-metadata-of-utxo" [
  tokenid: string
  utxo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/testnet/ntp1/tokenmetadata/{tokenid}/{utxo}"
    path_params: [{name: tokenid, var: tokenid}, {name: utxo, var: utxo}]
    query: [{name: verbosity, var: verbosity}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    tokenid: $tokenid, utxo: $utxo, verbosity: $verbosity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information On an NTP1 Transaction
#
# GET /testnet/ntp1/transactioninfo/{txid}
# Returns: record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, hex: string, locktime: float, time: float, totalsent: float, txid: string, version: float, vin: table<previousOutput: record, scriptSig: record, sequence: float, tokens: list, txid: string, value: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, tokens: list, used: bool, usedBlockheight: float, usedTxid: string, value: float>>
# operationId: testnet_getTransactionInfo
export def "testnet-get-transaction-info" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/testnet/ntp1/transactioninfo/{txid}"
    path_params: [{name: txid, var: txid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    txid: $txid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
