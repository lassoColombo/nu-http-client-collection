# Auto-generated client for Files.com API v0.0.1
# Source: https://api.apis.guru/v2/specs/files.com/0.0.1/openapi.json
# Auth: --token flag or $env.FILES_COM_API_TOKEN

const CLIENT = {
  base_url: "http://localhost//app.files.com/api/rest/v1"
  token_env_var: "FILES_COM_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-filesapi-key, in: header, header_name: X-FilesAPI-Key, prefix: ""}
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

def base-url-completer [] { ["http://localhost//app.files.com/api/rest/v1"] }
def auth-scheme-completer [] { ["x-filesapi-key"] }

# Completers for enum parameters
def permission-set-completer [] { ["desktop_app" "full" "mobile_app" "none" "office_integration" "sync_app"] }
def automation-completer [] { ["as2_send" "copy_file" "copy_newest_file" "create_folder" "delete_file" "move_file" "request_file" "request_move" "run_sync"] }
def trigger-completer [] { ["action" "custom_schedule" "daily" "email" "realtime" "webhook"] }
def permissions-completer [] { ["full" "none" "preview_only" "read" "read_write" "write"] }
def use-with-bundles-completer [] { ["available" "none" "require"] }
def use-with-inboxes-completer [] { ["available" "none" "require"] }
def use-with-users-completer [] { ["none" "require"] }
def status-completer [] { ["failure" "in_progress" "partial_failure" "skipped" "success"] }
def authentication-method-completer [] { ["email_signup" "none" "password" "password_with_imported_hash" "sso" "unused_former_ldap"] }
def require-2fa-completer [] { ["always_require" "never_require" "use_system_setting"] }
def ssl-required-completer [] { ["always_require" "never_require" "use_system_setting"] }
def files-agent-permission-set-completer [] { ["read_only" "read_write" "write_only"] }
def one-drive-account-type-completer [] { ["business_other" "personal"] }
def server-certificate-completer [] { ["allow_any" "require_match"] }
def server-type-completer [] { ["azure" "azure_files" "backblaze_b2" "box" "dropbox" "filebase" "files_agent" "ftp" "google_cloud_storage" "google_drive" "one_drive" "rackspace" "s3" "s3_compatible" "sftp" "sharepoint" "wasabi" "webdav"] }
def ssl-completer [] { ["if_available" "never" "require" "require_implicit"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-action-notification-export-results: "table<created_at: int, folder: string, id: int, message: string, path: string, request_headers: string, request_method: string, request_url: string, status: int, success: bool>"
    post-action-notification-exports: "record<end_at: string, export_version: string, id: int, query_folder: string, query_message: string, query_path: string, query_request_method: string, query_request_url: string, query_status: string, query_success: bool, results_url: string, start_at: string, status: string>"
    get-action-notification-exports-id: "record<end_at: string, export_version: string, id: int, query_folder: string, query_message: string, query_path: string, query_request_method: string, query_request_url: string, query_status: string, query_success: bool, results_url: string, start_at: string, status: string>"
    api-key-find-current: "record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    api-key-update-current: "record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    get-api-keys: "table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    post-api-keys: "record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    get-api-keys-id: "record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    patch-api-keys-id: "record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    get-apps: "table<app_type: string, documentation_links: record, extended_description: string, external_homepage_url: string, featured: bool, folder_behavior_type: string, icon_url: string, logo_thumbnail_url: string, logo_url: string, marketing_youtube_url: string, name: string, remote_server_type: string, screenshot_list_urls: list<string>, short_description: string, sso_strategy_type: string, tutorial_youtube_url: string>"
    get-as2-incoming-messages: "table<activity_log: string, as2_from: string, as2_partner_id: int, as2_station_id: int, as2_to: string, attachment_filename: string, body_size: string, content_type: string, created_at: string, date: string, encrypted_uri: string, hex_recipient_serial: string, http_headers: record, http_response_code: string, http_response_headers: record, id: int, ip: string, mdn_response_uri: string, message_decrypted: bool, message_id: string, message_mdn_returned: bool, message_processing_success: bool, message_received: bool, message_signature_verified: bool, mic: string, mic_algo: string, processing_result: string, processing_result_description: string, raw_uri: string, recipient_issuer: string, recipient_serial: string, smime_signed_uri: string, smime_uri: string, subject: string, uuid: string>"
    get-as2-outgoing-messages: "table<activity_log: string, as2_from: string, as2_partner_id: int, as2_station_id: int, as2_to: string, attachment_filename: string, body_size: string, created_at: string, date: string, encrypted_uri: string, http_headers: record, http_response_code: string, http_response_headers: record, http_transmission_duration: float, id: int, mdn_message_id_matched: bool, mdn_mic_matched: bool, mdn_processing_success: bool, mdn_received: bool, mdn_response_uri: string, mdn_signature_verified: bool, mdn_valid: bool, message_id: string, mic: string, mic_sha_256: string, processing_result: string, processing_result_description: string, raw_uri: string, smime_signed_uri: string, smime_uri: string, uuid: string>"
    get-as2-partners: "table<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string>"
    post-as2-partners: "record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string>"
    get-as2-partners-id: "record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string>"
    patch-as2-partners-id: "record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string>"
    get-as2-stations: "table<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string>"
    post-as2-stations: "record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string>"
    get-as2-stations-id: "record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string>"
    patch-as2-stations-id: "record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string>"
    get-automation-runs: "table<automation_id: int, completed_at: string, created_at: string, id: int, status: string, status_messages_url: string>"
    get-automation-runs-id: "record<automation_id: int, completed_at: string, created_at: string, id: int, status: string, status_messages_url: string>"
    get-automations: "table<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string>"
    post-automations: "record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string>"
    get-automations-id: "record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string>"
    patch-automations-id: "record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string>"
    get-bandwidth-snapshots: "table<bytes_received: float, bytes_sent: float, id: int, logged_at: string, requests_get: float, requests_other: float, requests_put: float, sync_bytes_received: float, sync_bytes_sent: float>"
    get-behaviors: "table<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>"
    post-behaviors: "record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>"
    behavior-list-for-path: "table<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>"
    post-behaviors-webhook-test: "record<clickwrap_body: string, clickwrap_id: int, code: int, data: record<dynamic: record>, errors: table<fields: list, messages: list>, message: string, status: string>"
    get-behaviors-id: "record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>"
    patch-behaviors-id: "record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>"
    get-bundle-downloads: "table<bundle_registration: record<bundle_code: string, bundle_id: int, bundle_recipient_id: int, clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_code: string, ip: string, name: string>, created_at: string, download_method: string, path: string>"
    get-bundle-notifications: "table<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int>"
    post-bundle-notifications: "record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int>"
    get-bundle-notifications-id: "record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int>"
    patch-bundle-notifications-id: "record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int>"
    get-bundle-recipients: "table<company: string, name: string, note: string, recipient: string, sent_at: string>"
    post-bundle-recipients: "record<company: string, name: string, note: string, recipient: string, sent_at: string>"
    get-bundle-registrations: "table<bundle_code: string, bundle_id: int, bundle_recipient_id: int, clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_code: string, ip: string, name: string>"
    get-bundles: "table<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list, form_layout: list, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record>"
    post-bundles: "record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record>"
    get-bundles-id: "record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record>"
    patch-bundles-id: "record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record>"
    get-clickwraps: "table<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string>"
    post-clickwraps: "record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string>"
    get-clickwraps-id: "record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string>"
    patch-clickwraps-id: "record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string>"
    get-dns-records: "table<domain: string, id: string, rrtype: string, value: string>"
    get-external-events: "table<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int>"
    post-external-events: "record<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int>"
    get-external-events-id: "record<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int>"
    file-action-begin-upload: "table<action: string, ask_about_overwrites: bool, available_parts: int, expires: string, headers: record, http_method: string, next_partsize: int, parallel_parts: bool, parameters: record, part_number: int, partsize: int, path: string, ref: string, send: record, upload_uri: string>"
    file-action-copy: "record<file_migration_id: int, status: string>"
    file-action-find: "record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, \"subfolders_locked?\": bool, type: string>"
    file-action-move: "record<file_migration_id: int, status: string>"
    post-file-comment-reactions: "record<emoji: string, id: int>"
    post-file-comments: "record<body: string, id: int, reactions: table<emoji: string, id: int>>"
    file-comment-list-for-path: "table<body: string, id: int, reactions: list<record>>"
    patch-file-comments-id: "record<body: string, id: int, reactions: table<emoji: string, id: int>>"
    get-file-migrations-id: "record<dest_path: string, files_moved: int, files_total: int, id: int, log_url: string, operation: string, path: string, region: string, status: string>"
    file-download: "record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, \"subfolders_locked?\": bool, type: string>"
    patch-files-path: "record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, \"subfolders_locked?\": bool, type: string>"
    post-files-path: "record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, \"subfolders_locked?\": bool, type: string>"
    folder-list-for-path: "table<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, \"subfolders_locked?\": bool, type: string>"
    post-folders-path: "record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, \"subfolders_locked?\": bool, type: string>"
    get-form-field-sets: "table<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>"
    post-form-field-sets: "record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>"
    get-form-field-sets-id: "record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>"
    patch-form-field-sets-id: "record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>"
    get-group-users: "table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>"
    post-group-users: "record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>"
    patch-group-users-id: "record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>"
    get-groups: "table<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string>"
    post-groups: "record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string>"
    patch-groups-group-id-memberships-user-id: "record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>"
    get-groups-group-id-permissions: "table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string>"
    get-groups-group-id-users: "table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>"
    post-groups-group-id-users: "record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>"
    get-groups-id: "record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string>"
    patch-groups-id: "record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string>"
    history-list: "table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>"
    history-list-for-file: "table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>"
    history-list-for-folder: "table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>"
    history-list-logins: "table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>"
    history-list-for-user: "table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>"
    get-history-export-results: "table<action: string, created_at: int, created_at_iso8601: int, destination: string, failure_type: string, file_id: int, folder: string, id: int, interface: string, ip: string, parent_id: int, path: string, src: string, target_expires_at: int, target_id: int, target_name: string, target_permission: string, target_permission_set: string, target_platform: string, target_recursive: bool, target_user_id: int, target_username: string, user_id: int, username: string>"
    post-history-exports: "record<end_at: string, history_version: string, id: int, query_action: string, query_destination: string, query_failure_type: string, query_file_id: string, query_folder: string, query_interface: string, query_ip: string, query_parent_id: string, query_path: string, query_src: string, query_target_id: string, query_target_name: string, query_target_permission: string, query_target_permission_set: string, query_target_platform: string, query_target_user_id: string, query_target_username: string, query_user_id: string, query_username: string, results_url: string, start_at: string, status: string>"
    get-history-exports-id: "record<end_at: string, history_version: string, id: int, query_action: string, query_destination: string, query_failure_type: string, query_file_id: string, query_folder: string, query_interface: string, query_ip: string, query_parent_id: string, query_path: string, query_src: string, query_target_id: string, query_target_name: string, query_target_permission: string, query_target_permission_set: string, query_target_platform: string, query_target_user_id: string, query_target_username: string, query_user_id: string, query_username: string, results_url: string, start_at: string, status: string>"
    get-inbox-recipients: "table<company: string, name: string, note: string, recipient: string, sent_at: string>"
    post-inbox-recipients: "record<company: string, name: string, note: string, recipient: string, sent_at: string>"
    get-inbox-registrations: "table<clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_id: int, inbox_recipient_id: int, inbox_title: string, name: string>"
    get-inbox-uploads: "table<created_at: string, inbox_registration: record<clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_id: int, inbox_recipient_id: int, inbox_title: string, name: string>, path: string>"
    get-invoices: "table<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: list<record>, method: string, payment_line_items: list<record>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string>"
    get-invoices-id: "record<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: table<amount: float, created_at: string, description: string, plan: string, service_end_at: string, service_start_at: string, site: string, type: string, updated_at: string>, method: string, payment_line_items: table<amount: float, created_at: string, invoice_id: int, payment_id: int>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string>"
    get-ip-addresses: "table<associated_with: string, group_id: int, id: string, ip_addresses: list<string>>"
    get-ip-addresses-exavault-reserved: "table<ftp_enabled: bool, ip_address: string, server_name: string, sftp_enabled: bool>"
    get-ip-addresses-reserved: "table<ftp_enabled: bool, ip_address: string, server_name: string, sftp_enabled: bool>"
    lock-list-for-path: "table<allow_access_by_any_user: bool, depth: string, exclusive: bool, owner: string, path: string, recursive: bool, scope: string, timeout: int, token: string, type: string, user_id: int, username: string>"
    post-locks-path: "record<allow_access_by_any_user: bool, depth: string, exclusive: bool, owner: string, path: string, recursive: bool, scope: string, timeout: int, token: string, type: string, user_id: int, username: string>"
    get-message-comment-reactions: "table<emoji: string, id: int>"
    post-message-comment-reactions: "record<emoji: string, id: int>"
    get-message-comment-reactions-id: "record<emoji: string, id: int>"
    get-message-comments: "table<body: string, id: int, reactions: list<record>>"
    post-message-comments: "record<body: string, id: int, reactions: table<emoji: string, id: int>>"
    get-message-comments-id: "record<body: string, id: int, reactions: table<emoji: string, id: int>>"
    patch-message-comments-id: "record<body: string, id: int, reactions: table<emoji: string, id: int>>"
    get-message-reactions: "table<emoji: string, id: int>"
    post-message-reactions: "record<emoji: string, id: int>"
    get-message-reactions-id: "record<emoji: string, id: int>"
    get-messages: "table<body: string, comments: list<record>, id: int, subject: string>"
    post-messages: "record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string>"
    get-messages-id: "record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string>"
    patch-messages-id: "record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string>"
    get-notifications: "table<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string>"
    post-notifications: "record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string>"
    get-notifications-id: "record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string>"
    patch-notifications-id: "record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string>"
    get-payments: "table<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: list<record>, method: string, payment_line_items: list<record>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string>"
    get-payments-id: "record<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: table<amount: float, created_at: string, description: string, plan: string, service_end_at: string, service_start_at: string, site: string, type: string, updated_at: string>, method: string, payment_line_items: table<amount: float, created_at: string, invoice_id: int, payment_id: int>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string>"
    get-permissions: "table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string>"
    post-permissions: "record<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string>"
    get-priorities: "table<color: string, path: string>"
    get-projects: "table<global_access: string, id: int>"
    post-projects: "record<global_access: string, id: int>"
    get-projects-id: "record<global_access: string, id: int>"
    patch-projects-id: "record<global_access: string, id: int>"
    get-public-keys: "table<created_at: string, fingerprint: string, id: int, title: string>"
    post-public-keys: "record<created_at: string, fingerprint: string, id: int, title: string>"
    get-public-keys-id: "record<created_at: string, fingerprint: string, id: int, title: string>"
    patch-public-keys-id: "record<created_at: string, fingerprint: string, id: int, title: string>"
    get-remote-bandwidth-snapshots: "table<id: int, logged_at: string, remote_server_id: int, sync_bytes_received: float, sync_bytes_sent: float>"
    get-remote-servers: "table<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string>"
    post-remote-servers: "record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string>"
    get-remote-servers-id: "record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string>"
    patch-remote-servers-id: "record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string>"
    get-remote-servers-id-configuration-file: "record<api_token: string, config_version: string, hostname: string, id: int, permission_set: string, port: int, private_key: string, public_key: string, root: string, server_host_key: string, status: string, subdomain: string>"
    post-remote-servers-id-configuration-file: "record<api_token: string, config_version: string, hostname: string, id: int, permission_set: string, port: int, private_key: string, public_key: string, root: string, server_host_key: string, status: string, subdomain: string>"
    get-requests: "table<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string>"
    post-requests: "record<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string>"
    get-requests-folders-path: "table<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string>"
    post-sessions: "record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool>"
    get-settings-changes: "table<changes: list<string>, created_at: string, user_id: int, user_is_files_support: bool, username: string>"
    get-sftp-host-keys: "table<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string>"
    post-sftp-host-keys: "record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string>"
    get-sftp-host-keys-id: "record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string>"
    patch-sftp-host-keys-id: "record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string>"
    get-site: "record<active_sftp_host_key_id: int, admin_user_id: int, allow_bundle_names: bool, allowed_2fa_method_bypass_for_ftp_sftp_dav: bool, allowed_2fa_method_sms: bool, allowed_2fa_method_totp: bool, allowed_2fa_method_u2f: bool, allowed_2fa_method_webauthn: bool, allowed_2fa_method_yubi: bool, allowed_countries: string, allowed_ips: string, ask_about_overwrites: bool, bundle_activity_notifications: string, bundle_expiration: int, bundle_password_required: bool, bundle_registration_notifications: string, bundle_require_share_recipient: bool, bundle_upload_receipt_notifications: string, bundle_watermark_attachment: record<name: string, uri: string>, bundle_watermark_value: record, color2_left: string, color2_link: string, color2_text: string, color2_top: string, color2_top_text: string, contact_name: string, created_at: string, currency: string, custom_namespace: bool, days_to_retain_backups: int, default_time_zone: string, desktop_app: bool, desktop_app_session_ip_pinning: bool, desktop_app_session_lifetime: int, disable_files_certificate_generation: bool, disable_notifications: bool, disable_password_reset: bool, disable_users_from_inactivity_period_days: int, disallowed_countries: string, domain: string, domain_hsts_header: bool, domain_letsencrypt_chain: string, email: string, folder_permissions_groups_only: bool, ftp_enabled: bool, hipaa: bool, icon128: record<name: string, uri: string>, icon16: record<name: string, uri: string>, icon32: record<name: string, uri: string>, icon48: record<name: string, uri: string>, immutable_files_set_at: string, include_password_in_welcome_email: bool, language: string, ldap_base_dn: string, ldap_domain: string, ldap_enabled: bool, ldap_group_action: string, ldap_group_exclusion: string, ldap_group_inclusion: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_type: string, ldap_user_action: string, ldap_user_include_groups: string, ldap_username: string, ldap_username_field: string, login_help_text: string, logo: record<name: string, uri: string>, max_prior_passwords: int, mobile_app: bool, mobile_app_session_ip_pinning: bool, mobile_app_session_lifetime: int, motd_text: string, motd_use_for_ftp: bool, motd_use_for_sftp: bool, name: string, next_billing_amount: float, next_billing_date: string, non_sso_groups_allowed: bool, non_sso_users_allowed: bool, office_integration_available: bool, office_integration_type: string, oncehub_link: string, opt_out_global: bool, overage_notified_at: string, overage_notify: bool, overdue: bool, password_min_length: int, password_require_letter: bool, password_require_mixed: bool, password_require_number: bool, password_require_special: bool, password_require_unbreached: bool, password_requirements_apply_to_bundles: bool, password_validity_days: int, phone: string, pin_all_remote_servers_to_site_region: bool, reply_to_email: string, require_2fa: bool, require_2fa_stop_time: string, require_2fa_user_type: string, session: record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool>, session_expiry: float, session_expiry_minutes: int, session_pinned_by_ip: bool, sftp_enabled: bool, sftp_host_key_type: string, sftp_insecure_ciphers: bool, sftp_user_root_enabled: bool, sharing_enabled: bool, show_request_access_link: bool, site_footer: string, site_header: string, smtp_address: string, smtp_authentication: string, smtp_from: string, smtp_port: int, smtp_username: string, ssl_required: bool, subdomain: string, switch_to_plan_date: string, tls_disabled: bool, trial_days_left: int, trial_until: string, updated_at: string, uploads_via_email_authentication: bool, use_provided_modified_at: bool, user: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>, user_lockout: bool, user_lockout_lock_period: int, user_lockout_tries: int, user_lockout_within: int, user_requests_enabled: bool, user_requests_notify_admins: bool, welcome_custom_text: string, welcome_email_cc: string, welcome_email_enabled: bool, welcome_email_subject: string, welcome_screen: string, windows_mode_ftp: bool>"
    patch-site: "record<active_sftp_host_key_id: int, admin_user_id: int, allow_bundle_names: bool, allowed_2fa_method_bypass_for_ftp_sftp_dav: bool, allowed_2fa_method_sms: bool, allowed_2fa_method_totp: bool, allowed_2fa_method_u2f: bool, allowed_2fa_method_webauthn: bool, allowed_2fa_method_yubi: bool, allowed_countries: string, allowed_ips: string, ask_about_overwrites: bool, bundle_activity_notifications: string, bundle_expiration: int, bundle_password_required: bool, bundle_registration_notifications: string, bundle_require_share_recipient: bool, bundle_upload_receipt_notifications: string, bundle_watermark_attachment: record<name: string, uri: string>, bundle_watermark_value: record, color2_left: string, color2_link: string, color2_text: string, color2_top: string, color2_top_text: string, contact_name: string, created_at: string, currency: string, custom_namespace: bool, days_to_retain_backups: int, default_time_zone: string, desktop_app: bool, desktop_app_session_ip_pinning: bool, desktop_app_session_lifetime: int, disable_files_certificate_generation: bool, disable_notifications: bool, disable_password_reset: bool, disable_users_from_inactivity_period_days: int, disallowed_countries: string, domain: string, domain_hsts_header: bool, domain_letsencrypt_chain: string, email: string, folder_permissions_groups_only: bool, ftp_enabled: bool, hipaa: bool, icon128: record<name: string, uri: string>, icon16: record<name: string, uri: string>, icon32: record<name: string, uri: string>, icon48: record<name: string, uri: string>, immutable_files_set_at: string, include_password_in_welcome_email: bool, language: string, ldap_base_dn: string, ldap_domain: string, ldap_enabled: bool, ldap_group_action: string, ldap_group_exclusion: string, ldap_group_inclusion: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_type: string, ldap_user_action: string, ldap_user_include_groups: string, ldap_username: string, ldap_username_field: string, login_help_text: string, logo: record<name: string, uri: string>, max_prior_passwords: int, mobile_app: bool, mobile_app_session_ip_pinning: bool, mobile_app_session_lifetime: int, motd_text: string, motd_use_for_ftp: bool, motd_use_for_sftp: bool, name: string, next_billing_amount: float, next_billing_date: string, non_sso_groups_allowed: bool, non_sso_users_allowed: bool, office_integration_available: bool, office_integration_type: string, oncehub_link: string, opt_out_global: bool, overage_notified_at: string, overage_notify: bool, overdue: bool, password_min_length: int, password_require_letter: bool, password_require_mixed: bool, password_require_number: bool, password_require_special: bool, password_require_unbreached: bool, password_requirements_apply_to_bundles: bool, password_validity_days: int, phone: string, pin_all_remote_servers_to_site_region: bool, reply_to_email: string, require_2fa: bool, require_2fa_stop_time: string, require_2fa_user_type: string, session: record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool>, session_expiry: float, session_expiry_minutes: int, session_pinned_by_ip: bool, sftp_enabled: bool, sftp_host_key_type: string, sftp_insecure_ciphers: bool, sftp_user_root_enabled: bool, sharing_enabled: bool, show_request_access_link: bool, site_footer: string, site_header: string, smtp_address: string, smtp_authentication: string, smtp_from: string, smtp_port: int, smtp_username: string, ssl_required: bool, subdomain: string, switch_to_plan_date: string, tls_disabled: bool, trial_days_left: int, trial_until: string, updated_at: string, uploads_via_email_authentication: bool, use_provided_modified_at: bool, user: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>, user_lockout: bool, user_lockout_lock_period: int, user_lockout_tries: int, user_lockout_within: int, user_requests_enabled: bool, user_requests_notify_admins: bool, welcome_custom_text: string, welcome_email_cc: string, welcome_email_enabled: bool, welcome_email_subject: string, welcome_screen: string, windows_mode_ftp: bool>"
    get-site-api-keys: "table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    post-site-api-keys: "record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    get-site-dns-records: "table<domain: string, id: string, rrtype: string, value: string>"
    get-site-ip-addresses: "table<associated_with: string, group_id: int, id: string, ip_addresses: list<string>>"
    post-site-test-webhook: "record<clickwrap_body: string, clickwrap_id: int, code: int, data: record<dynamic: record>, errors: table<fields: list, messages: list>, message: string, status: string>"
    get-site-usage: "record<bytes_sent: float, current_storage: float, deleted_files_counted_in_minimum: float, deleted_files_storage: float, end_at: string, high_water_storage: float, high_water_user_count: float, id: int, root_storage: float, start_at: string, sync_bytes_received: float, sync_bytes_sent: float, total_billable_transfer_usage: float, total_billable_usage: float, usage_by_top_level_dir: record>"
    get-sso-strategies: "table<deprovision_behavior: string, deprovision_groups: bool, deprovision_users: bool, enabled: bool, id: int, label: string, ldap_base_dn: string, ldap_domain: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_username: string, ldap_username_field: string, logo_url: string, protocol: string, provider: string, provision_attachments_permission: bool, provision_company: string, provision_dav_permission: bool, provision_email_signup_groups: string, provision_ftp_permission: bool, provision_group_default: string, provision_group_exclusion: string, provision_group_inclusion: string, provision_group_required: string, provision_groups: bool, provision_sftp_permission: bool, provision_site_admin_groups: string, provision_time_zone: string, provision_users: bool, saml_provider_cert_fingerprint: string, saml_provider_issuer_url: string, saml_provider_metadata_content: string, saml_provider_metadata_url: string, saml_provider_slo_target_url: string, saml_provider_sso_target_url: string, scim_authentication_method: string, scim_oauth_access_token: string, scim_oauth_access_token_expires_at: string, scim_username: string, subdomain: string>"
    get-sso-strategies-id: "record<deprovision_behavior: string, deprovision_groups: bool, deprovision_users: bool, enabled: bool, id: int, label: string, ldap_base_dn: string, ldap_domain: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_username: string, ldap_username_field: string, logo_url: string, protocol: string, provider: string, provision_attachments_permission: bool, provision_company: string, provision_dav_permission: bool, provision_email_signup_groups: string, provision_ftp_permission: bool, provision_group_default: string, provision_group_exclusion: string, provision_group_inclusion: string, provision_group_required: string, provision_groups: bool, provision_sftp_permission: bool, provision_site_admin_groups: string, provision_time_zone: string, provision_users: bool, saml_provider_cert_fingerprint: string, saml_provider_issuer_url: string, saml_provider_metadata_content: string, saml_provider_metadata_url: string, saml_provider_slo_target_url: string, saml_provider_sso_target_url: string, scim_authentication_method: string, scim_oauth_access_token: string, scim_oauth_access_token_expires_at: string, scim_username: string, subdomain: string>"
    get-styles-path: "record<id: int, logo: record<name: string, uri: string>, path: string, thumbnail: record<name: string, uri: string>>"
    patch-styles-path: "record<id: int, logo: record<name: string, uri: string>, path: string, thumbnail: record<name: string, uri: string>>"
    get-usage-daily-snapshots: "table<api_usage_available: bool, current_storage: int, date: string, deleted_files_counted_in_minimum: int, deleted_files_storage: int, id: int, read_api_usage: int, root_storage: int, usage_by_top_level_dir: record, user_count: int, write_api_usage: int>"
    get-usage-snapshots: "table<bytes_sent: float, current_storage: float, deleted_files_counted_in_minimum: float, deleted_files_storage: float, end_at: string, high_water_storage: float, high_water_user_count: float, id: int, root_storage: float, start_at: string, sync_bytes_received: float, sync_bytes_sent: float, total_billable_transfer_usage: float, total_billable_usage: float, usage_by_top_level_dir: record>"
    patch-user: "record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>"
    get-user-api-keys: "table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    post-user-api-keys: "record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    get-user-groups: "table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>"
    get-user-public-keys: "table<created_at: string, fingerprint: string, id: int, title: string>"
    post-user-public-keys: "record<created_at: string, fingerprint: string, id: int, title: string>"
    get-user-cipher-uses: "table<created_at: string, id: int, interface: string, protocol_cipher: string, updated_at: string, user_id: int>"
    get-user-requests: "table<details: string, email: string, id: int, name: string>"
    post-user-requests: "record<details: string, email: string, id: int, name: string>"
    get-user-requests-id: "record<details: string, email: string, id: int, name: string>"
    get-users: "table<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>"
    post-users: "record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>"
    get-users-id: "record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>"
    patch-users-id: "record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>"
    get-users-user-id-api-keys: "table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    post-users-user-id-api-keys: "record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>"
    get-users-user-id-cipher-uses: "table<created_at: string, id: int, interface: string, protocol_cipher: string, updated_at: string, user_id: int>"
    get-users-user-id-groups: "table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>"
    get-users-user-id-permissions: "table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string>"
    get-users-user-id-public-keys: "table<created_at: string, fingerprint: string, id: int, title: string>"
    post-users-user-id-public-keys: "record<created_at: string, fingerprint: string, id: int, title: string>"
    post-webhook-tests: "record<code: int, data: record<dynamic: record>, message: string, status: string, success: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-action-notification-export-results" "post-action-notification-exports" "get-action-notification-exports-id" "post-action-webhook-failures-id-retry" "api-key-delete-current" "api-key-find-current" "api-key-update-current" "get-api-keys" "post-api-keys" "delete-api-keys-id" "get-api-keys-id" "patch-api-keys-id" "get-apps" "get-as2-incoming-messages" "get-as2-outgoing-messages" "get-as2-partners" "post-as2-partners" "delete-as2-partners-id" "get-as2-partners-id" "patch-as2-partners-id" "get-as2-stations" "post-as2-stations" "delete-as2-stations-id" "get-as2-stations-id" "patch-as2-stations-id" "get-automation-runs" "get-automation-runs-id" "get-automations" "post-automations" "delete-automations-id" "get-automations-id" "patch-automations-id" "get-bandwidth-snapshots" "get-behaviors" "post-behaviors" "behavior-list-for-path" "post-behaviors-webhook-test" "delete-behaviors-id" "get-behaviors-id" "patch-behaviors-id" "get-bundle-downloads" "get-bundle-notifications" "post-bundle-notifications" "delete-bundle-notifications-id" "get-bundle-notifications-id" "patch-bundle-notifications-id" "get-bundle-recipients" "post-bundle-recipients" "get-bundle-registrations" "get-bundles" "post-bundles" "delete-bundles-id" "get-bundles-id" "patch-bundles-id" "post-bundles-id-share" "get-clickwraps" "post-clickwraps" "delete-clickwraps-id" "get-clickwraps-id" "patch-clickwraps-id" "get-dns-records" "get-external-events" "post-external-events" "get-external-events-id" "file-action-begin-upload" "file-action-copy" "file-action-find" "file-action-move" "post-file-comment-reactions" "delete-file-comment-reactions-id" "post-file-comments" "file-comment-list-for-path" "delete-file-comments-id" "patch-file-comments-id" "get-file-migrations-id" "delete-files-path" "file-download" "patch-files-path" "post-files-path" "folder-list-for-path" "post-folders-path" "get-form-field-sets" "post-form-field-sets" "delete-form-field-sets-id" "get-form-field-sets-id" "patch-form-field-sets-id" "get-group-users" "post-group-users" "delete-group-users-id" "patch-group-users-id" "get-groups" "post-groups" "delete-groups-group-id-memberships-user-id" "patch-groups-group-id-memberships-user-id" "get-groups-group-id-permissions" "get-groups-group-id-users" "post-groups-group-id-users" "delete-groups-id" "get-groups-id" "patch-groups-id" "history-list" "history-list-for-file" "history-list-for-folder" "history-list-logins" "history-list-for-user" "get-history-export-results" "post-history-exports" "get-history-exports-id" "get-inbox-recipients" "post-inbox-recipients" "get-inbox-registrations" "get-inbox-uploads" "get-invoices" "get-invoices-id" "get-ip-addresses" "get-ip-addresses-exavault-reserved" "get-ip-addresses-reserved" "delete-locks-path" "lock-list-for-path" "post-locks-path" "get-message-comment-reactions" "post-message-comment-reactions" "delete-message-comment-reactions-id" "get-message-comment-reactions-id" "get-message-comments" "post-message-comments" "delete-message-comments-id" "get-message-comments-id" "patch-message-comments-id" "get-message-reactions" "post-message-reactions" "delete-message-reactions-id" "get-message-reactions-id" "get-messages" "post-messages" "delete-messages-id" "get-messages-id" "patch-messages-id" "get-notifications" "post-notifications" "delete-notifications-id" "get-notifications-id" "patch-notifications-id" "get-payments" "get-payments-id" "get-permissions" "post-permissions" "delete-permissions-id" "get-priorities" "get-projects" "post-projects" "delete-projects-id" "get-projects-id" "patch-projects-id" "get-public-keys" "post-public-keys" "delete-public-keys-id" "get-public-keys-id" "patch-public-keys-id" "get-remote-bandwidth-snapshots" "get-remote-servers" "post-remote-servers" "delete-remote-servers-id" "get-remote-servers-id" "patch-remote-servers-id" "get-remote-servers-id-configuration-file" "post-remote-servers-id-configuration-file" "get-requests" "post-requests" "get-requests-folders-path" "delete-requests-id" "delete-sessions" "post-sessions" "get-settings-changes" "get-sftp-host-keys" "post-sftp-host-keys" "delete-sftp-host-keys-id" "get-sftp-host-keys-id" "patch-sftp-host-keys-id" "get-site" "patch-site" "get-site-api-keys" "post-site-api-keys" "get-site-dns-records" "get-site-ip-addresses" "post-site-test-webhook" "get-site-usage" "get-sso-strategies" "get-sso-strategies-id" "post-sso-strategies-id-sync" "delete-styles-path" "get-styles-path" "patch-styles-path" "get-usage-daily-snapshots" "get-usage-snapshots" "patch-user" "get-user-api-keys" "post-user-api-keys" "get-user-groups" "get-user-public-keys" "post-user-public-keys" "get-user-cipher-uses" "get-user-requests" "post-user-requests" "delete-user-requests-id" "get-user-requests-id" "get-users" "post-users" "delete-users-id" "get-users-id" "patch-users-id" "post-users-id2fa-reset" "post-users-id-resend-welcome-email" "post-users-id-unlock" "get-users-user-id-api-keys" "post-users-user-id-api-keys" "get-users-user-id-cipher-uses" "get-users-user-id-groups" "get-users-user-id-permissions" "get-users-user-id-public-keys" "post-users-user-id-public-keys" "post-webhook-tests" "commands"] | sort) } | get name | first)
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

# List Action Notification Export Results
#
# GET /action_notification_export_results
# Returns: table<created_at: int, folder: string, id: int, message: string, path: string, request_headers: string, request_method: string, request_url: string, status: int, success: bool>
# operationId: GetActionNotificationExportResults
export def "get-action-notification-export-results" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --action-notification-export-id: int # ID of the associated action notification export. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/action_notification_export_results"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: action_notification_export_id, var: action_notification_export_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, action_notification_export_id: $action_notification_export_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Action Notification Export
#
# POST /action_notification_exports
# Returns: record<end_at: string, export_version: string, id: int, query_folder: string, query_message: string, query_path: string, query_request_method: string, query_request_url: string, query_status: string, query_success: bool, results_url: string, start_at: string, status: string>
# operationId: PostActionNotificationExports
export def "post-action-notification-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-at: string # End date/time of export range. (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --query-folder: string # Return notifications that were triggered by actions in this folder. (e.g. MyFolder)
  --query-message: string # Error message associated with the request, if any. (e.g. Connection Refused)
  --query-path: string # Return notifications that were triggered by actions on this specific path. (e.g. MyFile.txt)
  --query-request-method: string # The HTTP request method used by the webhook. (e.g. GET)
  --query-request-url: string # The target webhook URL. (e.g. http://example.com/webhook)
  --query-status: string # The HTTP status returned from the server in response to the webhook request. (e.g. 200)
  --query-success: oneof<nothing, bool> # true if the webhook request succeeded (i.e. returned a 200 or 204 response status). false otherwise. (e.g. true)
  --start-at: string # Start date/time of export range. (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/action_notification_exports"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: end_at, var: end_at}, {name: query_folder, var: query_folder}, {name: query_message, var: query_message}, {name: query_path, var: query_path}, {name: query_request_method, var: query_request_method}, {name: query_request_url, var: query_request_url}, {name: query_status, var: query_status}, {name: query_success, var: query_success}, {name: start_at, var: start_at}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    end_at: $end_at, query_folder: $query_folder, query_message: $query_message, query_path: $query_path, query_request_method: $query_request_method, query_request_url: $query_request_url, query_status: $query_status, query_success: $query_success, start_at: $start_at, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Action Notification Export
#
# GET /action_notification_exports/{id}
# Returns: record<end_at: string, export_version: string, id: int, query_folder: string, query_message: string, query_path: string, query_request_method: string, query_request_url: string, query_status: string, query_success: bool, results_url: string, start_at: string, status: string>
# operationId: GetActionNotificationExportsId
export def "get-action-notification-exports-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/action_notification_exports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# retry Action Webhook Failure
#
# POST /action_webhook_failures/{id}/retry
# operationId: PostActionWebhookFailuresIdRetry
export def "post-action-webhook-failures-id-retry" [
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
    method: post
    path: "/action_webhook_failures/{id}/retry"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete current API key. (Requires current API connection to be using an API key.)
#
# DELETE /api_key
# operationId: ApiKeyDeleteCurrent
export def "api-key-delete-current" [
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
    path: "/api_key"
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show information about current API key. (Requires current API connection to be using an API key.)
#
# GET /api_key
# Returns: record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: ApiKeyFindCurrent
export def "api-key-find-current" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/api_key"
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update current API key. (Requires current API connection to be using an API key.)
#
# PATCH /api_key
# Returns: record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: ApiKeyUpdateCurrent
export def "api-key-update-current" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (e.g. full)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api_key"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: expires_at, var: expires_at}, {name: name, var: name}, {name: permission_set, var: permission_set}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    expires_at: $expires_at, name: $name, permission_set: $permission_set
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Api Keys
#
# GET /api_keys
# Returns: table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: GetApiKeys
export def "get-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[expires_at]=desc`). Valid fields are `expires_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `expires_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `expires_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `expires_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `expires_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api_keys"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Api Key
#
# POST /api_keys
# Returns: record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: PostApiKeys
export def "post-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --path: string # Folder path restriction for this api key. (e.g. shared/docs)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (default: full, e.g. full)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api_keys"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: name, var: name}, {name: path, var: path}, {name: permission_set, var: permission_set}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    description: $description, expires_at: $expires_at, name: $name, path: $path, permission_set: $permission_set, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Api Key
#
# DELETE /api_keys/{id}
# operationId: DeleteApiKeysId
export def "delete-api-keys-id" [
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
    path: "/api_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Api Key
#
# GET /api_keys/{id}
# Returns: record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: GetApiKeysId
export def "get-api-keys-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Api Key
#
# PATCH /api_keys/{id}
# Returns: record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: PatchApiKeysId
export def "patch-api-keys-id" [
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
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (e.g. full)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api_keys/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: name, var: name}, {name: permission_set, var: permission_set}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, description: $description, expires_at: $expires_at, name: $name, permission_set: $permission_set
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Apps
#
# GET /apps
# Returns: table<app_type: string, documentation_links: record, extended_description: string, external_homepage_url: string, featured: bool, folder_behavior_type: string, icon_url: string, logo_thumbnail_url: string, logo_url: string, marketing_youtube_url: string, name: string, remote_server_type: string, screenshot_list_urls: list<string>, short_description: string, sso_strategy_type: string, tutorial_youtube_url: string>
# operationId: GetApps
export def "get-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[name]=desc`). Valid fields are `name` and `app_type`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List As2 Incoming Messages
#
# GET /as2_incoming_messages
# Returns: table<activity_log: string, as2_from: string, as2_partner_id: int, as2_station_id: int, as2_to: string, attachment_filename: string, body_size: string, content_type: string, created_at: string, date: string, encrypted_uri: string, hex_recipient_serial: string, http_headers: record, http_response_code: string, http_response_headers: record, id: int, ip: string, mdn_response_uri: string, message_decrypted: bool, message_id: string, message_mdn_returned: bool, message_processing_success: bool, message_received: bool, message_signature_verified: bool, mic: string, mic_algo: string, processing_result: string, processing_result_description: string, raw_uri: string, recipient_issuer: string, recipient_serial: string, smime_signed_uri: string, smime_uri: string, subject: string, uuid: string>
# operationId: GetAs2IncomingMessages
export def "get-as2-incoming-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at` and `as2_partner_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
  --as2-partner-id: int # As2 Partner ID. If provided, will return message specific to that partner. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/as2_incoming_messages"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: as2_partner_id, var: as2_partner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, as2_partner_id: $as2_partner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List As2 Outgoing Messages
#
# GET /as2_outgoing_messages
# Returns: table<activity_log: string, as2_from: string, as2_partner_id: int, as2_station_id: int, as2_to: string, attachment_filename: string, body_size: string, created_at: string, date: string, encrypted_uri: string, http_headers: record, http_response_code: string, http_response_headers: record, http_transmission_duration: float, id: int, mdn_message_id_matched: bool, mdn_mic_matched: bool, mdn_processing_success: bool, mdn_received: bool, mdn_response_uri: string, mdn_signature_verified: bool, mdn_valid: bool, message_id: string, mic: string, mic_sha_256: string, processing_result: string, processing_result_description: string, raw_uri: string, smime_signed_uri: string, smime_uri: string, uuid: string>
# operationId: GetAs2OutgoingMessages
export def "get-as2-outgoing-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at` and `as2_partner_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
  --as2-partner-id: int # As2 Partner ID. If provided, will return message specific to that partner. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/as2_outgoing_messages"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: as2_partner_id, var: as2_partner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, as2_partner_id: $as2_partner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List As2 Partners
#
# GET /as2_partners
# Returns: table<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string>
# operationId: GetAs2Partners
export def "get-as2-partners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/as2_partners"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create As2 Partner
#
# POST /as2_partners
# Returns: record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string>
# operationId: PostAs2Partners
export def "post-as2-partners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  as2_station_id: int # Id of As2Station for this partner (format: int32)
  name: string # AS2 Name
  public_certificate: string
  --server-certificate: string # Remote server certificate security setting
  uri: string # URL base for AS2 responses
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/as2_partners"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: as2_station_id, var: as2_station_id}, {name: name, var: name}, {name: public_certificate, var: public_certificate}, {name: server_certificate, var: server_certificate}, {name: uri, var: uri}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    as2_station_id: $as2_station_id, name: $name, public_certificate: $public_certificate, server_certificate: $server_certificate, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete As2 Partner
#
# DELETE /as2_partners/{id}
# operationId: DeleteAs2PartnersId
export def "delete-as2-partners-id" [
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
    path: "/as2_partners/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show As2 Partner
#
# GET /as2_partners/{id}
# Returns: record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string>
# operationId: GetAs2PartnersId
export def "get-as2-partners-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/as2_partners/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update As2 Partner
#
# PATCH /as2_partners/{id}
# Returns: record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string>
# operationId: PatchAs2PartnersId
export def "patch-as2-partners-id" [
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
  --name: string # AS2 Name
  --public-certificate: string
  --server-certificate: string # Remote server certificate security setting
  --uri: string # URL base for AS2 responses
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/as2_partners/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: name, var: name}, {name: public_certificate, var: public_certificate}, {name: server_certificate, var: server_certificate}, {name: uri, var: uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, name: $name, public_certificate: $public_certificate, server_certificate: $server_certificate, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List As2 Stations
#
# GET /as2_stations
# Returns: table<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string>
# operationId: GetAs2Stations
export def "get-as2-stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/as2_stations"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create As2 Station
#
# POST /as2_stations
# Returns: record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string>
# operationId: PostAs2Stations
export def "post-as2-stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # AS2 Name
  private_key: string
  --private-key-password: string
  public_certificate: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/as2_stations"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: name, var: name}, {name: private_key, var: private_key}, {name: private_key_password, var: private_key_password}, {name: public_certificate, var: public_certificate}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    name: $name, private_key: $private_key, private_key_password: $private_key_password, public_certificate: $public_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete As2 Station
#
# DELETE /as2_stations/{id}
# operationId: DeleteAs2StationsId
export def "delete-as2-stations-id" [
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
    path: "/as2_stations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show As2 Station
#
# GET /as2_stations/{id}
# Returns: record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string>
# operationId: GetAs2StationsId
export def "get-as2-stations-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/as2_stations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update As2 Station
#
# PATCH /as2_stations/{id}
# Returns: record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string>
# operationId: PatchAs2StationsId
export def "patch-as2-stations-id" [
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
  --name: string # AS2 Name
  --private-key: string
  --private-key-password: string
  --public-certificate: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/as2_stations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: name, var: name}, {name: private_key, var: private_key}, {name: private_key_password, var: private_key_password}, {name: public_certificate, var: public_certificate}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, name: $name, private_key: $private_key, private_key_password: $private_key_password, public_certificate: $public_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Automation Runs
#
# GET /automation_runs
# Returns: table<automation_id: int, completed_at: string, created_at: string, id: int, status: string, status_messages_url: string>
# operationId: GetAutomationRuns
export def "get-automation-runs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at` and `status`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `status`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `status`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `status`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `status`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `status`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `status`.
  --automation-id: int # ID of the associated Automation. (required, format: int32, e.g. 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/automation_runs"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: automation_id, var: automation_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, automation_id: $automation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Automation Run
#
# GET /automation_runs/{id}
# Returns: record<automation_id: int, completed_at: string, created_at: string, id: int, status: string, status_messages_url: string>
# operationId: GetAutomationRunsId
export def "get-automation-runs-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/automation_runs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Automations
#
# GET /automations
# Returns: table<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string>
# operationId: GetAutomations
export def "get-automations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[automation]=desc`). Valid fields are `automation`, `disabled`, `last_modified_at` or `name`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --with-deleted: oneof<nothing, bool> # Set to true to include deleted automations in the results.
  --automation: string # DEPRECATED: Type of automation to filter by. Use `filter[automation]` instead.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/automations"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: with_deleted, var: with_deleted}, {name: automation, var: automation}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, with_deleted: $with_deleted, automation: $automation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Automation
#
# POST /automations
# Returns: record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string>
# operationId: PostAutomations
export def "post-automations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  automation: string@automation-completer # Automation type (e.g. create_folder)
  --description: string # Description for the this Automation. (e.g. example)
  --destination: string # DEPRECATED: Destination Path. Use `destinations` instead.
  --destination-replace-from: string # If set, this string in the destination path will be replaced with the value in `destination_replace_to`.
  --destination-replace-to: string # If set, this string will replace the value `destination_replace_from` in the destination filename. You can use special patterns here.
  --destinations: list<string> # A list of String destination paths or Hash of folder_path and optional file_path. (e.g. [folder_a/file_a.txt, {file_path: file_b.txt, folder_path: folder_b}, {folder_path: folder_c}])
  --disabled: oneof<nothing, bool> # If true, this automation will not run. (e.g. true)
  --group-ids: string # A list of group IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --interval: string # How often to run this automation? One of: `day`, `week`, `week_end`, `month`, `month_end`, `quarter`, `quarter_end`, `year`, `year_end` (e.g. year)
  --name: string # Name for this automation. (e.g. example)
  --path: string # Path on which this Automation runs. Supports globs.
  --schedule: record # Custom schedule for running this automation. (e.g. {days_of_week: [0, 1, 3], time_zone: Eastern Time (US & Canada), times_of_day: [7:30, 11:30]})
  --source: string # Source Path (e.g. source)
  --sync-ids: string # A list of sync IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --trigger: string@trigger-completer # How this automation is triggered to run. One of: `realtime`, `daily`, `custom_schedule`, `webhook`, `email`, or `action`. (e.g. realtime)
  --trigger-actions: list<string> # If trigger is `action`, this is the list of action types on which to trigger the automation. Valid actions are create, read, update, destroy, move, copy (e.g. [create])
  --user-ids: string # A list of user IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --value: record # A Hash of attributes specific to the automation type. (e.g. {limit: 1})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/automations"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: automation, var: automation}, {name: description, var: description}, {name: destination, var: destination}, {name: destination_replace_from, var: destination_replace_from}, {name: destination_replace_to, var: destination_replace_to}, {name: destinations, var: destinations}, {name: disabled, var: disabled}, {name: group_ids, var: group_ids}, {name: interval, var: interval}, {name: name, var: name}, {name: path, var: path}, {name: schedule, var: schedule}, {name: source, var: source}, {name: sync_ids, var: sync_ids}, {name: trigger, var: trigger}, {name: trigger_actions, var: trigger_actions}, {name: user_ids, var: user_ids}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    automation: $automation, description: $description, destination: $destination, destination_replace_from: $destination_replace_from, destination_replace_to: $destination_replace_to, destinations: $destinations, disabled: $disabled, group_ids: $group_ids, interval: $interval, name: $name, path: $path, schedule: $schedule, source: $source, sync_ids: $sync_ids, trigger: $trigger, trigger_actions: $trigger_actions, user_ids: $user_ids, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Automation
#
# DELETE /automations/{id}
# operationId: DeleteAutomationsId
export def "delete-automations-id" [
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
    path: "/automations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Automation
#
# GET /automations/{id}
# Returns: record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string>
# operationId: GetAutomationsId
export def "get-automations-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/automations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Automation
#
# PATCH /automations/{id}
# Returns: record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string>
# operationId: PatchAutomationsId
export def "patch-automations-id" [
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
  --automation: string@automation-completer # Automation type (e.g. create_folder)
  --description: string # Description for the this Automation. (e.g. example)
  --destination: string # DEPRECATED: Destination Path. Use `destinations` instead.
  --destination-replace-from: string # If set, this string in the destination path will be replaced with the value in `destination_replace_to`.
  --destination-replace-to: string # If set, this string will replace the value `destination_replace_from` in the destination filename. You can use special patterns here.
  --destinations: list<string> # A list of String destination paths or Hash of folder_path and optional file_path. (e.g. [folder_a/file_a.txt, {file_path: file_b.txt, folder_path: folder_b}, {folder_path: folder_c}])
  --disabled: oneof<nothing, bool> # If true, this automation will not run. (e.g. true)
  --group-ids: string # A list of group IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --interval: string # How often to run this automation? One of: `day`, `week`, `week_end`, `month`, `month_end`, `quarter`, `quarter_end`, `year`, `year_end` (e.g. year)
  --name: string # Name for this automation. (e.g. example)
  --path: string # Path on which this Automation runs. Supports globs.
  --schedule: record # Custom schedule for running this automation. (e.g. {days_of_week: [0, 1, 3], time_zone: Eastern Time (US & Canada), times_of_day: [7:30, 11:30]})
  --source: string # Source Path (e.g. source)
  --sync-ids: string # A list of sync IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --trigger: string@trigger-completer # How this automation is triggered to run. One of: `realtime`, `daily`, `custom_schedule`, `webhook`, `email`, or `action`. (e.g. realtime)
  --trigger-actions: list<string> # If trigger is `action`, this is the list of action types on which to trigger the automation. Valid actions are create, read, update, destroy, move, copy (e.g. [create])
  --user-ids: string # A list of user IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --value: record # A Hash of attributes specific to the automation type. (e.g. {limit: 1})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/automations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: automation, var: automation}, {name: description, var: description}, {name: destination, var: destination}, {name: destination_replace_from, var: destination_replace_from}, {name: destination_replace_to, var: destination_replace_to}, {name: destinations, var: destinations}, {name: disabled, var: disabled}, {name: group_ids, var: group_ids}, {name: interval, var: interval}, {name: name, var: name}, {name: path, var: path}, {name: schedule, var: schedule}, {name: source, var: source}, {name: sync_ids, var: sync_ids}, {name: trigger, var: trigger}, {name: trigger_actions, var: trigger_actions}, {name: user_ids, var: user_ids}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, automation: $automation, description: $description, destination: $destination, destination_replace_from: $destination_replace_from, destination_replace_to: $destination_replace_to, destinations: $destinations, disabled: $disabled, group_ids: $group_ids, interval: $interval, name: $name, path: $path, schedule: $schedule, source: $source, sync_ids: $sync_ids, trigger: $trigger, trigger_actions: $trigger_actions, user_ids: $user_ids, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Bandwidth Snapshots
#
# GET /bandwidth_snapshots
# Returns: table<bytes_received: float, bytes_sent: float, id: int, logged_at: string, requests_get: float, requests_other: float, requests_put: float, sync_bytes_received: float, sync_bytes_sent: float>
# operationId: GetBandwidthSnapshots
export def "get-bandwidth-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[logged_at]=desc`). Valid fields are `logged_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `logged_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `logged_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `logged_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `logged_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `logged_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `logged_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bandwidth_snapshots"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Behaviors
#
# GET /behaviors
# Returns: table<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>
# operationId: GetBehaviors
export def "get-behaviors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[behavior]=desc`). Valid fields are `behavior`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `behavior`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `behavior`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `behavior`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `behavior`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `behavior`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `behavior`.
  --behavior: string # If set, only shows folder behaviors matching this behavior type.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/behaviors"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: behavior, var: behavior}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, behavior: $behavior
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Behavior
#
# POST /behaviors
# Returns: record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>
# operationId: PostBehaviors
export def "post-behaviors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment-file: string # Certain behaviors may require a file, for instance, the "watermark" behavior requires a watermark image (format: binary)
  behavior: string # Behavior type. (e.g. webhook)
  --description: string # Description for this behavior. (e.g. example)
  --name: string # Name for this behavior. (e.g. example)
  path: string # Folder behaviors path.
  --value: string # The value of the folder behavior. Can be a integer, array, or hash depending on the type of folder behavior. See The Behavior Types section for example values for each type of behavior. (e.g. {"method": "GET"})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/behaviors"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: attachment_file, var: attachment_file}, {name: behavior, var: behavior}, {name: description, var: description}, {name: name, var: name}, {name: path, var: path}, {name: value, var: value}], files: [attachment_file]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    attachment_file: $attachment_file, behavior: $behavior, description: $description, name: $name, path: $path, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Behaviors by path
#
# GET /behaviors/folders/{path}
# Returns: table<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>
# operationId: BehaviorListForPath
export def "behavior-list-for-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[behavior]=desc`). Valid fields are `behavior`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `behavior`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `behavior`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `behavior`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `behavior`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `behavior`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `behavior`.
  --recursive: string # Show behaviors above this path?
  --behavior: string # DEPRECATED: If set only shows folder behaviors matching this behavior type. Use `filter[behavior]` instead.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/behaviors/folders/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: recursive, var: recursive}, {name: behavior, var: behavior}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, recursive: $recursive, behavior: $behavior
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test webhook.
#
# POST /behaviors/webhook/test
# Returns: record<clickwrap_body: string, clickwrap_id: int, code: int, data: record<dynamic: record>, errors: table<fields: list, messages: list>, message: string, status: string>
# operationId: PostBehaviorsWebhookTest
export def "post-behaviors-webhook-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # action for test body (e.g. test)
  --body: record # Additional body parameters. (e.g. {test-param: testvalue})
  --encoding: string # HTTP encoding method. Can be JSON, XML, or RAW (form data). (e.g. RAW)
  --headers: record # Additional request headers. (e.g. {x-test-header: testvalue})
  --method: string # HTTP method(GET or POST). (e.g. GET)
  url: string # URL for testing the webhook. (e.g. https://www.site.com/...)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/behaviors/webhook/test"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: action, var: action}, {name: body, var: body}, {name: encoding, var: encoding}, {name: headers, var: headers}, {name: method, var: method}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    action: $action, body: $body, encoding: $encoding, headers: $headers, method: $method, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Behavior
#
# DELETE /behaviors/{id}
# operationId: DeleteBehaviorsId
export def "delete-behaviors-id" [
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
    path: "/behaviors/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Behavior
#
# GET /behaviors/{id}
# Returns: record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>
# operationId: GetBehaviorsId
export def "get-behaviors-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/behaviors/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Behavior
#
# PATCH /behaviors/{id}
# Returns: record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record>
# operationId: PatchBehaviorsId
export def "patch-behaviors-id" [
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
  --attachment-delete: oneof<nothing, bool> # If true, will delete the file stored in attachment
  --attachment-file: string # Certain behaviors may require a file, for instance, the "watermark" behavior requires a watermark image (format: binary)
  --behavior: string # Behavior type. (e.g. webhook)
  --description: string # Description for this behavior. (e.g. example)
  --name: string # Name for this behavior. (e.g. example)
  --path: string # Folder behaviors path.
  --value: string # The value of the folder behavior. Can be a integer, array, or hash depending on the type of folder behavior. See The Behavior Types section for example values for each type of behavior. (e.g. {"method": "GET"})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/behaviors/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: attachment_delete, var: attachment_delete}, {name: attachment_file, var: attachment_file}, {name: behavior, var: behavior}, {name: description, var: description}, {name: name, var: name}, {name: path, var: path}, {name: value, var: value}], files: [attachment_file]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, attachment_delete: $attachment_delete, attachment_file: $attachment_file, behavior: $behavior, description: $description, name: $name, path: $path, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Bundle Downloads
#
# GET /bundle_downloads
# Returns: table<bundle_registration: record<bundle_code: string, bundle_id: int, bundle_recipient_id: int, clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_code: string, ip: string, name: string>, created_at: string, download_method: string, path: string>
# operationId: GetBundleDownloads
export def "get-bundle-downloads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
  --bundle-id: int # Bundle ID (format: int32)
  --bundle-registration-id: int # BundleRegistration ID (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bundle_downloads"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: bundle_id, var: bundle_id}, {name: bundle_registration_id, var: bundle_registration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, bundle_id: $bundle_id, bundle_registration_id: $bundle_registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Bundle Notifications
#
# GET /bundle_notifications
# Returns: table<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int>
# operationId: GetBundleNotifications
export def "get-bundle-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --bundle-id: int # Bundle ID to notify on (format: int32, e.g. 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bundle_notifications"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: bundle_id, var: bundle_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, bundle_id: $bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Bundle Notification
#
# POST /bundle_notifications
# Returns: record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int>
# operationId: PostBundleNotifications
export def "post-bundle-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bundle_id: int # Bundle ID to notify on (format: int32, e.g. 1)
  --notify-on-registration: oneof<nothing, bool> # Triggers bundle notification when a registration action occurs for it. (e.g. true)
  --notify-on-upload: oneof<nothing, bool> # Triggers bundle notification when a upload action occurs for it. (e.g. true)
  --user-id: int # The id of the user to notify. (format: int32, e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bundle_notifications"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: bundle_id, var: bundle_id}, {name: notify_on_registration, var: notify_on_registration}, {name: notify_on_upload, var: notify_on_upload}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    bundle_id: $bundle_id, notify_on_registration: $notify_on_registration, notify_on_upload: $notify_on_upload, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Bundle Notification
#
# DELETE /bundle_notifications/{id}
# operationId: DeleteBundleNotificationsId
export def "delete-bundle-notifications-id" [
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
    path: "/bundle_notifications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Bundle Notification
#
# GET /bundle_notifications/{id}
# Returns: record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int>
# operationId: GetBundleNotificationsId
export def "get-bundle-notifications-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bundle_notifications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Bundle Notification
#
# PATCH /bundle_notifications/{id}
# Returns: record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int>
# operationId: PatchBundleNotificationsId
export def "patch-bundle-notifications-id" [
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
  --notify-on-registration: oneof<nothing, bool> # Triggers bundle notification when a registration action occurs for it. (e.g. true)
  --notify-on-upload: oneof<nothing, bool> # Triggers bundle notification when a upload action occurs for it. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/bundle_notifications/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: notify_on_registration, var: notify_on_registration}, {name: notify_on_upload, var: notify_on_upload}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, notify_on_registration: $notify_on_registration, notify_on_upload: $notify_on_upload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Bundle Recipients
#
# GET /bundle_recipients
# Returns: table<company: string, name: string, note: string, recipient: string, sent_at: string>
# operationId: GetBundleRecipients
export def "get-bundle-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[has_registrations]=desc`). Valid fields are `has_registrations`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `has_registrations`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `has_registrations`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `has_registrations`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `has_registrations`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `has_registrations`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `has_registrations`.
  --bundle-id: int # List recipients for the bundle with this ID. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bundle_recipients"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: bundle_id, var: bundle_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, bundle_id: $bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Bundle Recipient
#
# POST /bundle_recipients
# Returns: record<company: string, name: string, note: string, recipient: string, sent_at: string>
# operationId: PostBundleRecipients
export def "post-bundle-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bundle_id: int # Bundle to share. (format: int32)
  --company: string # Company of recipient. (e.g. Acme Ltd)
  --name: string # Name of recipient. (e.g. John Smith)
  --note: string # Note to include in email. (e.g. Just a note.)
  recipient: string # Email addresses to share this bundle with. (e.g. johndoe@gmail.com)
  --share-after-create: oneof<nothing, bool> # Set to true to share the link with the recipient upon creation.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bundle_recipients"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: bundle_id, var: bundle_id}, {name: company, var: company}, {name: name, var: name}, {name: note, var: note}, {name: recipient, var: recipient}, {name: share_after_create, var: share_after_create}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    bundle_id: $bundle_id, company: $company, name: $name, note: $note, recipient: $recipient, share_after_create: $share_after_create, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Bundle Registrations
#
# GET /bundle_registrations
# Returns: table<bundle_code: string, bundle_id: int, bundle_recipient_id: int, clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_code: string, ip: string, name: string>
# operationId: GetBundleRegistrations
export def "get-bundle-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --bundle-id: int # ID of the associated Bundle (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bundle_registrations"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: bundle_id, var: bundle_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, bundle_id: $bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Bundles
#
# GET /bundles
# Returns: table<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list, form_layout: list, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record>
# operationId: GetBundles
export def "get-bundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at` and `code`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bundles"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Bundle
#
# POST /bundles
# Returns: record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record>
# operationId: PostBundles
export def "post-bundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clickwrap-id: int # ID of the clickwrap to use with this bundle. (format: int32, e.g. 1)
  --code: string # Bundle code. This code forms the end part of the Public URL. (e.g. abc123)
  --description: string # Public description (e.g. The public description of the bundle.)
  --dont-separate-submissions-by-folder: oneof<nothing, bool> # Do not create subfolders for files uploaded to this share. Note: there are subtle security pitfalls with allowing anonymous uploads from multiple users to live in the same folder. We strongly discourage use of this option unless absolutely required. (e.g. true)
  --expires-at: string # Bundle expiration date/time (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --form-field-set-id: int # Id of Form Field Set to use with this bundle (format: int32)
  --inbox-id: int # ID of the associated inbox, if available. (format: int32, e.g. 1)
  --max-uses: int # Maximum number of times bundle can be accessed (format: int32, e.g. 1)
  --note: string # Bundle internal note (e.g. The internal note on the bundle.)
  --password: string # Password for this bundle. (e.g. Password)
  --path-template: string # Template for creating submission subfolders. Can use the uploader's name, email address, ip, company, and any custom form data. (e.g. {{name}}_{{ip}})
  paths: list<string> # A list of paths to include in this bundle. (e.g. [file.txt])
  --permissions: string@permissions-completer # Permissions that apply to Folders in this Share Link. (e.g. read)
  --preview-only: oneof<nothing, bool> # Restrict users to previewing files only?
  --require-registration: oneof<nothing, bool> # Show a registration page that captures the downloader's name and email address?
  --require-share-recipient: oneof<nothing, bool> # Only allow access to recipients who have explicitly received the share via an email sent through the Files.com UI?
  --send-email-receipt-to-uploader: oneof<nothing, bool> # Send delivery receipt to the uploader. Note: For writable share only (e.g. true)
  --skip-company: oneof<nothing, bool> # BundleRegistrations can be saved without providing company? (e.g. true)
  --skip-email: oneof<nothing, bool> # BundleRegistrations can be saved without providing email? (e.g. true)
  --skip-name: oneof<nothing, bool> # BundleRegistrations can be saved without providing name? (e.g. true)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --watermark-attachment-file: string # Preview watermark image applied to all bundle items. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bundles"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: clickwrap_id, var: clickwrap_id}, {name: code, var: code}, {name: description, var: description}, {name: dont_separate_submissions_by_folder, var: dont_separate_submissions_by_folder}, {name: expires_at, var: expires_at}, {name: form_field_set_id, var: form_field_set_id}, {name: inbox_id, var: inbox_id}, {name: max_uses, var: max_uses}, {name: note, var: note}, {name: password, var: password}, {name: path_template, var: path_template}, {name: paths, var: paths}, {name: permissions, var: permissions}, {name: preview_only, var: preview_only}, {name: require_registration, var: require_registration}, {name: require_share_recipient, var: require_share_recipient}, {name: send_email_receipt_to_uploader, var: send_email_receipt_to_uploader}, {name: skip_company, var: skip_company}, {name: skip_email, var: skip_email}, {name: skip_name, var: skip_name}, {name: user_id, var: user_id}, {name: watermark_attachment_file, var: watermark_attachment_file}], files: [watermark_attachment_file]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    clickwrap_id: $clickwrap_id, code: $code, description: $description, dont_separate_submissions_by_folder: $dont_separate_submissions_by_folder, expires_at: $expires_at, form_field_set_id: $form_field_set_id, inbox_id: $inbox_id, max_uses: $max_uses, note: $note, password: $password, path_template: $path_template, paths: $paths, permissions: $permissions, preview_only: $preview_only, require_registration: $require_registration, require_share_recipient: $require_share_recipient, send_email_receipt_to_uploader: $send_email_receipt_to_uploader, skip_company: $skip_company, skip_email: $skip_email, skip_name: $skip_name, user_id: $user_id, watermark_attachment_file: $watermark_attachment_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Bundle
#
# DELETE /bundles/{id}
# operationId: DeleteBundlesId
export def "delete-bundles-id" [
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
    path: "/bundles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Bundle
#
# GET /bundles/{id}
# Returns: record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record>
# operationId: GetBundlesId
export def "get-bundles-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bundles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Bundle
#
# PATCH /bundles/{id}
# Returns: record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record>
# operationId: PatchBundlesId
export def "patch-bundles-id" [
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
  --clickwrap-id: int # ID of the clickwrap to use with this bundle. (format: int32, e.g. 1)
  --code: string # Bundle code. This code forms the end part of the Public URL. (e.g. abc123)
  --description: string # Public description (e.g. The public description of the bundle.)
  --dont-separate-submissions-by-folder: oneof<nothing, bool> # Do not create subfolders for files uploaded to this share. Note: there are subtle security pitfalls with allowing anonymous uploads from multiple users to live in the same folder. We strongly discourage use of this option unless absolutely required. (e.g. true)
  --expires-at: string # Bundle expiration date/time (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --form-field-set-id: int # Id of Form Field Set to use with this bundle (format: int32)
  --inbox-id: int # ID of the associated inbox, if available. (format: int32, e.g. 1)
  --max-uses: int # Maximum number of times bundle can be accessed (format: int32, e.g. 1)
  --note: string # Bundle internal note (e.g. The internal note on the bundle.)
  --password: string # Password for this bundle. (e.g. Password)
  --path-template: string # Template for creating submission subfolders. Can use the uploader's name, email address, ip, company, and any custom form data. (e.g. {{name}}_{{ip}})
  --paths: list<string> # A list of paths to include in this bundle. (e.g. [file.txt])
  --permissions: string@permissions-completer # Permissions that apply to Folders in this Share Link. (e.g. read)
  --preview-only: oneof<nothing, bool> # Restrict users to previewing files only?
  --require-registration: oneof<nothing, bool> # Show a registration page that captures the downloader's name and email address?
  --require-share-recipient: oneof<nothing, bool> # Only allow access to recipients who have explicitly received the share via an email sent through the Files.com UI?
  --send-email-receipt-to-uploader: oneof<nothing, bool> # Send delivery receipt to the uploader. Note: For writable share only (e.g. true)
  --skip-company: oneof<nothing, bool> # BundleRegistrations can be saved without providing company? (e.g. true)
  --skip-email: oneof<nothing, bool> # BundleRegistrations can be saved without providing email? (e.g. true)
  --skip-name: oneof<nothing, bool> # BundleRegistrations can be saved without providing name? (e.g. true)
  --watermark-attachment-delete: oneof<nothing, bool> # If true, will delete the file stored in watermark_attachment
  --watermark-attachment-file: string # Preview watermark image applied to all bundle items. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/bundles/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: clickwrap_id, var: clickwrap_id}, {name: code, var: code}, {name: description, var: description}, {name: dont_separate_submissions_by_folder, var: dont_separate_submissions_by_folder}, {name: expires_at, var: expires_at}, {name: form_field_set_id, var: form_field_set_id}, {name: inbox_id, var: inbox_id}, {name: max_uses, var: max_uses}, {name: note, var: note}, {name: password, var: password}, {name: path_template, var: path_template}, {name: paths, var: paths}, {name: permissions, var: permissions}, {name: preview_only, var: preview_only}, {name: require_registration, var: require_registration}, {name: require_share_recipient, var: require_share_recipient}, {name: send_email_receipt_to_uploader, var: send_email_receipt_to_uploader}, {name: skip_company, var: skip_company}, {name: skip_email, var: skip_email}, {name: skip_name, var: skip_name}, {name: watermark_attachment_delete, var: watermark_attachment_delete}, {name: watermark_attachment_file, var: watermark_attachment_file}], files: [watermark_attachment_file]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, clickwrap_id: $clickwrap_id, code: $code, description: $description, dont_separate_submissions_by_folder: $dont_separate_submissions_by_folder, expires_at: $expires_at, form_field_set_id: $form_field_set_id, inbox_id: $inbox_id, max_uses: $max_uses, note: $note, password: $password, path_template: $path_template, paths: $paths, permissions: $permissions, preview_only: $preview_only, require_registration: $require_registration, require_share_recipient: $require_share_recipient, send_email_receipt_to_uploader: $send_email_receipt_to_uploader, skip_company: $skip_company, skip_email: $skip_email, skip_name: $skip_name, watermark_attachment_delete: $watermark_attachment_delete, watermark_attachment_file: $watermark_attachment_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send email(s) with a link to bundle
#
# POST /bundles/{id}/share
# operationId: PostBundlesIdShare
export def "post-bundles-id-share" [
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
  --note: string # Note to include in email. (e.g. Just a note.)
  --recipients: list # A list of recipients to share this bundle with. Required unless `to` is used. (e.g. [{company: Acme Ltd, name: John Doe, recipient: johndoe@gmail.com}])
  --to: list<string> # A list of email addresses to share this bundle with. Required unless `recipients` is used. (e.g. [johndoe@gmail.com])
]: any -> any {
  $in | http-request {
    method: post
    path: "/bundles/{id}/share"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: note, var: note}, {name: recipients, var: recipients}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id, note: $note, recipients: $recipients, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Clickwraps
#
# GET /clickwraps
# Returns: table<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string>
# operationId: GetClickwraps
export def "get-clickwraps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/clickwraps"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Clickwrap
#
# POST /clickwraps
# Returns: record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string>
# operationId: PostClickwraps
export def "post-clickwraps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # Body text of Clickwrap (supports Markdown formatting). (e.g. [Legal body text])
  --name: string # Name of the Clickwrap agreement (used when selecting from multiple Clickwrap agreements.) (e.g. Example Site NDA for Files.com Use)
  --use-with-bundles: string@use-with-bundles-completer # Use this Clickwrap for Bundles? (e.g. example)
  --use-with-inboxes: string@use-with-inboxes-completer # Use this Clickwrap for Inboxes? (e.g. example)
  --use-with-users: string@use-with-users-completer # Use this Clickwrap for User Registrations? Note: This only applies to User Registrations where the User is invited to your Files.com site using an E-Mail invitation process where they then set their own password. (e.g. example)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clickwraps"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}, {name: name, var: name}, {name: use_with_bundles, var: use_with_bundles}, {name: use_with_inboxes, var: use_with_inboxes}, {name: use_with_users, var: use_with_users}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    body: $body, name: $name, use_with_bundles: $use_with_bundles, use_with_inboxes: $use_with_inboxes, use_with_users: $use_with_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Clickwrap
#
# DELETE /clickwraps/{id}
# operationId: DeleteClickwrapsId
export def "delete-clickwraps-id" [
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
    path: "/clickwraps/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Clickwrap
#
# GET /clickwraps/{id}
# Returns: record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string>
# operationId: GetClickwrapsId
export def "get-clickwraps-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/clickwraps/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Clickwrap
#
# PATCH /clickwraps/{id}
# Returns: record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string>
# operationId: PatchClickwrapsId
export def "patch-clickwraps-id" [
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
  --body: string # Body text of Clickwrap (supports Markdown formatting). (e.g. [Legal body text])
  --name: string # Name of the Clickwrap agreement (used when selecting from multiple Clickwrap agreements.) (e.g. Example Site NDA for Files.com Use)
  --use-with-bundles: string@use-with-bundles-completer # Use this Clickwrap for Bundles? (e.g. example)
  --use-with-inboxes: string@use-with-inboxes-completer # Use this Clickwrap for Inboxes? (e.g. example)
  --use-with-users: string@use-with-users-completer # Use this Clickwrap for User Registrations? Note: This only applies to User Registrations where the User is invited to your Files.com site using an E-Mail invitation process where they then set their own password. (e.g. example)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/clickwraps/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}, {name: name, var: name}, {name: use_with_bundles, var: use_with_bundles}, {name: use_with_inboxes, var: use_with_inboxes}, {name: use_with_users, var: use_with_users}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, body: $body, name: $name, use_with_bundles: $use_with_bundles, use_with_inboxes: $use_with_inboxes, use_with_users: $use_with_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show site DNS configuration.
#
# GET /dns_records
# Returns: table<domain: string, id: string, rrtype: string, value: string>
# operationId: GetDnsRecords
export def "get-dns-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/dns_records"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List External Events
#
# GET /external_events
# Returns: table<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int>
# operationId: GetExternalEvents
export def "get-external-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[remote_server_type]=desc`). Valid fields are `remote_server_type`, `site_id`, `folder_behavior_id`, `event_type`, `created_at` or `status`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/external_events"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create External Event
#
# POST /external_events
# Returns: record<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int>
# operationId: PostExternalEvents
export def "post-external-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Event body (e.g. example)
  status: string@status-completer # Status of event. (e.g. example)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/external_events"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    body: $body, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show External Event
#
# GET /external_events/{id}
# Returns: record<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int>
# operationId: GetExternalEventsId
export def "get-external-events-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/external_events/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begin file upload
#
# POST /file_actions/begin_upload/{path}
# Returns: table<action: string, ask_about_overwrites: bool, available_parts: int, expires: string, headers: record, http_method: string, next_partsize: int, parallel_parts: bool, parameters: record, part_number: int, partsize: int, path: string, ref: string, send: record, upload_uri: string>
# operationId: FileActionBeginUpload
export def "file-action-begin-upload" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mkdir-parents: oneof<nothing, bool> # Create parent directories if they do not exist?
  --part: int # Part if uploading a part. (format: int32)
  --parts: int # How many parts to fetch? (format: int32)
  --ref: string
  --restart: int # File byte offset to restart from. (format: int32)
  --size: int # Total bytes of file being uploaded (include bytes being retained if appending/restarting). (format: int32)
  --with-rename: oneof<nothing, bool> # Allow file rename instead of overwrite?
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/file_actions/begin_upload/{path}"
    path_params: [{name: path, var: path}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: mkdir_parents, var: mkdir_parents}, {name: part, var: part}, {name: parts, var: parts}, {name: ref, var: ref}, {name: restart, var: restart}, {name: size, var: size}, {name: with_rename, var: with_rename}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, mkdir_parents: $mkdir_parents, part: $part, parts: $parts, ref: $ref, restart: $restart, size: $size, with_rename: $with_rename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy file/folder
#
# POST /file_actions/copy/{path}
# Returns: record<file_migration_id: int, status: string>
# operationId: FileActionCopy
export def "file-action-copy" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string # Copy destination path.
  --structure: oneof<nothing, bool> # Copy structure only?
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/file_actions/copy/{path}"
    path_params: [{name: path, var: path}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: destination, var: destination}, {name: structure, var: structure}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    path: $path, destination: $destination, structure: $structure
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find file/folder by path
#
# GET /file_actions/metadata/{path}
# Returns: record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, "subfolders_locked?": bool, type: string>
# operationId: FileActionFind
export def "file-action-find" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preview-size: string # Request a preview size. Can be `small` (default), `large`, `xlarge`, or `pdf`.
  --with-previews: oneof<nothing, bool> # Include file preview information?
  --with-priority-color: oneof<nothing, bool> # Include file priority color information?
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/file_actions/metadata/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: preview_size, var: preview_size}, {name: with_previews, var: with_previews}, {name: with_priority_color, var: with_priority_color}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, preview_size: $preview_size, with_previews: $with_previews, with_priority_color: $with_priority_color
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move file/folder
#
# POST /file_actions/move/{path}
# Returns: record<file_migration_id: int, status: string>
# operationId: FileActionMove
export def "file-action-move" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string # Move destination path.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/file_actions/move/{path}"
    path_params: [{name: path, var: path}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: destination, var: destination}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    path: $path, destination: $destination
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create File Comment Reaction
#
# POST /file_comment_reactions
# Returns: record<emoji: string, id: int>
# operationId: PostFileCommentReactions
export def "post-file-comment-reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emoji: string # Emoji to react with.
  file_comment_id: int # ID of file comment to attach reaction to. (format: int32)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/file_comment_reactions"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: emoji, var: emoji}, {name: file_comment_id, var: file_comment_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    emoji: $emoji, file_comment_id: $file_comment_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete File Comment Reaction
#
# DELETE /file_comment_reactions/{id}
# operationId: DeleteFileCommentReactionsId
export def "delete-file-comment-reactions-id" [
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
    path: "/file_comment_reactions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create File Comment
#
# POST /file_comments
# Returns: record<body: string, id: int, reactions: table<emoji: string, id: int>>
# operationId: PostFileComments
export def "post-file-comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Comment body.
  path: string # File path.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/file_comments"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    body: $body, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List File Comments by path
#
# GET /file_comments/files/{path}
# Returns: table<body: string, id: int, reactions: list<record>>
# operationId: FileCommentListForPath
export def "file-comment-list-for-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/file_comments/files/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete File Comment
#
# DELETE /file_comments/{id}
# operationId: DeleteFileCommentsId
export def "delete-file-comments-id" [
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
    path: "/file_comments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update File Comment
#
# PATCH /file_comments/{id}
# Returns: record<body: string, id: int, reactions: table<emoji: string, id: int>>
# operationId: PatchFileCommentsId
export def "patch-file-comments-id" [
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
  body: string # Comment body.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/file_comments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show File Migration
#
# GET /file_migrations/{id}
# Returns: record<dest_path: string, files_moved: int, files_total: int, id: int, log_url: string, operation: string, path: string, region: string, status: string>
# operationId: GetFileMigrationsId
export def "get-file-migrations-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/file_migrations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete file/folder
#
# DELETE /files/{path}
# operationId: DeleteFilesPath
export def "delete-files-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # If true, will recursively delete folers. Otherwise, will error on non-empty folders.
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: recursive, var: recursive}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    path: $path, recursive: $recursive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download file
#
# GET /files/{path}
# Returns: record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, "subfolders_locked?": bool, type: string>
# operationId: FileDownload
export def "file-download" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # Can be blank, `redirect` or `stat`. If set to `stat`, we will return file information but without a download URL, and without logging a download. If set to `redirect` we will serve a 302 redirect directly to the file. This is used for integrations with Zapier, and is not recommended for most integrations.
  --preview-size: string # Request a preview size. Can be `small` (default), `large`, `xlarge`, or `pdf`.
  --with-previews: oneof<nothing, bool> # Include file preview information?
  --with-priority-color: oneof<nothing, bool> # Include file priority color information?
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: action, var: action}, {name: preview_size, var: preview_size}, {name: with_previews, var: with_previews}, {name: with_priority_color, var: with_priority_color}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, action: $action, preview_size: $preview_size, with_previews: $with_previews, with_priority_color: $with_priority_color
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update file/folder metadata
#
# PATCH /files/{path}
# Returns: record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, "subfolders_locked?": bool, type: string>
# operationId: PatchFilesPath
export def "patch-files-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --priority-color: string # Priority/Bookmark color of file. (e.g. red)
  --provided-mtime: string # Modified time of file. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/files/{path}"
    path_params: [{name: path, var: path}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: priority_color, var: priority_color}, {name: provided_mtime, var: provided_mtime}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, priority_color: $priority_color, provided_mtime: $provided_mtime
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file
#
# POST /files/{path}
# Returns: record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, "subfolders_locked?": bool, type: string>
# operationId: PostFilesPath
export def "post-files-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # The action to perform. Can be `append`, `attachment`, `end`, `upload`, `put`, or may not exist
  etags_etag: list<string> # etag identifier.
  etags_part: list<int> # Part number.
  --length: int # Length of file. (format: int32)
  --mkdir-parents: oneof<nothing, bool> # Create parent directories if they do not exist?
  --part: int # Part if uploading a part. (format: int32)
  --parts: int # How many parts to fetch? (format: int32)
  --provided-mtime: string # User provided modification time. (format: date-time)
  --ref: string
  --restart: int # File byte offset to restart from. (format: int32)
  --size: int # Size of file. (format: int32)
  --structure: string # If copying folder, copy just the structure?
  --with-rename: oneof<nothing, bool> # Allow file rename instead of overwrite?
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{path}"
    path_params: [{name: path, var: path}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: action, var: action}, {name: "etags[etag]", var: etags_etag}, {name: "etags[part]", var: etags_part}, {name: length, var: length}, {name: mkdir_parents, var: mkdir_parents}, {name: part, var: part}, {name: parts, var: parts}, {name: provided_mtime, var: provided_mtime}, {name: ref, var: ref}, {name: restart, var: restart}, {name: size, var: size}, {name: structure, var: structure}, {name: with_rename, var: with_rename}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    path: $path, action: $action, etags_etag: $etags_etag, etags_part: $etags_part, length: $length, mkdir_parents: $mkdir_parents, part: $part, parts: $parts, provided_mtime: $provided_mtime, ref: $ref, restart: $restart, size: $size, structure: $structure, with_rename: $with_rename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Folders by path
#
# GET /folders/{path}
# Returns: table<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, "subfolders_locked?": bool, type: string>
# operationId: FolderListForPath
export def "folder-list-for-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Send cursor to resume an existing list from the point at which you left off. Get a cursor from an existing list via the X-Files-Cursor-Next header or the X-Files-Cursor-Prev header.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --filter: string # If specified, will filter folders/files list by this string. Wildcards of `*` and `?` are acceptable here.
  --preview-size: string # Request a preview size. Can be `small` (default), `large`, `xlarge`, or `pdf`.
  --search: string # If `search_all` is `true`, provide the search string here. Otherwise, this parameter acts like an alias of `filter`.
  --search-all: oneof<nothing, bool> # Search entire site? If set, we will ignore the folder path provided and search the entire site. This is the same API used by the search bar in the UI. Search results are a best effort, not real time, and not guaranteed to match every file. This field should only be used for ad-hoc (human) searching, and not as part of an automated process.
  --with-previews: oneof<nothing, bool> # Include file previews?
  --with-priority-color: oneof<nothing, bool> # Include file priority color information?
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/folders/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: filter, var: filter}, {name: preview_size, var: preview_size}, {name: search, var: search}, {name: search_all, var: search_all}, {name: with_previews, var: with_previews}, {name: with_priority_color, var: with_priority_color}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, cursor: $cursor, per_page: $per_page, filter: $filter, preview_size: $preview_size, search: $search, search_all: $search_all, with_previews: $with_previews, with_priority_color: $with_priority_color
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create folder
#
# POST /folders/{path}
# Returns: record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, "subfolders_locked?": bool, type: string>
# operationId: PostFoldersPath
export def "post-folders-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mkdir-parents: oneof<nothing, bool> # Create parent directories if they do not exist?
  --provided-mtime: string # User provided modification time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folders/{path}"
    path_params: [{name: path, var: path}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: mkdir_parents, var: mkdir_parents}, {name: provided_mtime, var: provided_mtime}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    path: $path, mkdir_parents: $mkdir_parents, provided_mtime: $provided_mtime
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Form Field Sets
#
# GET /form_field_sets
# Returns: table<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>
# operationId: GetFormFieldSets
export def "get-form-field-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/form_field_sets"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Form Field Set
#
# POST /form_field_sets
# Returns: record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>
# operationId: PostFormFieldSets
export def "post-form-field-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-fields: list # item shape: {default_option?: string, field_type?: string, help_text?: string, id?: int, label?: string, options_for_select?: string, required?: bool}
  --skip-company: oneof<nothing, bool> # Skip validating company
  --skip-email: oneof<nothing, bool> # Skip validating form email
  --skip-name: oneof<nothing, bool> # Skip validating form name
  --title: string # Title to be displayed
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/form_field_sets"
    body: {content_type: "application/json", kind: json, fields: [{name: form_fields, var: form_fields}, {name: skip_company, var: skip_company}, {name: skip_email, var: skip_email}, {name: skip_name, var: skip_name}, {name: title, var: title}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    form_fields: $form_fields, skip_company: $skip_company, skip_email: $skip_email, skip_name: $skip_name, title: $title, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Form Field Set
#
# DELETE /form_field_sets/{id}
# operationId: DeleteFormFieldSetsId
export def "delete-form-field-sets-id" [
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
    path: "/form_field_sets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Form Field Set
#
# GET /form_field_sets/{id}
# Returns: record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>
# operationId: GetFormFieldSetsId
export def "get-form-field-sets-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/form_field_sets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Form Field Set
#
# PATCH /form_field_sets/{id}
# Returns: record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>
# operationId: PatchFormFieldSetsId
export def "patch-form-field-sets-id" [
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
  --form-fields: list # item shape: {default_option?: string, field_type?: string, help_text?: string, id?: int, label?: string, options_for_select?: string, required?: bool}
  --skip-company: oneof<nothing, bool> # Skip validating company
  --skip-email: oneof<nothing, bool> # Skip validating form email
  --skip-name: oneof<nothing, bool> # Skip validating form name
  --title: string # Title to be displayed
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/form_field_sets/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: form_fields, var: form_fields}, {name: skip_company, var: skip_company}, {name: skip_email, var: skip_email}, {name: skip_name, var: skip_name}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, form_fields: $form_fields, skip_company: $skip_company, skip_email: $skip_email, skip_name: $skip_name, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Group Users
#
# GET /group_users
# Returns: table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>
# operationId: GetGroupUsers
export def "get-group-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. If provided, will return group_users of this user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --group-id: int # Group ID. If provided, will return group_users of this group. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/group_users"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Group User
#
# POST /group_users
# Returns: record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>
# operationId: PostGroupUsers
export def "post-group-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin: oneof<nothing, bool> # Is the user a group administrator?
  group_id: int # Group ID to add user to. (format: int32)
  user_id: int # User ID to add to group. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/group_users"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: admin, var: admin}, {name: group_id, var: group_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    admin: $admin, group_id: $group_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Group User
#
# DELETE /group_users/{id}
# operationId: DeleteGroupUsersId
export def "delete-group-users-id" [
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
  --group-id: int # Group ID from which to remove user. (required, format: int32)
  --user-id: int # User ID to remove from group. (required, format: int32)
]: nothing -> any {
  http-request {
    method: delete
    path: "/group_users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: group_id, var: group_id, required: true}, {name: user_id, var: user_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id, group_id: $group_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Group User
#
# PATCH /group_users/{id}
# Returns: record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>
# operationId: PatchGroupUsersId
export def "patch-group-users-id" [
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
  --admin: oneof<nothing, bool> # Is the user a group administrator?
  group_id: int # Group ID to add user to. (format: int32)
  user_id: int # User ID to add to group. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/group_users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: admin, var: admin}, {name: group_id, var: group_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, admin: $admin, group_id: $group_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Groups
#
# GET /groups
# Returns: table<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string>
# operationId: GetGroups
export def "get-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[name]=desc`). Valid fields are `name`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `name`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `name`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `name`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `name`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `name`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `name`.
  --ids: string # Comma-separated list of group ids to include in results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: ids, var: ids}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Group
#
# POST /groups
# Returns: record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string>
# operationId: PostGroups
export def "post-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-ids: string # A list of group admin user ids. If sent as a string, should be comma-delimited.
  --name: string # Group name.
  --notes: string # Group notes.
  --user-ids: string # A list of user ids. If sent as a string, should be comma-delimited.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: admin_ids, var: admin_ids}, {name: name, var: name}, {name: notes, var: notes}, {name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    admin_ids: $admin_ids, name: $name, notes: $notes, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Group User
#
# DELETE /groups/{group_id}/memberships/{user_id}
# operationId: DeleteGroupsGroupIdMembershipsUserId
export def "delete-groups-group-id-memberships-user-id" [
  group_id: int
  user_id: int
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
    path: "/groups/{group_id}/memberships/{user_id}"
    path_params: [{name: group_id, var: group_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    group_id: $group_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Group User
#
# PATCH /groups/{group_id}/memberships/{user_id}
# Returns: record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>
# operationId: PatchGroupsGroupIdMembershipsUserId
export def "patch-groups-group-id-memberships-user-id" [
  group_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin: oneof<nothing, bool> # Is the user a group administrator?
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/groups/{group_id}/memberships/{user_id}"
    path_params: [{name: group_id, var: group_id}, {name: user_id, var: user_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: admin, var: admin}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    group_id: $group_id, user_id: $user_id, admin: $admin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Permissions
#
# GET /groups/{group_id}/permissions
# Returns: table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string>
# operationId: GetGroupsGroupIdPermissions
export def "get-groups-group-id-permissions" [
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
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[group_id]=desc`). Valid fields are `group_id`, `path`, `user_id` or `permission`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --path: string # DEPRECATED: Permission path. If provided, will scope permissions to this path. Use `filter[path]` instead.
  --user-id: string # DEPRECATED: User ID. If provided, will scope permissions to this user. Use `filter[user_id]` instead.`
  --include-groups: oneof<nothing, bool> # If searching by user or group, also include user's permissions that are inherited from its groups?
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group_id}/permissions"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: path, var: path}, {name: user_id, var: user_id}, {name: include_groups, var: include_groups}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    group_id: $group_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, path: $path, user_id: $user_id, include_groups: $include_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Group Users
#
# GET /groups/{group_id}/users
# Returns: table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>
# operationId: GetGroupsGroupIdUsers
export def "get-groups-group-id-users" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. If provided, will return group_users of this user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group_id}/users"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    group_id: $group_id, user_id: $user_id, cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create User
#
# POST /groups/{group_id}/users
# Returns: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>
# operationId: PostGroupsGroupIdUsers
export def "post-groups-group-id-users" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-ips: string # A list of allowed IPs if applicable. Newline delimited (e.g. 127.0.0.1)
  --announcements-read: oneof<nothing, bool> # Signifies that the user has read all the announcements in the UI.
  --attachments-permission: oneof<nothing, bool> # DEPRECATED: Can the user create Bundles (aka Share Links)? Use the bundle permission instead. (e.g. true)
  --authenticate-until: string # Scheduled Date/Time at which user will be deactivated (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --authentication-method: string@authentication-method-completer # How is this user authenticated? (e.g. password)
  --avatar-delete: oneof<nothing, bool> # If true, the avatar will be deleted.
  --avatar-file: string # An image file for your user avatar. (format: binary)
  --billing-permission: oneof<nothing, bool> # Allow this user to perform operations on the account, payments, and invoices?
  --bypass-inactive-disable: oneof<nothing, bool> # Exempt this user from being disabled based on inactivity?
  --bypass-site-allowed-ips: oneof<nothing, bool> # Allow this user to skip site-wide IP blacklists?
  --change-password: string # Used for changing a password on an existing user.
  --change-password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `change_password`.
  --company: string # User's company (e.g. ACME Corp.)
  --dav-permission: oneof<nothing, bool> # Can the user connect with WebDAV? (e.g. true)
  --disabled: oneof<nothing, bool> # Is user disabled? Disabled users cannot log in, and do not count for billing purposes. Users can be automatically disabled after an inactivity period via a Site setting. (e.g. true)
  --email: string # User's email.
  --ftp-permission: oneof<nothing, bool> # Can the user access with FTP/FTPS? (e.g. true)
  --grant-permission: string # Permission to grant on the user root. Can be blank or `full`, `read`, `write`, `list`, or `history`.
  --group-ids: string # A list of group ids to associate this user with. Comma delimited.
  --header-text: string # Text to display to the user in the header of the UI (e.g. User-specific message.)
  --imported-password-hash: string # Pre-calculated hash of the user's password. If supplied, this will be used to authenticate the user on first login. Supported hash menthods are MD5, SHA1, and SHA256.
  --language: string # Preferred language (e.g. en)
  --name: string # User's full name (e.g. John Doe)
  --notes: string # Any internal notes on the user (e.g. Internal notes on this user.)
  --notification-daily-send-time: int # Hour of the day at which daily notifications should be sent. Can be in range 0 to 23 (format: int32, e.g. 18)
  --office-integration-enabled: oneof<nothing, bool> # Enable integration with Office for the web? (e.g. true)
  --password: string # User password.
  --password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `password`.
  --password-validity-days: int # Number of days to allow user to use the same password (format: int32, e.g. 1)
  --receive-admin-alerts: oneof<nothing, bool> # Should the user receive admin alerts such a certificate expiration notifications and overages? (e.g. true)
  --require-2fa: string@require-2fa-completer # 2FA required setting (e.g. always_require)
  --require-password-change: oneof<nothing, bool> # Is a password change required upon next user login? (e.g. true)
  --restapi-permission: oneof<nothing, bool> # Can this user access the REST API? (e.g. true)
  --self-managed: oneof<nothing, bool> # Does this user manage it's own credentials or is it a shared/bot user? (e.g. true)
  --sftp-permission: oneof<nothing, bool> # Can the user access with SFTP? (e.g. true)
  --site-admin: oneof<nothing, bool> # Is the user an administrator for this site? (e.g. true)
  --skip-welcome-screen: oneof<nothing, bool> # Skip Welcome page in the UI? (e.g. true)
  --ssl-required: string@ssl-required-completer # SSL required setting (e.g. always_require)
  --sso-strategy-id: int # SSO (Single Sign On) strategy ID for the user, if applicable. (format: int32, e.g. 1)
  --subscribe-to-newsletter: oneof<nothing, bool> # Is the user subscribed to the newsletter? (e.g. true)
  --time-zone: string # User time zone (e.g. Pacific Time (US & Canada))
  --user-root: string # Root folder for FTP (and optionally SFTP if the appropriate site-wide setting is set.) Note that this is not used for API, Desktop, or Web interface. (e.g. example)
  --username: string # User's username (e.g. user)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{group_id}/users"
    path_params: [{name: group_id, var: group_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allowed_ips, var: allowed_ips}, {name: announcements_read, var: announcements_read}, {name: attachments_permission, var: attachments_permission}, {name: authenticate_until, var: authenticate_until}, {name: authentication_method, var: authentication_method}, {name: avatar_delete, var: avatar_delete}, {name: avatar_file, var: avatar_file}, {name: billing_permission, var: billing_permission}, {name: bypass_inactive_disable, var: bypass_inactive_disable}, {name: bypass_site_allowed_ips, var: bypass_site_allowed_ips}, {name: change_password, var: change_password}, {name: change_password_confirmation, var: change_password_confirmation}, {name: company, var: company}, {name: dav_permission, var: dav_permission}, {name: disabled, var: disabled}, {name: email, var: email}, {name: ftp_permission, var: ftp_permission}, {name: grant_permission, var: grant_permission}, {name: group_ids, var: group_ids}, {name: header_text, var: header_text}, {name: imported_password_hash, var: imported_password_hash}, {name: language, var: language}, {name: name, var: name}, {name: notes, var: notes}, {name: notification_daily_send_time, var: notification_daily_send_time}, {name: office_integration_enabled, var: office_integration_enabled}, {name: password, var: password}, {name: password_confirmation, var: password_confirmation}, {name: password_validity_days, var: password_validity_days}, {name: receive_admin_alerts, var: receive_admin_alerts}, {name: require_2fa, var: require_2fa}, {name: require_password_change, var: require_password_change}, {name: restapi_permission, var: restapi_permission}, {name: self_managed, var: self_managed}, {name: sftp_permission, var: sftp_permission}, {name: site_admin, var: site_admin}, {name: skip_welcome_screen, var: skip_welcome_screen}, {name: ssl_required, var: ssl_required}, {name: sso_strategy_id, var: sso_strategy_id}, {name: subscribe_to_newsletter, var: subscribe_to_newsletter}, {name: time_zone, var: time_zone}, {name: user_root, var: user_root}, {name: username, var: username}], files: [avatar_file]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    group_id: $group_id, allowed_ips: $allowed_ips, announcements_read: $announcements_read, attachments_permission: $attachments_permission, authenticate_until: $authenticate_until, authentication_method: $authentication_method, avatar_delete: $avatar_delete, avatar_file: $avatar_file, billing_permission: $billing_permission, bypass_inactive_disable: $bypass_inactive_disable, bypass_site_allowed_ips: $bypass_site_allowed_ips, change_password: $change_password, change_password_confirmation: $change_password_confirmation, company: $company, dav_permission: $dav_permission, disabled: $disabled, email: $email, ftp_permission: $ftp_permission, grant_permission: $grant_permission, group_ids: $group_ids, header_text: $header_text, imported_password_hash: $imported_password_hash, language: $language, name: $name, notes: $notes, notification_daily_send_time: $notification_daily_send_time, office_integration_enabled: $office_integration_enabled, password: $password, password_confirmation: $password_confirmation, password_validity_days: $password_validity_days, receive_admin_alerts: $receive_admin_alerts, require_2fa: $require_2fa, require_password_change: $require_password_change, restapi_permission: $restapi_permission, self_managed: $self_managed, sftp_permission: $sftp_permission, site_admin: $site_admin, skip_welcome_screen: $skip_welcome_screen, ssl_required: $ssl_required, sso_strategy_id: $sso_strategy_id, subscribe_to_newsletter: $subscribe_to_newsletter, time_zone: $time_zone, user_root: $user_root, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Group
#
# DELETE /groups/{id}
# operationId: DeleteGroupsId
export def "delete-groups-id" [
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
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Group
#
# GET /groups/{id}
# Returns: record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string>
# operationId: GetGroupsId
export def "get-groups-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Group
#
# PATCH /groups/{id}
# Returns: record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string>
# operationId: PatchGroupsId
export def "patch-groups-id" [
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
  --admin-ids: string # A list of group admin user ids. If sent as a string, should be comma-delimited.
  --name: string # Group name.
  --notes: string # Group notes.
  --user-ids: string # A list of user ids. If sent as a string, should be comma-delimited.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: admin_ids, var: admin_ids}, {name: name, var: name}, {name: notes, var: notes}, {name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, admin_ids: $admin_ids, name: $name, notes: $notes, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List site full action history.
#
# GET /history
# Returns: table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>
# operationId: HistoryList
export def "history-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[path]=desc`). Valid fields are `path`, `folder`, `user_id` or `created_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `user_id`, `folder` or `path`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/history"
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}, {name: display, var: display}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    start_at: $start_at, end_at: $end_at, display: $display, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List history for specific file.
#
# GET /history/files/{path}
# Returns: table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>
# operationId: HistoryListForFile
export def "history-list-for-file" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[user_id]=desc`). Valid fields are `user_id` and `created_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/history/files/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}, {name: display, var: display}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, start_at: $start_at, end_at: $end_at, display: $display, cursor: $cursor, per_page: $per_page, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List history for specific folder.
#
# GET /history/folders/{path}
# Returns: table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>
# operationId: HistoryListForFolder
export def "history-list-for-folder" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[user_id]=desc`). Valid fields are `user_id` and `created_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/history/folders/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}, {name: display, var: display}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, start_at: $start_at, end_at: $end_at, display: $display, cursor: $cursor, per_page: $per_page, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List site login history.
#
# GET /history/login
# Returns: table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>
# operationId: HistoryListLogins
export def "history-list-logins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[user_id]=desc`). Valid fields are `user_id` and `created_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/history/login"
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}, {name: display, var: display}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    start_at: $start_at, end_at: $end_at, display: $display, cursor: $cursor, per_page: $per_page, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List history for specific user.
#
# GET /history/users/{user_id}
# Returns: table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string>
# operationId: HistoryListForUser
export def "history-list-for-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[user_id]=desc`). Valid fields are `user_id` and `created_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/history/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}, {name: display, var: display}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, start_at: $start_at, end_at: $end_at, display: $display, cursor: $cursor, per_page: $per_page, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List History Export Results
#
# GET /history_export_results
# Returns: table<action: string, created_at: int, created_at_iso8601: int, destination: string, failure_type: string, file_id: int, folder: string, id: int, interface: string, ip: string, parent_id: int, path: string, src: string, target_expires_at: int, target_id: int, target_name: string, target_permission: string, target_permission_set: string, target_platform: string, target_recursive: bool, target_user_id: int, target_username: string, user_id: int, username: string>
# operationId: GetHistoryExportResults
export def "get-history-export-results" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --history-export-id: int # ID of the associated history export. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/history_export_results"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: history_export_id, var: history_export_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, history_export_id: $history_export_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create History Export
#
# POST /history_exports
# Returns: record<end_at: string, history_version: string, id: int, query_action: string, query_destination: string, query_failure_type: string, query_file_id: string, query_folder: string, query_interface: string, query_ip: string, query_parent_id: string, query_path: string, query_src: string, query_target_id: string, query_target_name: string, query_target_permission: string, query_target_permission_set: string, query_target_platform: string, query_target_user_id: string, query_target_username: string, query_user_id: string, query_username: string, results_url: string, start_at: string, status: string>
# operationId: PostHistoryExports
export def "post-history-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-at: string # End date/time of export range. (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --query-action: string # Filter results by this this action type. Valid values: `create`, `read`, `update`, `destroy`, `move`, `login`, `failedlogin`, `copy`, `user_create`, `user_update`, `user_destroy`, `group_create`, `group_update`, `group_destroy`, `permission_create`, `permission_destroy`, `api_key_create`, `api_key_update`, `api_key_destroy` (e.g. read)
  --query-destination: string # Return results that are file moves with this path as destination. (e.g. DestFolder)
  --query-failure-type: string # If searching for Histories about login failures, this parameter restricts results to failures of this specific type. Valid values: `expired_trial`, `account_overdue`, `locked_out`, `ip_mismatch`, `password_mismatch`, `site_mismatch`, `username_not_found`, `none`, `no_ftp_permission`, `no_web_permission`, `no_directory`, `errno_enoent`, `no_sftp_permission`, `no_dav_permission`, `no_restapi_permission`, `key_mismatch`, `region_mismatch`, `expired_access`, `desktop_ip_mismatch`, `desktop_api_key_not_used_quickly_enough`, `disabled`, `country_mismatch` (e.g. bad_password)
  --query-file-id: string # Return results that are file actions related to the file indicated by this File ID (e.g. 1)
  --query-folder: string # Return results that are file actions related to files or folders inside this folder path. (e.g. Folder)
  --query-interface: string # Filter results by this this interface type. Valid values: `web`, `ftp`, `robot`, `jsapi`, `webdesktopapi`, `sftp`, `dav`, `desktop`, `restapi`, `scim`, `office`, `mobile`, `as2`, `inbound_email`, `remote` (e.g. ftp)
  --query-ip: string # Filter results by this IP address. (e.g. 127.0.0.1)
  --query-parent-id: string # Return results that are file actions inside the parent folder specified by this folder ID (e.g. 1)
  --query-path: string # Return results that are file actions related to this path. (e.g. MyFile.txt)
  --query-src: string # Return results that are file moves originating from this path. (e.g. SrcFolder)
  --query-target-id: string # If searching for Histories about specific objects (such as Users, or API Keys), this paremeter restricts results to objects that match this ID. (e.g. 1)
  --query-target-name: string # If searching for Histories about Users, Groups or other objects with names, this parameter restricts results to objects with this name/username. (e.g. full)
  --query-target-permission: string # If searching for Histories about Permisisons, this parameter restricts results to permissions of this level. (e.g. full)
  --query-target-permission-set: string # If searching for Histories about API keys, this parameter restricts results to API keys with this permission set. (e.g. desktop_app)
  --query-target-platform: string # If searching for Histories about API keys, this parameter restricts results to API keys associated with this platform. (e.g. windows)
  --query-target-user-id: string # If searching for Histories about API keys, this parameter restricts results to API keys created by/for this user ID. (e.g. 1)
  --query-target-username: string # If searching for Histories about API keys, this parameter restricts results to API keys created by/for this username. (e.g. jerry)
  --query-user-id: string # Return results that are actions performed by the user indiciated by this User ID (e.g. 1)
  --query-username: string # Filter results by this username. (e.g. jerry)
  --start-at: string # Start date/time of export range. (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/history_exports"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: end_at, var: end_at}, {name: query_action, var: query_action}, {name: query_destination, var: query_destination}, {name: query_failure_type, var: query_failure_type}, {name: query_file_id, var: query_file_id}, {name: query_folder, var: query_folder}, {name: query_interface, var: query_interface}, {name: query_ip, var: query_ip}, {name: query_parent_id, var: query_parent_id}, {name: query_path, var: query_path}, {name: query_src, var: query_src}, {name: query_target_id, var: query_target_id}, {name: query_target_name, var: query_target_name}, {name: query_target_permission, var: query_target_permission}, {name: query_target_permission_set, var: query_target_permission_set}, {name: query_target_platform, var: query_target_platform}, {name: query_target_user_id, var: query_target_user_id}, {name: query_target_username, var: query_target_username}, {name: query_user_id, var: query_user_id}, {name: query_username, var: query_username}, {name: start_at, var: start_at}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    end_at: $end_at, query_action: $query_action, query_destination: $query_destination, query_failure_type: $query_failure_type, query_file_id: $query_file_id, query_folder: $query_folder, query_interface: $query_interface, query_ip: $query_ip, query_parent_id: $query_parent_id, query_path: $query_path, query_src: $query_src, query_target_id: $query_target_id, query_target_name: $query_target_name, query_target_permission: $query_target_permission, query_target_permission_set: $query_target_permission_set, query_target_platform: $query_target_platform, query_target_user_id: $query_target_user_id, query_target_username: $query_target_username, query_user_id: $query_user_id, query_username: $query_username, start_at: $start_at, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show History Export
#
# GET /history_exports/{id}
# Returns: record<end_at: string, history_version: string, id: int, query_action: string, query_destination: string, query_failure_type: string, query_file_id: string, query_folder: string, query_interface: string, query_ip: string, query_parent_id: string, query_path: string, query_src: string, query_target_id: string, query_target_name: string, query_target_permission: string, query_target_permission_set: string, query_target_platform: string, query_target_user_id: string, query_target_username: string, query_user_id: string, query_username: string, results_url: string, start_at: string, status: string>
# operationId: GetHistoryExportsId
export def "get-history-exports-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history_exports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Inbox Recipients
#
# GET /inbox_recipients
# Returns: table<company: string, name: string, note: string, recipient: string, sent_at: string>
# operationId: GetInboxRecipients
export def "get-inbox-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[has_registrations]=desc`). Valid fields are `has_registrations`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `has_registrations`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `has_registrations`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `has_registrations`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `has_registrations`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `has_registrations`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `has_registrations`.
  --inbox-id: int # List recipients for the inbox with this ID. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/inbox_recipients"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: inbox_id, var: inbox_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, inbox_id: $inbox_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Inbox Recipient
#
# POST /inbox_recipients
# Returns: record<company: string, name: string, note: string, recipient: string, sent_at: string>
# operationId: PostInboxRecipients
export def "post-inbox-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company: string # Company of recipient. (e.g. Acme Ltd)
  inbox_id: int # Inbox to share. (format: int32)
  --name: string # Name of recipient. (e.g. John Smith)
  --note: string # Note to include in email. (e.g. Just a note.)
  recipient: string # Email address to share this inbox with. (e.g. johndoe@gmail.com)
  --share-after-create: oneof<nothing, bool> # Set to true to share the link with the recipient upon creation.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbox_recipients"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: company, var: company}, {name: inbox_id, var: inbox_id}, {name: name, var: name}, {name: note, var: note}, {name: recipient, var: recipient}, {name: share_after_create, var: share_after_create}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    company: $company, inbox_id: $inbox_id, name: $name, note: $note, recipient: $recipient, share_after_create: $share_after_create, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Inbox Registrations
#
# GET /inbox_registrations
# Returns: table<clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_id: int, inbox_recipient_id: int, inbox_title: string, name: string>
# operationId: GetInboxRegistrations
export def "get-inbox-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --folder-behavior-id: int # ID of the associated Inbox. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/inbox_registrations"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: folder_behavior_id, var: folder_behavior_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, folder_behavior_id: $folder_behavior_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Inbox Uploads
#
# GET /inbox_uploads
# Returns: table<created_at: string, inbox_registration: record<clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_id: int, inbox_recipient_id: int, inbox_title: string, name: string>, path: string>
# operationId: GetInboxUploads
export def "get-inbox-uploads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
  --inbox-registration-id: int # InboxRegistration ID (format: int32)
  --inbox-id: int # Inbox ID (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/inbox_uploads"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: inbox_registration_id, var: inbox_registration_id}, {name: inbox_id, var: inbox_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, inbox_registration_id: $inbox_registration_id, inbox_id: $inbox_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Invoices
#
# GET /invoices
# Returns: table<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: list<record>, method: string, payment_line_items: list<record>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string>
# operationId: GetInvoices
export def "get-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/invoices"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Invoice
#
# GET /invoices/{id}
# Returns: record<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: table<amount: float, created_at: string, description: string, plan: string, service_end_at: string, service_start_at: string, site: string, type: string, updated_at: string>, method: string, payment_line_items: table<amount: float, created_at: string, invoice_id: int, payment_id: int>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string>
# operationId: GetInvoicesId
export def "get-invoices-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/invoices/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List IP Addresses associated with the current site
#
# GET /ip_addresses
# Returns: table<associated_with: string, group_id: int, id: string, ip_addresses: list<string>>
# operationId: GetIpAddresses
export def "get-ip-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ip_addresses"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all possible public ExaVault IP addresses
#
# GET /ip_addresses/exavault-reserved
# Returns: table<ftp_enabled: bool, ip_address: string, server_name: string, sftp_enabled: bool>
# operationId: GetIpAddressesExavaultReserved
export def "get-ip-addresses-exavault-reserved" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ip_addresses/exavault-reserved"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all possible public IP addresses
#
# GET /ip_addresses/reserved
# Returns: table<ftp_enabled: bool, ip_address: string, server_name: string, sftp_enabled: bool>
# operationId: GetIpAddressesReserved
export def "get-ip-addresses-reserved" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ip_addresses/reserved"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Lock
#
# DELETE /locks/{path}
# operationId: DeleteLocksPath
export def "delete-locks-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Lock token (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/locks/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    path: $path, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Locks by path
#
# GET /locks/{path}
# Returns: table<allow_access_by_any_user: bool, depth: string, exclusive: bool, owner: string, path: string, recursive: bool, scope: string, timeout: int, token: string, type: string, user_id: int, username: string>
# operationId: LockListForPath
export def "lock-list-for-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --include-children: oneof<nothing, bool> # Include locks from children objects?
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/locks/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: include_children, var: include_children}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, cursor: $cursor, per_page: $per_page, include_children: $include_children
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Lock
#
# POST /locks/{path}
# Returns: record<allow_access_by_any_user: bool, depth: string, exclusive: bool, owner: string, path: string, recursive: bool, scope: string, timeout: int, token: string, type: string, user_id: int, username: string>
# operationId: PostLocksPath
export def "post-locks-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-access-by-any-user: oneof<nothing, bool> # Allow lock to be updated by any user?
  --exclusive: oneof<nothing, bool> # Is lock exclusive?
  --recursive: string # Does lock apply to subfolders?
  --timeout: int # Lock timeout length (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/locks/{path}"
    path_params: [{name: path, var: path}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_access_by_any_user, var: allow_access_by_any_user}, {name: exclusive, var: exclusive}, {name: recursive, var: recursive}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    path: $path, allow_access_by_any_user: $allow_access_by_any_user, exclusive: $exclusive, recursive: $recursive, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Message Comment Reactions
#
# GET /message_comment_reactions
# Returns: table<emoji: string, id: int>
# operationId: GetMessageCommentReactions
export def "get-message-comment-reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --message-comment-id: int # Message comment to return reactions for. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/message_comment_reactions"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: message_comment_id, var: message_comment_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, message_comment_id: $message_comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Message Comment Reaction
#
# POST /message_comment_reactions
# Returns: record<emoji: string, id: int>
# operationId: PostMessageCommentReactions
export def "post-message-comment-reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emoji: string # Emoji to react with.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/message_comment_reactions"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: emoji, var: emoji}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    emoji: $emoji, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Message Comment Reaction
#
# DELETE /message_comment_reactions/{id}
# operationId: DeleteMessageCommentReactionsId
export def "delete-message-comment-reactions-id" [
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
    path: "/message_comment_reactions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Message Comment Reaction
#
# GET /message_comment_reactions/{id}
# Returns: record<emoji: string, id: int>
# operationId: GetMessageCommentReactionsId
export def "get-message-comment-reactions-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/message_comment_reactions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Message Comments
#
# GET /message_comments
# Returns: table<body: string, id: int, reactions: list<record>>
# operationId: GetMessageComments
export def "get-message-comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --message-id: int # Message comment to return comments for. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/message_comments"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: message_id, var: message_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Message Comment
#
# POST /message_comments
# Returns: record<body: string, id: int, reactions: table<emoji: string, id: int>>
# operationId: PostMessageComments
export def "post-message-comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Comment body.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/message_comments"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    body: $body, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Message Comment
#
# DELETE /message_comments/{id}
# operationId: DeleteMessageCommentsId
export def "delete-message-comments-id" [
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
    path: "/message_comments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Message Comment
#
# GET /message_comments/{id}
# Returns: record<body: string, id: int, reactions: table<emoji: string, id: int>>
# operationId: GetMessageCommentsId
export def "get-message-comments-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/message_comments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Message Comment
#
# PATCH /message_comments/{id}
# Returns: record<body: string, id: int, reactions: table<emoji: string, id: int>>
# operationId: PatchMessageCommentsId
export def "patch-message-comments-id" [
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
  body: string # Comment body.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/message_comments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Message Reactions
#
# GET /message_reactions
# Returns: table<emoji: string, id: int>
# operationId: GetMessageReactions
export def "get-message-reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --message-id: int # Message to return reactions for. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/message_reactions"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: message_id, var: message_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Message Reaction
#
# POST /message_reactions
# Returns: record<emoji: string, id: int>
# operationId: PostMessageReactions
export def "post-message-reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emoji: string # Emoji to react with.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/message_reactions"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: emoji, var: emoji}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    emoji: $emoji, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Message Reaction
#
# DELETE /message_reactions/{id}
# operationId: DeleteMessageReactionsId
export def "delete-message-reactions-id" [
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
    path: "/message_reactions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Message Reaction
#
# GET /message_reactions/{id}
# Returns: record<emoji: string, id: int>
# operationId: GetMessageReactionsId
export def "get-message-reactions-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/message_reactions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Messages
#
# GET /messages
# Returns: table<body: string, comments: list<record>, id: int, subject: string>
# operationId: GetMessages
export def "get-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --project-id: int # Project for which to return messages. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/messages"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: project_id, var: project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Message
#
# POST /messages
# Returns: record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string>
# operationId: PostMessages
export def "post-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Message body. (e.g. We should upgrade our Files.com account!)
  project_id: int # Project to which the message should be attached. (format: int32)
  subject: string # Message subject. (e.g. Files.com Account Upgrade)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}, {name: project_id, var: project_id}, {name: subject, var: subject}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    body: $body, project_id: $project_id, subject: $subject, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Message
#
# DELETE /messages/{id}
# operationId: DeleteMessagesId
export def "delete-messages-id" [
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
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Message
#
# GET /messages/{id}
# Returns: record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string>
# operationId: GetMessagesId
export def "get-messages-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Message
#
# PATCH /messages/{id}
# Returns: record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string>
# operationId: PatchMessagesId
export def "patch-messages-id" [
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
  body: string # Message body. (e.g. We should upgrade our Files.com account!)
  project_id: int # Project to which the message should be attached. (format: int32)
  subject: string # Message subject. (e.g. Files.com Account Upgrade)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: body, var: body}, {name: project_id, var: project_id}, {name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, body: $body, project_id: $project_id, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Notifications
#
# GET /notifications
# Returns: table<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string>
# operationId: GetNotifications
export def "get-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # DEPRECATED: Show notifications for this User ID. Use `filter[user_id]` instead. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[path]=desc`). Valid fields are `path`, `user_id` or `group_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --group-id: int # DEPRECATED: Show notifications for this Group ID. Use `filter[group_id]` instead. (format: int32)
  --path: string # Show notifications for this Path.
  --include-ancestors: oneof<nothing, bool> # If `include_ancestors` is `true` and `path` is specified, include notifications for any parent paths. Ignored if `path` is not specified.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/notifications"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: group_id, var: group_id}, {name: path, var: path}, {name: include_ancestors, var: include_ancestors}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, group_id: $group_id, path: $path, include_ancestors: $include_ancestors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Notification
#
# POST /notifications
# Returns: record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string>
# operationId: PostNotifications
export def "post-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # The ID of the group to notify. Provide `user_id`, `username` or `group_id`. (format: int32)
  --message: string # Custom message to include in notification emails. (e.g. custom notification email message)
  --notify-on-copy: oneof<nothing, bool> # If `true`, copying or moving resources into this path will trigger a notification, in addition to just uploads.
  --notify-on-delete: oneof<nothing, bool> # Triggers notification when deleting files from this path (e.g. true)
  --notify-on-download: oneof<nothing, bool> # Triggers notification when downloading files from this path (e.g. true)
  --notify-on-move: oneof<nothing, bool> # Triggers notification when moving files to this path (e.g. true)
  --notify-on-upload: oneof<nothing, bool> # Triggers notification when uploading new files to this path (e.g. true)
  --notify-user-actions: oneof<nothing, bool> # If `true` actions initiated by the user will still result in a notification
  --path: string # Path
  --recursive: oneof<nothing, bool> # If `true`, enable notifications for each subfolder in this path
  --send-interval: string # The time interval that notifications are aggregated by. Can be `five_minutes`, `fifteen_minutes`, `hourly`, or `daily`. (e.g. daily)
  --trigger-by-share-recipients: oneof<nothing, bool> # Notify when actions are performed by a share recipient? (e.g. true)
  --triggering-filenames: list<string> # Array of filenames (possibly with wildcards) to match for action path (e.g. [*.jpg, notify_file.txt])
  --triggering-group-ids: list<int> # Only notify on actions made by a member of one of the specified groups (e.g. [1])
  --triggering-user-ids: list<int> # Only notify on actions made one of the specified users (e.g. [1])
  --user-id: int # The id of the user to notify. Provide `user_id`, `username` or `group_id`. (format: int32)
  --username: string # The username of the user to notify. Provide `user_id`, `username` or `group_id`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notifications"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: group_id, var: group_id}, {name: message, var: message}, {name: notify_on_copy, var: notify_on_copy}, {name: notify_on_delete, var: notify_on_delete}, {name: notify_on_download, var: notify_on_download}, {name: notify_on_move, var: notify_on_move}, {name: notify_on_upload, var: notify_on_upload}, {name: notify_user_actions, var: notify_user_actions}, {name: path, var: path}, {name: recursive, var: recursive}, {name: send_interval, var: send_interval}, {name: trigger_by_share_recipients, var: trigger_by_share_recipients}, {name: triggering_filenames, var: triggering_filenames}, {name: triggering_group_ids, var: triggering_group_ids}, {name: triggering_user_ids, var: triggering_user_ids}, {name: user_id, var: user_id}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    group_id: $group_id, message: $message, notify_on_copy: $notify_on_copy, notify_on_delete: $notify_on_delete, notify_on_download: $notify_on_download, notify_on_move: $notify_on_move, notify_on_upload: $notify_on_upload, notify_user_actions: $notify_user_actions, path: $path, recursive: $recursive, send_interval: $send_interval, trigger_by_share_recipients: $trigger_by_share_recipients, triggering_filenames: $triggering_filenames, triggering_group_ids: $triggering_group_ids, triggering_user_ids: $triggering_user_ids, user_id: $user_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Notification
#
# DELETE /notifications/{id}
# operationId: DeleteNotificationsId
export def "delete-notifications-id" [
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
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Notification
#
# GET /notifications/{id}
# Returns: record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string>
# operationId: GetNotificationsId
export def "get-notifications-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Notification
#
# PATCH /notifications/{id}
# Returns: record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string>
# operationId: PatchNotificationsId
export def "patch-notifications-id" [
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
  --message: string # Custom message to include in notification emails. (e.g. custom notification email message)
  --notify-on-copy: oneof<nothing, bool> # If `true`, copying or moving resources into this path will trigger a notification, in addition to just uploads.
  --notify-on-delete: oneof<nothing, bool> # Triggers notification when deleting files from this path (e.g. true)
  --notify-on-download: oneof<nothing, bool> # Triggers notification when downloading files from this path (e.g. true)
  --notify-on-move: oneof<nothing, bool> # Triggers notification when moving files to this path (e.g. true)
  --notify-on-upload: oneof<nothing, bool> # Triggers notification when uploading new files to this path (e.g. true)
  --notify-user-actions: oneof<nothing, bool> # If `true` actions initiated by the user will still result in a notification
  --recursive: oneof<nothing, bool> # If `true`, enable notifications for each subfolder in this path
  --send-interval: string # The time interval that notifications are aggregated by. Can be `five_minutes`, `fifteen_minutes`, `hourly`, or `daily`. (e.g. daily)
  --trigger-by-share-recipients: oneof<nothing, bool> # Notify when actions are performed by a share recipient? (e.g. true)
  --triggering-filenames: list<string> # Array of filenames (possibly with wildcards) to match for action path (e.g. [*.jpg, notify_file.txt])
  --triggering-group-ids: list<int> # Only notify on actions made by a member of one of the specified groups (e.g. [1])
  --triggering-user-ids: list<int> # Only notify on actions made one of the specified users (e.g. [1])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: message, var: message}, {name: notify_on_copy, var: notify_on_copy}, {name: notify_on_delete, var: notify_on_delete}, {name: notify_on_download, var: notify_on_download}, {name: notify_on_move, var: notify_on_move}, {name: notify_on_upload, var: notify_on_upload}, {name: notify_user_actions, var: notify_user_actions}, {name: recursive, var: recursive}, {name: send_interval, var: send_interval}, {name: trigger_by_share_recipients, var: trigger_by_share_recipients}, {name: triggering_filenames, var: triggering_filenames}, {name: triggering_group_ids, var: triggering_group_ids}, {name: triggering_user_ids, var: triggering_user_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, message: $message, notify_on_copy: $notify_on_copy, notify_on_delete: $notify_on_delete, notify_on_download: $notify_on_download, notify_on_move: $notify_on_move, notify_on_upload: $notify_on_upload, notify_user_actions: $notify_user_actions, recursive: $recursive, send_interval: $send_interval, trigger_by_share_recipients: $trigger_by_share_recipients, triggering_filenames: $triggering_filenames, triggering_group_ids: $triggering_group_ids, triggering_user_ids: $triggering_user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payments
#
# GET /payments
# Returns: table<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: list<record>, method: string, payment_line_items: list<record>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string>
# operationId: GetPayments
export def "get-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/payments"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Payment
#
# GET /payments/{id}
# Returns: record<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: table<amount: float, created_at: string, description: string, plan: string, service_end_at: string, service_start_at: string, site: string, type: string, updated_at: string>, method: string, payment_line_items: table<amount: float, created_at: string, invoice_id: int, payment_id: int>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string>
# operationId: GetPaymentsId
export def "get-payments-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Permissions
#
# GET /permissions
# Returns: table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string>
# operationId: GetPermissions
export def "get-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[group_id]=desc`). Valid fields are `group_id`, `path`, `user_id` or `permission`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --path: string # DEPRECATED: Permission path. If provided, will scope permissions to this path. Use `filter[path]` instead.
  --group-id: string # DEPRECATED: Group ID. If provided, will scope permissions to this group. Use `filter[group_id]` instead.`
  --user-id: string # DEPRECATED: User ID. If provided, will scope permissions to this user. Use `filter[user_id]` instead.`
  --include-groups: oneof<nothing, bool> # If searching by user or group, also include user's permissions that are inherited from its groups?
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/permissions"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: path, var: path}, {name: group_id, var: group_id}, {name: user_id, var: user_id}, {name: include_groups, var: include_groups}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, path: $path, group_id: $group_id, user_id: $user_id, include_groups: $include_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Permission
#
# POST /permissions
# Returns: record<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string>
# operationId: PostPermissions
export def "post-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Group ID (format: int32)
  --path: string # Folder path
  --permission: string # Permission type. Can be `admin`, `full`, `readonly`, `writeonly`, `list`, or `history`
  --recursive: oneof<nothing, bool> # Apply to subfolders recursively?
  --user-id: int # User ID. Provide `username` or `user_id` (format: int32)
  --username: string # User username. Provide `username` or `user_id`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/permissions"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: group_id, var: group_id}, {name: path, var: path}, {name: permission, var: permission}, {name: recursive, var: recursive}, {name: user_id, var: user_id}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    group_id: $group_id, path: $path, permission: $permission, recursive: $recursive, user_id: $user_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Permission
#
# DELETE /permissions/{id}
# operationId: DeletePermissionsId
export def "delete-permissions-id" [
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
    path: "/permissions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Priorities
#
# GET /priorities
# Returns: table<color: string, path: string>
# operationId: GetPriorities
export def "get-priorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --path: string # The path to query for priorities (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/priorities"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: path, var: path, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Projects
#
# GET /projects
# Returns: table<global_access: string, id: int>
# operationId: GetProjects
export def "get-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Project
#
# POST /projects
# Returns: record<global_access: string, id: int>
# operationId: PostProjects
export def "post-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  global_access: string # Global permissions. Can be: `none`, `anyone_with_read`, `anyone_with_full`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: global_access, var: global_access}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    global_access: $global_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Project
#
# DELETE /projects/{id}
# operationId: DeleteProjectsId
export def "delete-projects-id" [
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
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Project
#
# GET /projects/{id}
# Returns: record<global_access: string, id: int>
# operationId: GetProjectsId
export def "get-projects-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Project
#
# PATCH /projects/{id}
# Returns: record<global_access: string, id: int>
# operationId: PatchProjectsId
export def "patch-projects-id" [
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
  global_access: string # Global permissions. Can be: `none`, `anyone_with_read`, `anyone_with_full`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: global_access, var: global_access}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, global_access: $global_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Public Keys
#
# GET /public_keys
# Returns: table<created_at: string, fingerprint: string, id: int, title: string>
# operationId: GetPublicKeys
export def "get-public-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/public_keys"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Public Key
#
# POST /public_keys
# Returns: record<created_at: string, fingerprint: string, id: int, title: string>
# operationId: PostPublicKeys
export def "post-public-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  public_key: string # Actual contents of SSH key.
  title: string # Internal reference for key. (e.g. My Main Key)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/public_keys"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: public_key, var: public_key}, {name: title, var: title}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    public_key: $public_key, title: $title, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Public Key
#
# DELETE /public_keys/{id}
# operationId: DeletePublicKeysId
export def "delete-public-keys-id" [
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
    path: "/public_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Public Key
#
# GET /public_keys/{id}
# Returns: record<created_at: string, fingerprint: string, id: int, title: string>
# operationId: GetPublicKeysId
export def "get-public-keys-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/public_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Public Key
#
# PATCH /public_keys/{id}
# Returns: record<created_at: string, fingerprint: string, id: int, title: string>
# operationId: PatchPublicKeysId
export def "patch-public-keys-id" [
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
  title: string # Internal reference for key. (e.g. My Main Key)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/public_keys/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Remote Bandwidth Snapshots
#
# GET /remote_bandwidth_snapshots
# Returns: table<id: int, logged_at: string, remote_server_id: int, sync_bytes_received: float, sync_bytes_sent: float>
# operationId: GetRemoteBandwidthSnapshots
export def "get-remote-bandwidth-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[logged_at]=desc`). Valid fields are `logged_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `logged_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `logged_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `logged_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `logged_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `logged_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `logged_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/remote_bandwidth_snapshots"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Remote Servers
#
# GET /remote_servers
# Returns: table<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string>
# operationId: GetRemoteServers
export def "get-remote-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/remote_servers"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Remote Server
#
# POST /remote_servers
# Returns: record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string>
# operationId: PostRemoteServers
export def "post-remote-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key: string # AWS Access Key. (e.g. example)
  --aws-secret-key: string # AWS secret key.
  --azure-blob-storage-access-key: string # Azure Blob Storage secret key.
  --azure-blob-storage-account: string # Azure Blob Storage Account name (e.g. storage-account-name)
  --azure-blob-storage-container: string # Azure Blob Storage Container name (e.g. container-name)
  --azure-blob-storage-sas-token: string # Shared Access Signature (SAS) token (e.g. storage-sas-token)
  --azure-files-storage-access-key: string # Azure File Storage access key.
  --azure-files-storage-account: string # Azure File Storage Account name (e.g. storage-account-name)
  --azure-files-storage-sas-token: string # Shared Access Signature (SAS) token (e.g. storage-sas-token)
  --azure-files-storage-share-name: string # Azure File Storage Share name (e.g. share-name)
  --backblaze-b2-application-key: string # Backblaze B2 Cloud Storage applicationKey.
  --backblaze-b2-bucket: string # Backblaze B2 Cloud Storage Bucket name (e.g. my-bucket)
  --backblaze-b2-key-id: string # Backblaze B2 Cloud Storage keyID.
  --backblaze-b2-s3-endpoint: string # Backblaze B2 Cloud Storage S3 Endpoint (e.g. s3.us-west-001.backblazeb2.com)
  --enable-dedicated-ips: oneof<nothing, bool> # `true` if remote server only accepts connections from dedicated IPs (e.g. true)
  --filebase-access-key: string # Filebase Access Key. (e.g. example)
  --filebase-bucket: string # Filebase Bucket name (e.g. my-bucket)
  --filebase-secret-key: string # Filebase secret key
  --files-agent-permission-set: string@files-agent-permission-set-completer # Local permissions for files agent. read_only, write_only, or read_write (e.g. read_write)
  --files-agent-root: string # Agent local root path (e.g. example)
  --google-cloud-storage-bucket: string # Google Cloud Storage bucket name (e.g. my-bucket)
  --google-cloud-storage-credentials-json: string # A JSON file that contains the private key. To generate see https://cloud.google.com/storage/docs/json_api/v1/how-tos/authorizing#APIKey
  --google-cloud-storage-project-id: string # Google Cloud Project ID (e.g. my-project)
  --hostname: string # Hostname or IP address (e.g. remote-server.com)
  --max-connections: int # Max number of parallel connections. Ignored for S3 connections (we will parallelize these as much as possible). (format: int32, e.g. 1)
  --name: string # Internal name for your reference (e.g. My Remote server)
  --one-drive-account-type: string@one-drive-account-type-completer # Either personal or business_other account types (e.g. personal)
  --password: string # Password if needed.
  --pin-to-site-region: oneof<nothing, bool> # If true, we will ensure that all communications with this remote server are made through the primary region of the site. This setting can also be overridden by a sitewide setting which will force it to true. (e.g. true)
  --port: int # Port for remote server. Not needed for S3. (format: int32, e.g. 1)
  --private-key: string # Private key if needed.
  --private-key-passphrase: string # Passphrase for private key if needed.
  --rackspace-api-key: string # Rackspace API key from the Rackspace Cloud Control Panel.
  --rackspace-container: string # The name of the container (top level directory) where files will sync. (e.g. my-container)
  --rackspace-region: string # Three letter airport code for Rackspace region. See https://support.rackspace.com/how-to/about-regions/ (e.g. dfw)
  --rackspace-username: string # Rackspace username used to login to the Rackspace Cloud Control Panel. (e.g. rackspaceuser)
  --reset-authentication: oneof<nothing, bool> # Reset authenticated account
  --s3-bucket: string # S3 bucket name (e.g. my-bucket)
  --s3-compatible-access-key: string # S3-compatible Access Key. (e.g. example)
  --s3-compatible-bucket: string # S3-compatible Bucket name (e.g. my-bucket)
  --s3-compatible-endpoint: string # S3-compatible endpoint (e.g. mys3platform.com)
  --s3-compatible-region: string # S3-compatible endpoint (e.g. us-east-1)
  --s3-compatible-secret-key: string # S3-compatible secret key
  --s3-region: string # S3 region (e.g. us-east-1)
  --server-certificate: string@server-certificate-completer # Remote server certificate (e.g. require_match)
  --server-host-key: string # Remote server SSH Host Key. If provided, we will require that the server host key matches the provided key. Uses OpenSSH format similar to what would go into ~/.ssh/known_hosts (e.g. [public key])
  --server-type: string@server-type-completer # Remote server type. (e.g. s3)
  --ssl: string@ssl-completer # Should we require SSL? (e.g. if_available)
  --ssl-certificate: string # SSL client certificate.
  --username: string # Remote server username. Not needed for S3 buckets. (e.g. user)
  --wasabi-access-key: string # Wasabi access key. (e.g. example)
  --wasabi-bucket: string # Wasabi Bucket name (e.g. my-bucket)
  --wasabi-region: string # Wasabi region (e.g. us-west-1)
  --wasabi-secret-key: string # Wasabi secret key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/remote_servers"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: aws_access_key, var: aws_access_key}, {name: aws_secret_key, var: aws_secret_key}, {name: azure_blob_storage_access_key, var: azure_blob_storage_access_key}, {name: azure_blob_storage_account, var: azure_blob_storage_account}, {name: azure_blob_storage_container, var: azure_blob_storage_container}, {name: azure_blob_storage_sas_token, var: azure_blob_storage_sas_token}, {name: azure_files_storage_access_key, var: azure_files_storage_access_key}, {name: azure_files_storage_account, var: azure_files_storage_account}, {name: azure_files_storage_sas_token, var: azure_files_storage_sas_token}, {name: azure_files_storage_share_name, var: azure_files_storage_share_name}, {name: backblaze_b2_application_key, var: backblaze_b2_application_key}, {name: backblaze_b2_bucket, var: backblaze_b2_bucket}, {name: backblaze_b2_key_id, var: backblaze_b2_key_id}, {name: backblaze_b2_s3_endpoint, var: backblaze_b2_s3_endpoint}, {name: enable_dedicated_ips, var: enable_dedicated_ips}, {name: filebase_access_key, var: filebase_access_key}, {name: filebase_bucket, var: filebase_bucket}, {name: filebase_secret_key, var: filebase_secret_key}, {name: files_agent_permission_set, var: files_agent_permission_set}, {name: files_agent_root, var: files_agent_root}, {name: google_cloud_storage_bucket, var: google_cloud_storage_bucket}, {name: google_cloud_storage_credentials_json, var: google_cloud_storage_credentials_json}, {name: google_cloud_storage_project_id, var: google_cloud_storage_project_id}, {name: hostname, var: hostname}, {name: max_connections, var: max_connections}, {name: name, var: name}, {name: one_drive_account_type, var: one_drive_account_type}, {name: password, var: password}, {name: pin_to_site_region, var: pin_to_site_region}, {name: port, var: port}, {name: private_key, var: private_key}, {name: private_key_passphrase, var: private_key_passphrase}, {name: rackspace_api_key, var: rackspace_api_key}, {name: rackspace_container, var: rackspace_container}, {name: rackspace_region, var: rackspace_region}, {name: rackspace_username, var: rackspace_username}, {name: reset_authentication, var: reset_authentication}, {name: s3_bucket, var: s3_bucket}, {name: s3_compatible_access_key, var: s3_compatible_access_key}, {name: s3_compatible_bucket, var: s3_compatible_bucket}, {name: s3_compatible_endpoint, var: s3_compatible_endpoint}, {name: s3_compatible_region, var: s3_compatible_region}, {name: s3_compatible_secret_key, var: s3_compatible_secret_key}, {name: s3_region, var: s3_region}, {name: server_certificate, var: server_certificate}, {name: server_host_key, var: server_host_key}, {name: server_type, var: server_type}, {name: ssl, var: ssl}, {name: ssl_certificate, var: ssl_certificate}, {name: username, var: username}, {name: wasabi_access_key, var: wasabi_access_key}, {name: wasabi_bucket, var: wasabi_bucket}, {name: wasabi_region, var: wasabi_region}, {name: wasabi_secret_key, var: wasabi_secret_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    aws_access_key: $aws_access_key, aws_secret_key: $aws_secret_key, azure_blob_storage_access_key: $azure_blob_storage_access_key, azure_blob_storage_account: $azure_blob_storage_account, azure_blob_storage_container: $azure_blob_storage_container, azure_blob_storage_sas_token: $azure_blob_storage_sas_token, azure_files_storage_access_key: $azure_files_storage_access_key, azure_files_storage_account: $azure_files_storage_account, azure_files_storage_sas_token: $azure_files_storage_sas_token, azure_files_storage_share_name: $azure_files_storage_share_name, backblaze_b2_application_key: $backblaze_b2_application_key, backblaze_b2_bucket: $backblaze_b2_bucket, backblaze_b2_key_id: $backblaze_b2_key_id, backblaze_b2_s3_endpoint: $backblaze_b2_s3_endpoint, enable_dedicated_ips: $enable_dedicated_ips, filebase_access_key: $filebase_access_key, filebase_bucket: $filebase_bucket, filebase_secret_key: $filebase_secret_key, files_agent_permission_set: $files_agent_permission_set, files_agent_root: $files_agent_root, google_cloud_storage_bucket: $google_cloud_storage_bucket, google_cloud_storage_credentials_json: $google_cloud_storage_credentials_json, google_cloud_storage_project_id: $google_cloud_storage_project_id, hostname: $hostname, max_connections: $max_connections, name: $name, one_drive_account_type: $one_drive_account_type, password: $password, pin_to_site_region: $pin_to_site_region, port: $port, private_key: $private_key, private_key_passphrase: $private_key_passphrase, rackspace_api_key: $rackspace_api_key, rackspace_container: $rackspace_container, rackspace_region: $rackspace_region, rackspace_username: $rackspace_username, reset_authentication: $reset_authentication, s3_bucket: $s3_bucket, s3_compatible_access_key: $s3_compatible_access_key, s3_compatible_bucket: $s3_compatible_bucket, s3_compatible_endpoint: $s3_compatible_endpoint, s3_compatible_region: $s3_compatible_region, s3_compatible_secret_key: $s3_compatible_secret_key, s3_region: $s3_region, server_certificate: $server_certificate, server_host_key: $server_host_key, server_type: $server_type, ssl: $ssl, ssl_certificate: $ssl_certificate, username: $username, wasabi_access_key: $wasabi_access_key, wasabi_bucket: $wasabi_bucket, wasabi_region: $wasabi_region, wasabi_secret_key: $wasabi_secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Remote Server
#
# DELETE /remote_servers/{id}
# operationId: DeleteRemoteServersId
export def "delete-remote-servers-id" [
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
    path: "/remote_servers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Remote Server
#
# GET /remote_servers/{id}
# Returns: record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string>
# operationId: GetRemoteServersId
export def "get-remote-servers-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/remote_servers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Remote Server
#
# PATCH /remote_servers/{id}
# Returns: record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string>
# operationId: PatchRemoteServersId
export def "patch-remote-servers-id" [
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
  --aws-access-key: string # AWS Access Key. (e.g. example)
  --aws-secret-key: string # AWS secret key.
  --azure-blob-storage-access-key: string # Azure Blob Storage secret key.
  --azure-blob-storage-account: string # Azure Blob Storage Account name (e.g. storage-account-name)
  --azure-blob-storage-container: string # Azure Blob Storage Container name (e.g. container-name)
  --azure-blob-storage-sas-token: string # Shared Access Signature (SAS) token (e.g. storage-sas-token)
  --azure-files-storage-access-key: string # Azure File Storage access key.
  --azure-files-storage-account: string # Azure File Storage Account name (e.g. storage-account-name)
  --azure-files-storage-sas-token: string # Shared Access Signature (SAS) token (e.g. storage-sas-token)
  --azure-files-storage-share-name: string # Azure File Storage Share name (e.g. share-name)
  --backblaze-b2-application-key: string # Backblaze B2 Cloud Storage applicationKey.
  --backblaze-b2-bucket: string # Backblaze B2 Cloud Storage Bucket name (e.g. my-bucket)
  --backblaze-b2-key-id: string # Backblaze B2 Cloud Storage keyID.
  --backblaze-b2-s3-endpoint: string # Backblaze B2 Cloud Storage S3 Endpoint (e.g. s3.us-west-001.backblazeb2.com)
  --enable-dedicated-ips: oneof<nothing, bool> # `true` if remote server only accepts connections from dedicated IPs (e.g. true)
  --filebase-access-key: string # Filebase Access Key. (e.g. example)
  --filebase-bucket: string # Filebase Bucket name (e.g. my-bucket)
  --filebase-secret-key: string # Filebase secret key
  --files-agent-permission-set: string@files-agent-permission-set-completer # Local permissions for files agent. read_only, write_only, or read_write (e.g. read_write)
  --files-agent-root: string # Agent local root path (e.g. example)
  --google-cloud-storage-bucket: string # Google Cloud Storage bucket name (e.g. my-bucket)
  --google-cloud-storage-credentials-json: string # A JSON file that contains the private key. To generate see https://cloud.google.com/storage/docs/json_api/v1/how-tos/authorizing#APIKey
  --google-cloud-storage-project-id: string # Google Cloud Project ID (e.g. my-project)
  --hostname: string # Hostname or IP address (e.g. remote-server.com)
  --max-connections: int # Max number of parallel connections. Ignored for S3 connections (we will parallelize these as much as possible). (format: int32, e.g. 1)
  --name: string # Internal name for your reference (e.g. My Remote server)
  --one-drive-account-type: string@one-drive-account-type-completer # Either personal or business_other account types (e.g. personal)
  --password: string # Password if needed.
  --pin-to-site-region: oneof<nothing, bool> # If true, we will ensure that all communications with this remote server are made through the primary region of the site. This setting can also be overridden by a sitewide setting which will force it to true. (e.g. true)
  --port: int # Port for remote server. Not needed for S3. (format: int32, e.g. 1)
  --private-key: string # Private key if needed.
  --private-key-passphrase: string # Passphrase for private key if needed.
  --rackspace-api-key: string # Rackspace API key from the Rackspace Cloud Control Panel.
  --rackspace-container: string # The name of the container (top level directory) where files will sync. (e.g. my-container)
  --rackspace-region: string # Three letter airport code for Rackspace region. See https://support.rackspace.com/how-to/about-regions/ (e.g. dfw)
  --rackspace-username: string # Rackspace username used to login to the Rackspace Cloud Control Panel. (e.g. rackspaceuser)
  --reset-authentication: oneof<nothing, bool> # Reset authenticated account
  --s3-bucket: string # S3 bucket name (e.g. my-bucket)
  --s3-compatible-access-key: string # S3-compatible Access Key. (e.g. example)
  --s3-compatible-bucket: string # S3-compatible Bucket name (e.g. my-bucket)
  --s3-compatible-endpoint: string # S3-compatible endpoint (e.g. mys3platform.com)
  --s3-compatible-region: string # S3-compatible endpoint (e.g. us-east-1)
  --s3-compatible-secret-key: string # S3-compatible secret key
  --s3-region: string # S3 region (e.g. us-east-1)
  --server-certificate: string@server-certificate-completer # Remote server certificate (e.g. require_match)
  --server-host-key: string # Remote server SSH Host Key. If provided, we will require that the server host key matches the provided key. Uses OpenSSH format similar to what would go into ~/.ssh/known_hosts (e.g. [public key])
  --server-type: string@server-type-completer # Remote server type. (e.g. s3)
  --ssl: string@ssl-completer # Should we require SSL? (e.g. if_available)
  --ssl-certificate: string # SSL client certificate.
  --username: string # Remote server username. Not needed for S3 buckets. (e.g. user)
  --wasabi-access-key: string # Wasabi access key. (e.g. example)
  --wasabi-bucket: string # Wasabi Bucket name (e.g. my-bucket)
  --wasabi-region: string # Wasabi region (e.g. us-west-1)
  --wasabi-secret-key: string # Wasabi secret key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/remote_servers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: aws_access_key, var: aws_access_key}, {name: aws_secret_key, var: aws_secret_key}, {name: azure_blob_storage_access_key, var: azure_blob_storage_access_key}, {name: azure_blob_storage_account, var: azure_blob_storage_account}, {name: azure_blob_storage_container, var: azure_blob_storage_container}, {name: azure_blob_storage_sas_token, var: azure_blob_storage_sas_token}, {name: azure_files_storage_access_key, var: azure_files_storage_access_key}, {name: azure_files_storage_account, var: azure_files_storage_account}, {name: azure_files_storage_sas_token, var: azure_files_storage_sas_token}, {name: azure_files_storage_share_name, var: azure_files_storage_share_name}, {name: backblaze_b2_application_key, var: backblaze_b2_application_key}, {name: backblaze_b2_bucket, var: backblaze_b2_bucket}, {name: backblaze_b2_key_id, var: backblaze_b2_key_id}, {name: backblaze_b2_s3_endpoint, var: backblaze_b2_s3_endpoint}, {name: enable_dedicated_ips, var: enable_dedicated_ips}, {name: filebase_access_key, var: filebase_access_key}, {name: filebase_bucket, var: filebase_bucket}, {name: filebase_secret_key, var: filebase_secret_key}, {name: files_agent_permission_set, var: files_agent_permission_set}, {name: files_agent_root, var: files_agent_root}, {name: google_cloud_storage_bucket, var: google_cloud_storage_bucket}, {name: google_cloud_storage_credentials_json, var: google_cloud_storage_credentials_json}, {name: google_cloud_storage_project_id, var: google_cloud_storage_project_id}, {name: hostname, var: hostname}, {name: max_connections, var: max_connections}, {name: name, var: name}, {name: one_drive_account_type, var: one_drive_account_type}, {name: password, var: password}, {name: pin_to_site_region, var: pin_to_site_region}, {name: port, var: port}, {name: private_key, var: private_key}, {name: private_key_passphrase, var: private_key_passphrase}, {name: rackspace_api_key, var: rackspace_api_key}, {name: rackspace_container, var: rackspace_container}, {name: rackspace_region, var: rackspace_region}, {name: rackspace_username, var: rackspace_username}, {name: reset_authentication, var: reset_authentication}, {name: s3_bucket, var: s3_bucket}, {name: s3_compatible_access_key, var: s3_compatible_access_key}, {name: s3_compatible_bucket, var: s3_compatible_bucket}, {name: s3_compatible_endpoint, var: s3_compatible_endpoint}, {name: s3_compatible_region, var: s3_compatible_region}, {name: s3_compatible_secret_key, var: s3_compatible_secret_key}, {name: s3_region, var: s3_region}, {name: server_certificate, var: server_certificate}, {name: server_host_key, var: server_host_key}, {name: server_type, var: server_type}, {name: ssl, var: ssl}, {name: ssl_certificate, var: ssl_certificate}, {name: username, var: username}, {name: wasabi_access_key, var: wasabi_access_key}, {name: wasabi_bucket, var: wasabi_bucket}, {name: wasabi_region, var: wasabi_region}, {name: wasabi_secret_key, var: wasabi_secret_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, aws_access_key: $aws_access_key, aws_secret_key: $aws_secret_key, azure_blob_storage_access_key: $azure_blob_storage_access_key, azure_blob_storage_account: $azure_blob_storage_account, azure_blob_storage_container: $azure_blob_storage_container, azure_blob_storage_sas_token: $azure_blob_storage_sas_token, azure_files_storage_access_key: $azure_files_storage_access_key, azure_files_storage_account: $azure_files_storage_account, azure_files_storage_sas_token: $azure_files_storage_sas_token, azure_files_storage_share_name: $azure_files_storage_share_name, backblaze_b2_application_key: $backblaze_b2_application_key, backblaze_b2_bucket: $backblaze_b2_bucket, backblaze_b2_key_id: $backblaze_b2_key_id, backblaze_b2_s3_endpoint: $backblaze_b2_s3_endpoint, enable_dedicated_ips: $enable_dedicated_ips, filebase_access_key: $filebase_access_key, filebase_bucket: $filebase_bucket, filebase_secret_key: $filebase_secret_key, files_agent_permission_set: $files_agent_permission_set, files_agent_root: $files_agent_root, google_cloud_storage_bucket: $google_cloud_storage_bucket, google_cloud_storage_credentials_json: $google_cloud_storage_credentials_json, google_cloud_storage_project_id: $google_cloud_storage_project_id, hostname: $hostname, max_connections: $max_connections, name: $name, one_drive_account_type: $one_drive_account_type, password: $password, pin_to_site_region: $pin_to_site_region, port: $port, private_key: $private_key, private_key_passphrase: $private_key_passphrase, rackspace_api_key: $rackspace_api_key, rackspace_container: $rackspace_container, rackspace_region: $rackspace_region, rackspace_username: $rackspace_username, reset_authentication: $reset_authentication, s3_bucket: $s3_bucket, s3_compatible_access_key: $s3_compatible_access_key, s3_compatible_bucket: $s3_compatible_bucket, s3_compatible_endpoint: $s3_compatible_endpoint, s3_compatible_region: $s3_compatible_region, s3_compatible_secret_key: $s3_compatible_secret_key, s3_region: $s3_region, server_certificate: $server_certificate, server_host_key: $server_host_key, server_type: $server_type, ssl: $ssl, ssl_certificate: $ssl_certificate, username: $username, wasabi_access_key: $wasabi_access_key, wasabi_bucket: $wasabi_bucket, wasabi_region: $wasabi_region, wasabi_secret_key: $wasabi_secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download configuration file (required for some Remote Server integrations, such as the Files.com Agent)
#
# GET /remote_servers/{id}/configuration_file
# Returns: record<api_token: string, config_version: string, hostname: string, id: int, permission_set: string, port: int, private_key: string, public_key: string, root: string, server_host_key: string, status: string, subdomain: string>
# operationId: GetRemoteServersIdConfigurationFile
export def "get-remote-servers-id-configuration-file" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/remote_servers/{id}/configuration_file"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post local changes, check in, and download configuration file (used by some Remote Server integrations, such as the Files.com Agent)
#
# POST /remote_servers/{id}/configuration_file
# Returns: record<api_token: string, config_version: string, hostname: string, id: int, permission_set: string, port: int, private_key: string, public_key: string, root: string, server_host_key: string, status: string, subdomain: string>
# operationId: PostRemoteServersIdConfigurationFile
export def "post-remote-servers-id-configuration-file" [
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
  --api-token: string # Files Agent API Token (e.g. example)
  --config-version: string # agent config version (e.g. example)
  --hostname: string # e.g. example
  --permission-set: string # e.g. full
  --port: int # Incoming port for files agent connections (format: int32, e.g. 1)
  --private-key: string # private key (e.g. example)
  --public-key: string # public key (e.g. example)
  --root: string # Agent local root path (e.g. example)
  --server-host-key: string # e.g. example
  --status: string # either running or shutdown (e.g. example)
  --subdomain: string # e.g. example
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/remote_servers/{id}/configuration_file"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: api_token, var: api_token}, {name: config_version, var: config_version}, {name: hostname, var: hostname}, {name: permission_set, var: permission_set}, {name: port, var: port}, {name: private_key, var: private_key}, {name: public_key, var: public_key}, {name: root, var: root}, {name: server_host_key, var: server_host_key}, {name: status, var: status}, {name: subdomain, var: subdomain}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    id: $id, api_token: $api_token, config_version: $config_version, hostname: $hostname, permission_set: $permission_set, port: $port, private_key: $private_key, public_key: $public_key, root: $root, server_host_key: $server_host_key, status: $status, subdomain: $subdomain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Requests
#
# GET /requests
# Returns: table<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string>
# operationId: GetRequests
export def "get-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[destination]=desc`). Valid fields are `destination`.
  --mine: oneof<nothing, bool> # Only show requests of the current user? (Defaults to true if current user is not a site admin.)
  --path: string # Path to show requests for. If omitted, shows all paths. Send `/` to represent the root directory.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/requests"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: mine, var: mine}, {name: path, var: path}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, mine: $mine, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Request
#
# POST /requests
# Returns: record<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string>
# operationId: PostRequests
export def "post-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string # Destination filename (without extension) to request.
  --group-ids: string # A list of group IDs to request the file from. If sent as a string, it should be comma-delimited.
  path: string # Folder path on which to request the file.
  --user-ids: string # A list of user IDs to request the file from. If sent as a string, it should be comma-delimited.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/requests"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: destination, var: destination}, {name: group_ids, var: group_ids}, {name: path, var: path}, {name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    destination: $destination, group_ids: $group_ids, path: $path, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Requests
#
# GET /requests/folders/{path}
# Returns: table<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string>
# operationId: GetRequestsFoldersPath
export def "get-requests-folders-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[destination]=desc`). Valid fields are `destination`.
  --mine: oneof<nothing, bool> # Only show requests of the current user? (Defaults to true if current user is not a site admin.)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/requests/folders/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: mine, var: mine}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, mine: $mine
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Request
#
# DELETE /requests/{id}
# operationId: DeleteRequestsId
export def "delete-requests-id" [
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
    path: "/requests/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user session (log out)
#
# DELETE /sessions
# operationId: DeleteSessions
export def "delete-sessions" [
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
    path: "/sessions"
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user session (log in)
#
# POST /sessions
# Returns: record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool>
# operationId: PostSessions
export def "post-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --otp: string # If this user has a 2FA device, provide its OTP or code here. (e.g. 123456)
  --partial-session-id: string # Identifier for a partially-completed login
  --password: string # Password for sign in (e.g. password)
  --username: string # Username to sign in as (e.g. username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sessions"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: otp, var: otp}, {name: partial_session_id, var: partial_session_id}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    otp: $otp, partial_session_id: $partial_session_id, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Settings Changes
#
# GET /settings_changes
# Returns: table<changes: list<string>, created_at: string, user_id: int, user_is_files_support: bool, username: string>
# operationId: GetSettingsChanges
export def "get-settings-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[api_key_id]=desc`). Valid fields are `api_key_id`, `created_at` or `user_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `api_key_id` and `user_id`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/settings_changes"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Sftp Host Keys
#
# GET /sftp_host_keys
# Returns: table<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string>
# operationId: GetSftpHostKeys
export def "get-sftp-host-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sftp_host_keys"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Sftp Host Key
#
# POST /sftp_host_keys
# Returns: record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string>
# operationId: PostSftpHostKeys
export def "post-sftp-host-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The friendly name of this SFTP Host Key.
  --private-key: string # The private key data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sftp_host_keys"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: name, var: name}, {name: private_key, var: private_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    name: $name, private_key: $private_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Sftp Host Key
#
# DELETE /sftp_host_keys/{id}
# operationId: DeleteSftpHostKeysId
export def "delete-sftp-host-keys-id" [
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
    path: "/sftp_host_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Sftp Host Key
#
# GET /sftp_host_keys/{id}
# Returns: record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string>
# operationId: GetSftpHostKeysId
export def "get-sftp-host-keys-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sftp_host_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Sftp Host Key
#
# PATCH /sftp_host_keys/{id}
# Returns: record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string>
# operationId: PatchSftpHostKeysId
export def "patch-sftp-host-keys-id" [
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
  --name: string # The friendly name of this SFTP Host Key.
  --private-key: string # The private key data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sftp_host_keys/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: name, var: name}, {name: private_key, var: private_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, name: $name, private_key: $private_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show site settings
#
# GET /site
# Returns: record<active_sftp_host_key_id: int, admin_user_id: int, allow_bundle_names: bool, allowed_2fa_method_bypass_for_ftp_sftp_dav: bool, allowed_2fa_method_sms: bool, allowed_2fa_method_totp: bool, allowed_2fa_method_u2f: bool, allowed_2fa_method_webauthn: bool, allowed_2fa_method_yubi: bool, allowed_countries: string, allowed_ips: string, ask_about_overwrites: bool, bundle_activity_notifications: string, bundle_expiration: int, bundle_password_required: bool, bundle_registration_notifications: string, bundle_require_share_recipient: bool, bundle_upload_receipt_notifications: string, bundle_watermark_attachment: record<name: string, uri: string>, bundle_watermark_value: record, color2_left: string, color2_link: string, color2_text: string, color2_top: string, color2_top_text: string, contact_name: string, created_at: string, currency: string, custom_namespace: bool, days_to_retain_backups: int, default_time_zone: string, desktop_app: bool, desktop_app_session_ip_pinning: bool, desktop_app_session_lifetime: int, disable_files_certificate_generation: bool, disable_notifications: bool, disable_password_reset: bool, disable_users_from_inactivity_period_days: int, disallowed_countries: string, domain: string, domain_hsts_header: bool, domain_letsencrypt_chain: string, email: string, folder_permissions_groups_only: bool, ftp_enabled: bool, hipaa: bool, icon128: record<name: string, uri: string>, icon16: record<name: string, uri: string>, icon32: record<name: string, uri: string>, icon48: record<name: string, uri: string>, immutable_files_set_at: string, include_password_in_welcome_email: bool, language: string, ldap_base_dn: string, ldap_domain: string, ldap_enabled: bool, ldap_group_action: string, ldap_group_exclusion: string, ldap_group_inclusion: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_type: string, ldap_user_action: string, ldap_user_include_groups: string, ldap_username: string, ldap_username_field: string, login_help_text: string, logo: record<name: string, uri: string>, max_prior_passwords: int, mobile_app: bool, mobile_app_session_ip_pinning: bool, mobile_app_session_lifetime: int, motd_text: string, motd_use_for_ftp: bool, motd_use_for_sftp: bool, name: string, next_billing_amount: float, next_billing_date: string, non_sso_groups_allowed: bool, non_sso_users_allowed: bool, office_integration_available: bool, office_integration_type: string, oncehub_link: string, opt_out_global: bool, overage_notified_at: string, overage_notify: bool, overdue: bool, password_min_length: int, password_require_letter: bool, password_require_mixed: bool, password_require_number: bool, password_require_special: bool, password_require_unbreached: bool, password_requirements_apply_to_bundles: bool, password_validity_days: int, phone: string, pin_all_remote_servers_to_site_region: bool, reply_to_email: string, require_2fa: bool, require_2fa_stop_time: string, require_2fa_user_type: string, session: record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool>, session_expiry: float, session_expiry_minutes: int, session_pinned_by_ip: bool, sftp_enabled: bool, sftp_host_key_type: string, sftp_insecure_ciphers: bool, sftp_user_root_enabled: bool, sharing_enabled: bool, show_request_access_link: bool, site_footer: string, site_header: string, smtp_address: string, smtp_authentication: string, smtp_from: string, smtp_port: int, smtp_username: string, ssl_required: bool, subdomain: string, switch_to_plan_date: string, tls_disabled: bool, trial_days_left: int, trial_until: string, updated_at: string, uploads_via_email_authentication: bool, use_provided_modified_at: bool, user: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>, user_lockout: bool, user_lockout_lock_period: int, user_lockout_tries: int, user_lockout_within: int, user_requests_enabled: bool, user_requests_notify_admins: bool, welcome_custom_text: string, welcome_email_cc: string, welcome_email_enabled: bool, welcome_email_subject: string, welcome_screen: string, windows_mode_ftp: bool>
# operationId: GetSite
export def "get-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/site"
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update site settings.
#
# PATCH /site
# Returns: record<active_sftp_host_key_id: int, admin_user_id: int, allow_bundle_names: bool, allowed_2fa_method_bypass_for_ftp_sftp_dav: bool, allowed_2fa_method_sms: bool, allowed_2fa_method_totp: bool, allowed_2fa_method_u2f: bool, allowed_2fa_method_webauthn: bool, allowed_2fa_method_yubi: bool, allowed_countries: string, allowed_ips: string, ask_about_overwrites: bool, bundle_activity_notifications: string, bundle_expiration: int, bundle_password_required: bool, bundle_registration_notifications: string, bundle_require_share_recipient: bool, bundle_upload_receipt_notifications: string, bundle_watermark_attachment: record<name: string, uri: string>, bundle_watermark_value: record, color2_left: string, color2_link: string, color2_text: string, color2_top: string, color2_top_text: string, contact_name: string, created_at: string, currency: string, custom_namespace: bool, days_to_retain_backups: int, default_time_zone: string, desktop_app: bool, desktop_app_session_ip_pinning: bool, desktop_app_session_lifetime: int, disable_files_certificate_generation: bool, disable_notifications: bool, disable_password_reset: bool, disable_users_from_inactivity_period_days: int, disallowed_countries: string, domain: string, domain_hsts_header: bool, domain_letsencrypt_chain: string, email: string, folder_permissions_groups_only: bool, ftp_enabled: bool, hipaa: bool, icon128: record<name: string, uri: string>, icon16: record<name: string, uri: string>, icon32: record<name: string, uri: string>, icon48: record<name: string, uri: string>, immutable_files_set_at: string, include_password_in_welcome_email: bool, language: string, ldap_base_dn: string, ldap_domain: string, ldap_enabled: bool, ldap_group_action: string, ldap_group_exclusion: string, ldap_group_inclusion: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_type: string, ldap_user_action: string, ldap_user_include_groups: string, ldap_username: string, ldap_username_field: string, login_help_text: string, logo: record<name: string, uri: string>, max_prior_passwords: int, mobile_app: bool, mobile_app_session_ip_pinning: bool, mobile_app_session_lifetime: int, motd_text: string, motd_use_for_ftp: bool, motd_use_for_sftp: bool, name: string, next_billing_amount: float, next_billing_date: string, non_sso_groups_allowed: bool, non_sso_users_allowed: bool, office_integration_available: bool, office_integration_type: string, oncehub_link: string, opt_out_global: bool, overage_notified_at: string, overage_notify: bool, overdue: bool, password_min_length: int, password_require_letter: bool, password_require_mixed: bool, password_require_number: bool, password_require_special: bool, password_require_unbreached: bool, password_requirements_apply_to_bundles: bool, password_validity_days: int, phone: string, pin_all_remote_servers_to_site_region: bool, reply_to_email: string, require_2fa: bool, require_2fa_stop_time: string, require_2fa_user_type: string, session: record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool>, session_expiry: float, session_expiry_minutes: int, session_pinned_by_ip: bool, sftp_enabled: bool, sftp_host_key_type: string, sftp_insecure_ciphers: bool, sftp_user_root_enabled: bool, sharing_enabled: bool, show_request_access_link: bool, site_footer: string, site_header: string, smtp_address: string, smtp_authentication: string, smtp_from: string, smtp_port: int, smtp_username: string, ssl_required: bool, subdomain: string, switch_to_plan_date: string, tls_disabled: bool, trial_days_left: int, trial_until: string, updated_at: string, uploads_via_email_authentication: bool, use_provided_modified_at: bool, user: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>, user_lockout: bool, user_lockout_lock_period: int, user_lockout_tries: int, user_lockout_within: int, user_requests_enabled: bool, user_requests_notify_admins: bool, welcome_custom_text: string, welcome_email_cc: string, welcome_email_enabled: bool, welcome_email_subject: string, welcome_screen: string, windows_mode_ftp: bool>
# operationId: PatchSite
export def "patch-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-sftp-host-key-id: int # Id of the currently selected custom SFTP Host Key (format: int32)
  --allow-bundle-names: oneof<nothing, bool> # Are manual Bundle names allowed?
  --allowed-2fa-method-bypass-for-ftp-sftp-dav: oneof<nothing, bool> # Are users allowed to configure their two factor authentication to be bypassed for FTP/SFTP/WebDAV?
  --allowed-2fa-method-sms: oneof<nothing, bool> # Is SMS two factor authentication allowed?
  --allowed-2fa-method-totp: oneof<nothing, bool> # Is TOTP two factor authentication allowed?
  --allowed-2fa-method-u2f: oneof<nothing, bool> # Is U2F two factor authentication allowed?
  --allowed-2fa-method-webauthn: oneof<nothing, bool> # Is WebAuthn two factor authentication allowed?
  --allowed-2fa-method-yubi: oneof<nothing, bool> # Is yubikey two factor authentication allowed?
  --allowed-countries: string # Comma seperated list of allowed Country codes
  --allowed-ips: string # List of allowed IP addresses
  --ask-about-overwrites: oneof<nothing, bool> # If false, rename conflicting files instead of asking for overwrite confirmation. Only applies to web interface.
  --bundle-activity-notifications: string # Do Bundle owners receive activity notifications?
  --bundle-expiration: int # Site-wide Bundle expiration in days (format: int32)
  --bundle-password-required: oneof<nothing, bool> # Do Bundles require password protection?
  --bundle-registration-notifications: string # Do Bundle owners receive registration notification?
  --bundle-require-share-recipient: oneof<nothing, bool> # Do Bundles require recipients for sharing?
  --bundle-upload-receipt-notifications: string # Do Bundle uploaders receive upload confirmation notifications?
  --bundle-watermark-attachment-delete: oneof<nothing, bool> # If true, will delete the file stored in bundle_watermark_attachment
  --bundle-watermark-attachment-file: string # format: binary
  --bundle-watermark-value: record # Preview watermark settings applied to all bundle items. Uses the same keys as Behavior.value
  --color2-left: string # Page link and button color
  --color2-link: string # Top bar link color
  --color2-text: string # Page link and button color
  --color2-top: string # Top bar background color
  --color2-top-text: string # Top bar text color
  --custom-namespace: oneof<nothing, bool> # Is this site using a custom namespace for users?
  --days-to-retain-backups: int # Number of days to keep deleted files (format: int32)
  --default-time-zone: string # Site default time zone
  --desktop-app: oneof<nothing, bool> # Is the desktop app enabled?
  --desktop-app-session-ip-pinning: oneof<nothing, bool> # Is desktop app session IP pinning enabled?
  --desktop-app-session-lifetime: int # Desktop app session lifetime (in hours) (format: int32)
  --disable-2fa-with-delay: oneof<nothing, bool> # If set to true, we will begin the process of disabling 2FA on this site.
  --disable-files-certificate-generation: oneof<nothing, bool> # If set, Files.com will not set the CAA records required to generate future SSL certificates for this domain.
  --disable-password-reset: oneof<nothing, bool> # Is password reset disabled?
  --disable-users-from-inactivity-period-days: int # If greater than zero, users will unable to login if they do not show activity within this number of days. (format: int32)
  --disallowed-countries: string # Comma seperated list of disallowed Country codes
  --domain: string # Custom domain
  --domain-hsts-header: oneof<nothing, bool> # Send HSTS (HTTP Strict Transport Security) header when visitors access the site via a custom domain?
  --domain-letsencrypt-chain: string # Letsencrypt chain to use when registering SSL Certificate for domain.
  --email: string # Main email for this site
  --folder-permissions-groups-only: oneof<nothing, bool> # If true, permissions for this site must be bound to a group (not a user). Otherwise, permissions must be bound to a user.
  --ftp-enabled: oneof<nothing, bool> # Is FTP enabled?
  --icon128-delete: oneof<nothing, bool> # If true, will delete the file stored in icon128
  --icon128-file: string # format: binary
  --icon16-delete: oneof<nothing, bool> # If true, will delete the file stored in icon16
  --icon16-file: string # format: binary
  --icon32-delete: oneof<nothing, bool> # If true, will delete the file stored in icon32
  --icon32-file: string # format: binary
  --icon48-delete: oneof<nothing, bool> # If true, will delete the file stored in icon48
  --icon48-file: string # format: binary
  --immutable-files: oneof<nothing, bool> # Are files protected from modification?
  --include-password-in-welcome-email: oneof<nothing, bool> # Include password in emails to new users?
  --language: string # Site default language
  --ldap-base-dn: string # Base DN for looking up users in LDAP server
  --ldap-domain: string # Domain name that will be appended to usernames
  --ldap-enabled: oneof<nothing, bool> # Main LDAP setting: is LDAP enabled?
  --ldap-group-action: string # Should we sync groups from LDAP server?
  --ldap-group-exclusion: string # Comma or newline separated list of group names (with optional wildcards) to exclude when syncing.
  --ldap-group-inclusion: string # Comma or newline separated list of group names (with optional wildcards) to include when syncing.
  --ldap-host: string # LDAP host
  --ldap-host-2: string # LDAP backup host
  --ldap-host-3: string # LDAP backup host
  --ldap-password-change: string # New LDAP password.
  --ldap-password-change-confirmation: string # Confirm new LDAP password.
  --ldap-port: int # LDAP port (format: int32)
  --ldap-secure: oneof<nothing, bool> # Use secure LDAP?
  --ldap-type: string # LDAP type
  --ldap-user-action: string # Should we sync users from LDAP server?
  --ldap-user-include-groups: string # Comma or newline separated list of group names (with optional wildcards) - if provided, only users in these groups will be added or synced.
  --ldap-username: string # Username for signing in to LDAP server.
  --ldap-username-field: string # LDAP username field
  --login-help-text: string # Login help text
  --logo-delete: oneof<nothing, bool> # If true, will delete the file stored in logo
  --logo-file: string # format: binary
  --max-prior-passwords: int # Number of prior passwords to disallow (format: int32)
  --mobile-app: oneof<nothing, bool> # Is the mobile app enabled?
  --mobile-app-session-ip-pinning: oneof<nothing, bool> # Is mobile app session IP pinning enabled?
  --mobile-app-session-lifetime: int # Mobile app session lifetime (in hours) (format: int32)
  --motd-text: string # A message to show users when they connect via FTP or SFTP.
  --motd-use-for-ftp: oneof<nothing, bool> # Show message to users connecting via FTP
  --motd-use-for-sftp: oneof<nothing, bool> # Show message to users connecting via SFTP
  --name: string # Site name
  --non-sso-groups-allowed: oneof<nothing, bool> # If true, groups can be manually created / modified / deleted by Site Admins. Otherwise, groups can only be managed via your SSO provider.
  --non-sso-users-allowed: oneof<nothing, bool> # If true, users can be manually created / modified / deleted by Site Admins. Otherwise, users can only be managed via your SSO provider.
  --office-integration-available: oneof<nothing, bool> # Allow users to use Office for the web?
  --office-integration-type: string # Office integration application used to edit and view the MS Office documents
  --opt-out-global: oneof<nothing, bool> # Use servers in the USA only?
  --overage-notify: oneof<nothing, bool> # Notify site email of overages?
  --password-min-length: int # Shortest password length for users (format: int32)
  --password-require-letter: oneof<nothing, bool> # Require a letter in passwords?
  --password-require-mixed: oneof<nothing, bool> # Require lower and upper case letters in passwords?
  --password-require-number: oneof<nothing, bool> # Require a number in passwords?
  --password-require-special: oneof<nothing, bool> # Require special characters in password?
  --password-require-unbreached: oneof<nothing, bool> # Require passwords that have not been previously breached? (see https://haveibeenpwned.com/)
  --password-requirements-apply-to-bundles: oneof<nothing, bool> # Require bundles' passwords, and passwords for other items (inboxes, public shares, etc.) to conform to the same requirements as users' passwords?
  --password-validity-days: int # Number of days password is valid (format: int32)
  --pin-all-remote-servers-to-site-region: oneof<nothing, bool> # If true, we will ensure that all internal communications with any remote server are made through the primary region of the site. This setting overrides individual remote server settings.
  --reply-to-email: string # Reply-to email for this site
  --require-2fa: oneof<nothing, bool> # Require two-factor authentication for all users?
  --require-2fa-user-type: string # What type of user is required to use two-factor authentication (when require_2fa is set to `true` for this site)?
  --session-expiry: float # Session expiry in hours (format: double)
  --session-expiry-minutes: int # Session expiry in minutes (format: int32)
  --session-pinned-by-ip: oneof<nothing, bool> # Are sessions locked to the same IP? (i.e. do users need to log in again if they change IPs?)
  --sftp-enabled: oneof<nothing, bool> # Is SFTP enabled?
  --sftp-host-key-type: string # Sftp Host Key Type
  --sftp-insecure-ciphers: oneof<nothing, bool> # Are Insecure Ciphers allowed for SFTP? Note: Settting TLS Disabled -> True will always allow insecure ciphers for SFTP as well. Enabling this is insecure.
  --sftp-user-root-enabled: oneof<nothing, bool> # Use user FTP roots also for SFTP?
  --sharing-enabled: oneof<nothing, bool> # Allow bundle creation
  --show-request-access-link: oneof<nothing, bool> # Show request access link for users without access? Currently unused.
  --site-footer: string # Custom site footer text
  --site-header: string # Custom site header text
  --smtp-address: string # SMTP server hostname or IP
  --smtp-authentication: string # SMTP server authentication type
  --smtp-from: string # From address to use when mailing through custom SMTP
  --smtp-password: string # Password for SMTP server.
  --smtp-port: int # SMTP server port (format: int32)
  --smtp-username: string # SMTP server username
  --ssl-required: oneof<nothing, bool> # Is SSL required? Disabling this is insecure.
  --subdomain: string # Site subdomain
  --tls-disabled: oneof<nothing, bool> # Are Insecure TLS and SFTP Ciphers allowed? Enabling this is insecure.
  --uploads-via-email-authentication: oneof<nothing, bool> # Do incoming emails in the Inboxes require checking for SPF/DKIM/DMARC?
  --use-provided-modified-at: oneof<nothing, bool> # Allow uploaders to set `provided_modified_at` for uploaded files?
  --user-lockout: oneof<nothing, bool> # Will users be locked out after incorrect login attempts?
  --user-lockout-lock-period: int # How many hours to lock user out for failed password? (format: int32)
  --user-lockout-tries: int # Number of login tries within `user_lockout_within` hours before users are locked out (format: int32)
  --user-lockout-within: int # Number of hours for user lockout window (format: int32)
  --user-requests-enabled: oneof<nothing, bool> # Enable User Requests feature
  --user-requests-notify-admins: oneof<nothing, bool> # Send email to site admins when a user request is received?
  --welcome-custom-text: string # Custom text send in user welcome email
  --welcome-email-cc: string # Include this email in welcome emails if enabled
  --welcome-email-enabled: oneof<nothing, bool> # Will the welcome email be sent to new users?
  --welcome-email-subject: string # Include this email subject in welcome emails if enabled
  --welcome-screen: string # Does the welcome screen appear?
  --windows-mode-ftp: oneof<nothing, bool> # Does FTP user Windows emulation mode?
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/site"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: active_sftp_host_key_id, var: active_sftp_host_key_id}, {name: allow_bundle_names, var: allow_bundle_names}, {name: allowed_2fa_method_bypass_for_ftp_sftp_dav, var: allowed_2fa_method_bypass_for_ftp_sftp_dav}, {name: allowed_2fa_method_sms, var: allowed_2fa_method_sms}, {name: allowed_2fa_method_totp, var: allowed_2fa_method_totp}, {name: allowed_2fa_method_u2f, var: allowed_2fa_method_u2f}, {name: allowed_2fa_method_webauthn, var: allowed_2fa_method_webauthn}, {name: allowed_2fa_method_yubi, var: allowed_2fa_method_yubi}, {name: allowed_countries, var: allowed_countries}, {name: allowed_ips, var: allowed_ips}, {name: ask_about_overwrites, var: ask_about_overwrites}, {name: bundle_activity_notifications, var: bundle_activity_notifications}, {name: bundle_expiration, var: bundle_expiration}, {name: bundle_password_required, var: bundle_password_required}, {name: bundle_registration_notifications, var: bundle_registration_notifications}, {name: bundle_require_share_recipient, var: bundle_require_share_recipient}, {name: bundle_upload_receipt_notifications, var: bundle_upload_receipt_notifications}, {name: bundle_watermark_attachment_delete, var: bundle_watermark_attachment_delete}, {name: bundle_watermark_attachment_file, var: bundle_watermark_attachment_file}, {name: bundle_watermark_value, var: bundle_watermark_value}, {name: color2_left, var: color2_left}, {name: color2_link, var: color2_link}, {name: color2_text, var: color2_text}, {name: color2_top, var: color2_top}, {name: color2_top_text, var: color2_top_text}, {name: custom_namespace, var: custom_namespace}, {name: days_to_retain_backups, var: days_to_retain_backups}, {name: default_time_zone, var: default_time_zone}, {name: desktop_app, var: desktop_app}, {name: desktop_app_session_ip_pinning, var: desktop_app_session_ip_pinning}, {name: desktop_app_session_lifetime, var: desktop_app_session_lifetime}, {name: disable_2fa_with_delay, var: disable_2fa_with_delay}, {name: disable_files_certificate_generation, var: disable_files_certificate_generation}, {name: disable_password_reset, var: disable_password_reset}, {name: disable_users_from_inactivity_period_days, var: disable_users_from_inactivity_period_days}, {name: disallowed_countries, var: disallowed_countries}, {name: domain, var: domain}, {name: domain_hsts_header, var: domain_hsts_header}, {name: domain_letsencrypt_chain, var: domain_letsencrypt_chain}, {name: email, var: email}, {name: folder_permissions_groups_only, var: folder_permissions_groups_only}, {name: ftp_enabled, var: ftp_enabled}, {name: icon128_delete, var: icon128_delete}, {name: icon128_file, var: icon128_file}, {name: icon16_delete, var: icon16_delete}, {name: icon16_file, var: icon16_file}, {name: icon32_delete, var: icon32_delete}, {name: icon32_file, var: icon32_file}, {name: icon48_delete, var: icon48_delete}, {name: icon48_file, var: icon48_file}, {name: immutable_files, var: immutable_files}, {name: include_password_in_welcome_email, var: include_password_in_welcome_email}, {name: language, var: language}, {name: ldap_base_dn, var: ldap_base_dn}, {name: ldap_domain, var: ldap_domain}, {name: ldap_enabled, var: ldap_enabled}, {name: ldap_group_action, var: ldap_group_action}, {name: ldap_group_exclusion, var: ldap_group_exclusion}, {name: ldap_group_inclusion, var: ldap_group_inclusion}, {name: ldap_host, var: ldap_host}, {name: ldap_host_2, var: ldap_host_2}, {name: ldap_host_3, var: ldap_host_3}, {name: ldap_password_change, var: ldap_password_change}, {name: ldap_password_change_confirmation, var: ldap_password_change_confirmation}, {name: ldap_port, var: ldap_port}, {name: ldap_secure, var: ldap_secure}, {name: ldap_type, var: ldap_type}, {name: ldap_user_action, var: ldap_user_action}, {name: ldap_user_include_groups, var: ldap_user_include_groups}, {name: ldap_username, var: ldap_username}, {name: ldap_username_field, var: ldap_username_field}, {name: login_help_text, var: login_help_text}, {name: logo_delete, var: logo_delete}, {name: logo_file, var: logo_file}, {name: max_prior_passwords, var: max_prior_passwords}, {name: mobile_app, var: mobile_app}, {name: mobile_app_session_ip_pinning, var: mobile_app_session_ip_pinning}, {name: mobile_app_session_lifetime, var: mobile_app_session_lifetime}, {name: motd_text, var: motd_text}, {name: motd_use_for_ftp, var: motd_use_for_ftp}, {name: motd_use_for_sftp, var: motd_use_for_sftp}, {name: name, var: name}, {name: non_sso_groups_allowed, var: non_sso_groups_allowed}, {name: non_sso_users_allowed, var: non_sso_users_allowed}, {name: office_integration_available, var: office_integration_available}, {name: office_integration_type, var: office_integration_type}, {name: opt_out_global, var: opt_out_global}, {name: overage_notify, var: overage_notify}, {name: password_min_length, var: password_min_length}, {name: password_require_letter, var: password_require_letter}, {name: password_require_mixed, var: password_require_mixed}, {name: password_require_number, var: password_require_number}, {name: password_require_special, var: password_require_special}, {name: password_require_unbreached, var: password_require_unbreached}, {name: password_requirements_apply_to_bundles, var: password_requirements_apply_to_bundles}, {name: password_validity_days, var: password_validity_days}, {name: pin_all_remote_servers_to_site_region, var: pin_all_remote_servers_to_site_region}, {name: reply_to_email, var: reply_to_email}, {name: require_2fa, var: require_2fa}, {name: require_2fa_user_type, var: require_2fa_user_type}, {name: session_expiry, var: session_expiry}, {name: session_expiry_minutes, var: session_expiry_minutes}, {name: session_pinned_by_ip, var: session_pinned_by_ip}, {name: sftp_enabled, var: sftp_enabled}, {name: sftp_host_key_type, var: sftp_host_key_type}, {name: sftp_insecure_ciphers, var: sftp_insecure_ciphers}, {name: sftp_user_root_enabled, var: sftp_user_root_enabled}, {name: sharing_enabled, var: sharing_enabled}, {name: show_request_access_link, var: show_request_access_link}, {name: site_footer, var: site_footer}, {name: site_header, var: site_header}, {name: smtp_address, var: smtp_address}, {name: smtp_authentication, var: smtp_authentication}, {name: smtp_from, var: smtp_from}, {name: smtp_password, var: smtp_password}, {name: smtp_port, var: smtp_port}, {name: smtp_username, var: smtp_username}, {name: ssl_required, var: ssl_required}, {name: subdomain, var: subdomain}, {name: tls_disabled, var: tls_disabled}, {name: uploads_via_email_authentication, var: uploads_via_email_authentication}, {name: use_provided_modified_at, var: use_provided_modified_at}, {name: user_lockout, var: user_lockout}, {name: user_lockout_lock_period, var: user_lockout_lock_period}, {name: user_lockout_tries, var: user_lockout_tries}, {name: user_lockout_within, var: user_lockout_within}, {name: user_requests_enabled, var: user_requests_enabled}, {name: user_requests_notify_admins, var: user_requests_notify_admins}, {name: welcome_custom_text, var: welcome_custom_text}, {name: welcome_email_cc, var: welcome_email_cc}, {name: welcome_email_enabled, var: welcome_email_enabled}, {name: welcome_email_subject, var: welcome_email_subject}, {name: welcome_screen, var: welcome_screen}, {name: windows_mode_ftp, var: windows_mode_ftp}], files: [bundle_watermark_attachment_file, icon128_file, icon16_file, icon32_file, icon48_file, logo_file]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    active_sftp_host_key_id: $active_sftp_host_key_id, allow_bundle_names: $allow_bundle_names, allowed_2fa_method_bypass_for_ftp_sftp_dav: $allowed_2fa_method_bypass_for_ftp_sftp_dav, allowed_2fa_method_sms: $allowed_2fa_method_sms, allowed_2fa_method_totp: $allowed_2fa_method_totp, allowed_2fa_method_u2f: $allowed_2fa_method_u2f, allowed_2fa_method_webauthn: $allowed_2fa_method_webauthn, allowed_2fa_method_yubi: $allowed_2fa_method_yubi, allowed_countries: $allowed_countries, allowed_ips: $allowed_ips, ask_about_overwrites: $ask_about_overwrites, bundle_activity_notifications: $bundle_activity_notifications, bundle_expiration: $bundle_expiration, bundle_password_required: $bundle_password_required, bundle_registration_notifications: $bundle_registration_notifications, bundle_require_share_recipient: $bundle_require_share_recipient, bundle_upload_receipt_notifications: $bundle_upload_receipt_notifications, bundle_watermark_attachment_delete: $bundle_watermark_attachment_delete, bundle_watermark_attachment_file: $bundle_watermark_attachment_file, bundle_watermark_value: $bundle_watermark_value, color2_left: $color2_left, color2_link: $color2_link, color2_text: $color2_text, color2_top: $color2_top, color2_top_text: $color2_top_text, custom_namespace: $custom_namespace, days_to_retain_backups: $days_to_retain_backups, default_time_zone: $default_time_zone, desktop_app: $desktop_app, desktop_app_session_ip_pinning: $desktop_app_session_ip_pinning, desktop_app_session_lifetime: $desktop_app_session_lifetime, disable_2fa_with_delay: $disable_2fa_with_delay, disable_files_certificate_generation: $disable_files_certificate_generation, disable_password_reset: $disable_password_reset, disable_users_from_inactivity_period_days: $disable_users_from_inactivity_period_days, disallowed_countries: $disallowed_countries, domain: $domain, domain_hsts_header: $domain_hsts_header, domain_letsencrypt_chain: $domain_letsencrypt_chain, email: $email, folder_permissions_groups_only: $folder_permissions_groups_only, ftp_enabled: $ftp_enabled, icon128_delete: $icon128_delete, icon128_file: $icon128_file, icon16_delete: $icon16_delete, icon16_file: $icon16_file, icon32_delete: $icon32_delete, icon32_file: $icon32_file, icon48_delete: $icon48_delete, icon48_file: $icon48_file, immutable_files: $immutable_files, include_password_in_welcome_email: $include_password_in_welcome_email, language: $language, ldap_base_dn: $ldap_base_dn, ldap_domain: $ldap_domain, ldap_enabled: $ldap_enabled, ldap_group_action: $ldap_group_action, ldap_group_exclusion: $ldap_group_exclusion, ldap_group_inclusion: $ldap_group_inclusion, ldap_host: $ldap_host, ldap_host_2: $ldap_host_2, ldap_host_3: $ldap_host_3, ldap_password_change: $ldap_password_change, ldap_password_change_confirmation: $ldap_password_change_confirmation, ldap_port: $ldap_port, ldap_secure: $ldap_secure, ldap_type: $ldap_type, ldap_user_action: $ldap_user_action, ldap_user_include_groups: $ldap_user_include_groups, ldap_username: $ldap_username, ldap_username_field: $ldap_username_field, login_help_text: $login_help_text, logo_delete: $logo_delete, logo_file: $logo_file, max_prior_passwords: $max_prior_passwords, mobile_app: $mobile_app, mobile_app_session_ip_pinning: $mobile_app_session_ip_pinning, mobile_app_session_lifetime: $mobile_app_session_lifetime, motd_text: $motd_text, motd_use_for_ftp: $motd_use_for_ftp, motd_use_for_sftp: $motd_use_for_sftp, name: $name, non_sso_groups_allowed: $non_sso_groups_allowed, non_sso_users_allowed: $non_sso_users_allowed, office_integration_available: $office_integration_available, office_integration_type: $office_integration_type, opt_out_global: $opt_out_global, overage_notify: $overage_notify, password_min_length: $password_min_length, password_require_letter: $password_require_letter, password_require_mixed: $password_require_mixed, password_require_number: $password_require_number, password_require_special: $password_require_special, password_require_unbreached: $password_require_unbreached, password_requirements_apply_to_bundles: $password_requirements_apply_to_bundles, password_validity_days: $password_validity_days, pin_all_remote_servers_to_site_region: $pin_all_remote_servers_to_site_region, reply_to_email: $reply_to_email, require_2fa: $require_2fa, require_2fa_user_type: $require_2fa_user_type, session_expiry: $session_expiry, session_expiry_minutes: $session_expiry_minutes, session_pinned_by_ip: $session_pinned_by_ip, sftp_enabled: $sftp_enabled, sftp_host_key_type: $sftp_host_key_type, sftp_insecure_ciphers: $sftp_insecure_ciphers, sftp_user_root_enabled: $sftp_user_root_enabled, sharing_enabled: $sharing_enabled, show_request_access_link: $show_request_access_link, site_footer: $site_footer, site_header: $site_header, smtp_address: $smtp_address, smtp_authentication: $smtp_authentication, smtp_from: $smtp_from, smtp_password: $smtp_password, smtp_port: $smtp_port, smtp_username: $smtp_username, ssl_required: $ssl_required, subdomain: $subdomain, tls_disabled: $tls_disabled, uploads_via_email_authentication: $uploads_via_email_authentication, use_provided_modified_at: $use_provided_modified_at, user_lockout: $user_lockout, user_lockout_lock_period: $user_lockout_lock_period, user_lockout_tries: $user_lockout_tries, user_lockout_within: $user_lockout_within, user_requests_enabled: $user_requests_enabled, user_requests_notify_admins: $user_requests_notify_admins, welcome_custom_text: $welcome_custom_text, welcome_email_cc: $welcome_email_cc, welcome_email_enabled: $welcome_email_enabled, welcome_email_subject: $welcome_email_subject, welcome_screen: $welcome_screen, windows_mode_ftp: $windows_mode_ftp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Api Keys
#
# GET /site/api_keys
# Returns: table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: GetSiteApiKeys
export def "get-site-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[expires_at]=desc`). Valid fields are `expires_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `expires_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `expires_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `expires_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `expires_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/site/api_keys"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Api Key
#
# POST /site/api_keys
# Returns: record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: PostSiteApiKeys
export def "post-site-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --path: string # Folder path restriction for this api key. (e.g. shared/docs)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (default: full, e.g. full)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/site/api_keys"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: name, var: name}, {name: path, var: path}, {name: permission_set, var: permission_set}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    description: $description, expires_at: $expires_at, name: $name, path: $path, permission_set: $permission_set, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show site DNS configuration.
#
# GET /site/dns_records
# Returns: table<domain: string, id: string, rrtype: string, value: string>
# operationId: GetSiteDnsRecords
export def "get-site-dns-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/site/dns_records"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List IP Addresses associated with the current site
#
# GET /site/ip_addresses
# Returns: table<associated_with: string, group_id: int, id: string, ip_addresses: list<string>>
# operationId: GetSiteIpAddresses
export def "get-site-ip-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/site/ip_addresses"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test webhook.
#
# POST /site/test-webhook
# Returns: record<clickwrap_body: string, clickwrap_id: int, code: int, data: record<dynamic: record>, errors: table<fields: list, messages: list>, message: string, status: string>
# operationId: PostSiteTestWebhook
export def "post-site-test-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # action for test body (e.g. test)
  --body: record # Additional body parameters. (e.g. {test-param: testvalue})
  --encoding: string # HTTP encoding method. Can be JSON, XML, or RAW (form data). (e.g. RAW)
  --headers: record # Additional request headers. (e.g. {x-test-header: testvalue})
  --method: string # HTTP method(GET or POST). (e.g. GET)
  url: string # URL for testing the webhook. (e.g. https://www.site.com/...)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/site/test-webhook"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: action, var: action}, {name: body, var: body}, {name: encoding, var: encoding}, {name: headers, var: headers}, {name: method, var: method}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    action: $action, body: $body, encoding: $encoding, headers: $headers, method: $method, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most recent usage snapshot (usage data for billing purposes) for a Site.
#
# GET /site/usage
# Returns: record<bytes_sent: float, current_storage: float, deleted_files_counted_in_minimum: float, deleted_files_storage: float, end_at: string, high_water_storage: float, high_water_user_count: float, id: int, root_storage: float, start_at: string, sync_bytes_received: float, sync_bytes_sent: float, total_billable_transfer_usage: float, total_billable_usage: float, usage_by_top_level_dir: record>
# operationId: GetSiteUsage
export def "get-site-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/site/usage"
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Sso Strategies
#
# GET /sso_strategies
# Returns: table<deprovision_behavior: string, deprovision_groups: bool, deprovision_users: bool, enabled: bool, id: int, label: string, ldap_base_dn: string, ldap_domain: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_username: string, ldap_username_field: string, logo_url: string, protocol: string, provider: string, provision_attachments_permission: bool, provision_company: string, provision_dav_permission: bool, provision_email_signup_groups: string, provision_ftp_permission: bool, provision_group_default: string, provision_group_exclusion: string, provision_group_inclusion: string, provision_group_required: string, provision_groups: bool, provision_sftp_permission: bool, provision_site_admin_groups: string, provision_time_zone: string, provision_users: bool, saml_provider_cert_fingerprint: string, saml_provider_issuer_url: string, saml_provider_metadata_content: string, saml_provider_metadata_url: string, saml_provider_slo_target_url: string, saml_provider_sso_target_url: string, scim_authentication_method: string, scim_oauth_access_token: string, scim_oauth_access_token_expires_at: string, scim_username: string, subdomain: string>
# operationId: GetSsoStrategies
export def "get-sso-strategies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sso_strategies"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Sso Strategy
#
# GET /sso_strategies/{id}
# Returns: record<deprovision_behavior: string, deprovision_groups: bool, deprovision_users: bool, enabled: bool, id: int, label: string, ldap_base_dn: string, ldap_domain: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_username: string, ldap_username_field: string, logo_url: string, protocol: string, provider: string, provision_attachments_permission: bool, provision_company: string, provision_dav_permission: bool, provision_email_signup_groups: string, provision_ftp_permission: bool, provision_group_default: string, provision_group_exclusion: string, provision_group_inclusion: string, provision_group_required: string, provision_groups: bool, provision_sftp_permission: bool, provision_site_admin_groups: string, provision_time_zone: string, provision_users: bool, saml_provider_cert_fingerprint: string, saml_provider_issuer_url: string, saml_provider_metadata_content: string, saml_provider_metadata_url: string, saml_provider_slo_target_url: string, saml_provider_sso_target_url: string, scim_authentication_method: string, scim_oauth_access_token: string, scim_oauth_access_token_expires_at: string, scim_username: string, subdomain: string>
# operationId: GetSsoStrategiesId
export def "get-sso-strategies-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sso_strategies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Synchronize provisioning data with the SSO remote server.
#
# POST /sso_strategies/{id}/sync
# operationId: PostSsoStrategiesIdSync
export def "post-sso-strategies-id-sync" [
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
    method: post
    path: "/sso_strategies/{id}/sync"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Style
#
# DELETE /styles/{path}
# operationId: DeleteStylesPath
export def "delete-styles-path" [
  path: string
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
    path: "/styles/{path}"
    path_params: [{name: path, var: path}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Style
#
# GET /styles/{path}
# Returns: record<id: int, logo: record<name: string, uri: string>, path: string, thumbnail: record<name: string, uri: string>>
# operationId: GetStylesPath
export def "get-styles-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/styles/{path}"
    path_params: [{name: path, var: path}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Style
#
# PATCH /styles/{path}
# Returns: record<id: int, logo: record<name: string, uri: string>, path: string, thumbnail: record<name: string, uri: string>>
# operationId: PatchStylesPath
export def "patch-styles-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Logo for custom branding. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/styles/{path}"
    path_params: [{name: path, var: path}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    path: $path, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Usage Daily Snapshots
#
# GET /usage_daily_snapshots
# Returns: table<api_usage_available: bool, current_storage: int, date: string, deleted_files_counted_in_minimum: int, deleted_files_storage: int, id: int, read_api_usage: int, root_storage: int, usage_by_top_level_dir: record, user_count: int, write_api_usage: int>
# operationId: GetUsageDailySnapshots
export def "get-usage-daily-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[date]=desc`). Valid fields are `date` and `usage_snapshot_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/usage_daily_snapshots"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Usage Snapshots
#
# GET /usage_snapshots
# Returns: table<bytes_sent: float, current_storage: float, deleted_files_counted_in_minimum: float, deleted_files_storage: float, end_at: string, high_water_storage: float, high_water_user_count: float, id: int, root_storage: float, start_at: string, sync_bytes_received: float, sync_bytes_sent: float, total_billable_transfer_usage: float, total_billable_usage: float, usage_by_top_level_dir: record>
# operationId: GetUsageSnapshots
export def "get-usage-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/usage_snapshots"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User
#
# PATCH /user
# Returns: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>
# operationId: PatchUser
export def "patch-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-ips: string # A list of allowed IPs if applicable. Newline delimited (e.g. 127.0.0.1)
  --announcements-read: oneof<nothing, bool> # Signifies that the user has read all the announcements in the UI.
  --attachments-permission: oneof<nothing, bool> # DEPRECATED: Can the user create Bundles (aka Share Links)? Use the bundle permission instead. (e.g. true)
  --authenticate-until: string # Scheduled Date/Time at which user will be deactivated (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --authentication-method: string@authentication-method-completer # How is this user authenticated? (e.g. password)
  --avatar-delete: oneof<nothing, bool> # If true, the avatar will be deleted.
  --avatar-file: string # An image file for your user avatar. (format: binary)
  --billing-permission: oneof<nothing, bool> # Allow this user to perform operations on the account, payments, and invoices?
  --bypass-inactive-disable: oneof<nothing, bool> # Exempt this user from being disabled based on inactivity?
  --bypass-site-allowed-ips: oneof<nothing, bool> # Allow this user to skip site-wide IP blacklists?
  --change-password: string # Used for changing a password on an existing user.
  --change-password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `change_password`.
  --company: string # User's company (e.g. ACME Corp.)
  --dav-permission: oneof<nothing, bool> # Can the user connect with WebDAV? (e.g. true)
  --disabled: oneof<nothing, bool> # Is user disabled? Disabled users cannot log in, and do not count for billing purposes. Users can be automatically disabled after an inactivity period via a Site setting. (e.g. true)
  --email: string # User's email.
  --ftp-permission: oneof<nothing, bool> # Can the user access with FTP/FTPS? (e.g. true)
  --grant-permission: string # Permission to grant on the user root. Can be blank or `full`, `read`, `write`, `list`, or `history`.
  --group-id: int # Group ID to associate this user with. (format: int32)
  --group-ids: string # A list of group ids to associate this user with. Comma delimited.
  --header-text: string # Text to display to the user in the header of the UI (e.g. User-specific message.)
  --imported-password-hash: string # Pre-calculated hash of the user's password. If supplied, this will be used to authenticate the user on first login. Supported hash menthods are MD5, SHA1, and SHA256.
  --language: string # Preferred language (e.g. en)
  --name: string # User's full name (e.g. John Doe)
  --notes: string # Any internal notes on the user (e.g. Internal notes on this user.)
  --notification-daily-send-time: int # Hour of the day at which daily notifications should be sent. Can be in range 0 to 23 (format: int32, e.g. 18)
  --office-integration-enabled: oneof<nothing, bool> # Enable integration with Office for the web? (e.g. true)
  --password: string # User password.
  --password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `password`.
  --password-validity-days: int # Number of days to allow user to use the same password (format: int32, e.g. 1)
  --receive-admin-alerts: oneof<nothing, bool> # Should the user receive admin alerts such a certificate expiration notifications and overages? (e.g. true)
  --require-2fa: string@require-2fa-completer # 2FA required setting (e.g. always_require)
  --require-password-change: oneof<nothing, bool> # Is a password change required upon next user login? (e.g. true)
  --restapi-permission: oneof<nothing, bool> # Can this user access the REST API? (e.g. true)
  --self-managed: oneof<nothing, bool> # Does this user manage it's own credentials or is it a shared/bot user? (e.g. true)
  --sftp-permission: oneof<nothing, bool> # Can the user access with SFTP? (e.g. true)
  --site-admin: oneof<nothing, bool> # Is the user an administrator for this site? (e.g. true)
  --skip-welcome-screen: oneof<nothing, bool> # Skip Welcome page in the UI? (e.g. true)
  --ssl-required: string@ssl-required-completer # SSL required setting (e.g. always_require)
  --sso-strategy-id: int # SSO (Single Sign On) strategy ID for the user, if applicable. (format: int32, e.g. 1)
  --subscribe-to-newsletter: oneof<nothing, bool> # Is the user subscribed to the newsletter? (e.g. true)
  --time-zone: string # User time zone (e.g. Pacific Time (US & Canada))
  --user-root: string # Root folder for FTP (and optionally SFTP if the appropriate site-wide setting is set.) Note that this is not used for API, Desktop, or Web interface. (e.g. example)
  --username: string # User's username (e.g. user)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/user"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allowed_ips, var: allowed_ips}, {name: announcements_read, var: announcements_read}, {name: attachments_permission, var: attachments_permission}, {name: authenticate_until, var: authenticate_until}, {name: authentication_method, var: authentication_method}, {name: avatar_delete, var: avatar_delete}, {name: avatar_file, var: avatar_file}, {name: billing_permission, var: billing_permission}, {name: bypass_inactive_disable, var: bypass_inactive_disable}, {name: bypass_site_allowed_ips, var: bypass_site_allowed_ips}, {name: change_password, var: change_password}, {name: change_password_confirmation, var: change_password_confirmation}, {name: company, var: company}, {name: dav_permission, var: dav_permission}, {name: disabled, var: disabled}, {name: email, var: email}, {name: ftp_permission, var: ftp_permission}, {name: grant_permission, var: grant_permission}, {name: group_id, var: group_id}, {name: group_ids, var: group_ids}, {name: header_text, var: header_text}, {name: imported_password_hash, var: imported_password_hash}, {name: language, var: language}, {name: name, var: name}, {name: notes, var: notes}, {name: notification_daily_send_time, var: notification_daily_send_time}, {name: office_integration_enabled, var: office_integration_enabled}, {name: password, var: password}, {name: password_confirmation, var: password_confirmation}, {name: password_validity_days, var: password_validity_days}, {name: receive_admin_alerts, var: receive_admin_alerts}, {name: require_2fa, var: require_2fa}, {name: require_password_change, var: require_password_change}, {name: restapi_permission, var: restapi_permission}, {name: self_managed, var: self_managed}, {name: sftp_permission, var: sftp_permission}, {name: site_admin, var: site_admin}, {name: skip_welcome_screen, var: skip_welcome_screen}, {name: ssl_required, var: ssl_required}, {name: sso_strategy_id, var: sso_strategy_id}, {name: subscribe_to_newsletter, var: subscribe_to_newsletter}, {name: time_zone, var: time_zone}, {name: user_root, var: user_root}, {name: username, var: username}], files: [avatar_file]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    allowed_ips: $allowed_ips, announcements_read: $announcements_read, attachments_permission: $attachments_permission, authenticate_until: $authenticate_until, authentication_method: $authentication_method, avatar_delete: $avatar_delete, avatar_file: $avatar_file, billing_permission: $billing_permission, bypass_inactive_disable: $bypass_inactive_disable, bypass_site_allowed_ips: $bypass_site_allowed_ips, change_password: $change_password, change_password_confirmation: $change_password_confirmation, company: $company, dav_permission: $dav_permission, disabled: $disabled, email: $email, ftp_permission: $ftp_permission, grant_permission: $grant_permission, group_id: $group_id, group_ids: $group_ids, header_text: $header_text, imported_password_hash: $imported_password_hash, language: $language, name: $name, notes: $notes, notification_daily_send_time: $notification_daily_send_time, office_integration_enabled: $office_integration_enabled, password: $password, password_confirmation: $password_confirmation, password_validity_days: $password_validity_days, receive_admin_alerts: $receive_admin_alerts, require_2fa: $require_2fa, require_password_change: $require_password_change, restapi_permission: $restapi_permission, self_managed: $self_managed, sftp_permission: $sftp_permission, site_admin: $site_admin, skip_welcome_screen: $skip_welcome_screen, ssl_required: $ssl_required, sso_strategy_id: $sso_strategy_id, subscribe_to_newsletter: $subscribe_to_newsletter, time_zone: $time_zone, user_root: $user_root, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Api Keys
#
# GET /user/api_keys
# Returns: table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: GetUserApiKeys
export def "get-user-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[expires_at]=desc`). Valid fields are `expires_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `expires_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `expires_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `expires_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `expires_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/api_keys"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Api Key
#
# POST /user/api_keys
# Returns: record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: PostUserApiKeys
export def "post-user-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --path: string # Folder path restriction for this api key. (e.g. shared/docs)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (default: full, e.g. full)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/api_keys"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: name, var: name}, {name: path, var: path}, {name: permission_set, var: permission_set}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    description: $description, expires_at: $expires_at, name: $name, path: $path, permission_set: $permission_set, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Group Users
#
# GET /user/groups
# Returns: table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>
# operationId: GetUserGroups
export def "get-user-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. If provided, will return group_users of this user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --group-id: int # Group ID. If provided, will return group_users of this group. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/groups"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Public Keys
#
# GET /user/public_keys
# Returns: table<created_at: string, fingerprint: string, id: int, title: string>
# operationId: GetUserPublicKeys
export def "get-user-public-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/public_keys"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Public Key
#
# POST /user/public_keys
# Returns: record<created_at: string, fingerprint: string, id: int, title: string>
# operationId: PostUserPublicKeys
export def "post-user-public-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  public_key: string # Actual contents of SSH key.
  title: string # Internal reference for key. (e.g. My Main Key)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/public_keys"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: public_key, var: public_key}, {name: title, var: title}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    public_key: $public_key, title: $title, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User Cipher Uses
#
# GET /user_cipher_uses
# Returns: table<created_at: string, id: int, interface: string, protocol_cipher: string, updated_at: string, user_id: int>
# operationId: GetUserCipherUses
export def "get-user-cipher-uses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user_cipher_uses"
    query: [{name: user_id, var: user_id}, {name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User Requests
#
# GET /user_requests
# Returns: table<details: string, email: string, id: int, name: string>
# operationId: GetUserRequests
export def "get-user-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user_requests"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create User Request
#
# POST /user_requests
# Returns: record<details: string, email: string, id: int, name: string>
# operationId: PostUserRequests
export def "post-user-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  details: string # Details of the user request
  email: string # Email of user requested
  name: string # Name of user requested
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user_requests"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: details, var: details}, {name: email, var: email}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    details: $details, email: $email, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete User Request
#
# DELETE /user_requests/{id}
# operationId: DeleteUserRequestsId
export def "delete-user-requests-id" [
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
    path: "/user_requests/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show User Request
#
# GET /user_requests/{id}
# Returns: record<details: string, email: string, id: int, name: string>
# operationId: GetUserRequestsId
export def "get-user-requests-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user_requests/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Users
#
# GET /users
# Returns: table<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>
# operationId: GetUsers
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
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[authenticate_until]=desc`). Valid fields are `authenticate_until`, `active`, `email`, `last_desktop_login_at`, `last_login_at`, `username`, `company`, `name`, `site_admin`, `receive_admin_alerts`, `password_validity_days`, `ssl_required` or `not_site_admin`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --ids: string # comma-separated list of User IDs
  --q-username: string # List users matching username.
  --q-email: string # List users matching email.
  --q-notes: string # List users matching notes field.
  --q-admin: string # If `true`, list only admin users.
  --q-allowed-ips: string # If set, list only users with overridden allowed IP setting.
  --q-password-validity-days: string # If set, list only users with overridden password validity days setting.
  --q-ssl-required: string # If set, list only users with overridden SSL required setting.
  --search: string # Searches for partial matches of name, username, or email.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: ids, var: ids}, {name: "q[username]", var: q_username}, {name: "q[email]", var: q_email}, {name: "q[notes]", var: q_notes}, {name: "q[admin]", var: q_admin}, {name: "q[allowed_ips]", var: q_allowed_ips}, {name: "q[password_validity_days]", var: q_password_validity_days}, {name: "q[ssl_required]", var: q_ssl_required}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, ids: $ids, q_username: $q_username, q_email: $q_email, q_notes: $q_notes, q_admin: $q_admin, q_allowed_ips: $q_allowed_ips, q_password_validity_days: $q_password_validity_days, q_ssl_required: $q_ssl_required, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create User
#
# POST /users
# Returns: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>
# operationId: PostUsers
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-ips: string # A list of allowed IPs if applicable. Newline delimited (e.g. 127.0.0.1)
  --announcements-read: oneof<nothing, bool> # Signifies that the user has read all the announcements in the UI.
  --attachments-permission: oneof<nothing, bool> # DEPRECATED: Can the user create Bundles (aka Share Links)? Use the bundle permission instead. (e.g. true)
  --authenticate-until: string # Scheduled Date/Time at which user will be deactivated (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --authentication-method: string@authentication-method-completer # How is this user authenticated? (e.g. password)
  --avatar-delete: oneof<nothing, bool> # If true, the avatar will be deleted.
  --avatar-file: string # An image file for your user avatar. (format: binary)
  --billing-permission: oneof<nothing, bool> # Allow this user to perform operations on the account, payments, and invoices?
  --bypass-inactive-disable: oneof<nothing, bool> # Exempt this user from being disabled based on inactivity?
  --bypass-site-allowed-ips: oneof<nothing, bool> # Allow this user to skip site-wide IP blacklists?
  --change-password: string # Used for changing a password on an existing user.
  --change-password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `change_password`.
  --company: string # User's company (e.g. ACME Corp.)
  --dav-permission: oneof<nothing, bool> # Can the user connect with WebDAV? (e.g. true)
  --disabled: oneof<nothing, bool> # Is user disabled? Disabled users cannot log in, and do not count for billing purposes. Users can be automatically disabled after an inactivity period via a Site setting. (e.g. true)
  --email: string # User's email.
  --ftp-permission: oneof<nothing, bool> # Can the user access with FTP/FTPS? (e.g. true)
  --grant-permission: string # Permission to grant on the user root. Can be blank or `full`, `read`, `write`, `list`, or `history`.
  --group-id: int # Group ID to associate this user with. (format: int32)
  --group-ids: string # A list of group ids to associate this user with. Comma delimited.
  --header-text: string # Text to display to the user in the header of the UI (e.g. User-specific message.)
  --imported-password-hash: string # Pre-calculated hash of the user's password. If supplied, this will be used to authenticate the user on first login. Supported hash menthods are MD5, SHA1, and SHA256.
  --language: string # Preferred language (e.g. en)
  --name: string # User's full name (e.g. John Doe)
  --notes: string # Any internal notes on the user (e.g. Internal notes on this user.)
  --notification-daily-send-time: int # Hour of the day at which daily notifications should be sent. Can be in range 0 to 23 (format: int32, e.g. 18)
  --office-integration-enabled: oneof<nothing, bool> # Enable integration with Office for the web? (e.g. true)
  --password: string # User password.
  --password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `password`.
  --password-validity-days: int # Number of days to allow user to use the same password (format: int32, e.g. 1)
  --receive-admin-alerts: oneof<nothing, bool> # Should the user receive admin alerts such a certificate expiration notifications and overages? (e.g. true)
  --require-2fa: string@require-2fa-completer # 2FA required setting (e.g. always_require)
  --require-password-change: oneof<nothing, bool> # Is a password change required upon next user login? (e.g. true)
  --restapi-permission: oneof<nothing, bool> # Can this user access the REST API? (e.g. true)
  --self-managed: oneof<nothing, bool> # Does this user manage it's own credentials or is it a shared/bot user? (e.g. true)
  --sftp-permission: oneof<nothing, bool> # Can the user access with SFTP? (e.g. true)
  --site-admin: oneof<nothing, bool> # Is the user an administrator for this site? (e.g. true)
  --skip-welcome-screen: oneof<nothing, bool> # Skip Welcome page in the UI? (e.g. true)
  --ssl-required: string@ssl-required-completer # SSL required setting (e.g. always_require)
  --sso-strategy-id: int # SSO (Single Sign On) strategy ID for the user, if applicable. (format: int32, e.g. 1)
  --subscribe-to-newsletter: oneof<nothing, bool> # Is the user subscribed to the newsletter? (e.g. true)
  --time-zone: string # User time zone (e.g. Pacific Time (US & Canada))
  --user-root: string # Root folder for FTP (and optionally SFTP if the appropriate site-wide setting is set.) Note that this is not used for API, Desktop, or Web interface. (e.g. example)
  --username: string # User's username (e.g. user)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allowed_ips, var: allowed_ips}, {name: announcements_read, var: announcements_read}, {name: attachments_permission, var: attachments_permission}, {name: authenticate_until, var: authenticate_until}, {name: authentication_method, var: authentication_method}, {name: avatar_delete, var: avatar_delete}, {name: avatar_file, var: avatar_file}, {name: billing_permission, var: billing_permission}, {name: bypass_inactive_disable, var: bypass_inactive_disable}, {name: bypass_site_allowed_ips, var: bypass_site_allowed_ips}, {name: change_password, var: change_password}, {name: change_password_confirmation, var: change_password_confirmation}, {name: company, var: company}, {name: dav_permission, var: dav_permission}, {name: disabled, var: disabled}, {name: email, var: email}, {name: ftp_permission, var: ftp_permission}, {name: grant_permission, var: grant_permission}, {name: group_id, var: group_id}, {name: group_ids, var: group_ids}, {name: header_text, var: header_text}, {name: imported_password_hash, var: imported_password_hash}, {name: language, var: language}, {name: name, var: name}, {name: notes, var: notes}, {name: notification_daily_send_time, var: notification_daily_send_time}, {name: office_integration_enabled, var: office_integration_enabled}, {name: password, var: password}, {name: password_confirmation, var: password_confirmation}, {name: password_validity_days, var: password_validity_days}, {name: receive_admin_alerts, var: receive_admin_alerts}, {name: require_2fa, var: require_2fa}, {name: require_password_change, var: require_password_change}, {name: restapi_permission, var: restapi_permission}, {name: self_managed, var: self_managed}, {name: sftp_permission, var: sftp_permission}, {name: site_admin, var: site_admin}, {name: skip_welcome_screen, var: skip_welcome_screen}, {name: ssl_required, var: ssl_required}, {name: sso_strategy_id, var: sso_strategy_id}, {name: subscribe_to_newsletter, var: subscribe_to_newsletter}, {name: time_zone, var: time_zone}, {name: user_root, var: user_root}, {name: username, var: username}], files: [avatar_file]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    allowed_ips: $allowed_ips, announcements_read: $announcements_read, attachments_permission: $attachments_permission, authenticate_until: $authenticate_until, authentication_method: $authentication_method, avatar_delete: $avatar_delete, avatar_file: $avatar_file, billing_permission: $billing_permission, bypass_inactive_disable: $bypass_inactive_disable, bypass_site_allowed_ips: $bypass_site_allowed_ips, change_password: $change_password, change_password_confirmation: $change_password_confirmation, company: $company, dav_permission: $dav_permission, disabled: $disabled, email: $email, ftp_permission: $ftp_permission, grant_permission: $grant_permission, group_id: $group_id, group_ids: $group_ids, header_text: $header_text, imported_password_hash: $imported_password_hash, language: $language, name: $name, notes: $notes, notification_daily_send_time: $notification_daily_send_time, office_integration_enabled: $office_integration_enabled, password: $password, password_confirmation: $password_confirmation, password_validity_days: $password_validity_days, receive_admin_alerts: $receive_admin_alerts, require_2fa: $require_2fa, require_password_change: $require_password_change, restapi_permission: $restapi_permission, self_managed: $self_managed, sftp_permission: $sftp_permission, site_admin: $site_admin, skip_welcome_screen: $skip_welcome_screen, ssl_required: $ssl_required, sso_strategy_id: $sso_strategy_id, subscribe_to_newsletter: $subscribe_to_newsletter, time_zone: $time_zone, user_root: $user_root, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete User
#
# DELETE /users/{id}
# operationId: DeleteUsersId
export def "delete-users-id" [
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
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show User
#
# GET /users/{id}
# Returns: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>
# operationId: GetUsersId
export def "get-users-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User
#
# PATCH /users/{id}
# Returns: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>
# operationId: PatchUsersId
export def "patch-users-id" [
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
  --allowed-ips: string # A list of allowed IPs if applicable. Newline delimited (e.g. 127.0.0.1)
  --announcements-read: oneof<nothing, bool> # Signifies that the user has read all the announcements in the UI.
  --attachments-permission: oneof<nothing, bool> # DEPRECATED: Can the user create Bundles (aka Share Links)? Use the bundle permission instead. (e.g. true)
  --authenticate-until: string # Scheduled Date/Time at which user will be deactivated (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --authentication-method: string@authentication-method-completer # How is this user authenticated? (e.g. password)
  --avatar-delete: oneof<nothing, bool> # If true, the avatar will be deleted.
  --avatar-file: string # An image file for your user avatar. (format: binary)
  --billing-permission: oneof<nothing, bool> # Allow this user to perform operations on the account, payments, and invoices?
  --bypass-inactive-disable: oneof<nothing, bool> # Exempt this user from being disabled based on inactivity?
  --bypass-site-allowed-ips: oneof<nothing, bool> # Allow this user to skip site-wide IP blacklists?
  --change-password: string # Used for changing a password on an existing user.
  --change-password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `change_password`.
  --company: string # User's company (e.g. ACME Corp.)
  --dav-permission: oneof<nothing, bool> # Can the user connect with WebDAV? (e.g. true)
  --disabled: oneof<nothing, bool> # Is user disabled? Disabled users cannot log in, and do not count for billing purposes. Users can be automatically disabled after an inactivity period via a Site setting. (e.g. true)
  --email: string # User's email.
  --ftp-permission: oneof<nothing, bool> # Can the user access with FTP/FTPS? (e.g. true)
  --grant-permission: string # Permission to grant on the user root. Can be blank or `full`, `read`, `write`, `list`, or `history`.
  --group-id: int # Group ID to associate this user with. (format: int32)
  --group-ids: string # A list of group ids to associate this user with. Comma delimited.
  --header-text: string # Text to display to the user in the header of the UI (e.g. User-specific message.)
  --imported-password-hash: string # Pre-calculated hash of the user's password. If supplied, this will be used to authenticate the user on first login. Supported hash menthods are MD5, SHA1, and SHA256.
  --language: string # Preferred language (e.g. en)
  --name: string # User's full name (e.g. John Doe)
  --notes: string # Any internal notes on the user (e.g. Internal notes on this user.)
  --notification-daily-send-time: int # Hour of the day at which daily notifications should be sent. Can be in range 0 to 23 (format: int32, e.g. 18)
  --office-integration-enabled: oneof<nothing, bool> # Enable integration with Office for the web? (e.g. true)
  --password: string # User password.
  --password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `password`.
  --password-validity-days: int # Number of days to allow user to use the same password (format: int32, e.g. 1)
  --receive-admin-alerts: oneof<nothing, bool> # Should the user receive admin alerts such a certificate expiration notifications and overages? (e.g. true)
  --require-2fa: string@require-2fa-completer # 2FA required setting (e.g. always_require)
  --require-password-change: oneof<nothing, bool> # Is a password change required upon next user login? (e.g. true)
  --restapi-permission: oneof<nothing, bool> # Can this user access the REST API? (e.g. true)
  --self-managed: oneof<nothing, bool> # Does this user manage it's own credentials or is it a shared/bot user? (e.g. true)
  --sftp-permission: oneof<nothing, bool> # Can the user access with SFTP? (e.g. true)
  --site-admin: oneof<nothing, bool> # Is the user an administrator for this site? (e.g. true)
  --skip-welcome-screen: oneof<nothing, bool> # Skip Welcome page in the UI? (e.g. true)
  --ssl-required: string@ssl-required-completer # SSL required setting (e.g. always_require)
  --sso-strategy-id: int # SSO (Single Sign On) strategy ID for the user, if applicable. (format: int32, e.g. 1)
  --subscribe-to-newsletter: oneof<nothing, bool> # Is the user subscribed to the newsletter? (e.g. true)
  --time-zone: string # User time zone (e.g. Pacific Time (US & Canada))
  --user-root: string # Root folder for FTP (and optionally SFTP if the appropriate site-wide setting is set.) Note that this is not used for API, Desktop, or Web interface. (e.g. example)
  --username: string # User's username (e.g. user)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allowed_ips, var: allowed_ips}, {name: announcements_read, var: announcements_read}, {name: attachments_permission, var: attachments_permission}, {name: authenticate_until, var: authenticate_until}, {name: authentication_method, var: authentication_method}, {name: avatar_delete, var: avatar_delete}, {name: avatar_file, var: avatar_file}, {name: billing_permission, var: billing_permission}, {name: bypass_inactive_disable, var: bypass_inactive_disable}, {name: bypass_site_allowed_ips, var: bypass_site_allowed_ips}, {name: change_password, var: change_password}, {name: change_password_confirmation, var: change_password_confirmation}, {name: company, var: company}, {name: dav_permission, var: dav_permission}, {name: disabled, var: disabled}, {name: email, var: email}, {name: ftp_permission, var: ftp_permission}, {name: grant_permission, var: grant_permission}, {name: group_id, var: group_id}, {name: group_ids, var: group_ids}, {name: header_text, var: header_text}, {name: imported_password_hash, var: imported_password_hash}, {name: language, var: language}, {name: name, var: name}, {name: notes, var: notes}, {name: notification_daily_send_time, var: notification_daily_send_time}, {name: office_integration_enabled, var: office_integration_enabled}, {name: password, var: password}, {name: password_confirmation, var: password_confirmation}, {name: password_validity_days, var: password_validity_days}, {name: receive_admin_alerts, var: receive_admin_alerts}, {name: require_2fa, var: require_2fa}, {name: require_password_change, var: require_password_change}, {name: restapi_permission, var: restapi_permission}, {name: self_managed, var: self_managed}, {name: sftp_permission, var: sftp_permission}, {name: site_admin, var: site_admin}, {name: skip_welcome_screen, var: skip_welcome_screen}, {name: ssl_required, var: ssl_required}, {name: sso_strategy_id, var: sso_strategy_id}, {name: subscribe_to_newsletter, var: subscribe_to_newsletter}, {name: time_zone, var: time_zone}, {name: user_root, var: user_root}, {name: username, var: username}], files: [avatar_file]}
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    id: $id, allowed_ips: $allowed_ips, announcements_read: $announcements_read, attachments_permission: $attachments_permission, authenticate_until: $authenticate_until, authentication_method: $authentication_method, avatar_delete: $avatar_delete, avatar_file: $avatar_file, billing_permission: $billing_permission, bypass_inactive_disable: $bypass_inactive_disable, bypass_site_allowed_ips: $bypass_site_allowed_ips, change_password: $change_password, change_password_confirmation: $change_password_confirmation, company: $company, dav_permission: $dav_permission, disabled: $disabled, email: $email, ftp_permission: $ftp_permission, grant_permission: $grant_permission, group_id: $group_id, group_ids: $group_ids, header_text: $header_text, imported_password_hash: $imported_password_hash, language: $language, name: $name, notes: $notes, notification_daily_send_time: $notification_daily_send_time, office_integration_enabled: $office_integration_enabled, password: $password, password_confirmation: $password_confirmation, password_validity_days: $password_validity_days, receive_admin_alerts: $receive_admin_alerts, require_2fa: $require_2fa, require_password_change: $require_password_change, restapi_permission: $restapi_permission, self_managed: $self_managed, sftp_permission: $sftp_permission, site_admin: $site_admin, skip_welcome_screen: $skip_welcome_screen, ssl_required: $ssl_required, sso_strategy_id: $sso_strategy_id, subscribe_to_newsletter: $subscribe_to_newsletter, time_zone: $time_zone, user_root: $user_root, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger 2FA Reset process for user who has lost access to their existing 2FA methods.
#
# POST /users/{id}/2fa/reset
# operationId: PostUsersId2faReset
export def "post-users-id2fa-reset" [
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
    method: post
    path: "/users/{id}/2fa/reset"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend user welcome email
#
# POST /users/{id}/resend_welcome_email
# operationId: PostUsersIdResendWelcomeEmail
export def "post-users-id-resend-welcome-email" [
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
    method: post
    path: "/users/{id}/resend_welcome_email"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlock user who has been locked out due to failed logins.
#
# POST /users/{id}/unlock
# operationId: PostUsersIdUnlock
export def "post-users-id-unlock" [
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
    method: post
    path: "/users/{id}/unlock"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-filesapi-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Api Keys
#
# GET /users/{user_id}/api_keys
# Returns: table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: GetUsersUserIdApiKeys
export def "get-users-user-id-api-keys" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[expires_at]=desc`). Valid fields are `expires_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `expires_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `expires_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `expires_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `expires_at`.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/api_keys"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Api Key
#
# POST /users/{user_id}/api_keys
# Returns: record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int>
# operationId: PostUsersUserIdApiKeys
export def "post-users-user-id-api-keys" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --path: string # Folder path restriction for this api key. (e.g. shared/docs)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (default: full, e.g. full)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/api_keys"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: name, var: name}, {name: path, var: path}, {name: permission_set, var: permission_set}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    user_id: $user_id, description: $description, expires_at: $expires_at, name: $name, path: $path, permission_set: $permission_set
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User Cipher Uses
#
# GET /users/{user_id}/cipher_uses
# Returns: table<created_at: string, id: int, interface: string, protocol_cipher: string, updated_at: string, user_id: int>
# operationId: GetUsersUserIdCipherUses
export def "get-users-user-id-cipher-uses" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/cipher_uses"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Group Users
#
# GET /users/{user_id}/groups
# Returns: table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>>
# operationId: GetUsersUserIdGroups
export def "get-users-user-id-groups" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --group-id: int # Group ID. If provided, will return group_users of this group. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/groups"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Permissions
#
# GET /users/{user_id}/permissions
# Returns: table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string>
# operationId: GetUsersUserIdPermissions
export def "get-users-user-id-permissions" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[group_id]=desc`). Valid fields are `group_id`, `path`, `user_id` or `permission`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --path: string # DEPRECATED: Permission path. If provided, will scope permissions to this path. Use `filter[path]` instead.
  --group-id: string # DEPRECATED: Group ID. If provided, will scope permissions to this group. Use `filter[group_id]` instead.`
  --include-groups: oneof<nothing, bool> # If searching by user or group, also include user's permissions that are inherited from its groups?
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/permissions"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by, style: multi}, {name: filter, var: filter, style: multi}, {name: filter_gt, var: filter_gt, style: multi}, {name: filter_gteq, var: filter_gteq, style: multi}, {name: filter_like, var: filter_like, style: multi}, {name: filter_lt, var: filter_lt, style: multi}, {name: filter_lteq, var: filter_lteq, style: multi}, {name: path, var: path}, {name: group_id, var: group_id}, {name: include_groups, var: include_groups}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page, sort_by: $sort_by, filter: $filter, filter_gt: $filter_gt, filter_gteq: $filter_gteq, filter_like: $filter_like, filter_lt: $filter_lt, filter_lteq: $filter_lteq, path: $path, group_id: $group_id, include_groups: $include_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Public Keys
#
# GET /users/{user_id}/public_keys
# Returns: table<created_at: string, fingerprint: string, id: int, title: string>
# operationId: GetUsersUserIdPublicKeys
export def "get-users-user-id-public-keys" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/public_keys"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: cursor, var: cursor}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-filesapi-key
  } {
    user_id: $user_id, cursor: $cursor, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Public Key
#
# POST /users/{user_id}/public_keys
# Returns: record<created_at: string, fingerprint: string, id: int, title: string>
# operationId: PostUsersUserIdPublicKeys
export def "post-users-user-id-public-keys" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  public_key: string # Actual contents of SSH key.
  title: string # Internal reference for key. (e.g. My Main Key)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/public_keys"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: public_key, var: public_key}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    user_id: $user_id, public_key: $public_key, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Webhook Test
#
# POST /webhook_tests
# Returns: record<code: int, data: record<dynamic: record>, message: string, status: string, success: bool>
# operationId: PostWebhookTests
export def "post-webhook-tests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # action for test body (e.g. test)
  --body: record # Additional body parameters. (e.g. {test-param: testvalue})
  --encoding: string # HTTP encoding method. Can be JSON, XML, or RAW (form data). (e.g. RAW)
  --file-as-body: oneof<nothing, bool> # Send the file data as the request body?
  --file-form-field: string # Send the file data as a named parameter in the request POST body (e.g. upload_file_data)
  --headers: record # Additional request headers. (e.g. {x-test-header: testvalue})
  --method: string # HTTP method(GET or POST). (e.g. GET)
  --raw-body: string # raw body text (e.g. test body)
  url: string # URL for testing the webhook. (e.g. https://www.site.com/...)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhook_tests"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: action, var: action}, {name: body, var: body}, {name: encoding, var: encoding}, {name: file_as_body, var: file_as_body}, {name: file_form_field, var: file_form_field}, {name: headers, var: headers}, {name: method, var: method}, {name: raw_body, var: raw_body}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-filesapi-key
  } {
    action: $action, body: $body, encoding: $encoding, file_as_body: $file_as_body, file_form_field: $file_form_field, headers: $headers, method: $method, raw_body: $raw_body, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
