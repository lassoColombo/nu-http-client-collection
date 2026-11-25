# Auto-generated client for Appwrite v0.9.3
# Source: https://api.apis.guru/v2/specs/appwrite.io/server/0.9.3/openapi.json
# Auth (JWT): --token-jwt flag or $env.APPWRITE_JWT_TOKEN
# Auth (Project): --token-project flag or $env.APPWRITE_PROJECT_TOKEN
# Auth (Key): --token-key flag or $env.APPWRITE_KEY_TOKEN

const CLIENT = {
  base_url: "https://appwrite.io/v1"
  token_env_var: "APPWRITE_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-appwrite-jwt, in: header, header_name: X-Appwrite-JWT, prefix: ""}
    {name: x-appwrite-key, in: header, header_name: X-Appwrite-Key, prefix: ""}
    {name: x-appwrite-locale, in: header, header_name: X-Appwrite-Locale, prefix: ""}
    {name: x-appwrite-project, in: header, header_name: X-Appwrite-Project, prefix: ""}
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

def base-url-completer [] { ["https://appwrite.io/v1"] }
def auth-scheme-completer [] { ["x-appwrite-jwt" "x-appwrite-key" "x-appwrite-locale" "x-appwrite-project"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-jwt" "token-project" "token-key"]
  let return_types = {
    account-get: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
    account-update-email: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
    account-get-logs: "record<logs: table<clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, deviceBrand: string, deviceModel: string, deviceName: string, event: string, ip: string, osCode: string, osName: string, osVersion: string, time: int>>"
    account-update-name: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
    account-update-password: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
    account-get-prefs: "record"
    account-update-prefs: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
    account-create-recovery: "record<\"$id\": string, expire: int, secret: string, userId: string>"
    account-update-recovery: "record<\"$id\": string, expire: int, secret: string, userId: string>"
    account-get-sessions: "record<sessions: table<\"$id\": string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string>, sum: int>"
    account-get-session: "record<\"$id\": string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string>"
    account-create-verification: "record<\"$id\": string, expire: int, secret: string, userId: string>"
    account-update-verification: "record<\"$id\": string, expire: int, secret: string, userId: string>"
    database-list-collections: "record<collections: table<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, name: string, rules: list>, sum: int>"
    database-create-collection: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, name: string, rules: table<\"$collection\": string, \"$id\": string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>>"
    database-get-collection: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, name: string, rules: table<\"$collection\": string, \"$id\": string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>>"
    database-update-collection: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, name: string, rules: table<\"$collection\": string, \"$id\": string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>>"
    database-list-documents: "record<documents: table<\"$collection\": string, \"$id\": string, \"$permissions\": record>, sum: int>"
    database-create-document: "record<\"$collection\": string, \"$id\": string, \"$permissions\": record>"
    database-get-document: "record<\"$collection\": string, \"$id\": string, \"$permissions\": record>"
    database-update-document: "record<\"$collection\": string, \"$id\": string, \"$permissions\": record>"
    functions-list: "record<functions: table<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, events: list, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>, sum: int>"
    functions-create: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>"
    functions-get: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>"
    functions-update: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>"
    functions-list-executions: "record<executions: table<\"$id\": string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string>, sum: int>"
    functions-create-execution: "record<\"$id\": string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string>"
    functions-get-execution: "record<\"$id\": string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string>"
    functions-update-tag: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>"
    functions-list-tags: "record<sum: int, tags: table<\"$id\": string, command: string, dateCreated: int, functionId: string, size: string>>"
    functions-create-tag: "record<\"$id\": string, command: string, dateCreated: int, functionId: string, size: string>"
    functions-get-tag: "record<\"$id\": string, command: string, dateCreated: int, functionId: string, size: string>"
    locale-get: "record<continent: string, continentCode: string, country: string, countryCode: string, currency: string, eu: bool, ip: string>"
    locale-get-continents: "record<continents: table<code: string, name: string>, sum: int>"
    locale-get-countries: "record<countries: table<code: string, name: string>, sum: int>"
    locale-get-countries-eu: "record<countries: table<code: string, name: string>, sum: int>"
    locale-get-countries-phones: "record<phones: table<code: string, countryCode: string, countryName: string>, sum: int>"
    locale-get-currencies: "record<currencies: table<code: string, decimalDigits: int, name: string, namePlural: string, rounding: float, symbol: string, symbolNative: string>, sum: int>"
    locale-get-languages: "record<languages: table<code: string, name: string, nativeName: string>, sum: int>"
    storage-list-files: "record<files: table<\"$id\": string, \"$permissions\": record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>, sum: int>"
    storage-create-file: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>"
    storage-get-file: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>"
    storage-update-file: "record<\"$id\": string, \"$permissions\": record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>"
    teams-list: "record<sum: int, teams: table<\"$id\": string, dateCreated: int, name: string, sum: int>>"
    teams-create: "record<\"$id\": string, dateCreated: int, name: string, sum: int>"
    teams-get: "record<\"$id\": string, dateCreated: int, name: string, sum: int>"
    teams-update: "record<\"$id\": string, dateCreated: int, name: string, sum: int>"
    teams-get-memberships: "record<memberships: table<\"$id\": string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list, teamId: string, userId: string>, sum: int>"
    teams-create-membership: "record<\"$id\": string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string>"
    teams-update-membership-roles: "record<\"$id\": string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string>"
    teams-update-membership-status: "record<\"$id\": string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string>"
    users-list: "record<sum: int, users: table<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>>"
    users-create: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
    users-get: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
    users-get-logs: "record<logs: table<clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, deviceBrand: string, deviceModel: string, deviceName: string, event: string, ip: string, osCode: string, osName: string, osVersion: string, time: int>>"
    users-get-prefs: "record"
    users-update-prefs: "record"
    users-get-sessions: "record<sessions: table<\"$id\": string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string>, sum: int>"
    users-update-status: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
    users-update-verification: "record<\"$id\": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["account-delete" "account-get" "account-update-email" "account-get-logs" "account-update-name" "account-update-password" "account-get-prefs" "account-update-prefs" "account-create-recovery" "account-update-recovery" "account-delete-sessions" "account-get-sessions" "account-delete-session" "account-get-session" "account-create-verification" "account-update-verification" "avatars-get-browser" "avatars-get-credit-card" "avatars-get-favicon" "avatars-get-flag" "avatars-get-image" "avatars-get-initials" "avatars-get-qr" "database-list-collections" "database-create-collection" "database-delete-collection" "database-get-collection" "database-update-collection" "database-list-documents" "database-create-document" "database-delete-document" "database-get-document" "database-update-document" "functions-list" "functions-create" "functions-delete" "functions-get" "functions-update" "functions-list-executions" "functions-create-execution" "functions-get-execution" "functions-update-tag" "functions-list-tags" "functions-create-tag" "functions-delete-tag" "functions-get-tag" "health-get" "health-get-anti-virus" "health-get-cache" "health-get-db" "health-get-queue-certificates" "health-get-queue-functions" "health-get-queue-logs" "health-get-queue-tasks" "health-get-queue-usage" "health-get-queue-webhooks" "health-get-storage-local" "health-get-time" "locale-get" "locale-get-continents" "locale-get-countries" "locale-get-countries-eu" "locale-get-countries-phones" "locale-get-currencies" "locale-get-languages" "storage-list-files" "storage-create-file" "storage-delete-file" "storage-get-file" "storage-update-file" "storage-get-file-download" "storage-get-file-preview" "storage-get-file-view" "teams-list" "teams-create" "teams-delete" "teams-get" "teams-update" "teams-get-memberships" "teams-create-membership" "teams-delete-membership" "teams-update-membership-roles" "teams-update-membership-status" "users-list" "users-create" "users-delete" "users-get" "users-get-logs" "users-get-prefs" "users-update-prefs" "users-delete-sessions" "users-get-sessions" "users-delete-session" "users-update-status" "users-update-verification" "commands"] | sort) } | get name | first)
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

# Delete Account
#
# DELETE /account
# operationId: accountDelete
export def "account-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/account"
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Account
#
# GET /account
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: accountGet
export def "account-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Account Email
#
# PATCH /account/email
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: accountUpdateEmail
export def "account-update-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email.
  password: string # User password. Must be between 6 to 32 chars.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account/email"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    email: $email, password: $password
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Account Logs
#
# GET /account/logs
# Returns: record<logs: table<clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, deviceBrand: string, deviceModel: string, deviceName: string, event: string, ip: string, osCode: string, osName: string, osVersion: string, time: int>>
# operationId: accountGetLogs
export def "account-get-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/logs"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Account Name
#
# PATCH /account/name
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: accountUpdateName
export def "account-update-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # User name. Max length: 128 chars.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account/name"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Account Password
#
# PATCH /account/password
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: accountUpdatePassword
export def "account-update-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --old-password: string # Old user password. Must be between 6 to 32 chars.
  password: string # New user password. Must be between 6 to 32 chars.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account/password"
    body: {content_type: "application/json", kind: json, fields: [{name: oldPassword, var: old_password}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    old_password: $old_password, password: $password
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Account Preferences
#
# GET /account/prefs
# Returns: record
# operationId: accountGetPrefs
export def "account-get-prefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/prefs"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Account Preferences
#
# PATCH /account/prefs
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: accountUpdatePrefs
export def "account-update-prefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  prefs: record # Prefs key-value JSON object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account/prefs"
    body: {content_type: "application/json", kind: json, fields: [{name: prefs, var: prefs}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    prefs: $prefs
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Password Recovery
#
# POST /account/recovery
# Returns: record<"$id": string, expire: int, secret: string, userId: string>
# operationId: accountCreateRecovery
export def "account-create-recovery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email.
  url: string # URL to redirect the user back to your app from the recovery email. Only URLs from hostnames in your project platform list are allowed. This requirement helps to prevent an [open redirect](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) attack against your project API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/recovery"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    email: $email, url: $url
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete Password Recovery
#
# PUT /account/recovery
# Returns: record<"$id": string, expire: int, secret: string, userId: string>
# operationId: accountUpdateRecovery
export def "account-update-recovery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # New password. Must be between 6 to 32 chars.
  password_again: string # New password again. Must be between 6 to 32 chars.
  secret: string # Valid reset token.
  user_id: string # User account UID address.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/recovery"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: passwordAgain, var: password_again}, {name: secret, var: secret}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    password: $password, password_again: $password_again, secret: $secret, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete All Account Sessions
#
# DELETE /account/sessions
# operationId: accountDeleteSessions
export def "account-delete-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/sessions"
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Account Sessions
#
# GET /account/sessions
# Returns: record<sessions: table<"$id": string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string>, sum: int>
# operationId: accountGetSessions
export def "account-get-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/sessions"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Account Session
#
# DELETE /account/sessions/{sessionId}
# operationId: accountDeleteSession
export def "account-delete-session" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/sessions/{sessionId}"
    path_params: [{name: sessionId, var: session_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    session_id: $session_id
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Session By ID
#
# GET /account/sessions/{sessionId}
# Returns: record<"$id": string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string>
# operationId: accountGetSession
export def "account-get-session" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/sessions/{sessionId}"
    path_params: [{name: sessionId, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    session_id: $session_id
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Email Verification
#
# POST /account/verification
# Returns: record<"$id": string, expire: int, secret: string, userId: string>
# operationId: accountCreateVerification
export def "account-create-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # URL to redirect the user back to your app from the verification email. Only URLs from hostnames in your project platform list are allowed. This requirement helps to prevent an [open redirect](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) attack against your project API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/verification"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    url: $url
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete Email Verification
#
# PUT /account/verification
# Returns: record<"$id": string, expire: int, secret: string, userId: string>
# operationId: accountUpdateVerification
export def "account-update-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  secret: string # Valid verification token.
  user_id: string # User unique ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/verification"
    body: {content_type: "application/json", kind: json, fields: [{name: secret, var: secret}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    secret: $secret, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Browser Icon
#
# GET /avatars/browsers/{code}
# operationId: avatarsGetBrowser
export def "avatars-get-browser" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # Image width. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --height: int # Image height. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --quality: int # Image quality. Pass an integer between 0 to 100. Defaults to 100. (format: int32, default: 100)
]: nothing -> any {
  http-request {
    method: get
    path: "/avatars/browsers/{code}"
    path_params: [{name: code, var: code}]
    query: [{name: width, var: width}, {name: height, var: height}, {name: quality, var: quality}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    code: $code, width: $width, height: $height, quality: $quality
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Credit Card Icon
#
# GET /avatars/credit-cards/{code}
# operationId: avatarsGetCreditCard
export def "avatars-get-credit-card" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # Image width. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --height: int # Image height. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --quality: int # Image quality. Pass an integer between 0 to 100. Defaults to 100. (format: int32, default: 100)
]: nothing -> any {
  http-request {
    method: get
    path: "/avatars/credit-cards/{code}"
    path_params: [{name: code, var: code}]
    query: [{name: width, var: width}, {name: height, var: height}, {name: quality, var: quality}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    code: $code, width: $width, height: $height, quality: $quality
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Favicon
#
# GET /avatars/favicon
# operationId: avatarsGetFavicon
export def "avatars-get-favicon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # Website URL which you want to fetch the favicon from. (required, format: url)
]: nothing -> any {
  http-request {
    method: get
    path: "/avatars/favicon"
    query: [{name: url, var: url, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    url: $url
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Country Flag
#
# GET /avatars/flags/{code}
# operationId: avatarsGetFlag
export def "avatars-get-flag" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # Image width. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --height: int # Image height. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --quality: int # Image quality. Pass an integer between 0 to 100. Defaults to 100. (format: int32, default: 100)
]: nothing -> any {
  http-request {
    method: get
    path: "/avatars/flags/{code}"
    path_params: [{name: code, var: code}]
    query: [{name: width, var: width}, {name: height, var: height}, {name: quality, var: quality}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    code: $code, width: $width, height: $height, quality: $quality
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Image from URL
#
# GET /avatars/image
# operationId: avatarsGetImage
export def "avatars-get-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # Image URL which you want to crop. (required, format: url)
  --width: int # Resize preview image width, Pass an integer between 0 to 2000. (format: int32, default: 400)
  --height: int # Resize preview image height, Pass an integer between 0 to 2000. (format: int32, default: 400)
]: nothing -> any {
  http-request {
    method: get
    path: "/avatars/image"
    query: [{name: url, var: url, required: true}, {name: width, var: width}, {name: height, var: height}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    url: $url, width: $width, height: $height
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Initials
#
# GET /avatars/initials
# operationId: avatarsGetInitials
export def "avatars-get-initials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Full Name. When empty, current user name or email will be used. Max length: 128 chars. (default: "")
  --width: int # Image width. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 500)
  --height: int # Image height. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 500)
  --color: string # Changes text color. By default a random color will be picked and stay will persistent to the given name. (default: "")
  --background: string # Changes background color. By default a random color will be picked and stay will persistent to the given name. (default: "")
]: nothing -> any {
  http-request {
    method: get
    path: "/avatars/initials"
    query: [{name: name, var: name}, {name: width, var: width}, {name: height, var: height}, {name: color, var: color}, {name: background, var: background}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    name: $name, width: $width, height: $height, color: $color, background: $background
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get QR Code
#
# GET /avatars/qr
# operationId: avatarsGetQR
export def "avatars-get-qr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Plain text to be converted to QR code image. (required)
  --size: int # QR code size. Pass an integer between 0 to 1000. Defaults to 400. (format: int32, default: 400)
  --margin: int # Margin from edge. Pass an integer between 0 to 10. Defaults to 1. (format: int32, default: 1)
  --download: oneof<nothing, bool> # Return resulting image with 'Content-Disposition: attachment ' headers for the browser to start downloading it. Pass 0 for no header, or 1 for otherwise. Default value is set to 0. (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/avatars/qr"
    query: [{name: text, var: text, required: true}, {name: size, var: size}, {name: margin, var: margin}, {name: download, var: download}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    text: $text, size: $size, margin: $margin, download: $download
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Collections
#
# GET /database/collections
# Returns: record<collections: table<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, name: string, rules: list>, sum: int>
# operationId: databaseListCollections
export def "database-list-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: "")
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/collections"
    query: [{name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderType, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    search: $search, limit: $limit, offset: $offset, order_type: $order_type
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Collection
#
# POST /database/collections
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, name: string, rules: table<"$collection": string, "$id": string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>>
# operationId: databaseCreateCollection
export def "database-create-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Collection name. Max length: 128 chars.
  read: list<string> # An array of strings with read permissions. By default no user is granted with any read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  rules: list<string> # Array of [rule objects](/docs/rules). Each rule define a collection field name, data type and validation.
  write: list<string> # An array of strings with write permissions. By default no user is granted with any write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/database/collections"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: read, var: read}, {name: rules, var: rules}, {name: write, var: write}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    name: $name, read: $read, rules: $rules, write: $write
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Collection
#
# DELETE /database/collections/{collectionId}
# operationId: databaseDeleteCollection
export def "database-delete-collection" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/database/collections/{collectionId}"
    path_params: [{name: collectionId, var: collection_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    collection_id: $collection_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Collection
#
# GET /database/collections/{collectionId}
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, name: string, rules: table<"$collection": string, "$id": string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>>
# operationId: databaseGetCollection
export def "database-get-collection" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/collections/{collectionId}"
    path_params: [{name: collectionId, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    collection_id: $collection_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Collection
#
# PUT /database/collections/{collectionId}
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, name: string, rules: table<"$collection": string, "$id": string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>>
# operationId: databaseUpdateCollection
export def "database-update-collection" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Collection name. Max length: 128 chars.
  --read: list<string> # An array of strings with read permissions. By default inherits the existing read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  --rules: list<string> # Array of [rule objects](/docs/rules). Each rule define a collection field name, data type and validation.
  --write: list<string> # An array of strings with write permissions. By default inherits the existing write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/database/collections/{collectionId}"
    path_params: [{name: collectionId, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: read, var: read}, {name: rules, var: rules}, {name: write, var: write}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    collection_id: $collection_id, name: $name, read: $read, rules: $rules, write: $write
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Documents
#
# GET /database/collections/{collectionId}/documents
# Returns: record<documents: table<"$collection": string, "$id": string, "$permissions": record>, sum: int>
# operationId: databaseListDocuments
export def "database-list-documents" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list<string> # Array of filter strings. Each filter is constructed from a key name, comparison operator (=, !=, >, <, <=, >=) and a value. You can also use a dot (.) separator in attribute names to filter by child document attributes. Examples: 'name=John Doe' or 'category.$id>=5bed2d152c362'. (default: [])
  --limit: int # Maximum number of documents to return in response. Use this value to manage pagination. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Offset value. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-field: string # Document field that results will be sorted by. (default: "")
  --order-type: string # Order direction. Possible values are DESC for descending order, or ASC for ascending order. (default: ASC)
  --order-cast: string # Order field type casting. Possible values are int, string, date, time or datetime. The database will attempt to cast the order field to the value you pass here. The default value is a string. (default: string)
  --search: string # Search query. Enter any free text search. The database will try to find a match against all document attributes and children. Max length: 256 chars. (default: "")
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/collections/{collectionId}/documents"
    path_params: [{name: collectionId, var: collection_id}]
    query: [{name: filters, var: filters, style: multi}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderField, var: order_field}, {name: orderType, var: order_type}, {name: orderCast, var: order_cast}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    collection_id: $collection_id, filters: $filters, limit: $limit, offset: $offset, order_field: $order_field, order_type: $order_type, order_cast: $order_cast, search: $search
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Document
#
# POST /database/collections/{collectionId}/documents
# Returns: record<"$collection": string, "$id": string, "$permissions": record>
# operationId: databaseCreateDocument
export def "database-create-document" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Document data as JSON object.
  --parent-document: string # Parent document unique ID. Use when you want your new document to be a child of a parent document.
  --parent-property: string # Parent document property name. Use when you want your new document to be a child of a parent document.
  --parent-property-type: string # Parent document property connection type. You can set this value to **assign**, **append** or **prepend**, default value is assign. Use when you want your new document to be a child of a parent document.
  --read: list<string> # An array of strings with read permissions. By default only the current user is granted with read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  --write: list<string> # An array of strings with write permissions. By default only the current user is granted with write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/database/collections/{collectionId}/documents"
    path_params: [{name: collectionId, var: collection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: parentDocument, var: parent_document}, {name: parentProperty, var: parent_property}, {name: parentPropertyType, var: parent_property_type}, {name: read, var: read}, {name: write, var: write}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    collection_id: $collection_id, data: $data, parent_document: $parent_document, parent_property: $parent_property, parent_property_type: $parent_property_type, read: $read, write: $write
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Document
#
# DELETE /database/collections/{collectionId}/documents/{documentId}
# operationId: databaseDeleteDocument
export def "database-delete-document" [
  collection_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/database/collections/{collectionId}/documents/{documentId}"
    path_params: [{name: collectionId, var: collection_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    collection_id: $collection_id, document_id: $document_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Document
#
# GET /database/collections/{collectionId}/documents/{documentId}
# Returns: record<"$collection": string, "$id": string, "$permissions": record>
# operationId: databaseGetDocument
export def "database-get-document" [
  collection_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/collections/{collectionId}/documents/{documentId}"
    path_params: [{name: collectionId, var: collection_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    collection_id: $collection_id, document_id: $document_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Document
#
# PATCH /database/collections/{collectionId}/documents/{documentId}
# Returns: record<"$collection": string, "$id": string, "$permissions": record>
# operationId: databaseUpdateDocument
export def "database-update-document" [
  collection_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Document data as JSON object.
  --read: list<string> # An array of strings with read permissions. By default inherits the existing read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  --write: list<string> # An array of strings with write permissions. By default inherits the existing write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/database/collections/{collectionId}/documents/{documentId}"
    path_params: [{name: collectionId, var: collection_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: read, var: read}, {name: write, var: write}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    collection_id: $collection_id, document_id: $document_id, data: $data, read: $read, write: $write
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Functions
#
# GET /functions
# Returns: record<functions: table<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, events: list, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>, sum: int>
# operationId: functionsList
export def "functions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: "")
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/functions"
    query: [{name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderType, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    search: $search, limit: $limit, offset: $offset, order_type: $order_type
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Function
#
# POST /functions
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>
# operationId: functionsCreate
export def "functions-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: list<string> # Events list.
  execute: list<string> # An array of strings with execution permissions. By default no user is granted with any execute permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  name: string # Function name. Max length: 128 chars.
  runtime: string # Execution runtime.
  --schedule: string # Schedule CRON syntax.
  --timeout: int # Function maximum execution time in seconds.
  --vars: record # Key-value JSON object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/functions"
    body: {content_type: "application/json", kind: json, fields: [{name: events, var: events}, {name: execute, var: execute}, {name: name, var: name}, {name: runtime, var: runtime}, {name: schedule, var: schedule}, {name: timeout, var: timeout}, {name: vars, var: vars}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    events: $events, execute: $execute, name: $name, runtime: $runtime, schedule: $schedule, timeout: $timeout, vars: $vars
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Function
#
# DELETE /functions/{functionId}
# operationId: functionsDelete
export def "functions-delete" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/functions/{functionId}"
    path_params: [{name: functionId, var: function_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Function
#
# GET /functions/{functionId}
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>
# operationId: functionsGet
export def "functions-get" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/functions/{functionId}"
    path_params: [{name: functionId, var: function_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Function
#
# PUT /functions/{functionId}
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>
# operationId: functionsUpdate
export def "functions-update" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: list<string> # Events list.
  execute: list<string> # An array of strings with execution permissions. By default no user is granted with any execute permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  name: string # Function name. Max length: 128 chars.
  --schedule: string # Schedule CRON syntax.
  --timeout: int # Function maximum execution time in seconds.
  --vars: record # Key-value JSON object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/functions/{functionId}"
    path_params: [{name: functionId, var: function_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: events, var: events}, {name: execute, var: execute}, {name: name, var: name}, {name: schedule, var: schedule}, {name: timeout, var: timeout}, {name: vars, var: vars}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, events: $events, execute: $execute, name: $name, schedule: $schedule, timeout: $timeout, vars: $vars
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Executions
#
# GET /functions/{functionId}/executions
# Returns: record<executions: table<"$id": string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string>, sum: int>
# operationId: functionsListExecutions
export def "functions-list-executions" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: "")
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/functions/{functionId}/executions"
    path_params: [{name: functionId, var: function_id}]
    query: [{name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderType, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, search: $search, limit: $limit, offset: $offset, order_type: $order_type
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Execution
#
# POST /functions/{functionId}/executions
# Returns: record<"$id": string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string>
# operationId: functionsCreateExecution
export def "functions-create-execution" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # String of custom data to send to function.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/functions/{functionId}/executions"
    path_params: [{name: functionId, var: function_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, data: $data
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Execution
#
# GET /functions/{functionId}/executions/{executionId}
# Returns: record<"$id": string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string>
# operationId: functionsGetExecution
export def "functions-get-execution" [
  function_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/functions/{functionId}/executions/{executionId}"
    path_params: [{name: functionId, var: function_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, execution_id: $execution_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Function Tag
#
# PATCH /functions/{functionId}/tag
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>
# operationId: functionsUpdateTag
export def "functions-update-tag" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tag: string # Tag unique ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/functions/{functionId}/tag"
    path_params: [{name: functionId, var: function_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, tag: $tag
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Tags
#
# GET /functions/{functionId}/tags
# Returns: record<sum: int, tags: table<"$id": string, command: string, dateCreated: int, functionId: string, size: string>>
# operationId: functionsListTags
export def "functions-list-tags" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: "")
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/functions/{functionId}/tags"
    path_params: [{name: functionId, var: function_id}]
    query: [{name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderType, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, search: $search, limit: $limit, offset: $offset, order_type: $order_type
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Tag
#
# POST /functions/{functionId}/tags
# Returns: record<"$id": string, command: string, dateCreated: int, functionId: string, size: string>
# operationId: functionsCreateTag
export def "functions-create-tag" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Gzip file with your code package. When used with the Appwrite CLI, pass the path to your code directory, and the CLI will automatically package your code. Use a path that is within the current directory.
  command: string # Code execution command.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/functions/{functionId}/tags"
    path_params: [{name: functionId, var: function_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: code, var: code}, {name: command, var: command}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, code: $code, command: $command
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Tag
#
# DELETE /functions/{functionId}/tags/{tagId}
# operationId: functionsDeleteTag
export def "functions-delete-tag" [
  function_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/functions/{functionId}/tags/{tagId}"
    path_params: [{name: functionId, var: function_id}, {name: tagId, var: tag_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, tag_id: $tag_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tag
#
# GET /functions/{functionId}/tags/{tagId}
# Returns: record<"$id": string, command: string, dateCreated: int, functionId: string, size: string>
# operationId: functionsGetTag
export def "functions-get-tag" [
  function_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/functions/{functionId}/tags/{tagId}"
    path_params: [{name: functionId, var: function_id}, {name: tagId, var: tag_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    function_id: $function_id, tag_id: $tag_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get HTTP
#
# GET /health
# operationId: healthGet
export def "health-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Anti virus
#
# GET /health/anti-virus
# operationId: healthGetAntiVirus
export def "health-get-anti-virus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/anti-virus"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Cache
#
# GET /health/cache
# operationId: healthGetCache
export def "health-get-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/cache"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get DB
#
# GET /health/db
# operationId: healthGetDB
export def "health-get-db" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/db"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Certificate Queue
#
# GET /health/queue/certificates
# operationId: healthGetQueueCertificates
export def "health-get-queue-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/queue/certificates"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Functions Queue
#
# GET /health/queue/functions
# operationId: healthGetQueueFunctions
export def "health-get-queue-functions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/queue/functions"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Logs Queue
#
# GET /health/queue/logs
# operationId: healthGetQueueLogs
export def "health-get-queue-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/queue/logs"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tasks Queue
#
# GET /health/queue/tasks
# operationId: healthGetQueueTasks
export def "health-get-queue-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/queue/tasks"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Usage Queue
#
# GET /health/queue/usage
# operationId: healthGetQueueUsage
export def "health-get-queue-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/queue/usage"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Webhooks Queue
#
# GET /health/queue/webhooks
# operationId: healthGetQueueWebhooks
export def "health-get-queue-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/queue/webhooks"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Local Storage
#
# GET /health/storage/local
# operationId: healthGetStorageLocal
export def "health-get-storage-local" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/storage/local"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Time
#
# GET /health/time
# operationId: healthGetTime
export def "health-get-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/health/time"
    accept: ["application/json"]
    ok: []
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Locale
#
# GET /locale
# Returns: record<continent: string, continentCode: string, country: string, countryCode: string, currency: string, eu: bool, ip: string>
# operationId: localeGet
export def "locale-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Continents
#
# GET /locale/continents
# Returns: record<continents: table<code: string, name: string>, sum: int>
# operationId: localeGetContinents
export def "locale-get-continents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/continents"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Countries
#
# GET /locale/countries
# Returns: record<countries: table<code: string, name: string>, sum: int>
# operationId: localeGetCountries
export def "locale-get-countries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/countries"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List EU Countries
#
# GET /locale/countries/eu
# Returns: record<countries: table<code: string, name: string>, sum: int>
# operationId: localeGetCountriesEU
export def "locale-get-countries-eu" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/countries/eu"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Countries Phone Codes
#
# GET /locale/countries/phones
# Returns: record<phones: table<code: string, countryCode: string, countryName: string>, sum: int>
# operationId: localeGetCountriesPhones
export def "locale-get-countries-phones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/countries/phones"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Currencies
#
# GET /locale/currencies
# Returns: record<currencies: table<code: string, decimalDigits: int, name: string, namePlural: string, rounding: float, symbol: string, symbolNative: string>, sum: int>
# operationId: localeGetCurrencies
export def "locale-get-currencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/currencies"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Languages
#
# GET /locale/languages
# Returns: record<languages: table<code: string, name: string, nativeName: string>, sum: int>
# operationId: localeGetLanguages
export def "locale-get-languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/languages"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Files
#
# GET /storage/files
# Returns: record<files: table<"$id": string, "$permissions": record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>, sum: int>
# operationId: storageListFiles
export def "storage-list-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: "")
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/storage/files"
    query: [{name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderType, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    search: $search, limit: $limit, offset: $offset, order_type: $order_type
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create File
#
# POST /storage/files
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>
# operationId: storageCreateFile
export def "storage-create-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Binary file.
  --read: list<string> # An array of strings with read permissions. By default only the current user is granted with read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  --write: list<string> # An array of strings with write permissions. By default only the current user is granted with write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/storage/files"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: read, var: read}, {name: write, var: write}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    file: $file, read: $read, write: $write
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete File
#
# DELETE /storage/files/{fileId}
# operationId: storageDeleteFile
export def "storage-delete-file" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/storage/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    file_id: $file_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get File
#
# GET /storage/files/{fileId}
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>
# operationId: storageGetFile
export def "storage-get-file" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/storage/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    file_id: $file_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update File
#
# PUT /storage/files/{fileId}
# Returns: record<"$id": string, "$permissions": record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>
# operationId: storageUpdateFile
export def "storage-update-file" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  read: list<string> # An array of strings with read permissions. By default no user is granted with any read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  write: list<string> # An array of strings with write permissions. By default no user is granted with any write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/storage/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: read, var: read}, {name: write, var: write}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    file_id: $file_id, read: $read, write: $write
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get File for Download
#
# GET /storage/files/{fileId}/download
# operationId: storageGetFileDownload
export def "storage-get-file-download" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/storage/files/{fileId}/download"
    path_params: [{name: fileId, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    file_id: $file_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get File Preview
#
# GET /storage/files/{fileId}/preview
# operationId: storageGetFilePreview
export def "storage-get-file-preview" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # Resize preview image width, Pass an integer between 0 to 4000. (format: int32, default: 0)
  --height: int # Resize preview image height, Pass an integer between 0 to 4000. (format: int32, default: 0)
  --gravity: string # Image crop gravity. Can be one of center,top-left,top,top-right,left,right,bottom-left,bottom,bottom-right (default: center)
  --quality: int # Preview image quality. Pass an integer between 0 to 100. Defaults to 100. (format: int32, default: 100)
  --border-width: int # Preview image border in pixels. Pass an integer between 0 to 100. Defaults to 0. (format: int32, default: 0)
  --border-color: string # Preview image border color. Use a valid HEX color, no # is needed for prefix. (default: "")
  --border-radius: int # Preview image border radius in pixels. Pass an integer between 0 to 4000. (format: int32, default: 0)
  --opacity: float # Preview image opacity. Only works with images having an alpha channel (like png). Pass a number between 0 to 1. (format: float, default: 1)
  --rotation: int # Preview image rotation in degrees. Pass an integer between 0 and 360. (format: int32, default: 0)
  --background: string # Preview image background color. Only works with transparent images (png). Use a valid HEX color, no # is needed for prefix. (default: "")
  --output: string # Output format type (jpeg, jpg, png, gif and webp). (default: "")
]: nothing -> any {
  http-request {
    method: get
    path: "/storage/files/{fileId}/preview"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: width, var: width}, {name: height, var: height}, {name: gravity, var: gravity}, {name: quality, var: quality}, {name: borderWidth, var: border_width}, {name: borderColor, var: border_color}, {name: borderRadius, var: border_radius}, {name: opacity, var: opacity}, {name: rotation, var: rotation}, {name: background, var: background}, {name: output, var: output}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    file_id: $file_id, width: $width, height: $height, gravity: $gravity, quality: $quality, border_width: $border_width, border_color: $border_color, border_radius: $border_radius, opacity: $opacity, rotation: $rotation, background: $background, output: $output
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get File for View
#
# GET /storage/files/{fileId}/view
# operationId: storageGetFileView
export def "storage-get-file-view" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/storage/files/{fileId}/view"
    path_params: [{name: fileId, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    file_id: $file_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Teams
#
# GET /teams
# Returns: record<sum: int, teams: table<"$id": string, dateCreated: int, name: string, sum: int>>
# operationId: teamsList
export def "teams-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: "")
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams"
    query: [{name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderType, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    search: $search, limit: $limit, offset: $offset, order_type: $order_type
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Team
#
# POST /teams
# Returns: record<"$id": string, dateCreated: int, name: string, sum: int>
# operationId: teamsCreate
export def "teams-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Team name. Max length: 128 chars.
  --roles: list<string> # Array of strings. Use this param to set the roles in the team for the user who created it. The default role is **owner**. A role can be any string. Learn more about [roles and permissions](/docs/permissions). Max length for each role is 32 chars.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    name: $name, roles: $roles
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Team
#
# DELETE /teams/{teamId}
# operationId: teamsDelete
export def "teams-delete" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/teams/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    team_id: $team_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Team
#
# GET /teams/{teamId}
# Returns: record<"$id": string, dateCreated: int, name: string, sum: int>
# operationId: teamsGet
export def "teams-get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    team_id: $team_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Team
#
# PUT /teams/{teamId}
# Returns: record<"$id": string, dateCreated: int, name: string, sum: int>
# operationId: teamsUpdate
export def "teams-update" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Team name. Max length: 128 chars.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/teams/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    team_id: $team_id, name: $name
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Team Memberships
#
# GET /teams/{teamId}/memberships
# Returns: record<memberships: table<"$id": string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list, teamId: string, userId: string>, sum: int>
# operationId: teamsGetMemberships
export def "teams-get-memberships" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: "")
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{teamId}/memberships"
    path_params: [{name: teamId, var: team_id}]
    query: [{name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderType, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    team_id: $team_id, search: $search, limit: $limit, offset: $offset, order_type: $order_type
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Team Membership
#
# POST /teams/{teamId}/memberships
# Returns: record<"$id": string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string>
# operationId: teamsCreateMembership
export def "teams-create-membership" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # New team member email.
  --name: string # New team member name. Max length: 128 chars.
  roles: list<string> # Array of strings. Use this param to set the user roles in the team. A role can be any string. Learn more about [roles and permissions](/docs/permissions). Max length for each role is 32 chars.
  url: string # URL to redirect the user back to your app from the invitation email. Only URLs from hostnames in your project platform list are allowed. This requirement helps to prevent an [open redirect](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) attack against your project API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{teamId}/memberships"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: roles, var: roles}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    team_id: $team_id, email: $email, name: $name, roles: $roles, url: $url
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Team Membership
#
# DELETE /teams/{teamId}/memberships/{membershipId}
# operationId: teamsDeleteMembership
export def "teams-delete-membership" [
  team_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/teams/{teamId}/memberships/{membershipId}"
    path_params: [{name: teamId, var: team_id}, {name: membershipId, var: membership_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    team_id: $team_id, membership_id: $membership_id
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Membership Roles
#
# PATCH /teams/{teamId}/memberships/{membershipId}
# Returns: record<"$id": string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string>
# operationId: teamsUpdateMembershipRoles
export def "teams-update-membership-roles" [
  team_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  roles: list<string> # Array of strings. Use this param to set the user roles in the team. A role can be any string. Learn more about [roles and permissions](/docs/permissions). Max length for each role is 32 chars.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/teams/{teamId}/memberships/{membershipId}"
    path_params: [{name: teamId, var: team_id}, {name: membershipId, var: membership_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    team_id: $team_id, membership_id: $membership_id, roles: $roles
    base_url: $base_url, token_jwt: $token_jwt, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Team Membership Status
#
# PATCH /teams/{teamId}/memberships/{membershipId}/status
# Returns: record<"$id": string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string>
# operationId: teamsUpdateMembershipStatus
export def "teams-update-membership-status" [
  team_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-jwt: string # Auth token for JWT (X-Appwrite-JWT)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  secret: string # Secret key.
  user_id: string # User unique ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/teams/{teamId}/memberships/{membershipId}/status"
    path_params: [{name: teamId, var: team_id}, {name: membershipId, var: membership_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: secret, var: secret}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-jwt, var: token_jwt, env: APPWRITE_JWT_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    team_id: $team_id, membership_id: $membership_id, secret: $secret, user_id: $user_id
    base_url: $base_url, token_jwt: $token_jwt, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Users
#
# GET /users
# Returns: record<sum: int, users: table<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>>
# operationId: usersList
export def "users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: "")
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderType, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    search: $search, limit: $limit, offset: $offset, order_type: $order_type
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create User
#
# POST /users
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: usersCreate
export def "users-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email.
  --name: string # User name. Max length: 128 chars.
  password: string # User password. Must be between 6 to 32 chars.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    email: $email, name: $name, password: $password
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete User
#
# DELETE /users/{userId}
# operationId: usersDelete
export def "users-delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User
#
# GET /users/{userId}
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: usersGet
export def "users-get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Logs
#
# GET /users/{userId}/logs
# Returns: record<logs: table<clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, deviceBrand: string, deviceModel: string, deviceName: string, event: string, ip: string, osCode: string, osName: string, osVersion: string, time: int>>
# operationId: usersGetLogs
export def "users-get-logs" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/logs"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Preferences
#
# GET /users/{userId}/prefs
# Returns: record
# operationId: usersGetPrefs
export def "users-get-prefs" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/prefs"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User Preferences
#
# PATCH /users/{userId}/prefs
# Returns: record
# operationId: usersUpdatePrefs
export def "users-update-prefs" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  prefs: record # Prefs key-value JSON object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{userId}/prefs"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: prefs, var: prefs}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id, prefs: $prefs
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete User Sessions
#
# DELETE /users/{userId}/sessions
# operationId: usersDeleteSessions
export def "users-delete-sessions" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{userId}/sessions"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Sessions
#
# GET /users/{userId}/sessions
# Returns: record<sessions: table<"$id": string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string>, sum: int>
# operationId: usersGetSessions
export def "users-get-sessions" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/sessions"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete User Session
#
# DELETE /users/{userId}/sessions/{sessionId}
# operationId: usersDeleteSession
export def "users-delete-session" [
  user_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{userId}/sessions/{sessionId}"
    path_params: [{name: userId, var: user_id}, {name: sessionId, var: session_id}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id, session_id: $session_id
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User Status
#
# PATCH /users/{userId}/status
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: usersUpdateStatus
export def "users-update-status" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: int # User Status code. To activate the user pass 1, to block the user pass 2 and for disabling the user pass 0
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{userId}/status"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id, status: $status
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Email Verification
#
# PATCH /users/{userId}/verification
# Returns: record<"$id": string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>
# operationId: usersUpdateVerification
export def "users-update-verification" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-key: string # Auth token for Key (X-Appwrite-Key)
  --token-project: string # Auth token for Project (X-Appwrite-Project)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-verification: oneof<nothing, bool> # User Email Verification Status.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{userId}/verification"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: emailVerification, var: email_verification, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: x-appwrite-key, var: token_key, env: APPWRITE_KEY_TOKEN}, {scheme: x-appwrite-project, var: token_project, env: APPWRITE_PROJECT_TOKEN}]
  } {
    user_id: $user_id, email_verification: $email_verification
    base_url: $base_url, token_key: $token_key, token_project: $token_project, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
