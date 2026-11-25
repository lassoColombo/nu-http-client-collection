# Auto-generated client for Open Build Service API v2.10.50
# Source: https://api.apis.guru/v2/specs/opensuse.org/obs/2.10.50/openapi.json
# Auth: --token flag or $env.OPEN_BUILD_SERVICE_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "OPEN_BUILD_SERVICE_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def cmd-completer [] { ["abortbuild" "killbuild" "rebuild" "restartbuild" "sendsysrq" "unpublish" "wipe"] }
def view-completer [] { ["binarylist" "status" "summary"] }
def view-completer-1 [] { ["order" "pkgnames" "revpkgnames"] }
def cmd-completer-1 [] { ["add_user" "remove_user" "set_email"] }
def cmd-completer-2 [] { ["register"] }
def cmd-completer-3 [] { ["change_password" "delete" "lock"] }
def operation-completer [] { ["rebuild" "release" "runservice"] }
def accept-completer [] { ["application/*" "text/xml"] }
def view-completer-2 [] { ["status"] }
def cmd-completer-4 [] { ["create"] }
def addrevision-completer [] { ["1"] }
def ignore-delegate-completer [] { ["1"] }
def ignore-build-state-completer [] { ["1"] }
def view-completer-3 [] { ["xml"] }
def withissues-completer [] { ["1" "true"] }
def accept-completer-1 [] { ["application/xml; charset=utf-8" "text/plain; charset=utf-8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-build-project-repository-architecture-package-file: "binary"
    get-published-project-name-repository-name-architecture-name-binary-filename: "binary"
    post-request-id-cmd-diff: "string"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-about" "get-architectures" "get-architectures-architecture-name" "get-attribute" "delete-attribute-namespace" "get-attribute-namespace" "delete-attribute-namespace-meta" "get-attribute-namespace-meta" "post-attribute-namespace-meta" "put-attribute-namespace-meta" "delete-attribute-namespace-attribute-name" "delete-attribute-namespace-attribute-name-meta" "get-attribute-namespace-attribute-name-meta" "post-attribute-namespace-attribute-name-meta" "put-attribute-namespace-attribute-name-meta" "get-build" "get-build-project-name" "post-build-project-name" "get-build-project-name-result" "get-build-project-name-repository-name" "get-build-project-name-repository-name-buildconfig" "get-build-project-name-repository-name-architecture-name-builddepinfo" "get-build-project-name-repository-name-architecture-name-repository" "get-build-project-name-repository-name-architecture-name-package-name" "get-build-project-repository-arch-package-buildinfo" "get-build-project-repository-arch-package-history" "get-build-project-name-repository-name-architecture-name-package-name-jobstatus" "get-build-project-repository-arch-package-log" "get-build-project-name-repository-name-architecture-name-package-name-reason" "get-build-project-repository-arch-package-status" "get-build-project-repository-architecture-package-file" "put-build-project-repository-architecture-package-file" "get-build-project-repository-architecture-package-file-view-fileinfo" "get-configuration" "put-configuration" "get-distributions" "post-distributions" "put-distributions-bulk-replace" "get-distributions-include-remotes" "delete-distributions-distribution-id" "get-distributions-distribution-id" "put-distributions-distribution-id" "get-group" "delete-group-group-title" "get-group-group-title" "post-group-group-title" "put-group-group-title" "get-issue-trackers" "post-issue-trackers" "delete-issue-trackers-issue-tracker-name" "get-issue-trackers-issue-tracker-name" "put-issue-trackers-issue-tracker-name" "get-issue-trackers-issue-tracker-name-issues-issue-name" "get-person" "post-person" "post-person-register" "get-person-login" "post-person-login" "put-person-login" "get-person-login-group" "get-person-login-token" "post-person-login-token" "delete-person-login-token-id" "get-published" "get-published-project-name" "get-published-project-name-repository-name" "get-published-project-name-repository-name-architecture-name" "get-published-project-name-repository-name-architecture-name-binary-filename" "get-published-project-name-repository-name-architecture-name-binary-filename-view-ymp" "get-published-project-name-repository-name-view-status" "get-request" "post-request" "delete-request-id" "get-request-id" "post-request-id" "put-request-id" "post-request-id-cmd-diff" "get-request-view-collection" "get-worker-status" "get-worker-architecture-name-worker-id" "post-worker-cmd-checkconstraints" "commands"] | sort) } | get name | first)
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

# Get information about API.
#
# GET /about
export def "get-about" [
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
    path: "/about"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all known architectures.
#
# GET /architectures
export def "get-architectures" [
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
    path: "/architectures"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show one architecture.
#
# GET /architectures/{architecture_name}
export def "get-architectures-architecture-name" [
  architecture_name: string
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
    path: "/architectures/{architecture_name}"
    path_params: [{name: architecture_name, var: architecture_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    architecture_name: $architecture_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all attribute namespaces.
#
# GET /attribute
export def "get-attribute" [
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
    path: "/attribute"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an attribute namespace and all attributes below.
#
# DELETE /attribute/{namespace}
export def "delete-attribute-namespace" [
  namespace: string
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
    path: "/attribute/{namespace}"
    path_params: [{name: namespace, var: namespace}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all attributes below a namespace.
#
# GET /attribute/{namespace}
export def "get-attribute-namespace" [
  namespace: string
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
    path: "/attribute/{namespace}"
    path_params: [{name: namespace, var: namespace}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an attribute namespace and all attributes below.
#
# DELETE /attribute/{namespace}/_meta
export def "delete-attribute-namespace-meta" [
  namespace: string
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
    path: "/attribute/{namespace}/_meta"
    path_params: [{name: namespace, var: namespace}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show attribute namespace.
#
# GET /attribute/{namespace}/_meta
export def "get-attribute-namespace-meta" [
  namespace: string
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
    path: "/attribute/{namespace}/_meta"
    path_params: [{name: namespace, var: namespace}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change attribute namespace. Create an attribute namespace if it doesn't exist.
#
# POST /attribute/{namespace}/_meta
export def "post-attribute-namespace-meta" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/attribute/{namespace}/_meta"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change attribute namespace. Create an attribute namespace if it doesn't exist.
#
# PUT /attribute/{namespace}/_meta
export def "put-attribute-namespace-meta" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/attribute/{namespace}/_meta"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an attribute and all its values in projects or packages.
#
# DELETE /attribute/{namespace}/{attribute_name}
export def "delete-attribute-namespace-attribute-name" [
  namespace: string
  attribute_name: string
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
    path: "/attribute/{namespace}/{attribute_name}"
    path_params: [{name: namespace, var: namespace}, {name: attribute_name, var: attribute_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace, attribute_name: $attribute_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an attribute and all its values in projects or packages.
#
# DELETE /attribute/{namespace}/{attribute_name}/_meta
export def "delete-attribute-namespace-attribute-name-meta" [
  namespace: string
  attribute_name: string
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
    path: "/attribute/{namespace}/{attribute_name}/_meta"
    path_params: [{name: namespace, var: namespace}, {name: attribute_name, var: attribute_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace, attribute_name: $attribute_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shows attribute.
#
# GET /attribute/{namespace}/{attribute_name}/_meta
export def "get-attribute-namespace-attribute-name-meta" [
  namespace: string
  attribute_name: string
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
    path: "/attribute/{namespace}/{attribute_name}/_meta"
    path_params: [{name: namespace, var: namespace}, {name: attribute_name, var: attribute_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace, attribute_name: $attribute_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change attribute data. Create an attribute if it doesn't exist.
#
# POST /attribute/{namespace}/{attribute_name}/_meta
export def "post-attribute-namespace-attribute-name-meta" [
  namespace: string
  attribute_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/attribute/{namespace}/{attribute_name}/_meta"
    path_params: [{name: namespace, var: namespace}, {name: attribute_name, var: attribute_name}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace, attribute_name: $attribute_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change attribute data. Create an attribute if it doesn't exist.
#
# PUT /attribute/{namespace}/{attribute_name}/_meta
export def "put-attribute-namespace-attribute-name-meta" [
  namespace: string
  attribute_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/attribute/{namespace}/{attribute_name}/_meta"
    path_params: [{name: namespace, var: namespace}, {name: attribute_name, var: attribute_name}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    namespace: $namespace, attribute_name: $attribute_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a simple directory listing of all projects
#
# GET /build
export def "get-build" [
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
    path: "/build"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a simple directory listing of all repositories for the specified project
#
# GET /build/{project_name}
export def "get-build-project-name" [
  project_name: string
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
    path: "/build/{project_name}"
    path_params: [{name: project_name, var: project_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply different actions on builds/build processes of the specified project
#
# POST /build/{project_name}
export def "post-build-project-name" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package: string # Name of the package. Scope the commands to the specified package. (e.g. firefox)
  --arch: string # Name of the build architecture. Scope the commands to the specified architectures. (e.g. x86_64)
  --repository: string # Name of the repository. Scope the commands to the specified repository. (e.g. openSUSE_Leap_15.2)
  --cmd: string@cmd-completer # **NOTE**: All commands described below, can be scoped to a package within the project by setting the `package` parameter. * `wipe`: Delete all binaries build by the project. * `restartbuild`: Restart all running build processes inside the project. * `rebuild`: Trigger a rebuild of all packages inside the project. * `abortbuild`: Abort all running build processes for the specified project, marking them as failed. * `killbuild`: Alias for `abortbuild`. * `unpublish`: Delete all published package binaries, for the specified project, from the download repository. * `sendsysrq`: Send a single sysrq character to the kernel of a running build. Character need to be specified through the `sysrq` parameter. Only a subset of debugging requests are supported (eg. 9, t or w). (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/build/{project_name}"
    path_params: [{name: project_name, var: project_name}]
    query: [{name: package, var: package}, {name: arch, var: arch}, {name: repository, var: repository}, {name: cmd, var: cmd, required: true}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, package: $package, arch: $arch, repository: $repository, cmd: $cmd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the build results for packages, architectures and repositories of the specified project.
#
# GET /build/{project_name}/_result
export def "get-build-project-name-result" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: string@view-completer # Specify which sections should be included in the result list. * `status`: Include detailed infos about the build status. **Default** * `summary`: Include the summary of the status values. * `binarylist`: Include a list of generated binary files.
  --package: string # Name of the package. Limit results to the specified package. (e.g. obs-server)
  --arch: string # Name of the build architecture. Limit results to the specified build architecture. (e.g. x86_64)
  --repository: string # Name of the repository. Limit results to the specified repository. (e.g. openSUSE_Leap_15.2)
  --lastbuild: oneof<nothing, bool> # Show the last build result (excludes current building job states). (e.g. 1)
  --locallink: oneof<nothing, bool> # Include build results from packages with project local links. (e.g. 1)
  --multibuild: oneof<nothing, bool> # Include build results from _multibuild definitions. (e.g. 1)
]: nothing -> any {
  http-request {
    method: get
    path: "/build/{project_name}/_result"
    path_params: [{name: project_name, var: project_name}]
    query: [{name: view, var: view}, {name: package, var: package}, {name: arch, var: arch}, {name: repository, var: repository}, {name: lastbuild, var: lastbuild}, {name: locallink, var: locallink}, {name: multibuild, var: multibuild}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, view: $view, package: $package, arch: $arch, repository: $repository, lastbuild: $lastbuild, locallink: $locallink, multibuild: $multibuild
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of all architectures the specified project builds against a given repository.
#
# GET /build/{project_name}/{repository_name}
export def "get-build-project-name-repository-name" [
  project_name: string
  repository_name: string
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
    path: "/build/{project_name}/{repository_name}"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the build configuration for the specified repository.
#
# GET /build/{project_name}/{repository_name}/_buildconfig
export def "get-build-project-name-repository-name-buildconfig" [
  project_name: string
  repository_name: string
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
    path: "/build/{project_name}/{repository_name}/_buildconfig"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}]
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the build dependencies of packages that are part of the project.
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/_builddepinfo
export def "get-build-project-name-repository-name-architecture-name-builddepinfo" [
  project_name: string
  repository_name: string
  architecture_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package: string # Name of the package. Limit results to the specified package. (e.g. obs-server)
  --view: string@view-completer-1 # * `pkgnames`: Show whole package dependencies, instead of individual binaries. * `revpkgnames`: Show which packages depend on the provided project/package for the given repository/architecture, and therefore a rebuild gets triggered on change. * `order`: Show packages ordered by dependencies.
]: nothing -> any {
  http-request {
    method: get
    path: "/build/{project_name}/{repository_name}/{architecture_name}/_builddepinfo"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}]
    query: [{name: package, var: package}, {name: view, var: view}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package: $package, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all binaries (produced by all packages of the given project).
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/_repository
export def "get-build-project-name-repository-name-architecture-name-repository" [
  project_name: string
  repository_name: string
  architecture_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/_repository"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List binaries built by the sources of the specified package.
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}
export def "get-build-project-name-repository-name-architecture-name-package-name" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This endpoint returns information about some specific artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_buildinfo
# operationId: getBuildProjectRepositoryArchPackageBuildinfo
export def "get-build-project-repository-arch-package-buildinfo" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_buildinfo"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This endpoint returns the build history for a specific artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_history
# operationId: getBuildProjectRepositoryArchPackageHistory
export def "get-build-project-repository-arch-package-history" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_history"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the build status of a currently running build job.
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_jobstatus
export def "get-build-project-name-repository-name-architecture-name-package-name-jobstatus" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_jobstatus"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This endpoint returns the last log file for a specific build artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_log
# operationId: getBuildProjectRepositoryArchPackageLog
export def "get-build-project-repository-arch-package-log" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_log"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}]
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the reason for the lastly triggered build.
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_reason
export def "get-build-project-name-repository-name-architecture-name-package-name-reason" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_reason"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This endpoint returns the building status for a specific artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_status
# operationId: getBuildProjectRepositoryArchPackageStatus
export def "get-build-project-repository-arch-package-status" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_status"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a specific artifact file contents
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}
# Returns: binary
# operationId: getBuildProjectRepositoryArchitecturePackageFile
export def "get-build-project-repository-architecture-package-file" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
  file_name: string
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
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}, {name: file_name, var: file_name}]
    accept: ["application/*"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific artifact file contents
#
# PUT /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}
# operationId: putBuildProjectRepositoryArchitecturePackageFile
export def "put-build-project-repository-architecture-package-file" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: list<string>
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name, encode: array}, {name: file_name, var: file_name}]
    body: {content_type: "plain/text", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name, file_name: $file_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This endpoint returns details about an specific artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}?view=fileinfo
# operationId: getBuildProjectRepositoryArchitecturePackageFileViewFileinfo
export def "get-build-project-repository-architecture-package-file-view-fileinfo" [
  project_name: string
  repository_name: string
  architecture_name: string
  package_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: list<string> # required
]: nothing -> any {
  http-request {
    method: get
    path: "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}"
    fixed_query: "view=fileinfo"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: package_name, var: package_name}, {name: file_name, var: file_name}]
    query: [{name: view, var: view, style: multi, required: true}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, package_name: $package_name, file_name: $file_name, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Display the configuration of this Open Build Service instance
#
# GET /configuration
export def "get-configuration" [
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
    path: "/configuration"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the configuration of this Open Build Service instance
#
# PUT /configuration
export def "put-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/configuration"
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all distributions.
#
# GET /distributions
export def "get-distributions" [
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
    path: "/distributions"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a distribution.
#
# POST /distributions
export def "post-distributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/distributions"
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk replace all distributions.
#
# PUT /distributions/bulk_replace
export def "put-distributions-bulk-replace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/distributions/bulk_replace"
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all distributions including remote.
#
# GET /distributions/include_remotes
export def "get-distributions-include-remotes" [
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
    path: "/distributions/include_remotes"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a distribution.
#
# DELETE /distributions/{distribution_id}
export def "delete-distributions-distribution-id" [
  distribution_id: int
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
    path: "/distributions/{distribution_id}"
    path_params: [{name: distribution_id, var: distribution_id}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    distribution_id: $distribution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show a distribution.
#
# GET /distributions/{distribution_id}
export def "get-distributions-distribution-id" [
  distribution_id: int
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
    path: "/distributions/{distribution_id}"
    path_params: [{name: distribution_id, var: distribution_id}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    distribution_id: $distribution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a distribution.
#
# PUT /distributions/{distribution_id}
export def "put-distributions-distribution-id" [
  distribution_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/distributions/{distribution_id}"
    path_params: [{name: distribution_id, var: distribution_id}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    distribution_id: $distribution_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available groups.
#
# GET /group
export def "get-group" [
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
    path: "/group"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a group.
#
# DELETE /group/{group_title}
export def "delete-group-group-title" [
  group_title: string
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
    path: "/group/{group_title}"
    path_params: [{name: group_title, var: group_title}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    group_title: $group_title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read group data.
#
# GET /group/{group_title}
export def "get-group-group-title" [
  group_title: string
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
    path: "/group/{group_title}"
    path_params: [{name: group_title, var: group_title}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    group_title: $group_title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify group data.
#
# POST /group/{group_title}
export def "post-group-group-title" [
  group_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer-1 # Command to be executed. It takes one of these available values: * `add_user`: add a user to a group. `userid` query parameter must be also used. * `remove_user`: remove a user from a group. `userid` query parameter must be also used. * `set_email`: set email adress of group. `email` query parameter must be also used.
  --userid: string # User login. Used with `cmd=add_user` or `cmd=remove_user`.
  --email: string # Group email. Used with `cmd=set_email`.
]: nothing -> any {
  http-request {
    method: post
    path: "/group/{group_title}"
    path_params: [{name: group_title, var: group_title}]
    query: [{name: cmd, var: cmd}, {name: userid, var: userid}, {name: email, var: email}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    group_title: $group_title, cmd: $cmd, userid: $userid, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Write group data.
#
# PUT /group/{group_title}
export def "put-group-group-title" [
  group_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/group/{group_title}"
    path_params: [{name: group_title, var: group_title}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    group_title: $group_title, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of issue trackers.
#
# GET /issue_trackers
export def "get-issue-trackers" [
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
    path: "/issue_trackers"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an issue tracker.
#
# POST /issue_trackers
export def "post-issue-trackers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/issue_trackers"
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an issue tracker.
#
# DELETE /issue_trackers/{issue_tracker_name}
export def "delete-issue-trackers-issue-tracker-name" [
  issue_tracker_name: string
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
    path: "/issue_trackers/{issue_tracker_name}"
    path_params: [{name: issue_tracker_name, var: issue_tracker_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    issue_tracker_name: $issue_tracker_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show an issue tracker.
#
# GET /issue_trackers/{issue_tracker_name}
export def "get-issue-trackers-issue-tracker-name" [
  issue_tracker_name: string
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
    path: "/issue_trackers/{issue_tracker_name}"
    path_params: [{name: issue_tracker_name, var: issue_tracker_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    issue_tracker_name: $issue_tracker_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update or create an issue tracker.
#
# PUT /issue_trackers/{issue_tracker_name}
export def "put-issue-trackers-issue-tracker-name" [
  issue_tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/issue_trackers/{issue_tracker_name}"
    path_params: [{name: issue_tracker_name, var: issue_tracker_name}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    issue_tracker_name: $issue_tracker_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show an issue of an issue tracker.
#
# GET /issue_trackers/{issue_tracker_name}/issues/{issue_name}
export def "get-issue-trackers-issue-tracker-name-issues-issue-name" [
  issue_tracker_name: string
  issue_name: string
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
    path: "/issue_trackers/{issue_tracker_name}/issues/{issue_name}"
    path_params: [{name: issue_tracker_name, var: issue_tracker_name}, {name: issue_name, var: issue_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    issue_tracker_name: $issue_tracker_name, issue_name: $issue_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all people.
#
# GET /person
export def "get-person" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string # A prefix to filter the people to look for (e.g. Adm)
]: nothing -> any {
  http-request {
    method: get
    path: "/person"
    query: [{name: prefix, var: prefix}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    prefix: $prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes a command on the person endpoint.
#
# POST /person
export def "post-person" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer-2 # The command to execute (required, e.g. register)
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/person"
    query: [{name: cmd, var: cmd, required: true, default: register}]
    body: {content_type: "application/xml", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    cmd: $cmd, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a new person
#
# POST /person/register
export def "post-person-register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/person/register"
    body: {content_type: "application/xml", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about a person
#
# GET /person/{login}
export def "get-person-login" [
  login: string
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
    path: "/person/{login}"
    path_params: [{name: login, var: login}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    login: $login
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform changes on a registered person
#
# POST /person/{login}
export def "post-person-login" [
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer-3 # The command to execute against the provided person. (required, e.g. change_password)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/person/{login}"
    path_params: [{name: login, var: login}]
    query: [{name: cmd, var: cmd, required: true}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    login: $login, cmd: $cmd, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update person
#
# PUT /person/{login}
export def "put-person-login" [
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/person/{login}"
    path_params: [{name: login, var: login}]
    body: {content_type: "application/xml", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    login: $login, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the groups of a person
#
# GET /person/{login}/group
export def "get-person-login-group" [
  login: string
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
    path: "/person/{login}/group"
    path_params: [{name: login, var: login}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    login: $login
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the authentication tokens of a person.
#
# GET /person/{login}/token
export def "get-person-login-token" [
  login: string
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
    path: "/person/{login}/token"
    path_params: [{name: login, var: login}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    login: $login
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new authentication token for a person.
#
# POST /person/{login}/token
export def "post-person-login-token" [
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: string # Project name. Should be provided, together with the package query parameter, to limit the token to a specific package. (e.g. home:hans)
  --package: string # Package name. Should be provided, together with the project query parameter, to limit the token to a specific package. (e.g. gchz)
  --operation: string@operation-completer # Operation indicates the kind of token that is going to be created. When operation is not specified, 'runservice' is the default value. (e.g. runservice)
  --scm-token: string # **(Beta/Unstable)** SCM token used in OBS workflows to report back the workflow status, when the operation is workflow. It's normally possible to generate SCM tokens directly on the SCM's website like GitHub or GitLab. (e.g. ghp_fake_token_123)
]: nothing -> any {
  http-request {
    method: post
    path: "/person/{login}/token"
    path_params: [{name: login, var: login}]
    query: [{name: project, var: project}, {name: package, var: package}, {name: operation, var: operation}, {name: scm_token, var: scm_token}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    login: $login, project: $project, package: $package, operation: $operation, scm_token: $scm_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a token of a person.
#
# DELETE /person/{login}/token/{id}
export def "delete-person-login-token-id" [
  login: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/person/{login}/token/{id}"
    path_params: [{name: login, var: login}, {name: id, var: id}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    login: $login, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the published projects.
#
# GET /published
export def "get-published" [
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
    path: "/published"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the repositories of a project with published binaries
#
# GET /published/{project_name}
export def "get-published-project-name" [
  project_name: string
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
    path: "/published/{project_name}"
    path_params: [{name: project_name, var: project_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the content of the directory tree where the binaries are published at the level project/repository.
#
# GET /published/{project_name}/{repository_name}
export def "get-published-project-name-repository-name" [
  project_name: string
  repository_name: string
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
    path: "/published/{project_name}/{repository_name}"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the content of the directory tree where the binaries are published at the level project/repository/architecture.
#
# GET /published/{project_name}/{repository_name}/{architecture_name}
export def "get-published-project-name-repository-name-architecture-name" [
  project_name: string
  repository_name: string
  architecture_name: string
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
    path: "/published/{project_name}/{repository_name}/{architecture_name}"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the binary file itself.
#
# GET /published/{project_name}/{repository_name}/{architecture_name}/{binary_filename}
# Returns: binary
export def "get-published-project-name-repository-name-architecture-name-binary-filename" [
  project_name: string
  repository_name: string
  architecture_name: string
  binary_filename: string
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
    method: get
    path: "/published/{project_name}/{repository_name}/{architecture_name}/{binary_filename}"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: binary_filename, var: binary_filename}]
    accept: ["application/*", "text/xml"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, binary_filename: $binary_filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generate a ymp pattern that includes the needed repositories to install the given binary.
#
# GET /published/{project_name}/{repository_name}/{architecture_name}/{binary_filename}?view=ymp
export def "get-published-project-name-repository-name-architecture-name-binary-filename-view-ymp" [
  project_name: string
  repository_name: string
  architecture_name: string
  binary_filename: string
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
    path: "/published/{project_name}/{repository_name}/{architecture_name}/{binary_filename}"
    fixed_query: "view=ymp"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}, {name: architecture_name, var: architecture_name}, {name: binary_filename, var: binary_filename}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, architecture_name: $architecture_name, binary_filename: $binary_filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Present information about the last publication of the pair project and repository.
#
# GET /published/{project_name}/{repository_name}?view=status
export def "get-published-project-name-repository-name-view-status" [
  project_name: string
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: string@view-completer-2 # Set this parameter to status in order to get details about the last publication. (e.g. status)
]: nothing -> any {
  http-request {
    method: get
    path: "/published/{project_name}/{repository_name}"
    fixed_query: "view=status"
    path_params: [{name: project_name, var: project_name}, {name: repository_name, var: repository_name}]
    query: [{name: view, var: view}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project_name: $project_name, repository_name: $repository_name, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a simple directory listing of all requests
#
# GET /request
export def "get-request" [
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
    path: "/request"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a request
#
# POST /request
export def "post-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer-4 # This endpoint will refuse the creation of a new request if this parameter is not set. (required)
  --addrevision: string@addrevision-completer # Ask the server to add revisions of the current sources to the request.
  --ignore-delegate: string@ignore-delegate-completer # Enforce a new package instance in a project which has OBS:DelegateRequestTarget set
  --ignore-build-state: string@ignore-build-state-completer # Skip the build state check
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/request"
    query: [{name: cmd, var: cmd, required: true, default: create}, {name: addrevision, var: addrevision}, {name: ignore_delegate, var: ignore_delegate}, {name: ignore_build_state, var: ignore_build_state}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    cmd: $cmd, addrevision: $addrevision, ignore_delegate: $ignore_delegate, ignore_build_state: $ignore_build_state, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a given request.
#
# DELETE /request/{id}
export def "delete-request-id" [
  id: int
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
    path: "/request/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show details about a specified request.
#
# GET /request/{id}
export def "get-request-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --withhistory: string # Include the request history in the results. (e.g. 1)
  --withfullhistory: string # Includes both, request and review history in the results. (e.g. 1)
]: nothing -> any {
  http-request {
    method: get
    path: "/request/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: withhistory, var: withhistory}, {name: withfullhistory, var: withfullhistory}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    id: $id, withhistory: $withhistory, withfullhistory: $withfullhistory
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply certain actions on a specified request.
#
# POST /request/{id}
export def "post-request-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string # - `addreview`: Add a review to a request. **NOTE:** You need to specify who has to address the review by providing an additional paramter. Possible options are: * by_user * by_group * by_project - `assignreview`: Accept a review for a given group and assign a new review to a specific user. **NOTE:** You need to pass the group name in the `by_group` parameter and the new reviewer in the `reviewer` parameter. - `changestate`: Modify the state of a given request. **NOTE:** You need to pass the new state throug the `newstate` parameter. Changing from one state to another is in certain cases not allowed. You can still force the operation by using the `force=1` parameter. - `changereviewstate`: Change the state of a review inside a given request. - `setpriority`: Change the priority of a given request. You have to pass the choosen priority through the `priority` parameter. Possible values are: * low * moderate * important * critical - `setincident`: Change the target incident for maintenance_incident actions **NOTE:** You need to provide the incident number through the `incident` parameter. - `setacceptat`: Set or modify the accept_at time. Either specified by the `time` parameter or by default set to now. - `approve`: Pre-approve a request in the review state. It will turn into state `accepted` after the last review. - `cancelapproval`: Reset the approval of a request
  --newstate: string # Define the new state
  --priority: string # Define the new priority
  --by-user: string # Specify the user of a new review
  --by-group: string # Specify the group of the new review
  --by-project: string # Specify the project of the new review
  --by-package: string # Specify the package of the new review
  --incident: string # Specify the incident number for `setincident`
  --time: string # Specify the time for `setacceptat`
  --comment: string # Add a comment to one of the actions
]: nothing -> any {
  http-request {
    method: post
    path: "/request/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: cmd, var: cmd}, {name: newstate, var: newstate}, {name: priority, var: priority}, {name: by_user, var: by_user}, {name: by_group, var: by_group}, {name: by_project, var: by_project}, {name: by_package, var: by_package}, {name: incident, var: incident}, {name: time, var: time}, {name: comment, var: comment}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    id: $id, cmd: $cmd, newstate: $newstate, priority: $priority, by_user: $by_user, by_group: $by_group, by_project: $by_project, by_package: $by_package, incident: $incident, time: $time, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a given request.
#
# PUT /request/{id}
export def "put-request-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/request/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the diff for all packages affected by the request.
#
# POST /request/{id}?cmd=diff
# Returns: string
export def "post-request-id-cmd-diff" [
  id: int
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
  --diff-to-superseded: string # Diff relative to a given superseded request. State the id of the corresponding superseded request. (e.g. 10401)
  --view: string@view-completer-3 # Set this parameter to xml in order to receive a structured diff instead of plain text.
  --withissues: string@withissues-completer # Include parsed issues
]: nothing -> any {
  http-request {
    method: post
    path: "/request/{id}"
    fixed_query: "cmd=diff"
    path_params: [{name: id, var: id}]
    query: [{name: diff_to_superseded, var: diff_to_superseded}, {name: view, var: view}, {name: withissues, var: withissues}]
    accept: ["application/xml; charset=utf-8", "text/plain; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    id: $id, diff_to_superseded: $diff_to_superseded, view: $view, withissues: $withissues
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a collection of requests for a specified target
#
# GET /request?view=collection
export def "get-request-view-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # Filter the results of requests and open reviews for a certain user. If no other parameters are applied, it will include requests where the user is maintainer of the target or the creator of the request. (e.g. hans)
  --project: string # Limit the results of requests and open review requests to the specified target project. (e.g. home:hans)
  --package: string # Limit the results of requests and open review requests to the specified target package. (e.g. ruby)
  --states: string # Limit results to a given request state. Multiple states can be provided as a comma separated list. (e.g. new,review)
  --types: string # Limit the results to certain action types. Multiple types can be provided as a comma separated list. (e.g. add_role,submit)
  --roles: string # Limit the results to a given role. Multiple roles can be provided as a comma separated list. (e.g. creator,maintainer,reviewer,source,target)
  --withhistory: string # Include the request history in the results. (e.g. 1)
  --withfullhistory: string # Includes both, request and review history in the results. (e.g. 1)
  --limit: int # Limit the results to the specified amount of requests. (e.g. 7)
  --ids: string # Limit the result to specified request id's. Multiple id's can be provided as a comma separated list. (e.g. 15,19,23)
]: nothing -> any {
  http-request {
    method: get
    path: "/request"
    fixed_query: "view=collection"
    query: [{name: user, var: user}, {name: project, var: project}, {name: package, var: package}, {name: states, var: states}, {name: types, var: types}, {name: roles, var: roles}, {name: withhistory, var: withhistory}, {name: withfullhistory, var: withfullhistory}, {name: limit, var: limit}, {name: ids, var: ids}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    user: $user, project: $project, package: $package, states: $states, types: $types, roles: $roles, withhistory: $withhistory, withfullhistory: $withfullhistory, limit: $limit, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists status of workers, jobs, backend services and general statistics.
#
# GET /worker/status
export def "get-worker-status" [
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
    path: "/worker/status"
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists capabilites of a worker.
#
# GET /worker/{architecture_name}:{worker_id}
export def "get-worker-architecture-name-worker-id" [
  architecture_name: string
  worker_id: string
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
    path: "/worker/{architecture_name}:{worker_id}"
    path_params: [{name: architecture_name, var: architecture_name}, {name: worker_id, var: worker_id}]
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    architecture_name: $architecture_name, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists workers which match a constraints filter.
#
# POST /worker?cmd=checkconstraints
export def "post-worker-cmd-checkconstraints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: string # Project name. (required, e.g. home:user1)
  --repository: string # Repository name. (required, e.g. openSUSE_Tumbleweed)
  --arch: string # Architecture name. (required, e.g. x86_64)
  --package: string # Package name. (required, e.g. test_package)
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/worker"
    fixed_query: "cmd=checkconstraints"
    query: [{name: project, var: project, required: true}, {name: repository, var: repository, required: true}, {name: arch, var: arch, required: true}, {name: package, var: package, required: true}]
    body: {content_type: "application/xml; charset=utf-8", kind: opaque, accepts: scalar}
    accept: ["application/xml; charset=utf-8"]
    ok: [200]
    auth: basic
  } {
    project: $project, repository: $repository, arch: $arch, package: $package, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
