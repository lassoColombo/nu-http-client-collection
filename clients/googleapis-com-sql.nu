# Auto-generated client for Cloud SQL Admin API v1beta4
# Source: https://api.apis.guru/v2/specs/googleapis.com/sql/v1beta4/openapi.json
# Auth: --token flag or $env.CLOUD_SQL_ADMIN_API_TOKEN

const CLIENT = {
  base_url: "https://sqladmin.googleapis.com"
  token_env_var: "CLOUD_SQL_ADMIN_API_TOKEN"
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

def base-url-completer [] { ["https://sqladmin.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def backend-type-completer [] { ["EXTERNAL" "FIRST_GEN" "SECOND_GEN" "SQL_BACKEND_TYPE_UNSPECIFIED"] }
def database-version-completer [] { ["MYSQL_5_1" "MYSQL_5_5" "MYSQL_5_6" "MYSQL_5_7" "MYSQL_8_0" "MYSQL_8_0_18" "MYSQL_8_0_26" "MYSQL_8_0_27" "MYSQL_8_0_28" "MYSQL_8_0_29" "MYSQL_8_0_30" "MYSQL_8_0_31" "MYSQL_8_0_32" "MYSQL_8_0_33" "MYSQL_8_0_34" "MYSQL_8_0_35" "MYSQL_8_0_36" "POSTGRES_10" "POSTGRES_11" "POSTGRES_12" "POSTGRES_13" "POSTGRES_14" "POSTGRES_9_6" "SQLSERVER_2017_ENTERPRISE" "SQLSERVER_2017_EXPRESS" "SQLSERVER_2017_STANDARD" "SQLSERVER_2017_WEB" "SQLSERVER_2019_ENTERPRISE" "SQLSERVER_2019_EXPRESS" "SQLSERVER_2019_STANDARD" "SQLSERVER_2019_WEB" "SQL_DATABASE_VERSION_UNSPECIFIED"] }
def instance-type-completer [] { ["CLOUD_SQL_INSTANCE" "ON_PREMISES_INSTANCE" "READ_REPLICA_INSTANCE" "SQL_INSTANCE_TYPE_UNSPECIFIED"] }
def state-completer [] { ["FAILED" "MAINTENANCE" "ONLINE_MAINTENANCE" "PENDING_CREATE" "PENDING_DELETE" "RUNNABLE" "SQL_INSTANCE_STATE_UNSPECIFIED" "SUSPENDED"] }
def backup-kind-completer [] { ["PHYSICAL" "SNAPSHOT" "SQL_BACKUP_KIND_UNSPECIFIED"] }
def status-completer [] { ["DELETED" "DELETION_FAILED" "DELETION_PENDING" "ENQUEUED" "FAILED" "OVERDUE" "RUNNING" "SKIPPED" "SQL_BACKUP_RUN_STATUS_UNSPECIFIED" "SUCCESSFUL"] }
def type-completer [] { ["AUTOMATED" "ON_DEMAND" "SQL_BACKUP_RUN_TYPE_UNSPECIFIED"] }
def sync-mode-completer [] { ["EXTERNAL_SYNC_MODE_UNSPECIFIED" "OFFLINE" "ONLINE"] }
def dual-password-type-completer [] { ["DUAL_PASSWORD" "DUAL_PASSWORD_TYPE_UNSPECIFIED" "NO_DUAL_PASSWORD" "NO_MODIFY_DUAL_PASSWORD"] }
def type-completer-1 [] { ["BUILT_IN" "CLOUD_IAM_SERVICE_ACCOUNT" "CLOUD_IAM_USER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    sql-flags-list: "record<items: table<allowedIntValues: list, allowedStringValues: list, appliesTo: list, inBeta: bool, kind: string, maxValue: string, minValue: string, name: string, requiresRestart: bool, type: string>, kind: string>"
    sql-instances-list: "record<items: table<availableMaintenanceVersions: list, backendType: string, connectionName: string, createTime: string, currentDiskSize: string, databaseInstalledVersion: string, databaseVersion: string, diskEncryptionConfiguration: record, diskEncryptionStatus: record, etag: string, failoverReplica: record, gceZone: string, instanceType: string, ipAddresses: list, ipv6Address: string, kind: string, maintenanceVersion: string, masterInstanceName: string, maxDiskSize: string, name: string, onPremisesConfiguration: record, outOfDiskReport: record, project: string, region: string, replicaConfiguration: record, replicaNames: list, rootPassword: string, satisfiesPzs: bool, scheduledMaintenance: record, secondaryGceZone: string, selfLink: string, serverCaCert: record, serviceAccountEmailAddress: string, settings: record, state: string, suspensionReason: list>, kind: string, nextPageToken: string, warnings: table<code: string, message: string, region: string>>"
    sql-instances-insert: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-delete: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-get: "record<availableMaintenanceVersions: list<string>, backendType: string, connectionName: string, createTime: string, currentDiskSize: string, databaseInstalledVersion: string, databaseVersion: string, diskEncryptionConfiguration: record<kind: string, kmsKeyName: string>, diskEncryptionStatus: record<kind: string, kmsKeyVersionName: string>, etag: string, failoverReplica: record<available: bool, name: string>, gceZone: string, instanceType: string, ipAddresses: table<ipAddress: string, timeToRetire: string, type: string>, ipv6Address: string, kind: string, maintenanceVersion: string, masterInstanceName: string, maxDiskSize: string, name: string, onPremisesConfiguration: record<caCertificate: string, clientCertificate: string, clientKey: string, dumpFilePath: string, hostPort: string, kind: string, password: string, sourceInstance: record<name: string, project: string, region: string>, username: string>, outOfDiskReport: record<sqlMinRecommendedIncreaseSizeGb: int, sqlOutOfDiskState: string>, project: string, region: string, replicaConfiguration: record<failoverTarget: bool, kind: string, mysqlReplicaConfiguration: record<caCertificate: string, clientCertificate: string, clientKey: string, connectRetryInterval: int, dumpFilePath: string, kind: string, masterHeartbeatPeriod: string, password: string, sslCipher: string, username: string, verifyServerCertificate: bool>>, replicaNames: list<string>, rootPassword: string, satisfiesPzs: bool, scheduledMaintenance: record<canDefer: bool, canReschedule: bool, scheduleDeadlineTime: string, startTime: string>, secondaryGceZone: string, selfLink: string, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, serviceAccountEmailAddress: string, settings: record<activationPolicy: string, activeDirectoryConfig: record<domain: string, kind: string>, advancedMachineFeatures: record<threadsPerCore: int>, authorizedGaeApplications: list<string>, availabilityType: string, backupConfiguration: record<backupRetentionSettings: record, binaryLogEnabled: bool, enabled: bool, kind: string, location: string, pointInTimeRecoveryEnabled: bool, replicationLogArchivingEnabled: bool, startTime: string, transactionLogRetentionDays: int>, collation: string, connectorEnforcement: string, crashSafeReplicationEnabled: bool, dataDiskSizeGb: string, dataDiskType: string, databaseFlags: list<record>, databaseReplicationEnabled: bool, deletionProtectionEnabled: bool, denyMaintenancePeriods: list<record>, insightsConfig: record<queryInsightsEnabled: bool, queryPlansPerMinute: int, queryStringLength: int, recordApplicationTags: bool, recordClientAddress: bool>, ipConfiguration: record<allocatedIpRange: string, authorizedNetworks: list, enablePrivatePathForGoogleCloudServices: bool, ipv4Enabled: bool, privateNetwork: string, requireSsl: bool>, kind: string, locationPreference: record<followGaeApplication: string, kind: string, secondaryZone: string, zone: string>, maintenanceWindow: record<day: int, hour: int, kind: string, updateTrack: string>, passwordValidationPolicy: record<complexity: string, disallowUsernameSubstring: bool, enablePasswordPolicy: bool, minLength: int, passwordChangeInterval: string, reuseInterval: int>, pricingPlan: string, replicationType: string, settingsVersion: string, sqlServerAuditConfig: record<bucket: string, kind: string, retentionInterval: string, uploadInterval: string>, storageAutoResize: bool, storageAutoResizeLimit: string, tier: string, timeZone: string, userLabels: record>, state: string, suspensionReason: list<string>>"
    sql-instances-patch: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-update: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-add-server-ca: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-backup-runs-list: "record<items: table<backupKind: string, description: string, diskEncryptionConfiguration: record, diskEncryptionStatus: record, endTime: string, enqueuedTime: string, error: record, id: string, instance: string, kind: string, location: string, selfLink: string, startTime: string, status: string, timeZone: string, type: string, windowStartTime: string>, kind: string, nextPageToken: string>"
    sql-backup-runs-insert: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-backup-runs-delete: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-backup-runs-get: "record<backupKind: string, description: string, diskEncryptionConfiguration: record<kind: string, kmsKeyName: string>, diskEncryptionStatus: record<kind: string, kmsKeyVersionName: string>, endTime: string, enqueuedTime: string, error: record<code: string, kind: string, message: string>, id: string, instance: string, kind: string, location: string, selfLink: string, startTime: string, status: string, timeZone: string, type: string, windowStartTime: string>"
    sql-instances-clone: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-connect-get: "record<backendType: string, databaseVersion: string, ipAddresses: table<ipAddress: string, timeToRetire: string, type: string>, kind: string, region: string, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>>"
    sql-ssl-certs-create-ephemeral: "record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>"
    sql-databases-list: "record<items: table<charset: string, collation: string, etag: string, instance: string, kind: string, name: string, project: string, selfLink: string, sqlserverDatabaseDetails: record>, kind: string>"
    sql-databases-insert: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-databases-delete: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-databases-get: "record<charset: string, collation: string, etag: string, instance: string, kind: string, name: string, project: string, selfLink: string, sqlserverDatabaseDetails: record<compatibilityLevel: int, recoveryModel: string>>"
    sql-databases-patch: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-databases-update: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-demote-master: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-export: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-failover: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-projects-instances-get-disk-shrink-config: "record<kind: string, minimalTargetSizeGb: string>"
    sql-instances-import: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-list-server-cas: "record<activeVersion: string, certs: table<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, kind: string>"
    sql-projects-instances-perform-disk-shrink: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-promote-replica: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-projects-instances-reschedule-maintenance: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-projects-instances-reset-replica-size: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-reset-ssl-config: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-restart: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-restore-backup: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-rotate-server-ca: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-ssl-certs-list: "record<items: table<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, kind: string>"
    sql-ssl-certs-insert: "record<clientCert: record<certInfo: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, certPrivateKey: string>, kind: string, operation: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list, kind: string>, exportContext: record<bakExportOptions: record, csvExportOptions: record, databases: list, fileType: string, kind: string, offload: bool, sqlExportOptions: record, uri: string>, importContext: record<bakImportOptions: record, csvImportOptions: record, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>>"
    sql-ssl-certs-delete: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-ssl-certs-get: "record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>"
    sql-projects-instances-start-external-sync: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-start-replica: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-stop-replica: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-instances-truncate-log: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-users-delete: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-users-list: "record<items: table<dualPasswordType: string, etag: string, host: string, instance: string, kind: string, name: string, password: string, passwordPolicy: record, project: string, sqlserverUserDetails: record, type: string>, kind: string, nextPageToken: string>"
    sql-users-insert: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-users-update: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-users-get: "record<dualPasswordType: string, etag: string, host: string, instance: string, kind: string, name: string, password: string, passwordPolicy: record<allowedFailedAttempts: int, enableFailedAttemptsCheck: bool, enablePasswordVerification: bool, passwordExpirationDuration: string, status: record<locked: bool, passwordExpirationTime: string>>, project: string, sqlserverUserDetails: record<disabled: bool, serverRoles: list<string>>, type: string>"
    sql-projects-instances-verify-external-sync-settings: "record<errors: table<detail: string, kind: string, type: string>, kind: string, warnings: table<detail: string, kind: string, type: string>>"
    sql-connect-generate-ephemeral: "record<ephemeralCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>>"
    sql-operations-list: "record<items: table<backupContext: record, endTime: string, error: record, exportContext: record, importContext: record, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>, kind: string, nextPageToken: string>"
    sql-operations-get: "record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>"
    sql-tiers-list: "record<items: table<DiskQuota: string, RAM: string, kind: string, region: list, tier: string>, kind: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["sql-flags-list" "sql-instances-list" "sql-instances-insert" "sql-instances-delete" "sql-instances-get" "sql-instances-patch" "sql-instances-update" "sql-instances-add-server-ca" "sql-backup-runs-list" "sql-backup-runs-insert" "sql-backup-runs-delete" "sql-backup-runs-get" "sql-instances-clone" "sql-connect-get" "sql-ssl-certs-create-ephemeral" "sql-databases-list" "sql-databases-insert" "sql-databases-delete" "sql-databases-get" "sql-databases-patch" "sql-databases-update" "sql-instances-demote-master" "sql-instances-export" "sql-instances-failover" "sql-projects-instances-get-disk-shrink-config" "sql-instances-import" "sql-instances-list-server-cas" "sql-projects-instances-perform-disk-shrink" "sql-instances-promote-replica" "sql-projects-instances-reschedule-maintenance" "sql-projects-instances-reset-replica-size" "sql-instances-reset-ssl-config" "sql-instances-restart" "sql-instances-restore-backup" "sql-instances-rotate-server-ca" "sql-ssl-certs-list" "sql-ssl-certs-insert" "sql-ssl-certs-delete" "sql-ssl-certs-get" "sql-projects-instances-start-external-sync" "sql-instances-start-replica" "sql-instances-stop-replica" "sql-instances-truncate-log" "sql-users-delete" "sql-users-list" "sql-users-insert" "sql-users-update" "sql-users-get" "sql-projects-instances-verify-external-sync-settings" "sql-connect-generate-ephemeral" "sql-operations-list" "sql-operations-get" "sql-tiers-list" "commands"] | sort) } | get name | first)
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

# Lists all available database flags for Cloud SQL instances.
#
# GET /sql/v1beta4/flags
# Returns: record<items: table<allowedIntValues: list, allowedStringValues: list, appliesTo: list, inBeta: bool, kind: string, maxValue: string, minValue: string, name: string, requiresRestart: bool, type: string>, kind: string>
# operationId: sql.flags.list
export def "sql-flags-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --database-version: string # Database type and version you want to retrieve flags for. By default, this method returns flags for all database types and versions.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/flags"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: databaseVersion, var: database_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, database_version: $database_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists instances under a given project.
#
# GET /sql/v1beta4/projects/{project}/instances
# Returns: record<items: table<availableMaintenanceVersions: list, backendType: string, connectionName: string, createTime: string, currentDiskSize: string, databaseInstalledVersion: string, databaseVersion: string, diskEncryptionConfiguration: record, diskEncryptionStatus: record, etag: string, failoverReplica: record, gceZone: string, instanceType: string, ipAddresses: list, ipv6Address: string, kind: string, maintenanceVersion: string, masterInstanceName: string, maxDiskSize: string, name: string, onPremisesConfiguration: record, outOfDiskReport: record, project: string, region: string, replicaConfiguration: record, replicaNames: list, rootPassword: string, satisfiesPzs: bool, scheduledMaintenance: record, secondaryGceZone: string, selfLink: string, serverCaCert: record, serviceAccountEmailAddress: string, settings: record, state: string, suspensionReason: list>, kind: string, nextPageToken: string, warnings: table<code: string, message: string, region: string>>
# operationId: sql.instances.list
export def "sql-instances-list" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. The expression is in the form of field:value. For example, 'instanceType:CLOUD_SQL_INSTANCE'. Fields can be nested as needed as per their JSON representation, such as 'settings.userLabels.auto_start:true'. Multiple filter queries are space-separated. For example. 'state:RUNNABLE instanceType:CLOUD_SQL_INSTANCE'. By default, each expression is an AND expression. However, you can include AND and OR expressions explicitly.
  --max-results: int # The maximum number of instances to return. The service may return fewer than this value. If unspecified, at most 500 instances are returned. The maximum value is 1000; values above 1000 are coerced to 1000.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Cloud SQL instance.
#
# POST /sql/v1beta4/projects/{project}/instances
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.insert
export def "sql-instances-insert" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --backend-type: string@backend-type-completer # The backend type. `SECOND_GEN`: Cloud SQL database instance. `EXTERNAL`: A database server that is not managed by Google. This property is read-only; use the `tier` property in the `settings` object to determine the database type.
  --connection-name: string # Connection name of the Cloud SQL instance used in connection strings.
  --current-disk-size: string # The current disk usage of the instance in bytes. This property has been deprecated. Use the "cloudsql.googleapis.com/database/disk/bytes_used" metric in Cloud Monitoring API instead. Please see [this announcement](https://groups.google.com/d/msg/google-cloud-sql-announce/I_7-F9EBhT0/BtvFtdFeAgAJ) for details. (format: int64)
  --database-version: string@database-version-completer # The database engine type and version. The `databaseVersion` field cannot be changed after instance creation.
  --disk-encryption-configuration: record # Disk encryption configuration for an instance. — shape: {kind?: string, kmsKeyName?: string}
  --disk-encryption-status: record # Disk encryption status for an instance. — shape: {kind?: string, kmsKeyVersionName?: string}
  --etag: string # This field is deprecated and will be removed from a future version of the API. Use the `settings.settingsVersion` field instead.
  --failover-replica: record # The name and status of the failover replica. — shape: {available?: bool, name?: string}
  --gce-zone: string # The Compute Engine zone that the instance is currently serving from. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary zone. WARNING: Changing this might restart the instance.
  --instance-type: string@instance-type-completer # The instance type.
  --ip-addresses: list # The assigned IP addresses for the instance. — item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
  --ipv6-address: string # The IPv6 address assigned to the instance. (Deprecated) This property was applicable only to First Generation instances.
  --kind: string # This is always `sql#instance`.
  --maintenance-version: string # The current software version on the instance.
  --master-instance-name: string # The name of the instance which will act as primary in the replication setup.
  --max-disk-size: string # The maximum disk size of the instance in bytes. (format: int64)
  --name: string # Name of the Cloud SQL instance. This does not include the project ID.
  --on-premises-configuration: record # On-premises instance configuration. — shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
  --out-of-disk-report: record # This message wraps up the information written by out-of-disk detection job. — shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
  --body-project: string # The project ID of the project containing the Cloud SQL instance. The Google apps domain is prefixed if applicable. (spec name: project)
  --region: string # The geographical region. Can be: * `us-central` (`FIRST_GEN` instances only) * `us-central1` (`SECOND_GEN` instances only) * `asia-east1` or `europe-west1`. Defaults to `us-central` or `us-central1` depending on the instance type. The region cannot be changed after instance creation.
  --replica-configuration: record # Read-replica configuration for connecting to the primary instance. — shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
  --replica-names: list<string> # The replicas of the instance.
  --root-password: string # Initial root password. Use only on creation. You must set root passwords before you can connect to PostgreSQL instances.
  --satisfies-pzs: oneof<nothing, bool> # The status indicating if instance satisfiesPzs. Reserved for future use.
  --scheduled-maintenance: record # Any scheduled maintenance for this instance. — shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
  --secondary-gce-zone: string # The Compute Engine zone that the failover instance is currently serving from for a regional instance. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary/failover zone.
  --self-link: string # The URI of this resource.
  --server-ca-cert: record # SslCerts Resource — shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
  --service-account-email-address: string # The service account email address assigned to the instance. \This property is read-only.
  --settings: record # Database instance settings. — shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
  --state: string@state-completer # The current serving state of the Cloud SQL instance.
  --suspension-reason: list<string> # If the instance state is SUSPENDED, the reason for the suspension.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: backendType, var: backend_type}, {name: connectionName, var: connection_name}, {name: currentDiskSize, var: current_disk_size}, {name: databaseVersion, var: database_version}, {name: diskEncryptionConfiguration, var: disk_encryption_configuration}, {name: diskEncryptionStatus, var: disk_encryption_status}, {name: etag, var: etag}, {name: failoverReplica, var: failover_replica}, {name: gceZone, var: gce_zone}, {name: instanceType, var: instance_type}, {name: ipAddresses, var: ip_addresses}, {name: ipv6Address, var: ipv6_address}, {name: kind, var: kind}, {name: maintenanceVersion, var: maintenance_version}, {name: masterInstanceName, var: master_instance_name}, {name: maxDiskSize, var: max_disk_size}, {name: name, var: name}, {name: onPremisesConfiguration, var: on_premises_configuration}, {name: outOfDiskReport, var: out_of_disk_report}, {name: project, var: body_project}, {name: region, var: region}, {name: replicaConfiguration, var: replica_configuration}, {name: replicaNames, var: replica_names}, {name: rootPassword, var: root_password}, {name: satisfiesPzs, var: satisfies_pzs}, {name: scheduledMaintenance, var: scheduled_maintenance}, {name: secondaryGceZone, var: secondary_gce_zone}, {name: selfLink, var: self_link}, {name: serverCaCert, var: server_ca_cert}, {name: serviceAccountEmailAddress, var: service_account_email_address}, {name: settings, var: settings}, {name: state, var: state}, {name: suspensionReason, var: suspension_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, backend_type: $backend_type, connection_name: $connection_name, current_disk_size: $current_disk_size, database_version: $database_version, disk_encryption_configuration: $disk_encryption_configuration, disk_encryption_status: $disk_encryption_status, etag: $etag, failover_replica: $failover_replica, gce_zone: $gce_zone, instance_type: $instance_type, ip_addresses: $ip_addresses, ipv6_address: $ipv6_address, kind: $kind, maintenance_version: $maintenance_version, master_instance_name: $master_instance_name, max_disk_size: $max_disk_size, name: $name, on_premises_configuration: $on_premises_configuration, out_of_disk_report: $out_of_disk_report, body_project: $body_project, region: $region, replica_configuration: $replica_configuration, replica_names: $replica_names, root_password: $root_password, satisfies_pzs: $satisfies_pzs, scheduled_maintenance: $scheduled_maintenance, secondary_gce_zone: $secondary_gce_zone, self_link: $self_link, server_ca_cert: $server_ca_cert, service_account_email_address: $service_account_email_address, settings: $settings, state: $state, suspension_reason: $suspension_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Cloud SQL instance.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.delete
export def "sql-instances-delete" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/sql/v1beta4/projects/{project}/instances/{instance}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a resource containing information about a Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}
# Returns: record<availableMaintenanceVersions: list<string>, backendType: string, connectionName: string, createTime: string, currentDiskSize: string, databaseInstalledVersion: string, databaseVersion: string, diskEncryptionConfiguration: record<kind: string, kmsKeyName: string>, diskEncryptionStatus: record<kind: string, kmsKeyVersionName: string>, etag: string, failoverReplica: record<available: bool, name: string>, gceZone: string, instanceType: string, ipAddresses: table<ipAddress: string, timeToRetire: string, type: string>, ipv6Address: string, kind: string, maintenanceVersion: string, masterInstanceName: string, maxDiskSize: string, name: string, onPremisesConfiguration: record<caCertificate: string, clientCertificate: string, clientKey: string, dumpFilePath: string, hostPort: string, kind: string, password: string, sourceInstance: record<name: string, project: string, region: string>, username: string>, outOfDiskReport: record<sqlMinRecommendedIncreaseSizeGb: int, sqlOutOfDiskState: string>, project: string, region: string, replicaConfiguration: record<failoverTarget: bool, kind: string, mysqlReplicaConfiguration: record<caCertificate: string, clientCertificate: string, clientKey: string, connectRetryInterval: int, dumpFilePath: string, kind: string, masterHeartbeatPeriod: string, password: string, sslCipher: string, username: string, verifyServerCertificate: bool>>, replicaNames: list<string>, rootPassword: string, satisfiesPzs: bool, scheduledMaintenance: record<canDefer: bool, canReschedule: bool, scheduleDeadlineTime: string, startTime: string>, secondaryGceZone: string, selfLink: string, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, serviceAccountEmailAddress: string, settings: record<activationPolicy: string, activeDirectoryConfig: record<domain: string, kind: string>, advancedMachineFeatures: record<threadsPerCore: int>, authorizedGaeApplications: list<string>, availabilityType: string, backupConfiguration: record<backupRetentionSettings: record, binaryLogEnabled: bool, enabled: bool, kind: string, location: string, pointInTimeRecoveryEnabled: bool, replicationLogArchivingEnabled: bool, startTime: string, transactionLogRetentionDays: int>, collation: string, connectorEnforcement: string, crashSafeReplicationEnabled: bool, dataDiskSizeGb: string, dataDiskType: string, databaseFlags: list<record>, databaseReplicationEnabled: bool, deletionProtectionEnabled: bool, denyMaintenancePeriods: list<record>, insightsConfig: record<queryInsightsEnabled: bool, queryPlansPerMinute: int, queryStringLength: int, recordApplicationTags: bool, recordClientAddress: bool>, ipConfiguration: record<allocatedIpRange: string, authorizedNetworks: list, enablePrivatePathForGoogleCloudServices: bool, ipv4Enabled: bool, privateNetwork: string, requireSsl: bool>, kind: string, locationPreference: record<followGaeApplication: string, kind: string, secondaryZone: string, zone: string>, maintenanceWindow: record<day: int, hour: int, kind: string, updateTrack: string>, passwordValidationPolicy: record<complexity: string, disallowUsernameSubstring: bool, enablePasswordPolicy: bool, minLength: int, passwordChangeInterval: string, reuseInterval: int>, pricingPlan: string, replicationType: string, settingsVersion: string, sqlServerAuditConfig: record<bucket: string, kind: string, retentionInterval: string, uploadInterval: string>, storageAutoResize: bool, storageAutoResizeLimit: string, tier: string, timeZone: string, userLabels: record>, state: string, suspensionReason: list<string>>
# operationId: sql.instances.get
export def "sql-instances-get" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially updates settings of a Cloud SQL instance by merging the request with the current configuration. This method supports patch semantics.
#
# PATCH /sql/v1beta4/projects/{project}/instances/{instance}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.patch
export def "sql-instances-patch" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --backend-type: string@backend-type-completer # The backend type. `SECOND_GEN`: Cloud SQL database instance. `EXTERNAL`: A database server that is not managed by Google. This property is read-only; use the `tier` property in the `settings` object to determine the database type.
  --connection-name: string # Connection name of the Cloud SQL instance used in connection strings.
  --current-disk-size: string # The current disk usage of the instance in bytes. This property has been deprecated. Use the "cloudsql.googleapis.com/database/disk/bytes_used" metric in Cloud Monitoring API instead. Please see [this announcement](https://groups.google.com/d/msg/google-cloud-sql-announce/I_7-F9EBhT0/BtvFtdFeAgAJ) for details. (format: int64)
  --database-version: string@database-version-completer # The database engine type and version. The `databaseVersion` field cannot be changed after instance creation.
  --disk-encryption-configuration: record # Disk encryption configuration for an instance. — shape: {kind?: string, kmsKeyName?: string}
  --disk-encryption-status: record # Disk encryption status for an instance. — shape: {kind?: string, kmsKeyVersionName?: string}
  --etag: string # This field is deprecated and will be removed from a future version of the API. Use the `settings.settingsVersion` field instead.
  --failover-replica: record # The name and status of the failover replica. — shape: {available?: bool, name?: string}
  --gce-zone: string # The Compute Engine zone that the instance is currently serving from. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary zone. WARNING: Changing this might restart the instance.
  --instance-type: string@instance-type-completer # The instance type.
  --ip-addresses: list # The assigned IP addresses for the instance. — item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
  --ipv6-address: string # The IPv6 address assigned to the instance. (Deprecated) This property was applicable only to First Generation instances.
  --kind: string # This is always `sql#instance`.
  --maintenance-version: string # The current software version on the instance.
  --master-instance-name: string # The name of the instance which will act as primary in the replication setup.
  --max-disk-size: string # The maximum disk size of the instance in bytes. (format: int64)
  --name: string # Name of the Cloud SQL instance. This does not include the project ID.
  --on-premises-configuration: record # On-premises instance configuration. — shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
  --out-of-disk-report: record # This message wraps up the information written by out-of-disk detection job. — shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
  --body-project: string # The project ID of the project containing the Cloud SQL instance. The Google apps domain is prefixed if applicable. (spec name: project)
  --region: string # The geographical region. Can be: * `us-central` (`FIRST_GEN` instances only) * `us-central1` (`SECOND_GEN` instances only) * `asia-east1` or `europe-west1`. Defaults to `us-central` or `us-central1` depending on the instance type. The region cannot be changed after instance creation.
  --replica-configuration: record # Read-replica configuration for connecting to the primary instance. — shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
  --replica-names: list<string> # The replicas of the instance.
  --root-password: string # Initial root password. Use only on creation. You must set root passwords before you can connect to PostgreSQL instances.
  --satisfies-pzs: oneof<nothing, bool> # The status indicating if instance satisfiesPzs. Reserved for future use.
  --scheduled-maintenance: record # Any scheduled maintenance for this instance. — shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
  --secondary-gce-zone: string # The Compute Engine zone that the failover instance is currently serving from for a regional instance. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary/failover zone.
  --self-link: string # The URI of this resource.
  --server-ca-cert: record # SslCerts Resource — shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
  --service-account-email-address: string # The service account email address assigned to the instance. \This property is read-only.
  --settings: record # Database instance settings. — shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
  --state: string@state-completer # The current serving state of the Cloud SQL instance.
  --suspension-reason: list<string> # If the instance state is SUSPENDED, the reason for the suspension.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sql/v1beta4/projects/{project}/instances/{instance}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: backendType, var: backend_type}, {name: connectionName, var: connection_name}, {name: currentDiskSize, var: current_disk_size}, {name: databaseVersion, var: database_version}, {name: diskEncryptionConfiguration, var: disk_encryption_configuration}, {name: diskEncryptionStatus, var: disk_encryption_status}, {name: etag, var: etag}, {name: failoverReplica, var: failover_replica}, {name: gceZone, var: gce_zone}, {name: instanceType, var: instance_type}, {name: ipAddresses, var: ip_addresses}, {name: ipv6Address, var: ipv6_address}, {name: kind, var: kind}, {name: maintenanceVersion, var: maintenance_version}, {name: masterInstanceName, var: master_instance_name}, {name: maxDiskSize, var: max_disk_size}, {name: name, var: name}, {name: onPremisesConfiguration, var: on_premises_configuration}, {name: outOfDiskReport, var: out_of_disk_report}, {name: project, var: body_project}, {name: region, var: region}, {name: replicaConfiguration, var: replica_configuration}, {name: replicaNames, var: replica_names}, {name: rootPassword, var: root_password}, {name: satisfiesPzs, var: satisfies_pzs}, {name: scheduledMaintenance, var: scheduled_maintenance}, {name: secondaryGceZone, var: secondary_gce_zone}, {name: selfLink, var: self_link}, {name: serverCaCert, var: server_ca_cert}, {name: serviceAccountEmailAddress, var: service_account_email_address}, {name: settings, var: settings}, {name: state, var: state}, {name: suspensionReason, var: suspension_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, backend_type: $backend_type, connection_name: $connection_name, current_disk_size: $current_disk_size, database_version: $database_version, disk_encryption_configuration: $disk_encryption_configuration, disk_encryption_status: $disk_encryption_status, etag: $etag, failover_replica: $failover_replica, gce_zone: $gce_zone, instance_type: $instance_type, ip_addresses: $ip_addresses, ipv6_address: $ipv6_address, kind: $kind, maintenance_version: $maintenance_version, master_instance_name: $master_instance_name, max_disk_size: $max_disk_size, name: $name, on_premises_configuration: $on_premises_configuration, out_of_disk_report: $out_of_disk_report, body_project: $body_project, region: $region, replica_configuration: $replica_configuration, replica_names: $replica_names, root_password: $root_password, satisfies_pzs: $satisfies_pzs, scheduled_maintenance: $scheduled_maintenance, secondary_gce_zone: $secondary_gce_zone, self_link: $self_link, server_ca_cert: $server_ca_cert, service_account_email_address: $service_account_email_address, settings: $settings, state: $state, suspension_reason: $suspension_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates settings of a Cloud SQL instance. Using this operation might cause your instance to restart.
#
# PUT /sql/v1beta4/projects/{project}/instances/{instance}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.update
export def "sql-instances-update" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --backend-type: string@backend-type-completer # The backend type. `SECOND_GEN`: Cloud SQL database instance. `EXTERNAL`: A database server that is not managed by Google. This property is read-only; use the `tier` property in the `settings` object to determine the database type.
  --connection-name: string # Connection name of the Cloud SQL instance used in connection strings.
  --current-disk-size: string # The current disk usage of the instance in bytes. This property has been deprecated. Use the "cloudsql.googleapis.com/database/disk/bytes_used" metric in Cloud Monitoring API instead. Please see [this announcement](https://groups.google.com/d/msg/google-cloud-sql-announce/I_7-F9EBhT0/BtvFtdFeAgAJ) for details. (format: int64)
  --database-version: string@database-version-completer # The database engine type and version. The `databaseVersion` field cannot be changed after instance creation.
  --disk-encryption-configuration: record # Disk encryption configuration for an instance. — shape: {kind?: string, kmsKeyName?: string}
  --disk-encryption-status: record # Disk encryption status for an instance. — shape: {kind?: string, kmsKeyVersionName?: string}
  --etag: string # This field is deprecated and will be removed from a future version of the API. Use the `settings.settingsVersion` field instead.
  --failover-replica: record # The name and status of the failover replica. — shape: {available?: bool, name?: string}
  --gce-zone: string # The Compute Engine zone that the instance is currently serving from. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary zone. WARNING: Changing this might restart the instance.
  --instance-type: string@instance-type-completer # The instance type.
  --ip-addresses: list # The assigned IP addresses for the instance. — item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
  --ipv6-address: string # The IPv6 address assigned to the instance. (Deprecated) This property was applicable only to First Generation instances.
  --kind: string # This is always `sql#instance`.
  --maintenance-version: string # The current software version on the instance.
  --master-instance-name: string # The name of the instance which will act as primary in the replication setup.
  --max-disk-size: string # The maximum disk size of the instance in bytes. (format: int64)
  --name: string # Name of the Cloud SQL instance. This does not include the project ID.
  --on-premises-configuration: record # On-premises instance configuration. — shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
  --out-of-disk-report: record # This message wraps up the information written by out-of-disk detection job. — shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
  --body-project: string # The project ID of the project containing the Cloud SQL instance. The Google apps domain is prefixed if applicable. (spec name: project)
  --region: string # The geographical region. Can be: * `us-central` (`FIRST_GEN` instances only) * `us-central1` (`SECOND_GEN` instances only) * `asia-east1` or `europe-west1`. Defaults to `us-central` or `us-central1` depending on the instance type. The region cannot be changed after instance creation.
  --replica-configuration: record # Read-replica configuration for connecting to the primary instance. — shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
  --replica-names: list<string> # The replicas of the instance.
  --root-password: string # Initial root password. Use only on creation. You must set root passwords before you can connect to PostgreSQL instances.
  --satisfies-pzs: oneof<nothing, bool> # The status indicating if instance satisfiesPzs. Reserved for future use.
  --scheduled-maintenance: record # Any scheduled maintenance for this instance. — shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
  --secondary-gce-zone: string # The Compute Engine zone that the failover instance is currently serving from for a regional instance. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary/failover zone.
  --self-link: string # The URI of this resource.
  --server-ca-cert: record # SslCerts Resource — shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
  --service-account-email-address: string # The service account email address assigned to the instance. \This property is read-only.
  --settings: record # Database instance settings. — shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
  --state: string@state-completer # The current serving state of the Cloud SQL instance.
  --suspension-reason: list<string> # If the instance state is SUSPENDED, the reason for the suspension.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sql/v1beta4/projects/{project}/instances/{instance}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: backendType, var: backend_type}, {name: connectionName, var: connection_name}, {name: currentDiskSize, var: current_disk_size}, {name: databaseVersion, var: database_version}, {name: diskEncryptionConfiguration, var: disk_encryption_configuration}, {name: diskEncryptionStatus, var: disk_encryption_status}, {name: etag, var: etag}, {name: failoverReplica, var: failover_replica}, {name: gceZone, var: gce_zone}, {name: instanceType, var: instance_type}, {name: ipAddresses, var: ip_addresses}, {name: ipv6Address, var: ipv6_address}, {name: kind, var: kind}, {name: maintenanceVersion, var: maintenance_version}, {name: masterInstanceName, var: master_instance_name}, {name: maxDiskSize, var: max_disk_size}, {name: name, var: name}, {name: onPremisesConfiguration, var: on_premises_configuration}, {name: outOfDiskReport, var: out_of_disk_report}, {name: project, var: body_project}, {name: region, var: region}, {name: replicaConfiguration, var: replica_configuration}, {name: replicaNames, var: replica_names}, {name: rootPassword, var: root_password}, {name: satisfiesPzs, var: satisfies_pzs}, {name: scheduledMaintenance, var: scheduled_maintenance}, {name: secondaryGceZone, var: secondary_gce_zone}, {name: selfLink, var: self_link}, {name: serverCaCert, var: server_ca_cert}, {name: serviceAccountEmailAddress, var: service_account_email_address}, {name: settings, var: settings}, {name: state, var: state}, {name: suspensionReason, var: suspension_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, backend_type: $backend_type, connection_name: $connection_name, current_disk_size: $current_disk_size, database_version: $database_version, disk_encryption_configuration: $disk_encryption_configuration, disk_encryption_status: $disk_encryption_status, etag: $etag, failover_replica: $failover_replica, gce_zone: $gce_zone, instance_type: $instance_type, ip_addresses: $ip_addresses, ipv6_address: $ipv6_address, kind: $kind, maintenance_version: $maintenance_version, master_instance_name: $master_instance_name, max_disk_size: $max_disk_size, name: $name, on_premises_configuration: $on_premises_configuration, out_of_disk_report: $out_of_disk_report, body_project: $body_project, region: $region, replica_configuration: $replica_configuration, replica_names: $replica_names, root_password: $root_password, satisfies_pzs: $satisfies_pzs, scheduled_maintenance: $scheduled_maintenance, secondary_gce_zone: $secondary_gce_zone, self_link: $self_link, server_ca_cert: $server_ca_cert, service_account_email_address: $service_account_email_address, settings: $settings, state: $state, suspension_reason: $suspension_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new trusted Certificate Authority (CA) version for the specified instance. Required to prepare for a certificate rotation. If a CA version was previously added but never used in a certificate rotation, this operation replaces that version. There cannot be more than one CA version waiting to be rotated in.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/addServerCa
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.addServerCa
export def "sql-instances-add-server-ca" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/addServerCa"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all backup runs associated with the project or a given instance and configuration in the reverse chronological order of the backup initiation time.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/backupRuns
# Returns: record<items: table<backupKind: string, description: string, diskEncryptionConfiguration: record, diskEncryptionStatus: record, endTime: string, enqueuedTime: string, error: record, id: string, instance: string, kind: string, location: string, selfLink: string, startTime: string, status: string, timeZone: string, type: string, windowStartTime: string>, kind: string, nextPageToken: string>
# operationId: sql.backupRuns.list
export def "sql-backup-runs-list" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Maximum number of backup runs per response.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/backupRuns"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new backup run on demand.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/backupRuns
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.backupRuns.insert
export def "sql-backup-runs-insert" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --backup-kind: string@backup-kind-completer # Specifies the kind of backup, PHYSICAL or DEFAULT_SNAPSHOT.
  --description: string # The description of this run, only applicable to on-demand backups.
  --disk-encryption-configuration: record # Disk encryption configuration for an instance. — shape: {kind?: string, kmsKeyName?: string}
  --disk-encryption-status: record # Disk encryption status for an instance. — shape: {kind?: string, kmsKeyVersionName?: string}
  --end-time: string # The time the backup operation completed in UTC timezone in [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example `2012-11-15T16:19:00.094Z`. (format: google-datetime)
  --enqueued-time: string # The time the run was enqueued in UTC timezone in [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example `2012-11-15T16:19:00.094Z`. (format: google-datetime)
  --error: record # Database instance operation error. — shape: {code?: string, kind?: string, message?: string}
  --id: string # The identifier for this backup run. Unique only for a specific Cloud SQL instance. (format: int64)
  --body-instance: string # Name of the database instance. (spec name: instance)
  --kind: string # This is always `sql#backupRun`.
  --location: string # Location of the backups.
  --self-link: string # The URI of this resource.
  --start-time: string # The time the backup operation actually started in UTC timezone in [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example `2012-11-15T16:19:00.094Z`. (format: google-datetime)
  --status: string@status-completer # The status of this run.
  --time-zone: string # Backup time zone to prevent restores to an instance with a different time zone. Now relevant only for SQL Server.
  --type: string@type-completer # The type of this run; can be either "AUTOMATED" or "ON_DEMAND" or "FINAL". This field defaults to "ON_DEMAND" and is ignored, when specified for insert requests.
  --window-start-time: string # The start time of the backup window during which this the backup was attempted in [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example `2012-11-15T16:19:00.094Z`. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/backupRuns"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: backupKind, var: backup_kind}, {name: description, var: description}, {name: diskEncryptionConfiguration, var: disk_encryption_configuration}, {name: diskEncryptionStatus, var: disk_encryption_status}, {name: endTime, var: end_time}, {name: enqueuedTime, var: enqueued_time}, {name: error, var: error}, {name: id, var: id}, {name: instance, var: body_instance}, {name: kind, var: kind}, {name: location, var: location}, {name: selfLink, var: self_link}, {name: startTime, var: start_time}, {name: status, var: status}, {name: timeZone, var: time_zone}, {name: type, var: type}, {name: windowStartTime, var: window_start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, backup_kind: $backup_kind, description: $description, disk_encryption_configuration: $disk_encryption_configuration, disk_encryption_status: $disk_encryption_status, end_time: $end_time, enqueued_time: $enqueued_time, error: $error, id: $id, body_instance: $body_instance, kind: $kind, location: $location, self_link: $self_link, start_time: $start_time, status: $status, time_zone: $time_zone, type: $type, window_start_time: $window_start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the backup taken by a backup run.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}/backupRuns/{id}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.backupRuns.delete
export def "sql-backup-runs-delete" [
  project: string
  instance: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/backupRuns/{id}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a resource containing information about a backup run.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/backupRuns/{id}
# Returns: record<backupKind: string, description: string, diskEncryptionConfiguration: record<kind: string, kmsKeyName: string>, diskEncryptionStatus: record<kind: string, kmsKeyVersionName: string>, endTime: string, enqueuedTime: string, error: record<code: string, kind: string, message: string>, id: string, instance: string, kind: string, location: string, selfLink: string, startTime: string, status: string, timeZone: string, type: string, windowStartTime: string>
# operationId: sql.backupRuns.get
export def "sql-backup-runs-get" [
  project: string
  instance: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/backupRuns/{id}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Cloud SQL instance as a clone of the source instance. Using this operation might cause your instance to restart.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/clone
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.clone
export def "sql-instances-clone" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --clone-context: record # Database instance clone context. — shape: {allocatedIpRange?: string, binLogCoordinates?: record, databaseNames?: list<string>, destinationInstanceName?: string, kind?: string, pitrTimestampMs?: string, pointInTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/clone"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloneContext, var: clone_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, clone_context: $clone_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves connect settings about a Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/connectSettings
# Returns: record<backendType: string, databaseVersion: string, ipAddresses: table<ipAddress: string, timeToRetire: string, type: string>, kind: string, region: string, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>>
# operationId: sql.connect.get
export def "sql-connect-get" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --read-time: string # Optional. Optional snapshot read timestamp to trade freshness for performance.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/connectSettings"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: readTime, var: read_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, read_time: $read_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a short-lived X509 certificate containing the provided public key and signed by a private key specific to the target instance. Users may use the certificate to authenticate as themselves when connecting to the database.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/createEphemeral
# Returns: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>
# operationId: sql.sslCerts.createEphemeral
export def "sql-ssl-certs-create-ephemeral" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-access-token: string # Access token to include in the signed certificate. (spec name: access_token)
  --public-key: string # PEM encoded public key to include in the signed certificate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/createEphemeral"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_token, var: body_access_token}, {name: public_key, var: public_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_access_token: $body_access_token, public_key: $public_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists databases in the specified Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/databases
# Returns: record<items: table<charset: string, collation: string, etag: string, instance: string, kind: string, name: string, project: string, selfLink: string, sqlserverDatabaseDetails: record>, kind: string>
# operationId: sql.databases.list
export def "sql-databases-list" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/databases"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a resource containing information about a database inside a Cloud SQL instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/databases
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.databases.insert
export def "sql-databases-insert" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --charset: string # The Cloud SQL charset value.
  --collation: string # The Cloud SQL collation value.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID. (spec name: instance)
  --kind: string # This is always `sql#database`.
  --name: string # The name of the database in the Cloud SQL instance. This does not include the project ID or instance name.
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable. (spec name: project)
  --self-link: string # The URI of this resource.
  --sqlserver-database-details: record # Represents a Sql Server database on the Cloud SQL instance. — shape: {compatibilityLevel?: int, recoveryModel?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/databases"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: charset, var: charset}, {name: collation, var: collation}, {name: etag, var: etag}, {name: instance, var: body_instance}, {name: kind, var: kind}, {name: name, var: name}, {name: project, var: body_project}, {name: selfLink, var: self_link}, {name: sqlserverDatabaseDetails, var: sqlserver_database_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, charset: $charset, collation: $collation, etag: $etag, body_instance: $body_instance, kind: $kind, name: $name, body_project: $body_project, self_link: $self_link, sqlserver_database_details: $sqlserver_database_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a database from a Cloud SQL instance.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.databases.delete
export def "sql-databases-delete" [
  project: string
  instance: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: database, var: database}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, database: $database, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a resource containing information about a database inside a Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}
# Returns: record<charset: string, collation: string, etag: string, instance: string, kind: string, name: string, project: string, selfLink: string, sqlserverDatabaseDetails: record<compatibilityLevel: int, recoveryModel: string>>
# operationId: sql.databases.get
export def "sql-databases-get" [
  project: string
  instance: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: database, var: database}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, database: $database, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially updates a resource containing information about a database inside a Cloud SQL instance. This method supports patch semantics.
#
# PATCH /sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.databases.patch
export def "sql-databases-patch" [
  project: string
  instance: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --charset: string # The Cloud SQL charset value.
  --collation: string # The Cloud SQL collation value.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID. (spec name: instance)
  --kind: string # This is always `sql#database`.
  --name: string # The name of the database in the Cloud SQL instance. This does not include the project ID or instance name.
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable. (spec name: project)
  --self-link: string # The URI of this resource.
  --sqlserver-database-details: record # Represents a Sql Server database on the Cloud SQL instance. — shape: {compatibilityLevel?: int, recoveryModel?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: database, var: database}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: charset, var: charset}, {name: collation, var: collation}, {name: etag, var: etag}, {name: instance, var: body_instance}, {name: kind, var: kind}, {name: name, var: name}, {name: project, var: body_project}, {name: selfLink, var: self_link}, {name: sqlserverDatabaseDetails, var: sqlserver_database_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, database: $database, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, charset: $charset, collation: $collation, etag: $etag, body_instance: $body_instance, kind: $kind, name: $name, body_project: $body_project, self_link: $self_link, sqlserver_database_details: $sqlserver_database_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a resource containing information about a database inside a Cloud SQL instance.
#
# PUT /sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.databases.update
export def "sql-databases-update" [
  project: string
  instance: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --charset: string # The Cloud SQL charset value.
  --collation: string # The Cloud SQL collation value.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID. (spec name: instance)
  --kind: string # This is always `sql#database`.
  --name: string # The name of the database in the Cloud SQL instance. This does not include the project ID or instance name.
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable. (spec name: project)
  --self-link: string # The URI of this resource.
  --sqlserver-database-details: record # Represents a Sql Server database on the Cloud SQL instance. — shape: {compatibilityLevel?: int, recoveryModel?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: database, var: database}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: charset, var: charset}, {name: collation, var: collation}, {name: etag, var: etag}, {name: instance, var: body_instance}, {name: kind, var: kind}, {name: name, var: name}, {name: project, var: body_project}, {name: selfLink, var: self_link}, {name: sqlserverDatabaseDetails, var: sqlserver_database_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, database: $database, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, charset: $charset, collation: $collation, etag: $etag, body_instance: $body_instance, kind: $kind, name: $name, body_project: $body_project, self_link: $self_link, sqlserver_database_details: $sqlserver_database_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Demotes the stand-alone instance to be a Cloud SQL read replica for an external database server.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/demoteMaster
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.demoteMaster
export def "sql-instances-demote-master" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --demote-master-context: record # Database instance demote primary instance context. — shape: {kind?: string, masterInstanceName?: string, replicaConfiguration?: record, skipReplicationSetup?: bool, verifyGtidConsistency?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/demoteMaster"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: demoteMasterContext, var: demote_master_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, demote_master_context: $demote_master_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports data from a Cloud SQL instance to a Cloud Storage bucket as a SQL dump or CSV file.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/export
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.export
export def "sql-instances-export" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --export-context: record # Database instance export context. — shape: {bakExportOptions?: record, csvExportOptions?: record, databases?: list<string>, fileType?: "SQL_FILE_TYPE_UNSPECIFIED"|"SQL"|"CSV"|"BAK", kind?: string, offload?: bool, sqlExportOptions?: record, uri?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/export"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: exportContext, var: export_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, export_context: $export_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a manual failover of a high availability (HA) primary instance to a standby instance, which becomes the primary instance. Users are then rerouted to the new primary. For more information, see the [Overview of high availability](https://cloud.google.com/sql/docs/mysql/high-availability) page in the Cloud SQL documentation. If using Legacy HA (MySQL only), this causes the instance to failover to its failover replica instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/failover
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.failover
export def "sql-instances-failover" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --failover-context: record # Database instance failover context. — shape: {kind?: string, settingsVersion?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/failover"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: failoverContext, var: failover_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, failover_context: $failover_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Disk Shrink Config for a given instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/getDiskShrinkConfig
# Returns: record<kind: string, minimalTargetSizeGb: string>
# operationId: sql.projects.instances.getDiskShrinkConfig
export def "sql-projects-instances-get-disk-shrink-config" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/getDiskShrinkConfig"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports data into a Cloud SQL instance from a SQL dump or CSV file in Cloud Storage.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/import
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.import
export def "sql-instances-import" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --import-context: record # Database instance import context. — shape: {bakImportOptions?: record, csvImportOptions?: record, database?: string, fileType?: "SQL_FILE_TYPE_UNSPECIFIED"|"SQL"|"CSV"|"BAK", importUser?: string, kind?: string, uri?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/import"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: importContext, var: import_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, import_context: $import_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the trusted Certificate Authorities (CAs) for the specified instance. There can be up to three CAs listed: the CA that was used to sign the certificate that is currently in use, a CA that has been added but not yet used to sign a certificate, and a CA used to sign a certificate that has previously rotated out.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/listServerCas
# Returns: record<activeVersion: string, certs: table<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, kind: string>
# operationId: sql.instances.listServerCas
export def "sql-instances-list-server-cas" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/listServerCas"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform Disk Shrink on primary instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/performDiskShrink
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.projects.instances.performDiskShrink
export def "sql-projects-instances-perform-disk-shrink" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --target-size-gb: string # The target disk shrink size in GigaBytes. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/performDiskShrink"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetSizeGb, var: target_size_gb}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, target_size_gb: $target_size_gb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promotes the read replica instance to be a stand-alone Cloud SQL instance. Using this operation might cause your instance to restart.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/promoteReplica
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.promoteReplica
export def "sql-instances-promote-replica" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/promoteReplica"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reschedules the maintenance on the given instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/rescheduleMaintenance
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.projects.instances.rescheduleMaintenance
export def "sql-projects-instances-reschedule-maintenance" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --reschedule: record # shape: {rescheduleType?: "RESCHEDULE_TYPE_UNSPECIFIED"|"IMMEDIATE"|"NEXT_AVAILABLE_WINDOW"|"SPECIFIC_TIME", scheduleTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/rescheduleMaintenance"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: reschedule, var: reschedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, reschedule: $reschedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset Replica Size to primary instance disk size.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/resetReplicaSize
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.projects.instances.resetReplicaSize
export def "sql-projects-instances-reset-replica-size" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/resetReplicaSize"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all client certificates and generates a new server SSL certificate for the instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/resetSslConfig
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.resetSslConfig
export def "sql-instances-reset-ssl-config" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/resetSslConfig"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a Cloud SQL instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/restart
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.restart
export def "sql-instances-restart" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/restart"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a backup of a Cloud SQL instance. Using this operation might cause your instance to restart.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/restoreBackup
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.restoreBackup
export def "sql-instances-restore-backup" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --restore-backup-context: record # Database instance restore from backup context. Backup context contains source instance id and project id. — shape: {backupRunId?: string, instanceId?: string, kind?: string, project?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/restoreBackup"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: restoreBackupContext, var: restore_backup_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, restore_backup_context: $restore_backup_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rotates the server certificate to one signed by the Certificate Authority (CA) version previously added with the addServerCA method.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/rotateServerCa
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.rotateServerCa
export def "sql-instances-rotate-server-ca" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --rotate-server-ca-context: record # Instance rotate server CA context. — shape: {kind?: string, nextVersion?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/rotateServerCa"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: rotateServerCaContext, var: rotate_server_ca_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, rotate_server_ca_context: $rotate_server_ca_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the current SSL certificates for the instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/sslCerts
# Returns: record<items: table<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, kind: string>
# operationId: sql.sslCerts.list
export def "sql-ssl-certs-list" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/sslCerts"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an SSL certificate and returns it along with the private key and server certificate authority. The new certificate will not be usable until the instance is restarted.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/sslCerts
# Returns: record<clientCert: record<certInfo: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, certPrivateKey: string>, kind: string, operation: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list, kind: string>, exportContext: record<bakExportOptions: record, csvExportOptions: record, databases: list, fileType: string, kind: string, offload: bool, sqlExportOptions: record, uri: string>, importContext: record<bakImportOptions: record, csvImportOptions: record, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>>
# operationId: sql.sslCerts.insert
export def "sql-ssl-certs-insert" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --common-name: string # User supplied name. Must be a distinct name from the other certificates for this instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/sslCerts"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: commonName, var: common_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, common_name: $common_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the SSL certificate. For First Generation instances, the certificate remains valid until the instance is restarted.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}/sslCerts/{sha1Fingerprint}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.sslCerts.delete
export def "sql-ssl-certs-delete" [
  project: string
  instance: string
  sha1_fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/sslCerts/{sha1Fingerprint}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: sha1Fingerprint, var: sha1_fingerprint}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, sha1_fingerprint: $sha1_fingerprint, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a particular SSL certificate. Does not include the private key (required for usage). The private key must be saved from the response to initial creation.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/sslCerts/{sha1Fingerprint}
# Returns: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>
# operationId: sql.sslCerts.get
export def "sql-ssl-certs-get" [
  project: string
  instance: string
  sha1_fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/sslCerts/{sha1Fingerprint}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: sha1Fingerprint, var: sha1_fingerprint}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, sha1_fingerprint: $sha1_fingerprint, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start External primary instance migration.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/startExternalSync
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.projects.instances.startExternalSync
export def "sql-projects-instances-start-external-sync" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --mysql-sync-config: record # MySQL-specific external server sync settings. — shape: {initialSyncFlags?: list}
  --skip-verification: oneof<nothing, bool> # Whether to skip the verification step (VESS).
  --sync-mode: string@sync-mode-completer # External sync mode.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/startExternalSync"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: mysqlSyncConfig, var: mysql_sync_config}, {name: skipVerification, var: skip_verification}, {name: syncMode, var: sync_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, mysql_sync_config: $mysql_sync_config, skip_verification: $skip_verification, sync_mode: $sync_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the replication in the read replica instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/startReplica
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.startReplica
export def "sql-instances-start-replica" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/startReplica"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the replication in the read replica instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/stopReplica
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.stopReplica
export def "sql-instances-stop-replica" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/stopReplica"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Truncate MySQL general and slow query log tables MySQL only.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/truncateLog
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.instances.truncateLog
export def "sql-instances-truncate-log" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --truncate-log-context: record # Database Instance truncate log context. — shape: {kind?: string, logType?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/truncateLog"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: truncateLogContext, var: truncate_log_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, truncate_log_context: $truncate_log_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a user from a Cloud SQL instance.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}/users
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.users.delete
export def "sql-users-delete" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --host: string # Host of the user in the instance.
  --name: string # Name of the user in the instance.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/users"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: host, var: host}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, host: $host, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists users in the specified Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/users
# Returns: record<items: table<dualPasswordType: string, etag: string, host: string, instance: string, kind: string, name: string, password: string, passwordPolicy: record, project: string, sqlserverUserDetails: record, type: string>, kind: string, nextPageToken: string>
# operationId: sql.users.list
export def "sql-users-list" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/users"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new user in a Cloud SQL instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/users
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.users.insert
export def "sql-users-insert" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dual-password-type: string@dual-password-type-completer # Dual password status for the user.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --host: string # Optional. The host from which the user can connect. For `insert` operations, host defaults to an empty string. For `update` operations, host is specified as part of the request URL. The host name cannot be updated after insertion. For a MySQL instance, it's required; for a PostgreSQL or SQL Server instance, it's optional.
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID. Can be omitted for *update* because it is already specified on the URL. (spec name: instance)
  --kind: string # This is always `sql#user`.
  --name: string # The name of the user in the Cloud SQL instance. Can be omitted for `update` because it is already specified in the URL.
  --password: string # The password for the user.
  --password-policy: record # User level password validation policy. — shape: {allowedFailedAttempts?: int, enableFailedAttemptsCheck?: bool, enablePasswordVerification?: bool, passwordExpirationDuration?: string, status?: record}
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable. Can be omitted for *update* because it is already specified on the URL. (spec name: project)
  --sqlserver-user-details: record # Represents a Sql Server user on the Cloud SQL instance. — shape: {disabled?: bool, serverRoles?: list<string>}
  --type: string@type-completer-1 # The user type. It determines the method to authenticate the user during login. The default is the database's built-in user type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/users"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dualPasswordType, var: dual_password_type}, {name: etag, var: etag}, {name: host, var: host}, {name: instance, var: body_instance}, {name: kind, var: kind}, {name: name, var: name}, {name: password, var: password}, {name: passwordPolicy, var: password_policy}, {name: project, var: body_project}, {name: sqlserverUserDetails, var: sqlserver_user_details}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dual_password_type: $dual_password_type, etag: $etag, host: $host, body_instance: $body_instance, kind: $kind, name: $name, password: $password, password_policy: $password_policy, body_project: $body_project, sqlserver_user_details: $sqlserver_user_details, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing user in a Cloud SQL instance.
#
# PUT /sql/v1beta4/projects/{project}/instances/{instance}/users
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.users.update
export def "sql-users-update" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --host: string # Optional. Host of the user in the instance.
  --name: string # Name of the user in the instance.
  --dual-password-type: string@dual-password-type-completer # Dual password status for the user.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --body-host: string # Optional. The host from which the user can connect. For `insert` operations, host defaults to an empty string. For `update` operations, host is specified as part of the request URL. The host name cannot be updated after insertion. For a MySQL instance, it's required; for a PostgreSQL or SQL Server instance, it's optional. (spec name: host)
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID. Can be omitted for *update* because it is already specified on the URL. (spec name: instance)
  --kind: string # This is always `sql#user`.
  --body-name: string # The name of the user in the Cloud SQL instance. Can be omitted for `update` because it is already specified in the URL. (spec name: name)
  --password: string # The password for the user.
  --password-policy: record # User level password validation policy. — shape: {allowedFailedAttempts?: int, enableFailedAttemptsCheck?: bool, enablePasswordVerification?: bool, passwordExpirationDuration?: string, status?: record}
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable. Can be omitted for *update* because it is already specified on the URL. (spec name: project)
  --sqlserver-user-details: record # Represents a Sql Server user on the Cloud SQL instance. — shape: {disabled?: bool, serverRoles?: list<string>}
  --type: string@type-completer-1 # The user type. It determines the method to authenticate the user during login. The default is the database's built-in user type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/users"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: host, var: host}, {name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: dualPasswordType, var: dual_password_type}, {name: etag, var: etag}, {name: host, var: body_host}, {name: instance, var: body_instance}, {name: kind, var: kind}, {name: name, var: body_name}, {name: password, var: password}, {name: passwordPolicy, var: password_policy}, {name: project, var: body_project}, {name: sqlserverUserDetails, var: sqlserver_user_details}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, host: $host, name: $name, dual_password_type: $dual_password_type, etag: $etag, body_host: $body_host, body_instance: $body_instance, kind: $kind, body_name: $body_name, password: $password, password_policy: $password_policy, body_project: $body_project, sqlserver_user_details: $sqlserver_user_details, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a resource containing information about a user.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/users/{name}
# Returns: record<dualPasswordType: string, etag: string, host: string, instance: string, kind: string, name: string, password: string, passwordPolicy: record<allowedFailedAttempts: int, enableFailedAttemptsCheck: bool, enablePasswordVerification: bool, passwordExpirationDuration: string, status: record<locked: bool, passwordExpirationTime: string>>, project: string, sqlserverUserDetails: record<disabled: bool, serverRoles: list<string>>, type: string>
# operationId: sql.users.get
export def "sql-users-get" [
  project: string
  instance: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --host: string # Host of a user of the instance.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/users/{name}"
    path_params: [{name: project, var: project}, {name: instance, var: instance}, {name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: host, var: host}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, host: $host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify External primary instance external sync settings.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/verifyExternalSyncSettings
# Returns: record<errors: table<detail: string, kind: string, type: string>, kind: string, warnings: table<detail: string, kind: string, type: string>>
# operationId: sql.projects.instances.verifyExternalSyncSettings
export def "sql-projects-instances-verify-external-sync-settings" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --mysql-sync-config: record # MySQL-specific external server sync settings. — shape: {initialSyncFlags?: list}
  --sync-mode: string@sync-mode-completer # External sync mode
  --verify-connection-only: oneof<nothing, bool> # Flag to enable verifying connection only
  --verify-replication-only: oneof<nothing, bool> # Optional. Flag to verify settings required by replication setup only
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}/verifyExternalSyncSettings"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: mysqlSyncConfig, var: mysql_sync_config}, {name: syncMode, var: sync_mode}, {name: verifyConnectionOnly, var: verify_connection_only}, {name: verifyReplicationOnly, var: verify_replication_only}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, mysql_sync_config: $mysql_sync_config, sync_mode: $sync_mode, verify_connection_only: $verify_connection_only, verify_replication_only: $verify_replication_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a short-lived X509 certificate containing the provided public key and signed by a private key specific to the target instance. Users may use the certificate to authenticate as themselves when connecting to the database.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}:generateEphemeralCert
# Returns: record<ephemeralCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>>
# operationId: sql.connect.generateEphemeral
export def "sql-connect-generate-ephemeral" [
  project: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-access-token: string # Optional. Access token to include in the signed certificate. (spec name: access_token)
  --public-key: string # PEM encoded public key to include in the signed certificate.
  --read-time: string # Optional. Optional snapshot read timestamp to trade freshness for performance. (format: google-datetime)
  --valid-duration: string # Optional. If set, it will contain the cert valid duration. (format: google-duration)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sql/v1beta4/projects/{project}/instances/{instance}:generateEphemeralCert"
    path_params: [{name: project, var: project}, {name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_token, var: body_access_token}, {name: public_key, var: public_key}, {name: readTime, var: read_time}, {name: validDuration, var: valid_duration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_access_token: $body_access_token, public_key: $public_key, read_time: $read_time, valid_duration: $valid_duration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all instance operations that have been performed on the given Cloud SQL instance in the reverse chronological order of the start time.
#
# GET /sql/v1beta4/projects/{project}/operations
# Returns: record<items: table<backupContext: record, endTime: string, error: record, exportContext: record, importContext: record, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>, kind: string, nextPageToken: string>
# operationId: sql.operations.list
export def "sql-operations-list" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --instance: string # Cloud SQL instance ID. This does not include the project ID.
  --max-results: int # Maximum number of operations per response.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/operations"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: instance, var: instance}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, instance: $instance, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an instance operation that has been performed on an instance.
#
# GET /sql/v1beta4/projects/{project}/operations/{operation}
# Returns: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>
# operationId: sql.operations.get
export def "sql-operations-get" [
  project: string
  operation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/operations/{operation}"
    path_params: [{name: project, var: project}, {name: operation, var: operation}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, operation: $operation, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all available machine types (tiers) for Cloud SQL, for example, `db-custom-1-3840`. For related information, see [Pricing](/sql/pricing).
#
# GET /sql/v1beta4/projects/{project}/tiers
# Returns: record<items: table<DiskQuota: string, RAM: string, kind: string, region: list, tier: string>, kind: string>
# operationId: sql.tiers.list
export def "sql-tiers-list" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sql/v1beta4/projects/{project}/tiers"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
